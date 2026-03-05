import apiClient from './client';
import type { BackupRecordData, CreateBackupRequest, BackupType } from '@/types';

/**
 * Backup / Restore API
 */

/** Új mentés létrehozása */
export async function createBackup(type: BackupType = 'FULL'): Promise<BackupRecordData> {
  const { data } = await apiClient.post<BackupRecordData>('/backup/create', { type } as CreateBackupRequest);
  return data;
}

/** Backup visszaállítás */
export async function restoreBackup(id: string): Promise<void> {
  await apiClient.post(`/backup/${id}/restore`);
}

/** Backup előzmények */
export async function getBackupHistory(
  page = 0,
  size = 20
): Promise<{ content: BackupRecordData[]; totalElements: number; totalPages: number }> {
  const { data } = await apiClient.get('/backup/history', { params: { page, size } });
  return data;
}

/** Backup letöltés */
export async function downloadBackup(id: string): Promise<Blob> {
  const { data } = await apiClient.get(`/backup/${id}/download`, { responseType: 'blob' });
  return data;
}
