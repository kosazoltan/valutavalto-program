import apiClient from './client';
import type { StampBatch, StampAssignment, CreateStampBatchRequest, AssignStampRequest } from '@/types';

export async function getStampInventory(): Promise<StampBatch[]> {
  const { data } = await apiClient.get<StampBatch[]>('/stamps/inventory');
  return data;
}

export async function receiveStampBatch(request: CreateStampBatchRequest): Promise<StampBatch> {
  const { data } = await apiClient.post<StampBatch>('/stamps/receive', request);
  return data;
}

export async function assignStamp(request: AssignStampRequest): Promise<StampAssignment> {
  const { data } = await apiClient.post<StampAssignment>('/stamps/assign', request);
  return data;
}

export async function getUsedStamps(): Promise<StampAssignment[]> {
  const { data } = await apiClient.get<StampAssignment[]>('/stamps/used');
  return data;
}
