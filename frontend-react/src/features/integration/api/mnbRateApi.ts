/**
 * MNB Rate API - MNB árfolyamok lekérése
 *
 * ÚJ moduláris API: /api/v2/mnb-rates
 *
 * @since 2026-01-13
 */

import { useAuthStore } from '../../../stores/authStore'
import type { MnbRateDto, MnbRatesResponse, ComparisonReport } from '../types'

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
 * MNB Rate API
 */
export const mnbRateApi = {
  /**
   * Aktuális MNB árfolyamok lekérése
   *
   * GET /api/v2/mnb-rates/current
   */
  getCurrentRates: async (): Promise<MnbRatesResponse> => {
    return fetchWithAuth<MnbRatesResponse>('/mnb-rates/current')
  },

  /**
   * MNB árfolyamok adott dátumra
   *
   * GET /api/v2/mnb-rates/date/{date}
   */
  getRatesForDate: async (date: Date): Promise<MnbRatesResponse> => {
    return fetchWithAuth<MnbRatesResponse>(`/mnb-rates/date/${formatDate(date)}`)
  },

  /**
   * Egyedi valuta árfolyam
   *
   * GET /api/v2/mnb-rates/currency/{code}
   */
  getRateForCurrency: async (code: string, date?: Date): Promise<MnbRateDto> => {
    const params = date ? `?date=${formatDate(date)}` : ''
    return fetchWithAuth<MnbRateDto>(`/mnb-rates/currency/${code}${params}`)
  },

  /**
   * Árfolyam történet
   *
   * GET /api/v2/mnb-rates/history/{code}
   */
  getRateHistory: async (
    code: string,
    startDate: Date,
    endDate: Date
  ): Promise<MnbRateDto[]> => {
    const params = `?startDate=${formatDate(startDate)}&endDate=${formatDate(endDate)}`
    return fetchWithAuth<MnbRateDto[]>(`/mnb-rates/history/${code}${params}`)
  },

  /**
   * Összehasonlítás belső árfolyamokkal
   *
   * GET /api/v2/mnb-rates/compare
   */
  compareWithInternalRates: async (date?: Date): Promise<ComparisonReport> => {
    const params = date ? `?date=${formatDate(date)}` : ''
    return fetchWithAuth<ComparisonReport>(`/mnb-rates/compare${params}`)
  },
}
