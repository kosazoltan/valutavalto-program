import apiClient from './client';
import type { EveningClosingData } from '@/types';

export async function prepareEveningClosing(
  date?: string,
): Promise<EveningClosingData> {
  const response = await apiClient.post<EveningClosingData>(
    '/evening-closing/prepare',
    undefined,
    { params: { date } },
  );
  return response.data;
}

export async function sendEveningPackage(
  id: string,
): Promise<EveningClosingData> {
  const response = await apiClient.post<EveningClosingData>(
    `/evening-closing/${id}/send`,
  );
  return response.data;
}

export async function getEveningClosingStatus(
  date?: string,
): Promise<EveningClosingData> {
  const response = await apiClient.get<EveningClosingData>(
    '/evening-closing/status',
    { params: { date } },
  );
  return response.data;
}
