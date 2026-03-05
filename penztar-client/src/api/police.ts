import apiClient from './client';
import type { PoliceRequestData, CreatePoliceRequest } from '@/types';

interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

export async function createPoliceRequest(data: CreatePoliceRequest): Promise<PoliceRequestData> {
  const res = await apiClient.post<PoliceRequestData>('/police/requests', data);
  return res.data;
}

export async function processPoliceRequest(id: string): Promise<PoliceRequestData> {
  const res = await apiClient.post<PoliceRequestData>(`/police/requests/${id}/process`);
  return res.data;
}

export async function getPoliceRequests(page = 0, size = 20): Promise<PageResponse<PoliceRequestData>> {
  const res = await apiClient.get<PageResponse<PoliceRequestData>>('/police/requests', {
    params: { page, size },
  });
  return res.data;
}

export async function getPoliceRequest(id: string): Promise<PoliceRequestData> {
  const res = await apiClient.get<PoliceRequestData>(`/police/requests/${id}`);
  return res.data;
}
