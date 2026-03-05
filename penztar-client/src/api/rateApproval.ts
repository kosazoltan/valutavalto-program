import apiClient from './client';
import type { RateApproval, RequestRateChangeRequest } from '@/types';

export async function requestRateChange(data: RequestRateChangeRequest): Promise<RateApproval> {
  const res = await apiClient.post<RateApproval>('/rate-approvals/request', data);
  return res.data;
}

export async function approveRateChange(id: string): Promise<RateApproval> {
  const res = await apiClient.post<RateApproval>(`/rate-approvals/${id}/approve`);
  return res.data;
}

export async function rejectRateChange(id: string, reason?: string): Promise<RateApproval> {
  const res = await apiClient.post<RateApproval>(`/rate-approvals/${id}/reject`, { reason });
  return res.data;
}

export async function getPendingApprovals(): Promise<RateApproval[]> {
  const res = await apiClient.get<RateApproval[]>('/rate-approvals/pending');
  return res.data;
}

export async function getApprovalHistory(branchId: string): Promise<RateApproval[]> {
  const res = await apiClient.get<RateApproval[]>('/rate-approvals/history', {
    params: { branchId },
  });
  return res.data;
}
