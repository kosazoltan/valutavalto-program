/**
 * Compliance API - AML és megfelelőségi ellenőrzések
 *
 * ÚJ moduláris API: /api/v2/compliance
 *
 * @since 2026-01-13
 */

import { useAuthStore } from '../../../stores/authStore'
import type {
  ComplianceCheck,
  CustomerRiskProfile,
  AmlAlert,
  DailyComplianceSummary,
} from '../types'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080'
const API_V2_PREFIX = '/api/v2'

/**
 * Authentikált fetch wrapper
 */
async function fetchWithAuth<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const { token, tokenType } = useAuthStore.getState()

  if (!token) {
    throw new Error('Nincs bejelentkezve!')
  }

  const url = `${API_BASE_URL}${API_V2_PREFIX}${endpoint}`

  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `${tokenType || 'Bearer'} ${token}`,
      ...options.headers,
    },
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`API hiba (${response.status}): ${errorText}`)
  }

  return response.json()
}

/**
 * Compliance API
 */
export const complianceApi = {
  /**
   * Ügyfél compliance ellenőrzése
   *
   * GET /api/v2/compliance/check
   *
   * @param customerId Ügyfél azonosító
   * @param amount Tervezett tranzakció összege HUF-ban
   */
  checkCompliance: async (customerId: string, amount: number): Promise<ComplianceCheck> => {
    const params = `?customerId=${encodeURIComponent(customerId)}&amount=${amount}`
    return fetchWithAuth<ComplianceCheck>(`/compliance/check${params}`)
  },

  /**
   * Ügyfél kockázati profil lekérése
   *
   * GET /api/v2/compliance/profile/{customerId}
   *
   * @param customerId Ügyfél azonosító
   */
  getCustomerProfile: async (customerId: string): Promise<CustomerRiskProfile> => {
    return fetchWithAuth<CustomerRiskProfile>(`/compliance/profile/${encodeURIComponent(customerId)}`)
  },

  /**
   * AML riasztások listázása
   *
   * GET /api/v2/compliance/alerts
   *
   * @param status Státusz szűrő (opcionális)
   * @param page Oldalszám
   * @param size Oldal méret
   */
  getAlerts: async (
    status?: string,
    page = 0,
    size = 20
  ): Promise<AmlAlert[]> => {
    const params = new URLSearchParams()
    if (status) params.append('status', status)
    params.append('page', page.toString())
    params.append('size', size.toString())
    return fetchWithAuth<AmlAlert[]>(`/compliance/alerts?${params}`)
  },

  /**
   * Napi compliance összesítés
   *
   * GET /api/v2/compliance/daily-summary
   */
  getDailySummary: async (): Promise<DailyComplianceSummary> => {
    return fetchWithAuth<DailyComplianceSummary>('/compliance/daily-summary')
  },
}
