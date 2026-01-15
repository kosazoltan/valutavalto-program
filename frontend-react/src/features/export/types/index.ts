/**
 * Export modul típusok
 *
 * @since 2026-01-13
 */

/**
 * Export típus információ
 */
export interface ExportTypeInfo {
  code: string
  name: string
  formats: string[]
}

/**
 * Export kérés
 */
export interface ExportRequest {
  exportType: string
  format: string
  startDate: string
  endDate: string
  date?: string
  currencyCode?: string
  workerId?: number
}

/**
 * Export eredmény
 */
export interface ExportResult {
  exportId: string
  fileName: string
  contentType: string
  fileSize: number
  recordCount: number
  generatedAt: string
  downloadUrl?: string
}
