import type { ExchangeRate } from '../services/api/exchange-rates'

interface BandResult {
  tierRate: number
  minRate: number
  maxRate: number
  tierName: string
}

export function getBandForAmount(
  rate: ExchangeRate,
  mode: 'buy' | 'sell',
  hufAmount: number,
): BandResult {
  const base = mode === 'buy' ? rate.baseBuyRate : rate.baseSellRate

  let tierRate = base
  let tierName = 'alap'

  if (rate.limit3Amount != null && hufAmount >= rate.limit3Amount) {
    const lr = mode === 'buy' ? rate.limit3BuyRate : rate.limit3SellRate
    if (lr != null) {
      tierRate = lr
      tierName = 'limit3'
    }
  } else if (rate.limit2Amount != null && hufAmount >= rate.limit2Amount) {
    const lr = mode === 'buy' ? rate.limit2BuyRate : rate.limit2SellRate
    if (lr != null) {
      tierRate = lr
      tierName = 'limit2'
    }
  } else if (rate.limit1Amount != null && hufAmount >= rate.limit1Amount) {
    const lr = mode === 'buy' ? rate.limit1BuyRate : rate.limit1SellRate
    if (lr != null) {
      tierRate = lr
      tierName = 'limit1'
    }
  }

  if (mode === 'buy') {
    return { tierRate, minRate: base, maxRate: tierRate, tierName }
  }
  return { tierRate, minRate: tierRate, maxRate: base, tierName }
}

export function isWithinBand(
  rate: ExchangeRate,
  customRate: number,
  mode: 'buy' | 'sell',
  hufAmount: number,
): boolean {
  const band = getBandForAmount(rate, mode, hufAmount)
  return customRate >= band.minRate && customRate <= band.maxRate
}

export function isWithinHardLimit(
  customRate: number,
  officialRate: number | undefined | null,
  mode: 'buy' | 'sell',
): boolean {
  if (officialRate == null || officialRate <= 0) return true
  if (mode === 'buy') return customRate <= officialRate
  return customRate >= officialRate
}

export function getHardLimitMessage(mode: 'buy' | 'sell', officialRate: number): string {
  if (mode === 'buy') {
    return `Vételi árfolyam nem lehet magasabb az elszámoló árfolyamnál (${officialRate.toFixed(2)}).`
  }
  return `Eladási árfolyam nem lehet alacsonyabb az elszámoló árfolyamnál (${officialRate.toFixed(2)}).`
}
