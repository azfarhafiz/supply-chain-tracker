
import axios from 'axios';
import type { OrderSearchResult, CustomerOrderResult, OrderEventResult, SearchResponse } from '../viewmodel/order.types'


const BASE_URL = 'http://localhost:8080/api/v1';

const api = axios.create({
  baseURL: BASE_URL,
});

export interface PaginatedResponse<T> {
    content: T[];
    totalElements: number;
    totalPages: number;
    size: number;
    number: number;
}

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const message = error.response?.data?.message || error.message || 'Unknown error';
    const code = error.response?.data?.code || 'NETWORK_ERROR';
    return Promise.reject({ code, message, status: error.response?.status });
  }
);

/* export const searchOrders = (ref: string, status: string, size: number = 25, page: number = 0) => {
    return axios.get<OrderSearchResult[]>(`${BASE_URL}/orders/search`, {
        params: { ref, status, size, page }
    });
} */

export const searchOrders = (ref: string, status: string, size: number = 25, page: number = 0) =>
  api.get<SearchResponse>('/orders/search', { params: { ref, status, size, page } });

export const getOrderByRef = (ref: string) => {
    return axios.get<CustomerOrderResult>(`${BASE_URL}/customer-orders/${ref}`);
}

export const getEventsByOrderRef = (ref: string) => {
    return axios.get<OrderEventResult[]>(`${BASE_URL}/orders/CUSTOMER/${ref}/events`);
}

