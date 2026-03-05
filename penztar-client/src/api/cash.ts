import apiClient from './client';
import type { CashBalance, CashBalanceSummary, CompanyTotals } from '@/types';

export async function getCashBalances(): Promise<CashBalance[]> {
  const response = await apiClient.get<CashBalance[]>('/cash-balances');
  return response.data;
}

export async function getCashBalanceSummary(): Promise<CashBalanceSummary[]> {
  const response = await apiClient.get<CashBalanceSummary[]>('/cash-balances/summary');
  return response.data;
}

export async function getCompanyTotals(): Promise<CompanyTotals> {
  const response = await apiClient.get<CompanyTotals>('/cash-balances/company-totals');
  return response.data;
}

export async function adjustCashBalance(
  currencyCode: string,
  amount: number,
  reason: string,
): Promise<CashBalance> {
  const response = await apiClient.put<CashBalance>(
    `/cash-balances/${currencyCode}`,
    { amount, reason },
  );
  return response.data;
}
