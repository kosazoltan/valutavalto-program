import apiClient from './client';
import type { BranchStatusData } from '@/types';

/**
 * Fiók monitoring API — locserver
 */

/** Heartbeat küldés */
export async function sendHeartbeat(branchId: string): Promise<void> {
  await apiClient.post('/monitoring/heartbeat', { branchId });
}

/** Online fiókok lekérdezése */
export async function getOnlineBranches(): Promise<BranchStatusData[]> {
  const { data } = await apiClient.get<BranchStatusData[]>('/monitoring/online');
  return data;
}

/** Offline fiókok lekérdezése */
export async function getOfflineBranches(minutes = 5): Promise<BranchStatusData[]> {
  const { data } = await apiClient.get<BranchStatusData[]>('/monitoring/offline', { params: { minutes } });
  return data;
}

/** Összes fiók dashboard */
export async function getBranchDashboard(): Promise<Record<string, BranchStatusData>> {
  const { data } = await apiClient.get<Record<string, BranchStatusData>>('/monitoring/dashboard');
  return data;
}
