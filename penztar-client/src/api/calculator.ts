import apiClient from './client';
import type { CalculationResult, ConvertRequest, ReverseRequest, RoundingRule } from '@/types';

export async function convertCurrency(request: ConvertRequest): Promise<CalculationResult> {
  const response = await apiClient.post<CalculationResult>('/calculator/convert', request);
  return response.data;
}

export async function reverseCalculate(request: ReverseRequest): Promise<{ hufAmount: number; foreignAmount: number }> {
  const response = await apiClient.post<{ hufAmount: number; foreignAmount: number }>('/calculator/reverse', request);
  return response.data;
}

export async function getExchangeMatrix(): Promise<Record<string, Record<string, number>>> {
  const response = await apiClient.get<Record<string, Record<string, number>>>('/calculator/matrix');
  return response.data;
}

export async function getRoundingRules(): Promise<RoundingRule[]> {
  const response = await apiClient.get<RoundingRule[]>('/rounding-rules');
  return response.data;
}

export async function getRoundingRule(currencyCode: string): Promise<RoundingRule> {
  const response = await apiClient.get<RoundingRule>(`/rounding-rules/${currencyCode}`);
  return response.data;
}
