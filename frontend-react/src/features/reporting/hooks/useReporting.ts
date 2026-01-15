/**
 * Reporting Hooks - TanStack Query hooksk a riportokhoz
 *
 * @since 2026-01-13
 */

import { useQuery } from '@tanstack/react-query'
import { reportingApi } from '../api/reportingApi'
import type {
  DailyReport,
  DailySummary,
  PeriodReport,
  CurrencyTurnover,
  WorkerStats,
} from '../types'

/**
 * Query key factory - konzisztens query kulcsok
 */
export const reportingKeys = {
  all: ['reporting'] as const,
  dailyReport: (date?: Date) =>
    [...reportingKeys.all, 'daily', date?.toISOString().split('T')[0] || 'today'] as const,
  dailySummary: (date?: Date) =>
    [...reportingKeys.all, 'summary', date?.toISOString().split('T')[0] || 'today'] as const,
  periodReport: (startDate: Date, endDate: Date) =>
    [
      ...reportingKeys.all,
      'period',
      startDate.toISOString().split('T')[0],
      endDate.toISOString().split('T')[0],
    ] as const,
  currencyTurnover: (startDate: Date, endDate: Date) =>
    [
      ...reportingKeys.all,
      'currency',
      startDate.toISOString().split('T')[0],
      endDate.toISOString().split('T')[0],
    ] as const,
  workerStats: (startDate: Date, endDate: Date) =>
    [
      ...reportingKeys.all,
      'workers',
      startDate.toISOString().split('T')[0],
      endDate.toISOString().split('T')[0],
    ] as const,
}

/**
 * Napi riport lekérése
 *
 * @param date Riport dátuma (opcionális)
 * @param enabled Engedélyezve-e a lekérés
 */
export function useDailyReport(date?: Date, enabled = true) {
  return useQuery<DailyReport, Error>({
    queryKey: reportingKeys.dailyReport(date),
    queryFn: () => reportingApi.getDailyReport(date),
    enabled,
    staleTime: 5 * 60 * 1000, // 5 perc
    refetchOnWindowFocus: false,
  })
}

/**
 * Napi összesítés lekérése
 *
 * @param date Riport dátuma (opcionális)
 * @param enabled Engedélyezve-e a lekérés
 */
export function useDailySummary(date?: Date, enabled = true) {
  return useQuery<DailySummary, Error>({
    queryKey: reportingKeys.dailySummary(date),
    queryFn: () => reportingApi.getDailySummary(date),
    enabled,
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
  })
}

/**
 * Időszaki riport lekérése
 *
 * @param startDate Kezdő dátum
 * @param endDate Záró dátum
 * @param enabled Engedélyezve-e a lekérés
 */
export function usePeriodReport(startDate: Date, endDate: Date, enabled = true) {
  return useQuery<PeriodReport, Error>({
    queryKey: reportingKeys.periodReport(startDate, endDate),
    queryFn: () => reportingApi.getPeriodReport(startDate, endDate),
    enabled,
    staleTime: 10 * 60 * 1000, // 10 perc
    refetchOnWindowFocus: false,
  })
}

/**
 * Valuta forgalom riport lekérése
 *
 * @param startDate Kezdő dátum
 * @param endDate Záró dátum
 * @param enabled Engedélyezve-e a lekérés
 */
export function useCurrencyTurnover(startDate: Date, endDate: Date, enabled = true) {
  return useQuery<CurrencyTurnover, Error>({
    queryKey: reportingKeys.currencyTurnover(startDate, endDate),
    queryFn: () => reportingApi.getCurrencyTurnover(startDate, endDate),
    enabled,
    staleTime: 10 * 60 * 1000,
    refetchOnWindowFocus: false,
  })
}

/**
 * Pénztáros statisztika lekérése
 *
 * @param startDate Kezdő dátum
 * @param endDate Záró dátum
 * @param enabled Engedélyezve-e a lekérés
 */
export function useWorkerStats(startDate: Date, endDate: Date, enabled = true) {
  return useQuery<WorkerStats, Error>({
    queryKey: reportingKeys.workerStats(startDate, endDate),
    queryFn: () => reportingApi.getWorkerStats(startDate, endDate),
    enabled,
    staleTime: 10 * 60 * 1000,
    refetchOnWindowFocus: false,
  })
}
