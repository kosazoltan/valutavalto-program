import apiClient from './client';

export interface SystemParamData {
  id: string;
  parameterKey: string;
  parameterValue: string;
  parameterType: string;
  category: string;
  description: string;
  isActive: boolean;
  updatedAt: string;
  updatedBy: string | null;
}

export async function getAllSystemParams(): Promise<SystemParamData[]> {
  const { data } = await apiClient.get<SystemParamData[]>('/system-params');
  return data;
}

export async function getSystemParamsByCategory(category: string): Promise<SystemParamData[]> {
  const { data } = await apiClient.get<SystemParamData[]>(`/system-params/category/${category}`);
  return data;
}

export async function updateSystemParam(key: string, value: string, description?: string): Promise<SystemParamData> {
  const body: Record<string, string> = { value };
  if (description) body.description = description;
  const { data } = await apiClient.put<SystemParamData>(`/system-params/${key}`, body);
  return data;
}

export async function bulkUpdateSystemParams(params: Record<string, string>): Promise<{ updated: string }> {
  const { data } = await apiClient.post<{ updated: string }>('/system-params/bulk-update', { parameters: params });
  return data;
}
