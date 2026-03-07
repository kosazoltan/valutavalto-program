import apiClient from './client';
import type { StornoCheck, StornoRequest, StornoResponse } from '@/types';

// ============================================================
// Storno API — igazítva a StornoController-hez
// ============================================================

export async function checkStorno(
  transactionId: number,
  workerId: number,
): Promise<StornoCheck> {
  const { data } = await apiClient.get<StornoCheck>(
    `/stornos/check/${transactionId}`,
    { params: { workerId } },
  );
  return data;
}

export async function executeStorno(
  request: StornoRequest,
  workerId: number,
): Promise<StornoResponse> {
  const { data } = await apiClient.post<StornoResponse>(
    '/stornos/execute',
    request,
    { params: { workerId } },
  );
  return data;
}

export async function requestStornoApproval(
  transactionId: number,
  workerId: number,
  reason: string,
) {
  const { data } = await apiClient.post('/stornos/request-approval', null, {
    params: { transactionId, workerId, reason },
  });
  return data;
}

export async function approveStorno(
  approvalId: number,
  approvedByWorkerId: number,
  approved: boolean,
  reason?: string,
) {
  const { data } = await apiClient.post(`/stornos/approve/${approvalId}`, null, {
    params: { approvedByWorkerId, approved, reason },
  });
  return data;
}
