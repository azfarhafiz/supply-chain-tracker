
import styled from "styled-components";
import type { OrderStatus } from "../viewmodel/order.types"

interface StatusBadgeProps {
    status: OrderStatus | string;
}

const badgeColors: Record<string, { bg: string; color: string }> = {
    RECEIVED: { bg: '#f1efee', color: '#444441' },
    PROCESSING: { bg: '#faeeda', color: '#633806' },
    SHIPPED: { bg: '#e6f1fb', color: '#0c447c' },
    DELIVERED: { bg: '#eaf3de', color: '#27500a' },
    EXCEPTION: { bg: '#fcebeb', color: '#791f1f' },
}

const Badge = styled.span<{ $bg: string; $color: string }>`
  display: inline-block;
  padding: 3px 12px;
  border-radius: 99px;
  font-size: 12px;
  font-weight: 500;
  background: ${props => props.$bg};
  color: ${props => props.$color};
`;

function StatusBadge({ status }: StatusBadgeProps) {
    const colors = badgeColors[status] ?? { bg: '#eee', color: '#333' };
    return (
        <Badge $bg={colors.bg} $color={colors.color}>
            {status}
        </Badge>
    );
}

export default StatusBadge;
