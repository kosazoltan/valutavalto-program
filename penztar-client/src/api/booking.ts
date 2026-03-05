import apiClient from './client';

export async function downloadDailyCsv(
  branchId: string,
  date: string,
): Promise<Blob> {
  const response = await apiClient.get<Blob>('/booking/daily', {
    params: { branchId, date },
    responseType: 'blob',
  });
  return response.data;
}

export async function downloadMonthlyCsv(
  branchId: string,
  month: string,
): Promise<Blob> {
  const response = await apiClient.get<Blob>('/booking/monthly', {
    params: { branchId, month },
    responseType: 'blob',
  });
  return response.data;
}

export async function downloadInventoryCsv(
  branchId: string,
  date: string,
): Promise<Blob> {
  const response = await apiClient.get<Blob>('/booking/inventory', {
    params: { branchId, date },
    responseType: 'blob',
  });
  return response.data;
}
