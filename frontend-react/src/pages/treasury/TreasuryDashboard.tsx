import { useState, useEffect, useCallback } from 'react'
import {
  ArrowLeftRight,
  TrendingUp,
  Users,
  Coins,
  ArrowUp,
  ArrowDown,
  Trophy,
  CheckCircle,
  Clock,
  XCircle,
  RefreshCw,
} from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
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

  const fetchData = useCallback(async () => {
    try {
      const [turnoverData, balanceDataRaw] = await Promise.all([
        transactionApi.getDailyTurnover().catch(() => null),
        cashBalanceApi.getCompanyBalances().catch(() => []),
      ])

      if (turnoverData) setTurnover(turnoverData)
      const balanceData = safeArray<CashBalance>(balanceDataRaw)
      setBalances(balanceData)

      // Build branch rankings from balance data (group by branch)
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

      // Fetch closing statuses
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
      // Add branches without session
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
    const interval = setInterval(() => void fetchData(), 60_000) // 60s polling
    return () => clearInterval(interval)
  }, [fetchData])

  // R = manual refresh
  useHotkeys('r', () => void fetchData(), { enableOnFormTags: false })

  if (loading) return <DashboardSkeleton />

  const totalTx = (turnover?.totalBuyCount ?? 0) + (turnover?.totalSellCount ?? 0)
  const totalVolume = (turnover?.totalBuyHuf ?? 0) + (turnover?.totalSellHuf ?? 0)
  const totalCustomers = turnover?.totalBuyCount ?? 0 // approximation
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

      {/* KPI Cards */}
      <div className="grid grid-cols-4 gap-4">
        <KpiCard
          icon={ArrowLeftRight}
          label="Mai tranzakciók"
          value={formatInteger(totalTx)}
          trend={totalTx > 0 ? 'up' : undefined}
          trendLabel={`${totalTx} db`}
          bgFrom="from-primary-50"
          bgTo="to-primary-100"
          borderColor="border-primary-200"
          iconBg="bg-primary-100"
          iconColor="text-primary-600"
        />
        <KpiCard
          icon={TrendingUp}
          label="Napi forgalom"
          value={formatMillions(totalVolume)}
          trend={totalVolume > 0 ? 'up' : undefined}
          trendLabel={formatMillions(totalVolume)}
          bgFrom="from-success-50"
          bgTo="to-success-100"
          borderColor="border-success-200"
          iconBg="bg-success-100"
          iconColor="text-success-600"
        />
        <KpiCard
          icon={Users}
          label="Kiszolgált ügyfelek"
          value={formatInteger(totalCustomers)}
          trend={totalCustomers > 0 ? 'up' : undefined}
          trendLabel={`${totalCustomers} fő`}
          bgFrom="from-accent-50"
          bgTo="to-accent-100"
          borderColor="border-accent-200"
          iconBg="bg-accent-100"
          iconColor="text-accent-600"
        />
        <KpiCard
          icon={Coins}
          label="Készlet érték (összes)"
          value={formatMillions(totalStockValue)}
          trend={undefined}
          trendLabel=""
          bgFrom="from-secondary-50"
          bgTo="to-secondary-100"
          borderColor="border-secondary-200"
          iconBg="bg-secondary-100"
          iconColor="text-secondary-600"
        />
      </div>

      {/* Two-column: Top Branches + Closing status */}
      <div className="grid grid-cols-2 gap-4">
        {/* TOP Irodák */}
        <div className="form-panel">
          <h2 className="text-lg font-bold text-secondary-900 mb-4 flex items-center gap-2">
            <Trophy size={20} className="text-accent-600" />
            TOP Irodák (készlet érték)
          </h2>
          <div className="space-y-3">
            {topBranches.length === 0 && (
              <p className="text-sm text-secondary-400">Nincs adat</p>
            )}
            {topBranches.map((branch, index) => (
              <div key={branch.id} className="flex items-center gap-3">
                <div className="w-8 h-8 flex items-center justify-center bg-primary-100 text-primary-700 font-bold rounded-lg text-sm">
                  {index + 1}
                </div>
                <div className="flex-1">
                  <div className="flex items-baseline justify-between mb-1">
                    <span className="font-semibold text-secondary-900 text-sm">{branch.name}</span>
                    <span className="text-xs text-secondary-600">
                      {formatMillions(branch.revenue)} ({branch.percentage}%)
                    </span>
                  </div>
                  <div className="h-2 bg-secondary-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-primary-500 to-primary-600 transition-all duration-500"
                      style={{ width: `${branch.percentage}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Zárási állapot */}
        <div className="form-panel">
          <h2 className="text-lg font-bold text-secondary-900 mb-4 flex items-center gap-2">
            <CheckCircle size={20} className="text-success-600" />
            Zárási állapot (ma)
          </h2>
          <div className="flex flex-wrap gap-2 mb-4">
            {closingStatuses.map((branch) => (
              <div
                key={branch.id}
                className={`px-3 py-2 rounded-lg border text-sm font-semibold flex items-center gap-2 ${
                  branch.closingStatus === 'CLOSED'
                    ? 'bg-success-50 border-success-200 text-success-700'
                    : branch.closingStatus === 'IN_PROGRESS'
                      ? 'bg-warning-50 border-warning-200 text-warning-700'
                      : 'bg-danger-50 border-danger-200 text-danger-700'
                }`}
              >
                {branch.closingStatus === 'CLOSED' && <CheckCircle size={16} />}
                {branch.closingStatus === 'IN_PROGRESS' && <Clock size={16} />}
                {branch.closingStatus === 'NOT_CLOSED' && <XCircle size={16} />}
                {branch.shortName}
              </div>
            ))}
            {closingStatuses.length === 0 && (
              <p className="text-sm text-secondary-400">Nincs iroda adat</p>
            )}
          </div>
          {closingStatuses.length > 0 && (
            <div className="text-sm text-secondary-600">
              Státusz: <strong>{closedCount}/{closingStatuses.length}</strong> iroda zárva
              {inProgressCount > 0 && <>, <strong>{inProgressCount}</strong> folyamatban</>}
              {notClosedCount > 0 && <>, <strong>{notClosedCount}</strong> hiányzik</>}
            </div>
          )}
        </div>
      </div>

      {/* Bank forgalom (summary) */}
      <div className="form-panel">
        <h2 className="text-lg font-bold text-secondary-900 mb-4 flex items-center gap-2">
          <TrendingUp size={20} className="text-primary-600" />
          Forgalom összesítés
        </h2>
        <div className="grid grid-cols-5 gap-4">
          <SummaryItem label="Vétel (db)" value={formatInteger(turnover?.totalBuyCount ?? 0)} />
          <SummaryItem label="Eladás (db)" value={formatInteger(turnover?.totalSellCount ?? 0)} />
          <SummaryItem label="Vétel (HUF)" value={formatMillions(turnover?.totalBuyHuf ?? 0)} accent />
          <SummaryItem label="Eladás (HUF)" value={formatMillions(turnover?.totalSellHuf ?? 0)} accent />
          <SummaryItem label="Kezelési díjak" value={formatMillions(turnover?.totalHandlingFees ?? 0)} />
        </div>
      </div>
    </div>
  )
}

// ---- Sub-components ----

interface KpiCardProps {
  icon: React.ComponentType<{ size?: number | string; className?: string }>
  label: string
  value: string
  trend?: 'up' | 'down'
  trendLabel: string
  bgFrom: string
  bgTo: string
  borderColor: string
  iconBg: string
  iconColor: string
}

function KpiCard({
  icon: Icon,
  label,
  value,
  trend,
  trendLabel,
  bgFrom,
  bgTo,
  borderColor,
  iconBg,
  iconColor,
}: KpiCardProps) {
  return (
    <div className={`stat-card bg-gradient-to-br ${bgFrom} ${bgTo} border ${borderColor}`}>
      <div className="flex items-start justify-between mb-3">
        <div className={`p-2.5 rounded-lg ${iconBg} ${iconColor}`}>
          <Icon size={20} />
        </div>
        {trend && (
          <div
            className={`flex items-center gap-1 text-xs font-semibold ${
              trend === 'up' ? 'text-success-700' : 'text-danger-700'
            }`}
          >
            {trend === 'up' ? <ArrowUp size={14} /> : <ArrowDown size={14} />}
            {trendLabel}
          </div>
        )}
      </div>
      <div className="text-sm text-secondary-600 mb-1">{label}</div>
      <div className="text-lg font-bold text-secondary-900 font-mono">{value}</div>
    </div>
  )
}

function SummaryItem({ label, value, accent }: { label: string; value: string; accent?: boolean }) {
  return (
    <div className="p-3 bg-secondary-50 border border-secondary-200 rounded-lg">
      <div className="text-xs text-secondary-600 mb-1">{label}</div>
      <div className={`text-lg font-bold font-mono ${accent ? 'text-primary-700' : 'text-secondary-900'}`}>
        {value}
      </div>
    </div>
  )
}
