

export interface OrderSearchResult {
    orderRef: string;
    orderType: string;
    customerName: string;
    status: string;
    updatedAt: string;
}

export interface CustomerOrderResult {
    orderRef: string;
    customerName: string;
    status: string;
    orderDate: string;
    requestedDeliveryDate: string;
    country: string;
    totalItems: number;
    totalWeightKg: number;
}

export interface OrderEventResult {
    eventCode: string;
    eventDescription: string;
    eventTimestamp: string;
    location: string;
}

export interface SearchResponse {
    content: OrderSearchResult[];
    total: number;
    page: number;
    size: number;
}

export type OrderStatus =
    | 'DELIVERED'
    | 'EXCEPTION'
    | 'PROCESSING'
    | 'RECEIVED'
    | 'SHIPPED';