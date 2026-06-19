import { api } from './client'

export type CalculatorDirection = 'BUY' | 'SELL'

export interface CurrencyConvertRequest {
  fromCurrency: string
  toCurrency: string
  amount: number
  direction: CalculatorDirection
}

export interface CurrencyCalculationResult {
  fromCurrency: string
  toCurrency: string
  fromAmount: number
  toAmount: number
  appliedRate: number
  spread: number
  commission: number
  direction: CalculatorDirection
  roundingInfo?: string | null
}

export interface CurrencyReverseResult {
  currency: string
  hufAmount: number
  foreignAmount: number
}

export type CurrencyExchangeMatrix = Record<string, Record<string, number>>

export const currencyCalculatorApi = {
  convert: async (request: CurrencyConvertRequest): Promise<CurrencyCalculationResult> =>
    (await api.post<CurrencyCalculationResult>('/calculator/convert', request)).data,

  reverse: async (request: { currency: string; hufAmount: number }): Promise<CurrencyReverseResult> =>
    (await api.post<CurrencyReverseResult>('/calculator/reverse', request)).data,

  matrix: async (): Promise<CurrencyExchangeMatrix> =>
    (await api.get<CurrencyExchangeMatrix>('/calculator/matrix')).data,
}
