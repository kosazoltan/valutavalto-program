import apiClient from './client';
import type {
  SupervisorAuthResponse,
  OverrideRateRequest,
  OverrideFeeRequest,
  SystemParam,
} from '@/types';

export async function supervisorAuthenticate(password: string): Promise<SupervisorAuthResponse> {
  const { data } = await apiClient.post<SupervisorAuthResponse>('/supervisor/authenticate', { password });
  return data;
}

export async function getSystemParams(): Promise<SystemParam[]> {
  const { data } = await apiClient.get<SystemParam[]>('/supervisor/params');
  return data;
}

export async function overrideRate(request: OverrideRateRequest): Promise<void> {
  await apiClient.post('/supervisor/override-rate', request);
}

export async function overrideFee(request: OverrideFeeRequest): Promise<void> {
  await apiClient.post('/supervisor/override-fee', request);
}
