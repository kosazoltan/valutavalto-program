import apiClient from './client';
import type { HrkTransaction, CreateHrkRequest } from '@/types';

export async function hrkHandover(
  request: CreateHrkRequest,
): Promise<HrkTransaction> {
  const response = await apiClient.post<HrkTransaction>(
    '/hrk/handover',
    request,
  );
  return response.data;
}

export async function hrkReceive(
  request: CreateHrkRequest,
): Promise<HrkTransaction> {
  const response = await apiClient.post<HrkTransaction>(
    '/hrk/receive',
    request,
  );
  return response.data;
}

export async function getHrkJournal(): Promise<HrkTransaction[]> {
  const response = await apiClient.get<HrkTransaction[]>('/hrk/journal');
  return response.data;
}

export async function closeHrkDaily(
  date?: string,
): Promise<HrkTransaction[]> {
  const response = await apiClient.post<HrkTransaction[]>(
    '/hrk/close-daily',
    undefined,
    { params: { date } },
  );
  return response.data;
}
