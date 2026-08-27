import React, { useState, useEffect, useCallback } from 'react'
import {
  RefreshCw,
  Send,
  AlertTriangle,
  ChevronDown,
  ChevronRight,
  Users,
  Undo2,
  Redo2,
} from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { useGridNavigation } from '../../hooks/useGridNavigation'
import { useUndoStack } from '../../hooks/useUndoStack'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

/**
 * Arfolyam rogzites — Legacy: arfdata.dat adatbevitel.
 *
 * A foertektaros itt rogziti az osszes valuta arfolyamat egyszerre:
 * - Alap veteli / eladasi arfolyam
 * - Hivatalos (MNB/elszamolasi) arfolyam
 * - Limit szintek (1-3) osszegekkel es arfolyamokkal
 *
 * Mentés utan a "Publikalas" gombbal az osszes fiok megkapja az uj arfolyamokat.
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

interface WorkgroupInfo {
  id: string
  name: string
  code: string
}

function toNum(val: string): number | null {
  const trimmed = val.trim()
  if (!trimmed) return null
  const num = parseFloat(trimmed)
  return isNaN(num) ? null : num
}

export default function SettlementRateEntry() {
  const { t } = useTranslation()
  const [rates, setRates] = useState<ExchangeRateData[]>([])
  const [workgroups, setWorkgroups] = useState<WorkgroupInfo[]>([])
  const [currencies, setCurrencies] = useState<CurrencyInfo[]>([])
  const [selectedWorkgroup, setSelectedWorkgroup] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [validationErrors, setValidationErrors] = useState<
    { row: number; code: string; message: string }[]
  >([])
  const [success, setSuccess] = useState<string | null>(null)
  const [expandedLimits, setExpandedLimits] = useState<Set<number>>(new Set())

  const MAIN_FIELDS: EditableField[] = ['officialRate', 'baseBuyRate', 'baseSellRate']
  const { containerRef, activeCell, getCellProps } = useGridNavigation({
    rows: rates.length,
    cols: MAIN_FIELDS.length,
  })

  const { push: pushUndo, undo, redo, canUndo, canRedo } = useUndoStack<ExchangeRateData[]>()

  // Ctrl+Z / Ctrl+Shift+Z global handler
  useEffect(() => {
    const handleGlobalKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'z') {
        if (e.shiftKey) {
          e.preventDefault()
          const snapshot = redo()
          if (snapshot) setRates(snapshot)
        } else {
          e.preventDefault()
          const snapshot = undo()
          if (snapshot) setRates(snapshot)
        }
      }
      if ((e.ctrlKey || e.metaKey) && e.key === 'y') {
        e.preventDefault()
        const snapshot = redo()
        if (snapshot) setRates(snapshot)
      }
    }
    window.addEventListener('keydown', handleGlobalKeyDown)
    return () => window.removeEventListener('keydown', handleGlobalKeyDown)
  }, [undo, redo])

  // Egyszeri betöltés: valuták + munkacsoportok (nem változnak workgroup váltáskor)
  useEffect(() => {
    Promise.all([
      api.get<CurrencyInfo[]>('/currencies'),
      api.get<WorkgroupInfo[]>('/rate-creation/workgroups'),
    ])
      .then(([currRes, wgRes]) => {
        const currenciesData = safeArray<CurrencyInfo>(currRes?.data)
        const workgroupsData = safeArray<WorkgroupInfo>(wgRes?.data)
        const sorted = currenciesData
          .filter((c: CurrencyInfo) => c.code !== 'HUF')
          .sort(
            (a: CurrencyInfo, b: CurrencyInfo) => (a.displayOrder ?? 100) - (b.displayOrder ?? 100),
          )
        setCurrencies(sorted)
        setWorkgroups(workgroupsData)
        if (workgroupsData[0]) {
          setSelectedWorkgroup(workgroupsData[0].id)
        }
      })
      .catch((err) => {
        logger.error('SettlementRateEntry', 'Failed to load reference data:', err)
        setError('Referencia adatok betöltése sikertelen')
      })
  }, [])

  // Árfolyamok frissítése (csak rates API) — selectedWorkgroup vagy currencies változásakor
  const fetchRates = useCallback(async () => {
    if (currencies.length === 0) return
    setLoading(true)
    setError(null)
    try {
      const rateRes = await api.get<CurrentRateFromApi[]>('/exchange-rates/current')
      const ratesData = safeArray<CurrentRateFromApi>(rateRes?.data)
      const rateMap = new Map<number, CurrentRateFromApi>()
      for (const r of ratesData) {
        rateMap.set(r.currencyId, r)
      }

      const rateEntries: ExchangeRateData[] = currencies.map((c: CurrencyInfo) => {
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
      logger.error('SettlementRateEntry', 'Failed to load rates:', err)
      setError('Árfolyam adatok betöltése sikertelen')
    } finally {
      setLoading(false)
    }
  }, [currencies])

  useEffect(() => {
    void fetchRates()
  }, [fetchRates])

  type EditableField = Exclude<
    keyof ExchangeRateData,
    'id' | 'currencyId' | 'currencyCode' | 'currencyName'
  >

  const updateRate = (index: number, field: EditableField, value: string) => {
    setRates((prev) => {
      const next = prev.map((r, i) => {
        if (i !== index) return r
        const copy = { ...r }
        copy[field] = value
        return copy
      })
      pushUndo({ prev, next })
      return next
    })
  }

  const toggleLimits = (currencyId: number) => {
    setExpandedLimits((prev) => {
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
    setValidationErrors([])
    setSuccess(null)

    // Validalas: legalabb 1 valutahoz kell arfolyam
    const validRates = rates.filter((r) => r.baseBuyRate.trim() && r.baseSellRate.trim())
    if (validRates.length === 0) {
      setError('Legalabb egy valutahoz rogzitsen veteli es eladasi arfolyamot!')
      return
    }

    // Strukturalt per-row validacio
    const errors: { row: number; code: string; message: string }[] = []
    for (let i = 0; i < rates.length; i++) {
      const r = rates[i]!
      const hasBuy = r.baseBuyRate.trim() !== ''
      const hasSell = r.baseSellRate.trim() !== ''

      // Csak az egyiket toltotte ki
      if (hasBuy !== hasSell) {
        errors.push({
          row: i,
          code: r.currencyCode ?? '',
          message: 'Veteli es eladasi arfolyam egyutt szukseges',
        })
        continue
      }
      if (!hasBuy && !hasSell) continue

      const buy = parseFloat(r.baseBuyRate)
      const sell = parseFloat(r.baseSellRate)

      if (isNaN(buy)) {
        errors.push({
          row: i,
          code: r.currencyCode ?? '',
          message: 'Ervenytelen veteli arfolyam ertek',
        })
      }
      if (isNaN(sell)) {
        errors.push({
          row: i,
          code: r.currencyCode ?? '',
          message: 'Ervenytelen eladasi arfolyam ertek',
        })
      }
      if (!isNaN(buy) && !isNaN(sell) && sell <= buy) {
        errors.push({
          row: i,
          code: r.currencyCode ?? '',
          message: `Eladasi (${sell}) nagyobb kell legyen a veteliinel (${buy})`,
        })
      }

      // Limit validacio: ha limit osszeg van, limit arfolyam is kell
      for (const lvl of [1, 2, 3] as const) {
        const amt = r[`limit${lvl}Amount` as EditableField]?.trim()
        const lBuy = r[`limit${lvl}BuyRate` as EditableField]?.trim()
        const lSell = r[`limit${lvl}SellRate` as EditableField]?.trim()
        if (amt && (!lBuy || !lSell)) {
          errors.push({
            row: i,
            code: r.currencyCode ?? '',
            message: `Limit ${lvl}: osszeghez arfolyam is szukseges`,
          })
        }
      }
    }

    if (errors.length > 0) {
      setValidationErrors(errors)
      setError(`${errors.length} validacios hiba talalhato`)
      return
    }

    setSaving(true)
    try {
      const payload = {
        groupId: selectedWorkgroup,
        rates: validRates.map((r) => ({
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
      setSuccess(`Sikeres publikálás! ${validRates.length} valuta árfolyama frissítve.`)

      // Reload data to show updated values
      await fetchRates()
    } catch (err: unknown) {
      const axiosErr = err as { response?: { data?: { message?: string } } }
      const msg = axiosErr?.response?.data?.message || 'Publikálás sikertelen'
      setError(msg)
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <RefreshCw className="h-6 w-6 animate-spin text-muted-foreground" />
        <span className="ml-2 text-muted-foreground">
          {i18n.t('literals.arfolyamok-betoltese')}
        </span>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Workgroup selector */}
      {workgroups.length > 0 && (
        <div className="flex items-center gap-3 rounded-lg border bg-card p-3 shadow-sm">
          <Users className="h-4 w-4 text-muted-foreground" />
          <label className="text-sm font-medium">{t('ratemanagement.munkacsoport')}</label>
          <select
            className="border rounded px-3 py-1.5 text-sm bg-background"
            value={selectedWorkgroup ?? ''}
            onChange={(e) => setSelectedWorkgroup(e.target.value || null)}
          >
            {workgroups.map((wg) => (
              <option key={wg.id} value={wg.id}>
                {wg.name}
                {i18n.t('literals.lit')}
                {wg.code}
                {i18n.t('literals.lit-2')}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Header */}
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          {t(
            'ratemanagement.rogzitseAzArfolyamokatAzOsszesAktivValutahozAPublikalasGombbalAzArfolyamokAzonnalEloveValnak',
          )}
        </p>
        <div className="flex gap-2">
          <button
            className="inline-flex items-center justify-center rounded-md border px-2 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
            onClick={() => {
              const s = undo()
              if (s) setRates(s)
            }}
            disabled={!canUndo}
            title="Visszavonás (Ctrl+Z)"
          >
            <Undo2 className="h-4 w-4" />
          </button>
          <button
            className="inline-flex items-center justify-center rounded-md border px-2 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
            onClick={() => {
              const s = redo()
              if (s) setRates(s)
            }}
            disabled={!canRedo}
            title="Újra (Ctrl+Shift+Z)"
          >
            <Redo2 className="h-4 w-4" />
          </button>
          <button
            className="inline-flex items-center justify-center rounded-md border px-3 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
            onClick={fetchRates}
            disabled={saving}
          >
            <RefreshCw className="h-4 w-4 mr-2" />
            {t('common.refresh')}
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
            {saving ? 'Publikálás...' : 'Publikálás'}
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
      {validationErrors.length > 0 && (
        <div className="rounded-md bg-destructive/10 border border-destructive/20 p-3 text-sm">
          <div className="font-medium text-destructive mb-2">
            {t('ratemanagement.validaciosHibak')}
            {validationErrors.length}
            {i18n.t('literals.lit-43')}
          </div>
          <ul className="list-disc list-inside space-y-1 text-destructive/90">
            {validationErrors.map((ve, i) => (
              <li key={i}>
                <span className="font-mono font-bold">{ve.code}</span>
                {i18n.t('literals.lit-22')}
                {ve.message}
              </li>
            ))}
          </ul>
        </div>
      )}
      {success && (
        <div className="rounded-md bg-green-500/10 border border-green-500/20 p-3 text-sm text-green-700 dark:text-green-400">
          {success}
        </div>
      )}

      {/* Rate entry table */}
      <div ref={containerRef} className="rounded-lg border bg-card shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b bg-muted/50">
                <th className="text-left p-3 font-medium w-28">{t('common.currency')}</th>
                <th className="text-left p-3 font-medium">{t('ratemanagement.hivatalosMnb')}</th>
                <th className="text-left p-3 font-medium">{t('ratemanagement.veteliArfolyam')}</th>
                <th className="text-left p-3 font-medium">{t('ratemanagement.eladasiArfolyam')}</th>
                <th className="text-left p-3 font-medium w-24">{t('ratemanagement.spread2')}</th>
                <th className="text-left p-3 font-medium w-16">{t('components.limit')}</th>
              </tr>
            </thead>
            <tbody>
              {rates.map((rate, idx) => {
                const buy = parseFloat(rate.baseBuyRate)
                const sell = parseFloat(rate.baseSellRate)
                const spread = !isNaN(buy) && !isNaN(sell) ? (sell - buy).toFixed(2) : '-'
                const isValid =
                  !rate.baseBuyRate ||
                  !rate.baseSellRate ||
                  (!isNaN(buy) && !isNaN(sell) && sell > buy)
                const rowErrors = validationErrors.filter((ve) => ve.row === idx)
                const hasRowError = rowErrors.length > 0
                const isExpanded = expandedLimits.has(rate.currencyId)

                return (
                  <React.Fragment key={rate.currencyId}>
                    <tr
                      className={`border-b hover:bg-muted/30 ${!isValid || hasRowError ? 'bg-destructive/5' : ''}`}
                    >
                      {/* Currency */}
                      <td className="p-3">
                        <div className="flex flex-col">
                          <span className="font-mono font-bold text-base">{rate.currencyCode}</span>
                          <span className="text-xs text-muted-foreground truncate max-w-[100px]">
                            {rate.currencyName}
                          </span>
                        </div>
                      </td>

                      {/* Official rate */}
                      <td className="p-2">
                        <input
                          type="text"
                          inputMode="decimal"
                          {...getCellProps(idx, 0)}
                          className={`w-full h-9 rounded-md border px-2 py-1 text-sm font-mono text-center bg-blue-50 dark:bg-blue-950/30 ${activeCell?.row === idx && activeCell?.col === 0 ? 'ring-2 ring-blue-500' : ''}`}
                          value={rate.officialRate}
                          onChange={(e) => updateRate(idx, 'officialRate', e.target.value)}
                          placeholder="MNB"
                        />
                      </td>

                      {/* Buy rate */}
                      <td className="p-2">
                        <input
                          type="text"
                          inputMode="decimal"
                          {...getCellProps(idx, 1)}
                          className={`w-full h-9 rounded-md border px-2 py-1 text-sm font-mono text-center ${
                            !isValid ? 'border-destructive' : 'focus:ring-2 focus:ring-primary'
                          } ${activeCell?.row === idx && activeCell?.col === 1 ? 'ring-2 ring-blue-500' : ''}`}
                          value={rate.baseBuyRate}
                          onChange={(e) => updateRate(idx, 'baseBuyRate', e.target.value)}
                          placeholder="Vétel"
                        />
                      </td>

                      {/* Sell rate */}
                      <td className="p-2">
                        <input
                          type="text"
                          inputMode="decimal"
                          {...getCellProps(idx, 2)}
                          className={`w-full h-9 rounded-md border px-2 py-1 text-sm font-mono text-center ${
                            !isValid ? 'border-destructive' : 'focus:ring-2 focus:ring-primary'
                          } ${activeCell?.row === idx && activeCell?.col === 2 ? 'ring-2 ring-blue-500' : ''}`}
                          value={rate.baseSellRate}
                          onChange={(e) => updateRate(idx, 'baseSellRate', e.target.value)}
                          placeholder="Eladás"
                        />
                      </td>

                      {/* Spread (read-only) */}
                      <td className="p-3 text-center font-mono text-muted-foreground">{spread}</td>

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
                              <h4 className="text-xs font-semibold text-muted-foreground uppercase">
                                {t('ratemanagement.limit1')}
                              </h4>
                              <div>
                                <label className="text-xs text-muted-foreground">
                                  {t('ratemanagement.osszegFt')}
                                </label>
                                <input
                                  type="text"
                                  inputMode="decimal"
                                  className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                  value={rate.limit1Amount}
                                  onChange={(e) => updateRate(idx, 'limit1Amount', e.target.value)}
                                  placeholder="pl. 100000"
                                />
                              </div>
                              <div className="grid grid-cols-2 gap-2">
                                <div>
                                  <label className="text-xs text-muted-foreground">
                                    {t('cashier.buy')}
                                  </label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit1BuyRate}
                                    onChange={(e) =>
                                      updateRate(idx, 'limit1BuyRate', e.target.value)
                                    }
                                  />
                                </div>
                                <div>
                                  <label className="text-xs text-muted-foreground">
                                    {t('cashier.sell')}
                                  </label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit1SellRate}
                                    onChange={(e) =>
                                      updateRate(idx, 'limit1SellRate', e.target.value)
                                    }
                                  />
                                </div>
                              </div>
                            </div>

                            {/* Limit 2 */}
                            <div className="space-y-2 rounded-md border p-3">
                              <h4 className="text-xs font-semibold text-muted-foreground uppercase">
                                {t('ratemanagement.limit2')}
                              </h4>
                              <div>
                                <label className="text-xs text-muted-foreground">
                                  {t('ratemanagement.osszegFt')}
                                </label>
                                <input
                                  type="text"
                                  inputMode="decimal"
                                  className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                  value={rate.limit2Amount}
                                  onChange={(e) => updateRate(idx, 'limit2Amount', e.target.value)}
                                  placeholder="pl. 500000"
                                />
                              </div>
                              <div className="grid grid-cols-2 gap-2">
                                <div>
                                  <label className="text-xs text-muted-foreground">
                                    {t('cashier.buy')}
                                  </label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit2BuyRate}
                                    onChange={(e) =>
                                      updateRate(idx, 'limit2BuyRate', e.target.value)
                                    }
                                  />
                                </div>
                                <div>
                                  <label className="text-xs text-muted-foreground">
                                    {t('cashier.sell')}
                                  </label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit2SellRate}
                                    onChange={(e) =>
                                      updateRate(idx, 'limit2SellRate', e.target.value)
                                    }
                                  />
                                </div>
                              </div>
                            </div>

                            {/* Limit 3 */}
                            <div className="space-y-2 rounded-md border p-3">
                              <h4 className="text-xs font-semibold text-muted-foreground uppercase">
                                {t('ratemanagement.limit3')}
                              </h4>
                              <div>
                                <label className="text-xs text-muted-foreground">
                                  {t('ratemanagement.osszegFt')}
                                </label>
                                <input
                                  type="text"
                                  inputMode="decimal"
                                  className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                  value={rate.limit3Amount}
                                  onChange={(e) => updateRate(idx, 'limit3Amount', e.target.value)}
                                  placeholder="pl. 1000000"
                                />
                              </div>
                              <div className="grid grid-cols-2 gap-2">
                                <div>
                                  <label className="text-xs text-muted-foreground">
                                    {t('cashier.buy')}
                                  </label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit3BuyRate}
                                    onChange={(e) =>
                                      updateRate(idx, 'limit3BuyRate', e.target.value)
                                    }
                                  />
                                </div>
                                <div>
                                  <label className="text-xs text-muted-foreground">
                                    {t('cashier.sell')}
                                  </label>
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    className="w-full h-8 rounded-md border px-2 py-1 text-xs font-mono"
                                    value={rate.limit3SellRate}
                                    onChange={(e) =>
                                      updateRate(idx, 'limit3SellRate', e.target.value)
                                    }
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
          {rates.filter((r) => r.baseBuyRate.trim() && r.baseSellRate.trim()).length}
          {i18n.t('literals.lit-40')} {rates.length} {t('ratemanagement.valutaKitoltve')}
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
          {saving ? 'Árfolyamok frissítése...' : 'Árfolyamok publikálása'}
        </button>
      </div>
    </div>
  )
}
