import apiClient from './client';
import type { ReceiptSearchResult, ReceiptDetail } from '@/types';

interface PageResponse<T> {
  content: T[];
  totalPages: number;
  totalElements: number;
  number: number;
  size: number;
}

export interface ReceiptSearchParams {
  number?: string;
  dateFrom?: string;
  dateTo?: string;
  type?: string;
  minAmount?: number;
  maxAmount?: number;
  customer?: string;
  page?: number;
  size?: number;
}

export async function searchReceipts(params: ReceiptSearchParams): Promise<PageResponse<ReceiptSearchResult>> {
  const { data } = await apiClient.get<PageResponse<ReceiptSearchResult>>('/receipts/search', { params });
  return data;
}

export async function getReceiptDetail(id: number): Promise<ReceiptDetail> {
  const { data } = await apiClient.get<ReceiptDetail>(`/receipts/${id}`);
  return data;
}
