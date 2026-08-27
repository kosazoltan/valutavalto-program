import { useCallback, useEffect, useMemo, useState } from 'react'
import type React from 'react'
import { Link } from 'react-router-dom'
import {
  AlertTriangle,
  ArrowLeftRight,
  Bell,
  Building2,
  Camera,
  CheckCircle,
  ClipboardCheck,
  CreditCard,
  Database,
  FileText,
  Globe,
  Loader2,
  Package,
  RefreshCw,
  Search,
  Server,
  ShieldAlert,
  Smartphone,
  Upload,
  Users,
  Wallet,
} from 'lucide-react'
import {
  api,
  branchMonitoringApi,
  cashBalanceApi,
  customerApi,
  documentScannerApi,
  exchangeRateApi,
  ertektarApi,
  notificationApi,
  posTerminalApi,
  rateApprovalApi,
  stornoApi,
  synchronizationApi,
  transferDocumentApi,
  type BankTransaction,
  type BranchStatusResponse,
  type CashPositionItem,
  type Customer,
  type DetailedCashPosition,
  type DocumentScannerUploadRequest,
  type ErtektarCollection,
  type ErtektarDistribution,
  type ExchangeRate,
  type Notification as AppNotification,
  type PosTerminal,
  type PosTerminalRuntimeStatus,
  type ScannedDocument,
  type StornoApproval,
  type TransferDocument,
  type VaultOperationStatus,
} from '../../services/api/index'
import { diagnosticsApi, type ErrorSummary } from '../../services/api/diagnostics'
import { useAuthStore } from '../../stores/authStore'
import { getErrorMessage } from '../../utils/errorHandling'
import { formatMillions } from '../treasury/treasuryUtils'
import i18n from '../../i18n'

interface DashboardSummary {
  todayVolume?: number
  activeBranches?: number
  openTransactions?: number
  alertCount?: number
}

interface SyncProbe {
  shouldSync: boolean
  pendingCount: number
}

interface DataCollectionStatus {
  id?: string
  branchId?: string
  collectionDate?: string
  status: string
  collectionType?: string
  transactionCount?: number
  completedAt?: string
  errorMessage?: string
}

interface SystemParam {
  id?: string
  key: string
  value?: string | null
  type?: string | null
  category?: string | null
  description?: string | null
  updatedAt?: string | null
}

interface SyncRestoreStatus {
  branchId?: string
  totalTransactions?: number
  earliestDate?: string | null
  latestDate?: string | null
  restoreAvailable?: boolean
}

interface YearOpeningStatus {
  lastExecutionYear?: number | string | null
  lastExecutionAt?: string | null
  canExecute?: boolean
  status?: string | null
  message?: string | null
}

interface WuBalance {
  id?: string
  branchId?: string
  usdBalance?: number | string | null
  hufBalance?: number | string | null
  updatedAt?: string | null
}

interface WuDailyReport {
  date?: string
  sendCount?: number
  receiveCount?: number
  totalSendUsd?: number | string | null
  totalReceiveUsd?: number | string | null
  totalFees?: number | string | null
  stornoCount?: number
}

interface DailyReportSubmissionStatus {
  branchId?: string
  branchCode?: string
  branchName?: string
  submitted?: boolean | null
  submittedAt?: string | null
}

interface RateApproval {
  id?: string
  branchId?: string
  branchName?: string
  currencyCode?: string
  oldBuyRate?: number | string | null
  oldSellRate?: number | string | null
  newBuyRate?: number | string | null
  newSellRate?: number | string | null
  status?: string | null
  requestedByName?: string | null
  requestedAt?: string | null
  reason?: string | null
}

interface CameraStatus {
  cameraId: string
  cameraName?: string | null
  recording?: boolean | null
  connected?: boolean | null
}

interface CameraStorageStats {
  totalUsageBytes?: number | null
  availableSpaceBytes?: number | null
  totalRecordings?: number | null
  oldestDate?: string | null
  newestDate?: string | null
}

interface CameraUploadStatus {
  pendingUploads?: number | null
}

interface CashRegisterDevice {
  id: string
  branchId: string
  code: string
  name?: string | null
  appMode?: string | null
  appVersion?: string | null
  lastSeenAt?: string | null
  isActive?: boolean | null
}

interface CashRegisterEvent {
  id?: string
  branchId?: string
  eventType?: string | null
  status?: string | null
  receiptNumber?: string | null
  occurredAt?: string | null
  createdAt?: string | null
  rawResponse?: string | null
}

interface NavClosing {
  id: string
  closingDate?: string | null
  branchId?: string | null
  closingType?: string | null
  totalRevenue?: number | string | null
  totalExpense?: number | string | null
  status?: string | null
  navReferenceNumber?: string | null
  createdAt?: string | null
}

interface PageResponse<T> {
  content?: T[]
}

interface WuStubRate {
  sourceCurrency?: string | null
  targetCurrency?: string | null
  currency?: string | null
  rate?: number | string | null
  fee?: number | string | null
}

interface WuStubStatus {
  mtcn?: string | null
  status?: string | null
  message?: string | null
  amountUsd?: number | string | null
  destinationCountry?: string | null
}

type PanelStatus = 'ok' | 'loading' | 'unavailable'
type MobileWorkArea =
  | 'cashier'
  | 'field'
  | 'camera'
  | 'vault'
  | 'approval'
  | 'customer'
  | 'management'
  | 'integrations'
type MobileErtektarStatusKind = 'collection' | 'distribution' | 'bankTransaction'
type MobileBranchSyncKind = 'rates' | 'transactions' | 'inventory' | 'full'

const fmt = (value: number | undefined | null) => (value ?? 0).toLocaleString('hu-HU')
const num = (value: number | string | null | undefined) => {
  const parsed = typeof value === 'number' ? value : Number(String(value ?? '').replace(',', '.'))
  return Number.isFinite(parsed) ? parsed : 0
}
const isBranchOnline = (branch: BranchStatusResponse) => Boolean(branch.isOnline ?? branch.online)
const compactBranchId = (branchId: string) =>
  branchId.length > 18 ? `${branchId.slice(0, 8)}...${branchId.slice(-6)}` : branchId
const formatLocalDateTime = (value?: string | null) =>
  value ? value.replace('T', ' ').slice(0, 16) : 'Nincs adat'
const formatBytes = (value?: number | null) => {
  const bytes = value ?? 0
  if (bytes < 1024 * 1024) return `${Math.round(bytes / 1024)} KB`
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`
}
const minutesSince = (value?: string | null) => {
  if (!value) return null
  const timestamp = new Date(value).getTime()
  if (!Number.isFinite(timestamp)) return null
  return Math.max(0, Math.floor((Date.now() - timestamp) / 60_000))
}
const todayIso = () => new Date().toISOString().slice(0, 10)
const RATE_REJECTION_REASON = 'Mobil elutasítás'

export default function MobileOverviewPage() {
  const worker = useAuthStore((state) => state.worker)

  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [dashboard, setDashboard] = useState<DashboardSummary | null>(null)
  const [position, setPosition] = useState<DetailedCashPosition | null>(null)
  const [rates, setRates] = useState<ExchangeRate[]>([])
  const [approvals, setApprovals] = useState<StornoApproval[]>([])
  const [syncProbe, setSyncProbe] = useState<SyncProbe | null>(null)
  const [dataCollectionRows, setDataCollectionRows] = useState<DataCollectionStatus[]>([])
  const [errorSummary, setErrorSummary] = useState<ErrorSummary | null>(null)
  const [branchDashboard, setBranchDashboard] = useState<BranchStatusResponse[]>([])
  const [onlineBranches, setOnlineBranches] = useState<BranchStatusResponse[]>([])
  const [offlineBranches, setOfflineBranches] = useState<BranchStatusResponse[]>([])
  const [supervisorParams, setSupervisorParams] = useState<SystemParam[]>([])
  const [syncRestoreStatus, setSyncRestoreStatus] = useState<SyncRestoreStatus | null>(null)
  const [yearOpeningStatus, setYearOpeningStatus] = useState<YearOpeningStatus | null>(null)
  const [wuBalance, setWuBalance] = useState<WuBalance[]>([])
  const [wuDailyReport, setWuDailyReport] = useState<WuDailyReport | null>(null)
  const [dailyReportStatusRows, setDailyReportStatusRows] = useState<DailyReportSubmissionStatus[]>(
    [],
  )
  const [pendingRateApprovals, setPendingRateApprovals] = useState<RateApproval[]>([])
  const [rateApprovalHistory, setRateApprovalHistory] = useState<RateApproval[]>([])
  const [cameraStatuses, setCameraStatuses] = useState<CameraStatus[]>([])
  const [cameraStorageStats, setCameraStorageStats] = useState<CameraStorageStats | null>(null)
  const [cameraUploadStatus, setCameraUploadStatus] = useState<CameraUploadStatus | null>(null)
  const [posTerminals, setPosTerminals] = useState<PosTerminal[]>([])
  const [posRuntimeStatuses, setPosRuntimeStatuses] = useState<
    Record<string, PosTerminalRuntimeStatus>
  >({})
  const [cashRegisterDevices, setCashRegisterDevices] = useState<CashRegisterDevice[]>([])
  const [cashRegisterEvents, setCashRegisterEvents] = useState<CashRegisterEvent[]>([])
  const [cashRegisterGaps, setCashRegisterGaps] = useState<string[]>([])
  const [navClosings, setNavClosings] = useState<NavClosing[]>([])
  const [wuStubRates, setWuStubRates] = useState<WuStubRate[]>([])
  const [wuStubMtcn, setWuStubMtcn] = useState('')
  const [wuStubStatus, setWuStubStatus] = useState<WuStubStatus | null>(null)
  const [wuStubStatusLoading, setWuStubStatusLoading] = useState(false)
  const [transferDocuments, setTransferDocuments] = useState<TransferDocument[]>([])
  const [ertektarCollections, setErtektarCollections] = useState<ErtektarCollection[]>([])
  const [ertektarDistributions, setErtektarDistributions] = useState<ErtektarDistribution[]>([])
  const [ertektarBankTransactions, setErtektarBankTransactions] = useState<BankTransaction[]>([])
  const [panelStatus, setPanelStatus] = useState<Record<string, PanelStatus>>({})
  const [actionError, setActionError] = useState<string | null>(null)
  const [actingApprovalId, setActingApprovalId] = useState<string | null>(null)
  const [actingRateApprovalId, setActingRateApprovalId] = useState<string | null>(null)
  const [actingTransferDocumentId, setActingTransferDocumentId] = useState<string | null>(null)
  const [actingErtektarStatusId, setActingErtektarStatusId] = useState<string | null>(null)
  const [transferPickupPin, setTransferPickupPin] = useState('')
  const [customerQuery, setCustomerQuery] = useState('')
  const [customerResults, setCustomerResults] = useState<Customer[]>([])
  const [customerLoading, setCustomerLoading] = useState(false)
  const [customerError, setCustomerError] = useState<string | null>(null)
  const [notifications, setNotifications] = useState<AppNotification[]>([])
  const [unreadNotificationCount, setUnreadNotificationCount] = useState(0)
  const [actingNotificationId, setActingNotificationId] = useState<string | null>(null)
  const [mobileDocumentCustomerId, setMobileDocumentCustomerId] = useState('')
  const [mobileDocumentType, setMobileDocumentType] =
    useState<DocumentScannerUploadRequest['documentType']>('ID_CARD')
  const [mobileDocumentNotes, setMobileDocumentNotes] = useState('')
  const [mobileScannedDocuments, setMobileScannedDocuments] = useState<ScannedDocument[]>([])
  const [mobileDocumentUploading, setMobileDocumentUploading] = useState(false)
  const [mobileDocumentError, setMobileDocumentError] = useState<string | null>(null)
  const [activeWorkArea, setActiveWorkArea] = useState<MobileWorkArea>('cashier')
  const [supervisorPassword, setSupervisorPassword] = useState('')
  const [supervisorBranchId, setSupervisorBranchId] = useState(() =>
    worker?.branchId ? String(worker.branchId) : '',
  )
  const [supervisorCurrency, setSupervisorCurrency] = useState('EUR')
  const [supervisorBuyRate, setSupervisorBuyRate] = useState('')
  const [supervisorSellRate, setSupervisorSellRate] = useState('')
  const [supervisorRateReason, setSupervisorRateReason] = useState('')
  const [supervisorTransactionId, setSupervisorTransactionId] = useState('')
  const [supervisorFee, setSupervisorFee] = useState('')
  const [supervisorFeeReason, setSupervisorFeeReason] = useState('')
  const [supervisorOverrideMessage, setSupervisorOverrideMessage] = useState<string | null>(null)
  const [supervisorActionLoading, setSupervisorActionLoading] = useState<string | null>(null)
  const [yearOpeningTargetYear, setYearOpeningTargetYear] = useState(() =>
    String(new Date().getFullYear() + 1),
  )
  const [yearOpeningRunning, setYearOpeningRunning] = useState(false)
  const [mobileSyncBranchId, setMobileSyncBranchId] = useState(() =>
    worker?.branchId ? String(worker.branchId) : '',
  )
  const [mobileSyncActionLoading, setMobileSyncActionLoading] =
    useState<MobileBranchSyncKind | null>(null)
  const [mobileSyncMessage, setMobileSyncMessage] = useState<string | null>(null)

  const setPanel = useCallback((key: string, status: PanelStatus) => {
    setPanelStatus((prev) => ({ ...prev, [key]: status }))
  }, [])

  const load = useCallback(async () => {
    setRefreshing(true)
    setActionError(null)
    const panelKeys = [
      'dashboard',
      'position',
      'rates',
      'approvals',
      'sync',
      'dataCollection',
      'diagnostics',
      'branchMonitoring',
      'operationalControl',
      'rateApprovals',
      'camera',
      'integrations',
      'transferDocuments',
      'ertektarStatus',
      'notifications',
    ]
    panelKeys.forEach((key) => setPanel(key, 'loading'))
    const branchId = worker?.branchId
    const reportDate = todayIso()

    const [
      dashboardResult,
      positionResult,
      ratesResult,
      approvalsResult,
      syncResult,
      dataCollectionResult,
      diagnosticsResult,
      branchDashboardResult,
      onlineBranchesResult,
      offlineBranchesResult,
      supervisorParamsResult,
      syncRestoreResult,
      yearOpeningResult,
      wuBalanceResult,
      wuDailyReportResult,
      dailyReportStatusResult,
      pendingRateApprovalsResult,
      rateApprovalHistoryResult,
      cameraStatusResult,
      cameraStorageResult,
      cameraUploadResult,
      posTerminalsResult,
      cashRegisterDevicesResult,
      cashRegisterEventsResult,
      cashRegisterGapsResult,
      navClosingsResult,
      wuStubRatesResult,
      transferDocumentsResult,
      ertektarCollectionsResult,
      ertektarDistributionsResult,
      ertektarBankTransactionsResult,
      unreadNotificationsResult,
      unreadNotificationCountResult,
    ] = await Promise.allSettled([
      api.get<DashboardSummary>('/dashboard/summary'),
      cashBalanceApi.getDetailedPosition(),
      exchangeRateApi.list(),
      stornoApi.pendingApprovals(),
      synchronizationApi.shouldSync(),
      api.get<DataCollectionStatus[]>('/data-collection/status'),
      diagnosticsApi.getErrorSummary(),
      branchMonitoringApi.dashboard(),
      branchMonitoringApi.online(),
      branchMonitoringApi.offline(5),
      api.get<SystemParam[]>('/supervisor/params'),
      api.get<SyncRestoreStatus>('/sync/restore/status'),
      api.get<YearOpeningStatus>('/year-opening/status'),
      branchId
        ? api.get<WuBalance[]>('/western-union/balance', { params: { branchId } })
        : Promise.reject(new Error('Nincs branchId a WU egyenleg lekéréshez.')),
      branchId
        ? api.get<WuDailyReport>('/western-union/daily-report', {
            params: { branchId, date: reportDate },
          })
        : Promise.reject(new Error('Nincs branchId a WU napi riport lekéréshez.')),
      api.get<DailyReportSubmissionStatus[]>('/reports/daily/submission-status', {
        params: { date: reportDate },
      }),
      rateApprovalApi.pending(),
      rateApprovalApi.history(),
      api.get<CameraStatus[]>('/camera/status'),
      api.get<CameraStorageStats>('/camera/admin/storage-stats'),
      api.get<CameraUploadStatus>('/camera/admin/upload-status'),
      posTerminalApi.list(),
      api.get<CashRegisterDevice[]>('/cash-register/devices'),
      branchId
        ? api.get<CashRegisterEvent[]>(`/cash-register/events/${branchId}`, {
            params: { date: reportDate },
          })
        : Promise.reject(new Error('Nincs branchId a pénztárgép események lekéréshez.')),
      branchId
        ? api.get<string[]>(`/cash-register/receipt-gaps/${branchId}`, {
            params: { date: reportDate },
          })
        : Promise.reject(new Error('Nincs branchId a pénztárgép sorszámellenőrzéshez.')),
      api.get<PageResponse<NavClosing> | NavClosing[]>('/nav/closings', {
        params: { page: 0, size: 5, dateFrom: reportDate, dateTo: reportDate },
      }),
      api.get<WuStubRate[]>('/western-union-stub/rates'),
      transferDocumentApi.list(),
      ertektarApi.getCollections(),
      ertektarApi.getDistributions(),
      ertektarApi.getBankTransactions(),
      notificationApi.getUnread(),
      notificationApi.unreadCount(),
    ])

    if (dashboardResult.status === 'fulfilled') {
      setDashboard(dashboardResult.value.data ?? null)
      setPanel('dashboard', 'ok')
    } else {
      setDashboard(null)
      setPanel('dashboard', 'unavailable')
    }

    if (positionResult.status === 'fulfilled') {
      setPosition(positionResult.value)
      setPanel('position', 'ok')
    } else {
      setPosition(null)
      setPanel('position', 'unavailable')
    }

    if (ratesResult.status === 'fulfilled') {
      setRates(ratesResult.value.filter((rate) => rate.active).slice(0, 4))
      setPanel('rates', 'ok')
    } else {
      setRates([])
      setPanel('rates', 'unavailable')
    }

    if (approvalsResult.status === 'fulfilled') {
      setApprovals(approvalsResult.value)
      setPanel('approvals', 'ok')
    } else {
      setApprovals([])
      setPanel('approvals', 'unavailable')
    }

    if (syncResult.status === 'fulfilled') {
      setSyncProbe(syncResult.value)
      setPanel('sync', 'ok')
    } else {
      setSyncProbe(null)
      setPanel('sync', 'unavailable')
    }

    if (dataCollectionResult.status === 'fulfilled') {
      setDataCollectionRows(dataCollectionResult.value.data ?? [])
      setPanel('dataCollection', 'ok')
    } else {
      setDataCollectionRows([])
      setPanel('dataCollection', 'unavailable')
    }

    if (diagnosticsResult.status === 'fulfilled') {
      setErrorSummary(diagnosticsResult.value)
      setPanel('diagnostics', 'ok')
    } else {
      setErrorSummary(null)
      setPanel('diagnostics', 'unavailable')
    }

    if (
      branchDashboardResult.status === 'fulfilled' &&
      onlineBranchesResult.status === 'fulfilled' &&
      offlineBranchesResult.status === 'fulfilled'
    ) {
      setBranchDashboard(Object.values(branchDashboardResult.value ?? {}))
      setOnlineBranches(onlineBranchesResult.value)
      setOfflineBranches(offlineBranchesResult.value)
      setPanel('branchMonitoring', 'ok')
    } else {
      setBranchDashboard([])
      setOnlineBranches([])
      setOfflineBranches([])
      setPanel('branchMonitoring', 'unavailable')
    }

    if (
      supervisorParamsResult.status === 'fulfilled' &&
      syncRestoreResult.status === 'fulfilled' &&
      yearOpeningResult.status === 'fulfilled' &&
      wuBalanceResult.status === 'fulfilled' &&
      wuDailyReportResult.status === 'fulfilled' &&
      dailyReportStatusResult.status === 'fulfilled'
    ) {
      setSupervisorParams(supervisorParamsResult.value.data ?? [])
      setSyncRestoreStatus(syncRestoreResult.value.data ?? null)
      setYearOpeningStatus(yearOpeningResult.value.data ?? null)
      setWuBalance(wuBalanceResult.value.data ?? [])
      setWuDailyReport(wuDailyReportResult.value.data ?? null)
      setDailyReportStatusRows(dailyReportStatusResult.value.data ?? [])
      setPanel('operationalControl', 'ok')
    } else {
      setSupervisorParams([])
      setSyncRestoreStatus(null)
      setYearOpeningStatus(null)
      setWuBalance([])
      setWuDailyReport(null)
      setDailyReportStatusRows([])
      setPanel('operationalControl', 'unavailable')
    }

    if (
      pendingRateApprovalsResult.status === 'fulfilled' &&
      rateApprovalHistoryResult.status === 'fulfilled'
    ) {
      setPendingRateApprovals(pendingRateApprovalsResult.value ?? [])
      setRateApprovalHistory(rateApprovalHistoryResult.value ?? [])
      setPanel('rateApprovals', 'ok')
    } else {
      setPendingRateApprovals([])
      setRateApprovalHistory([])
      setPanel('rateApprovals', 'unavailable')
    }

    if (
      cameraStatusResult.status === 'fulfilled' &&
      cameraStorageResult.status === 'fulfilled' &&
      cameraUploadResult.status === 'fulfilled'
    ) {
      setCameraStatuses(cameraStatusResult.value.data ?? [])
      setCameraStorageStats(cameraStorageResult.value.data ?? null)
      setCameraUploadStatus(cameraUploadResult.value.data ?? null)
      setPanel('camera', 'ok')
    } else {
      setCameraStatuses([])
      setCameraStorageStats(null)
      setCameraUploadStatus(null)
      setPanel('camera', 'unavailable')
    }

    if (
      posTerminalsResult.status === 'fulfilled' &&
      cashRegisterDevicesResult.status === 'fulfilled' &&
      cashRegisterEventsResult.status === 'fulfilled' &&
      cashRegisterGapsResult.status === 'fulfilled' &&
      navClosingsResult.status === 'fulfilled' &&
      wuStubRatesResult.status === 'fulfilled'
    ) {
      const terminals = posTerminalsResult.value ?? []
      const runtimeResults = await Promise.allSettled(
        terminals
          .filter((terminal) => terminal.isActive !== false)
          .slice(0, 3)
          .map(
            async (terminal) =>
              [terminal.terminalId, await posTerminalApi.status(terminal.terminalId)] as const,
          ),
      )
      const runtimeStatuses: Record<string, PosTerminalRuntimeStatus> = {}
      for (const result of runtimeResults) {
        if (result.status === 'fulfilled') {
          runtimeStatuses[result.value[0]] = result.value[1]
        }
      }
      const navClosingPayload = navClosingsResult.value.data
      setPosTerminals(terminals)
      setPosRuntimeStatuses(runtimeStatuses)
      setCashRegisterDevices(cashRegisterDevicesResult.value.data ?? [])
      setCashRegisterEvents(cashRegisterEventsResult.value.data ?? [])
      setCashRegisterGaps(cashRegisterGapsResult.value.data ?? [])
      setNavClosings(
        Array.isArray(navClosingPayload) ? navClosingPayload : (navClosingPayload?.content ?? []),
      )
      setWuStubRates(wuStubRatesResult.value.data ?? [])
      setPanel('integrations', 'ok')
    } else {
      setPosTerminals([])
      setPosRuntimeStatuses({})
      setCashRegisterDevices([])
      setCashRegisterEvents([])
      setCashRegisterGaps([])
      setNavClosings([])
      setWuStubRates([])
      setPanel('integrations', 'unavailable')
    }

    if (transferDocumentsResult.status === 'fulfilled') {
      setTransferDocuments(transferDocumentsResult.value.slice(0, 5))
      setPanel('transferDocuments', 'ok')
    } else {
      setTransferDocuments([])
      setPanel('transferDocuments', 'unavailable')
    }

    if (
      ertektarCollectionsResult.status === 'fulfilled' &&
      ertektarDistributionsResult.status === 'fulfilled' &&
      ertektarBankTransactionsResult.status === 'fulfilled'
    ) {
      setErtektarCollections(
        Array.isArray(ertektarCollectionsResult.value) ? ertektarCollectionsResult.value : [],
      )
      setErtektarDistributions(
        Array.isArray(ertektarDistributionsResult.value) ? ertektarDistributionsResult.value : [],
      )
      setErtektarBankTransactions(
        Array.isArray(ertektarBankTransactionsResult.value)
          ? ertektarBankTransactionsResult.value
          : [],
      )
      setPanel('ertektarStatus', 'ok')
    } else {
      setErtektarCollections([])
      setErtektarDistributions([])
      setErtektarBankTransactions([])
      setPanel('ertektarStatus', 'unavailable')
    }

    if (unreadNotificationsResult.status === 'fulfilled') {
      setNotifications(unreadNotificationsResult.value)
      setUnreadNotificationCount(
        unreadNotificationCountResult.status === 'fulfilled'
          ? unreadNotificationCountResult.value
          : unreadNotificationsResult.value.length,
      )
      setPanel('notifications', 'ok')
    } else {
      setNotifications([])
      setUnreadNotificationCount(0)
      setPanel('notifications', 'unavailable')
    }

    setLoading(false)
    setRefreshing(false)
  }, [setPanel, worker?.branchId])

  useEffect(() => {
    void load()
  }, [load])

  const alertCount =
    (dashboard?.alertCount ?? 0) +
    (position?.lowBalanceAlerts ?? 0) +
    (position?.highBalanceAlerts ?? 0)
  const syncPendingCount = syncProbe?.pendingCount ?? 0
  const monitoredBranchCount = branchDashboard.length
  const onlineBranchCount = onlineBranches.length || branchDashboard.filter(isBranchOnline).length
  const offlineBranchCount =
    offlineBranches.length || branchDashboard.filter((branch) => !isBranchOnline(branch)).length
  const branchOpenAlerts = branchDashboard.reduce(
    (sum, branch) => sum + (branch.openAlerts ?? 0),
    0,
  )
  const branchDailyTransactions = branchDashboard.reduce(
    (sum, branch) => sum + (branch.dailyTransactionCount ?? 0),
    0,
  )
  const branchDailyVolume = branchDashboard.reduce(
    (sum, branch) => sum + (branch.dailyVolumeHuf ?? 0),
    0,
  )
  const failedDataCollections = dataCollectionRows.filter((row) => row.status === 'FAILED').length
  const pendingDataCollections = dataCollectionRows.filter(
    (row) => row.status !== 'COMPLETED' && row.status !== 'FAILED',
  ).length
  const latestDataCollection = dataCollectionRows[0]
  const restoreMissing = syncRestoreStatus ? !syncRestoreStatus.restoreAvailable : false
  const wuUsdBalance = wuBalance.reduce((sum, row) => sum + num(row.usdBalance), 0)
  const wuHufBalance = wuBalance.reduce((sum, row) => sum + num(row.hufBalance), 0)
  const submittedDailyReports = dailyReportStatusRows.filter((row) => row.submitted).length
  const missingDailyReports = dailyReportStatusRows.filter((row) => !row.submitted)
  const latestRateApproval = rateApprovalHistory[0]
  const connectedCameraCount = cameraStatuses.filter((camera) => camera.connected !== false).length
  const recordingCameraCount = cameraStatuses.filter((camera) => camera.recording).length
  const disconnectedCameraCount = cameraStatuses.filter(
    (camera) => camera.connected === false,
  ).length
  const pendingCameraUploads = cameraUploadStatus?.pendingUploads ?? 0
  const activePosTerminalCount = posTerminals.filter(
    (terminal) => terminal.isActive !== false,
  ).length
  const connectedPosTerminalCount = Object.values(posRuntimeStatuses).filter(
    (status) => status.connected,
  ).length
  const unavailablePosTerminalCount = Math.max(
    0,
    activePosTerminalCount - connectedPosTerminalCount,
  )
  const staleCashRegisterDevices = cashRegisterDevices.filter((device) => {
    const age = minutesSince(device.lastSeenAt)
    return device.isActive !== false && (age == null || age > 10)
  })
  const openNavClosingCount = navClosings.filter((closing) => {
    const status = String(closing.status ?? '').toUpperCase()
    return status !== 'SUBMITTED' && status !== 'CLOSED' && status !== 'ACCEPTED'
  }).length
  const integrationAlertCount =
    unavailablePosTerminalCount + staleCashRegisterDevices.length + cashRegisterGaps.length
  const activeTransferDocumentCount = transferDocuments.filter(
    (row) => row.status !== 'CONFIRMED',
  ).length
  const openErtektarCollections = ertektarCollections
    .filter((row) => row.status !== 'COMPLETED' && row.status !== 'REJECTED')
    .slice(0, 3)
  const openErtektarDistributions = ertektarDistributions
    .filter((row) => row.status !== 'COMPLETED' && row.status !== 'REJECTED')
    .slice(0, 3)
  const openErtektarBankTransactions = ertektarBankTransactions
    .filter((row) => row.status !== 'COMPLETED' && row.status !== 'REJECTED')
    .slice(0, 3)
  const openErtektarStatusCount =
    openErtektarCollections.length +
    openErtektarDistributions.length +
    openErtektarBankTransactions.length
  const cashPositionItems = useMemo(
    () =>
      [...(position?.items ?? [])]
        .sort(
          (a, b) =>
            Number(b.isLowBalance || b.isHighBalance) - Number(a.isLowBalance || a.isHighBalance),
        )
        .slice(0, 4),
    [position?.items],
  )
  const criticalCount =
    approvals.length +
    pendingRateApprovals.length +
    alertCount +
    syncPendingCount +
    unreadNotificationCount +
    (errorSummary?.last24h ?? 0) +
    offlineBranchCount +
    branchOpenAlerts +
    failedDataCollections +
    (restoreMissing ? 1 : 0) +
    missingDailyReports.length +
    activeTransferDocumentCount +
    openErtektarStatusCount +
    disconnectedCameraCount +
    pendingCameraUploads +
    integrationAlertCount
  const workAreaAlerts: Record<MobileWorkArea, number> = {
    cashier: alertCount + syncPendingCount,
    field:
      offlineBranchCount +
      failedDataCollections +
      pendingDataCollections +
      activeTransferDocumentCount,
    camera: disconnectedCameraCount + pendingCameraUploads,
    vault: openErtektarStatusCount,
    approval: approvals.length + pendingRateApprovals.length,
    customer: mobileScannedDocuments.length,
    management:
      branchOpenAlerts +
      unreadNotificationCount +
      (errorSummary?.last24h ?? 0) +
      missingDailyReports.length +
      (restoreMissing ? 1 : 0),
    integrations: integrationAlertCount,
  }

  const statusTone = useMemo(() => {
    if (criticalCount > 0) return 'border-amber-200 bg-amber-50 text-amber-900'
    return 'border-emerald-200 bg-emerald-50 text-emerald-900'
  }, [criticalCount])

  const panel = (key: string): PanelStatus => panelStatus[key] ?? 'loading'

  const approve = async (approval: StornoApproval) => {
    try {
      setActingApprovalId(approval.id)
      setActionError(null)
      await stornoApi.approve(approval.id, true)
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setActingApprovalId(null)
    }
  }

  const approveRateApproval = async (approval: RateApproval) => {
    if (!approval.id) return

    try {
      setActingRateApprovalId(`${approval.id}:approve`)
      setActionError(null)
      await rateApprovalApi.approve(approval.id)
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setActingRateApprovalId(null)
    }
  }

  const rejectRateApproval = async (approval: RateApproval) => {
    if (!approval.id) return

    try {
      setActingRateApprovalId(`${approval.id}:reject`)
      setActionError(null)
      await rateApprovalApi.reject(approval.id, RATE_REJECTION_REASON)
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setActingRateApprovalId(null)
    }
  }

  const searchCustomers = async () => {
    const query = customerQuery.trim()
    if (!query) {
      setCustomerResults([])
      setCustomerError(null)
      return
    }

    try {
      setCustomerLoading(true)
      setCustomerError(null)
      const results = await customerApi.search(query)
      setCustomerResults(results)
      if (!mobileDocumentCustomerId.trim() && results[0]?.id != null) {
        setMobileDocumentCustomerId(String(results[0].id))
      }
    } catch (err) {
      setCustomerResults([])
      setCustomerError(getErrorMessage(err))
    } finally {
      setCustomerLoading(false)
    }
  }

  const parsedMobileDocumentCustomerId = () => {
    const parsed = Number(mobileDocumentCustomerId.trim())
    return Number.isInteger(parsed) && parsed > 0 ? parsed : null
  }

  const loadMobileCustomerDocuments = async () => {
    const customerId = parsedMobileDocumentCustomerId()
    if (customerId == null) {
      setMobileDocumentError('Adj meg érvényes ügyfél azonosítót az okmánylistához.')
      return
    }

    try {
      setMobileDocumentError(null)
      setMobileScannedDocuments(await documentScannerApi.getCustomerDocuments(customerId))
    } catch (err) {
      setMobileScannedDocuments([])
      setMobileDocumentError(getErrorMessage(err))
    }
  }

  const handleMobileDocumentUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    event.target.value = ''
    if (!file) return

    const customerId = parsedMobileDocumentCustomerId()
    if (customerId == null) {
      setMobileDocumentError('Adj meg érvényes ügyfél azonosítót a telefonos feltöltéshez.')
      return
    }

    try {
      setMobileDocumentUploading(true)
      setMobileDocumentError(null)
      await documentScannerApi.uploadScannedDocument(file, {
        customerId,
        documentType: mobileDocumentType ?? 'OTHER',
        notes: mobileDocumentNotes.trim() || undefined,
      })
      setMobileScannedDocuments(await documentScannerApi.getCustomerDocuments(customerId))
    } catch (err) {
      setMobileDocumentError(getErrorMessage(err))
    } finally {
      setMobileDocumentUploading(false)
    }
  }

  const markNotificationRead = async (notification: AppNotification) => {
    try {
      setActingNotificationId(notification.id)
      setActionError(null)
      await notificationApi.markAsRead(notification.id)
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setActingNotificationId(null)
    }
  }

  const markAllMobileNotificationsRead = async () => {
    try {
      setActingNotificationId('all')
      setActionError(null)
      await notificationApi.markAllAsRead()
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setActingNotificationId(null)
    }
  }

  const searchWuStubStatus = async () => {
    const mtcn = wuStubMtcn.trim()
    if (!/^\d{10}$/.test(mtcn)) {
      setActionError('Az MTCN pontosan 10 számjegy lehet.')
      return
    }

    try {
      setWuStubStatusLoading(true)
      setActionError(null)
      const response = await api.get<WuStubStatus>(`/western-union-stub/status/${mtcn}`)
      setWuStubStatus(response.data ?? null)
    } catch (err) {
      setWuStubStatus(null)
      setActionError(getErrorMessage(err))
    } finally {
      setWuStubStatusLoading(false)
    }
  }

  const updateTransferDocument = async (
    document: TransferDocument,
    action: 'pickup' | 'deliver' | 'confirm',
  ) => {
    if (!document.id) return
    if ((action === 'pickup' || action === 'confirm') && !worker?.id) {
      setActionError('Nincs bejelentkezett dolgozó a mobil átadás-átvétel művelethez.')
      return
    }

    try {
      const key = `${document.id}:${action}`
      setActingTransferDocumentId(key)
      setActionError(null)
      if (action === 'pickup') {
        await transferDocumentApi.pickup(document.id, Number(worker!.id), transferPickupPin)
        setTransferPickupPin('')
      } else if (action === 'deliver') {
        await transferDocumentApi.deliver(document.id)
      } else {
        await transferDocumentApi.confirm(document.id, Number(worker!.id))
      }
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setActingTransferDocumentId(null)
    }
  }

  const updateMobileErtektarStatus = async (
    kind: MobileErtektarStatusKind,
    id: number,
    status: VaultOperationStatus,
  ) => {
    if (!window.confirm(`Biztosan ${status} státuszra állítod a #${id} értéktári tételt?`)) return

    const key = `${kind}:${id}:${status}`
    try {
      setActingErtektarStatusId(key)
      setActionError(null)
      if (kind === 'collection') {
        await ertektarApi.updateCollectionStatus(id, status)
      } else if (kind === 'distribution') {
        await ertektarApi.updateDistributionStatus(id, status)
      } else {
        await ertektarApi.updateBankTransactionStatus(id, status)
      }
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setActingErtektarStatusId(null)
    }
  }

  const authenticateSupervisor = async () => {
    const password = supervisorPassword.trim()
    if (!password) {
      setActionError('Supervisor jelszó kötelező.')
      return
    }

    try {
      setSupervisorActionLoading('auth')
      setActionError(null)
      setSupervisorOverrideMessage(null)
      const response = await api.post<{ authenticated: boolean }>('/supervisor/authenticate', {
        password,
      })
      setSupervisorOverrideMessage(
        response.data?.authenticated
          ? 'Supervisor jelszó ellenőrizve.'
          : 'Supervisor jelszó elutasítva.',
      )
      setSupervisorPassword('')
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setSupervisorActionLoading(null)
    }
  }

  const overrideSupervisorRate = async () => {
    const branchId = supervisorBranchId.trim()
    const currency = supervisorCurrency.trim().toUpperCase()
    const newBuyRate = num(supervisorBuyRate)
    const newSellRate = num(supervisorSellRate)
    const reason = supervisorRateReason.trim()
    if (!branchId || !currency || newBuyRate <= 0 || newSellRate <= 0 || !reason) {
      setActionError(
        'Árfolyam felülbíráláshoz iroda, valuta, két pozitív árfolyam és indoklás kell.',
      )
      return
    }

    try {
      setSupervisorActionLoading('rate')
      setActionError(null)
      setSupervisorOverrideMessage(null)
      await api.post('/supervisor/override-rate', {
        branchId,
        currency,
        newBuyRate,
        newSellRate,
        reason,
      })
      setSupervisorOverrideMessage('Árfolyam felülbírálat rögzítve.')
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setSupervisorActionLoading(null)
    }
  }

  const overrideSupervisorFee = async () => {
    const transactionId = Number(supervisorTransactionId.trim())
    const newFee = num(supervisorFee)
    const reason = supervisorFeeReason.trim()
    if (!Number.isInteger(transactionId) || transactionId <= 0 || newFee < 0 || !reason) {
      setActionError('Díj felülbíráláshoz pozitív tranzakció ID, nem negatív díj és indoklás kell.')
      return
    }

    try {
      setSupervisorActionLoading('fee')
      setActionError(null)
      setSupervisorOverrideMessage(null)
      await api.post('/supervisor/override-fee', { transactionId, newFee, reason })
      setSupervisorOverrideMessage('Kezelési díj felülbírálat rögzítve.')
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setSupervisorActionLoading(null)
    }
  }

  const runMobileBranchSync = async (kind: MobileBranchSyncKind) => {
    const selectedBranchId = mobileSyncBranchId.trim()
    if (!selectedBranchId) {
      setActionError('Adj meg iroda azonosítót a mobil sync indításához.')
      return
    }

    try {
      setMobileSyncActionLoading(kind)
      setActionError(null)
      setMobileSyncMessage(null)
      const requestConfig = { validateStatus: () => true }
      const response =
        kind === 'rates'
          ? await api.post<{ status?: string; syncType?: string }>(
              `/sync/rates/${selectedBranchId}`,
              null,
              requestConfig,
            )
          : kind === 'transactions'
            ? await api.post<{ status?: string; syncType?: string }>(
                `/sync/transactions/${selectedBranchId}`,
                null,
                requestConfig,
              )
            : kind === 'inventory'
              ? await api.post<{ status?: string; syncType?: string }>(
                  `/sync/inventory/${selectedBranchId}`,
                  null,
                  requestConfig,
                )
              : await api.post<{ status?: string; syncType?: string }>(
                  `/sync/full/${selectedBranchId}`,
                  null,
                  requestConfig,
                )
      if (response.status >= 400 && response.status !== 503)
        throw new Error(`HTTP ${response.status}`)
      setMobileSyncMessage(`${selectedBranchId}: ${response.data?.status ?? kind} sync elindítva.`)
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setMobileSyncActionLoading(null)
    }
  }

  const executeYearOpening = async () => {
    const targetYear = Number(yearOpeningTargetYear.trim())
    if (!Number.isInteger(targetYear) || targetYear < 2000 || targetYear > 2100) {
      setActionError('Érvényes cél évet adj meg az évnyitáshoz.')
      return
    }
    if (
      !window.confirm(
        `Biztosan futtatod az évnyitást ${targetYear} évre? Ez adminisztratív záró/nyitó workflow.`,
      )
    )
      return

    try {
      setYearOpeningRunning(true)
      setActionError(null)
      await api.post('/year-opening/execute', null, { params: { targetYear } })
      await load()
    } catch (err) {
      setActionError(getErrorMessage(err))
    } finally {
      setYearOpeningRunning(false)
    }
  }

  return (
    <div className="mx-auto flex w-full max-w-5xl flex-col gap-3 pb-36 sm:pb-4">
      <div className={`rounded-lg border p-3 ${statusTone}`}>
        <div className="flex items-start justify-between gap-2">
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <Smartphone size={18} className="shrink-0" />
              <h1 className="text-base font-bold leading-tight">
                {i18n.t('literals.mobil-felugyelet')}
              </h1>
            </div>
            <p className="mt-1 text-xs leading-5">
              {criticalCount > 0
                ? `${criticalCount} figyelendő ügy, ${offlineBranchCount} offline iroda, ${syncPendingCount} sync sorban.`
                : 'Nincs kiemelt riasztás, minden monitorozott iroda rendben.'}
            </p>
          </div>
          <button
            type="button"
            onClick={() => void load()}
            disabled={refreshing}
            className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-md border border-current/20 bg-white/60"
            aria-label="Mobil felügyelet frissítése"
          >
            <RefreshCw size={16} className={refreshing ? 'animate-spin' : ''} />
          </button>
        </div>
      </div>

      {actionError && (
        <div className="rounded-md border border-red-200 bg-red-50 p-3 text-sm text-red-700">
          {actionError}
        </div>
      )}

      {loading ? (
        <div className="flex items-center justify-center gap-2 rounded-lg border bg-white p-6 text-sm text-gray-500">
          <Loader2 size={18} className="animate-spin" />
          {i18n.t('literals.mobil-nezet-betoltese')}
        </div>
      ) : (
        <>
          <section
            className="grid gap-2 sm:grid-cols-2 xl:grid-cols-8"
            aria-label="Telefonos használati pontok"
          >
            <MobileUseCaseCard
              icon={Wallet}
              title="Pénztár"
              summary={`${fmt(position?.totalHufValue)} Ft`}
              detail={`${position?.currencyCount ?? 0} valuta, ${syncPendingCount} sync sorban`}
              urgent={alertCount + syncPendingCount > 0}
              active={activeWorkArea === 'cashier'}
              onClick={() => setActiveWorkArea('cashier')}
            />
            <MobileUseCaseCard
              icon={Server}
              title="Riasztás és státusz"
              summary={`${criticalCount} figyelendő ügy`}
              detail={`${offlineBranchCount} offline iroda, ${errorSummary?.last24h ?? 0} hiba 24h`}
              urgent={criticalCount > 0}
              active={activeWorkArea === 'management'}
              onClick={() => setActiveWorkArea('management')}
            />
            <MobileUseCaseCard
              icon={ClipboardCheck}
              title="Jóváhagyás"
              summary={`${approvals.length + pendingRateApprovals.length} függő döntés`}
              detail={`${approvals.length} sztornó, ${pendingRateApprovals.length} árfolyam`}
              urgent={approvals.length + pendingRateApprovals.length > 0}
              active={activeWorkArea === 'approval'}
              onClick={() => setActiveWorkArea('approval')}
            />
            <MobileUseCaseCard
              icon={Search}
              title="Ügyfél és AML"
              summary="Gyors keresés"
              detail="Ügyféltörzs, compliance, rendőrségi ügy"
              active={activeWorkArea === 'customer'}
              onClick={() => setActiveWorkArea('customer')}
            />
            <MobileUseCaseCard
              icon={Building2}
              title="Terepi kontroll"
              summary={`${branchDailyTransactions} mai irodai tétel`}
              detail={`${failedDataCollections} adatgyűjtési hiba, ${pendingDataCollections} folyamatban`}
              urgent={failedDataCollections + pendingDataCollections + offlineBranchCount > 0}
              active={activeWorkArea === 'field'}
              onClick={() => setActiveWorkArea('field')}
            />
            <MobileUseCaseCard
              icon={Camera}
              title="Kamera"
              summary={`${recordingCameraCount}/${cameraStatuses.length} rögzít`}
              detail={`${pendingCameraUploads} feltöltés vár, ${formatBytes(cameraStorageStats?.totalUsageBytes)} tárhely`}
              urgent={disconnectedCameraCount + pendingCameraUploads > 0}
              active={activeWorkArea === 'camera'}
              onClick={() => setActiveWorkArea('camera')}
            />
            <MobileUseCaseCard
              icon={Wallet}
              title="Értéktár"
              summary={`${openErtektarStatusCount} nyitott státusz`}
              detail={`${openErtektarCollections.length} begyűjtés, ${openErtektarDistributions.length} szétosztás, ${openErtektarBankTransactions.length} bank`}
              urgent={openErtektarStatusCount > 0}
              active={activeWorkArea === 'vault'}
              onClick={() => setActiveWorkArea('vault')}
            />
            <MobileUseCaseCard
              icon={CreditCard}
              title="Eszközök"
              summary={`${activePosTerminalCount} POS / ${cashRegisterDevices.length} pénztárgép`}
              detail={`${cashRegisterGaps.length} sorszám-gap, ${openNavClosingCount} NAV zárás`}
              urgent={integrationAlertCount > 0}
              active={activeWorkArea === 'integrations'}
              onClick={() => setActiveWorkArea('integrations')}
            />
          </section>

          <section
            className="rounded-lg border border-gray-200 bg-white p-3"
            data-testid="mobile-work-area"
          >
            <div className="mb-3 flex items-center justify-between gap-2">
              <div>
                <h2 className="text-sm font-bold text-gray-900">
                  {i18n.t('literals.mobil-munkanezet')}
                </h2>
                <p className="mt-0.5 text-xs text-gray-500">
                  {i18n.t('literals.nyitott-ugy')}
                  {criticalCount}
                  {i18n.t('literals.offline-iroda')}
                  {offlineBranchCount}
                  {i18n.t('literals.sync-sor')} {syncPendingCount}
                </p>
              </div>
              <span
                className={`shrink-0 rounded-full px-2 py-1 text-[11px] font-semibold ${criticalCount > 0 ? 'bg-amber-100 text-amber-800' : 'bg-emerald-100 text-emerald-800'}`}
              >
                {criticalCount > 0 ? `${criticalCount} ügy` : 'Rendben'}
              </span>
            </div>

            <div
              className="grid grid-cols-2 gap-2 sm:grid-cols-3 xl:grid-cols-7"
              role="tablist"
              aria-label="Mobil munkanézet választó"
            >
              <WorkAreaTab
                id="cashier"
                active={activeWorkArea === 'cashier'}
                icon={Wallet}
                label="Pénztár"
                alerts={workAreaAlerts.cashier}
                onClick={setActiveWorkArea}
              />
              <WorkAreaTab
                id="field"
                active={activeWorkArea === 'field'}
                icon={Package}
                label="Terep"
                alerts={workAreaAlerts.field}
                onClick={setActiveWorkArea}
              />
              <WorkAreaTab
                id="camera"
                active={activeWorkArea === 'camera'}
                icon={Camera}
                label="Kamera"
                alerts={workAreaAlerts.camera}
                onClick={setActiveWorkArea}
              />
              <WorkAreaTab
                id="vault"
                active={activeWorkArea === 'vault'}
                icon={Wallet}
                label="Értéktár"
                alerts={workAreaAlerts.vault}
                onClick={setActiveWorkArea}
              />
              <WorkAreaTab
                id="approval"
                active={activeWorkArea === 'approval'}
                icon={ShieldAlert}
                label="Jóváhagyás"
                alerts={workAreaAlerts.approval}
                onClick={setActiveWorkArea}
              />
              <WorkAreaTab
                id="customer"
                active={activeWorkArea === 'customer'}
                icon={Users}
                label="Ügyfél"
                alerts={workAreaAlerts.customer}
                onClick={setActiveWorkArea}
              />
              <WorkAreaTab
                id="management"
                active={activeWorkArea === 'management'}
                icon={Server}
                label="Vezetés"
                alerts={workAreaAlerts.management}
                onClick={setActiveWorkArea}
              />
              <WorkAreaTab
                id="integrations"
                active={activeWorkArea === 'integrations'}
                icon={CreditCard}
                label="Eszközök"
                alerts={workAreaAlerts.integrations}
                onClick={setActiveWorkArea}
              />
            </div>

            <div className="mt-3" role="tabpanel">
              {activeWorkArea === 'cashier' && (
                <div className="space-y-3" data-testid="mobile-work-area-cashier">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <StatusLine label="Készlet HUF" value={`${fmt(position?.totalHufValue)} Ft`} />
                    <StatusLine
                      label="Mai változás"
                      value={`${fmt(position?.totalDailyChangeHuf)} Ft`}
                      urgent={(position?.totalDailyChangeHuf ?? 0) < 0}
                    />
                    <StatusLine
                      label="Nyitott tranzakció"
                      value={dashboard?.openTransactions ?? 0}
                    />
                    <StatusLine
                      label="Sync sor"
                      value={syncPendingCount}
                      urgent={syncPendingCount > 0}
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <MobileAction
                      to="/transactions/cashier"
                      icon={ArrowLeftRight}
                      label="Vétel / eladás"
                    />
                    <MobileAction to="/customers/new" icon={Users} label="Új ügyfél" />
                    <MobileAction to="/closing/wizard" icon={FileText} label="Napzárás" />
                  </div>
                  <MobilePanel
                    title="Pénztári készletfigyelő"
                    icon={Wallet}
                    status={panel('position')}
                  >
                    {cashPositionItems.length === 0 ? (
                      <p className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-600">
                        {i18n.t('literals.nincs-valutankenti-keszletadat-a-mobil-n')}
                      </p>
                    ) : (
                      <div className="space-y-2">
                        {cashPositionItems.map((item) => (
                          <CashPositionMobileCard key={item.currencyCode} item={item} />
                        ))}
                      </div>
                    )}
                  </MobilePanel>
                  <div className="space-y-2">
                    {rates.slice(0, 3).map((rate) => (
                      <div
                        key={rate.currencyCode}
                        className="flex items-center justify-between rounded-md border bg-gray-50 px-3 py-2 text-sm"
                      >
                        <span className="font-bold">{rate.currencyCode}</span>
                        <span className="font-mono text-xs">
                          {i18n.t('literals.v-2')}
                          {rate.baseBuyRate.toFixed(2)}
                          {i18n.t('literals.e')}
                          {rate.baseSellRate.toFixed(2)}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {activeWorkArea === 'field' && (
                <div className="space-y-3" data-testid="mobile-work-area-field">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <StatusLine
                      label="Offline irodák"
                      value={offlineBranchCount}
                      urgent={offlineBranchCount > 0}
                    />
                    <StatusLine
                      label="Adatgyűjtés hiba"
                      value={failedDataCollections}
                      urgent={failedDataCollections > 0}
                    />
                    <StatusLine
                      label="Folyamatban"
                      value={pendingDataCollections}
                      urgent={pendingDataCollections > 0}
                    />
                    <StatusLine
                      label="Aktív átadás"
                      value={activeTransferDocumentCount}
                      urgent={activeTransferDocumentCount > 0}
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <MobileAction to="/inventory" icon={Wallet} label="Értéktári készlet" />
                    <MobileAction to="/shipments" icon={ArrowLeftRight} label="Átadás-átvétel" />
                    <MobileAction to="/transfer-documents" icon={FileText} label="Bizonylatok" />
                    <MobileAction to="/transit" icon={Package} label="Úton lévő" />
                    <MobileAction to="/seal-tracking" icon={ShieldAlert} label="Plomba" />
                  </div>
                  <MobilePanel
                    title="Mobil átadási bizonylatok"
                    icon={FileText}
                    status={panel('transferDocuments')}
                  >
                    {transferDocuments.length === 0 ? (
                      <p className="rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
                        {i18n.t('literals.nincs-aktiv-mobil-atadasi-bizonylat')}
                      </p>
                    ) : (
                      <div className="space-y-2">
                        {transferDocuments.map((document) => (
                          <TransferDocumentMobileCard
                            key={document.id}
                            document={document}
                            pin={transferPickupPin}
                            actingId={actingTransferDocumentId}
                            onPinChange={setTransferPickupPin}
                            onAction={updateTransferDocument}
                          />
                        ))}
                      </div>
                    )}
                  </MobilePanel>
                  <div className="space-y-2">
                    {offlineBranches.length === 0 ? (
                      <p className="rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
                        {i18n.t('literals.nincs-offline-iroda-a-mobil-kontrollban')}
                      </p>
                    ) : (
                      offlineBranches.slice(0, 3).map((branch) => (
                        <div
                          key={branch.branchId}
                          className="rounded-md border border-amber-200 bg-amber-50 px-3 py-2"
                        >
                          <div className="break-all text-sm font-semibold text-amber-900">
                            {compactBranchId(branch.branchId)}
                          </div>
                          <div className="text-xs text-amber-800">
                            {i18n.t('literals.utolso-eletjel')}
                            {formatLocalDateTime(branch.lastHeartbeat)}
                          </div>
                        </div>
                      ))
                    )}
                  </div>
                </div>
              )}

              {activeWorkArea === 'camera' && (
                <div className="space-y-3" data-testid="mobile-work-area-camera">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <StatusLine
                      label="Elérhető kamera"
                      value={`${connectedCameraCount}/${cameraStatuses.length}`}
                      urgent={disconnectedCameraCount > 0}
                    />
                    <StatusLine
                      label="Rögzít"
                      value={recordingCameraCount}
                      urgent={recordingCameraCount === 0 && cameraStatuses.length > 0}
                    />
                    <StatusLine
                      label="Feltöltés vár"
                      value={pendingCameraUploads}
                      urgent={pendingCameraUploads > 0}
                    />
                    <StatusLine
                      label="Tárhely"
                      value={formatBytes(cameraStorageStats?.totalUsageBytes)}
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <MobileAction to="/camera/live" icon={Camera} label="Élő kép" />
                    <MobileAction to="/camera/playback" icon={FileText} label="Felvételek" />
                    <MobileAction to="/camera/status" icon={Server} label="Státusz" />
                    <MobileAction to="/camera/export" icon={Upload} label="Export" />
                  </div>
                  <MobilePanel title="Kamera mobil státusz" icon={Camera} status={panel('camera')}>
                    {cameraStatuses.length === 0 ? (
                      <p className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-600">
                        {i18n.t('literals.nincs-betoltott-kamera-statusz-a-mobil-n')}
                      </p>
                    ) : (
                      <div className="space-y-2">
                        {cameraStatuses.slice(0, 4).map((camera) => (
                          <div
                            key={camera.cameraId}
                            className={`rounded-md border px-3 py-2 ${
                              camera.connected === false
                                ? 'border-red-200 bg-red-50'
                                : 'border-gray-200 bg-gray-50'
                            }`}
                          >
                            <div className="flex items-start justify-between gap-2">
                              <div className="min-w-0">
                                <div className="break-words text-sm font-bold text-gray-900">
                                  {camera.cameraName || camera.cameraId}
                                </div>
                                <div className="mt-1 text-xs text-gray-600">
                                  {camera.recording ? 'Rögzítés aktív' : 'Nem rögzít'}
                                </div>
                              </div>
                              <span
                                className={`shrink-0 rounded-full px-2 py-1 text-[11px] font-semibold ${
                                  camera.connected === false
                                    ? 'bg-red-100 text-red-800'
                                    : 'bg-emerald-100 text-emerald-800'
                                }`}
                              >
                                {camera.connected === false ? 'Offline' : 'Online'}
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                    <div className="mt-3 rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-xs text-gray-600">
                      <div>
                        {i18n.t('literals.felvetel')}
                        {cameraStorageStats?.totalRecordings ?? 0}
                      </div>
                      <div>
                        {i18n.t('literals.idoszak-2')}
                        {cameraStorageStats?.oldestDate ?? '-'}
                        {i18n.t('literals.lit-39')} {cameraStorageStats?.newestDate ?? '-'}
                      </div>
                      <div>
                        {i18n.t('literals.szabad-tarhely')}
                        {formatBytes(cameraStorageStats?.availableSpaceBytes)}
                      </div>
                    </div>
                  </MobilePanel>
                </div>
              )}

              {activeWorkArea === 'approval' && (
                <div className="space-y-3" data-testid="mobile-work-area-approval">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <StatusLine
                      label="Sztornó jóváhagyás"
                      value={approvals.length}
                      urgent={approvals.length > 0}
                    />
                    <StatusLine
                      label="Árfolyam jóváhagyás"
                      value={pendingRateApprovals.length}
                      urgent={pendingRateApprovals.length > 0}
                    />
                    <StatusLine
                      label="Hiba 24h"
                      value={errorSummary?.last24h ?? 0}
                      urgent={(errorSummary?.last24h ?? 0) > 0}
                    />
                    <StatusLine label="Audit útvonal" value="Elérhető" />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <MobileAction to="/compliance" icon={ClipboardCheck} label="AML kontroll" />
                    <MobileAction to="/customers" icon={Search} label="Ügyfél törzs" />
                    <MobileAction to="/police-requests" icon={ShieldAlert} label="Megkeresés" />
                    <MobileAction to="/audit-log" icon={FileText} label="Audit napló" />
                  </div>
                  {approvals.slice(0, 2).map((approval) => (
                    <div
                      key={approval.id}
                      className="rounded-md border border-amber-200 bg-amber-50 p-2"
                    >
                      <div className="text-sm font-semibold text-amber-900">
                        {approval.receiptNumber || approval.transactionId}
                      </div>
                      <button
                        type="button"
                        onClick={() => void approve(approval)}
                        disabled={actingApprovalId === approval.id}
                        className="mt-2 inline-flex min-h-10 w-full items-center justify-center gap-2 rounded-md bg-emerald-600 px-3 text-sm font-semibold text-white disabled:opacity-60"
                      >
                        {actingApprovalId === approval.id ? (
                          <Loader2 size={14} className="animate-spin" />
                        ) : (
                          <CheckCircle size={14} />
                        )}
                        {i18n.t('literals.mobil-engedelyezes')}
                      </button>
                    </div>
                  ))}
                  {pendingRateApprovals.slice(0, 2).map((approval) => (
                    <div
                      key={approval.id ?? `${approval.branchId}-${approval.currencyCode}`}
                      className="rounded-md border border-amber-200 bg-amber-50 p-2"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <div className="text-sm font-semibold text-amber-900">
                            {approval.currencyCode ?? 'Árfolyam'}
                          </div>
                          <div className="text-xs text-amber-800">
                            {approval.branchName ?? 'Nincs iroda'}
                            {i18n.t('literals.v-3')} {fmt(Math.round(num(approval.newBuyRate)))}
                            {i18n.t('literals.e-2')} {fmt(Math.round(num(approval.newSellRate)))}
                          </div>
                        </div>
                        <span className="shrink-0 rounded-full bg-amber-100 px-2 py-1 text-[11px] font-semibold text-amber-800">
                          {approval.status ?? 'PENDING'}
                        </span>
                      </div>
                      <div className="mt-2 grid grid-cols-2 gap-2">
                        <button
                          type="button"
                          onClick={() => void approveRateApproval(approval)}
                          disabled={
                            !approval.id || actingRateApprovalId === `${approval.id}:approve`
                          }
                          className="inline-flex min-h-10 items-center justify-center gap-1 rounded-md bg-emerald-600 px-2 text-xs font-semibold text-white disabled:opacity-60"
                        >
                          {actingRateApprovalId === `${approval.id}:approve` && (
                            <Loader2 size={13} className="animate-spin" />
                          )}
                          {i18n.t('literals.arfolyam-engedelyezes')}
                        </button>
                        <button
                          type="button"
                          onClick={() => void rejectRateApproval(approval)}
                          disabled={
                            !approval.id || actingRateApprovalId === `${approval.id}:reject`
                          }
                          className="inline-flex min-h-10 items-center justify-center gap-1 rounded-md border border-red-200 bg-white px-2 text-xs font-semibold text-red-700 disabled:opacity-60"
                        >
                          {actingRateApprovalId === `${approval.id}:reject` && (
                            <Loader2 size={13} className="animate-spin" />
                          )}
                          {i18n.t('literals.arfolyam-elutasitas')}
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {activeWorkArea === 'vault' && (
                <div className="space-y-3" data-testid="mobile-work-area-vault">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <StatusLine
                      label="Begyűjtés"
                      value={openErtektarCollections.length}
                      urgent={openErtektarCollections.length > 0}
                    />
                    <StatusLine
                      label="Szétosztás"
                      value={openErtektarDistributions.length}
                      urgent={openErtektarDistributions.length > 0}
                    />
                    <StatusLine
                      label="Banki tétel"
                      value={openErtektarBankTransactions.length}
                      urgent={openErtektarBankTransactions.length > 0}
                    />
                    <StatusLine
                      label="Összes nyitott"
                      value={openErtektarStatusCount}
                      urgent={openErtektarStatusCount > 0}
                    />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <MobileAction to="/treasury" icon={Wallet} label="Értéktári dashboard" />
                    <MobileAction to="/treasury/movements" icon={ArrowLeftRight} label="Mozgások" />
                    <MobileAction to="/treasury/bank" icon={Building2} label="Banki tételek" />
                    <MobileAction to="/inventory" icon={Package} label="Készlet" />
                  </div>
                  <MobilePanel
                    title="Értéktári mobil státusz"
                    icon={Wallet}
                    status={panel('ertektarStatus')}
                  >
                    {openErtektarStatusCount === 0 ? (
                      <p className="rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
                        {i18n.t('literals.nincs-mobilon-kezelendo-ertektari-status')}
                      </p>
                    ) : (
                      <div className="space-y-2">
                        {openErtektarCollections.map((row) => (
                          <MobileErtektarStatusCard
                            key={`collection-${row.id}`}
                            kind="collection"
                            title="Begyűjtés"
                            id={row.id}
                            status={row.status}
                            primary={
                              row.sourceBranchName ?? row.sourceBranchCode ?? 'Ismeretlen pénztár'
                            }
                            secondary={`${fmt(Math.round(row.amount ?? 0))} ${row.currencyCode ?? ''}`}
                            actingId={actingErtektarStatusId}
                            onUpdate={updateMobileErtektarStatus}
                          />
                        ))}
                        {openErtektarDistributions.map((row) => {
                          const firstLine = row.lines?.[0]
                          return (
                            <MobileErtektarStatusCard
                              key={`distribution-${row.id}`}
                              kind="distribution"
                              title="Szétosztás"
                              id={row.id}
                              status={row.status}
                              primary={
                                firstLine?.targetBranchName ??
                                firstLine?.targetBranchCode ??
                                row.note ??
                                'Cél nélküli tétel'
                              }
                              secondary={
                                firstLine
                                  ? `${fmt(Math.round(firstLine.amount ?? 0))} ${firstLine.currencyCode ?? ''}`
                                  : (row.createdAt ?? '-')
                              }
                              actingId={actingErtektarStatusId}
                              onUpdate={updateMobileErtektarStatus}
                            />
                          )
                        })}
                        {openErtektarBankTransactions.map((row) => (
                          <MobileErtektarStatusCard
                            key={`bank-${row.id}`}
                            kind="bankTransaction"
                            title="Banki tétel"
                            id={row.id}
                            status={row.status}
                            primary={`${row.transactionType} ${row.currencyCode}`}
                            secondary={`${fmt(Math.round(row.amount))} - ${row.bankName ?? 'Nincs bank'}`}
                            actingId={actingErtektarStatusId}
                            onUpdate={updateMobileErtektarStatus}
                          />
                        ))}
                      </div>
                    )}
                  </MobilePanel>
                </div>
              )}

              {activeWorkArea === 'customer' && (
                <div className="space-y-3" data-testid="mobile-work-area-customer">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <StatusLine
                      label="Ügyfélkereső"
                      value={
                        customerResults.length > 0
                          ? `${customerResults.length} találat`
                          : 'Készen áll'
                      }
                    />
                    <StatusLine label="AML útvonal" value="Elérhető" />
                    <StatusLine
                      label="Okmányfotó"
                      value={
                        mobileScannedDocuments.length > 0
                          ? `${mobileScannedDocuments.length} fájl`
                          : 'Készen áll'
                      }
                    />
                    <StatusLine
                      label="Értesítés"
                      value={unreadNotificationCount}
                      urgent={unreadNotificationCount > 0}
                    />
                  </div>
                  <div className="flex gap-2">
                    <input
                      value={customerQuery}
                      onChange={(event) => setCustomerQuery(event.target.value)}
                      onKeyDown={(event) => {
                        if (event.key === 'Enter') void searchCustomers()
                      }}
                      className="form-input min-w-0 flex-1"
                      placeholder="Név vagy okmányszám..."
                    />
                    <button
                      type="button"
                      onClick={() => void searchCustomers()}
                      disabled={customerLoading}
                      className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-md bg-primary-600 text-white disabled:opacity-60"
                      aria-label="Ügyfél keresése"
                    >
                      {customerLoading ? (
                        <Loader2 size={16} className="animate-spin" />
                      ) : (
                        <Search size={16} />
                      )}
                    </button>
                  </div>
                  {customerError && <div className="text-sm text-red-700">{customerError}</div>}
                  <div className="grid grid-cols-2 gap-2">
                    <MobileAction to="/customers/new" icon={Users} label="Új ügyfél" />
                    <MobileAction to="/compliance" icon={ClipboardCheck} label="AML kontroll" />
                    <MobileAction to="/police-requests" icon={ShieldAlert} label="Megkeresés" />
                    <MobileAction to="/audit-log" icon={FileText} label="Audit napló" />
                  </div>
                  <div className="space-y-2">
                    {customerResults.slice(0, 5).map((customer) => (
                      <div key={customer.id} className="rounded-md border bg-gray-50 px-3 py-2">
                        <Link to={`/customers/${customer.id}`} className="block">
                          <div className="text-sm font-semibold text-gray-900">{customer.name}</div>
                          <div className="text-xs text-gray-500">
                            {customer.documentNumber || 'Nincs okmányszám'}
                          </div>
                        </Link>
                        <button
                          type="button"
                          onClick={() => setMobileDocumentCustomerId(String(customer.id))}
                          className="mt-2 inline-flex min-h-9 w-full items-center justify-center rounded-md border border-gray-200 bg-white px-3 text-sm font-semibold text-gray-800"
                        >
                          {i18n.t('literals.okmany-celpont')}
                        </button>
                      </div>
                    ))}
                  </div>
                  <MobilePanel title="Telefonos okmányfeltöltés" icon={Camera} status="ok">
                    <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
                      <input
                        className="form-input"
                        value={mobileDocumentCustomerId}
                        onChange={(event) => setMobileDocumentCustomerId(event.target.value)}
                        placeholder="Ügyfél ID"
                        aria-label="Mobil okmány ügyfél ID"
                      />
                      <select
                        className="form-input"
                        value={mobileDocumentType}
                        onChange={(event) =>
                          setMobileDocumentType(
                            event.target.value as DocumentScannerUploadRequest['documentType'],
                          )
                        }
                        aria-label="Mobil okmány típusa"
                      >
                        <option value="ID_CARD">{i18n.t('literals.szemelyi-igazolvany')}</option>
                        <option value="PASSPORT">{i18n.t('literals.utlevel')}</option>
                        <option value="DRIVERS_LICENSE">{i18n.t('literals.jogositvany')}</option>
                        <option value="OTHER">{i18n.t('literals.egyeb')}</option>
                      </select>
                    </div>
                    <input
                      className="form-input mt-2"
                      value={mobileDocumentNotes}
                      onChange={(event) => setMobileDocumentNotes(event.target.value)}
                      placeholder="Megjegyzés"
                      aria-label="Mobil okmány megjegyzés"
                    />
                    {mobileDocumentError && (
                      <p className="mt-2 rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
                        {mobileDocumentError}
                      </p>
                    )}
                    <div className="mt-2 grid grid-cols-2 gap-2">
                      <button
                        type="button"
                        onClick={() => void loadMobileCustomerDocuments()}
                        className="inline-flex min-h-10 items-center justify-center gap-2 rounded-md border border-gray-200 bg-gray-50 px-3 text-sm font-semibold text-gray-800"
                      >
                        <FileText size={15} />
                        {i18n.t('literals.lista')}
                      </button>
                      <label className="inline-flex min-h-10 cursor-pointer items-center justify-center gap-2 rounded-md bg-primary-600 px-3 text-sm font-semibold text-white">
                        {mobileDocumentUploading ? (
                          <Loader2 size={15} className="animate-spin" />
                        ) : (
                          <Upload size={15} />
                        )}
                        {i18n.t('literals.feltoltes')}
                        <input
                          type="file"
                          accept="image/*,application/pdf"
                          capture="environment"
                          className="hidden"
                          disabled={mobileDocumentUploading}
                          onChange={(event) => void handleMobileDocumentUpload(event)}
                          data-testid="mobile-document-upload-input"
                        />
                      </label>
                    </div>
                    <div className="mt-3 space-y-2">
                      {mobileScannedDocuments.length === 0 ? (
                        <p className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-600">
                          {i18n.t('literals.nincs-betoltott-okmany-ehhez-az-ugyfelhe')}
                        </p>
                      ) : (
                        mobileScannedDocuments.slice(0, 3).map((document) => (
                          <div
                            key={document.id}
                            className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2"
                          >
                            <div className="break-words text-sm font-semibold text-gray-900">
                              {document.fileName}
                            </div>
                            <div className="text-xs text-gray-500">
                              {document.documentType}
                              {i18n.t('literals.lit-17')}
                              {formatLocalDateTime(document.scannedAt)}
                            </div>
                          </div>
                        ))
                      )}
                    </div>
                  </MobilePanel>
                </div>
              )}

              {activeWorkArea === 'management' && (
                <div className="space-y-3" data-testid="mobile-work-area-management">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <StatusLine
                      label="Napi jelentés"
                      value={`${submittedDailyReports}/${dailyReportStatusRows.length}`}
                      urgent={missingDailyReports.length > 0}
                    />
                    <StatusLine
                      label="Hiányzó jelentés"
                      value={missingDailyReports.length}
                      urgent={missingDailyReports.length > 0}
                    />
                    <StatusLine
                      label="Olvasatlan"
                      value={unreadNotificationCount}
                      urgent={unreadNotificationCount > 0}
                    />
                    <StatusLine label="WU USD" value={fmt(Math.round(wuUsdBalance))} />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <MobileAction to="/central-workstation" icon={Server} label="Irányító" />
                    <MobileAction
                      to="/central/closing-control"
                      icon={ClipboardCheck}
                      label="Zárás"
                    />
                    <MobileAction to="/treasury" icon={Wallet} label="Értéktár" />
                    <MobileAction to="/admin/error-monitor" icon={AlertTriangle} label="Hibák" />
                  </div>
                  <MobilePanel
                    title="Irodai sync gyorsműveletek"
                    icon={RefreshCw}
                    status={panel('sync')}
                  >
                    <div className="space-y-3" data-testid="mobile-sync-actions-panel">
                      <div className="grid grid-cols-2 gap-2 text-sm">
                        <StatusLine
                          label="Sync sor"
                          value={syncPendingCount}
                          urgent={syncPendingCount > 0}
                        />
                        <StatusLine
                          label="Sync szükséges"
                          value={syncProbe?.shouldSync ? 'Igen' : 'Nem'}
                          urgent={syncProbe?.shouldSync}
                        />
                      </div>
                      <label className="grid gap-1 text-xs font-semibold text-gray-600">
                        {i18n.t('literals.sync-iroda-id')}
                        <input
                          value={mobileSyncBranchId}
                          onChange={(event) => setMobileSyncBranchId(event.target.value)}
                          className="min-h-10 rounded-md border border-gray-300 px-3 text-sm font-normal text-gray-900"
                        />
                      </label>
                      {mobileSyncMessage && (
                        <div className="rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
                          {mobileSyncMessage}
                        </div>
                      )}
                      <div className="grid grid-cols-2 gap-2">
                        {(
                          [
                            ['rates', 'Árfolyam sync'],
                            ['transactions', 'Tranzakció sync'],
                            ['inventory', 'Készlet sync'],
                            ['full', 'Teljes sync'],
                          ] as const
                        ).map(([kind, label]) => (
                          <button
                            key={kind}
                            type="button"
                            onClick={() => void runMobileBranchSync(kind)}
                            disabled={mobileSyncActionLoading === kind}
                            data-testid={`mobile-sync-${kind}`}
                            className="inline-flex min-h-10 items-center justify-center gap-2 rounded-md border border-gray-200 bg-gray-50 px-2 text-xs font-semibold text-gray-800 disabled:opacity-60"
                          >
                            {mobileSyncActionLoading === kind ? (
                              <Loader2 size={14} className="animate-spin" />
                            ) : (
                              <RefreshCw size={14} />
                            )}
                            {label}
                          </button>
                        ))}
                      </div>
                    </div>
                  </MobilePanel>
                  <div
                    className="rounded-md border border-red-200 bg-red-50 p-3"
                    data-testid="mobile-year-opening-panel"
                  >
                    <div className="mb-2 flex items-center justify-between gap-2">
                      <div className="text-sm font-semibold text-red-900">
                        {i18n.t('literals.evnyitas-admin-workflow')}
                      </div>
                      <span className="rounded bg-white px-2 py-1 text-xs font-semibold text-red-800">
                        {yearOpeningStatus?.status ??
                          (yearOpeningStatus?.canExecute ? 'Futtatható' : 'Kontroll')}
                      </span>
                    </div>
                    <div className="grid grid-cols-[1fr_auto] gap-2">
                      <label className="grid gap-1 text-xs font-semibold text-red-900">
                        {i18n.t('literals.cel-ev')}
                        <input
                          inputMode="numeric"
                          value={yearOpeningTargetYear}
                          onChange={(event) => setYearOpeningTargetYear(event.target.value)}
                          className="min-h-10 rounded-md border border-red-200 px-3 text-sm font-normal text-gray-900"
                        />
                      </label>
                      <button
                        type="button"
                        onClick={() => void executeYearOpening()}
                        disabled={yearOpeningRunning || yearOpeningStatus?.canExecute === false}
                        className="self-end inline-flex min-h-10 items-center justify-center gap-2 rounded-md bg-red-700 px-3 text-sm font-semibold text-white disabled:opacity-60"
                      >
                        {yearOpeningRunning ? (
                          <Loader2 size={15} className="animate-spin" />
                        ) : (
                          <AlertTriangle size={15} />
                        )}
                        {i18n.t('literals.futtatas')}
                      </button>
                    </div>
                  </div>
                  {missingDailyReports.slice(0, 2).map((row) => (
                    <div
                      key={row.branchId ?? row.branchCode ?? row.branchName}
                      className="rounded-md border border-amber-200 bg-amber-50 px-3 py-2"
                    >
                      <div className="text-sm font-semibold text-amber-900">
                        {row.branchCode ||
                          row.branchName ||
                          compactBranchId(String(row.branchId ?? 'Ismeretlen iroda'))}
                      </div>
                      <div className="text-xs text-amber-800">
                        {i18n.t('literals.napi-jelentes-nincs-leadva')}
                      </div>
                    </div>
                  ))}
                  <MobilePanel
                    title="Supervisor mobil felülbírálás"
                    icon={ShieldAlert}
                    status={panel('operationalControl')}
                  >
                    <div className="space-y-3" data-testid="mobile-supervisor-override-panel">
                      {supervisorOverrideMessage && (
                        <div className="rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
                          {supervisorOverrideMessage}
                        </div>
                      )}
                      <div className="grid gap-2">
                        <label
                          className="text-xs font-semibold text-gray-600"
                          htmlFor="mobile-supervisor-password"
                        >
                          {i18n.t('literals.supervisor-jelszo')}
                        </label>
                        <input
                          id="mobile-supervisor-password"
                          type="password"
                          value={supervisorPassword}
                          onChange={(event) => setSupervisorPassword(event.target.value)}
                          className="min-h-10 rounded-md border border-gray-300 px-3 text-sm"
                          autoComplete="current-password"
                        />
                        <button
                          type="button"
                          onClick={() => void authenticateSupervisor()}
                          disabled={supervisorActionLoading === 'auth'}
                          className="inline-flex min-h-10 w-full items-center justify-center gap-2 rounded-md bg-slate-800 px-3 text-sm font-semibold text-white disabled:opacity-60"
                        >
                          {supervisorActionLoading === 'auth' ? (
                            <Loader2 size={15} className="animate-spin" />
                          ) : (
                            <CheckCircle size={15} />
                          )}
                          {i18n.t('literals.supervisor-ellenorzes')}
                        </button>
                      </div>
                      <div className="rounded-md border border-gray-200 bg-gray-50 p-3">
                        <div className="mb-2 text-sm font-semibold text-gray-900">
                          {i18n.t('literals.arfolyam-felulbiralas')}
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                          <label className="col-span-2 grid gap-1 text-xs font-semibold text-gray-600">
                            {i18n.t('literals.iroda-id')}
                            <input
                              value={supervisorBranchId}
                              onChange={(event) => setSupervisorBranchId(event.target.value)}
                              className="min-h-10 rounded-md border border-gray-300 px-3 text-sm font-normal text-gray-900"
                            />
                          </label>
                          <label className="grid gap-1 text-xs font-semibold text-gray-600">
                            {i18n.t('literals.valuta')}
                            <input
                              value={supervisorCurrency}
                              onChange={(event) =>
                                setSupervisorCurrency(event.target.value.toUpperCase())
                              }
                              className="min-h-10 rounded-md border border-gray-300 px-3 text-sm font-normal text-gray-900"
                            />
                          </label>
                          <label className="grid gap-1 text-xs font-semibold text-gray-600">
                            {i18n.t('literals.veteli')}
                            <input
                              inputMode="decimal"
                              value={supervisorBuyRate}
                              onChange={(event) => setSupervisorBuyRate(event.target.value)}
                              className="min-h-10 rounded-md border border-gray-300 px-3 text-sm font-normal text-gray-900"
                            />
                          </label>
                          <label className="grid gap-1 text-xs font-semibold text-gray-600">
                            {i18n.t('literals.eladasi')}
                            <input
                              inputMode="decimal"
                              value={supervisorSellRate}
                              onChange={(event) => setSupervisorSellRate(event.target.value)}
                              className="min-h-10 rounded-md border border-gray-300 px-3 text-sm font-normal text-gray-900"
                            />
                          </label>
                          <label className="col-span-2 grid gap-1 text-xs font-semibold text-gray-600">
                            {i18n.t('literals.indoklas')}
                            <input
                              value={supervisorRateReason}
                              onChange={(event) => setSupervisorRateReason(event.target.value)}
                              className="min-h-10 rounded-md border border-gray-300 px-3 text-sm font-normal text-gray-900"
                            />
                          </label>
                        </div>
                        <button
                          type="button"
                          onClick={() => void overrideSupervisorRate()}
                          disabled={supervisorActionLoading === 'rate'}
                          className="mt-3 inline-flex min-h-10 w-full items-center justify-center gap-2 rounded-md bg-primary-700 px-3 text-sm font-semibold text-white disabled:opacity-60"
                        >
                          {supervisorActionLoading === 'rate' ? (
                            <Loader2 size={15} className="animate-spin" />
                          ) : (
                            <ShieldAlert size={15} />
                          )}
                          {i18n.t('literals.arfolyam-felulbiralas-kuldese')}
                        </button>
                      </div>
                      <div className="rounded-md border border-gray-200 bg-gray-50 p-3">
                        <div className="mb-2 text-sm font-semibold text-gray-900">
                          {i18n.t('literals.kezelesi-dij-felulbiralas')}
                        </div>
                        <div className="grid grid-cols-2 gap-2">
                          <label className="grid gap-1 text-xs font-semibold text-gray-600">
                            {i18n.t('literals.tranzakcio-id')}
                            <input
                              inputMode="numeric"
                              value={supervisorTransactionId}
                              onChange={(event) => setSupervisorTransactionId(event.target.value)}
                              className="min-h-10 rounded-md border border-gray-300 px-3 text-sm font-normal text-gray-900"
                            />
                          </label>
                          <label className="grid gap-1 text-xs font-semibold text-gray-600">
                            {i18n.t('literals.uj-dij')}
                            <input
                              inputMode="decimal"
                              value={supervisorFee}
                              onChange={(event) => setSupervisorFee(event.target.value)}
                              className="min-h-10 rounded-md border border-gray-300 px-3 text-sm font-normal text-gray-900"
                            />
                          </label>
                          <label className="col-span-2 grid gap-1 text-xs font-semibold text-gray-600">
                            {i18n.t('literals.dij-indoklas')}
                            <input
                              value={supervisorFeeReason}
                              onChange={(event) => setSupervisorFeeReason(event.target.value)}
                              className="min-h-10 rounded-md border border-gray-300 px-3 text-sm font-normal text-gray-900"
                            />
                          </label>
                        </div>
                        <button
                          type="button"
                          onClick={() => void overrideSupervisorFee()}
                          disabled={supervisorActionLoading === 'fee'}
                          className="mt-3 inline-flex min-h-10 w-full items-center justify-center gap-2 rounded-md bg-primary-700 px-3 text-sm font-semibold text-white disabled:opacity-60"
                        >
                          {supervisorActionLoading === 'fee' ? (
                            <Loader2 size={15} className="animate-spin" />
                          ) : (
                            <ShieldAlert size={15} />
                          )}
                          {i18n.t('literals.dij-felulbiralas-kuldese')}
                        </button>
                      </div>
                    </div>
                  </MobilePanel>
                  <MobilePanel
                    title="Mobil értesítések"
                    icon={Bell}
                    status={panel('notifications')}
                  >
                    <div className="mb-2 grid grid-cols-2 gap-2 text-sm">
                      <StatusLine
                        label="Olvasatlan"
                        value={unreadNotificationCount}
                        urgent={unreadNotificationCount > 0}
                      />
                      <StatusLine label="Lista" value={notifications.length} />
                    </div>
                    <button
                      type="button"
                      onClick={() => void markAllMobileNotificationsRead()}
                      disabled={notifications.length === 0 || actingNotificationId === 'all'}
                      className="mb-2 inline-flex min-h-10 w-full items-center justify-center gap-2 rounded-md border border-gray-200 bg-gray-50 px-3 text-sm font-semibold text-gray-800 disabled:opacity-60"
                    >
                      {actingNotificationId === 'all' ? (
                        <Loader2 size={15} className="animate-spin" />
                      ) : (
                        <CheckCircle size={15} />
                      )}
                      {i18n.t('literals.mind-olvasott')}
                    </button>
                    <div className="space-y-2">
                      {notifications.length === 0 ? (
                        <p className="rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
                          {i18n.t('literals.nincs-olvasatlan-mobil-ertesites')}
                        </p>
                      ) : (
                        notifications.slice(0, 4).map((notification) => (
                          <div
                            key={notification.id}
                            className="rounded-md border border-amber-200 bg-amber-50 px-3 py-2"
                          >
                            <div className="flex items-start justify-between gap-2">
                              <div className="min-w-0">
                                <div className="break-words text-sm font-semibold text-amber-900">
                                  {notification.title}
                                </div>
                                <div className="mt-1 break-words text-xs text-amber-800">
                                  {notification.message}
                                </div>
                              </div>
                              <span className="shrink-0 rounded-full bg-white px-2 py-1 text-[11px] font-semibold text-amber-800">
                                {notification.type}
                              </span>
                            </div>
                            <button
                              type="button"
                              onClick={() => void markNotificationRead(notification)}
                              disabled={actingNotificationId === notification.id}
                              className="mt-2 inline-flex min-h-9 w-full items-center justify-center gap-2 rounded-md bg-emerald-600 px-3 text-sm font-semibold text-white disabled:opacity-60"
                            >
                              {actingNotificationId === notification.id ? (
                                <Loader2 size={14} className="animate-spin" />
                              ) : (
                                <CheckCircle size={14} />
                              )}
                              {i18n.t('literals.olvasott')}
                            </button>
                          </div>
                        ))
                      )}
                    </div>
                  </MobilePanel>
                </div>
              )}

              {activeWorkArea === 'integrations' && (
                <div className="space-y-3" data-testid="mobile-work-area-integrations">
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <StatusLine
                      label="POS aktív"
                      value={activePosTerminalCount}
                      urgent={unavailablePosTerminalCount > 0}
                    />
                    <StatusLine
                      label="POS elérhető"
                      value={`${connectedPosTerminalCount}/${activePosTerminalCount}`}
                      urgent={unavailablePosTerminalCount > 0}
                    />
                    <StatusLine
                      label="Pénztárgép stale"
                      value={staleCashRegisterDevices.length}
                      urgent={staleCashRegisterDevices.length > 0}
                    />
                    <StatusLine label="NAV nyitott" value={openNavClosingCount} />
                    <StatusLine
                      label="Sorszám-gap"
                      value={cashRegisterGaps.length}
                      urgent={cashRegisterGaps.length > 0}
                    />
                    <StatusLine label="WU árfolyam" value={wuStubRates.length} />
                  </div>
                  <div className="grid grid-cols-2 gap-2">
                    <MobileAction to="/pos-terminal" icon={CreditCard} label="POS terminálok" />
                    <MobileAction to="/nav-integration" icon={Database} label="NAV integráció" />
                    <MobileAction to="/foertektar" icon={Server} label="Pénztárgépek" />
                    <MobileAction to="/western-union" icon={Globe} label="Western Union" />
                  </div>
                  <MobilePanel
                    title="POS mobil runtime"
                    icon={CreditCard}
                    status={panel('integrations')}
                  >
                    {posTerminals.length === 0 ? (
                      <p className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-600">
                        {i18n.t('literals.nincs-konfiguralt-pos-terminal-a-mobil-n')}
                      </p>
                    ) : (
                      <div className="space-y-2">
                        {posTerminals.slice(0, 4).map((terminal) => {
                          const runtime = posRuntimeStatuses[terminal.terminalId]
                          const connected = runtime?.connected === true
                          return (
                            <div
                              key={terminal.id}
                              className={`rounded-md border px-3 py-2 ${connected ? 'border-emerald-200 bg-emerald-50' : 'border-amber-200 bg-amber-50'}`}
                            >
                              <div className="flex items-start justify-between gap-2">
                                <div className="min-w-0">
                                  <div className="break-words text-sm font-bold text-gray-900">
                                    {terminal.terminalName}
                                  </div>
                                  <div className="mt-1 break-all font-mono text-xs text-gray-600">
                                    {terminal.terminalId}
                                  </div>
                                  {runtime?.message && (
                                    <div className="mt-1 break-words text-xs text-gray-600">
                                      {runtime.message}
                                    </div>
                                  )}
                                </div>
                                <span
                                  className={`shrink-0 rounded-full px-2 py-1 text-[11px] font-semibold ${connected ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'}`}
                                >
                                  {connected
                                    ? 'Elérhető'
                                    : runtime
                                      ? 'Nem elérhető'
                                      : 'Nincs státusz'}
                                </span>
                              </div>
                            </div>
                          )
                        })}
                      </div>
                    )}
                  </MobilePanel>

                  <MobilePanel
                    title="Pénztárgép mobil állapot"
                    icon={Server}
                    status={panel('integrations')}
                  >
                    <div className="mb-2 grid grid-cols-2 gap-2 text-sm">
                      <StatusLine label="Eszköz" value={cashRegisterDevices.length} />
                      <StatusLine label="Mai esemény" value={cashRegisterEvents.length} />
                    </div>
                    <div className="space-y-2">
                      {cashRegisterDevices.length === 0 ? (
                        <p className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-600">
                          {i18n.t('literals.nincs-regisztralt-penztargep-eszkoz')}
                        </p>
                      ) : (
                        cashRegisterDevices.slice(0, 4).map((device) => {
                          const age = minutesSince(device.lastSeenAt)
                          const stale = device.isActive !== false && (age == null || age > 10)
                          return (
                            <div
                              key={device.id}
                              className={`rounded-md border px-3 py-2 ${stale ? 'border-amber-200 bg-amber-50' : 'border-gray-200 bg-gray-50'}`}
                            >
                              <div className="flex items-start justify-between gap-2">
                                <div className="min-w-0">
                                  <div className="break-words text-sm font-bold text-gray-900">
                                    {device.name || device.code}
                                  </div>
                                  <div className="mt-1 break-all text-xs text-gray-600">
                                    {device.appMode ?? '-'} {device.appVersion ?? ''}
                                  </div>
                                </div>
                                <span
                                  className={`shrink-0 rounded-full px-2 py-1 text-[11px] font-semibold ${stale ? 'bg-amber-100 text-amber-800' : 'bg-emerald-100 text-emerald-800'}`}
                                >
                                  {age == null
                                    ? 'Nincs heartbeat'
                                    : age < 60
                                      ? `${age} perc`
                                      : `${Math.floor(age / 60)} óra`}
                                </span>
                              </div>
                            </div>
                          )
                        })
                      )}
                    </div>
                    {cashRegisterGaps.length > 0 && (
                      <div className="mt-3 rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800">
                        {cashRegisterGaps.slice(0, 3).map((gap) => (
                          <div key={gap} className="break-words">
                            {gap}
                          </div>
                        ))}
                      </div>
                    )}
                    {cashRegisterEvents.length > 0 && (
                      <div className="mt-3 space-y-2">
                        {cashRegisterEvents.slice(0, 3).map((event, index) => (
                          <div
                            key={event.id ?? `${event.eventType}-${index}`}
                            className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2"
                          >
                            <div className="text-sm font-semibold text-gray-900">
                              {event.eventType ?? 'Esemény'}
                              {i18n.t('literals.lit-17')}
                              {event.status ?? '-'}
                            </div>
                            <div className="text-xs text-gray-500">
                              {formatLocalDateTime(event.occurredAt ?? event.createdAt)}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </MobilePanel>

                  <MobilePanel
                    title="NAV zárás mobil lista"
                    icon={Database}
                    status={panel('integrations')}
                  >
                    {navClosings.length === 0 ? (
                      <p className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-600">
                        {i18n.t('literals.nincs-mai-nav-zaras-talalat')}
                      </p>
                    ) : (
                      <div className="space-y-2">
                        {navClosings.slice(0, 4).map((closing) => (
                          <div
                            key={closing.id}
                            className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2"
                          >
                            <div className="flex items-start justify-between gap-2">
                              <div className="min-w-0">
                                <div className="break-words text-sm font-bold text-gray-900">
                                  {closing.closingDate ?? '-'}
                                </div>
                                <div className="mt-1 text-xs text-gray-600">
                                  {i18n.t('literals.bevetel')}
                                  {fmt(Math.round(num(closing.totalRevenue)))}
                                  {i18n.t('literals.ft')}
                                </div>
                              </div>
                              <span className="shrink-0 rounded-full bg-white px-2 py-1 text-[11px] font-semibold text-gray-700">
                                {closing.status ?? '-'}
                              </span>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </MobilePanel>

                  <MobilePanel
                    title="WU adapter mobil státusz"
                    icon={Globe}
                    status={panel('integrations')}
                  >
                    <div className="space-y-2">
                      {wuStubRates.length === 0 ? (
                        <p className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-600">
                          {i18n.t('literals.nincs-wu-adapter-arfolyam-adat')}
                        </p>
                      ) : (
                        wuStubRates.slice(0, 3).map((rate, index) => (
                          <div
                            key={`${rate.currency ?? rate.targetCurrency ?? 'rate'}-${index}`}
                            className="flex items-center justify-between rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-sm"
                          >
                            <span className="font-semibold">
                              {rate.sourceCurrency ?? 'USD'}
                              {i18n.t('literals.lit-40')}{' '}
                              {rate.targetCurrency ?? rate.currency ?? '-'}
                            </span>
                            <span className="font-mono">{num(rate.rate).toFixed(4)}</span>
                          </div>
                        ))
                      )}
                    </div>
                    <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] gap-2">
                      <input
                        value={wuStubMtcn}
                        onChange={(event) =>
                          setWuStubMtcn(event.target.value.replace(/\D/g, '').slice(0, 10))
                        }
                        inputMode="numeric"
                        className="form-input min-w-0"
                        placeholder="MTCN 10 számjegy"
                        aria-label="WU MTCN státusz"
                      />
                      <button
                        type="button"
                        onClick={() => void searchWuStubStatus()}
                        disabled={wuStubStatusLoading}
                        className="inline-flex min-h-10 items-center justify-center gap-2 rounded-md bg-primary-700 px-3 text-sm font-semibold text-white disabled:opacity-60"
                      >
                        {wuStubStatusLoading ? (
                          <Loader2 size={14} className="animate-spin" />
                        ) : (
                          <Search size={14} />
                        )}
                        {i18n.t('literals.statusz')}
                      </button>
                    </div>
                    {wuStubStatus && (
                      <div className="mt-3 rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-900">
                        <div className="font-semibold">
                          {wuStubStatus.mtcn ?? wuStubMtcn}
                          {i18n.t('literals.lit-17')}
                          {wuStubStatus.status ?? '-'}
                        </div>
                        <div className="mt-1 text-xs">
                          {wuStubStatus.message ??
                            wuStubStatus.destinationCountry ??
                            'Nincs további üzenet'}
                        </div>
                      </div>
                    )}
                  </MobilePanel>
                </div>
              )}
            </div>
          </section>

          <MobileBottomNavigation
            active={activeWorkArea}
            alerts={workAreaAlerts}
            onSelect={setActiveWorkArea}
          />

          <section className="grid grid-cols-2 gap-2 sm:grid-cols-4">
            <QuickAction to="/reports/live-cash-position" icon={Wallet} label="Pénztárállás" />
            <QuickAction to="/stornos/approvals" icon={ClipboardCheck} label="Jóváhagyás" />
            <QuickAction to="/camera/status" icon={Camera} label="Kamera státusz" />
            <QuickAction to="/synchronization" icon={RefreshCw} label="Sync / adatgyűjtés" />
            <QuickAction to="/admin/error-monitor" icon={Server} label="Hiba-monitor" />
          </section>

          <section className="grid gap-3 lg:grid-cols-2">
            <MobileTaskGroup title="Pénztári mobil műveletek" icon={Wallet}>
              <TaskLink
                to="/transactions/cashier"
                icon={ArrowLeftRight}
                title="Valuta vétel / eladás"
                meta="Pénztári tranzakció"
              />
              <TaskLink
                to="/customers/new"
                icon={Users}
                title="Új ügyfél"
                meta="Okmány-duplikáció ellenőrzéssel"
              />
              <TaskLink
                to="/closing/wizard"
                icon={FileText}
                title="Napzárás"
                meta="Zárási varázsló"
              />
            </MobileTaskGroup>

            <MobileTaskGroup title="Értéktári és terepi mobil műveletek" icon={Building2}>
              <TaskLink
                to="/inventory"
                icon={Wallet}
                title="Értéktári készlet"
                meta="Valutánkénti készlet"
              />
              <TaskLink
                to="/shipments"
                icon={ArrowLeftRight}
                title="Átadás-átvétel"
                meta="Csomag és szállítólevél"
              />
              <TaskLink
                to="/transfer-documents"
                icon={FileText}
                title="Átadási bizonylatok"
                meta="Átvétel, leadás, igazolás"
              />
              <TaskLink
                to="/transit"
                icon={Package}
                title="Úton lévő csomagok"
                meta="Terepi státusz"
              />
              <TaskLink
                to="/seal-tracking"
                icon={ShieldAlert}
                title="Plomba nyilvántartás"
                meta="Mai plombaszámok"
              />
            </MobileTaskGroup>

            <MobileTaskGroup title="Compliance mobil műveletek" icon={ShieldAlert}>
              <TaskLink
                to="/compliance"
                icon={ClipboardCheck}
                title="AML ellenőrzés"
                meta="Kézi tranzakcióvizsgálat"
              />
              <TaskLink
                to="/customers"
                icon={Search}
                title="Ügyfélkeresés"
                meta="Ügyfél törzsadat"
              />
              <TaskLink
                to="/police-requests"
                icon={ShieldAlert}
                title="Rendőrségi megkeresés"
                meta="Compliance ügy"
              />
              <TaskLink
                to="/audit-log"
                icon={FileText}
                title="Audit napló"
                meta="Ellenőrzési nyom"
              />
            </MobileTaskGroup>

            <MobileTaskGroup title="Vezetői mobil műveletek" icon={Server}>
              <TaskLink
                to="/central-workstation"
                icon={Server}
                title="Irányítóközpont"
                meta="Központi állapot"
              />
              <TaskLink
                to="/central/closing-control"
                icon={ClipboardCheck}
                title="Zárás beérkezés"
                meta="Napi kontroll"
              />
              <TaskLink to="/company" icon={Building2} title="Cégadatok" meta="Admin részletek" />
              <TaskLink
                to="/admin/branches"
                icon={Building2}
                title="Pénztár törzs"
                meta="Irodai lista"
              />
            </MobileTaskGroup>

            <MobileTaskGroup title="Integrációs mobil státusz" icon={CreditCard}>
              <TaskLink
                to="/pos-terminal"
                icon={CreditCard}
                title="POS terminálok"
                meta="Runtime státusz"
              />
              <TaskLink
                to="/nav-integration"
                icon={Database}
                title="NAV integráció"
                meta="Pénztárgép kapcsolat"
              />
              <TaskLink
                to="/foertektar"
                icon={Server}
                title="Pénztárgépek"
                meta="Heartbeat / eszközlista"
              />
              <TaskLink
                to="/western-union"
                icon={Globe}
                title="Western Union"
                meta="Adapter és napi státusz"
              />
            </MobileTaskGroup>
          </section>

          <section className="grid grid-cols-2 gap-2 md:grid-cols-3 xl:grid-cols-6">
            <MetricCard
              icon={Wallet}
              label="Mai forgalom"
              value={formatMillions(dashboard?.todayVolume ?? 0)}
              unavailable={panelStatus.dashboard === 'unavailable'}
            />
            <MetricCard
              icon={Building2}
              label="Aktív irodák"
              value={onlineBranchCount || dashboard?.activeBranches || 0}
              unavailable={
                panelStatus.branchMonitoring === 'unavailable' &&
                panelStatus.dashboard === 'unavailable'
              }
            />
            <MetricCard
              icon={Server}
              label="Offline iroda"
              value={offlineBranchCount}
              unavailable={panelStatus.branchMonitoring === 'unavailable'}
              urgent={offlineBranchCount > 0}
            />
            <MetricCard
              icon={AlertTriangle}
              label="Figyelendő"
              value={criticalCount}
              urgent={criticalCount > 0}
            />
            <MetricCard
              icon={Server}
              label="Sync sor"
              value={syncPendingCount}
              unavailable={panelStatus.sync === 'unavailable'}
              urgent={syncPendingCount > 0}
            />
            <MetricCard
              icon={Users}
              label="Hibák 24h"
              value={errorSummary?.last24h ?? 0}
              unavailable={panelStatus.diagnostics === 'unavailable'}
              urgent={(errorSummary?.last24h ?? 0) > 0}
            />
          </section>

          <section className="grid gap-3 lg:grid-cols-2">
            <MobilePanel title="Vezetői státusz" icon={Wallet} status={panel('position')}>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <StatusLine label="Készlet HUF" value={`${fmt(position?.totalHufValue)} Ft`} />
                <StatusLine
                  label="Napi változás"
                  value={`${fmt(position?.totalDailyChangeHuf)} Ft`}
                />
                <StatusLine label="Mai tranzakció" value={dashboard?.openTransactions ?? 0} />
                <StatusLine label="Készlet riasztás" value={alertCount} urgent={alertCount > 0} />
              </div>
              <Link
                to="/reports/live-cash-position"
                className="mt-3 inline-flex text-sm font-semibold text-primary-700"
              >
                {i18n.t('literals.pillanatnyi-penztarallas-megnyitasa')}
              </Link>
            </MobilePanel>

            <MobilePanel title="Jóváhagyások" icon={ClipboardCheck} status={panel('approvals')}>
              {approvals.length === 0 ? (
                <p className="text-sm text-gray-500">
                  {i18n.t('literals.nincs-fuggo-sztorno-jovahagyas')}
                </p>
              ) : (
                <div className="space-y-2">
                  {approvals.slice(0, 3).map((approval) => (
                    <div
                      key={approval.id}
                      className="rounded-md border border-amber-200 bg-amber-50 p-2"
                    >
                      <div className="text-sm font-semibold text-amber-900">
                        {approval.receiptNumber || approval.transactionId}
                      </div>
                      <div className="text-xs text-amber-800">
                        {approval.workerName || approval.workerId}
                      </div>
                      <div className="mt-2 flex gap-2">
                        <button
                          type="button"
                          onClick={() => void approve(approval)}
                          disabled={actingApprovalId === approval.id}
                          className="inline-flex min-h-9 flex-1 items-center justify-center gap-1 rounded-md bg-emerald-600 px-3 text-sm font-semibold text-white disabled:opacity-60"
                        >
                          {actingApprovalId === approval.id ? (
                            <Loader2 size={14} className="animate-spin" />
                          ) : (
                            <CheckCircle size={14} />
                          )}
                          {i18n.t('literals.engedelyezes')}
                        </button>
                        <Link
                          to="/stornos/approvals"
                          className="inline-flex min-h-9 flex-1 items-center justify-center rounded-md border border-amber-300 bg-white px-3 text-sm font-semibold text-amber-900"
                        >
                          {i18n.t('literals.reszletek-2')}
                        </Link>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </MobilePanel>

            <MobilePanel
              title="Árfolyam jóváhagyások"
              icon={ShieldAlert}
              status={panel('rateApprovals')}
            >
              <div className="grid grid-cols-2 gap-2 text-sm">
                <StatusLine
                  label="Függő árfolyam"
                  value={pendingRateApprovals.length}
                  urgent={pendingRateApprovals.length > 0}
                />
                <StatusLine label="Előzmények" value={rateApprovalHistory.length} />
              </div>
              <div className="mt-3 space-y-2">
                {pendingRateApprovals.length === 0 ? (
                  <p className="rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
                    {i18n.t('literals.nincs-fuggo-arfolyam-modositas')}
                  </p>
                ) : (
                  pendingRateApprovals.slice(0, 3).map((approval) => (
                    <div
                      key={approval.id ?? `${approval.branchId}-${approval.currencyCode}`}
                      className="rounded-md border border-amber-200 bg-amber-50 px-3 py-2"
                    >
                      <div className="flex items-center justify-between gap-2">
                        <div className="text-sm font-semibold text-amber-900">
                          {approval.currencyCode ?? 'Árfolyam'}
                        </div>
                        <div className="text-xs font-semibold text-amber-800">
                          {approval.status ?? 'PENDING'}
                        </div>
                      </div>
                      <div className="mt-1 text-xs text-amber-800">
                        {approval.branchName ?? 'Nincs iroda'}
                        {i18n.t('literals.v-3')} {fmt(Math.round(num(approval.newBuyRate)))}
                        {i18n.t('literals.e-2')} {fmt(Math.round(num(approval.newSellRate)))}
                      </div>
                      {approval.reason && (
                        <div className="mt-1 break-words text-xs text-amber-800">
                          {approval.reason}
                        </div>
                      )}
                      <div className="mt-2 grid grid-cols-2 gap-2">
                        <button
                          type="button"
                          onClick={() => void approveRateApproval(approval)}
                          disabled={
                            !approval.id || actingRateApprovalId === `${approval.id}:approve`
                          }
                          className="inline-flex min-h-9 items-center justify-center gap-1 rounded-md bg-emerald-600 px-2 text-xs font-semibold text-white disabled:opacity-60"
                        >
                          {actingRateApprovalId === `${approval.id}:approve` && (
                            <Loader2 size={13} className="animate-spin" />
                          )}
                          {i18n.t('literals.arfolyam-engedelyezes')}
                        </button>
                        <button
                          type="button"
                          onClick={() => void rejectRateApproval(approval)}
                          disabled={
                            !approval.id || actingRateApprovalId === `${approval.id}:reject`
                          }
                          className="inline-flex min-h-9 items-center justify-center gap-1 rounded-md border border-red-200 bg-white px-2 text-xs font-semibold text-red-700 disabled:opacity-60"
                        >
                          {actingRateApprovalId === `${approval.id}:reject` && (
                            <Loader2 size={13} className="animate-spin" />
                          )}
                          {i18n.t('literals.arfolyam-elutasitas')}
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>
              {latestRateApproval && (
                <div className="mt-3 rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-xs text-gray-600">
                  {i18n.t('literals.utolso-dontes')}
                  {latestRateApproval.currencyCode ?? '-'}
                  {i18n.t('literals.lit-40')} {latestRateApproval.status ?? '-'}
                  {i18n.t('literals.lit-40')} {formatLocalDateTime(latestRateApproval.requestedAt)}
                </div>
              )}
            </MobilePanel>

            <MobilePanel title="Monitoring" icon={Server} status={panel('diagnostics')}>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <StatusLine
                  label="Utolsó 24 óra hiba"
                  value={errorSummary?.last24h ?? 0}
                  urgent={(errorSummary?.last24h ?? 0) > 0}
                />
                <StatusLine label="Utolsó 7 nap hiba" value={errorSummary?.last7d ?? 0} />
                <StatusLine label="Összes hiba" value={errorSummary?.totalAllTime ?? 0} />
                <StatusLine
                  label="Sync szükséges"
                  value={syncProbe?.shouldSync ? 'Igen' : 'Nem'}
                  urgent={syncProbe?.shouldSync}
                />
              </div>
              <div className="mt-3 flex flex-wrap gap-2">
                <Link
                  to="/synchronization"
                  className="rounded-md border px-3 py-2 text-sm font-semibold text-gray-700"
                >
                  {i18n.t('literals.sync')}
                </Link>
                <Link
                  to="/admin/error-monitor"
                  className="rounded-md border px-3 py-2 text-sm font-semibold text-gray-700"
                >
                  {i18n.t('literals.hiba-monitor')}
                </Link>
              </div>
            </MobilePanel>

            <MobilePanel
              title="Központi adatgyűjtés"
              icon={Database}
              status={panel('dataCollection')}
            >
              <div className="grid grid-cols-2 gap-2 text-sm">
                <StatusLine
                  label="Utolsó státusz"
                  value={latestDataCollection?.status ?? 'Nincs adat'}
                  urgent={latestDataCollection?.status === 'FAILED'}
                />
                <StatusLine label="Irodák" value={dataCollectionRows.length} />
                <StatusLine
                  label="Hibás"
                  value={failedDataCollections}
                  urgent={failedDataCollections > 0}
                />
                <StatusLine
                  label="Folyamatban"
                  value={pendingDataCollections}
                  urgent={pendingDataCollections > 0}
                />
              </div>
              <div className="mt-2 grid grid-cols-2 gap-2 text-sm">
                <StatusLine label="Dátum" value={latestDataCollection?.collectionDate ?? '-'} />
                <StatusLine
                  label="Tranzakció"
                  value={latestDataCollection?.transactionCount ?? 0}
                />
              </div>
              {latestDataCollection?.errorMessage && (
                <p className="mt-3 break-words rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-900">
                  {latestDataCollection.errorMessage}
                </p>
              )}
              <Link
                to="/synchronization"
                className="mt-3 inline-flex text-sm font-semibold text-primary-700"
              >
                {i18n.t('literals.adatgyujtes-kezelese')}
              </Link>
            </MobilePanel>

            <MobilePanel
              title="Irodai online állapot"
              icon={Building2}
              status={panel('branchMonitoring')}
            >
              <div className="grid grid-cols-2 gap-2 text-sm">
                <StatusLine label="Monitorozott iroda" value={monitoredBranchCount} />
                <StatusLine label="Online iroda" value={onlineBranchCount} />
                <StatusLine
                  label="Offline iroda"
                  value={offlineBranchCount}
                  urgent={offlineBranchCount > 0}
                />
                <StatusLine
                  label="Nyitott riasztás"
                  value={branchOpenAlerts}
                  urgent={branchOpenAlerts > 0}
                />
              </div>
              <div className="mt-2 grid grid-cols-2 gap-2 text-sm">
                <StatusLine label="Mai tranzakció" value={branchDailyTransactions} />
                <StatusLine
                  label="Napi volumen"
                  value={`${formatMillions(branchDailyVolume)} Ft`}
                />
              </div>
              <div className="mt-3 space-y-2">
                {offlineBranches.length === 0 ? (
                  <p className="rounded-md border border-emerald-200 bg-emerald-50 px-3 py-2 text-sm text-emerald-800">
                    {i18n.t('literals.minden-monitorozott-iroda-online')}
                  </p>
                ) : (
                  offlineBranches.slice(0, 3).map((branch) => (
                    <div
                      key={branch.branchId}
                      className="rounded-md border border-amber-200 bg-amber-50 px-3 py-2"
                    >
                      <div className="break-all text-sm font-semibold text-amber-900">
                        {compactBranchId(branch.branchId)}
                      </div>
                      <div className="text-xs text-amber-800">
                        {i18n.t('literals.utolso-eletjel')}
                        {formatLocalDateTime(branch.lastHeartbeat)}
                      </div>
                    </div>
                  ))
                )}
              </div>
              <Link
                to="/foertektar"
                className="mt-3 inline-flex text-sm font-semibold text-primary-700"
              >
                {i18n.t('literals.foertektar-dashboard-megnyitasa')}
              </Link>
            </MobilePanel>

            <MobilePanel title="Árfolyam gyorsnézet" icon={ShieldAlert} status={panel('rates')}>
              <div className="space-y-2">
                {rates.map((rate) => (
                  <div
                    key={rate.currencyCode}
                    className="flex items-center justify-between rounded-md border bg-gray-50 px-3 py-2 text-sm"
                  >
                    <div>
                      <div className="font-bold">{rate.currencyCode}</div>
                      <div className="text-xs text-gray-500">{rate.currencyName}</div>
                    </div>
                    <div className="text-right font-mono text-xs">
                      <div>
                        {i18n.t('literals.v-2')}
                        {rate.baseBuyRate.toFixed(2)}
                      </div>
                      <div>
                        {i18n.t('literals.e-3')}
                        {rate.baseSellRate.toFixed(2)}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
              <Link to="/rates" className="mt-3 inline-flex text-sm font-semibold text-primary-700">
                {i18n.t('literals.arfolyamok-megnyitasa')}
              </Link>
            </MobilePanel>

            <MobilePanel title="Üzemi kontroll" icon={Server} status={panel('operationalControl')}>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <StatusLine label="Paraméterek" value={supervisorParams.length} />
                <StatusLine
                  label="Restore adat"
                  value={syncRestoreStatus?.restoreAvailable ? 'Van' : 'Nincs'}
                  urgent={restoreMissing}
                />
                <StatusLine
                  label="Restore tranzakció"
                  value={syncRestoreStatus?.totalTransactions ?? 0}
                />
                <StatusLine
                  label="Évnyitás"
                  value={
                    yearOpeningStatus?.status ??
                    (yearOpeningStatus?.canExecute ? 'Futtatható' : 'Kontroll')
                  }
                  urgent={yearOpeningStatus?.canExecute}
                />
              </div>
              <div className="mt-2 grid grid-cols-2 gap-2 text-sm">
                <StatusLine label="WU USD" value={fmt(Math.round(wuUsdBalance))} />
                <StatusLine label="WU HUF" value={`${fmt(Math.round(wuHufBalance))} Ft`} />
                <StatusLine label="WU küldés" value={wuDailyReport?.sendCount ?? 0} />
                <StatusLine label="WU fogadás" value={wuDailyReport?.receiveCount ?? 0} />
                <StatusLine
                  label="Napi jelentés"
                  value={`${submittedDailyReports}/${dailyReportStatusRows.length}`}
                  urgent={missingDailyReports.length > 0}
                />
                <StatusLine
                  label="Hiányzó jelentés"
                  value={missingDailyReports.length}
                  urgent={missingDailyReports.length > 0}
                />
              </div>
              <div className="mt-3 rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-xs text-gray-600">
                <div>
                  {i18n.t('literals.restore-idoszak')}
                  {syncRestoreStatus?.earliestDate ?? '-'}
                  {i18n.t('literals.lit-39')} {syncRestoreStatus?.latestDate ?? '-'}
                </div>
                <div>
                  {i18n.t('literals.wu-dij-ma')}
                  {fmt(Math.round(num(wuDailyReport?.totalFees)))}
                  {i18n.t('literals.ft')}
                </div>
              </div>
              {missingDailyReports.length > 0 && (
                <div className="mt-3 space-y-2">
                  {missingDailyReports.slice(0, 3).map((row) => (
                    <div
                      key={row.branchId ?? row.branchCode ?? row.branchName}
                      className="rounded-md border border-amber-200 bg-amber-50 px-3 py-2"
                    >
                      <div className="text-sm font-semibold text-amber-900">
                        {row.branchCode ||
                          row.branchName ||
                          compactBranchId(String(row.branchId ?? 'Ismeretlen iroda'))}
                      </div>
                      <div className="text-xs text-amber-800">
                        {row.branchName || 'Nincs irodanév'}
                        {i18n.t('literals.napi-jelentes-nincs-leadva-2')}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </MobilePanel>
          </section>
        </>
      )}
    </div>
  )
}

function MobileUseCaseCard({
  icon: Icon,
  title,
  summary,
  detail,
  urgent,
  active,
  onClick,
}: {
  icon: React.ElementType
  title: string
  summary: string
  detail: string
  urgent?: boolean
  active: boolean
  onClick: () => void
}) {
  const tone = urgent
    ? active
      ? 'border-amber-400 bg-amber-50 text-amber-950'
      : 'border-amber-200 bg-white text-amber-950'
    : active
      ? 'border-primary-400 bg-primary-50 text-primary-950'
      : 'border-gray-200 bg-white text-gray-900'

  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex min-h-[6.25rem] w-full items-start gap-3 rounded-lg border p-3 text-left shadow-sm ${tone}`}
      data-testid={`mobile-use-case-${title.toLowerCase().replaceAll(' ', '-')}`}
    >
      <span
        className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-md ${urgent ? 'bg-amber-100 text-amber-700' : 'bg-primary-50 text-primary-700'}`}
      >
        <Icon size={18} />
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-sm font-bold leading-tight">{title}</span>
        <span className="mt-1 block break-words text-base font-semibold leading-tight">
          {summary}
        </span>
        <span className="mt-1 block break-words text-xs leading-4 text-gray-600">{detail}</span>
      </span>
    </button>
  )
}

function QuickAction({
  to,
  icon: Icon,
  label,
}: {
  to: string
  icon: React.ElementType
  label: string
}) {
  return (
    <Link
      to={to}
      className="flex min-h-16 items-center gap-2 rounded-lg border border-gray-200 bg-white p-3 text-sm font-semibold text-gray-800 shadow-sm"
    >
      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-md bg-primary-50 text-primary-700">
        <Icon size={17} />
      </span>
      <span className="min-w-0 leading-tight">{label}</span>
    </Link>
  )
}

function WorkAreaTab({
  id,
  active,
  icon: Icon,
  label,
  alerts,
  onClick,
}: {
  id: MobileWorkArea
  active: boolean
  icon: React.ElementType
  label: string
  alerts: number
  onClick: (id: MobileWorkArea) => void
}) {
  return (
    <button
      type="button"
      role="tab"
      aria-selected={active}
      onClick={() => onClick(id)}
      className={`flex min-h-14 items-center gap-2 rounded-md border px-3 py-2 text-left text-sm font-semibold transition ${
        active
          ? 'border-primary-500 bg-primary-50 text-primary-800'
          : 'border-gray-200 bg-gray-50 text-gray-700'
      }`}
    >
      <Icon size={17} className="shrink-0" />
      <span className="min-w-0 flex-1 leading-tight">{label}</span>
      {alerts > 0 && (
        <span className="shrink-0 rounded-full bg-amber-100 px-1.5 py-0.5 text-[11px] font-bold text-amber-800">
          {alerts}
        </span>
      )}
    </button>
  )
}

function MobileBottomNavigation({
  active,
  alerts,
  onSelect,
}: {
  active: MobileWorkArea
  alerts: Record<MobileWorkArea, number>
  onSelect: (id: MobileWorkArea) => void
}) {
  const items: Array<{ id: MobileWorkArea; label: string; icon: React.ElementType }> = [
    { id: 'cashier', label: 'Pénztár', icon: Wallet },
    { id: 'field', label: 'Terep', icon: Package },
    { id: 'camera', label: 'Kamera', icon: Camera },
    { id: 'vault', label: 'Értéktár', icon: Wallet },
    { id: 'approval', label: 'Döntés', icon: ShieldAlert },
    { id: 'customer', label: 'Ügyfél', icon: Users },
    { id: 'management', label: 'Vezetés', icon: Server },
    { id: 'integrations', label: 'Eszköz', icon: CreditCard },
  ]

  return (
    <nav
      className="fixed inset-x-0 bottom-0 z-40 border-t border-gray-200 bg-white/95 px-2 pb-[max(env(safe-area-inset-bottom),0.5rem)] pt-2 shadow-[0_-10px_25px_rgba(15,23,42,0.12)] backdrop-blur sm:hidden"
      aria-label="Mobil alsó munkanézet navigáció"
      data-testid="mobile-bottom-nav"
    >
      <div className="mx-auto grid max-w-md grid-cols-4 gap-1">
        {items.map(({ id, label, icon: Icon }) => {
          const isActive = active === id
          const count = alerts[id]
          return (
            <button
              key={id}
              type="button"
              onClick={() => onSelect(id)}
              aria-current={isActive ? 'page' : undefined}
              className={`relative flex min-h-[3.5rem] flex-col items-center justify-center gap-1 rounded-md px-1 text-[11px] font-semibold leading-tight ${
                isActive ? 'bg-primary-50 text-primary-800' : 'text-gray-600'
              }`}
              data-testid={`mobile-bottom-nav-${id}`}
            >
              <Icon size={18} />
              <span className="max-w-full truncate">{label}</span>
              {count > 0 && (
                <span className="absolute right-1 top-1 min-w-4 rounded-full bg-amber-500 px-1 text-[10px] leading-4 text-white">
                  {count > 9 ? '9+' : count}
                </span>
              )}
            </button>
          )
        })}
      </div>
    </nav>
  )
}

function MobileAction({
  to,
  icon: Icon,
  label,
}: {
  to: string
  icon: React.ElementType
  label: string
}) {
  return (
    <Link
      to={to}
      className="flex min-h-12 items-center justify-center gap-2 rounded-md border border-gray-200 bg-gray-50 px-2 py-2 text-center text-sm font-semibold text-gray-800"
    >
      <Icon size={16} className="shrink-0 text-primary-700" />
      <span className="min-w-0 leading-tight">{label}</span>
    </Link>
  )
}

function TransferDocumentMobileCard({
  document,
  pin,
  actingId,
  onPinChange,
  onAction,
}: {
  document: TransferDocument
  pin: string
  actingId: string | null
  onPinChange: (value: string) => void
  onAction: (document: TransferDocument, action: 'pickup' | 'deliver' | 'confirm') => void
}) {
  const status = document.status ?? 'PENDING'
  const amount =
    document.quantity == null
      ? '-'
      : typeof document.quantity === 'number'
        ? document.quantity.toLocaleString('hu-HU')
        : document.quantity

  return (
    <div
      className="rounded-md border border-gray-200 bg-gray-50 p-3"
      data-testid={`mobile-transfer-document-${document.id}`}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0">
          <div className="break-words text-sm font-bold text-gray-900">
            {document.documentNumber ?? document.id}
          </div>
          <div className="mt-1 break-words text-xs text-gray-600">
            {document.sourceType ?? '-'}
            {i18n.t('literals.lit-7')}
            {document.sourceId ?? '-'}
            {i18n.t('literals.lit-39')} {document.destinationType ?? '-'}
            {i18n.t('literals.lit-7')}
            {document.destinationId ?? '-'}
          </div>
        </div>
        <span className="shrink-0 rounded-full bg-white px-2 py-1 text-[11px] font-semibold text-gray-700">
          {status}
        </span>
      </div>
      <div className="mt-2 grid grid-cols-2 gap-2 text-sm">
        <StatusLine label="Összeg" value={`${amount} ${document.currencyCode ?? ''}`} />
        <StatusLine label="Dátum" value={formatLocalDateTime(document.createdAt)} />
      </div>
      {document.notes && (
        <div className="mt-2 break-words rounded-md bg-white px-3 py-2 text-xs text-gray-600">
          {document.notes}
        </div>
      )}
      {status === 'PENDING' && (
        <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto] gap-2">
          <input
            className="form-input min-w-0"
            value={pin}
            onChange={(event) => onPinChange(event.target.value)}
            placeholder="Futár PIN"
            data-testid={`mobile-transfer-pin-${document.id}`}
          />
          <button
            type="button"
            onClick={() => onAction(document, 'pickup')}
            disabled={actingId === `${document.id}:pickup`}
            className="inline-flex min-h-10 items-center justify-center gap-1 rounded-md bg-emerald-600 px-3 text-sm font-semibold text-white disabled:opacity-60"
            data-testid={`mobile-transfer-pickup-${document.id}`}
          >
            {actingId === `${document.id}:pickup` && <Loader2 size={13} className="animate-spin" />}
            {i18n.t('literals.atvetel')}
          </button>
        </div>
      )}
      {status === 'PICKED_UP' && (
        <button
          type="button"
          onClick={() => onAction(document, 'deliver')}
          disabled={actingId === `${document.id}:deliver`}
          className="mt-3 inline-flex min-h-10 w-full items-center justify-center gap-1 rounded-md bg-primary-600 px-3 text-sm font-semibold text-white disabled:opacity-60"
          data-testid={`mobile-transfer-deliver-${document.id}`}
        >
          {actingId === `${document.id}:deliver` && <Loader2 size={13} className="animate-spin" />}
          {i18n.t('literals.leadas')}
        </button>
      )}
      {status === 'DELIVERED' && (
        <button
          type="button"
          onClick={() => onAction(document, 'confirm')}
          disabled={actingId === `${document.id}:confirm`}
          className="mt-3 inline-flex min-h-10 w-full items-center justify-center gap-1 rounded-md bg-emerald-600 px-3 text-sm font-semibold text-white disabled:opacity-60"
          data-testid={`mobile-transfer-confirm-${document.id}`}
        >
          {actingId === `${document.id}:confirm` && <Loader2 size={13} className="animate-spin" />}
          {i18n.t('literals.igazolas')}
        </button>
      )}
    </div>
  )
}

function MobileErtektarStatusCard({
  kind,
  title,
  id,
  status,
  primary,
  secondary,
  actingId,
  onUpdate,
}: {
  kind: MobileErtektarStatusKind
  title: string
  id: number
  status: string
  primary: string
  secondary: string
  actingId: string | null
  onUpdate: (kind: MobileErtektarStatusKind, id: number, status: VaultOperationStatus) => void
}) {
  const targetStatuses: VaultOperationStatus[] = ['IN_PROGRESS', 'COMPLETED', 'REJECTED']

  return (
    <div
      className="rounded-md border border-gray-200 bg-gray-50 p-3"
      data-testid={`mobile-ertektar-status-${kind}-${id}`}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0">
          <div className="break-words text-sm font-bold text-gray-900">
            {title}
            {i18n.t('literals.lit-41')}
            {id}
          </div>
          <div className="mt-1 break-words text-xs text-gray-600">{primary}</div>
          <div className="mt-1 break-words text-xs text-gray-500">{secondary}</div>
        </div>
        <span className="shrink-0 rounded-full bg-white px-2 py-1 text-[11px] font-semibold text-gray-700">
          {status}
        </span>
      </div>
      <div className="mt-3 grid grid-cols-3 gap-2">
        {targetStatuses.map((targetStatus) => {
          const key = `${kind}:${id}:${targetStatus}`
          return (
            <button
              key={targetStatus}
              type="button"
              onClick={() => onUpdate(kind, id, targetStatus)}
              disabled={status === targetStatus || actingId === key}
              className="inline-flex min-h-10 items-center justify-center gap-1 rounded-md border border-gray-200 bg-white px-2 text-[11px] font-semibold text-gray-800 disabled:opacity-50"
              aria-label={`${title} #${id} mobil státusz ${targetStatus}`}
            >
              {actingId === key && <Loader2 size={12} className="animate-spin" />}
              {targetStatus === 'IN_PROGRESS'
                ? 'Folyamat'
                : targetStatus === 'COMPLETED'
                  ? 'Kész'
                  : 'Elutasít'}
            </button>
          )
        })}
      </div>
    </div>
  )
}

function CashPositionMobileCard({ item }: { item: CashPositionItem }) {
  const urgent = item.isLowBalance || item.isHighBalance
  const dailyChange = item.dailyChange ?? 0
  const dailyChangeHuf = item.dailyChangeHuf ?? 0

  return (
    <div
      className={`rounded-md border p-3 ${urgent ? 'border-amber-200 bg-amber-50' : 'border-gray-200 bg-gray-50'}`}
    >
      <div className="flex items-start justify-between gap-2">
        <div className="min-w-0">
          <div className="font-mono text-sm font-bold text-blue-700">{item.currencyCode}</div>
          <div className="mt-0.5 break-words text-xs text-gray-600">{item.currencyName}</div>
        </div>
        {urgent && (
          <span className="shrink-0 rounded-full bg-amber-100 px-2 py-1 text-[11px] font-semibold text-amber-800">
            {item.isLowBalance ? 'Alacsony' : 'Magas'}
          </span>
        )}
      </div>
      <div className="mt-2 grid grid-cols-2 gap-2 text-sm">
        <StatusLine label="Aktuális" value={fmt(Math.round(item.currentBalance))} urgent={urgent} />
        <StatusLine
          label="HUF érték"
          value={`${fmt(Math.round(item.hufValue))} Ft`}
          urgent={urgent}
        />
        <StatusLine
          label="Mai változás"
          value={fmt(Math.round(dailyChange))}
          urgent={dailyChange < 0}
        />
        <StatusLine
          label="Napi HUF"
          value={`${fmt(Math.round(dailyChangeHuf))} Ft`}
          urgent={dailyChangeHuf < 0}
        />
      </div>
      <div className="mt-2 text-xs text-gray-500">
        {i18n.t('literals.utolso-mozgas')}
        {formatLocalDateTime(item.lastTransactionAt)}
      </div>
    </div>
  )
}

function MobileTaskGroup({
  title,
  icon: Icon,
  children,
}: {
  title: string
  icon: React.ElementType
  children: React.ReactNode
}) {
  return (
    <section className="rounded-lg border border-gray-200 bg-white p-3">
      <h2 className="mb-3 flex items-center gap-2 text-sm font-bold text-gray-900">
        <Icon size={16} />
        {title}
      </h2>
      <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">{children}</div>
    </section>
  )
}

function TaskLink({
  to,
  icon: Icon,
  title,
  meta,
}: {
  to: string
  icon: React.ElementType
  title: string
  meta: string
}) {
  return (
    <Link
      to={to}
      className="flex min-h-[4.25rem] items-center gap-3 rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-gray-900 transition hover:border-primary-300 hover:bg-primary-50"
    >
      <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-md bg-white text-primary-700 shadow-sm">
        <Icon size={17} />
      </span>
      <span className="min-w-0">
        <span className="block text-sm font-semibold leading-tight">{title}</span>
        <span className="mt-1 block text-xs leading-tight text-gray-500">{meta}</span>
      </span>
    </Link>
  )
}

function MetricCard({
  icon: Icon,
  label,
  value,
  urgent,
  unavailable,
}: {
  icon: React.ElementType
  label: string
  value: string | number
  urgent?: boolean
  unavailable?: boolean
}) {
  return (
    <div
      className={`rounded-lg border bg-white p-3 ${urgent ? 'border-amber-300' : 'border-gray-200'}`}
    >
      <div className="flex items-center gap-1.5 text-xs text-gray-500">
        <Icon size={14} />
        <span>{label}</span>
      </div>
      <div className={`mt-1 text-lg font-bold ${urgent ? 'text-amber-700' : 'text-gray-900'}`}>
        {unavailable ? '-' : value}
      </div>
    </div>
  )
}

function MobilePanel({
  title,
  icon: Icon,
  status,
  children,
}: {
  title: string
  icon: React.ElementType
  status: PanelStatus
  children: React.ReactNode
}) {
  return (
    <section className="rounded-lg border border-gray-200 bg-white p-3">
      <div className="mb-3 flex items-center justify-between gap-2">
        <h2 className="flex items-center gap-2 text-sm font-bold text-gray-900">
          <Icon size={16} />
          {title}
        </h2>
        {status === 'loading' && <Loader2 size={14} className="animate-spin text-gray-400" />}
        {status === 'unavailable' && (
          <span className="rounded-full bg-gray-100 px-2 py-1 text-[11px] font-semibold text-gray-600">
            {i18n.t('literals.nem-elerheto')}
          </span>
        )}
      </div>
      {status === 'unavailable' ? (
        <p className="text-sm text-gray-500">
          {i18n.t('literals.ehhez-a-panelhez-nincs-jogosultsag-vagy')}
        </p>
      ) : (
        children
      )}
    </section>
  )
}

function StatusLine({
  label,
  value,
  urgent,
}: {
  label: string
  value: string | number
  urgent?: boolean
}) {
  return (
    <div className="rounded-md bg-gray-50 p-2">
      <div className="text-xs text-gray-500">{label}</div>
      <div
        className={`mt-0.5 break-words font-semibold ${urgent ? 'text-amber-700' : 'text-gray-900'}`}
      >
        {value}
      </div>
    </div>
  )
}
