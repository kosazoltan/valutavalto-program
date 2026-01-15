/**
 * Compliance Hooks - TanStack Query hooksk
 *
 * @since 2026-01-13
 */

import { useQuery, useMutation } from '@tanstack/react-query'
import { complianceApi } from '../api/complianceApi'
import type {
  ComplianceCheck,
  CustomerRiskProfile,
  AmlAlert,
  DailyComplianceSummary,
} from '../types'

/**
 * Query key factory
 */
export const complianceKeys = {
  all: ['compliance'] as const,
  check: (customerId: string, amount: number) =>
    [...complianceKeys.all, 'check', customerId, amount] as const,
  profile: (customerId: string) =>
    [...complianceKeys.all, 'profile', customerId] as const,
  alerts: (status?: string, page?: number) =>
    [...complianceKeys.all, 'alerts', status || 'all', page || 0] as const,
  dailySummary: () => [...complianceKeys.all, 'daily-summary'] as const,
}

/**
 * Compliance ellenőrzés mutation
 */
export function useComplianceCheck() {
  return useMutation<ComplianceCheck, Error, { customerId: string; amount: number }>({
    mutationFn: ({ customerId, amount }) =>
      complianceApi.checkCompliance(customerId, amount),
  })
}

/**
 * Ügyfél kockázati profil lekérése
 */
export function useCustomerProfile(customerId: string, enabled = true) {
  return useQuery<CustomerRiskProfile, Error>({
    queryKey: complianceKeys.profile(customerId),
    queryFn: () => complianceApi.getCustomerProfile(customerId),
    enabled: enabled && !!customerId,
    staleTime: 5 * 60 * 1000,
  })
}

/**
 * AML riasztások listázása
 */
export function useAmlAlerts(status?: string, page = 0, size = 20, enabled = true) {
  return useQuery<AmlAlert[], Error>({
    queryKey: complianceKeys.alerts(status, page),
    queryFn: () => complianceApi.getAlerts(status, page, size),
    enabled,
    staleTime: 60 * 1000, // 1 perc
  })
}

/**
 * Napi compliance összesítés
 */
export function useDailyComplianceSummary(enabled = true) {
  return useQuery<DailyComplianceSummary, Error>({
    queryKey: complianceKeys.dailySummary(),
    queryFn: () => complianceApi.getDailySummary(),
    enabled,
    staleTime: 5 * 60 * 1000,
  })
}
