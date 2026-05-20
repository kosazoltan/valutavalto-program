import { Suspense, lazy, useEffect, useState } from 'react'
import { Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom'
import { useAuthStore } from './stores/authStore'
import { Toaster } from './components/ui/toaster'
import ErrorBoundary from './components/ErrorBoundary'
// EBC Hangsegéd Phase 9.5b — VoiceAssistantProvider + Panel mount (env-flag gated)
import { VoiceAssistantProvider, VoiceAssistantPanel } from './modules/voice-assistant'

const VOICE_ASSISTANT_ENABLED = import.meta.env.VITE_VOICE_ASSISTANT_ENABLED === 'true'
import { api, clearPersistedToken, hasPersistedToken, loadPersistedToken } from './services/api/index'
import { HEARTBEAT_INTERVAL_MS } from './config/heartbeat'
import { useAppMode } from './hooks/useAppMode'
import { appModeLabel, isRoleSelectableForAppMode } from './utils/appModeRoles'
import { resolveOfflineRestoreProfile, type OfflineJwtPayload } from './utils/offlineAuthRestore'

// Layouts
import MainLayout from './layouts/MainLayout'
import AuthLayout from './layouts/AuthLayout'

// Pages
import LoginPage from './pages/auth/LoginPage'
import { logger } from './utils/logger';
const ResetPasswordPage = lazy(() => import('./pages/auth/ResetPasswordPage'))

const SetupWizard = lazy(() => import('./pages/setup/SetupWizard'))
const CustomerDisplayPage = lazy(() => import('./pages/customer-display/CustomerDisplayPage'))
const WorkerPage = lazy(() => import('./pages/workers/WorkerPage'))
const TransitPage = lazy(() => import('./pages/transit/TransitPage'))
const NotFoundPage = lazy(() => import('./pages/common/NotFoundPage'))
const DashboardPage = lazy(() => import('./pages/DashboardPage'))
const CentralWorkstationPage = lazy(() => import('./pages/central/CentralWorkstationPage'))
const ClosingControlPage = lazy(() => import('./pages/central/ClosingControlPage'))
const ReceivedDataOverviewPage = lazy(() => import('./pages/central/ReceivedDataOverviewPage'))
const CentralVaultDashboard = lazy(() => import('./pages/foertektar/CentralVaultDashboard'))
const RateMasterWorkflowPage = lazy(() => import('./pages/rate-management/RateMasterWorkflowPage'))
const MnbReportsPage = lazy(() => import('./pages/mnb/MnbReportsPage'))
const CashierKpiPage = lazy(() => import('./pages/statistics/CashierKpiPage'))
const SanctionPage = lazy(() => import('./pages/sanction/SanctionPage'))
const AttendancePage = lazy(() => import('./pages/attendance/AttendancePage'))
const PermissionMatrixPage = lazy(() => import('./pages/settings/PermissionMatrixPage'))
const VaultStocktakeListPage = lazy(() => import('./pages/vaultStocktake/VaultStocktakeListPage'))
const VaultStocktakeDetailPage = lazy(() => import('./pages/vaultStocktake/VaultStocktakeDetailPage'))
const ComplianceDashboardPage = lazy(() => import('./pages/compliance/ComplianceDashboardPage'))
const TransactionPage = lazy(() => import('./pages/transactions/TransactionPage'))
const TransactionListPage = lazy(() => import('./pages/transactions/TransactionListPage'))
const ConversionPage = lazy(() => import('./pages/transactions/ConversionPage'))
const CashierTransactionPage = lazy(() => import('./pages/transactions/CashierTransactionPage'))
const CashierMainMenu = lazy(() => import('./pages/CashierMainMenu'))
const ClosingWizardPage = lazy(() => import('./pages/closing/ClosingWizardPage'))
const TransferPage = lazy(() => import('./pages/transfers/TransferPage'))
// 2026-04-29 v2.3.15 (E-B8 banki workflow skeleton — teljes impl v2.4.0)
const BankOrderPage = lazy(() => import('./pages/bankorders/BankOrderPage'))
const ErrorMonitorPage = lazy(() => import('./pages/admin/ErrorMonitorPage'))
// V234 belso log+audit modul (2026-05-18)
const AuditDiagnosticsPage = lazy(() => import('./pages/admin/AuditDiagnosticsPage'))
const CustomerListPage = lazy(() => import('./pages/customers/CustomerListPage'))
const CustomerDetailPage = lazy(() => import('./pages/customers/CustomerDetailPage'))
const CustomerCreatePage = lazy(() => import('./pages/customers/CustomerCreatePage'))
const RatesPage = lazy(() => import('./pages/rates/RatesPage'))
const RateCreationPage = lazy(() => import('./pages/rates/RateCreationPage'))
const MainRateSheetPage = lazy(() => import('./pages/rates/MainRateSheetPage'))
const CashDeskPage = lazy(() => import('./pages/cashdesk/CashDeskPage'))
const DenominationPage = lazy(() => import('./pages/cashdesk/DenominationPage'))
const DayOpenPage = lazy(() => import('./pages/cashdesk/DayOpenPage'))
const ReportsPage = lazy(() => import('./pages/reports/ReportsPage'))
const SettingsPage = lazy(() => import('./pages/settings/SettingsPage'))
const StornoPage = lazy(() => import('./pages/stornos/StornoPage'))
const RepresentativeListPage = lazy(() => import('./pages/representatives/RepresentativeListPage'))
const RepresentativeCreatePage = lazy(() => import('./pages/representatives/RepresentativeCreatePage'))
const RepresentativeDetailPage = lazy(() => import('./pages/representatives/RepresentativeDetailPage'))
const ShipmentListPage = lazy(() => import('./pages/shipments/ShipmentListPage'))
const ShipmentNewPage = lazy(() => import('./pages/shipments/ShipmentNewPage'))
const WorkerCommissionPage = lazy(() => import('./pages/commissions/WorkerCommissionPage'))
const WorkstationPage = lazy(() => import('./pages/workstations/WorkstationPage'))
const ContributionPage = lazy(() => import('./pages/contributions/ContributionPage'))
const CashDeskBreakPage = lazy(() => import('./pages/cashdesk/CashDeskBreakPage'))
const LoggingPage = lazy(() => import('./pages/logging/LoggingPage'))
const OrganizationPage = lazy(() => import('./pages/organizations/OrganizationPage'))
const OwnCompanyPage = lazy(() => import('./pages/company/OwnCompanyPage'))
const ReceiptPage = lazy(() => import('./pages/receipts/ReceiptPage'))
const HandoverSheetPage = lazy(() => import('./pages/handover/HandoverSheetPage'))
const ExtendedReportsPage = lazy(() => import('./pages/reports/ExtendedReportsPage'))
const HandlingFeeDecadePage = lazy(() => import('./pages/reports/HandlingFeeDecadePage'))
const BankTransactionReportPage = lazy(() => import('./pages/reports/BankTransactionReportPage'))
const CashierTurnoverReportPage = lazy(() => import('./pages/reports/CashierTurnoverReportPage'))
const RecurringCustomerReportPage = lazy(() => import('./pages/reports/RecurringCustomerReportPage'))
const FeePage = lazy(() => import('./pages/fees/FeePage'))
const BlacklistPage = lazy(() => import('./pages/blacklist/BlacklistPage'))
const AnonymousReportPage = lazy(() => import('./pages/reports/AnonymousReportPage'))
const CommissionRatePage = lazy(() => import('./pages/commissions/CommissionRatePage'))
const ArchivingPage = lazy(() => import('./pages/archiving/ArchivingPage'))
const ExchangeRateDisplayPage = lazy(() => import('./pages/display/ExchangeRateDisplayPage'))
const SynchronizationPage = lazy(() => import('./pages/sync/SynchronizationPage'))
const LocalQueuePage = lazy(() => import('./pages/sync/LocalQueuePage'))
const PosTerminalPage = lazy(() => import('./pages/pos/PosTerminalPage'))
const NavIntegrationPage = lazy(() => import('./pages/nav/NavIntegrationPage'))
const DocumentStoragePage = lazy(() => import('./pages/documents/DocumentStoragePage'))
const NotificationPage = lazy(() => import('./pages/notifications/NotificationPage'))
const OrganizationalSystemParameterPage = lazy(() => import('./pages/organizations/OrganizationalSystemParameterPage'))
const BranchGroupPage = lazy(() => import('./pages/branches/BranchGroupPage'))
const AuditLogPage = lazy(() => import('./pages/audit/AuditLogPage'))
const CircularPage = lazy(() => import('./pages/circulars/CircularPage'))
const FeePackagePage = lazy(() => import('./pages/fees/FeePackagePage'))
const HandlingFeeConfigPage = lazy(() => import('./pages/fees/HandlingFeeConfigPage'))
const PepPage = lazy(() => import('./pages/pep/PepPage'))
const RateGroupPage = lazy(() => import('./pages/rates/RateGroupPage'))
const ReservationPage = lazy(() => import('./pages/reservations/ReservationPage'))
const SuspiciousReportPage = lazy(() => import('./pages/suspicious/SuspiciousReportPage'))
const PermissionPage = lazy(() => import('./pages/settings/PermissionPage'))
const RolePage = lazy(() => import('./pages/settings/RolePage'))
const SystemParameterPage = lazy(() => import('./pages/settings/SystemParameterPage'))
const UserPage = lazy(() => import('./pages/settings/UserPage'))

// === Kamera modul ===
import CameraGuard from './components/CameraGuard'
const CameraLivePage = lazy(() => import('./pages/camera/CameraLivePage'))
const CameraPlaybackPage = lazy(() => import('./pages/camera/CameraPlaybackPage'))
const CameraConfigPage = lazy(() => import('./pages/camera/CameraConfigPage'))
const CameraStatusPage = lazy(() => import('./pages/camera/CameraStatusPage'))
const CameraExportPage = lazy(() => import('./pages/camera/CameraExportPage'))
const DariusReportPage = lazy(() => import('./pages/darius/DariusReportPage'))
const DecadeReportPage = lazy(() => import('./pages/decade/DecadeReportPage'))

// === Árfolyam-kezelés modul ===
const RateCreationDashboard = lazy(() => import('./pages/ratemanagement/RateCreationDashboard'))

// === Sprint 7 — Missing pages ===
const CurrencyGroupPage = lazy(() => import('./pages/currencies/CurrencyGroupPage'))
const MonthlyClosingPage = lazy(() => import('./pages/closing/MonthlyClosingPage'))
const BackupPage = lazy(() => import('./pages/backup/BackupPage'))
const ProfitPage = lazy(() => import('./pages/profit/ProfitPage'))
const MnbReportPage = lazy(() => import('./pages/reports/MnbReportPage'))
const InventoryPage = lazy(() => import('./pages/inventory/InventoryPage'))
const CashierStocksPage = lazy(() => import('./pages/inventory/CashierStocksPage'))
const WesternUnionPage = lazy(() => import('./pages/westernunion/WesternUnionPage'))
const CompetitorPage = lazy(() => import('./pages/competitors/CompetitorPage'))
const PoliceRequestPage = lazy(() => import('./pages/police/PoliceRequestPage'))
const SealTrackingPage = lazy(() => import('./pages/seals/SealTrackingPage'))
const PrintTemplatePage = lazy(() => import('./pages/print/PrintTemplatePage'))
const LicensePage = lazy(() => import('./pages/licenses/LicensePage'))
const SchedulerPage = lazy(() => import('./pages/scheduler/SchedulerPage'))
const EmailPage = lazy(() => import('./pages/email/EmailPage'))
const EmployeePage = lazy(() => import('./pages/employees/EmployeePage'))
const LedDisplayPage = lazy(() => import('./pages/led/LedDisplayPage'))
const DataImportPage = lazy(() => import('./pages/import/DataImportPage'))
const StampPage = lazy(() => import('./pages/stamps/StampPage'))
const StockSnapshotPage = lazy(() => import('./pages/stock/StockSnapshotPage'))
const RateCategoryPage = lazy(() => import('./pages/rates/RateCategoryPage'))
const RateHistoryPage = lazy(() => import('./pages/rates/RateHistoryPage'))
const TransferDocumentPage = lazy(() => import('./pages/transfers/TransferDocumentPage'))
const BookingExportPage = lazy(() => import('./pages/export/BookingExportPage'))

// === Treasury (Értéktári) modul ===
const TreasuryLayout = lazy(() => import('./pages/treasury/TreasuryLayout'))
const TreasuryDashboard = lazy(() => import('./pages/treasury/TreasuryDashboard'))
const StockMatrix = lazy(() => import('./pages/treasury/StockMatrix'))
const MovementManager = lazy(() => import('./pages/treasury/MovementManager'))
// const RatePanel = lazy(() => import('./pages/treasury/RatePanel')) // Replaced by RateCreationDashboard in treasury
const ReportsCirculars = lazy(() => import('./pages/treasury/ReportsCirculars'))
const BankTransactions = lazy(() => import('./pages/treasury/BankTransactions'))
const VatRefundPage = lazy(() => import('./pages/treasury/VatRefundPage'))
const TrbExportPage = lazy(() => import('./pages/treasury/TrbExportPage'))
const CustomerTurnoverPage = lazy(() => import('./pages/treasury/CustomerTurnoverPage'))
const BankTurnoverPage = lazy(() => import('./pages/treasury/BankTurnoverPage'))
const DaybookPage = lazy(() => import('./pages/reports/DaybookPage'))
const DailyTurnoverPage = lazy(() => import('./pages/reports/DailyTurnoverPage'))
const EveningClosingPage = lazy(() => import('./pages/closing/EveningClosingPage'))
const DailyChecklistPage = lazy(() => import('./pages/cashdesk/DailyChecklistPage'))

function RouteLoadingFallback() {
  return (
    <div className="flex h-full min-h-[240px] items-center justify-center">
      <p className="text-sm text-gray-500">Oldal betöltése...</p>
    </div>
  )
}

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated)
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }
  
  return <>{children}</>
}

/**
 * SetupGuard — Electron-only first-run detektálás.
 *
 * Ha a telepített app még nem fut le First-Run Setup Wizard-del (nincs .env vagy
 * hiányzik a JWT_SECRET), átirányít a /setup útvonalra. Minden más kontextusban
 * (web, setup már kész, vagy már a /setup-on van) átengedi a children-t.
 */
function SetupGuard({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<'checking' | 'ok'>(
    () => (window.electronAPI?.setupCheck ? 'checking' : 'ok'),
  )
  const location = useLocation()
  const navigate = useNavigate()

  useEffect(() => {
    if (!window.electronAPI?.setupCheck) {
      setStatus('ok')
      return
    }

    let cancelled = false
    const check = async () => {
      try {
        const result = await window.electronAPI!.setupCheck!()
        if (cancelled) return
        if (result.isFirstRun && location.pathname !== '/setup') {
          navigate('/setup', { replace: true })
        }
      } catch (err) {
        logger.error('SetupGuard', 'setupCheck hiba:', err)
      } finally {
        if (!cancelled) setStatus('ok')
      }
    }
    void check()
    return () => { cancelled = true }
  }, [location.pathname, navigate])

  if (status === 'checking') {
    return (
      <div className="flex h-screen items-center justify-center">
        <p className="text-gray-500">Beállítások ellenőrzése...</p>
      </div>
    )
  }

  return <>{children}</>
}

export default function App() {
  const { mode: appMode, isLoading: appModeLoading } = useAppMode()
  const [isRestoring, setIsRestoring] = useState(() => hasPersistedToken() || appModeLoading)
  const defaultProtectedRoute = import.meta.env.VITE_APP_FLAVOR === 'central-workstation'
    ? '/central-workstation'
    : import.meta.env.VITE_APP_FLAVOR === 'rate-maker'
    ? '/rates/main'
    : appMode === 'full'
    ? '/central-workstation'
    : '/dashboard'

  // Desktopon és weben is megpróbáljuk visszatölteni a tárolt JWT-t.
  useEffect(() => {
    if (appModeLoading) {
      setIsRestoring(true)
      return
    }

    const restoreToken = async () => {
      try {
        const token = await loadPersistedToken()
        if (token) {
          const parts = token.split('.')
          if (parts.length === 3 && parts[1]) {
            // Base64URL → Base64 conversion (JWT payload uses URL-safe encoding)
            const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
            const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4);
            const payload = JSON.parse(atob(padded)) as {
              exp?: number
              activeRole?: string
              permissions?: string[]
              roles?: string[]
            } & OfflineJwtPayload
            const now = Math.floor(Date.now() / 1000)
            if (payload.exp && payload.exp > now) {
              // Token érvényes → restore auth state
              try {
                const res = await api.get('/workers/me', {
                  headers: { Authorization: `Bearer ${token}` },
                })
                if (res.data) {
                  // V57: activeRole + permissions restore a JWT payload-ból
                  const restoredRole = payload.activeRole ?? res.data.role
                  if (!isRoleSelectableForAppMode(restoredRole, appMode)) {
                    logger.warn('App', `Token restore elutasítva: ${restoredRole} role nem használható ebben a programban (${appModeLabel(appMode)}).`)
                    await clearPersistedToken()
                    return
                  }
                  useAuthStore.getState().login(
                    res.data, token, 'Bearer',
                    new Date(payload.exp * 1000).toISOString(),
                    payload.activeRole ?? null,
                    payload.permissions ?? [],
                    payload.roles ?? [],
                  )
                }
              } catch (apiErr: unknown) {
                // Network error (offline) → restore from JWT payload if Electron
                const isNetworkError = apiErr instanceof Error && (
                  apiErr.message === 'Network Error' ||
                  apiErr.message.includes('ECONNREFUSED') ||
                  apiErr.message.includes('timeout')
                )
                if (isNetworkError && window.electronAPI) {
                  const offlineProfile = resolveOfflineRestoreProfile(payload, appMode)
                  if (!offlineProfile) {
                    logger.warn('App', `Offline token restore elutasítva: nincs ${appModeLabel(appMode)} módban használható role a tárolt tokenben.`)
                    await clearPersistedToken()
                    return
                  }
                  // Offline fallback: az appMode-hoz illeszkedo aktiv role-t tartjuk meg,
                  // de permissions nelkul. Igy az ertektar/ertekszallito app nem esik ki
                  // automatikusan, mikozben az offline jogosultsag tovabbra is minimalis.
                  useAuthStore.getState().login(
                    offlineProfile.worker, token, 'Bearer',
                    new Date(payload.exp! * 1000).toISOString(),
                    offlineProfile.activeRole,
                    [],
                    offlineProfile.roles,
                  )
                  logger.warn('App', `Offline login restore — ${offlineProfile.activeRole} profil, permissions nelkul.`)
                } else {
                  // Token szerver oldalon érvénytelen
                  await clearPersistedToken()
                }
              }
            } else {
              await clearPersistedToken()
            }
          } else {
            await clearPersistedToken()
          }
        }
      } catch (err) {
        logger.error('App', 'Token restore hiba:', err)
      } finally {
        setIsRestoring(false)
      }
    }
    void restoreToken()
  }, [appMode, appModeLoading])

  // 2026-04-29 v2.3.11 (E-B6.4 renderer heartbeat + window error catcher):
  // 60 másodpercenként rögzítünk egy életjelet a logger-be — fagyás-detection
  // céljából. Ha a renderer event-loop blokkolódik, a heartbeat megáll, és a
  // `electron-log` rotáló fájlban (~/AppData/Roaming/valuta-penztar/logs/main.log)
  // látható lesz, mikor szakadt meg.
  // Ezenkívül listenert teszünk a window.error és window.unhandledrejection
  // eseményekre, hogy a néma JS hibák is bekerüljenek a logba.
  // 2026-04-29 v2.3.20 (Sourcery PR #283 P2 follow-up): heartbeat-intervallum
  // central config-ból (`config/heartbeat.ts`), env-flag override támogatással
  // (`VITE_HEARTBEAT_INTERVAL_MS`). NEM inline konstans, hogy audit-elhető +
  // tesztelhető legyen, és más entrypoint-ok is reuse-olhassák.
  useEffect(() => {
    const heartbeatId = setInterval(() => {
      logger.heartbeat('App', `alive @ ${new Date().toISOString()}`)
    }, HEARTBEAT_INTERVAL_MS)

    const handleError = (event: ErrorEvent) => {
      logger.error('App', '[window.onerror]', {
        message: event.message,
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
        error: event.error?.stack || String(event.error),
      })
    }
    const handleRejection = (event: PromiseRejectionEvent) => {
      logger.error('App', '[unhandledrejection]', {
        reason: event.reason instanceof Error ? event.reason.stack : String(event.reason),
      })
    }
    window.addEventListener('error', handleError)
    window.addEventListener('unhandledrejection', handleRejection)

    return () => {
      clearInterval(heartbeatId)
      window.removeEventListener('error', handleError)
      window.removeEventListener('unhandledrejection', handleRejection)
    }
  }, [])

  // 2026-04-29 v2.3.11 (E-B6.2 Page Visibility API):
  // Amikor az Electron ablak inaktívvá válik (`document.visibilityState === 'hidden'`),
  // jelezzük az Electron main process-nek, hogy állítsa le a sync-engine-t.
  // Visszaaktiváláskor (visible) újraindítjuk. Ezzel a renderer NEM pollozik
  // 30 másodpercenként, ha a felhasználó más alkalmazással dolgozik 5+ percig.
  useEffect(() => {
    const handleVisibilityChange = () => {
      const electronAPI = window.electronAPI
      if (!electronAPI?.syncEnginePause || !electronAPI.syncEngineResume) return // web fallback

      if (document.visibilityState === 'hidden') {
        logger.info('App', '[visibility] hidden — sync-engine pause')
        void electronAPI.syncEnginePause()
      } else if (document.visibilityState === 'visible') {
        logger.info('App', '[visibility] visible — sync-engine resume')
        void electronAPI.syncEngineResume()
      }
    }
    document.addEventListener('visibilitychange', handleVisibilityChange)
    return () => document.removeEventListener('visibilitychange', handleVisibilityChange)
  }, [])

  if (isRestoring) {
    return (
      <div className="flex h-screen items-center justify-center">
        <p className="text-gray-500">Betöltés...</p>
      </div>
    )
  }

  return (
    <ErrorBoundary>
      <VoiceAssistantProvider>
      <Suspense fallback={<RouteLoadingFallback />}>
      <SetupGuard>
        <Routes>
          {/* First-Run Setup Wizard — teljes képernyős, nincs layout. */}
          <Route path="/setup" element={<SetupWizard />} />

          {/* Auth routes */}
          <Route element={<AuthLayout />}>
            <Route path="/login" element={<LoginPage />} />
          </Route>

          {/* Audit P1.8 (2026-05-04): reset-password page (full-screen, sajat layout) */}
          <Route path="/reset-password" element={<ResetPasswordPage />} />

          {/* P2-1: VFD ügyfélkijelző — full-screen, NINCS auth, NINCS layout.
              Egy második Electron BrowserWindow tölti be a /customer-display útvonalon. */}
          <Route path="/customer-display" element={<CustomerDisplayPage />} />

          {/* Day open — full-screen, no MainLayout */}
          <Route path="/cashdesk/day-open" element={<ProtectedRoute><DayOpenPage /></ProtectedRoute>} />

          {/* Protected routes */}
          <Route
            element={
              <ProtectedRoute>
                <MainLayout />
              </ProtectedRoute>
            }
          >
            <Route path="/" element={<Navigate to={defaultProtectedRoute} replace />} />
            <Route path="/central-workstation" element={<CentralWorkstationPage />} />
            <Route path="/central/closing-control" element={<ClosingControlPage />} />
            <Route path="/central/received-data" element={<ReceivedDataOverviewPage />} />
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/foertektar" element={<CentralVaultDashboard />} />
            <Route path="/rate-management/workflow" element={<RateMasterWorkflowPage />} />
            <Route path="/mnb/reports" element={<MnbReportsPage />} />
            <Route path="/statistics/cashier-kpi" element={<CashierKpiPage />} />
            <Route path="/sanction" element={<SanctionPage />} />
            <Route path="/attendance" element={<AttendancePage />} />
            <Route path="/settings/permission-matrix" element={<PermissionMatrixPage />} />
            <Route path="/vault-stocktake" element={<VaultStocktakeListPage />} />
            <Route path="/vault-stocktake/:id" element={<VaultStocktakeDetailPage />} />
            <Route path="/compliance" element={<ComplianceDashboardPage />} />
          
          {/* Cashier (penztaros) routes */}
          <Route path="/cashier" element={<CashierMainMenu />} />
          <Route path="/transactions/cashier" element={<CashierTransactionPage />} />
          <Route path="/closing/wizard" element={<ClosingWizardPage />} />

          {/* Transactions */}
          <Route path="/transactions" element={<TransactionListPage />} />
          <Route path="/transactions/new" element={<TransactionPage />} />
          <Route path="/transactions/conversion" element={<ConversionPage />} />
          <Route path="/transactions/:id" element={<TransactionPage />} />
          <Route path="/transactions/:id/storno" element={<StornoPage />} />
          
          {/* Customers */}
          <Route path="/customers" element={<CustomerListPage />} />
          <Route path="/customers/new" element={<CustomerCreatePage />} />
          <Route path="/customers/:id" element={<CustomerDetailPage />} />
          
          {/* Rates */}
          <Route path="/rates" element={<RatesPage />} />
          <Route path="/rates/main" element={<MainRateSheetPage />} />
          <Route path="/rates/creation" element={<RateCreationPage />} />
          
          {/* Cash desk */}
          <Route path="/cashdesk" element={<CashDeskPage />} />
          <Route path="/cashdesk/denominations" element={<DenominationPage />} />
          <Route path="/cashdesk/breaks" element={<CashDeskBreakPage />} />
          
          {/* Closing */}
          <Route path="/closing/wizard/:wizardId" element={<ClosingWizardPage />} />
          
          {/* Representatives */}
          <Route path="/customers/:customerId/representatives" element={<RepresentativeListPage />} />
          <Route path="/customers/:customerId/representatives/new" element={<RepresentativeCreatePage />} />
          <Route path="/customers/:customerId/representatives/:representativeId" element={<RepresentativeDetailPage />} />
          
          {/* Shipments */}
          <Route path="/shipments" element={<ShipmentListPage />} />
          <Route path="/shipments/new" element={<ShipmentNewPage />} />

          {/* Transfers */}
          <Route path="/transfers" element={<TransferPage />} />
          <Route path="/transfers/:id" element={<TransferPage />} />
          {/* 2026-04-29 v2.3.15 E-B8 banki workflow skeleton */}
          <Route path="/bank-orders" element={<BankOrderPage />} />
          
          {/* Reports */}
          <Route path="/reports" element={<ReportsPage />} />
          <Route path="/reports/extended" element={<ExtendedReportsPage />} />
          <Route path="/reports/handling-fee-decade" element={<HandlingFeeDecadePage />} />
          <Route path="/reports/bank-transactions" element={<BankTransactionReportPage />} />
          <Route path="/reports/cashier-turnover" element={<CashierTurnoverReportPage />} />
          <Route path="/reports/recurring-customers" element={<RecurringCustomerReportPage />} />
          
          {/* Receipts */}
          <Route path="/receipts" element={<ReceiptPage />} />
          
          {/* Handover Sheets */}
          <Route path="/handover-sheets" element={<HandoverSheetPage />} />
          
          {/* Company */}
          <Route path="/company" element={<OwnCompanyPage />} />
          
          {/* Commissions & Contributions */}
          <Route path="/commissions" element={<WorkerCommissionPage />} />
          <Route path="/contributions" element={<ContributionPage />} />
          
          {/* Workstations */}
          <Route path="/workstations" element={<WorkstationPage />} />
          
          {/* Organizations */}
          <Route path="/organizations" element={<OrganizationPage />} />
          
          {/* Logging */}
          <Route path="/logging" element={<LoggingPage />} />
          
          {/* Settings */}
          <Route path="/settings" element={<SettingsPage />} />
          
          {/* Fees */}
          <Route path="/fees" element={<FeePage />} />
          
          {/* Blacklist */}
          <Route path="/blacklist" element={<BlacklistPage />} />
          
          {/* Anonymous Reports */}
          <Route path="/anonymous-reports" element={<AnonymousReportPage />} />
          
          {/* Commission Rates */}
          <Route path="/commission-rates" element={<CommissionRatePage />} />
          
          {/* Archiving */}
          <Route path="/archiving" element={<ArchivingPage />} />
          
          {/* Exchange Rate Display */}
          <Route path="/exchange-rate-display" element={<ExchangeRateDisplayPage />} />
          
          {/* Synchronization */}
          <Route path="/synchronization" element={<SynchronizationPage />} />
          <Route path="/local-queue" element={<LocalQueuePage />} />
          
          {/* POS Terminal */}
          <Route path="/pos-terminal" element={<PosTerminalPage />} />
          
          {/* NAV Integration */}
          <Route path="/nav-integration" element={<NavIntegrationPage />} />
          
          {/* Document Storage */}
          <Route path="/documents" element={<DocumentStoragePage />} />
          
          {/* Notifications */}
          <Route path="/notifications" element={<NotificationPage />} />
          
          {/* Organizational System Parameters */}
          <Route path="/organizational-system-parameters" element={<OrganizationalSystemParameterPage />} />
          
          {/* Branch Groups */}
          <Route path="/branch-groups" element={<BranchGroupPage />} />

          {/* Audit Log */}
          <Route path="/audit-log" element={<AuditLogPage />} />

          {/* Hiba-monitor (admin/manager/supervisor) */}
          <Route path="/admin/error-monitor" element={<ErrorMonitorPage />} />

          {/* V234 Audit-diagnosztika (admin/support/manager) - belso log+audit modul */}
          <Route path="/admin/audit-diagnostics" element={<AuditDiagnosticsPage />} />

          {/* Circulars (Körlevelek) */}
          <Route path="/circulars" element={<CircularPage />} />

          {/* Fee Packages */}
          <Route path="/fee-packages" element={<FeePackagePage />} />
          <Route path="/handling-fee-config" element={<HandlingFeeConfigPage />} />

          {/* PEP (Politically Exposed Persons) */}
          <Route path="/pep" element={<PepPage />} />

          {/* Rate Groups */}
          <Route path="/rates/groups" element={<RateGroupPage />} />

          {/* Reservations (Foglalások) */}
          <Route path="/reservations" element={<ReservationPage />} />

          {/* Suspicious Reports (Gyanús tranzakció jelentések) */}
          <Route path="/suspicious-reports" element={<SuspiciousReportPage />} />

          {/* Settings sub-pages */}
          <Route path="/settings/permissions" element={<PermissionPage />} />
          <Route path="/settings/roles" element={<RolePage />} />
          <Route path="/settings/parameters" element={<SystemParameterPage />} />
          <Route path="/settings/users" element={<UserPage />} />

          {/* === Treasury (Értéktári) Routes === */}
          <Route path="/treasury" element={<TreasuryLayout />}>
            <Route index element={<TreasuryDashboard />} />
            <Route path="matrix" element={<StockMatrix />} />
            <Route path="movements" element={<MovementManager />} />
            <Route path="bank" element={<BankTransactions />} />
            <Route path="rates" element={<RateCreationDashboard />} />
            <Route path="reports" element={<ReportsCirculars />} />
            <Route path="vat" element={<VatRefundPage />} />
            <Route path="trb-export" element={<TrbExportPage />} />
            <Route path="customer-turnover" element={<CustomerTurnoverPage />} />
            <Route path="bank-turnover" element={<BankTurnoverPage />} />
          </Route>

          {/* === Kamera Routes === */}
          <Route path="/camera/live" element={<CameraGuard><CameraLivePage /></CameraGuard>} />
          <Route path="/camera/playback" element={<CameraGuard><CameraPlaybackPage /></CameraGuard>} />
          <Route path="/camera/config" element={<CameraGuard><CameraConfigPage /></CameraGuard>} />
          <Route path="/camera/status" element={<CameraGuard><CameraStatusPage /></CameraGuard>} />
          <Route path="/camera/export" element={<CameraGuard><CameraExportPage /></CameraGuard>} />
          <Route path="/darius" element={<DariusReportPage />} />
          <Route path="/decade" element={<DecadeReportPage />} />
          <Route path="/daybook" element={<DaybookPage />} />
          <Route path="/daily-turnover" element={<DailyTurnoverPage />} />
          <Route path="/evening-closing" element={<EveningClosingPage />} />
          <Route path="/daily-checklist" element={<DailyChecklistPage />} />

          {/* === Árfolyam-kezelés Routes === */}
          <Route path="/rate-management" element={<RateCreationDashboard />} />
          <Route path="/trade" element={<Navigate to="/cashier" replace />} />

          {/* === Sprint 7 Routes === */}
          <Route path="/currency-groups" element={<CurrencyGroupPage />} />
          <Route path="/closing/monthly" element={<MonthlyClosingPage />} />
          <Route path="/backup" element={<BackupPage />} />
          <Route path="/profit" element={<ProfitPage />} />
          <Route path="/reports/mnb" element={<MnbReportPage />} />
          <Route path="/inventory" element={<InventoryPage />} />
          <Route path="/cashier-stocks" element={<CashierStocksPage />} />
          <Route path="/western-union" element={<WesternUnionPage />} />
          <Route path="/competitors" element={<CompetitorPage />} />
          <Route path="/police-requests" element={<PoliceRequestPage />} />
          <Route path="/seal-tracking" element={<SealTrackingPage />} />
          <Route path="/print-templates" element={<PrintTemplatePage />} />
          <Route path="/licenses" element={<LicensePage />} />
          <Route path="/scheduler" element={<SchedulerPage />} />
          <Route path="/email-settings" element={<EmailPage />} />
          <Route path="/employees" element={<EmployeePage />} />
          <Route path="/workers" element={<WorkerPage />} />
          <Route path="/transit" element={<TransitPage />} />
          <Route path="/led-display" element={<LedDisplayPage />} />
          <Route path="/data-import" element={<DataImportPage />} />
          <Route path="/stamps" element={<StampPage />} />
          <Route path="/stock-snapshot" element={<StockSnapshotPage />} />
          <Route path="/stock-snapshots" element={<StockSnapshotPage />} />
          <Route path="/rates/categories" element={<RateCategoryPage />} />
          <Route path="/rates/history" element={<RateHistoryPage />} />
          <Route path="/transfer-documents" element={<TransferDocumentPage />} />
          <Route path="/booking-export" element={<BookingExportPage />} />

          {/* PR #116: /conversion alias -> /transactions/conversion (user typed the short URL) */}
          <Route path="/conversion" element={<Navigate to="/transactions/conversion" replace />} />

          {/* PR #116: 404 NotFound - silent failure kikuszobolese */}
          <Route path="*" element={<NotFoundPage />} />
          </Route>
        </Routes>
      </SetupGuard>
      </Suspense>
      <Toaster />
      {VOICE_ASSISTANT_ENABLED && <VoiceAssistantPanel />}
      </VoiceAssistantProvider>
    </ErrorBoundary>
  )
}
