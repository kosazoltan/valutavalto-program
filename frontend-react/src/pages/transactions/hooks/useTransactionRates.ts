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

export function useTransactionRates() {
  const electronQueueAvailable = isElectronQueueAvailable()
  const [currencyRates, setCurrencyRates] = useState<CurrencyRate[]>([])

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
            unit: 1,
          }))
        setCurrencyRates(mapped)
      } catch {
        setCurrencyRates([])
      }
    }

    void loadRates()
  }, [electronQueueAvailable])

  return { currencyRates, electronQueueAvailable }
}
