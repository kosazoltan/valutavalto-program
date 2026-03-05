import apiClient from './client';
import type { RegenerationResult } from '@/types';

export async function regenerateInventory(branchId: string): Promise<RegenerationResult> {
  const res = await apiClient.post<RegenerationResult>(
    '/inventory/regeneration/run',
    null,
    { params: { branchId } },
  );
  return res.data;
}

export async function getLastRegeneration(branchId: string): Promise<RegenerationResult> {
  const res = await apiClient.get<RegenerationResult>(
    '/inventory/regeneration/last',
    { params: { branchId } },
  );
  return res.data;
}
