import { useState, useEffect, useCallback, useRef } from 'react'
import { RefreshCw, Pause, Play, Download } from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
import { cashBalanceApi, currencyApi } from '../../services/api/index'
import type { CashBalance, Currency } from '../../services/api/index'
import {
  formatInteger,
  formatMillions,
  getStockLevel,
  stockLevelColor,
  stockLevelIcon,
  currencyColorClass,
} from './treasuryUtils'
import { TableSkeleton } from './LoadingSkeleton'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import { downloadBlob } from '../../utils/downloadBlob'

/** Branch aggregated data for the matrix */
interface BranchRow {
  id: string
  name: string
  stocks: Map<string, number> // currencyCode → amount
  totalHuf: number
}

export default function StockMatrix() {
  const { t } = useTranslation()
  const [loading, setLoading] = useState(true)
  const [balances, setBalances] = useState<CashBalance[]>([])
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [countdown, setCountdown] = useState(30)
  const [branchFilter, setBranchFilter] = useState('all')
  const [currencyFilter, setCurrencyFilter] = useState('all')
  const countdownRef = useRef(30)

  const fetchData = useCallback(async () => {
    try {
      const [balanceDataRaw, currencyDataRaw] = await Promise.all([
        cashBalanceApi.getCompanyBalances().catch(() => []),
        currencyApi.list().catch(() => []),
      ])
      const balanceData = safeArray<CashBalance>(balanceDataRaw)
      const currencyData = safeArray<Currency>(currencyDataRaw)
      setBalances(balanceData)
      setCurrencies(currencyData)
      setCountdown(30)
      countdownRef.current = 30
    } catch (err) {
      logger.error('StockMatrix', 'StockMatrix fetch error:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  // Initial load + polling
  useEffect(() => {
    void fetchData()
  }, [fetchData])

  useEffect(() => {
    if (!autoRefresh) return
    const interval = setInterval(() => void fetchData(), 30_000)
    return () => clearInterval(interval)
  }, [autoRefresh, fetchData])

  // Countdown timer
  useEffect(() => {
    if (!autoRefresh) return
    const timer = setInterval(() => {
      countdownRef.current -= 1
      setCountdown(countdownRef.current)
      if (countdownRef.current <= 0) {
        countdownRef.current = 30
        setCountdown(30)
      }
    }, 1000)
    return () => clearInterval(timer)
  }, [autoRefresh])

  // Hotkeys
  useHotkeys('r', () => void fetchData(), { enableOnFormTags: false })
  useHotkeys('p', () => setAutoRefresh((v) => !v), { enableOnFormTags: false })

  // Build the matrix
  const branchMap = new Map<string, BranchRow>()
  for (const b of balances) {
    let row = branchMap.get(b.branchId)
    if (!row) {
      row = {
        id: b.branchId,
        name: b.branchName ?? b.branchId,
        stocks: new Map(),
        totalHuf: 0,
      }
      branchMap.set(b.branchId, row)
    }
    row.stocks.set(b.currencyCode, (row.stocks.get(b.currencyCode) ?? 0) + b.currentBalance)
    row.totalHuf += b.currentBalance
  }

  const branchRows = Array.from(branchMap.values()).sort((a, b) => b.totalHuf - a.totalHuf)

  // Filter currencies: show active currencies from the data or all from API
  let displayCurrencies = currencies.filter((c) => c.active)
  if (currencyFilter === 'top8') {
    displayCurrencies = displayCurrencies.slice(0, 8)
  } else if (currencyFilter !== 'all') {
    displayCurrencies = displayCurrencies.filter((c) => c.code === currencyFilter)
  }

  // Filter branches
  const displayBranches =
    branchFilter === 'all' ? branchRows : branchRows.filter((b) => b.id === branchFilter)

  // Totals per currency
  const currencyTotals = new Map<string, number>()
  for (const row of displayBranches) {
    for (const [code, amount] of row.stocks) {
      currencyTotals.set(code, (currencyTotals.get(code) ?? 0) + amount)
    }
  }
  const grandTotal = displayBranches.reduce((sum, b) => sum + b.totalHuf, 0)

  // Export helper
  const handleExport = useCallback(() => {
    const header = ['Iroda', ...displayCurrencies.map((c) => c.code), 'ÖSSZ (Ft)']
    const rows = displayBranches.map((b) => [
      b.name,
      ...displayCurrencies.map((c) => String(b.stocks.get(c.code) ?? 0)),
      String(b.totalHuf),
    ])
    const csv = [header, ...rows].map((r) => r.join(';')).join('\n')
    downloadBlob(
      '\ufeff' + csv,
      `keszlet-matrix-${new Date().toISOString().slice(0, 10)}.csv`,
      'text/csv;charset=utf-8',
    )
  }, [displayBranches, displayCurrencies])

  useHotkeys('e', () => handleExport(), { enableOnFormTags: false })

  if (loading) return <TableSkeleton rows={8} cols={8} />

  return (
    <div className="space-y-4">
      {/* Header with auto-refresh controls */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h1 className="text-xl font-bold text-secondary-900">{t('treasury.keszletMatrix')}</h1>
          <div className="flex items-center gap-2 text-sm text-secondary-600">
            <RefreshCw size={16} className={autoRefresh ? 'animate-spin' : ''} />
            {autoRefresh ? (
              <span>
                {t('treasury.autoRefresh')}
                <strong>{countdown}s</strong>
              </span>
            ) : (
              <span className="text-warning-600">{t('treasury.szuneteltetve')}</span>
            )}
          </div>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => setAutoRefresh((v) => !v)} className="form-button h-8 text-xs">
            {autoRefresh ? <Pause size={16} /> : <Play size={16} />}
            <span>{autoRefresh ? 'Szünet' : 'Indít'}</span>
          </button>
          <button onClick={handleExport} className="form-button h-8 text-xs">
            <Download size={16} />
            <span>{t('treasury.exportCsv')}</span>
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4 px-4 py-3 bg-white border border-form-border rounded-lg">
        <div className="flex items-center gap-2">
          <label className="text-sm font-medium text-secondary-700">{t('audit.iroda')}</label>
          <select
            className="form-input w-48 h-8 text-xs"
            value={branchFilter}
            onChange={(e) => setBranchFilter(e.target.value)}
          >
            <option value="all">
              {t('treasury.mind')}
              {branchRows.length})
            </option>
            {branchRows.map((b) => (
              <option key={b.id} value={b.id}>
                {b.name}
              </option>
            ))}
          </select>
        </div>
        <div className="flex items-center gap-2">
          <label className="text-sm font-medium text-secondary-700">{t('components.valuta')}</label>
          <select
            className="form-input w-40 h-8 text-xs"
            value={currencyFilter}
            onChange={(e) => setCurrencyFilter(e.target.value)}
          >
            <option value="all">
              {t('treasury.mind')}
              {currencies.length})
            </option>
            <option value="top8">{t('treasury.top8')}</option>
            {currencies
              .filter((c) => c.active)
              .map((c) => (
                <option key={c.code} value={c.code}>
                  {c.code}
                </option>
              ))}
          </select>
        </div>
      </div>

      {/* Matrix table */}
      <div className="overflow-x-auto">
        <table className="data-grid w-full min-w-[1200px]">
          <thead>
            <tr>
              <th className="sticky left-0 bg-secondary-50 z-10 min-w-[180px]">
                {t('common.office')}
              </th>
              {displayCurrencies.map((c) => (
                <th key={c.code} className="text-right min-w-[80px]">
                  <div className="flex flex-col items-end">
                    <span className={`font-bold ${currencyColorClass(c.code)}`}>{c.code}</span>
                    <span className="text-xs text-secondary-500 font-normal">{c.symbol ?? ''}</span>
                  </div>
                </th>
              ))}
              <th className="text-right min-w-[100px]">{t('treasury.osszFt')}</th>
            </tr>
          </thead>
          <tbody>
            {displayBranches.map((branch) => (
              <tr key={branch.id} className="hover:bg-primary-50">
                <td className="sticky left-0 bg-white font-semibold text-secondary-900 z-10">
                  {branch.name}
                </td>
                {displayCurrencies.map((c) => {
                  const stock = branch.stocks.get(c.code) ?? 0
                  const level = getStockLevel(stock, c.code)
                  return (
                    <td key={c.code} className="text-right font-mono">
                      <div className="flex items-center justify-end gap-1">
                        <span className="text-xs">{stockLevelIcon(level)}</span>
                        <span className={stockLevelColor(level)}>{formatInteger(stock)}</span>
                      </div>
                    </td>
                  )
                })}
                <td className="text-right font-bold text-secondary-900 font-mono">
                  {formatMillions(branch.totalHuf)}
                </td>
              </tr>
            ))}
            {/* Summary row */}
            <tr className="bg-secondary-100 border-t-2 border-secondary-300">
              <td className="sticky left-0 bg-secondary-100 font-bold text-secondary-900 z-10">
                {t('treasury.osszes')}
              </td>
              {displayCurrencies.map((c) => (
                <td key={c.code} className="text-right font-mono font-bold text-secondary-900">
                  {formatInteger(currencyTotals.get(c.code) ?? 0)}
                </td>
              ))}
              <td className="text-right font-bold text-primary-700 text-lg font-mono">
                {formatMillions(grandTotal)}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      {/* Legend */}
      <div className="flex items-center gap-4 text-xs text-secondary-600">
        <span>{t('treasury.jelmagyarazat')}</span>
        <span>{t('treasury.NormalgtKuszob')}</span>
        <span>{t('treasury.AlacsonyKuszobgtKritikus')}</span>
        <span>{t('treasury.KritikusKritikus')}</span>
      </div>
    </div>
  )
}
