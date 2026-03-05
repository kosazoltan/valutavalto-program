import apiClient from './client';

export interface CommissionCalculationResponse {
  id: string;
  workerId: number;
  branchId: string;
  period: string;
  calculationType: string;
  totalTransactions: number;
  totalVolumeHuf: number;
  commissionRate: number;
  commissionAmount: number;
  bonusAmount: number;
  deductions: number;
  netCommission: number;
  status: 'CALCULATED' | 'APPROVED' | 'PAID';
  calculatedAt: string;
  approvedBy: number | null;
  approvedAt: string | null;
}

export async function calculateCommission(
  workerId: number,
  month: string,
): Promise<CommissionCalculationResponse> {
  const response = await apiClient.post<CommissionCalculationResponse>(
    '/commissions/calculate',
    null,
    { params: { workerId, month } },
  );
  return response.data;
}

export async function calculateAllCommissions(
  branchId: string,
  month: string,
): Promise<CommissionCalculationResponse[]> {
  const response = await apiClient.post<CommissionCalculationResponse[]>(
    '/commissions/calculate-all',
    null,
    { params: { branchId, month } },
  );
  return response.data;
}

export async function approveCommission(
  id: string,
): Promise<CommissionCalculationResponse> {
  const response = await apiClient.post<CommissionCalculationResponse>(
    `/commissions/${id}/approve`,
  );
  return response.data;
}

export async function getCommissionReport(
  branchId: string,
  month: string,
): Promise<CommissionCalculationResponse[]> {
  const response = await apiClient.get<CommissionCalculationResponse[]>(
    '/commissions/report',
    { params: { branchId, month } },
  );
  return response.data;
}
