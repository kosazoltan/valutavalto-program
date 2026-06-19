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
import { transactionApi, cashBalanceApi, dailySessionApi, treasuryApi, ertektarApi } from '../../services/api/index'
import type {
  DailyTurnoverSummary,
  CashBalance,
  CurrencyTotalBalance,
  CompanyCashPosition,
  DailySession,
  TreasuryDashboardSummary,
  TreasuryBranchComparison,
  TreasurySubmissionStatus,
  TreasuryBankFlow,
  TreasuryAggregate,
  BranchStatusResponse,
  ErtektarConsolidatedReport,
  BankTransaction,
  ErtektarCollection,
  ErtektarDistribution,
  VaultOperationStatus,
  VaultTransferItem,
  MaterialReceiptItem,
  StockCorrectionItem,
} from '../../services/api/index'
import { formatInteger, formatMillions } from './treasuryUtils'
import { DashboardSkeleton } from './LoadingSkeleton'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { localIsoDate } from '../../utils/dateFormat'
import { useTranslation } from 'react-i18next'

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
  const { t } = useTranslation()
  const [loading, setLoading] = useState(true)
  const [turnover, setTurnover] = useState<DailyTurnoverSummary | null>(null)
  const [companyPosition, setCompanyPosition] = useState<CompanyCashPosition | null>(null)
  const [companyTotals, setCompanyTotals] = useState<CurrencyTotalBalance[]>([])
  const [lowBalanceAlerts, setLowBalanceAlerts] = useState<CashBalance[]>([])
  const [highBalanceAlerts, setHighBalanceAlerts] = useState<CashBalance[]>([])
  const [topBranches, setTopBranches] = useState<BranchRanking[]>([])
  const [closingStatuses, setClosingStatuses] = useState<BranchClosing[]>([])
  const [treasurySummary, setTreasurySummary] = useState<TreasuryDashboardSummary | null>(null)
  const [branchComparison, setBranchComparison] = useState<TreasuryBranchComparison[]>([])
  const [submissionStatus, setSubmissionStatus] = useState<TreasurySubmissionStatus[]>([])
  const [bankFlow, setBankFlow] = useState<TreasuryBankFlow[]>([])
  const [branchGroupSummary, setBranchGroupSummary] = useState<TreasuryAggregate[]>([])
  const [companySummary, setCompanySummary] = useState<TreasuryAggregate[]>([])
  const [ertektarBranches, setErtektarBranches] = useState<BranchStatusResponse[]>([])
  const [ertektarConsolidatedReport, setErtektarConsolidatedReport] = useState<ErtektarConsolidatedReport | null>(null)
  const [ertektarCollections, setErtektarCollections] = useState<ErtektarCollection[]>([])
  const [ertektarDistributions, setErtektarDistributions] = useState<ErtektarDistribution[]>([])
  const [ertektarBankTransactions, setErtektarBankTransactions] = useState<BankTransaction[]>([])
  const [ertektarTransfers, setErtektarTransfers] = useState<VaultTransferItem[]>([])
  const [ertektarPendingTransfers, setErtektarPendingTransfers] = useState<VaultTransferItem[]>([])
  const [materialReceipts, setMaterialReceipts] = useState<MaterialReceiptItem[]>([])
  const [materialReceiptsIn, setMaterialReceiptsIn] = useState<MaterialReceiptItem[]>([])
  const [materialReceiptsOut, setMaterialReceiptsOut] = useState<MaterialReceiptItem[]>([])
  const [stockCorrections, setStockCorrections] = useState<StockCorrectionItem[]>([])
  const [pendingStockCorrections, setPendingStockCorrections] = useState<StockCorrectionItem[]>([])
  const [statusAction, setStatusAction] = useState<string | null>(null)
  const [statusActionError, setStatusActionError] = useState<string | null>(null)
  const [treasuryApiRestricted, setTreasuryApiRestricted] = useState(false)
  const [lastRefresh, setLastRefresh] = useState(new Date())
  // v2.5.3: ha a /cash-balances/company endpoint 403-at ad (csak MANAGER+ ADMIN
  // hozzáfér), a UI "Korlátozott jogosultság" panellel jelzi a SUPERVISOR
  // szerepkörű értéktárosnak — toast helyett (Codex-style: NEM eltüntetjük az
  // információt, csak a riasztó modal-szerű hibajelzést kapcsoljuk ki).
  const [companyBalanceRestricted, setCompanyBalanceRestricted] = useState(false)

  const fetchData = useCallback(async () => {
    try {
      setCompanyBalanceRestricted(false)
      setTreasuryApiRestricted(false)

      const [
        turnoverData,
        balanceDataRaw,
        companyPositionData,
        companyTotalsData,
        lowBalanceAlertsData,
        highBalanceAlertsData,
        treasuryDashboardData,
        branchComparisonData,
        submissionStatusData,
        bankFlowData,
        branchGroupSummaryData,
        companySummaryData,
        ertektarBranchesData,
        ertektarConsolidatedReportData,
        ertektarCollectionsData,
        ertektarDistributionsData,
        ertektarBankTransactionsData,
        ertektarTransfersData,
        ertektarPendingTransfersData,
        materialReceiptsData,
        materialReceiptsInData,
        materialReceiptsOutData,
        stockCorrectionsData,
        pendingStockCorrectionsData,
      ] = await Promise.all([
        transactionApi.getDailyTurnover().catch(() => null),
        cashBalanceApi.getCompanyBalances().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setCompanyBalanceRestricted(true)
          }
          return []
        }),
        cashBalanceApi.getCompanyPosition().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setCompanyBalanceRestricted(true)
          }
          return null
        }),
        cashBalanceApi.getCompanyTotals().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setCompanyBalanceRestricted(true)
          }
          return []
        }),
        cashBalanceApi.getLowAlerts().catch(() => []),
        cashBalanceApi.getHighAlerts().catch(() => []),
        treasuryApi.dashboard().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return null
        }),
        treasuryApi.branchComparison().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        treasuryApi.submissionStatus().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        treasuryApi.bankFlow().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        treasuryApi.branchGroupSummary().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        treasuryApi.companySummary().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        treasuryApi.ertektarBranches().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return {}
        }),
        treasuryApi.ertektarConsolidatedReport().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return null
        }),
        ertektarApi.getCollections().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        ertektarApi.getDistributions().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        ertektarApi.getBankTransactions().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        ertektarApi.getTransfers().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        ertektarApi.getPendingTransfers().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        ertektarApi.getReceipts().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        ertektarApi.getReceiptsByType('B').catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        ertektarApi.getReceiptsByType('K').catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        ertektarApi.getCorrections().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
        ertektarApi.getPendingCorrections().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return []
        }),
      ])

      if (turnoverData) setTurnover(turnoverData)
      setCompanyPosition(companyPositionData)
      setCompanyTotals(safeArray<CurrencyTotalBalance>(companyTotalsData))
      setLowBalanceAlerts(safeArray<CashBalance>(lowBalanceAlertsData))
      setHighBalanceAlerts(safeArray<CashBalance>(highBalanceAlertsData))
      setTreasurySummary(treasuryDashboardData)
      setBranchComparison(safeArray<TreasuryBranchComparison>(branchComparisonData))
      setSubmissionStatus(safeArray<TreasurySubmissionStatus>(submissionStatusData))
      setBankFlow(safeArray<TreasuryBankFlow>(bankFlowData))
      setBranchGroupSummary(safeArray<TreasuryAggregate>(branchGroupSummaryData))
      setCompanySummary(safeArray<TreasuryAggregate>(companySummaryData))
      setErtektarBranches(Object.values(ertektarBranchesData ?? {}))
      setErtektarConsolidatedReport(ertektarConsolidatedReportData)
      setErtektarCollections(safeArray<ErtektarCollection>(ertektarCollectionsData))
      setErtektarDistributions(safeArray<ErtektarDistribution>(ertektarDistributionsData))
      setErtektarBankTransactions(safeArray<BankTransaction>(ertektarBankTransactionsData))
      setErtektarTransfers(safeArray<VaultTransferItem>(ertektarTransfersData))
      setErtektarPendingTransfers(safeArray<VaultTransferItem>(ertektarPendingTransfersData))
      setMaterialReceipts(safeArray<MaterialReceiptItem>(materialReceiptsData))
      setMaterialReceiptsIn(safeArray<MaterialReceiptItem>(materialReceiptsInData))
      setMaterialReceiptsOut(safeArray<MaterialReceiptItem>(materialReceiptsOutData))
      setStockCorrections(safeArray<StockCorrectionItem>(stockCorrectionsData))
      setPendingStockCorrections(safeArray<StockCorrectionItem>(pendingStockCorrectionsData))
      const balanceData = safeArray<CashBalance>(balanceDataRaw)

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

      const today = localIsoDate()
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

  const updateErtektarStatus = async (
    kind: 'collection' | 'distribution' | 'bankTransaction',
    id: number,
    status: VaultOperationStatus,
  ) => {
    if (!window.confirm(`Biztosan ${status} státuszra állítja az értéktári tételt?`)) return

    const actionKey = `${kind}:${id}:${status}`
    try {
      setStatusAction(actionKey)
      setStatusActionError(null)
      if (kind === 'collection') {
        await ertektarApi.updateCollectionStatus(id, status)
      } else if (kind === 'distribution') {
        await ertektarApi.updateDistributionStatus(id, status)
      } else {
        await ertektarApi.updateBankTransactionStatus(id, status)
      }
      await fetchData()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Értéktári státuszváltás sikertelen.'
      setStatusActionError(message)
      logger.error('TreasuryDashboard', 'Ertektar status update error:', err)
    } finally {
      setStatusAction(null)
    }
  }

  if (loading) return <DashboardSkeleton />

  const totalTx = (turnover?.totalBuyCount ?? 0) + (turnover?.totalSellCount ?? 0)
  const totalVolume = (turnover?.totalBuyHuf ?? 0) + (turnover?.totalSellHuf ?? 0)
  const totalCustomers = turnover?.totalBuyCount ?? 0
  const totalStockValue = companyPosition?.grandTotalHuf ?? 0

  const closedCount = closingStatuses.filter((s) => s.closingStatus === 'CLOSED').length
  const inProgressCount = closingStatuses.filter((s) => s.closingStatus === 'IN_PROGRESS').length
  const notClosedCount = closingStatuses.filter((s) => s.closingStatus === 'NOT_CLOSED').length
  const submittedCount = submissionStatus.filter((s) => s.submitted).length
  const missingSubmissionCount = submissionStatus.filter((s) => !s.submitted).length
  const topBackendBranches = [...branchComparison]
    .sort((a, b) => Number(b.totalProfit ?? 0) - Number(a.totalProfit ?? 0))
    .slice(0, 3)
  const topBankFlow = bankFlow[0]
  const topBranchGroup = branchGroupSummary[0]
  const topCompanySummary = companySummary[0]
  const topCompanyTotal = [...companyTotals]
    .sort((a, b) => Number(b.totalBalance ?? 0) - Number(a.totalBalance ?? 0))[0]
  const stockAlertCount = lowBalanceAlerts.length + highBalanceAlerts.length
  const ertektarOnlineCount = ertektarBranches.filter((b) => b.isOnline ?? b.online).length
  const ertektarOfflineCount = ertektarBranches.filter((b) => !(b.isOnline ?? b.online)).length
  const ertektarOpenAlerts = ertektarBranches.reduce((sum, b) => sum + (b.openAlerts ?? 0), 0)
  const consolidatedTotals = ertektarConsolidatedReport?.totals
  const consolidatedBranchCount = ertektarConsolidatedReport?.branches?.length ?? 0
  const openCollections = ertektarCollections.filter((row) => row.status !== 'COMPLETED' && row.status !== 'REJECTED').slice(0, 3)
  const openDistributions = ertektarDistributions.filter((row) => row.status !== 'COMPLETED' && row.status !== 'REJECTED').slice(0, 3)
  const openBankTransactions = ertektarBankTransactions.filter((row) => row.status !== 'COMPLETED' && row.status !== 'REJECTED').slice(0, 3)
  const recentTransfers = ertektarTransfers.slice(0, 3)
  const recentReceipts = materialReceipts.slice(0, 3)
  const recentCorrections = stockCorrections.slice(0, 3)

  return (
    <div className="space-y-3">
      {/* Page header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-lg font-bold text-secondary-900">{t('treasury.ertektariDashboard')}</h1>
          <p className="text-sm text-secondary-500 mt-1">
            {t('treasury.osszesitettKeszletForgalomIrodaiRangsor')}
          </p>
        </div>
        <div className="flex items-center gap-3">
          <button onClick={() => void fetchData()} className="form-button h-8 text-xs">
            <RefreshCw size={14} />
            <span>{t('common.refresh')}</span>
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
            <p className="font-semibold text-amber-900">{t('treasury.korlatozottJogosultsag')}</p>
            <p className="text-xs text-amber-800">
              {t('treasury.azOsszesitettKeszletEsTopIrodakLekerdezesehezManagerVagyAdmin')}
              {t('treasury.szerepkorSzuksegesANapiForgalomEsTranzakcioAdatokElerhetok')}
            </p>
          </div>
        </div>
      )}

      {treasuryApiRestricted && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 flex items-start gap-2">
          <Lock size={18} className="text-amber-600 shrink-0 mt-0.5" />
          <div className="text-sm">
            <p className="font-semibold text-amber-900">{t('treasury.dedikaltTreasuryApiKorlatozott')}</p>
            <p className="text-xs text-amber-800">{t('treasury.treasuryOsszesitokManagerVagyAdmin')}</p>
          </div>
        </div>
      )}

      <div className="form-panel">
        <div className="grid grid-cols-1 gap-3 md:grid-cols-3 xl:grid-cols-6">
          <SummaryCard
            label="Backend treasury összesítő"
            value={`${formatInteger(treasurySummary?.totalTransactionCount ?? 0)} db`}
            detail={`${formatMillions(Number(treasurySummary?.totalProfit ?? 0))} profit`}
          />
          <SummaryCard
            label="Fiók összehasonlítás"
            value={`${formatInteger(branchComparison.length)} iroda`}
            detail={topBackendBranches[0]?.branchName ?? topBackendBranches[0]?.branchCode ?? 'Nincs adat'}
          />
          <SummaryCard
            label="Beküldési státusz"
            value={`${submittedCount}/${submissionStatus.length}`}
            detail={missingSubmissionCount > 0 ? `${missingSubmissionCount} hiányzó jelentés` : 'Minden jelentés beérkezett'}
          />
          <SummaryCard
            label="Értéktári pénztár monitoring"
            value={`${ertektarOnlineCount}/${ertektarBranches.length} online`}
            detail={ertektarOfflineCount > 0 ? `${ertektarOfflineCount} offline, ${ertektarOpenAlerts} riasztás` : `${ertektarOpenAlerts} nyitott riasztás`}
          />
          <SummaryCard
            label="Értéktári konszolidált riport"
            value={`${formatInteger(consolidatedTotals?.totalTransactions ?? 0)} db`}
            detail={`${formatMillions(Number(consolidatedTotals?.totalHufTurnover ?? 0))} / ${consolidatedBranchCount} iroda`}
          />
          <SummaryCard
            label="Készlet riasztások"
            value={`${formatInteger(stockAlertCount)} jelzés`}
            detail={`${formatInteger(lowBalanceAlerts.length)} alacsony, ${formatInteger(highBalanceAlerts.length)} magas`}
          />
        </div>
      </div>

      <div className="form-panel">
        <div className="grid grid-cols-1 gap-3 md:grid-cols-4">
          <SummaryCard
            label="Bankflow összesítő"
            value={topBankFlow?.currencyCode ?? 'Nincs adat'}
            detail={topBankFlow ? `${formatMillions(Number(topBankFlow.netFlow ?? 0))} nettó` : 'Nincs bankflow adat'}
          />
          <SummaryCard
            label="Fiókcsoport összesítő"
            value={`${formatInteger(branchGroupSummary.length)} csoport`}
            detail={topBranchGroup?.name ?? topBranchGroup?.code ?? 'Nincs adat'}
          />
          <SummaryCard
            label="Cégösszesítő"
            value={`${formatInteger(companySummary.length)} egység`}
            detail={topCompanySummary ? `${formatMillions(Number(topCompanySummary.totalProfit ?? 0))} profit` : 'Nincs adat'}
          />
          <SummaryCard
            label="Valutánkénti készlet"
            value={`${formatInteger(companyTotals.length)} valuta`}
            detail={topCompanyTotal ? `${topCompanyTotal.currencyCode} ${formatInteger(Number(topCompanyTotal.totalBalance ?? 0))}` : 'Nincs adat'}
          />
        </div>
      </div>

      <div className="form-panel" data-testid="ertektar-status-control">
        <div className="mb-3 flex items-center justify-between gap-2">
          <h2 className="text-base font-bold text-secondary-900">Értéktári státusz kontroll</h2>
          <span className="text-xs text-secondary-500">
            {openCollections.length + openDistributions.length + openBankTransactions.length} nyitott tétel
          </span>
        </div>
        {statusActionError && (
          <div className="mb-3 rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
            {statusActionError}
          </div>
        )}
        <div className="grid grid-cols-1 gap-3 lg:grid-cols-3">
          <StatusQueue
            title="Begyűjtés"
            rows={openCollections.map((row) => ({
              id: row.id,
              status: row.status,
              primary: row.sourceBranchName ?? row.sourceBranchCode ?? `#${row.id}`,
              secondary: `${row.currencyCode ?? '-'} ${formatInteger(Number(row.amount ?? 0))}`,
            }))}
            kind="collection"
            busyKey={statusAction}
            onUpdate={updateErtektarStatus}
          />
          <StatusQueue
            title="Szétosztás"
            rows={openDistributions.map((row) => ({
              id: row.id,
              status: row.status,
              primary: row.lines?.[0]?.targetBranchName ?? row.lines?.[0]?.targetBranchCode ?? `#${row.id}`,
              secondary: `${row.lines?.length ?? 0} sor`,
            }))}
            kind="distribution"
            busyKey={statusAction}
            onUpdate={updateErtektarStatus}
          />
          <StatusQueue
            title="Banki tranzakció"
            rows={openBankTransactions.map((row) => ({
              id: row.id,
              status: row.status,
              primary: `${row.transactionType} ${row.currencyCode}`,
              secondary: `${formatInteger(Number(row.amount ?? 0))} / ${row.bankName ?? '-'}`,
            }))}
            kind="bankTransaction"
            busyKey={statusAction}
            onUpdate={updateErtektarStatus}
          />
        </div>
      </div>

      <div className="form-panel" data-testid="ertektar-readonly-ledger">
        <div className="mb-3 flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
          <h2 className="text-base font-bold text-secondary-900">Értéktári bizonylat és korrekció áttekintés</h2>
          <span className="text-xs text-secondary-500">
            {formatInteger(ertektarTransfers.length + materialReceipts.length + stockCorrections.length)} listázott tétel
          </span>
        </div>
        <div className="grid grid-cols-1 gap-3 lg:grid-cols-3">
          <ReadOnlyQueue
            title="Áttételek"
            summary={`${formatInteger(ertektarPendingTransfers.length)} függő / ${formatInteger(ertektarTransfers.length)} összes`}
            rows={recentTransfers.map((row) => ({
              id: row.id,
              primary: row.transferNumber,
              secondary: `${row.currencyCode} ${formatInteger(Number(row.amount ?? 0))}`,
              status: row.status,
            }))}
          />
          <ReadOnlyQueue
            title="Anyagbizonylatok"
            summary={`${formatInteger(materialReceiptsIn.length)} bevét / ${formatInteger(materialReceiptsOut.length)} kiadás`}
            rows={recentReceipts.map((row) => ({
              id: row.id,
              primary: row.receiptNumber,
              secondary: `${row.receiptType} ${formatInteger(row.lines?.length ?? 0)} sor`,
              status: row.status,
            }))}
          />
          <ReadOnlyQueue
            title="Készletkorrekciók"
            summary={`${formatInteger(pendingStockCorrections.length)} függő / ${formatInteger(stockCorrections.length)} összes`}
            rows={recentCorrections.map((row) => ({
              id: row.id,
              primary: `${row.entityType} ${row.entityId}`,
              secondary: `${row.currencyCode} ${formatInteger(Number(row.difference ?? 0))}`,
              status: row.status,
            }))}
          />
        </div>
      </div>

      {/* Compact data row — egyszerű számok, nincs grafikon */}
      <div className="form-panel">
        <div className="grid grid-cols-1 gap-x-6 gap-y-2 text-sm sm:grid-cols-2 xl:grid-cols-4">
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
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="form-panel">
          <h2 className="text-base font-bold text-secondary-900 mb-3 flex items-center gap-2">
            <Trophy size={18} className="text-accent-600" />
            {t('treasury.topIrodakKeszletErtek')}
          </h2>
          {topBranches.length === 0 ? (
            <p className="text-sm text-secondary-400">{t('common.noData')}</p>
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
            {t('treasury.zarasiAllapotMa')}
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
              <p className="text-sm text-secondary-400">{t('treasury.nincsIrodaAdat')}</p>
            )}
          </div>
          {closingStatuses.length > 0 && (
            <div className="text-xs text-secondary-600">
              <strong>{closedCount}/{closingStatuses.length}</strong>{t('treasury.zarva')}
              {inProgressCount > 0 && <>, <strong>{inProgressCount}</strong> {t('treasury.folyamatban')}</>}
              {notClosedCount > 0 && <>, <strong>{notClosedCount}</strong> {t('treasury.hianyzik')}</>}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

interface StatusQueueRow {
  id: number
  status: string
  primary: string
  secondary: string
}

function StatusQueue({
  title,
  rows,
  kind,
  busyKey,
  onUpdate,
}: {
  title: string
  rows: StatusQueueRow[]
  kind: 'collection' | 'distribution' | 'bankTransaction'
  busyKey: string | null
  onUpdate: (kind: 'collection' | 'distribution' | 'bankTransaction', id: number, status: VaultOperationStatus) => void
}) {
  const targetStatuses: VaultOperationStatus[] = ['IN_PROGRESS', 'COMPLETED', 'REJECTED']

  return (
    <section className="rounded-lg border border-secondary-100 bg-white p-3">
      <div className="mb-2 flex items-center justify-between gap-2">
        <h3 className="text-sm font-bold text-secondary-900">{title}</h3>
        <span className="text-xs text-secondary-500">{rows.length} nyitott</span>
      </div>
      {rows.length === 0 ? (
        <p className="rounded border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
          Nincs nyitott tétel.
        </p>
      ) : (
        <div className="space-y-2">
          {rows.map((row) => (
            <div key={row.id} className="rounded border border-secondary-100 bg-secondary-50 p-2">
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <div className="break-words text-sm font-semibold text-secondary-900">{row.primary}</div>
                  <div className="text-xs text-secondary-500">{row.secondary}</div>
                </div>
                <span className="shrink-0 rounded bg-white px-2 py-1 text-[11px] font-semibold text-secondary-700">
                  {row.status}
                </span>
              </div>
              <div className="mt-2 grid grid-cols-3 gap-1.5">
                {targetStatuses.map((status) => {
                  const actionKey = `${kind}:${row.id}:${status}`
                  return (
                    <button
                      key={status}
                      type="button"
                      className="min-h-9 rounded border border-secondary-200 bg-white px-2 text-[11px] font-semibold text-secondary-800 disabled:opacity-50"
                      disabled={row.status === status || busyKey === actionKey}
                      onClick={() => onUpdate(kind, row.id, status)}
                      aria-label={`${title} #${row.id} státusz ${status}`}
                    >
                      {busyKey === actionKey ? '...' : status}
                    </button>
                  )
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  )
}

interface ReadOnlyQueueRow {
  id: number
  primary: string
  secondary: string
  status: string
}

function ReadOnlyQueue({
  title,
  summary,
  rows,
}: {
  title: string
  summary: string
  rows: ReadOnlyQueueRow[]
}) {
  return (
    <section className="rounded-lg border border-secondary-100 bg-white p-3">
      <div className="mb-2 flex items-center justify-between gap-2">
        <h3 className="text-sm font-bold text-secondary-900">{title}</h3>
        <span className="text-xs text-secondary-500">{summary}</span>
      </div>
      {rows.length === 0 ? (
        <p className="rounded border border-secondary-200 bg-secondary-50 px-3 py-2 text-sm text-secondary-600">
          Nincs listázható tétel.
        </p>
      ) : (
        <div className="space-y-2">
          {rows.map((row) => (
            <div key={row.id} className="rounded border border-secondary-100 bg-secondary-50 p-2">
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <div className="break-words text-sm font-semibold text-secondary-900">{row.primary}</div>
                  <div className="text-xs text-secondary-500">{row.secondary}</div>
                </div>
                <span className="shrink-0 rounded bg-white px-2 py-1 text-[11px] font-semibold text-secondary-700">
                  {row.status}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
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

function SummaryCard({ label, value, detail }: { label: string; value: string; detail: string }) {
  return (
    <div className="rounded-lg border border-secondary-100 bg-white p-3">
      <div className="text-xs font-semibold uppercase text-secondary-500">{label}</div>
      <div className="mt-1 text-xl font-bold text-secondary-900">{value}</div>
      <div className="mt-1 text-xs text-secondary-500">{detail}</div>
    </div>
  )
}
