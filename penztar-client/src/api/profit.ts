import apiClient from './client';

export interface ProfitCurrencyEntry {
  currencyCode: string;
  buyCount: number;
  sellCount: number;
  buyHuf: number;
  sellHuf: number;
  revenue: number;
  fees: number;
  profit: number;
}

export interface ProfitReportResponse {
  revenue: number;
  expenses: number;
  grossProfit: number;
  netProfit: number;
  totalTransactions: number;
  profitByCurrency: ProfitCurrencyEntry[];
}

export async function getDailyProfit(
  branchId: string,
  date: string,
): Promise<ProfitReportResponse> {
  const response = await apiClient.get<ProfitReportResponse>('/profit/daily', {
    params: { branchId, date },
  });
  return response.data;
}

export async function getMonthlyProfit(
  branchId: string,
  month: string,
): Promise<ProfitReportResponse> {
  const response = await apiClient.get<ProfitReportResponse>(
    '/profit/monthly',
    { params: { branchId, month } },
  );
  return response.data;
}

export async function getCompanyProfit(
  companyId: string,
  month: string,
): Promise<ProfitReportResponse> {
  const response = await apiClient.get<ProfitReportResponse>(
    '/profit/company',
    { params: { companyId, month } },
  );
  return response.data;
}
