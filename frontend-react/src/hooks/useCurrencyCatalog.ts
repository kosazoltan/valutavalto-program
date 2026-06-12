import { useCallback, useEffect, useRef, useState } from 'react'
import { currencyApi } from '../services/api/exchange-rates'
import type { Currency } from '../services/api/exchange-rates'
import { logger } from '../utils/logger'

/**
 * FK04 — Valuta-katalógus hook: a Főlap (MainRateSheetPage) és a munkacsoportok
 * (RateCreationPage) valutalistájának EGYETLEN frontend-oldali forrása.
 *
 * Absztrakciós réteg (NFR-3): a forrás (jelenleg `GET /api/v1/currencies/all`)
 * kizárólag itt cserélhető — a fogyasztó oldalak kódját nem kell módosítani.
 */

/**
 * FK04 / FR-9 (TBD-1 eldöntve): a kereszt-alap térkép a korábbi
 * MainRateSheetPage.DEFAULT_CURRENCIES[].crossBase értékeinek 1:1 átemelése.
 * NEM kerül a DB-be (kontextus-dokumentum §2 OUT) — csak a Főlap G/H oszlopának
 * számításához kell. `null` = közvetlen árfolyam (nem kereszt).
 */
export const CROSS_BASE_MAP: Record<string, 'EUR' | 'USD' | null> = {
  EUR: null, // főváluta
  USD: null, // főváluta
  GBP: null, // főváluta
  CHF: null, // főváluta
  AUD: null, // OTP-ből (B oszlop)
  CAD: null, // OTP-ből (B oszlop)
  JPY: null, // 3 tizedes
  EUA: null, // euró érme — vétel külön, eladás = EUR eladási
  CZK: 'EUR',
  PLN: 'EUR',
  RON: 'EUR',
  RSD: 'EUR',
  TRY: 'EUR',
  BAM: 'EUR',
  ILS: 'USD',
  UAH: 'USD',
  RUB: 'USD',
  CNY: 'USD',
  THB: 'USD',
  BRL: 'USD',
  MXN: 'USD',
  NZD: 'USD',
}

/** Kereszt-alap lekérés; a térképen kívüli (újonnan felvett) valuta = közvetlen árfolyam. */
export function getCrossBase(code: string): 'EUR' | 'USD' | null {
  return CROSS_BASE_MAP[code] ?? null
}

/**
 * A katalógus-szűrés tiszta (tesztelhető) magja: aktív valuták + EUA, HUF nélkül,
 * displayOrder szerint rendezve (azonos sorrendnél kód-ABC a determinizmusért).
 *
 * - EUA: szándékosan inaktív törzsadat (V298), hogy a pénztár/készlet/címletezés
 *   `findByActiveTrue` felületei ne lássák — az árfolyamkészítőn viszont KELL (FR-1).
 * - HUF: bázisdeviza (display_order=0), a Főlapon nincs saját sora.
 */
export function selectCatalogCurrencies(all: Currency[]): Currency[] {
  return all
    .filter(c => c.code !== 'HUF' && (c.active || c.code === 'EUA'))
    .sort((a, b) => {
      const ia = a.displayOrder ?? Number.MAX_SAFE_INTEGER
      const ib = b.displayOrder ?? Number.MAX_SAFE_INTEGER
      if (ia === ib) return a.code.localeCompare(b.code)
      return ia - ib
    })
}

export interface CurrencyCatalog {
  /** Szűrt + rendezett katalógus: aktív ∪ EUA, HUF nélkül, displayOrder szerint. */
  currencies: Currency[]
  /** A teljes (aktív+inaktív) törzslista — pl. kód→id térképhez, inaktív-szűréshez. */
  all: Currency[]
  loading: boolean
  error: Error | null
  /** Újratöltés (pl. a Valutakezelő módosítása után). */
  reload: () => void
}

export function useCurrencyCatalog(): CurrencyCatalog {
  const [all, setAll] = useState<Currency[]>([])
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)
  const [reloadCounter, setReloadCounter] = useState(0)
  const mountedRef = useRef(true)

  useEffect(() => {
    mountedRef.current = true
    setLoading(true)
    currencyApi.getAll()
      .then(data => {
        if (!mountedRef.current) return
        setAll(data)
        setCurrencies(selectCatalogCurrencies(data))
        setError(null)
      })
      .catch((err: unknown) => {
        if (!mountedRef.current) return
        logger.error('useCurrencyCatalog', 'currencies/all betöltés sikertelen', err)
        setError(err instanceof Error ? err : new Error(String(err)))
        setAll([])
        setCurrencies([])
      })
      .finally(() => {
        if (mountedRef.current) setLoading(false)
      })
    return () => { mountedRef.current = false }
  }, [reloadCounter])

  const reload = useCallback(() => setReloadCounter(n => n + 1), [])

  return { currencies, all, loading, error, reload }
}
