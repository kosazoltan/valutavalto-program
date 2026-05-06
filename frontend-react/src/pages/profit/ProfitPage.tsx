import { useState, useEffect, useCallback } from 'react'
import { TrendingUp, RefreshCw, AlertTriangle } from 'lucide-react'
import { api } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useTranslation } from 'react-i18next'

/**
 * ProfitReport shape (backend: ProfitCalculationService.ProfitReport)
 * - revenue, expenses, grossProfit, netProfit (BigDecimal -> number/string)
 * - totalTransactions (int)
 * - profitByCurrency: [{ currency, buyCount, sellCount, buyHuf, sellHuf, fees, profit }]
 *
 * Codex PR #144 P1 fix: GET /api/v1/profit/company EGY ProfitReport objektumot
 * ad vissza, NEM array-t. A korabbi safeArray<ProfitItem[]> mindig uresre esett.
 */
interface CurrencyProfitRow {
  currency?: string
  currencyCode?: string
  buyCount?: number
  sellCount?: number
  buyHuf?: number | string
  sellHuf?: number | string
  fees?: number | string
  profit?: number | string
}

interface ProfitReport {
  revenue?: number | string
  expenses?: number | string
  grossProfit?: number | string
  netProfit?: number | string
  totalTransactions?: number
  profitByCurrency?: CurrencyProfitRow[]
}

function formatHuf(v: number | string | undefined): string {
  if (v == null) return '-'
  const n = typeof v === 'string' ? Number(v) : v
  if (Number.isNaN(n)) return String(v)
  return n.toLocaleString('hu-HU')
}

export default function ProfitPage() {
  const { t } = useTranslation()
  const [report, setReport] = useState<ProfitReport | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    // Sourcery PR #145 P2 fix: companyId check BEFORE setLoading(true)
    // hogy ne legyen briefly loading state ha tudjuk, hogy a call nem megy.
    // Fix: useAuthStore.user getter legacy compat, de zustand snapshot-ban always null (getter
    // csak store creation-kor fut). A worker a valos, reaktiv mezoi - minden mas oldal ezt hasznalja.
    const companyId = useAuthStore.getState().worker?.companyId
    if (!companyId) {
      setError('Nincs bejelentkezett ceg (companyId hianyzik) - haszon kimutatas nem tolthet')
      setLoading(false)
      setReport(null)
      return
    }

    try {
      setLoading(true)
      setError(null)
      const month = new Date().toISOString().slice(0, 7)
      const response = await api.get<ProfitReport>('/profit/company', { params: { companyId, month } })
      // Codex PR #144 P1 fix: object wrapper, nem safeArray
      setReport(response.data ?? null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('ProfitPage', 'Betoltesi hiba:', err)
      setError(msg)
      setReport(null)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const rows: CurrencyProfitRow[] = report?.profitByCurrency ?? []

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <TrendingUp className="h-6 w-6" />
          {t('profit.haszonKimutatas')}
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissites">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {/* Osszesitett sor */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-white rounded shadow p-3">
          <div className="text-xs text-gray-500">{t('profit.bevetel')}</div>
          <div className="text-xl font-mono">{formatHuf(report?.revenue)}</div>
        </div>
        <div className="bg-white rounded shadow p-3">
          <div className="text-xs text-gray-500">{t('profit.koltsegek')}</div>
          <div className="text-xl font-mono">{formatHuf(report?.expenses)}</div>
        </div>
        <div className="bg-white rounded shadow p-3">
          <div className="text-xs text-gray-500">{t('profit.bruttoHaszon')}</div>
          <div className="text-xl font-mono">{formatHuf(report?.grossProfit)}</div>
        </div>
        <div className="bg-white rounded shadow p-3">
          <div className="text-xs text-gray-500">{t('profit.nettoHaszon')}</div>
          <div className="text-xl font-mono">{formatHuf(report?.netProfit)}</div>
        </div>
      </div>

      {/* Devizanemenkent */}
      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('common.deviza')}</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">{t('darius.vetelDb')}</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">{t('darius.eladasDb')}</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">{t('profit.vetelHuf')}</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">{t('profit.eladasHuf')}</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">{t('profit.haszon')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">Betoltes...</td></tr>
            ) : rows.length === 0 ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">{t('common.noData')}</td></tr>
            ) : rows.map((r, i) => (
              <tr key={`${r.currencyCode ?? r.currency ?? 'idx'}-${i}`} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{r.currencyCode ?? r.currency ?? '-'}</td>
                <td className="px-4 py-3 text-right text-sm font-mono">{r.buyCount ?? '-'}</td>
                <td className="px-4 py-3 text-right text-sm font-mono">{r.sellCount ?? '-'}</td>
                <td className="px-4 py-3 text-right text-sm font-mono">{formatHuf(r.buyHuf)}</td>
                <td className="px-4 py-3 text-right text-sm font-mono">{formatHuf(r.sellHuf)}</td>
                <td className="px-4 py-3 text-right text-sm font-mono">{formatHuf(r.profit)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('decade.tranzakciok')}{report?.totalTransactions ?? 0}
      </div>
    </div>
  )
}