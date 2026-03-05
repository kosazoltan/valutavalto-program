import apiClient from './client';
import type { DailySession, CashBalance } from '@/types';

export async function openDailySession(
  openingBalances: CashBalance[],
): Promise<DailySession> {
  const response = await apiClient.post<DailySession>('/daily-sessions/open', {
    openingBalances,
  });
  return response.data;
}

export async function closeDailySession(
  sessionId: number,
): Promise<DailySession> {
  const response = await apiClient.post<DailySession>(
    `/daily-sessions/${sessionId}/close`,
  );
  return response.data;
}

export async function getCurrentSession(): Promise<DailySession | null> {
  try {
    const response = await apiClient.get<DailySession>('/daily-sessions/current');
    return response.data;
  } catch {
    return null;
  }
}
