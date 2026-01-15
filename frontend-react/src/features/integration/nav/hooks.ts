/**
 * NAV Integration Hooks - TanStack Query hooks
 *
 * @since 2026-01-13
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { navApi } from './api'
import type {
  NavCashRegisterStatus,
  NavReceipt,
  NavSyncResult,
  NavConnectionTest,
  NavDailyStatistics,
} from './types'

/**
 * Query key factory
 */
export const navKeys = {
  all: ['nav'] as const,
  status: (apNumber?: string) => [...navKeys.all, 'status', apNumber] as const,
  pending: (apNumber?: string) => [...navKeys.all, 'pending', apNumber] as const,
  receipts: (date?: Date, apNumber?: string) =>
    [...navKeys.all, 'receipts', date?.toISOString().split('T')[0], apNumber] as const,
  connection: () => [...navKeys.all, 'connection'] as const,
  statistics: (date?: Date) =>
    [...navKeys.all, 'statistics', date?.toISOString().split('T')[0]] as const,
}

/**
 * Pénztárgép státusz lekérése
 */
export function useNavCashRegisterStatus(apNumber?: string, enabled = true) {
  return useQuery<NavCashRegisterStatus[], Error>({
    queryKey: navKeys.status(apNumber),
    queryFn: () => navApi.getCashRegisterStatus(apNumber),
    enabled,
    staleTime: 30 * 1000, // 30 másodperc
    refetchInterval: 60 * 1000, // 1 percenként frissít
  })
}

/**
 * Függőben lévő nyugták lekérése
 */
export function useNavPendingReceipts(apNumber?: string, enabled = true) {
  return useQuery<NavReceipt[], Error>({
    queryKey: navKeys.pending(apNumber),
    queryFn: () => navApi.getPendingReceipts(apNumber),
    enabled,
    staleTime: 30 * 1000,
    refetchInterval: 60 * 1000,
  })
}

/**
 * Napi nyugták lekérése
 */
export function useNavDailyReceipts(date?: Date, apNumber?: string, enabled = true) {
  return useQuery<NavReceipt[], Error>({
    queryKey: navKeys.receipts(date, apNumber),
    queryFn: () => navApi.getDailyReceipts(date, apNumber),
    enabled,
    staleTime: 5 * 60 * 1000, // 5 perc
  })
}

/**
 * NAV kapcsolat tesztelése
 */
export function useNavConnectionTest(enabled = true) {
  return useQuery<NavConnectionTest, Error>({
    queryKey: navKeys.connection(),
    queryFn: () => navApi.testConnection(),
    enabled,
    staleTime: 60 * 1000,
  })
}

/**
 * Napi statisztika lekérése
 */
export function useNavDailyStatistics(date?: Date, enabled = true) {
  return useQuery<NavDailyStatistics, Error>({
    queryKey: navKeys.statistics(date),
    queryFn: () => navApi.getDailyStatistics(date),
    enabled,
    staleTime: 5 * 60 * 1000,
  })
}

/**
 * Szinkronizálás mutation
 */
export function useNavSync() {
  const queryClient = useQueryClient()

  return useMutation<NavSyncResult, Error, string | undefined>({
    mutationFn: (apNumber) => navApi.syncReceipts(apNumber),
    onSuccess: () => {
      // Frissítjük a függőben lévő nyugtákat és státuszt
      queryClient.invalidateQueries({ queryKey: navKeys.all })
    },
  })
}
