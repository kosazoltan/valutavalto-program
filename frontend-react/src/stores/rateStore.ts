import { create } from 'zustand'
import { api } from '../services/api/index'
import type { ExchangeRate } from '../services/api/index'

/**
 * Limit szintű árfolyam feloldó — közös logika vételi és eladási irányhoz.
 * Magasabb összeg → magasabb limit szint → kedvezőbb ráta.
 * Legacy: LIMIT3 > LIMIT2 > LIMIT1 > ALAPVETEL/ALAPELADAS
 */
const LIMIT_TIERS = [3, 2, 1] as const

/** Type-safe limit field accessor to avoid `as keyof` casts. */
function getLimitField(
  rate: ExchangeRate,
  tier: 1 | 2 | 3,
  field: 'Amount' | 'BuyRate' | 'SellRate',
): number | undefined {
  if (tier === 3) {
    if (field === 'Amount') return rate.limit3Amount
    if (field === 'BuyRate') return rate.limit3BuyRate
    return rate.limit3SellRate
  }
  if (tier === 2) {
    if (field === 'Amount') return rate.limit2Amount
    if (field === 'BuyRate') return rate.limit2BuyRate
    return rate.limit2SellRate
  }
  if (field === 'Amount') return rate.limit1Amount
  if (field === 'BuyRate') return rate.limit1BuyRate
  return rate.limit1SellRate
}

function resolveEffectiveRate(
  rate: ExchangeRate,
  foreignAmount: number,
  side: 'buy' | 'sell',
): number {
  const rateField = side === 'buy' ? 'BuyRate' : 'SellRate'
  for (const tier of LIMIT_TIERS) {
    const amount = getLimitField(rate, tier, 'Amount')
    const tierRate = getLimitField(rate, tier, rateField)
    if (amount != null && tierRate != null && foreignAmount >= amount) {
      return tierRate
    }
  }
  return side === 'buy' ? rate.baseBuyRate : rate.baseSellRate
}

/**
 * WebSocket publish payload — az applyPublishedRates() fogadja.
 * A mezőneveket a backend RateUpdateMessage DTO-jához igazítjuk.
 */
export type RateUpdateEntry = {
  currencyCode?: string
  buyRate: number | string
  sellRate: number | string
  officialRate?: number | string | null
  limit1Amount?: number | string | null
  limit1BuyRate?: number | string | null
  limit1SellRate?: number | string | null
  limit2Amount?: number | string | null
  limit2BuyRate?: number | string | null
  limit2SellRate?: number | string | null
  limit3Amount?: number | string | null
  limit3BuyRate?: number | string | null
  limit3SellRate?: number | string | null
}

interface RateState {
  rates: ExchangeRate[]
  lastUpdate: string | null
  isLoading: boolean
  error: string | null
  autoRefreshIntervalId: ReturnType<typeof setInterval> | null

  fetchRates: () => Promise<void>
  /**
   * WebSocket által küldött azonnali árfolyam frissítés alkalmazása.
   * Csak a megváltozott devizákat frissíti, a többi érintetlen marad.
   */
  applyPublishedRates: (updates: RateUpdateEntry[]) => void
  getRate: (currencyCode: string) => ExchangeRate | undefined
  getBuyRate: (currencyCode: string) => number
  getSellRate: (currencyCode: string) => number
  /**
   * Limit-aware vételi árfolyam — a devizaösszeg alapján a megfelelő limit szintet választja.
   * Ha az összeg eléri a limit1/2/3 küszöböt, az ahhoz tartozó kedvezőbb rátát adja vissza.
   */
  getEffectiveBuyRate: (currencyCode: string, foreignAmount: number) => number
  /**
   * Limit-aware eladási árfolyam — a devizaösszeg alapján a megfelelő limit szintet választja.
   */
  getEffectiveSellRate: (currencyCode: string, foreignAmount: number) => number
  startAutoRefresh: (intervalMs?: number) => void
  stopAutoRefresh: () => void
}

/**
 * Árfolyam store — admin és Electron kliens közös árfolyam kezelése.
 *
 * Legacy: a régi rendszerben az értéktár FTP-n küldte ki az árfolyamokat
 * (NR*.DAT fájlok) és a pénztár letöltötte + a helyi ARFOLYAM táblába
 * mentette. Az új rendszerben REST API-n keresztül kéri le és
 * WebSocket STOMP-on kapja az azonnali frissítéseket.
 */
let _fetchSeq = 0

export const useRateStore = create<RateState>()((set, get) => ({
  rates: [],
  lastUpdate: null,
  isLoading: false,
  error: null,
  autoRefreshIntervalId: null,

  fetchRates: async () => {
    const seq = ++_fetchSeq
    set({ isLoading: true, error: null })
    try {
      const response = await api.get<ExchangeRate[]>('/exchange-rates')
      if (seq !== _fetchSeq) return
      set({
        rates: response.data,
        lastUpdate: new Date().toISOString(),
        isLoading: false,
      })
    } catch (err) {
      if (seq !== _fetchSeq) return
      const message = err instanceof Error ? err.message : 'Árfolyam lekérési hiba'
      set({ error: message, isLoading: false })
    }
  },

  applyPublishedRates: (updates) => {
    if (!updates.length) {
      return
    }

    const now = new Date().toISOString()
    const currentRates = get().rates
    const nextByCode = new Map(currentRates.map((rate) => [rate.currencyCode, rate]))

    const toOptNum = (v: number | string | null | undefined): number | null => {
      if (v == null) return null
      const n = Number(v)
      return Number.isFinite(n) ? n : null
    }

    for (const update of updates) {
      const code = update.currencyCode
      if (!code) {
        continue
      }

      const current = nextByCode.get(code)
      const parsedBuy = Number(update.buyRate)
      const parsedSell = Number(update.sellRate)

      const baseBuyRate = Number.isFinite(parsedBuy) ? parsedBuy : (current?.baseBuyRate ?? 0)
      const baseSellRate = Number.isFinite(parsedSell) ? parsedSell : (current?.baseSellRate ?? 0)

      // For brand-new currencies arriving via WebSocket (not yet in the store),
      // scaffold the required ExchangeRate fields with safe defaults. Required
      // fields like id/currencyId/validDate are unknown at this point — they
      // will be reconciled on the next fetchRates() call.
      const scaffold: ExchangeRate = current ?? {
        id: 0,
        currencyId: 0,
        currencyCode: code,
        currencyName: code,
        validDate: now.slice(0, 10),
        validTime: now.slice(11, 19),
        baseBuyRate: 0,
        baseSellRate: 0,
        active: true,
        createdAt: now,
      }

      nextByCode.set(code, {
        ...scaffold,
        currencyCode: code,
        baseBuyRate,
        baseSellRate,
        createdAt: now,
        officialRate: toOptNum(update.officialRate) ?? current?.officialRate,
        limit1Amount: toOptNum(update.limit1Amount) ?? current?.limit1Amount,
        limit1BuyRate: toOptNum(update.limit1BuyRate) ?? current?.limit1BuyRate,
        limit1SellRate: toOptNum(update.limit1SellRate) ?? current?.limit1SellRate,
        limit2Amount: toOptNum(update.limit2Amount) ?? current?.limit2Amount,
        limit2BuyRate: toOptNum(update.limit2BuyRate) ?? current?.limit2BuyRate,
        limit2SellRate: toOptNum(update.limit2SellRate) ?? current?.limit2SellRate,
        limit3Amount: toOptNum(update.limit3Amount) ?? current?.limit3Amount,
        limit3BuyRate: toOptNum(update.limit3BuyRate) ?? current?.limit3BuyRate,
        limit3SellRate: toOptNum(update.limit3SellRate) ?? current?.limit3SellRate,
      })
    }

    // Preserve original order, append new currencies at the end
    const nextRates: ExchangeRate[] = []
    for (const rate of currentRates) {
      const updated = nextByCode.get(rate.currencyCode)
      if (updated) {
        nextRates.push(updated)
        nextByCode.delete(rate.currencyCode)
      }
    }
    for (const extra of nextByCode.values()) {
      nextRates.push(extra)
    }

    set({ rates: nextRates, lastUpdate: now, error: null })
  },

  getRate: (currencyCode) => {
    return get().rates.find((r) => r.currencyCode === currencyCode)
  },

  getBuyRate: (currencyCode) => {
    const rate = get().getRate(currencyCode)
    return rate?.baseBuyRate ?? 0
  },

  getSellRate: (currencyCode) => {
    const rate = get().getRate(currencyCode)
    return rate?.baseSellRate ?? 0
  },

  getEffectiveBuyRate: (currencyCode, foreignAmount) => {
    const rate = get().getRate(currencyCode)
    if (!rate) return 0
    return resolveEffectiveRate(rate, foreignAmount, 'buy')
  },

  getEffectiveSellRate: (currencyCode, foreignAmount) => {
    const rate = get().getRate(currencyCode)
    if (!rate) return 0
    return resolveEffectiveRate(rate, foreignAmount, 'sell')
  },

  startAutoRefresh: (intervalMs = 60_000) => {
    const existing = get().autoRefreshIntervalId
    if (existing) clearInterval(existing)

    // Első lekérés azonnal
    void get().fetchRates()

    const id = setInterval(() => {
      void get().fetchRates()
    }, intervalMs)

    set({ autoRefreshIntervalId: id })
  },

  stopAutoRefresh: () => {
    const id = get().autoRefreshIntervalId
    if (id) {
      clearInterval(id)
      set({ autoRefreshIntervalId: null })
    }
  },
}))
