import apiClient from './client';

export interface ProposeTradeRequest {
  fromBranchId: string;
  toBranchId: string;
  currencyCode: string;
  amount: number;
  rate: number;
  notes?: string;
}

export interface TradeDto {
  id: string;
  fromBranchId: string;
  fromBranchName: string;
  toBranchId: string;
  toBranchName: string;
  currencyCode: string;
  amount: number;
  rate: number;
  status: string;
  proposedBy: number;
  acceptedBy: number | null;
  proposedAt: string;
  acceptedAt: string | null;
  completedAt: string | null;
  notes: string | null;
}

export async function proposeTrade(dto: ProposeTradeRequest): Promise<TradeDto> {
  const { data } = await apiClient.post<TradeDto>('/trades/propose', dto);
  return data;
}

export async function acceptTrade(id: string): Promise<TradeDto> {
  const { data } = await apiClient.post<TradeDto>(`/trades/${id}/accept`);
  return data;
}

export async function rejectTrade(id: string, reason?: string): Promise<TradeDto> {
  const { data } = await apiClient.post<TradeDto>(`/trades/${id}/reject`, { reason });
  return data;
}

export async function completeTrade(id: string): Promise<TradeDto> {
  const { data } = await apiClient.post<TradeDto>(`/trades/${id}/complete`);
  return data;
}

export async function cancelTrade(id: string): Promise<TradeDto> {
  const { data } = await apiClient.delete<TradeDto>(`/trades/${id}`);
  return data;
}

export async function getPendingTrades(branchId?: string): Promise<TradeDto[]> {
  const params = branchId ? { branchId } : {};
  const { data } = await apiClient.get<TradeDto[]>('/trades/pending', { params });
  return data;
}

export async function getTradeHistory(
  from: string,
  to: string,
  branchId?: string,
  page = 0,
  size = 20
): Promise<{ content: TradeDto[]; totalPages: number; totalElements: number }> {
  const params: Record<string, string | number> = { from, to, page, size };
  if (branchId) params.branchId = branchId;
  const { data } = await apiClient.get('/trades/history', { params });
  return data as { content: TradeDto[]; totalPages: number; totalElements: number };
}
