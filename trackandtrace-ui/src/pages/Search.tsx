import { useState, useEffect } from "react";
import type { OrderSearchResult } from "../viewmodel/order.types";
import { useNavigate, useSearchParams } from "react-router-dom";
import { searchOrders } from "../api/orderApi";
import styled from "styled-components";
import StatusBadge from "../components/StatusBadge";

const PageWrapper = styled.div`
  max-width: 1000px;
  margin: 0 auto;
  padding: 32px 24px;
`;

const PageTitle = styled.div`
  font-size: 20px;
  font-weight: 500;
  margin-bottom: 24px;
  color: #111;
`;

const SearchRow = styled.div`
  display: flex;
  gap: 8px;
  margin-bottom: 24px;
`;

const Input = styled.input`
  flex: 2;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  outline: none;

  &:focus {
    border-color: #378add;
  }
`;

const Select = styled.select`
  flex: 1;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  outline: none;
  background: #fff;

  &:focus {
    border-color: #378add;
  }
`;

const SearchButton = styled.button`
  padding: 8px 24px;
  border: 1px solid #292727;
  border-radius: 6px;
  font-size: 14px;
  background: #9b999786;
  transition: background 0.15s;

  &:hover {
    background: #f5f5f5;
  }
`;

const ClearButton = styled.button`
  padding: 8px 24px;
  border: 1px solid #303030;
  border-radius: 6px;
  font-size: 14px;
  background: #f55e6b9e;
  transition: background 0.15s;

  &:hover {
    background: #f5f5f5;
  }
`;

const Table = styled.table`
  background: #fff;
  border-radius: 8px;
  border: 1px solid #eee;
  overflow: hidden;
  font-size: 14px;
`;

const Th = styled.th`
  text-align: left;
  padding: 10px 16px;
  font-weight: 500;
  color: #666;
  font-size: 13px;
  background: #f9f9f9;
  border-bottom: 1px solid #eee;
`;

const Tr = styled.tr`
  border-top: 1px solid #eee;
  cursor: pointer;
  transition: background 0.1s;

  &:hover {
    background: #f5f5f5;
  }
`;

const Td = styled.td`
  padding: 12px 16px;
  color: #333;
`;

const Message = styled.p`
  color: #888;
  font-size: 14px;
`;

const ErrorMessage = styled.p`
  color: #dc3545;
  font-size: 14px;
`;

const PaginationRow = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 16px;
  font-size: 13px;
  color: #666;
`;

const PageButton = styled.button<{ $active?: boolean }>`
  padding: 6px 12px;
  margin: 0 2px;
  border: 1px solid ${props => props.$active ? '#378add' : '#ddd'};
  border-radius: 4px;
  background: ${props => props.$active ? '#e6f1fb' : '#fff'};
  color: ${props => props.$active ? '#0c447c' : '#333'};
  font-size: 13px;
  cursor: pointer;

  &:hover {
    background: #f5f5f5;
  }

  &:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }
`;

function Search() {
    const [searchParams, setSearchParams] = useSearchParams();
    const [ref, setRef] = useState<string>(searchParams.get('ref') || '');
    const [status, setStatus] = useState<string>(searchParams.get('status') || '');
    const [results, setResults] = useState<OrderSearchResult[]>([]);
    const [loading, setLoading] = useState<boolean>(false);
    const [error, setError] = useState<string | null>(null);
    const [searched, setSearched] = useState<boolean>(false);
    const navigate = useNavigate();
    const [page, setPage] = useState<number>(0);
    const [total, setTotal] = useState<number>(0);
    const size = 25;

    useEffect(() => {
        handleSearch();
    }, []);

    const handleSearch = async (pageNum: number = 0) => {
        setLoading(true);
        setError(null);
        setSearched(true);
        setSearchParams({ ref, status, page: String(pageNum) });

        try {
            const res = await searchOrders(ref, status, size, pageNum);
            setResults(res.data.content);
            setTotal(res.data.total);
            setPage(pageNum);

        } catch (err) {
            setError('Failed to fetch orders. Please try again.');
            setResults([]);

        } finally {
            setLoading(false);

        }
    }

    const clearFilter = () => {
        setRef('');
        setStatus('');
    };

    const handleRowClick = (order: OrderSearchResult) => {
        navigate(`/orders/${order.orderRef}?type=${order.orderType}`);
    };

    return (
        <PageWrapper>
            <PageTitle>Track and Trace</PageTitle>

            <SearchRow>
                <Input
                    type="text"
                    placeholder="Enter order reference e.g. CO-2026-000001"
                    value={ref}
                    onChange={(e) => setRef(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
                />

                <Select value={status} onChange={(e) => setStatus(e.target.value)}>
                    <option value="">All Statuses</option>
                    <option value="DELIVERED">Delivered</option>
                    <option value="EXCEPTION">Exception</option>
                    <option value="PROCESSING">Processing</option>
                    <option value="RECEIVED">Received</option>
                    <option value="SHIPPED">Shipped</option>
                </Select>
                <SearchButton onClick={() => handleSearch(0)}>Search</SearchButton>
                <ClearButton onClick={clearFilter}> Clear </ClearButton>


            </SearchRow>



            {loading && <Message>Loading...</Message>}
            {error && <ErrorMessage>{error}</ErrorMessage>}
            {!loading && searched && results.length === 0 && (
                <Message>No Orders found</Message>
            )}

            {!loading && results.length > 0 && (
                <>
                    <Table>
                        <thead>
                            <tr>
                                <Th>Order ref</Th>
                                <Th>Type</Th>
                                <Th>Customer</Th>
                                <Th>Status</Th>
                                <Th>Updated</Th>
                            </tr>
                        </thead>
                        <tbody>
                            {results.map((order) => (
                                <Tr key={order.orderRef} onClick={() => handleRowClick(order)}>
                                    <Td>{order.orderRef}</Td>
                                    <Td>{order.orderType}</Td>
                                    <Td>{order.customerName}</Td>
                                    <Td><StatusBadge status={order.status} /></Td>
                                    <Td>
                                        {order.updatedAt
                                            ? new Date(order.updatedAt).toLocaleString() : '-'}
                                    </Td>
                                </Tr>
                            ))}
                        </tbody>
                    </Table>

                    <PaginationRow>
                        <span>
                            Showing {page * size + 1}–{Math.min((page + 1) * size, total)} of {total} orders
                        </span>
                        <div>
                            <PageButton
                                disabled={page === 0}
                                onClick={() => handleSearch(page - 1)}
                            >
                                ← Prev
                            </PageButton>

                            {[...Array(Math.ceil(total / size))].map((_, i) => (
                                <PageButton
                                    key={i}
                                    $active={i === page}
                                    onClick={() => handleSearch(i)}
                                >
                                    {i + 1}
                                </PageButton>
                            ))}

                            <PageButton
                                disabled={(page + 1) * size >= total}
                                onClick={() => handleSearch(page + 1)}
                            >
                                Next →
                            </PageButton>
                        </div>
                    </PaginationRow>
                </>
            )}

        </PageWrapper>

    );

}

export default Search;
