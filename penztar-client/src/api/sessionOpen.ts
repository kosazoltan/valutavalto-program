import apiClient from './client';
import type { SessionData, SessionOpenRequest } from '@/types';

export async function openSession(request: SessionOpenRequest): Promise<SessionData> {
  const response = await apiClient.post<SessionData>('/sessions/open', request);
  return response.data;
}

export async function getOpeningBalance(sessionId: number): Promise<Record<string, number>> {
  const response = await apiClient.get<Record<string, number>>(`/sessions/opening-balance/${sessionId}`);
  return response.data;
}

export async function validateSessionOpen(branchId: string): Promise<string[]> {
  const response = await apiClient.get<string[]>(`/sessions/validate-open/${branchId}`);
  return response.data;
}
