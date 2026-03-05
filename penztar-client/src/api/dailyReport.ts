import apiClient from './client';
import type { DailyReportData } from '@/types';

export async function generateDailyReport(branchId: string, date?: string): Promise<DailyReportData> {
  const res = await apiClient.post<DailyReportData>(
    `/reports/daily/${branchId}/generate`,
    null,
    { params: date ? { date } : undefined },
  );
  return res.data;
}

export async function getDailyReport(branchId: string, date: string): Promise<DailyReportData> {
  const res = await apiClient.get<DailyReportData>(`/reports/daily/${branchId}/${date}`);
  return res.data;
}

export async function submitDailyReport(reportId: number): Promise<DailyReportData> {
  const res = await apiClient.post<DailyReportData>(`/reports/daily/${reportId}/submit`);
  return res.data;
}
