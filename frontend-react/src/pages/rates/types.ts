export interface EditableRate {
  currencyId: number
  currencyCode: string
  currencyName: string
  /** FK04 (FR-4): a currency tábla megjelenítési sorrendje — a sorok ez alapján rendeződnek. */
  displayOrder?: number | null
  officialRate: number | null
  buyRate: string
  sellRate: string
  limit1BuyRate: string
  limit1SellRate: string
  limit2BuyRate: string
  limit2SellRate: string
  limit3BuyRate: string
  limit3SellRate: string
  hasRate: boolean
  modified: boolean
}

export function parseNum(val: string): number {
  return parseFloat(val.replace(',', '.')) || 0
}

export function fmtRate(val: number | null | undefined, decimals = 4): string {
  if (val == null || val === 0) return ''
  return val.toFixed(decimals).replace('.', ',')
}

export function fmtAmount(val: number | null | undefined): string {
  if (val == null || val === 0) return ''
  return Math.round(val).toLocaleString('hu-HU')
}
