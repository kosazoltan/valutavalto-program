/**
 * NAV Integration API
 *
 * ÚJ moduláris API: /api/v2/nav
 *
 * @since 2026-01-13
 */

import { useAuthStore } from '../../../stores/authStore'
import type {
  NavCashRegisterStatus,
  NavReceipt,
  NavSyncResult,
  NavConnectionTest,
  NavDailyStatistics,
} from './types'

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
 * Dátum formázása API híváshoz
 */
function formatDate(date: Date): string {
  return date.toISOString().substring(0, 10)
}

/**
 * NAV Integration API
 */
export const navApi = {
  /**
   * Pénztárgép státusz lekérése
   *
   * GET /api/v2/nav/status
   */
  getCashRegisterStatus: async (apNumber?: string): Promise<NavCashRegisterStatus[]> => {
    const params = apNumber ? `?apNumber=${apNumber}` : ''
    return fetchWithAuth<NavCashRegisterStatus[]>(`/nav/status${params}`)
  },

  /**
   * Függőben lévő nyugták lekérése
   *
   * GET /api/v2/nav/pending
   */
  getPendingReceipts: async (apNumber?: string): Promise<NavReceipt[]> => {
    const params = apNumber ? `?apNumber=${apNumber}` : ''
    return fetchWithAuth<NavReceipt[]>(`/nav/pending${params}`)
  },

  /**
   * Napi nyugták lekérése
   *
   * GET /api/v2/nav/receipts
   */
  getDailyReceipts: async (date?: Date, apNumber?: string): Promise<NavReceipt[]> => {
    const params = new URLSearchParams()
    if (date) params.append('date', formatDate(date))
    if (apNumber) params.append('apNumber', apNumber)
    const queryString = params.toString() ? `?${params.toString()}` : ''
    return fetchWithAuth<NavReceipt[]>(`/nav/receipts${queryString}`)
  },

  /**
   * Manuális szinkronizálás indítása
   *
   * POST /api/v2/nav/sync
   */
  syncReceipts: async (apNumber?: string): Promise<NavSyncResult> => {
    const params = apNumber ? `?apNumber=${apNumber}` : ''
    return fetchWithAuth<NavSyncResult>(`/nav/sync${params}`, {
      method: 'POST',
    })
  },

  /**
   * NAV kapcsolat tesztelése
   *
   * GET /api/v2/nav/test-connection
   */
  testConnection: async (): Promise<NavConnectionTest> => {
    return fetchWithAuth<NavConnectionTest>('/nav/test-connection')
  },

  /**
   * Napi statisztika lekérése
   *
   * GET /api/v2/nav/statistics
   */
  getDailyStatistics: async (date?: Date): Promise<NavDailyStatistics> => {
    const params = date ? `?date=${formatDate(date)}` : ''
    return fetchWithAuth<NavDailyStatistics>(`/nav/statistics${params}`)
  },
}
