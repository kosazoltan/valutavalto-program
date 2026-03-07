import apiClient from './client';
import type { Transfer, TransferRequest, Branch } from '@/types';

// ============================================================
// Transfer API — igazítva a TransferController-hez
// ============================================================

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
  receivedAmount: number,
  notes?: string,
): Promise<Transfer> {
  const { data } = await apiClient.post<Transfer>(`/transfers/${id}/receive`, {
    receivedAmount,
    notes,
  });
  return data;
}

export async function rejectTransfer(
  id: number,
  reason: string,
): Promise<Transfer> {
  const { data } = await apiClient.post<Transfer>(
    `/transfers/${id}/reject`,
    null,
    { params: { reason } },
  );
  return data;
}

export async function getBranches(): Promise<Branch[]> {
  const response = await apiClient.get<Branch[]>('/branches');
  return response.data;
}
