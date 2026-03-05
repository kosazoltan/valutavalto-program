import apiClient from './client';
import type { Transfer, TransferRequest, Branch } from '@/types';

export async function createTransfer(
  request: TransferRequest,
): Promise<Transfer> {
  const response = await apiClient.post<Transfer>('/transfers', request);
  return response.data;
}

export async function getPendingTransfers(): Promise<Transfer[]> {
  const response = await apiClient.get<Transfer[]>('/transfers/pending');
  return response.data;
}

export async function receiveTransfer(
  id: number,
): Promise<Transfer> {
  const response = await apiClient.post<Transfer>(`/transfers/${id}/receive`);
  return response.data;
}

export async function rejectTransfer(
  id: number,
  reason: string,
): Promise<Transfer> {
  const response = await apiClient.post<Transfer>(`/transfers/${id}/reject`, {
    reason,
  });
  return response.data;
}

export async function getBranches(): Promise<Branch[]> {
  const response = await apiClient.get<Branch[]>('/branches');
  return response.data;
}
