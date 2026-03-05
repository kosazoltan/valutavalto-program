import apiClient from './client';

export interface RecentTransaction {
  id: number;
  receiptNumber: string;
  type: string;
  currencyCode: string;
  amount: number;
  hufAmount: number;
  cashierName: string;
  createdAt: string;
}

export interface BranchSyncStatus {
  branchCode: string;
  branchName: string;
  lastSyncAt: string;
  status: string;
}

export interface DashboardSummary {
  todayVolume: number;
  activeBranches: number;
  openTransactions: number;
  alertCount: number;
  currencyVolumes: Record<string, number>;
  recentTransactions: RecentTransaction[];
  branchSyncStatuses: BranchSyncStatus[];
}

export async function getDashboardSummary(branchId?: string): Promise<DashboardSummary> {
  const params = branchId ? { branchId } : {};
  const { data } = await apiClient.get<DashboardSummary>('/dashboard/summary', { params });
  return data;
}
