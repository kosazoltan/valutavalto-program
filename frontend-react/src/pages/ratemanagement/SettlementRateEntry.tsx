import React, { useState, useEffect, useCallback } from 'react'
import { RefreshCw, Send, AlertTriangle, ChevronDown, ChevronRight } from 'lucide-react'
import { api } from '../../services/api'

/**
 * Arfolyam rogzites — Legacy: arfdata.dat adatbevitel.
 *
 * A foertektaros itt rogziti az osszes valuta arfolyamat egyszerre:
 * - Alap veteli / eladasi arfolyam
 * - Hivatalos (MNB/elszamolasi) arfolyam
 * - Limit szintek (1-3) osszegekkel es arfolyamokkal
 *
 * Mentes utan a "Publikalas" gombbal az osszes fiok megkapja az uj arfolyamokat.
 */

interface CurrencyInfo {
  id: number
  code: string
  name: string
  displayOrder: number
}

interface ExchangeRateData {
  id?: number
  currencyId: number
  currencyCode?: string
  currencyName?: string
  baseBuyRate: string
  baseSellRate: string
  officialRate: string
  limit1Amount: string
  limit1BuyRate: string
  limit1SellRate: string
  limit2Amount: string
  limit2BuyRate: string
  limit2SellRate: string
  limit3Amount: string
  limit3BuyRate: string
  limit3SellRate: string
}

interface CurrentRateFromApi {
  id: number
  currencyId: number
  currencyCode: string
  currencyName: string
  baseBuyRate: number | null
  baseSellRate: number | null
  officialRate: number | null
  limit1Amount: number | null
  limit1BuyRate: number | null
  limit1SellRate: number | null
  limit2Amount: number | null
  limit2BuyRate: number | null
  limit2SellRate: number | null
  limit3Amount: number | null
  limit3BuyRate: number | null
  limit3SellRate: number | null
}

function toStr(val: number | null | undefined): string {
  return val != null ? String(val) : ''
}

function toNum(val: string): number | null {
  const trimmed = val.trim()
  if (!trimmed) return null
  const num = parseFloat(trimmed)
  return isNaN(num) ? null : num
}

export default function SettlementRateEntry() {
  const [rates, setRates] = useState<ExchangeRateData[]>([])
  const [_currencies, setCurrencies] = useState<CurrencyInfo[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [expandedLimits, setExpandedLimits] = useState<Set<number>>(new Set())

  const fetchData = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      // Parallel fetch: currencies + current rates
      const [currRes, rateRes] = await Promise.all([
        api.get<CurrencyInfo[]>('/currencies'),
        api.get<CurrentRateFromApi[]>('/exchange-rates/current'),
      ])

      const activeCurrencies = currRes.data
        .filter((c: CurrencyInfo) => c.code !== 'HUF')
        .sort((a: CurrencyInfo, b: CurrencyInfo) => (a.displayOrder ?? 100) - (b.displayOrder ?? 100))
      setCurrencies(activeCurrencies)

      // Build rate map from current rates
      const rateMap = new Map<number, CurrentRateFromApi>()
      for (const r of rateRes.data) {
        rateMap.set(r.currencyId, r)
      }

      // Create rate entry for each active currency, pre-filled from current rates
      const rateEntries: ExchangeRateData[] = activeCurrencies.map((c: CurrencyInfo) => {
        const existing = rateMap.get(c.id)
        return {
          currencyId: c.id,
          currencyCode: c.code,
          currencyName: c.name,
          baseBuyRate: existing ? toStr(existing.baseBuyRate) : '',
          baseSellRate: existing ? toStr(existing.baseSellRate) : '',
          officialRate: existing ? toStr(existing.officialRate) : '',
          limit1Amount: existing ? toStr(existing.limit1Amount) : '',
          limit1BuyRate: existing ? toStr(existing.limit1BuyRate) : '',
          limit1SellRate: existing ? toStr(existing.limit1SellRate) : '',
          limit2Amount: existing ? toStr(existing.limit2Amount) : '',
          limit2BuyRate: existing ? toStr(existing.limit2BuyRate) : '',
          limit2SellRate: existing ? toStr(existing.limit2SellRate) : '',
          limit3Amount: existing ? toStr(existing.limit3Amount) : '',
          limit3BuyRate: existing ? toStr(existing.limit3BuyRate) : '',
          limit3SellRate: existing ? toStr(existing.limit3SellRate) : '',
        }
      })

      setRates(rateEntries)
    } catch (err) {
      console.error('Failed to load data:', err)
      setError('Arfolyam adatok betoltese sikertelen')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void fetchData()
  }, [fetchData])

  type EditableField = Exclude<keyof ExchangeRateData, 'id' | 'currencyId' | 'currencyCode' | 'currencyName'>

  const updateRate = (index: number, field: EditableField, value: string) => {
    setRates(prev => prev.map((r, i) => {
      if (i !== index) return r
      const copy = { ...r }
      copy[field] = value
      return copy
    }))
  }

  const toggleLimits = (currencyId: number) => {
    setExpandedLimits(prev => {
      const next = new Set(prev)
      if (next.has(currencyId)) {
        next.delete(currencyId)
      } else {
        next.add(currencyId)
      }
      return next
    })
  }

  const hasLimits = (rate: ExchangeRateData): boolean => {
    return !!(rate.limit1Amount || rate.limit2Amount || rate.limit3Amount)
  }

  /**
   * Publikalas — elkesziti az arfolyamokat az osszes fiokba.
   * Legacy: MNBArfKikuldo
   */
  const publishRates = async () => {
    setError(null)
    setSuccess(null)

    // Validalas: legalabb 1 valutahoz kell arfolyam
    const validRates = rates.filter(r => r.baseBuyRate.trim() && r.baseSellRate.trim())
    if (validRates.length === 0) {
      setError('Legalabb egy valutahoz rogzitsen veteli es eladasi arfolyamot!')
      return
    }

    // Validalas: eladasi > veteli
    for (const r of validRates) {
      const buy = parseFloat(r.baseBuyRate)
      const sell = parseFloat(r.baseSellRate)
      if (isNaN(buy) || isNaN(sell)) {
        setError(`${r.currencyCode}: ervenytelen arfolyam ertek!`)
        return
      }
      if (sell <= buy) {
        setError(`${r.currencyCode}: az eladasi arfolyamnak (${sell}) nagyobbnak kell lennie a vetelinel (${buy})!`)
        return
      }
    }

    setSaving(true)
    try {
      const payload = {
        groupId: null,
        rates: validRates.map(r => ({
          currencyId: r.currencyId,
          buyRate: toNum(r.baseBuyRate),
          sellRate: toNum(r.baseSellRate),
          officialRate: toNum(r.officialRate),
          limit1Amount: toNum(r.limit1Amount),
          limit1BuyRate: toNum(r.limit1BuyRate),
          limit1SellRate: toNum(r.limit1SellRate),
          limit2Amount: toNum(r.limit2Amount),
          limit2BuyRate: toNum(r.limit2BuyRate),
          limit2SellRate: toNum(r.limit2SellRate),
          limit3Amount: toNum(r.limit3Amount),
          limit3BuyRate: toNum(r.limit3BuyRate),
          limit3SellRate: toNum(r.limit3SellRate),
        })),
      }

      await api.post('/rate-creation/publish-group-rate', payload)
      setSuccess(`Sikeres publikalas! ${validRates.length} valuta arfolyama frissiteve.`)

      // Reload data to show updated values
      await fetchData()
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } }
      const msg = axiosErr?.response?.data?.message || 'Publikalas sikertelen'
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <RefreshCw className="h-6 w-6 animate-spin text-muted-foreground" />
        <span className="ml-2 text-muted-foreground">Arfolyamok betoltese...</span>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          Rogzitse az arfolyamokat az osszes aktiv valutahoz. A "Publikalas" gombbal az arfolyamok azonnal elove valnak.
        </p>
        <div className="flex gap-2">
          <button
            className="inline-flex items-center justify-center rounded-md border px-3 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
            onClick={fetchData}
            disabled={saving}
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            Frissites
          </button>
          <button
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
            onClick={publishRates}
            disabled={saving}
          >
            {saving ? (
              <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
            ) : (
              <Send className="h-4 w-4 mr-2" />
            )}
            {saving ? 'Publikalas...' : 'Publikalas'}
          </button>
        </div>
      </div>

      {/* Messages */}
      {error && (
        <div className="rounded-md bg-destructive/10 border border-destructive/20 p-3 text-sm text-destructive flex items-center gap-2">
          <AlertTriangle className="h-4 w-4 flex-shrink-0" />
          {error}
        </div>
      )}
      {success && (
        <div className="rounded-md bg-green-500/10 border border-green-500/20 p-3 text-sm text-green-700 dark:text-green-400">
          {success}
        </div>
      )}

      {/* Rate entry table */}
      <div className="rounded-lg border bg-card shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/50">
                <th className="text-left p-3 font-medium w-28">Valuta</th>
                <th className="text-left p-3 font-medium">Hivatalos (MNB)</th>
                <th className="text-left p-3 font-medium">Veteli arfolyam</th>
                <th className="text-left p-3 font-medium">Eladasi arfolyam</th>
                <th className="text-left p-3 font-medium w-24">Spread</th>
                <th className="text-left p-3 font-medium w-16">Limit</th>
              </tr>
            </thead>
            <tbody>
              {rates.map((rate, idx) => {
                const buy = parseFloat(rate.baseBuyRate)
                const sell = parseFloat(rate.baseSellRate)
                const spread = !isNaN(buy) && !isNaN(sell) ? (sell - buy).toFixed(2) : '-'
                const isValid = !rate.baseBuyRate || !rate.baseSellRate || (!isNaN(buy) && !isNaN(sell) && sell > buy)
                const isExpanded = expandedLimits.has(rate.currencyId)

                return (
                  <React.Fragment key={rate.currencyId}>
                    <tr className={`border-b hover:bg-muted/30 ${!isValid ? 'bg-destructive/5' : ''}`}>
                      {/* Currency */}
                      <td className="p-3">
                        <div className="flex flex-col">
                          <span className="font-mono font-bold text-base">{rate.currencyCode}</span>
                          <span className="text-xs text-muted-foreground truncate max-w-[100px]">{rate.currencyName}</span>
                        </div>
                      </td>

                      {/* Official rate */}
                      <td className="p-2">
                        <input
                          type="text"
                          inputMode="decimal"
                          className="w-full h-9 rounded-md border px-2 py-1 text-sm font-mono text-center bg-blue-50 dark:bg-blue-950/30"
                          value={rate.officialRate}
                          onChange={e => updateRate(idx, 'officialRate', e.target.value)}
                          placeholder="MNB"
                        />
                      </td>

                      {/* Buy rate */}
                      <td className="p-2">
                        <input
                          type="text"
                          inputMode="decimal"
                          className={`w-full h-9 rounded-md border px-2 py-1 text-sm font-mono text-center ${
                            !isValid ? 'border-destructive' : 'focus:ring-2 focus:ring-primary'
                          }`}
                          value={rate.baseBuyRate}
                          onChange={e => updateRate(idx, 'baseBuyRate', e.target.value)}
                          placeholder="Vetel"
                        />
                      </td>

                      {/* Sell rate */}
                      <td className="p-2">
                        <input
                          type="text"
                          inputMode="decimal"
                          className={`w-full h-9 rounded-md border px-2 py-1 text-sm font-mono text-center ${
                            !isValid ? 'border-destructive' : 'focus:ring-2 focus:ring-primary'
                          }`}
                          value={rate.baseSellRate}
                          onChange={e => updateRate(idx, 'baseSellRate', e.target.value)}
                          placeholder="Eladas"
                        />
                      </td>

                      {/* Spread (read-only) */}
                      <td className="p-3 text-center font-mono text-muted-foreground">
                        {spread}
                      </td>

                      {/* Limit toggle */}
                      <td className="p-2 text-center">
                        <button
                          className={`inline-flex items-center justify-center rounded-md p-1.5 text-xs hover:bg-muted ${
                            hasLimits(rate) ? 'text-primary font-bold' : 'text-muted-foreground'
                          }`}
                          onClick={() => toggleLimits(rate.currencyId)}
                          title="Limit szintek"
                        >
                          {isExpanded ? (
                            <ChevronDown className="h-4 w-4" />
                          ) : (
                            <ChevronRight className="h-4 w-4" />
                          )}
                        </button>
                      </td>
                    </tr>

                    {/* Limit levels (expandable) */}
                    {isExpanded && (
                      <tr className="border-b bg-muted/20">
                        <td colSpan={6} className="p-3">
                          <div className="grid grid-cols-3 gap-4">
                            {/* Limit 1 */}
                            <div className="space-y-2 rounded-md border p-3">
                              <h4 className="text-xs font-semibold text-muted-foreground uppercase">Limit 1</h4>
                              <div>
                                <label className="text-xs text-muted-foreground">Osszeg (Ft)</label>
                                <input
                                  type="text"
                                  inputMode="decimal"
                                  className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                  value={rate.limit1Amount}
                                  onChange={e => updateRate(idx, 'limit1Amount', e.target.value)}
                                  placeholder="pl. 100000"
                                />
                              </div>
                              <div className="grid grid-cols-2 gap-2">
                                <div>
                                  <label className="text-xs text-muted-foreground">Vetel</label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit1BuyRate}
                                    onChange={e => updateRate(idx, 'limit1BuyRate', e.target.value)}
                                  />
                                </div>
                                <div>
                                  <label className="text-xs text-muted-foreground">Eladas</label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit1SellRate}
                                    onChange={e => updateRate(idx, 'limit1SellRate', e.target.value)}
                                  />
                                </div>
                              </div>
                            </div>

                            {/* Limit 2 */}
                            <div className="space-y-2 rounded-md border p-3">
                              <h4 className="text-xs font-semibold text-muted-foreground uppercase">Limit 2</h4>
                              <div>
                                <label className="text-xs text-muted-foreground">Osszeg (Ft)</label>
                                <input
                                  type="text"
                                  inputMode="decimal"
                                  className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                  value={rate.limit2Amount}
                                  onChange={e => updateRate(idx, 'limit2Amount', e.target.value)}
                                  placeholder="pl. 500000"
                                />
                              </div>
                              <div className="grid grid-cols-2 gap-2">
                                <div>
                                  <label className="text-xs text-muted-foreground">Vetel</label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit2BuyRate}
                                    onChange={e => updateRate(idx, 'limit2BuyRate', e.target.value)}
                                  />
                                </div>
                                <div>
                                  <label className="text-xs text-muted-foreground">Eladas</label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit2SellRate}
                                    onChange={e => updateRate(idx, 'limit2SellRate', e.target.value)}
                                  />
                                </div>
                              </div>
                            </div>

                            {/* Limit 3 */}
                            <div className="space-y-2 rounded-md border p-3">
                              <h4 className="text-xs font-semibold text-muted-foreground uppercase">Limit 3</h4>
                              <div>
                                <label className="text-xs text-muted-foreground">Osszeg (Ft)</label>
                                <input
                                  type="text"
                                  inputMode="decimal"
                                  className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                  value={rate.limit3Amount}
                                  onChange={e => updateRate(idx, 'limit3Amount', e.target.value)}
                                  placeholder="pl. 1000000"
                                />
                              </div>
                              <div className="grid grid-cols-2 gap-2">
                                <div>
                                  <label className="text-xs text-muted-foreground">Vetel</label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit3BuyRate}
                                    onChange={e => updateRate(idx, 'limit3BuyRate', e.target.value)}
                                  />
                                </div>
                                <div>
                                  <label className="text-xs text-muted-foreground">Eladas</label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit3SellRate}
                                    onChange={e => updateRate(idx, 'limit3SellRate', e.target.value)}
                                  />
                                </div>
                              </div>
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Bottom actions */}
      <div className="flex justify-between items-center">
        <span className="text-xs text-muted-foreground">
          {rates.filter(r => r.baseBuyRate.trim() && r.baseSellRate.trim()).length} / {rates.length} valuta kitoltve
        </span>
        <button
          className="inline-flex items-center justify-center rounded-md bg-primary px-6 py-2.5 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
          onClick={publishRates}
          disabled={saving}
        >
          {saving ? (
            <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
          ) : (
            <Send className="h-4 w-4 mr-2" />
          )}
          {saving ? 'Arfolyamok frissitese...' : 'Arfolyamok publikalasa'}
        </button>
      </div>
    </div>
  )
}
