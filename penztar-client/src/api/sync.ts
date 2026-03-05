import apiClient from './client';

export interface SyncLogDto {
  id: string;
  branchId: string;
  syncType: string;
  direction: string;
  status: string;
  startedAt: string;
  completedAt: string | null;
  recordCount: number;
  errorMessage: string | null;
}

export interface SyncStatusDto {
  branchId: string;
  lastSyncTimes: Record<string, string>;
}

export async function syncRates(branchId: string): Promise<SyncLogDto> {
  const { data } = await apiClient.post<SyncLogDto>(`/sync/rates/${branchId}`);
  return data;
}

export async function syncTransactions(branchId: string): Promise<SyncLogDto> {
  const { data } = await apiClient.post<SyncLogDto>(`/sync/transactions/${branchId}`);
  return data;
}

export async function syncInventory(branchId: string): Promise<SyncLogDto> {
  const { data } = await apiClient.post<SyncLogDto>(`/sync/inventory/${branchId}`);
  return data;
}

export async function syncFull(branchId: string): Promise<SyncLogDto> {
  const { data } = await apiClient.post<SyncLogDto>(`/sync/full/${branchId}`);
  return data;
}

export async function getSyncStatus(branchId: string): Promise<SyncStatusDto> {
  const { data } = await apiClient.get<SyncStatusDto>(`/sync/status/${branchId}`);
  return data;
}

export async function getSyncHistory(
  branchId: string,
  page = 0,
  size = 20
): Promise<{ content: SyncLogDto[]; totalPages: number }> {
  const { data } = await apiClient.get(`/sync/history/${branchId}`, { params: { page, size } });
  return data as { content: SyncLogDto[]; totalPages: number };
}
