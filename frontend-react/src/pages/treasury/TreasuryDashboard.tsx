import { useState, useEffect, useCallback } from 'react'
import {
  Trophy,
  CheckCircle,
  Clock,
  XCircle,
  RefreshCw,
  Lock,
} from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
import { AxiosError } from 'axios'
import { transactionApi, cashBalanceApi, dailySessionApi } from '../../services/api/index'
import type { DailyTurnoverSummary, CashBalance, DailySession } from '../../services/api/index'
import { formatInteger, formatMillions } from './treasuryUtils'
import { DashboardSkeleton } from './LoadingSkeleton'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'

interface BranchRanking {
  id: string
  name: string
  revenue: number
  percentage: number
}

type ClosingStatus = 'CLOSED' | 'IN_PROGRESS' | 'NOT_CLOSED'

interface BranchClosing {
  id: string
  name: string
  shortName: string
  closingStatus: ClosingStatus
}

export default function TreasuryDashboard() {
  const [loading, setLoading] = useState(true)
  const [turnover, setTurnover] = useState<DailyTurnoverSummary | null>(null)
  const [balances, setBalances] = useState<CashBalance[]>([])
  const [topBranches, setTopBranches] = useState<BranchRanking[]>([])
  const [closingStatuses, setClosingStatuses] = useState<BranchClosing[]>([])
  const [lastRefresh, setLastRefresh] = useState(new Date())
  // v2.5.3: ha a /cash-balances/company endpoint 403-at ad (csak MANAGER+ ADMIN
  // hozzáfér), a UI "Korlátozott jogosultság" panellel jelzi a SUPERVISOR
  // szerepkörű értéktárosnak — toast helyett (Codex-style: NEM eltüntetjük az
  // információt, csak a riasztó modal-szerű hibajelzést kapcsoljuk ki).
  const [companyBalanceRestricted, setCompanyBalanceRestricted] = useState(false)

  const fetchData = useCallback(async () => {
    try {
      const [turnoverData, balanceDataRaw] = await Promise.all([
        transactionApi.getDailyTurnover().catch(() => null),
        cashBalanceApi.getCompanyBalances().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setCompanyBalanceRestricted(true)
          }
          return []
        }),
      ])

      if (turnoverData) setTurnover(turnoverData)
      const balanceData = safeArray<CashBalance>(balanceDataRaw)
      setBalances(balanceData)

      const branchMap = new Map<string, { id: string; name: string; total: number }>()
      for (const b of balanceData) {
        const existing = branchMap.get(b.branchId)
        if (existing) {
          existing.total += b.currentBalance
        } else {
          branchMap.set(b.branchId, {
            id: b.branchId,
            name: b.branchName ?? b.branchId,
            total: b.currentBalance,
          })
        }
      }
      const sorted = Array.from(branchMap.values()).sort((a, b) => b.total - a.total)
      const grandTotal = sorted.reduce((sum, b) => sum + b.total, 0)
      setTopBranches(
        sorted.slice(0, 5).map((b) => ({
          id: b.id,
          name: b.name,
          revenue: b.total,
          percentage: grandTotal > 0 ? Math.round((b.total / grandTotal) * 100) : 0,
        }))
      )

      const today = new Date().toISOString().slice(0, 10)
      const sessionsRaw = await dailySessionApi
        .getHistory(today, today)
        .catch(() => [])
      const sessions = safeArray<DailySession>(sessionsRaw)

      const closingMap = new Map<string, BranchClosing>()
      for (const s of sessions) {
        closingMap.set(s.branchId, {
          id: s.branchId,
          name: s.branchName ?? s.branchId,
          shortName: (s.branchName ?? s.branchId).split(' ').slice(0, 2).join(' '),
          closingStatus: s.status === 'CLOSED' ? 'CLOSED' : 'IN_PROGRESS',
        })
      }
      for (const b of sorted) {
        if (!closingMap.has(b.id)) {
          closingMap.set(b.id, {
            id: b.id,
            name: b.name,
            shortName: b.name.split(' ').slice(0, 2).join(' '),
            closingStatus: 'NOT_CLOSED',
          })
        }
      }
      setClosingStatuses(Array.from(closingMap.values()))

      setLastRefresh(new Date())
    } catch (err) {
      logger.error('TreasuryDashboard', 'Treasury dashboard fetch error:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void fetchData()
    const interval = setInterval(() => void fetchData(), 60_000)
    return () => clearInterval(interval)
  }, [fetchData])

  useHotkeys('r', () => void fetchData(), { enableOnFormTags: false })

  if (loading) return <DashboardSkeleton />

  const totalTx = (turnover?.totalBuyCount ?? 0) + (turnover?.totalSellCount ?? 0)
  const totalVolume = (turnover?.totalBuyHuf ?? 0) + (turnover?.totalSellHuf ?? 0)
  const totalCustomers = turnover?.totalBuyCount ?? 0
  const totalStockValue = balances.reduce((sum, b) => sum + b.currentBalance, 0)

  const closedCount = closingStatuses.filter((s) => s.closingStatus === 'CLOSED').length
  const inProgressCount = closingStatuses.filter((s) => s.closingStatus === 'IN_PROGRESS').length
  const notClosedCount = closingStatuses.filter((s) => s.closingStatus === 'NOT_CLOSED').length

  return (
    <div className="space-y-3">
      {/* Page header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-lg font-bold text-secondary-900">Értéktári Dashboard</h1>
          <p className="text-sm text-secondary-500 mt-1">
            Összesített készlet, forgalom, irodai rangsor
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={() => void fetchData()} className="form-button h-8 text-xs">
            <RefreshCw size={14} />
            <span>Frissítés</span>
          </button>
          <span className="text-xs text-secondary-400">
            {lastRefresh.toLocaleTimeString('hu-HU')}
          </span>
        </div>
      </div>

      {/* v2.5.3: Korlátozott jogosultság jelzés — ha a /cash-balances/company 403-at ad
          (SUPERVISOR és alacsonyabb role-oknak), nem dobunk modal toast-ot, hanem
          informatív panellel jelezzük, hogy a "Készlet érték (összes)" + TOP Irodák
          szekciók korlátozottak. */}
      {companyBalanceRestricted && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 flex items-start gap-2">
          <Lock size={18} className="text-amber-600 shrink-0 mt-0.5" />
          <div className="text-sm">
            <p className="font-semibold text-amber-900">Korlátozott jogosultság</p>
            <p className="text-xs text-amber-800">
              Az összesített készlet és TOP-irodák lekérdezéséhez MANAGER vagy ADMIN
              szerepkör szükséges. A napi forgalom és tranzakció-adatok elérhetők.
            </p>
          </div>
        </div>
      )}

      {/* Compact data row — egyszerű számok, nincs grafikon */}
      <div className="form-panel">
        <div className="grid grid-cols-4 gap-x-6 gap-y-2 text-sm">
          <DataRow label="Mai tranzakciók" value={`${formatInteger(totalTx)} db`} />
          <DataRow label="Napi forgalom" value={formatMillions(totalVolume)} accent />
          <DataRow label="Kiszolgált ügyfelek" value={`${formatInteger(totalCustomers)} fő`} />
          <DataRow
            label="Készlet érték (összes)"
            value={companyBalanceRestricted ? '— (jogosultság)' : formatMillions(totalStockValue)}
            accent={!companyBalanceRestricted}
          />
          <DataRow label="Vétel (db)" value={formatInteger(turnover?.totalBuyCount ?? 0)} />
          <DataRow label="Eladás (db)" value={formatInteger(turnover?.totalSellCount ?? 0)} />
          <DataRow label="Vétel (HUF)" value={formatMillions(turnover?.totalBuyHuf ?? 0)} />
          <DataRow label="Eladás (HUF)" value={formatMillions(turnover?.totalSellHuf ?? 0)} />
          <DataRow label="Kezelési díjak" value={formatMillions(turnover?.totalHandlingFees ?? 0)} />
        </div>
      </div>

      {/* TOP Irodák — egyszerű lista, nincs progress bar */}
      <div className="grid grid-cols-2 gap-4">
        <div className="form-panel">
          <h2 className="text-base font-bold text-secondary-900 mb-3 flex items-center gap-2">
            <Trophy size={18} className="text-accent-600" />
            TOP Irodák (készlet érték)
          </h2>
          {topBranches.length === 0 ? (
            <p className="text-sm text-secondary-400">Nincs adat</p>
          ) : (
            <table className="w-full text-sm">
              <tbody>
                {topBranches.map((branch, index) => (
                  <tr key={branch.id} className="border-b border-secondary-100 last:border-0">
                    <td className="py-1.5 pr-2 w-8 text-secondary-500 font-mono">{index + 1}.</td>
                    <td className="py-1.5 pr-2 font-medium text-secondary-900">{branch.name}</td>
                    <td className="py-1.5 text-right font-mono text-secondary-700">
                      {formatMillions(branch.revenue)}
                    </td>
                    <td className="py-1.5 pl-2 text-right text-xs text-secondary-500 w-12">
                      {branch.percentage}%
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* Zárási állapot */}
        <div className="form-panel">
          <h2 className="text-base font-bold text-secondary-900 mb-3 flex items-center gap-2">
            <CheckCircle size={18} className="text-success-600" />
            Zárási állapot (ma)
          </h2>
          <div className="flex flex-wrap gap-1.5 mb-3">
            {closingStatuses.map((branch) => (
              <div
                key={branch.id}
                className={`px-2 py-1 rounded border text-xs font-semibold flex items-center gap-1 ${
                  branch.closingStatus === 'CLOSED'
                    ? 'bg-success-50 border-success-200 text-success-700'
                    : branch.closingStatus === 'IN_PROGRESS'
                      ? 'bg-warning-50 border-warning-200 text-warning-700'
                      : 'bg-danger-50 border-danger-200 text-danger-700'
                }`}
              >
                {branch.closingStatus === 'CLOSED' && <CheckCircle size={12} />}
                {branch.closingStatus === 'IN_PROGRESS' && <Clock size={12} />}
                {branch.closingStatus === 'NOT_CLOSED' && <XCircle size={12} />}
                {branch.shortName}
              </div>
            ))}
            {closingStatuses.length === 0 && (
              <p className="text-sm text-secondary-400">Nincs iroda adat</p>
            )}
          </div>
          {closingStatuses.length > 0 && (
            <div className="text-xs text-secondary-600">
              <strong>{closedCount}/{closingStatuses.length}</strong> zárva
              {inProgressCount > 0 && <>, <strong>{inProgressCount}</strong> folyamatban</>}
              {notClosedCount > 0 && <>, <strong>{notClosedCount}</strong> hiányzik</>}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function DataRow({ label, value, accent }: { label: string; value: string; accent?: boolean }) {
  return (
    <div className="flex justify-between items-baseline border-b border-secondary-100 pb-1.5">
      <span className="text-secondary-600">{label}</span>
      <span className={`font-mono font-semibold ${accent ? 'text-primary-700' : 'text-secondary-900'}`}>
        {value}
      </span>
    </div>
  )
}
