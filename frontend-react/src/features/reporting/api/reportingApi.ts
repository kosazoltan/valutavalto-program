/**
 * Reporting API - Riportok és statisztikák
 *
 * ÚJ moduláris API: /api/v2/reporting
 *
 * FONTOS:
 * - Ez egy ÚJ API modul, NEM módosítja a meglévő api.ts fájlt!
 * - Használja az authStore-t a token kezeléshez
 *
 * @since 2026-01-13
 */

import { useAuthStore } from '../../../stores/authStore'
import type {
  DailyReport,
  DailySummary,
  PeriodReport,
  CurrencyTurnover,
  WorkerStats,
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
 * Dátum formázása API híváshoz
 */
function formatDate(date: Date): string {
  return date.toISOString().substring(0, 10)
}

/**
 * Reporting API
 */
export const reportingApi = {
  /**
   * Napi riport lekérése
   *
   * GET /api/v2/reporting/daily
   *
   * @param date Riport dátuma (opcionális, alapértelmezett: ma)
   */
  getDailyReport: async (date?: Date): Promise<DailyReport> => {
    const params = date ? `?date=${formatDate(date)}` : ''
    return fetchWithAuth<DailyReport>(`/reporting/daily${params}`)
  },

  /**
   * Napi összesítés lekérése
   *
   * GET /api/v2/reporting/daily-summary
   *
   * @param date Riport dátuma (opcionális, alapértelmezett: ma)
   */
  getDailySummary: async (date?: Date): Promise<DailySummary> => {
    const params = date ? `?date=${formatDate(date)}` : ''
    return fetchWithAuth<DailySummary>(`/reporting/daily-summary${params}`)
  },

  /**
   * Időszaki riport lekérése
   *
   * GET /api/v2/reporting/period
   *
   * @param startDate Kezdő dátum
   * @param endDate Záró dátum
   */
  getPeriodReport: async (startDate: Date, endDate: Date): Promise<PeriodReport> => {
    const params = `?startDate=${formatDate(startDate)}&endDate=${formatDate(endDate)}`
    return fetchWithAuth<PeriodReport>(`/reporting/period${params}`)
  },

  /**
   * Valuta forgalom riport lekérése
   *
   * GET /api/v2/reporting/currency-turnover
   *
   * @param startDate Kezdő dátum
   * @param endDate Záró dátum
   */
  getCurrencyTurnover: async (startDate: Date, endDate: Date): Promise<CurrencyTurnover> => {
    const params = `?startDate=${formatDate(startDate)}&endDate=${formatDate(endDate)}`
    return fetchWithAuth<CurrencyTurnover>(`/reporting/currency-turnover${params}`)
  },

  /**
   * Pénztáros statisztika lekérése
   *
   * GET /api/v2/reporting/worker-stats
   *
   * @param startDate Kezdő dátum
   * @param endDate Záró dátum
   */
  getWorkerStats: async (startDate: Date, endDate: Date): Promise<WorkerStats> => {
    const params = `?startDate=${formatDate(startDate)}&endDate=${formatDate(endDate)}`
    return fetchWithAuth<WorkerStats>(`/reporting/worker-stats${params}`)
  },
}
