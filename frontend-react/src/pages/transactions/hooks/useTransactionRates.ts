import { useState, useEffect } from 'react'
import { exchangeRateApi } from '../../../services/api/index'
import type { ExchangeRate } from '../../../services/api/index'
import {
  getElectronCachedRates,
  isElectronQueueAvailable,
  mapCachedRatesToExchangeRates,
} from '../../../utils/electronTransactions'

export interface CurrencyRate {
  id: string
  code: string
  name: string
  buyRate: number
  sellRate: number
  unit: number
}

function resolveUnit(rate: ExchangeRate): number {
  const candidate = (rate as ExchangeRate & { unit?: number }).unit
  return typeof candidate === 'number' && Number.isFinite(candidate) && candidate > 0
    ? candidate
    : 1
}

export function useTransactionRates() {
  const electronQueueAvailable = isElectronQueueAvailable()
  const [currencyRates, setCurrencyRates] = useState<CurrencyRate[]>([])
  const [rawExchangeRates, setRawExchangeRates] = useState<ExchangeRate[]>([])

  useEffect(() => {
    const loadRates = async () => {
      try {
        let sourceRates: ExchangeRate[] = []

        if (electronQueueAvailable) {
          const cachedRates = await getElectronCachedRates()
          if (cachedRates.length > 0) {
            sourceRates = mapCachedRatesToExchangeRates(cachedRates)
          }
        }

        if (sourceRates.length === 0) {
          sourceRates = await exchangeRateApi.list()
        }

        const mapped: CurrencyRate[] = sourceRates
          .filter((r) => r.active && r.currencyCode !== 'HUF')
          .map((r) => ({
            id: String(r.currencyId),
            code: r.currencyCode,
            name: r.currencyName,
            buyRate: r.baseBuyRate,
            sellRate: r.baseSellRate,
            unit: resolveUnit(r),
          }))
        setCurrencyRates(mapped)
        setRawExchangeRates(sourceRates)
      } catch {
        setCurrencyRates([])
        setRawExchangeRates([])
      }
    }

    void loadRates()
  }, [electronQueueAvailable])

  return { currencyRates, rawExchangeRates, electronQueueAvailable }
}
