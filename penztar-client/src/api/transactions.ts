import apiClient from './client';
import type { TransactionRequest, TransactionResponse } from '@/types';

export async function sellCurrency(
  request: TransactionRequest,
): Promise<TransactionResponse> {
  const response = await apiClient.post<TransactionResponse>(
    '/transactions/sell',
    request,
  );
  return response.data;
}

export async function buyCurrency(
  request: TransactionRequest,
): Promise<TransactionResponse> {
  const response = await apiClient.post<TransactionResponse>(
    '/transactions/buy',
    request,
  );
  return response.data;
}

export async function reversalTransaction(
  transactionId: number,
  reason: string,
): Promise<TransactionResponse> {
  const response = await apiClient.post<TransactionResponse>(
    `/transactions/${transactionId}/reversal`,
    { reason },
  );
  return response.data;
}
