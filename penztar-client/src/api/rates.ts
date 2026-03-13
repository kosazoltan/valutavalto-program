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

/**
 * Árfolyam elosztás visszaigazolása.
 * A pénztár jelzi, hogy megkapta az új árfolyamot.
 */
export async function acknowledgeRateDistribution(
  distributionId: string,
): Promise<void> {
  await apiClient.post(
    `/exchange-rate-master/distribution/${distributionId}/acknowledge`,
  );
}
