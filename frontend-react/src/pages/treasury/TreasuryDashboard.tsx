import { useState, useEffect, useCallback, useMemo, type FormEvent, type ReactNode } from 'react'
import { Trophy, CheckCircle, Clock, XCircle, RefreshCw, Lock } from 'lucide-react'
import { useHotkeys } from 'react-hotkeys-hook'
import { AxiosError } from 'axios'
import {
  transactionApi,
  cashBalanceApi,
  dailySessionApi,
  treasuryApi,
  ertektarApi,
  getPublicWebUrl,
} from '../../services/api/index'
import PwaInstallHelp from '../competitors/PwaInstallHelp'
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
import { useAppMode } from '../../hooks/useAppMode'
import { useAuthStore } from '../../stores/authStore'
import { CENTRAL_VAULT_ROLES } from './TreasuryLayout'
import i18n from '../../i18n'

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
  closingStatus: ClosingStatus
}

interface StockCorrectionDraftForm {
  entityType: 'VAULT' | 'CASHIER'
  entityId: string
  currencyCode: string
  newQuantity: string
  reason: string
}

const EMPTY_CORRECTION_FORM: StockCorrectionDraftForm = {
  entityType: 'VAULT',
  entityId: '',
  currencyCode: '',
  newQuantity: '',
  reason: '',
}

interface SingleLineVaultRequestForm {
  branchCode: string
  currencyCode: string
  amount: string
  note: string
}

const EMPTY_VAULT_REQUEST_FORM: SingleLineVaultRequestForm = {
  branchCode: '',
  currencyCode: '',
  amount: '',
  note: '',
}

interface VaultTransferDraftForm {
  sourceBranchCode: string
  targetBranchCode: string
  currencyCode: string
  amount: string
  note: string
}

const EMPTY_TRANSFER_FORM: VaultTransferDraftForm = {
  sourceBranchCode: '',
  targetBranchCode: '',
  currencyCode: '',
  amount: '',
  note: '',
}

interface MaterialReceiptDraftForm {
  receiptType: 'B' | 'K'
  branchCode: string
  counterpartName: string
  currencyCode: string
  amount: string
  note: string
}

const EMPTY_RECEIPT_FORM: MaterialReceiptDraftForm = {
  receiptType: 'B',
  branchCode: '',
  counterpartName: '',
  currencyCode: '',
  amount: '',
  note: '',
}

export default function TreasuryDashboard() {
  const { t } = useTranslation()
  // FK-037 (2026-06-20): a cegszintu/vezetoi treasury-widgetek (treasury/** osszesitok,
  // ertektar/** operativ sorok, cash-balances company-totals/position) csak a backend-jogosult
  // szerepkoroknek (MANAGER/ADMIN/FOERTEKTAR/UGYVEZETO) jelennek meg, ES SOHA a lokalis 'ertektar'
  // Electron modban — ott a helyi ertektaros csak a sajat operativ feluleteit hasznalja
  // (TreasuryLayout konvencio, appMode==='ertektar' -> CENTRAL_VAULT_ROLES rejtve). Ezeket a
  // vegpontokat ilyenkor NEM is kerjuk le -> nincs 403, nincs toast-ozon, nincs ures widget.
  const { mode: appMode } = useAppMode()
  const roles = useAuthStore((state) => state.roles)
  const activeRole = useAuthStore((state) => state.activeRole)
  const workerRole = useAuthStore((state) => state.worker?.role)
  const isManagerOrAbove = useAuthStore((state) => state.isManagerOrAbove)
  const hasCanonicalRole = useAuthStore((state) => state.hasCanonicalRole)
  const canViewCentralTreasury = useMemo(
    () =>
      appMode !== 'ertektar' && (isManagerOrAbove() || hasCanonicalRole([...CENTRAL_VAULT_ROLES])),
    // eslint-disable-next-line react-hooks/exhaustive-deps -- roles/activeRole/workerRole szandekos extra trigger (login/role-change)
    [appMode, isManagerOrAbove, hasCanonicalRole, roles, activeRole, workerRole],
  )
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
  const [ertektarConsolidatedReport, setErtektarConsolidatedReport] =
    useState<ErtektarConsolidatedReport | null>(null)
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
  const [transferAction, setTransferAction] = useState<string | null>(null)
  const [receiptAction, setReceiptAction] = useState<string | null>(null)
  const [correctionAction, setCorrectionAction] = useState<string | null>(null)
  const [createCorrectionSubmitting, setCreateCorrectionSubmitting] = useState(false)
  const [newCorrection, setNewCorrection] =
    useState<StockCorrectionDraftForm>(EMPTY_CORRECTION_FORM)
  const [createCollectionSubmitting, setCreateCollectionSubmitting] = useState(false)
  const [newCollection, setNewCollection] =
    useState<SingleLineVaultRequestForm>(EMPTY_VAULT_REQUEST_FORM)
  const [createDistributionSubmitting, setCreateDistributionSubmitting] = useState(false)
  const [newDistribution, setNewDistribution] =
    useState<SingleLineVaultRequestForm>(EMPTY_VAULT_REQUEST_FORM)
  const [createTransferSubmitting, setCreateTransferSubmitting] = useState(false)
  const [newTransfer, setNewTransfer] = useState<VaultTransferDraftForm>(EMPTY_TRANSFER_FORM)
  const [createReceiptSubmitting, setCreateReceiptSubmitting] = useState(false)
  const [newReceipt, setNewReceipt] = useState<MaterialReceiptDraftForm>(EMPTY_RECEIPT_FORM)
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

      // FK-037: vezetoi treasury-vegpont — csak jogosult szerepkorrel hivjuk; egyebkent a default
      // ertekkel terunk vissza (a lokalis ertektaros nezetben nincs lekeres, igy nincs 403/toast/banner).
      const treasuryGet = <T,>(run: () => Promise<T>, fallback: T): Promise<T> => {
        if (!canViewCentralTreasury) return Promise.resolve(fallback)
        return run().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setTreasuryApiRestricted(true)
          }
          return fallback
        })
      }
      // Ugyanaz, de a cegszintu cash-balance 403-at a "Korlatozott jogosultsag" panelhez koti.
      const companyGet = <T,>(run: () => Promise<T>, fallback: T): Promise<T> => {
        if (!canViewCentralTreasury) return Promise.resolve(fallback)
        return run().catch((err: unknown) => {
          if (err instanceof AxiosError && err.response?.status === 403) {
            setCompanyBalanceRestricted(true)
          }
          return fallback
        })
      }

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
        companyGet<CompanyCashPosition | null>(() => cashBalanceApi.getCompanyPosition(), null),
        companyGet<CurrencyTotalBalance[]>(() => cashBalanceApi.getCompanyTotals(), []),
        cashBalanceApi.getLowAlerts().catch(() => []),
        cashBalanceApi.getHighAlerts().catch(() => []),
        treasuryGet<TreasuryDashboardSummary | null>(() => treasuryApi.dashboard(), null),
        treasuryGet<TreasuryBranchComparison[]>(() => treasuryApi.branchComparison(), []),
        treasuryGet<TreasurySubmissionStatus[]>(() => treasuryApi.submissionStatus(), []),
        treasuryGet<TreasuryBankFlow[]>(() => treasuryApi.bankFlow(), []),
        treasuryGet<TreasuryAggregate[]>(() => treasuryApi.branchGroupSummary(), []),
        treasuryGet<TreasuryAggregate[]>(() => treasuryApi.companySummary(), []),
        canViewCentralTreasury
          ? treasuryApi.ertektarBranches().catch((err: unknown) => {
              if (err instanceof AxiosError && err.response?.status === 403) {
                setTreasuryApiRestricted(true)
              }
              return {}
            })
          : Promise.resolve({}),
        treasuryGet<ErtektarConsolidatedReport | null>(
          () => treasuryApi.ertektarConsolidatedReport(),
          null,
        ),
        treasuryGet<ErtektarCollection[]>(() => ertektarApi.getCollections(), []),
        treasuryGet<ErtektarDistribution[]>(() => ertektarApi.getDistributions(), []),
        treasuryGet<BankTransaction[]>(() => ertektarApi.getBankTransactions(), []),
        treasuryGet<VaultTransferItem[]>(() => ertektarApi.getTransfers(), []),
        treasuryGet<VaultTransferItem[]>(() => ertektarApi.getPendingTransfers(), []),
        treasuryGet<MaterialReceiptItem[]>(() => ertektarApi.getReceipts(), []),
        treasuryGet<MaterialReceiptItem[]>(() => ertektarApi.getReceiptsByType('B'), []),
        treasuryGet<MaterialReceiptItem[]>(() => ertektarApi.getReceiptsByType('K'), []),
        treasuryGet<StockCorrectionItem[]>(() => ertektarApi.getCorrections(), []),
        treasuryGet<StockCorrectionItem[]>(() => ertektarApi.getPendingCorrections(), []),
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
        })),
      )

      const today = localIsoDate()
      const sessionsRaw = await dailySessionApi.getHistory(today, today).catch(() => [])
      const sessions = safeArray<DailySession>(sessionsRaw)

      const closingMap = new Map<string, BranchClosing>()
      for (const s of sessions) {
        closingMap.set(s.branchId, {
          id: s.branchId,
          name: s.branchName ?? s.branchId,
          closingStatus: s.status === 'CLOSED' ? 'CLOSED' : 'IN_PROGRESS',
        })
      }
      for (const b of sorted) {
        if (!closingMap.has(b.id)) {
          closingMap.set(b.id, {
            id: b.id,
            name: b.name,
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
  }, [canViewCentralTreasury])

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

  const createVaultCollection = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const sourceBranchCode = newCollection.branchCode.trim()
    const currencyCode = newCollection.currencyCode.trim().toUpperCase()
    const amount = Number(newCollection.amount)
    const note = newCollection.note.trim()

    if (!sourceBranchCode || !currencyCode || !Number.isFinite(amount) || amount <= 0) {
      setStatusActionError('Begyűjtéshez iroda, valuta és pozitív összeg szükséges.')
      return
    }
    if (!window.confirm(`Biztosan létrehozza a ${currencyCode} begyűjtési kérelmet?`)) return

    try {
      setCreateCollectionSubmitting(true)
      setStatusActionError(null)
      await ertektarApi.createCollection({
        sourceBranchCode,
        currencyCode,
        amount,
        ...(note ? { note } : {}),
      })
      setNewCollection(EMPTY_VAULT_REQUEST_FORM)
      await fetchData()
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Begyűjtési kérelem létrehozás sikertelen.'
      setStatusActionError(message)
      logger.error('TreasuryDashboard', 'Vault collection create error:', err)
    } finally {
      setCreateCollectionSubmitting(false)
    }
  }

  const createVaultDistribution = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const targetBranchCode = newDistribution.branchCode.trim()
    const currencyCode = newDistribution.currencyCode.trim().toUpperCase()
    const amount = Number(newDistribution.amount)
    const note = newDistribution.note.trim()

    if (!targetBranchCode || !currencyCode || !Number.isFinite(amount) || amount <= 0) {
      setStatusActionError('Szétosztáshoz cél iroda, valuta és pozitív összeg szükséges.')
      return
    }
    if (!window.confirm(`Biztosan létrehozza a ${currencyCode} szétosztási kérelmet?`)) return

    try {
      setCreateDistributionSubmitting(true)
      setStatusActionError(null)
      await ertektarApi.createDistribution({
        items: [{ targetBranchCode, currencyCode, amount }],
        ...(note ? { note } : {}),
      })
      setNewDistribution(EMPTY_VAULT_REQUEST_FORM)
      await fetchData()
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Szétosztási kérelem létrehozás sikertelen.'
      setStatusActionError(message)
      logger.error('TreasuryDashboard', 'Vault distribution create error:', err)
    } finally {
      setCreateDistributionSubmitting(false)
    }
  }

  const createVaultTransfer = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const sourceBranchCode = newTransfer.sourceBranchCode.trim()
    const targetBranchCode = newTransfer.targetBranchCode.trim()
    const currencyCode = newTransfer.currencyCode.trim().toUpperCase()
    const amount = Number(newTransfer.amount)
    const note = newTransfer.note.trim()

    if (
      !sourceBranchCode ||
      !targetBranchCode ||
      !currencyCode ||
      !Number.isFinite(amount) ||
      amount <= 0
    ) {
      setStatusActionError(
        'Áttételhez forrás iroda, cél iroda, valuta és pozitív összeg szükséges.',
      )
      return
    }
    if (!window.confirm(`Biztosan létrehozza a ${currencyCode} áttételi kérelmet?`)) return

    try {
      setCreateTransferSubmitting(true)
      setStatusActionError(null)
      await ertektarApi.createTransfer({
        sourceBranchCode,
        targetBranchCode,
        currencyCode,
        amount,
        ...(note ? { note } : {}),
      })
      setNewTransfer(EMPTY_TRANSFER_FORM)
      await fetchData()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Áttételi kérelem létrehozás sikertelen.'
      setStatusActionError(message)
      logger.error('TreasuryDashboard', 'Vault transfer create error:', err)
    } finally {
      setCreateTransferSubmitting(false)
    }
  }

  const createMaterialReceipt = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const receiptType = newReceipt.receiptType
    const branchCode = newReceipt.branchCode.trim()
    const counterpartName = newReceipt.counterpartName.trim()
    const currencyCode = newReceipt.currencyCode.trim().toUpperCase()
    const amount = Number(newReceipt.amount)
    const note = newReceipt.note.trim()

    if (!branchCode || !currencyCode || !Number.isFinite(amount) || amount <= 0) {
      setStatusActionError('Anyagbizonylathoz iroda, valuta és pozitív összeg szükséges.')
      return
    }
    if (!window.confirm(`Biztosan létrehozza a ${receiptType} típusú anyagbizonylatot?`)) return

    try {
      setCreateReceiptSubmitting(true)
      setStatusActionError(null)
      await ertektarApi.createReceipt({
        receiptType,
        branchCode,
        ...(counterpartName ? { counterpartName } : {}),
        ...(note ? { note } : {}),
        lines: [{ currencyCode, amount }],
      })
      setNewReceipt(EMPTY_RECEIPT_FORM)
      await fetchData()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Anyagbizonylat létrehozás sikertelen.'
      setStatusActionError(message)
      logger.error('TreasuryDashboard', 'Material receipt create error:', err)
    } finally {
      setCreateReceiptSubmitting(false)
    }
  }

  const decideStockCorrection = async (id: number, decision: 'approve' | 'reject') => {
    const label = decision === 'approve' ? 'jóváhagyja' : 'elutasítja'
    if (!window.confirm(`Biztosan ${label} a #${id} készletkorrekciót?`)) return

    const actionKey = `correction:${id}:${decision}`
    try {
      setCorrectionAction(actionKey)
      setStatusActionError(null)
      if (decision === 'approve') {
        await ertektarApi.approveCorrection(id)
      } else {
        await ertektarApi.rejectCorrection(id)
      }
      await fetchData()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Készletkorrekció döntés sikertelen.'
      setStatusActionError(message)
      logger.error('TreasuryDashboard', 'Stock correction decision error:', err)
    } finally {
      setCorrectionAction(null)
    }
  }

  const createStockCorrection = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const entityId = newCorrection.entityId.trim()
    const currencyCode = newCorrection.currencyCode.trim().toUpperCase()
    const reason = newCorrection.reason.trim()
    const newQuantity = Number(newCorrection.newQuantity)

    if (!entityId || !currencyCode || !reason || !Number.isFinite(newQuantity) || newQuantity < 0) {
      setStatusActionError(
        'Készletkorrekcióhoz típus, azonosító, valuta, nem negatív mennyiség és indok szükséges.',
      )
      return
    }
    if (!window.confirm(`Biztosan létrehozza a ${currencyCode} készletkorrekciós kérelmet?`)) return

    try {
      setCreateCorrectionSubmitting(true)
      setStatusActionError(null)
      await ertektarApi.createCorrection({
        entityType: newCorrection.entityType,
        entityId,
        currencyCode,
        newQuantity,
        reason,
      })
      setNewCorrection(EMPTY_CORRECTION_FORM)
      await fetchData()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Készletkorrekció létrehozás sikertelen.'
      setStatusActionError(message)
      logger.error('TreasuryDashboard', 'Stock correction create error:', err)
    } finally {
      setCreateCorrectionSubmitting(false)
    }
  }

  const decideVaultTransfer = async (
    id: number,
    decision: 'supervisorApprove' | 'complete' | 'reject',
  ) => {
    const label =
      decision === 'supervisorApprove'
        ? 'supervisori jóváhagyja'
        : decision === 'complete'
          ? 'végrehajtja'
          : 'elutasítja'
    if (!window.confirm(`Biztosan ${label} a #${id} áttételt?`)) return

    const actionKey = `transfer:${id}:${decision}`
    try {
      setTransferAction(actionKey)
      setStatusActionError(null)
      if (decision === 'supervisorApprove') {
        await ertektarApi.supervisorApproveTransfer(id)
      } else if (decision === 'complete') {
        await ertektarApi.completeTransfer(id)
      } else {
        await ertektarApi.rejectTransfer(id)
      }
      await fetchData()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Áttétel művelet sikertelen.'
      setStatusActionError(message)
      logger.error('TreasuryDashboard', 'Vault transfer decision error:', err)
    } finally {
      setTransferAction(null)
    }
  }

  const finalizeMaterialReceipt = async (id: number) => {
    if (!window.confirm(`Biztosan véglegesíti a #${id} anyagbizonylatot?`)) return

    const actionKey = `receipt:${id}:finalize`
    try {
      setReceiptAction(actionKey)
      setStatusActionError(null)
      await ertektarApi.finalizeReceipt(id)
      await fetchData()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Anyagbizonylat véglegesítés sikertelen.'
      setStatusActionError(message)
      logger.error('TreasuryDashboard', 'Material receipt finalize error:', err)
    } finally {
      setReceiptAction(null)
    }
  }

  if (loading) return <DashboardSkeleton />

  const totalTx = (turnover?.totalBuyCount ?? 0) + (turnover?.totalSellCount ?? 0)
  const totalVolume = (turnover?.totalBuyHuf ?? 0) + (turnover?.totalSellHuf ?? 0)
  const totalCustomers = turnover?.totalBuyCount ?? 0
  const totalStockValue = companyPosition?.grandTotalHuf ?? 0
  // FK-037: a cegszintu keszlet-ertek a getCompanyPosition-bol jon (vezetoi vegpont). A lokalis
  // ertektar nezetben NEM kerjuk le, ezert semleges "—"-t mutatunk (nem 0-t, ami felrevezeto lenne);
  // jogosult, de 403-as esetben a meglevo "— (jogosultsag)" jelzes marad.
  let stockValueDisplay = formatMillions(totalStockValue)
  if (!canViewCentralTreasury) {
    stockValueDisplay = '—'
  } else if (companyBalanceRestricted) {
    stockValueDisplay = '— (jogosultság)'
  }
  const stockValueAccent = canViewCentralTreasury && !companyBalanceRestricted

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
  const topCompanyTotal = [...companyTotals].sort(
    (a, b) => Number(b.totalBalance ?? 0) - Number(a.totalBalance ?? 0),
  )[0]
  const stockAlertCount = lowBalanceAlerts.length + highBalanceAlerts.length
  const ertektarOnlineCount = ertektarBranches.filter((b) => b.isOnline ?? b.online).length
  const ertektarOfflineCount = ertektarBranches.filter((b) => !(b.isOnline ?? b.online)).length
  const ertektarOpenAlerts = ertektarBranches.reduce((sum, b) => sum + (b.openAlerts ?? 0), 0)
  const consolidatedTotals = ertektarConsolidatedReport?.totals
  const consolidatedBranchCount = ertektarConsolidatedReport?.branches?.length ?? 0
  const openCollections = ertektarCollections
    .filter((row) => row.status !== 'COMPLETED' && row.status !== 'REJECTED')
    .slice(0, 3)
  const openDistributions = ertektarDistributions
    .filter((row) => row.status !== 'COMPLETED' && row.status !== 'REJECTED')
    .slice(0, 3)
  const openBankTransactions = ertektarBankTransactions
    .filter((row) => row.status !== 'COMPLETED' && row.status !== 'REJECTED')
    .slice(0, 3)
  const recentTransfers = ertektarTransfers.slice(0, 3)
  const recentReceipts = materialReceipts.slice(0, 3)
  const recentCorrections = stockCorrections.slice(0, 3)

  return (
    <div className="space-y-3">
      {/* Page header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-lg font-bold text-secondary-900">
            {t('treasury.ertektariDashboard')}
          </h1>
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
            <p className="font-semibold text-amber-900">
              {t('treasury.dedikaltTreasuryApiKorlatozott')}
            </p>
            <p className="text-xs text-amber-800">
              {t('treasury.treasuryOsszesitokManagerVagyAdmin')}
            </p>
          </div>
        </div>
      )}

      {/* FK-037: cegszintu/vezetoi treasury-szekciok — csak a backend-jogosult szerepkoroknek
          (MANAGER/ADMIN/FOERTEKTAR/UGYVEZETO); a lokalis 'ertektar' modban teljesen rejtve, es a
          mogottes vegpontokat sem hivjuk (lasd canViewCentralTreasury + treasuryGet/companyGet). */}
      {canViewCentralTreasury && (
        <>
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
                detail={
                  topBackendBranches[0]?.branchName ??
                  topBackendBranches[0]?.branchCode ??
                  'Nincs adat'
                }
              />
              <SummaryCard
                label="Beküldési státusz"
                value={`${submittedCount}/${submissionStatus.length}`}
                detail={
                  missingSubmissionCount > 0
                    ? `${missingSubmissionCount} hiányzó jelentés`
                    : 'Minden jelentés beérkezett'
                }
              />
              <SummaryCard
                label="Értéktári pénztár monitoring"
                value={`${ertektarOnlineCount}/${ertektarBranches.length} online`}
                detail={
                  ertektarOfflineCount > 0
                    ? `${ertektarOfflineCount} offline, ${ertektarOpenAlerts} riasztás`
                    : `${ertektarOpenAlerts} nyitott riasztás`
                }
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
                detail={
                  topBankFlow
                    ? `${formatMillions(Number(topBankFlow.netFlow ?? 0))} nettó`
                    : 'Nincs bankflow adat'
                }
              />
              <SummaryCard
                label="Fiókcsoport összesítő"
                value={`${formatInteger(branchGroupSummary.length)} csoport`}
                detail={topBranchGroup?.name ?? topBranchGroup?.code ?? 'Nincs adat'}
              />
              <SummaryCard
                label="Cégösszesítő"
                value={`${formatInteger(companySummary.length)} egység`}
                detail={
                  topCompanySummary
                    ? `${formatMillions(Number(topCompanySummary.totalProfit ?? 0))} profit`
                    : 'Nincs adat'
                }
              />
              <SummaryCard
                label="Valutánkénti készlet"
                value={`${formatInteger(companyTotals.length)} valuta`}
                detail={
                  topCompanyTotal
                    ? `${topCompanyTotal.currencyCode} ${formatInteger(Number(topCompanyTotal.totalBalance ?? 0))}`
                    : 'Nincs adat'
                }
              />
            </div>
          </div>

          <div className="form-panel" data-testid="ertektar-status-control">
            <div className="mb-3 flex items-center justify-between gap-2">
              <h2 className="text-base font-bold text-secondary-900">
                {i18n.t('literals.ertektari-statusz-kontroll')}
              </h2>
              <span className="text-xs text-secondary-500">
                {openCollections.length + openDistributions.length + openBankTransactions.length}{' '}
                {i18n.t('literals.nyitott-tetel')}
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
              >
                <form
                  onSubmit={(event) => void createVaultCollection(event)}
                  className="grid grid-cols-1 gap-2 sm:grid-cols-2"
                >
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.forras-iroda')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newCollection.branchCode}
                      onChange={(event) =>
                        setNewCollection((value) => ({ ...value, branchCode: event.target.value }))
                      }
                      disabled={createCollectionSubmitting}
                      placeholder="BUD01"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.begyujtes-valuta')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm uppercase"
                      value={newCollection.currencyCode}
                      onChange={(event) =>
                        setNewCollection((value) => ({
                          ...value,
                          currencyCode: event.target.value,
                        }))
                      }
                      disabled={createCollectionSubmitting}
                      placeholder="EUR"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.begyujtes-osszeg')}
                    <input
                      type="number"
                      min="0.01"
                      step="0.01"
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newCollection.amount}
                      onChange={(event) =>
                        setNewCollection((value) => ({ ...value, amount: event.target.value }))
                      }
                      disabled={createCollectionSubmitting}
                      placeholder="0"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.begyujtes-megjegyzes')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newCollection.note}
                      onChange={(event) =>
                        setNewCollection((value) => ({ ...value, note: event.target.value }))
                      }
                      disabled={createCollectionSubmitting}
                      placeholder="Megjegyzés"
                    />
                  </label>
                  <button
                    type="submit"
                    aria-label="Begyűjtés kérése"
                    className="rounded bg-primary-600 px-3 py-2 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-60 sm:col-span-2"
                    disabled={createCollectionSubmitting}
                  >
                    {createCollectionSubmitting ? '...' : 'Begyűjtés kérése'}
                  </button>
                </form>
              </StatusQueue>
              <StatusQueue
                title="Szétosztás"
                rows={openDistributions.map((row) => ({
                  id: row.id,
                  status: row.status,
                  primary:
                    row.lines?.[0]?.targetBranchName ??
                    row.lines?.[0]?.targetBranchCode ??
                    `#${row.id}`,
                  secondary: `${row.lines?.length ?? 0} sor`,
                }))}
                kind="distribution"
                busyKey={statusAction}
                onUpdate={updateErtektarStatus}
              >
                <form
                  onSubmit={(event) => void createVaultDistribution(event)}
                  className="grid grid-cols-1 gap-2 sm:grid-cols-2"
                >
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.cel-iroda')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newDistribution.branchCode}
                      onChange={(event) =>
                        setNewDistribution((value) => ({
                          ...value,
                          branchCode: event.target.value,
                        }))
                      }
                      disabled={createDistributionSubmitting}
                      placeholder="PECS"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.szetosztas-valuta')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm uppercase"
                      value={newDistribution.currencyCode}
                      onChange={(event) =>
                        setNewDistribution((value) => ({
                          ...value,
                          currencyCode: event.target.value,
                        }))
                      }
                      disabled={createDistributionSubmitting}
                      placeholder="USD"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.szetosztas-osszeg')}
                    <input
                      type="number"
                      min="0.01"
                      step="0.01"
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newDistribution.amount}
                      onChange={(event) =>
                        setNewDistribution((value) => ({ ...value, amount: event.target.value }))
                      }
                      disabled={createDistributionSubmitting}
                      placeholder="0"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.szetosztas-megjegyzes')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newDistribution.note}
                      onChange={(event) =>
                        setNewDistribution((value) => ({ ...value, note: event.target.value }))
                      }
                      disabled={createDistributionSubmitting}
                      placeholder="Megjegyzés"
                    />
                  </label>
                  <button
                    type="submit"
                    aria-label="Szétosztás kérése"
                    className="rounded bg-primary-600 px-3 py-2 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-60 sm:col-span-2"
                    disabled={createDistributionSubmitting}
                  >
                    {createDistributionSubmitting ? '...' : 'Szétosztás kérése'}
                  </button>
                </form>
              </StatusQueue>
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
              <h2 className="text-base font-bold text-secondary-900">
                {i18n.t('literals.ertektari-bizonylat-es-korrekcio-attekin')}
              </h2>
              <span className="text-xs text-secondary-500">
                {formatInteger(
                  ertektarTransfers.length + materialReceipts.length + stockCorrections.length,
                )}{' '}
                {i18n.t('literals.listazott-tetel')}
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
                  requiresSupervisor: row.requiresSupervisor,
                }))}
                busyKey={transferAction}
                actions={(row) => {
                  if (row.status === 'REQUESTED' && row.requiresSupervisor) {
                    return [
                      {
                        key: `transfer:${row.id}:supervisorApprove`,
                        label: 'Supervisor',
                        ariaLabel: `Áttétel #${row.id} supervisor jóváhagyás`,
                        onClick: () => void decideVaultTransfer(row.id, 'supervisorApprove'),
                      },
                      {
                        key: `transfer:${row.id}:reject`,
                        label: 'Elutasítás',
                        ariaLabel: `Áttétel #${row.id} elutasítás`,
                        onClick: () => void decideVaultTransfer(row.id, 'reject'),
                      },
                    ]
                  }
                  if (row.status === 'REQUESTED' || row.status === 'IN_PROGRESS') {
                    return [
                      {
                        key: `transfer:${row.id}:complete`,
                        label: 'Átvétel',
                        ariaLabel: `Áttétel #${row.id} végrehajtás`,
                        onClick: () => void decideVaultTransfer(row.id, 'complete'),
                      },
                      {
                        key: `transfer:${row.id}:reject`,
                        label: 'Elutasítás',
                        ariaLabel: `Áttétel #${row.id} elutasítás`,
                        onClick: () => void decideVaultTransfer(row.id, 'reject'),
                      },
                    ]
                  }
                  return []
                }}
              >
                <form
                  onSubmit={(event) => void createVaultTransfer(event)}
                  className="grid grid-cols-1 gap-2 sm:grid-cols-2"
                >
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.attetel-forras-iroda')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newTransfer.sourceBranchCode}
                      onChange={(event) =>
                        setNewTransfer((value) => ({
                          ...value,
                          sourceBranchCode: event.target.value,
                        }))
                      }
                      disabled={createTransferSubmitting}
                      placeholder="BUD01"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.attetel-cel-iroda')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newTransfer.targetBranchCode}
                      onChange={(event) =>
                        setNewTransfer((value) => ({
                          ...value,
                          targetBranchCode: event.target.value,
                        }))
                      }
                      disabled={createTransferSubmitting}
                      placeholder="PECS"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.attetel-valuta')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm uppercase"
                      value={newTransfer.currencyCode}
                      onChange={(event) =>
                        setNewTransfer((value) => ({ ...value, currencyCode: event.target.value }))
                      }
                      disabled={createTransferSubmitting}
                      placeholder="EUR"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.attetel-osszeg')}
                    <input
                      type="number"
                      min="0.01"
                      step="0.01"
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newTransfer.amount}
                      onChange={(event) =>
                        setNewTransfer((value) => ({ ...value, amount: event.target.value }))
                      }
                      disabled={createTransferSubmitting}
                      placeholder="0"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700 sm:col-span-2">
                    {i18n.t('literals.attetel-megjegyzes')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newTransfer.note}
                      onChange={(event) =>
                        setNewTransfer((value) => ({ ...value, note: event.target.value }))
                      }
                      disabled={createTransferSubmitting}
                      placeholder="Megjegyzés"
                    />
                  </label>
                  <button
                    type="submit"
                    aria-label="Áttétel kérése"
                    className="rounded bg-primary-600 px-3 py-2 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-60 sm:col-span-2"
                    disabled={createTransferSubmitting}
                  >
                    {createTransferSubmitting ? '...' : 'Áttétel kérése'}
                  </button>
                </form>
              </ReadOnlyQueue>
              <ReadOnlyQueue
                title="Anyagbizonylatok"
                summary={`${formatInteger(materialReceiptsIn.length)} bevét / ${formatInteger(materialReceiptsOut.length)} kiadás`}
                rows={recentReceipts.map((row) => ({
                  id: row.id,
                  primary: row.receiptNumber,
                  secondary: `${row.receiptType} ${formatInteger(row.lines?.length ?? 0)} sor`,
                  status: row.status,
                }))}
                busyKey={receiptAction}
                actions={(row) =>
                  row.status === 'DRAFT'
                    ? [
                        {
                          key: `receipt:${row.id}:finalize`,
                          label: 'Véglegesítés',
                          ariaLabel: `Anyagbizonylat #${row.id} véglegesítés`,
                          onClick: () => void finalizeMaterialReceipt(row.id),
                        },
                      ]
                    : []
                }
              >
                <form
                  onSubmit={(event) => void createMaterialReceipt(event)}
                  className="grid grid-cols-1 gap-2 sm:grid-cols-2"
                >
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.bizonylat-tipus')}
                    <select
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newReceipt.receiptType}
                      onChange={(event) =>
                        setNewReceipt((value) => ({
                          ...value,
                          receiptType: event.target.value as 'B' | 'K',
                        }))
                      }
                      disabled={createReceiptSubmitting}
                    >
                      <option value="B">{i18n.t('literals.bevet')}</option>
                      <option value="K">{i18n.t('literals.kiadas-2')}</option>
                    </select>
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.bizonylat-iroda')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newReceipt.branchCode}
                      onChange={(event) =>
                        setNewReceipt((value) => ({ ...value, branchCode: event.target.value }))
                      }
                      disabled={createReceiptSubmitting}
                      placeholder="BUD01"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.bizonylat-valuta')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm uppercase"
                      value={newReceipt.currencyCode}
                      onChange={(event) =>
                        setNewReceipt((value) => ({ ...value, currencyCode: event.target.value }))
                      }
                      disabled={createReceiptSubmitting}
                      placeholder="EUR"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.bizonylat-osszeg')}
                    <input
                      type="number"
                      min="0.01"
                      step="0.01"
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newReceipt.amount}
                      onChange={(event) =>
                        setNewReceipt((value) => ({ ...value, amount: event.target.value }))
                      }
                      disabled={createReceiptSubmitting}
                      placeholder="0"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.partner')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newReceipt.counterpartName}
                      onChange={(event) =>
                        setNewReceipt((value) => ({
                          ...value,
                          counterpartName: event.target.value,
                        }))
                      }
                      disabled={createReceiptSubmitting}
                      placeholder="Partner"
                    />
                  </label>
                  <label className="text-xs font-medium text-secondary-700">
                    {i18n.t('literals.bizonylat-megjegyzes')}
                    <input
                      className="mt-1 w-full rounded border border-secondary-200 px-2 py-1 text-sm"
                      value={newReceipt.note}
                      onChange={(event) =>
                        setNewReceipt((value) => ({ ...value, note: event.target.value }))
                      }
                      disabled={createReceiptSubmitting}
                      placeholder="Megjegyzés"
                    />
                  </label>
                  <button
                    type="submit"
                    aria-label="Anyagbizonylat kérése"
                    className="rounded bg-primary-600 px-3 py-2 text-xs font-semibold text-white hover:bg-primary-700 disabled:opacity-60 sm:col-span-2"
                    disabled={createReceiptSubmitting}
                  >
                    {createReceiptSubmitting ? '...' : 'Anyagbizonylat kérése'}
                  </button>
                </form>
              </ReadOnlyQueue>
              <ReadOnlyQueue
                title="Készletkorrekciók"
                summary={`${formatInteger(pendingStockCorrections.length)} függő / ${formatInteger(stockCorrections.length)} összes`}
                rows={recentCorrections.map((row) => ({
                  id: row.id,
                  primary: `${row.entityType} ${row.entityId}`,
                  secondary: `${row.currencyCode} ${formatInteger(Number(row.difference ?? 0))}`,
                  status: row.status,
                }))}
                busyKey={correctionAction}
                actions={(row) =>
                  row.status === 'PENDING'
                    ? [
                        {
                          key: `correction:${row.id}:approve`,
                          label: 'Jóváhagyás',
                          ariaLabel: `Készletkorrekció #${row.id} jóváhagyás`,
                          onClick: () => void decideStockCorrection(row.id, 'approve'),
                        },
                        {
                          key: `correction:${row.id}:reject`,
                          label: 'Elutasítás',
                          ariaLabel: `Készletkorrekció #${row.id} elutasítás`,
                          onClick: () => void decideStockCorrection(row.id, 'reject'),
                        },
                      ]
                    : []
                }
              >
                <form
                  onSubmit={(event) => void createStockCorrection(event)}
                  className="grid grid-cols-1 gap-2 sm:grid-cols-2"
                >
                  <label className="text-xs font-semibold text-secondary-600">
                    {i18n.t('literals.tipus')}
                    <select
                      className="form-input mt-1 h-8 w-full text-xs"
                      value={newCorrection.entityType}
                      onChange={(event) =>
                        setNewCorrection((value) => ({
                          ...value,
                          entityType: event.target.value as StockCorrectionDraftForm['entityType'],
                        }))
                      }
                      disabled={createCorrectionSubmitting}
                    >
                      <option value="VAULT">{i18n.t('literals.vault')}</option>
                      <option value="CASHIER">{i18n.t('literals.cashier')}</option>
                    </select>
                  </label>
                  <label className="text-xs font-semibold text-secondary-600">
                    {i18n.t('literals.azonosito')}
                    <input
                      className="form-input mt-1 h-8 w-full text-xs"
                      value={newCorrection.entityId}
                      onChange={(event) =>
                        setNewCorrection((value) => ({ ...value, entityId: event.target.value }))
                      }
                      disabled={createCorrectionSubmitting}
                      placeholder="BUD01"
                    />
                  </label>
                  <label className="text-xs font-semibold text-secondary-600">
                    {i18n.t('literals.valuta')}
                    <input
                      className="form-input mt-1 h-8 w-full text-xs font-mono uppercase"
                      value={newCorrection.currencyCode}
                      onChange={(event) =>
                        setNewCorrection((value) => ({
                          ...value,
                          currencyCode: event.target.value,
                        }))
                      }
                      disabled={createCorrectionSubmitting}
                      placeholder="EUR"
                    />
                  </label>
                  <label className="text-xs font-semibold text-secondary-600">
                    {i18n.t('literals.uj-mennyiseg')}
                    <input
                      type="number"
                      min="0"
                      step="0.01"
                      className="form-input mt-1 h-8 w-full text-xs font-mono"
                      value={newCorrection.newQuantity}
                      onChange={(event) =>
                        setNewCorrection((value) => ({ ...value, newQuantity: event.target.value }))
                      }
                      disabled={createCorrectionSubmitting}
                      placeholder="0"
                    />
                  </label>
                  <label className="text-xs font-semibold text-secondary-600 sm:col-span-2">
                    {i18n.t('literals.indok')}
                    <input
                      className="form-input mt-1 h-8 w-full text-xs"
                      value={newCorrection.reason}
                      onChange={(event) =>
                        setNewCorrection((value) => ({ ...value, reason: event.target.value }))
                      }
                      disabled={createCorrectionSubmitting}
                      placeholder="Leltár eltérés"
                    />
                  </label>
                  <button
                    type="submit"
                    className="form-button-primary min-h-9 text-xs sm:col-span-2"
                    disabled={createCorrectionSubmitting}
                  >
                    {createCorrectionSubmitting ? '...' : 'Korrekció kérése'}
                  </button>
                </form>
              </ReadOnlyQueue>
            </div>
          </div>
        </>
      )}

      {/* Compact data row — egyszerű számok, nincs grafikon */}
      <div className="form-panel">
        <div className="grid grid-cols-1 gap-x-6 gap-y-2 text-sm sm:grid-cols-2 xl:grid-cols-4">
          <DataRow label="Mai tranzakciók" value={`${formatInteger(totalTx)} db`} />
          <DataRow label="Napi forgalom" value={formatMillions(totalVolume)} accent />
          <DataRow label="Kiszolgált ügyfelek" value={`${formatInteger(totalCustomers)} fő`} />
          <DataRow
            label="Készlet érték (összes)"
            value={stockValueDisplay}
            accent={stockValueAccent}
          />
          <DataRow label="Vétel (db)" value={formatInteger(turnover?.totalBuyCount ?? 0)} />
          <DataRow label="Eladás (db)" value={formatInteger(turnover?.totalSellCount ?? 0)} />
          <DataRow label="Vétel (HUF)" value={formatMillions(turnover?.totalBuyHuf ?? 0)} />
          <DataRow label="Eladás (HUF)" value={formatMillions(turnover?.totalSellHuf ?? 0)} />
          <DataRow
            label="Kezelési díjak"
            value={formatMillions(turnover?.totalHandlingFees ?? 0)}
          />
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
                    <td className="py-1.5 pr-2 w-8 text-secondary-500 font-mono">
                      {index + 1}
                      {i18n.t('literals.lit-5')}
                    </td>
                    <td className="py-1.5 pr-2 font-medium text-secondary-900">{branch.name}</td>
                    <td className="py-1.5 text-right font-mono text-secondary-700">
                      {formatMillions(branch.revenue)}
                    </td>
                    <td className="py-1.5 pl-2 text-right text-xs text-secondary-500 w-12">
                      {branch.percentage}
                      {i18n.t('literals.lit-30')}
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
                title={branch.name}
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
                {branch.name}
              </div>
            ))}
            {closingStatuses.length === 0 && (
              <p className="text-sm text-secondary-400">{t('treasury.nincsIrodaAdat')}</p>
            )}
          </div>
          {closingStatuses.length > 0 && (
            <div className="text-xs text-secondary-600">
              <strong>
                {closedCount}
                {i18n.t('literals.lit-4')}
                {closingStatuses.length}
              </strong>
              {t('treasury.zarva')}
              {inProgressCount > 0 && (
                <>
                  {i18n.t('literals.lit-13')}
                  <strong>{inProgressCount}</strong> {t('treasury.folyamatban')}
                </>
              )}
              {notClosedCount > 0 && (
                <>
                  {i18n.t('literals.lit-13')}
                  <strong>{notClosedCount}</strong> {t('treasury.hianyzik')}
                </>
              )}
            </div>
          )}
        </div>
      </div>

      {/* FK-041/II: az értéktáros innen mutathatja meg a QR-kódot, amivel az árfolyam néző telefonjára
          telepíthető a versenytárs-árfolyam beíró PWA. Electron kliensben a publikus web-URL kell (a
          window.location.origin lokális lenne), ezért getPublicWebUrl()-t adunk át. */}
      <PwaInstallHelp url={getPublicWebUrl()} title={t('pwaInstall.cimErtektar')} />
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
  children,
}: {
  title: string
  rows: StatusQueueRow[]
  kind: 'collection' | 'distribution' | 'bankTransaction'
  busyKey: string | null
  onUpdate: (
    kind: 'collection' | 'distribution' | 'bankTransaction',
    id: number,
    status: VaultOperationStatus,
  ) => void
  children?: ReactNode
}) {
  const targetStatuses: VaultOperationStatus[] = ['IN_PROGRESS', 'COMPLETED', 'REJECTED']

  return (
    <section className="rounded-lg border border-secondary-100 bg-white p-3">
      <div className="mb-2 flex items-center justify-between gap-2">
        <h3 className="text-sm font-bold text-secondary-900">{title}</h3>
        <span className="text-xs text-secondary-500">
          {rows.length}
          {i18n.t('literals.nyitott-2')}
        </span>
      </div>
      {children && (
        <div className="mb-3 rounded border border-secondary-100 bg-secondary-50 p-2">
          {children}
        </div>
      )}
      {rows.length === 0 ? (
        <p className="rounded border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
          {i18n.t('literals.nincs-nyitott-tetel')}
        </p>
      ) : (
        <div className="space-y-2">
          {rows.map((row) => (
            <div key={row.id} className="rounded border border-secondary-100 bg-secondary-50 p-2">
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <div className="break-words text-sm font-semibold text-secondary-900">
                    {row.primary}
                  </div>
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
  requiresSupervisor?: boolean
}

interface ReadOnlyQueueAction {
  key: string
  label: string
  ariaLabel: string
  onClick: () => void
}

function ReadOnlyQueue({
  title,
  summary,
  rows,
  busyKey,
  actions,
  children,
}: {
  title: string
  summary: string
  rows: ReadOnlyQueueRow[]
  busyKey?: string | null
  actions?: (row: ReadOnlyQueueRow) => ReadOnlyQueueAction[]
  children?: ReactNode
}) {
  return (
    <section className="rounded-lg border border-secondary-100 bg-white p-3">
      <div className="mb-2 flex items-center justify-between gap-2">
        <h3 className="text-sm font-bold text-secondary-900">{title}</h3>
        <span className="text-xs text-secondary-500">{summary}</span>
      </div>
      {children && (
        <div className="mb-3 rounded border border-secondary-100 bg-secondary-50 p-2">
          {children}
        </div>
      )}
      {rows.length === 0 ? (
        <p className="rounded border border-secondary-200 bg-secondary-50 px-3 py-2 text-sm text-secondary-600">
          {i18n.t('literals.nincs-listazhato-tetel')}
        </p>
      ) : (
        <div className="space-y-2">
          {rows.map((row) => {
            const rowActions = actions?.(row) ?? []
            return (
              <div key={row.id} className="rounded border border-secondary-100 bg-secondary-50 p-2">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <div className="break-words text-sm font-semibold text-secondary-900">
                      {row.primary}
                    </div>
                    <div className="text-xs text-secondary-500">{row.secondary}</div>
                  </div>
                  <span className="shrink-0 rounded bg-white px-2 py-1 text-[11px] font-semibold text-secondary-700">
                    {row.status}
                  </span>
                </div>
                {rowActions.length > 0 && (
                  <div className="mt-2 grid grid-cols-2 gap-1.5">
                    {rowActions.map((action) => (
                      <button
                        key={action.key}
                        type="button"
                        className="min-h-9 rounded border border-secondary-200 bg-white px-2 text-[11px] font-semibold text-secondary-800 disabled:opacity-50"
                        disabled={busyKey === action.key}
                        onClick={action.onClick}
                        aria-label={action.ariaLabel}
                      >
                        {busyKey === action.key ? '...' : action.label}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}
    </section>
  )
}

function DataRow({ label, value, accent }: { label: string; value: string; accent?: boolean }) {
  return (
    <div className="flex justify-between items-baseline border-b border-secondary-100 pb-1.5">
      <span className="text-secondary-600">{label}</span>
      <span
        className={`font-mono font-semibold ${accent ? 'text-primary-700' : 'text-secondary-900'}`}
      >
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
