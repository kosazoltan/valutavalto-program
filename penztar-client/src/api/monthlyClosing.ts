import apiClient from './client';

export interface MonthlyClosingSummaryResponse {
  id: number;
  yearMonth: string;
  closedAt: string;
  totalBuyHuf: number;
  totalSellHuf: number;
  totalHandlingFee: number;
  transactionCount: number;
  currencyBreakdown: string;
}

export async function performMonthlyClosing(
  branchId: string,
  yearMonth: string,
): Promise<MonthlyClosingSummaryResponse> {
  const response = await apiClient.post<MonthlyClosingSummaryResponse>(
    `/closing/monthly/${branchId}/${yearMonth}`,
  );
  return response.data;
}

export async function getMonthlyReport(
  branchId: string,
  yearMonth: string,
): Promise<MonthlyClosingSummaryResponse> {
  const response = await apiClient.get<MonthlyClosingSummaryResponse>(
    `/closing/monthly/${branchId}/${yearMonth}`,
  );
  return response.data;
}

export async function getAllClosedMonths(
  branchId: string,
): Promise<MonthlyClosingSummaryResponse[]> {
  const response = await apiClient.get<MonthlyClosingSummaryResponse[]>(
    `/closing/monthly/${branchId}`,
  );
  return response.data;
}
