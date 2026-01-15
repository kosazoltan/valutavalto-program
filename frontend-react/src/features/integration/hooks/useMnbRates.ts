/**
 * MNB Rates Hooks - TanStack Query hooks
 *
 * @since 2026-01-13
 */

import { useQuery } from '@tanstack/react-query'
import { mnbRateApi } from '../api/mnbRateApi'
import type { MnbRateDto, MnbRatesResponse, ComparisonReport } from '../types'

/**
 * Query key factory
 */
export const mnbRateKeys = {
  all: ['mnb-rates'] as const,
  current: () => [...mnbRateKeys.all, 'current'] as const,
  forDate: (date: Date) => [...mnbRateKeys.all, 'date', date.toISOString().split('T')[0]] as const,
  currency: (code: string, date?: Date) =>
    [...mnbRateKeys.all, 'currency', code, date?.toISOString().split('T')[0]] as const,
  history: (code: string, startDate: Date, endDate: Date) =>
    [
      ...mnbRateKeys.all,
      'history',
      code,
      startDate.toISOString().split('T')[0],
      endDate.toISOString().split('T')[0],
    ] as const,
  compare: (date?: Date) =>
    [...mnbRateKeys.all, 'compare', date?.toISOString().split('T')[0]] as const,
}

/**
 * Aktuális MNB árfolyamok lekérése
 */
export function useMnbCurrentRates(enabled = true) {
  return useQuery<MnbRatesResponse, Error>({
    queryKey: mnbRateKeys.current(),
    queryFn: () => mnbRateApi.getCurrentRates(),
    enabled,
    staleTime: 5 * 60 * 1000, // 5 perc
    refetchInterval: 10 * 60 * 1000, // 10 percenként frissít
  })
}

/**
 * MNB árfolyamok adott dátumra
 */
export function useMnbRatesForDate(date: Date, enabled = true) {
  return useQuery<MnbRatesResponse, Error>({
    queryKey: mnbRateKeys.forDate(date),
    queryFn: () => mnbRateApi.getRatesForDate(date),
    enabled,
    staleTime: 60 * 60 * 1000, // 1 óra (múltbeli adatok ritkán változnak)
  })
}

/**
 * Egyedi valuta árfolyam
 */
export function useMnbCurrencyRate(code: string, date?: Date, enabled = true) {
  return useQuery<MnbRateDto, Error>({
    queryKey: mnbRateKeys.currency(code, date),
    queryFn: () => mnbRateApi.getRateForCurrency(code, date),
    enabled: enabled && !!code,
    staleTime: 5 * 60 * 1000,
  })
}

/**
 * Árfolyam történet
 */
export function useMnbRateHistory(
  code: string,
  startDate: Date,
  endDate: Date,
  enabled = true
) {
  return useQuery<MnbRateDto[], Error>({
    queryKey: mnbRateKeys.history(code, startDate, endDate),
    queryFn: () => mnbRateApi.getRateHistory(code, startDate, endDate),
    enabled: enabled && !!code,
    staleTime: 60 * 60 * 1000, // 1 óra
  })
}

/**
 * Összehasonlítás belső árfolyamokkal
 */
export function useMnbRateComparison(date?: Date, enabled = true) {
  return useQuery<ComparisonReport, Error>({
    queryKey: mnbRateKeys.compare(date),
    queryFn: () => mnbRateApi.compareWithInternalRates(date),
    enabled,
    staleTime: 5 * 60 * 1000,
  })
}
