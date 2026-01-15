/**
 * Export API - Adatok exportálása
 *
 * ÚJ moduláris API: /api/v2/export
 *
 * @since 2026-01-13
 */

import { useAuthStore } from '../../../stores/authStore'
import type { ExportTypeInfo, ExportResult } from '../types'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080'
const API_V2_PREFIX = '/api/v2'

/**
 * Authentikált fetch wrapper JSON-hoz
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
  const isoString = date.toISOString()
  return isoString.substring(0, 10)
}

/**
 * Export API
 */
export const exportApi = {
  /**
   * Elérhető export típusok lekérése
   *
   * GET /api/v2/export/types
   */
  getExportTypes: async (): Promise<ExportTypeInfo[]> => {
    return fetchWithAuth<ExportTypeInfo[]>('/export/types')
  },

  /**
   * Tranzakciók exportálása CSV-be (fájl letöltés)
   *
   * GET /api/v2/export/transactions/csv
   *
   * @param startDate Kezdő dátum
   * @param endDate Záró dátum
   */
  downloadTransactionsCsv: async (startDate: Date, endDate: Date): Promise<void> => {
    const { token, tokenType } = useAuthStore.getState()
    if (!token) throw new Error('Nincs bejelentkezve!')

    const params = `?startDate=${formatDate(startDate)}&endDate=${formatDate(endDate)}`
    const url = `${API_BASE_URL}${API_V2_PREFIX}/export/transactions/csv${params}`

    const response = await fetch(url, {
      headers: {
        Authorization: `${tokenType || 'Bearer'} ${token}`,
      },
    })

    if (!response.ok) {
      throw new Error(`Export hiba (${response.status})`)
    }

    // Fájl letöltés blob-ból
    const blob = await response.blob()
    const contentDisposition = response.headers.get('Content-Disposition')
    const fileName = contentDisposition?.match(/filename="(.+)"/)?.[1] || 'export.csv'

    const downloadUrl = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = downloadUrl
    link.download = fileName
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(downloadUrl)
  },

  /**
   * Napi riport exportálása CSV-be (fájl letöltés)
   *
   * GET /api/v2/export/daily-report/csv
   *
   * @param date Riport dátuma (opcionális)
   */
  downloadDailyReportCsv: async (date?: Date): Promise<void> => {
    const { token, tokenType } = useAuthStore.getState()
    if (!token) throw new Error('Nincs bejelentkezve!')

    const params = date ? `?date=${formatDate(date)}` : ''
    const url = `${API_BASE_URL}${API_V2_PREFIX}/export/daily-report/csv${params}`

    const response = await fetch(url, {
      headers: {
        Authorization: `${tokenType || 'Bearer'} ${token}`,
      },
    })

    if (!response.ok) {
      throw new Error(`Export hiba (${response.status})`)
    }

    const blob = await response.blob()
    const contentDisposition = response.headers.get('Content-Disposition')
    const fileName = contentDisposition?.match(/filename="(.+)"/)?.[1] || 'daily-report.csv'

    const downloadUrl = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = downloadUrl
    link.download = fileName
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(downloadUrl)
  },

  /**
   * Export info lekérése (fájl letöltése nélkül)
   *
   * GET /api/v2/export/transactions/info
   */
  getTransactionsExportInfo: async (startDate: Date, endDate: Date): Promise<ExportResult> => {
    const params = `?startDate=${formatDate(startDate)}&endDate=${formatDate(endDate)}`
    return fetchWithAuth<ExportResult>(`/export/transactions/info${params}`)
  },
}
