/**
 * NAV Integration típusdefiníciók
 *
 * @since 2026-01-13
 */

/**
 * NAV Pénztárgép státusz
 */
export interface NavCashRegisterStatus {
  apNumber: string
  status: string
  online: boolean
  lastSync?: string
  pendingReceipts: number
  errorMessage?: string
  responseTimeMs?: number
}

/**
 * NAV nyugta
 */
export interface NavReceipt {
  id: number
  receiptNumber: string
  apNumber: string
  receiptType: 'NORMAL' | 'STORNO' | 'COPY'
  totalAmount: number
  currency: string
  createdAt: string
  sentToNav: boolean
  navAcknowledgedAt?: string
  navTransactionId?: string
  errorMessage?: string
}

/**
 * NAV szinkronizáció eredmény
 */
export interface NavSyncResult {
  success: boolean
  syncedAt: string
  sentCount: number
  successCount: number
  failedCount: number
  syncedReceiptIds: number[]
  failedReceiptIds: number[]
  errorMessage?: string
  errors?: string[]
}

/**
 * NAV kapcsolat teszt eredmény
 */
export interface NavConnectionTest {
  connected: boolean
  testedAt: string
  responseTimeMs: number
  navServerStatus: string
  certificateValid: boolean
  certificateExpiry: string
}

/**
 * NAV napi statisztika
 */
export interface NavDailyStatistics {
  date: string
  totalReceipts: number
  successfulSyncs: number
  failedSyncs: number
  totalAmount: number
  stornoCount: number
  averageResponseTimeMs: number
  generatedAt: string
}
