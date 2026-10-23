import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import styled from 'styled-components';
import { getOrderByRef, getEventsByOrderRef } from '../api/orderApi';
import type { CustomerOrderResult, OrderEventResult } from '../viewmodel/order.types';
import StatusBadge from '../components/StatusBadge';
import EventTimeline from '../components/EventTimeline';

const PageWrapper = styled.div`
  padding: 32px 24px;
  margin: 0 auto;
  max-width: 1400px;
`;

const BackButton = styled.button`
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 14px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 13px;
  background: #fff;
  margin-bottom: 20px;
  color: #555;

  &:hover {
    background: #f5f5f5;
  }
`;

const OrderHeader = styled.div`
  margin-bottom: 24px;
`;

const OrderRef = styled.h2`
  font-size: 20px;
  font-weight: 500;
  color: #111;
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 4px;
`;

const CustomerName = styled.b`
  font-size: 32px;
  color: #142791;

`;

const DetailGrid = styled.div`
  display: grid;
  grid-template-columns: 1fr 1fr; 
  gap: 32px;
  width: 100%;
`;

const Card = styled.div`
  background: #ffffff;
  border: 1px solid #eee;
  border-radius: 8px;
  padding: 100px 100px;
`;

const CardTitle = styled.h2`
  font-size: 20px;
  color: #142791;
  margin-bottom: 16px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
`;

const MetaRow = styled.div`
  display: flex;
  justify-content: space-between;
  padding: 14px 0;
  border-bottom: 1px solid #f5f5f5;
  font-size: 14px;
`;

const MetaLabel = styled.span`
  color: #525151;
`;

const MetaValue = styled.span`
  font-weight: 500;
  color: #000000;
`;

const Message = styled.p`
  color: #888;
  font-size: 14px;
`;

const ErrorMessage = styled.p`
  color: #dc3545;
  font-size: 14px;
`;

const SkeletonBlock = styled.div<{ $width?: string; $height?: string }>`
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 4px;
  width: ${props => props.$width || '100%'};
  height: ${props => props.$height || '16px'};
  margin-bottom: 12px;

  @keyframes shimmer {
    0% { background-position: 200% 0; }
    100% { background-position: -200% 0; }
  }
`;

const SkeletonCard = styled.div`
  background: #fff;
  border: 1px solid #eee;
  border-radius: 8px;
  padding: 28px 32px;
`;

function OrderDetail() {
  const { ref } = useParams<{ ref: string }>();
  const navigate = useNavigate();
  const [order, setOrder] = useState<CustomerOrderResult | null>(null);
  const [events, setEvents] = useState<OrderEventResult[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!ref) return;

    const fetchData = async () => {
      setLoading(true);
      try {
        const [orderRes, eventsRes] = await Promise.all([
          getOrderByRef(ref),
          getEventsByOrderRef(ref)
        ]);
        setOrder(orderRes.data);
        setEvents(eventsRes.data);
      } catch (err: any) {
        if (err.response?.status === 404) {
          setError('Order not found.');
        } else {
          setError('Failed to load order details.');
        }
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [ref]);

/*   if (loading) return <PageWrapper><Message>Loading...</Message></PageWrapper>;
 */
  if (loading) return (
  <PageWrapper>
    <SkeletonBlock $width="120px" $height="32px" />
    <SkeletonBlock $width="200px" $height="24px" style={{ marginBottom: '24px' }} />
    <DetailGrid>
      <SkeletonCard>
        {[...Array(5)].map((_, i) => (
          <SkeletonBlock key={i} $width={i % 2 === 0 ? '60%' : '40%'} />
        ))}
      </SkeletonCard>
      <SkeletonCard>
        {[...Array(4)].map((_, i) => (
          <SkeletonBlock key={i} />
        ))}
      </SkeletonCard>
    </DetailGrid>
  </PageWrapper>
);

  if (error) return (
    <PageWrapper>
      <BackButton onClick={() => navigate('/')}>&lt; Back</BackButton>
      <ErrorMessage>{error}</ErrorMessage>
    </PageWrapper>
  );

  if (!order) return null;
  
  return (
    <PageWrapper>
      <BackButton onClick={() => navigate(-1)}>&lt; Back to search</BackButton>

      <OrderHeader>
        <OrderRef>
          {order.orderRef}
          <StatusBadge status={order.status} />
        </OrderRef>
        <CustomerName>{order.customerName}</CustomerName>
      </OrderHeader>

      <DetailGrid>
        <Card>
          <CardTitle>Order details</CardTitle>
          <MetaRow>
            <MetaLabel>Order date</MetaLabel>
            <MetaValue>{order.orderDate ?? '-'}</MetaValue>
          </MetaRow>
          <MetaRow>
            <MetaLabel>Requested delivery</MetaLabel>
            <MetaValue>{order.requestedDeliveryDate ?? '-'}</MetaValue>
          </MetaRow>
          <MetaRow>
            <MetaLabel>Country</MetaLabel>
            <MetaValue>{order.country ?? '-'}</MetaValue>
          </MetaRow>
          <MetaRow>
            <MetaLabel>Total items</MetaLabel>
            <MetaValue>{order.totalItems ?? '-'}</MetaValue>
          </MetaRow>
          <MetaRow>
            <MetaLabel>Total weight</MetaLabel>
            <MetaValue>{order.totalWeightKg ? `${order.totalWeightKg} kg` : '-'}</MetaValue>
          </MetaRow>
        </Card>

        <Card>
          <CardTitle>Event timeline</CardTitle>
          <EventTimeline events={events} />
        </Card>
      </DetailGrid>
    </PageWrapper>
  );
}

export default OrderDetail;