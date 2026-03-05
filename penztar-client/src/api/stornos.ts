import apiClient from './client';
import type { StornoCheck, StornoRequest, StornoResponse } from '@/types';

export async function checkStorno(
  transactionId: number,
): Promise<StornoCheck> {
  const response = await apiClient.get<StornoCheck>(
    `/stornos/check/${transactionId}`,
  );
  return response.data;
}

export async function executeStorno(
  request: StornoRequest,
): Promise<StornoResponse> {
  const response = await apiClient.post<StornoResponse>(
    '/stornos/execute',
    request,
  );
  return response.data;
}
