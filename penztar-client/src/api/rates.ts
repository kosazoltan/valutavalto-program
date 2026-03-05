import apiClient from './client';
import type { ExchangeRate, ExchangeRateDetail, ExchangeRateHistory } from '@/types';

export async function getCurrentRates(): Promise<ExchangeRate[]> {
  const response = await apiClient.get<ExchangeRate[]>('/exchange-rates/current');
  return response.data;
}

export async function getRateByCode(
  currencyCode: string,
): Promise<ExchangeRateDetail> {
  const response = await apiClient.get<ExchangeRateDetail>(
    `/exchange-rates/code/${currencyCode}`,
  );
  return response.data;
}

export async function getRateHistory(
  currencyCode: string,
  from: string,
  to: string,
): Promise<ExchangeRateHistory[]> {
  const response = await apiClient.get<ExchangeRateHistory[]>(
    '/exchange-rates/history',
    { params: { currencyCode, from, to } },
  );
  return response.data;
}
