import apiClient from './client';
import type { DenominationEntry, DenominationBulkRequest } from '@/types';

export async function getDenominations(
  currencyCode: string,
): Promise<DenominationEntry[]> {
  const response = await apiClient.get<DenominationEntry[]>(
    `/denominations/code/${currencyCode}`,
  );
  return response.data;
}

export async function saveDenominationsBulk(
  request: DenominationBulkRequest,
): Promise<DenominationEntry[]> {
  const response = await apiClient.put<DenominationEntry[]>(
    '/denominations/bulk',
    request,
  );
  return response.data;
}
