/**
 * Integration modul típusdefiníciók
 *
 * @since 2026-01-13
 */

/**
 * MNB árfolyam DTO
 */
export interface MnbRateDto {
  currencyCode: string
  currencyName: string
  rate: number
  unit: number
  rateDate: string
  previousRate?: number
  changePercent?: number
  fetchedAt?: string
}

/**
 * MNB árfolyamok válasz
 */
export interface MnbRatesResponse {
  rateDate: string
  rates: MnbRateDto[]
  currencyCount: number
  source: string
  status: string
  fetchedAt: string
  fromCache: boolean
}

/**
 * Árfolyam összehasonlítás
 */
export interface RateComparison {
  currencyCode: string
  mnbRate: number
  internalBuyRate: number
  internalSellRate: number
  buySpread: number
  sellSpread: number
}

/**
 * Összehasonlítási riport
 */
export interface ComparisonReport {
  date: string
  comparisons: RateComparison[]
  comparedCount: number
  generatedAt: string
}
