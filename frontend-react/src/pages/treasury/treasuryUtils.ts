/**
 * Treasury utility functions — number formatting, stock level classification
 */

/** Format number with Hungarian locale: thousand separators + 2 decimals */
export function formatAmount(value: number, decimals = 2): string {
  return value.toLocaleString('hu-HU', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  })
}

/** Format number with thousand separators, no decimals */
export function formatInteger(value: number): string {
  return value.toLocaleString('hu-HU', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  })
}

/** Format large amounts in millions (M Ft) */
export function formatMillions(value: number): string {
  if (Math.abs(value) >= 1_000_000) {
    return `${(value / 1_000_000).toFixed(1)}M Ft`
  }
  if (Math.abs(value) >= 1_000) {
    return `${(value / 1_000).toFixed(0)}k Ft`
  }
  return `${formatInteger(value)} Ft`
}

/** Stock level classification */
export type StockLevel = 'NORMAL' | 'LOW' | 'CRITICAL'

/** Default thresholds per currency (can be overridden from backend) */
const DEFAULT_THRESHOLDS: Record<string, { low: number; critical: number }> = {
  EUR: { low: 500, critical: 200 },
  USD: { low: 600, critical: 250 },
  GBP: { low: 300, critical: 100 },
  CHF: { low: 350, critical: 150 },
  CZK: { low: 5000, critical: 2000 },
  PLN: { low: 2000, critical: 800 },
  RON: { low: 2000, critical: 800 },
}

/** Classify stock level by currency and amount */
export function getStockLevel(amount: number, currencyCode: string): StockLevel {
  const thresholds = DEFAULT_THRESHOLDS[currencyCode] ?? { low: 500, critical: 200 }
  if (amount <= thresholds.critical) return 'CRITICAL'
  if (amount <= thresholds.low) return 'LOW'
  return 'NORMAL'
}

/** CSS classes for stock level badges */
export function stockLevelColor(level: StockLevel): string {
  switch (level) {
    case 'CRITICAL':
      return 'text-danger-700 font-bold'
    case 'LOW':
      return 'text-warning-700 font-semibold'
    case 'NORMAL':
      return 'text-secondary-900'
  }
}

/** Stock level indicator emoji */
export function stockLevelIcon(level: StockLevel): string {
  switch (level) {
    case 'CRITICAL':
      return '🔴'
    case 'LOW':
      return '🟡'
    case 'NORMAL':
      return '🟢'
  }
}

/** Movement type labels (Hungarian) */
export const MOVEMENT_TYPE_LABELS: Record<string, string> = {
  BANK_WITHDRAWAL: 'Bank kivét',
  BANK_DEPOSIT: 'Bank befizetés',
  TRANSFER: 'Iroda szállítás',
  VAULT_WITHDRAW: 'Bank kivét',
  VAULT_DEPOSIT: 'Bank befizetés',
  CURRENCY: 'Iroda szállítás',
  CORRECTION: 'Korrekció',
}

/** Movement status labels (Hungarian) */
export const MOVEMENT_STATUS_LABELS: Record<string, string> = {
  PENDING: 'Függő',
  APPROVED: 'Jóváhagyva',
  COMPLETED: 'Teljesítve',
  RECEIVED: 'Átvéve',
  REJECTED: 'Elutasítva',
  IN_TRANSIT: 'Szállítás alatt',
  CANCELLED: 'Visszavonva',
}

/** Today's date as YYYY-MM-DD */
export function todayISO(): string {
  return new Date().toISOString().slice(0, 10)
}

/** Format datetime to Hungarian locale */
export function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString('hu-HU', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  })
}

/** Format time only */
export function formatTime(iso: string): string {
  return new Date(iso).toLocaleTimeString('hu-HU', {
    hour: '2-digit',
    minute: '2-digit',
  })
}

/** Currency code → display color class */
export function currencyColorClass(code: string): string {
  const map: Record<string, string> = {
    HUF: 'text-currency-huf',
    EUR: 'text-currency-eur',
    USD: 'text-currency-usd',
    GBP: 'text-currency-gbp',
    CHF: 'text-currency-chf',
    CZK: 'text-currency-czk',
    PLN: 'text-currency-pln',
    RON: 'text-currency-ron',
  }
  return map[code] ?? 'text-secondary-700'
}

/**
 * FKH-037 FR-5: a Mozgások előzmény TYPE cellája a bejelentkezett értéktár szemszögéből
 * mutat irányt. Ha egyik vég sem a saját fiók, a technikai típuscímke marad (TBD-2).
 *
 * Önátadás-él (fromBranchId === toBranchId === workerBranchId): a szabályok sorrendje
 * szerint 'Átadás' nyer — ez szándékos, nem hiba.
 */
export function movementDirectionLabel(
  movement: { fromBranchId?: string | null; toBranchId?: string | null },
  workerBranchId?: string | null,
): 'Átadás' | 'Átvétel' | null {
  if (!workerBranchId) return null
  if (movement.fromBranchId === workerBranchId) return 'Átadás'
  if (movement.toBranchId === workerBranchId) return 'Átvétel'
  return null
}
