import apiClient from './client';
import type { WorkerDetail, WorkerAttendance, WorkerBreak } from '@/types';

interface PageResponse<T> {
  content: T[];
  totalPages: number;
  totalElements: number;
  number: number;
  size: number;
}

export async function getWorkers(): Promise<WorkerDetail[]> {
  const { data } = await apiClient.get<WorkerDetail[]>('/workers');
  return data;
}

export async function createWorker(worker: {
  companyId: string;
  branchId: string;
  code: string;
  name: string;
  password: string;
  role: string;
  phone?: string;
  email?: string;
}): Promise<WorkerDetail> {
  const { data } = await apiClient.post<WorkerDetail>('/workers', worker);
  return data;
}

export async function updateWorker(
  id: number,
  updates: Partial<{
    name: string;
    role: string;
    branchId: string;
    phone: string;
    email: string;
    active: boolean;
  }>,
): Promise<WorkerDetail> {
  const { data } = await apiClient.put<WorkerDetail>(`/workers/${id}`, updates);
  return data;
}

export async function resetWorkerPassword(id: number, newPassword: string): Promise<void> {
  await apiClient.post(`/workers/${id}/reset-password`, { newPassword });
}

export async function getWorkerAttendance(
  id: number,
  page = 0,
  size = 20,
): Promise<PageResponse<WorkerAttendance>> {
  const { data } = await apiClient.get<PageResponse<WorkerAttendance>>(
    `/workers/${id}/attendance`,
    { params: { page, size } },
  );
  return data;
}

export async function startWorkerBreak(id: number, reason?: string): Promise<WorkerBreak> {
  const { data } = await apiClient.post<WorkerBreak>(`/workers/${id}/break-start`, { reason });
  return data;
}

export async function endWorkerBreak(id: number): Promise<WorkerBreak> {
  const { data } = await apiClient.post<WorkerBreak>(`/workers/${id}/break-end`);
  return data;
}
