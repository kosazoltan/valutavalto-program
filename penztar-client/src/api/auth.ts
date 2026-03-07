import apiClient, { setAuthToken } from './client';
import type { LoginRequest, LoginResponse, SelectRoleRequest } from '@/types';

export async function login(request: LoginRequest): Promise<LoginResponse> {
  const response = await apiClient.post<LoginResponse>('/auth/login', request);
  setAuthToken(response.data.token);
  return response.data;
}

/**
 * V57: Operatív szerepkör kiválasztása login után.
 * Ha a worker-nek több role-ja van, a login után ezzel választja ki az aktív role-t.
 */
export async function selectRole(request: SelectRoleRequest): Promise<LoginResponse> {
  const response = await apiClient.post<LoginResponse>('/auth/login/select-role', request);
  setAuthToken(response.data.token);
  return response.data;
}

export async function logout(): Promise<void> {
  try {
    await apiClient.post('/auth/logout');
  } finally {
    setAuthToken(null);
  }
}

export async function refreshToken(token: string): Promise<string> {
  const response = await apiClient.post<{ token: string }>('/auth/refresh', {
    refreshToken: token,
  });
  setAuthToken(response.data.token);
  return response.data.token;
}
