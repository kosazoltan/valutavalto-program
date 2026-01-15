/**
 * Export Hooks - TanStack Query hooksk
 *
 * @since 2026-01-13
 */

import { useQuery, useMutation } from '@tanstack/react-query'
import { exportApi } from '../api/exportApi'
import type { ExportTypeInfo, ExportResult } from '../types'

/**
 * Query key factory
 */
export const exportKeys = {
  all: ['export'] as const,
  types: () => [...exportKeys.all, 'types'] as const,
  info: (startDate: Date, endDate: Date) =>
    [
      ...exportKeys.all,
      'info',
      startDate.toISOString().split('T')[0],
      endDate.toISOString().split('T')[0],
    ] as const,
}

/**
 * Export típusok lekérése
 */
export function useExportTypes(enabled = true) {
  return useQuery<ExportTypeInfo[], Error>({
    queryKey: exportKeys.types(),
    queryFn: () => exportApi.getExportTypes(),
    enabled,
    staleTime: 60 * 60 * 1000, // 1 óra
  })
}

/**
 * Tranzakciók exportálása mutation
 */
export function useExportTransactionsCsv() {
  return useMutation<void, Error, { startDate: Date; endDate: Date }>({
    mutationFn: ({ startDate, endDate }) =>
      exportApi.downloadTransactionsCsv(startDate, endDate),
  })
}

/**
 * Napi riport exportálása mutation
 */
export function useExportDailyReportCsv() {
  return useMutation<void, Error, { date?: Date }>({
    mutationFn: ({ date }) => exportApi.downloadDailyReportCsv(date),
  })
}

/**
 * Export info lekérése
 */
export function useExportInfo(startDate: Date, endDate: Date, enabled = true) {
  return useQuery<ExportResult, Error>({
    queryKey: exportKeys.info(startDate, endDate),
    queryFn: () => exportApi.getTransactionsExportInfo(startDate, endDate),
    enabled,
    staleTime: 5 * 60 * 1000,
  })
}
