import { useState, useEffect, useCallback, useMemo } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Building2, AlertTriangle, Search, RefreshCw } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { ertektarApi, branchApi } from '../../services/api/index'
import type { BranchInfo, BankTransaction } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

/**
 * Banki tranzakciók riport (ATVETT bank → értéktár, ATADOTT értéktár → bank).
 *
 * A backend nyelvezetében:
 *   - transactionType = "BUY"  -> ATVETT (Banktól vettünk valutát)
 *   - transactionType = "SELL" -> ATADOTT (Banknak adtunk át valutát)
 *
 * Backend végpont (létezik):
 *   GET /api/v1/ertektar/bank-transactions
 *   GET /api/v1/ertektar/bank-transactions/by-type?type=BUY|SELL
 *
 * A backend NEM támogat dátum-tartomány szerinti szűrést a jelenlegi szignatúrában,
 * ezért a frontend a teljes listát lehúzza, és kliens-oldalon szűri.
 * A branch-szűrés sincs a backenden — a BankTransactionResponseDto NEM tartalmaz branchId-t,
 * helyette vaultTerritoryId / vaultTerritoryName mezők vannak (értéktári terület).
 *
 * Filter állapot URL query paramban kerül megőrzésre (?from=...&to=...&direction=...).
 */

type BankTxn = BankTransaction

function toNum(v: number | string | null | undefined): number {
  if (v == null) return 0
  const n = typeof v === 'string' ? Number(v) : v
  return Number.isNaN(n) ? 0 : n
}

function formatHuf(n: number): string {
  return n.toLocaleString('hu-HU') + ' Ft'
}

function formatNum(n: number | string | undefined | null): string {
  if (n == null) return '-'
  const v = typeof n === 'string' ? Number(n) : n
  if (Number.isNaN(v)) return '-'
  return v.toLocaleString('hu-HU')
}

function formatDateTime(s: string | null | undefined): string {
  if (!s) return '-'
  try {
    return new Date(s).toLocaleString('hu-HU')
  } catch {
    return s
  }
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10)
}

export default function BankTransactionReportPage() {
  const { t } = useTranslation()

  const directionLabel = useCallback(
    (direction: string): string => {
      if (direction === 'in') return t('reports.bankTransactions.directionIn')
      if (direction === 'out') return t('reports.bankTransactions.directionOut')
      return t('reports.bankTransactions.directionAll')
    },
    [t]
  )
  const [searchParams, setSearchParams] = useSearchParams()

  const today = useMemo(() => new Date(), [])
  const monthStart = useMemo(() => {
    const d = new Date(today)
    d.setDate(1)
    return d
  }, [today])

  const [from, setFrom] = useState<string>(searchParams.get('from') ?? isoDate(monthStart))
  const [to, setTo] = useState<string>(searchParams.get('to') ?? isoDate(today))
  const [direction, setDirection] = useState<'all' | 'in' | 'out'>(
    (searchParams.get('direction') as 'all' | 'in' | 'out') ?? 'all'
  )
  const [branchId, setBranchId] = useState<string>(searchParams.get('branchId') ?? '')

  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [transactions, setTransactions] = useState<BankTxn[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // URL query param szinkronizálás
  useEffect(() => {
    const params: Record<string, string> = {}
    if (from) params.from = from
    if (to) params.to = to
    if (direction !== 'all') params.direction = direction
    if (branchId) params.branchId = branchId
    setSearchParams(params, { replace: true })
  }, [from, to, direction, branchId, setSearchParams])

  const loadBranches = useCallback(async () => {
    try {
      const list = await branchApi.listActive()
      setBranches(list)
    } catch (err) {
      logger.error('BankTransactionReportPage', 'Branch betöltés hiba:', err)
    }
  }, [])

  useEffect(() => {
    void loadBranches()
  }, [loadBranches])

  const fetchTransactions = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      let raw: BankTxn[]
      if (direction === 'in') {
        raw = await ertektarApi.getBankTransactionsByType('BUY')
      } else if (direction === 'out') {
        raw = await ertektarApi.getBankTransactionsByType('SELL')
      } else {
        raw = await ertektarApi.getBankTransactions()
      }
      setTransactions(Array.isArray(raw) ? raw : [])
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('BankTransactionReportPage', 'Lekérdezés hiba:', err)
      setError(msg)
      setTransactions([])
    } finally {
      setLoading(false)
    }
  }, [direction])

  useEffect(() => {
    void fetchTransactions()
  }, [fetchTransactions])

  // Kliens-oldali szűrés dátum + branch (vaultTerritoryName szöveges illesztés) szerint
  const filtered = useMemo(() => {
    const fromMs = from ? new Date(from + 'T00:00:00').getTime() : Number.NEGATIVE_INFINITY
    const toMs = to ? new Date(to + 'T23:59:59.999').getTime() : Number.POSITIVE_INFINITY
    const branchName = branchId
      ? branches.find((b) => b.id === branchId)?.name ?? ''
      : ''
    return transactions.filter((tx) => {
      if (tx.createdAt) {
        const ms = new Date(tx.createdAt).getTime()
        if (Number.isFinite(ms) && (ms < fromMs || ms > toMs)) return false
      }
      if (branchName && tx.vaultTerritoryName) {
        if (!tx.vaultTerritoryName.toLowerCase().includes(branchName.toLowerCase())) {
          return false
        }
      }
      return true
    })
  }, [transactions, from, to, branchId, branches])

  // Valutánkénti összesítés
  const totalsByCurrency = useMemo(() => {
    const map = new Map<string, { amount: number; hufAmount: number; count: number }>()
    for (const tx of filtered) {
      const key = tx.currencyCode ?? '?'
      const existing = map.get(key)
      if (existing) {
        existing.amount += toNum(tx.amount)
        existing.hufAmount += toNum(tx.hufAmount)
        existing.count += 1
      } else {
        map.set(key, {
          amount: toNum(tx.amount),
          hufAmount: toNum(tx.hufAmount),
          count: 1,
        })
      }
    }
    return Array.from(map.entries()).map(([code, vals]) => ({ code, ...vals }))
  }, [filtered])

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Building2 className="h-6 w-6" />
          {t('reports.bankTransactions.title')}
        </h1>
        <button
          type="button"
          onClick={() => void fetchTransactions()}
          disabled={loading}
          className="form-button p-2"
          title="Frissítés"
        >
          <RefreshCw className={loading ? 'h-4 w-4 animate-spin' : 'h-4 w-4'} />
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="bg-white rounded shadow p-4 grid grid-cols-1 md:grid-cols-5 gap-3 items-end">
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="bt-from">{t('reports.bankTransactions.from')}</label>
          <input
            id="bt-from"
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="bt-to">{t('reports.bankTransactions.to')}</label>
          <input
            id="bt-to"
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            className="form-input w-full text-sm"
          />
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="bt-direction">{t('reports.bankTransactions.direction')}</label>
          <select
            id="bt-direction"
            value={direction}
            onChange={(e) => setDirection(e.target.value as 'all' | 'in' | 'out')}
            className="form-input w-full text-sm"
          >
            <option value="all">{t('reports.bankTransactions.directionAll')}</option>
            <option value="in">{t('reports.bankTransactions.directionIn')}</option>
            <option value="out">{t('reports.bankTransactions.directionOut')}</option>
          </select>
        </div>
        <div>
          <label className="block text-xs text-gray-500 mb-1" htmlFor="bt-branch">{t('reports.bankTransactions.branch')}</label>
          <select
            id="bt-branch"
            value={branchId}
            onChange={(e) => setBranchId(e.target.value)}
            className="form-input w-full text-sm"
          >
            <option value="">{t('reports.bankTransactions.branchAll')}</option>
            {branches.map((b) => (
              <option key={b.id} value={b.id}>
                {b.code} - {b.name}
              </option>
            ))}
          </select>
        </div>
        <div>
          <button
            type="button"
            onClick={() => void fetchTransactions()}
            disabled={loading}
            className="form-button-primary flex items-center gap-2 w-full justify-center"
          >
            <Search className="h-4 w-4" />
            {loading ? t('reports.bankTransactions.loading') : t('reports.bankTransactions.submit')}
          </button>
        </div>
      </div>

      <div className="text-xs text-gray-500">
        {t('reports.bankTransactions.activeFilter', { label: directionLabel(direction), count: filtered.length })}
      </div>

      {totalsByCurrency.length > 0 && (
        <div className="bg-white rounded shadow">
          <div className="bg-gray-50 px-4 py-2 border-b">
            <h2 className="font-semibold">{t('reports.bankTransactions.currencySummary')}</h2>
          </div>
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.currencyTable.currency')}</th>
                <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.currencyTable.transactions')}</th>
                <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.currencyTable.amount')}</th>
                <th className="px-4 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.currencyTable.hufValue')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {totalsByCurrency.map((r) => (
                <tr key={r.code} className="hover:bg-gray-50">
                  <td className="px-4 py-2 text-sm font-mono font-semibold">{r.code}</td>
                  <td className="px-4 py-2 text-right text-sm font-mono">{r.count}</td>
                  <td className="px-4 py-2 text-right text-sm font-mono">{formatNum(r.amount)}</td>
                  <td className="px-4 py-2 text-right text-sm font-mono font-semibold">{formatHuf(r.hufAmount)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="bg-white rounded shadow">
        <div className="bg-gray-50 px-4 py-2 border-b">
          <h2 className="font-semibold">{t('reports.bankTransactions.transactions')}</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.table.date')}</th>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.table.direction')}</th>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.table.currency')}</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.table.amount')}</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.table.rate')}</th>
                <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.table.huf')}</th>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.table.bank')}</th>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.table.ref')}</th>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.table.vault')}</th>
                <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">{t('reports.bankTransactions.table.note')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filtered.length === 0 && (
                <tr>
                  <td colSpan={10} className="px-4 py-4 text-center text-sm text-gray-500">
                    {loading ? t('reports.bankTransactions.table.loading') : t('reports.bankTransactions.table.noResults')}
                  </td>
                </tr>
              )}
              {filtered.map((tx) => (
                <tr key={tx.id} className="hover:bg-gray-50">
                  <td className="px-3 py-2 text-xs">{formatDateTime(tx.createdAt)}</td>
                  <td className="px-3 py-2 text-xs">
                    <span
                      className={
                        tx.transactionType === 'BUY'
                          ? 'inline-block px-2 py-0.5 rounded bg-blue-100 text-blue-700 font-medium'
                          : 'inline-block px-2 py-0.5 rounded bg-orange-100 text-orange-700 font-medium'
                      }
                    >
                      {tx.transactionType === 'BUY' ? t('reports.bankTransactions.table.atvett') : t('reports.bankTransactions.table.atadott')}
                    </span>
                  </td>
                  <td className="px-3 py-2 text-sm font-mono font-semibold">{tx.currencyCode}</td>
                  <td className="px-3 py-2 text-right text-sm font-mono">{formatNum(tx.amount)}</td>
                  <td className="px-3 py-2 text-right text-xs font-mono">
                    {tx.exchangeRate != null ? toNum(tx.exchangeRate).toFixed(4) : '-'}
                  </td>
                  <td className="px-3 py-2 text-right text-sm font-mono font-semibold">
                    {formatHuf(toNum(tx.hufAmount))}
                  </td>
                  <td className="px-3 py-2 text-xs">{tx.bankName ?? '-'}</td>
                  <td className="px-3 py-2 text-xs">{tx.bankReference ?? '-'}</td>
                  <td className="px-3 py-2 text-xs">{tx.vaultTerritoryName ?? '-'}</td>
                  <td className="px-3 py-2 text-xs max-w-[20ch] truncate" title={tx.note ?? undefined}>
                    {tx.note ?? '-'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
