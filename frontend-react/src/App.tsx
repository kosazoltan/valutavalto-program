import { Suspense, lazy, useEffect, useState } from 'react'
import { Routes, Route, Navigate, useLocation, useNavigate } from 'react-router-dom'
import { useAuthStore } from './stores/authStore'
import RoleGate from './components/RoleGate'
import { menuGroups, getDefaultRouteForRoles } from './layouts/menuGroups'
import { effectiveCanonicalRolesForPath } from './layouts/menuVisibility'
import { Toaster } from './components/ui/toaster'
import ErrorBoundary from './components/ErrorBoundary'
// EBC Hangsegéd Phase 9.5b — VoiceAssistantProvider + Panel mount (env-flag gated)
import { VoiceAssistantProvider, VoiceAssistantPanel } from './modules/voice-assistant'

const VOICE_ASSISTANT_ENABLED = import.meta.env.VITE_VOICE_ASSISTANT_ENABLED === 'true'
import {
  api,
  clearPersistedToken,
  hasPersistedToken,
  loadPersistedToken,
} from './services/api/index'
import { HEARTBEAT_INTERVAL_MS } from './config/heartbeat'
import { useAppMode } from './hooks/useAppMode'
import { appModeLabel, isRoleSelectableForAppMode } from './utils/appModeRoles'
import { resolveOfflineRestoreProfile, type OfflineJwtPayload } from './utils/offlineAuthRestore'

// Layouts
import MainLayout from './layouts/MainLayout'
import AuthLayout from './layouts/AuthLayout'

// Pages
import LoginPage from './pages/auth/LoginPage'
import { logger } from './utils/logger'
const ResetPasswordPage = lazy(() => import('./pages/auth/ResetPasswordPage'))

const SetupWizard = lazy(() => import('./pages/setup/SetupWizard'))
const CustomerDisplayPage = lazy(() => import('./pages/customer-display/CustomerDisplayPage'))
const WorkerPage = lazy(() => import('./pages/workers/WorkerPage'))
const WorkersDatabasePage = lazy(() => import('./pages/workers/WorkersDatabasePage'))
const TransitPage = lazy(() => import('./pages/transit/TransitPage'))
const NotFoundPage = lazy(() => import('./pages/common/NotFoundPage'))
const DashboardPage = lazy(() => import('./pages/DashboardPage'))
const MobileOverviewPage = lazy(() => import('./pages/mobile/MobileOverviewPage'))
const CentralWorkstationPage = lazy(() => import('./pages/central/CentralWorkstationPage'))
const ClosingControlPage = lazy(() => import('./pages/central/ClosingControlPage'))
const ReceivedDataOverviewPage = lazy(() => import('./pages/central/ReceivedDataOverviewPage'))
const CentralVaultDashboard = lazy(() => import('./pages/foertektar/CentralVaultDashboard'))
const MnbSettlementRatePage = lazy(() => import('./pages/foertektar/MnbSettlementRatePage'))
const RateMasterWorkflowPage = lazy(() => import('./pages/rate-management/RateMasterWorkflowPage'))
const MnbReportsPage = lazy(() => import('./pages/mnb/MnbReportsPage'))
const CashierKpiPage = lazy(() => import('./pages/statistics/CashierKpiPage'))
const SanctionPage = lazy(() => import('./pages/sanction/SanctionPage'))
const AttendancePage = lazy(() => import('./pages/attendance/AttendancePage'))
const PermissionMatrixPage = lazy(() => import('./pages/settings/PermissionMatrixPage'))
const VaultStocktakeListPage = lazy(() => import('./pages/vaultStocktake/VaultStocktakeListPage'))
const VaultStocktakeDetailPage = lazy(
  () => import('./pages/vaultStocktake/VaultStocktakeDetailPage'),
)
const ComplianceDashboardPage = lazy(() => import('./pages/compliance/ComplianceDashboardPage'))
const DocumentShortagePage = lazy(() => import('./pages/compliance/DocumentShortagePage'))
const ComplianceQuestionsPage = lazy(() => import('./pages/compliance/ComplianceQuestionsPage'))
const ComplianceTransactionsPage = lazy(() => import('./pages/compliance/ComplianceTransactionsPage'))
const TransactionPage = lazy(() => import('./pages/transactions/TransactionPage'))
const TransactionListPage = lazy(() => import('./pages/transactions/TransactionListPage'))
const ConversionPage = lazy(() => import('./pages/transactions/ConversionPage'))
const CashierTransactionPage = lazy(() => import('./pages/transactions/CashierTransactionPage'))
const CashierMainMenu = lazy(() => import('./pages/CashierMainMenu'))
const ClosingWizardPage = lazy(() => import('./pages/closing/ClosingWizardPage'))
const TransferPage = lazy(() => import('./pages/transfers/TransferPage'))
const TransferCreatePage = lazy(() => import('./pages/transfers/TransferCreatePage'))
const TradePage = lazy(() => import('./pages/trades/TradePage'))
// E-B8 banki workflow — működő backend-integrált oldal.
const BankOrderPage = lazy(() => import('./pages/bankorders/BankOrderPage'))
const ErrorMonitorPage = lazy(() => import('./pages/admin/ErrorMonitorPage'))
// V234 belso log+audit modul (2026-05-18)
const AuditDiagnosticsPage = lazy(() => import('./pages/admin/AuditDiagnosticsPage'))
const CustomerListPage = lazy(() => import('./pages/customers/CustomerListPage'))
const CustomerDetailPage = lazy(() => import('./pages/customers/CustomerDetailPage'))
const CustomerCreatePage = lazy(() => import('./pages/customers/CustomerCreatePage'))
const RatesPage = lazy(() => import('./pages/rates/RatesPage'))
const CompetitorRateEntryPage = lazy(() => import('./pages/competitors/CompetitorRateEntryPage'))
const RateCreationPage = lazy(() => import('./pages/rates/RateCreationPage'))
const MainRateSheetPage = lazy(() => import('./pages/rates/MainRateSheetPage'))
const CashDeskPage = lazy(() => import('./pages/cashdesk/CashDeskPage'))
const DenominationPage = lazy(() => import('./pages/cashdesk/DenominationPage'))
const DenominationImagesPage = lazy(() => import('./pages/cashier/DenominationImagesPage'))
const DayOpenPage = lazy(() => import('./pages/cashdesk/DayOpenPage'))
const ReportsPage = lazy(() => import('./pages/reports/ReportsPage'))
const SettingsPage = lazy(() => import('./pages/settings/SettingsPage'))
const PenztarSettingsPage = lazy(() => import('./pages/settings/PenztarSettingsPage'))
const StornoPage = lazy(() => import('./pages/stornos/StornoPage'))
const StornoApprovalListPage = lazy(() => import('./pages/stornos/StornoApprovalListPage'))
const RepresentativeListPage = lazy(() => import('./pages/representatives/RepresentativeListPage'))
const RepresentativeCreatePage = lazy(
  () => import('./pages/representatives/RepresentativeCreatePage'),
)
const RepresentativeDetailPage = lazy(
  () => import('./pages/representatives/RepresentativeDetailPage'),
)
const ShipmentListPage = lazy(() => import('./pages/shipments/ShipmentListPage'))
const ShipmentNewPage = lazy(() => import('./pages/shipments/ShipmentNewPage'))
const PackagingPage = lazy(() => import('./pages/packaging/PackagingPage'))
const NewCashierBranchPage = lazy(() => import('./pages/branches/NewCashierBranchPage'))
const NewVaultWorkerPage = lazy(() => import('./pages/vault-workers/NewVaultWorkerPage'))
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
const PosHandlingFeePage = lazy(() => import('./pages/reports/PosHandlingFeePage'))
const BankTransactionReportPage = lazy(() => import('./pages/reports/BankTransactionReportPage'))
const CashierTurnoverReportPage = lazy(() => import('./pages/reports/CashierTurnoverReportPage'))
const RecurringCustomerReportPage = lazy(
  () => import('./pages/reports/RecurringCustomerReportPage'),
)
const AverageRateReportPage = lazy(() => import('./pages/reports/AverageRateReportPage'))
const DailyJournalPage = lazy(() => import('./pages/reports/DailyJournalPage'))
const CentralReportsPage = lazy(() => import('./pages/reports/CentralReportsPage'))
const NavReportPage = lazy(() => import('./pages/reports/NavReportPage'))
const LiveCashPositionPage = lazy(() => import('./pages/reports/LiveCashPositionPage'))
const MonthlyTabloPage = lazy(() => import('./pages/reports/MonthlyTabloPage'))
const RegionTurnoverReportPage = lazy(() => import('./pages/reports/RegionTurnoverReportPage'))
const TerritoryReconciliationPage = lazy(
  () => import('./pages/reports/TerritoryReconciliationPage'),
)
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
// EXCMD b6b FR-EFM-01 + b5 FR-KC-05: konszolidált választó-menük (Egyéb feladatok, Címletezés-zárások).
const OtherTasksPage = lazy(() => import('./pages/othertasks/OtherTasksPage'))
const ClosingDenominationMenuPage = lazy(
  () => import('./pages/closing/ClosingDenominationMenuPage'),
)
const DocumentStoragePage = lazy(() => import('./pages/documents/DocumentStoragePage'))
const NotificationPage = lazy(() => import('./pages/notifications/NotificationPage'))
const OrganizationalSystemParameterPage = lazy(
  () => import('./pages/organizations/OrganizationalSystemParameterPage'),
)
const BranchGroupPage = lazy(() => import('./pages/branches/BranchGroupPage'))
// FK-020: Pénztár Törzs Adatbázis lista (Adminisztráció menücsoport).
const BranchPage = lazy(() => import('./pages/branches/BranchPage'))
// FK-021: Új iroda felrögzítése (teljes törzsadat-form, 5 csoport).
const BranchCreatePage = lazy(() => import('./pages/branches/BranchCreatePage'))
const BranchEditPage = lazy(() => import('./pages/branches/BranchEditPage'))
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
// FKH-030: Pénzforgalom riport (Transfer + Shipment, dátumtartományra, körzet-szűrten).
const CashFlowReportPage = lazy(() => import('./pages/reports/CashFlowReportPage'))
const DailyTurnoverPage = lazy(() => import('./pages/reports/DailyTurnoverPage'))
const EveningClosingPage = lazy(() => import('./pages/closing/EveningClosingPage'))
const DailyChecklistPage = lazy(() => import('./pages/cashdesk/DailyChecklistPage'))
const DailyCheckPage = lazy(() => import('./pages/foertektar/DailyCheckPage'))

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
 * RateWatcherGuard — FK-041/II route-szintű izoláció az „árfolyam néző"-nek.
 *
 * Követelmény: az árfolyam néző CSAK versenytárs-árfolyamot vihet be, belső árfolyamot /
 * pénztárnevet / készletet NEM láthat. A menü-rejtés és a backend 403 mellé ez a defense-in-depth
 * réteg gondoskodik arról, hogy URL-beírással se töltse be a belső oldalak shell-jét, és belépés
 * után ne egy üres irányítóközpontra, hanem a saját beíró oldalára landoljon.
 *
 * A „kizárólag néző" feltétel a multirole-helyes EGYETLEN forrásigazságból jön
 * (`getDefaultRouteForRoles`): csak akkor zár, ha a user kanonikus default route-ja a
 * `/competitor-rates` — azaz nincs magasabb prioritású operatív szerepe.
 *
 * appMode-tudatosság (FK-041/II hardening): a default route-ot KIZÁRÓLAG az AKTUÁLIS appMode-ban
 * használható szerepekből számítjuk. Enélkül egy `penztar`+`arfolyam_nezo` user full (Szerver) módban
 * — ahol a `penztar` NEM választható (isRoleSelectableForAppMode('penztar','full')===false), de a
 * backend a teljes, szűretlen role-listát adja vissza — a penztar precedenciája miatt `/cashier`-re
 * oldódna, és kikerülné a néző-izolációt (eléri pl. a /central-workstation, /foertektar shellt). A
 * szűréssel full módban a penztar/ertektar kiesik → marad az arfolyam_nezo → a guard zár.
 * Egy penztáros+néző PENZTÁR módban viszont a penztar marad érvényes → /cashier → NEM zár (helyes).
 */
function RateWatcherGuard({ children }: { children: React.ReactNode }) {
  const location = useLocation()
  const { mode: appMode } = useAppMode()
  const roles = useAuthStore((state) => state.roles)
  const activeRole = useAuthStore((state) => state.activeRole)

  const effectiveRoles = roles.filter((r) => isRoleSelectableForAppMode(r, appMode))
  const effectiveActiveRole =
    activeRole && isRoleSelectableForAppMode(activeRole, appMode) ? activeRole : null

  const belongsToWatcherOnly =
    getDefaultRouteForRoles(effectiveRoles, effectiveActiveRole) === '/competitor-rates'
  if (belongsToWatcherOnly && location.pathname !== '/competitor-rates') {
    return <Navigate to="/competitor-rates" replace />
  }

  return <>{children}</>
}

/**
 * MenuRoleGate — RBAC-audit (2026-06-05): szerepkör-szintű route-védelem, ahol a megengedett
 * szerepkörök a MENÜBŐL származnak (single source of truth, `effectiveCanonicalRolesForPath`).
 * Így a route-hozzáférés definíció szerint egyezik a (full-módú) menü-láthatósággal.
 * A RoleGate SZIGORÚAN (oversight-bypass nélkül) érvényesít minden módban.
 *
 * Fail-safe: ha az útvonal nincs a menüben (nincs definiált megszorítás), nem szűkítünk.
 * A `menuVisibility.test.ts` ("minden MenuRoleGate-tel védett admin-route-nak van nem-üres
 * menü-szerepköre") garantálja, hogy az itt gatelt path-ok mind feloldódnak szerepkörre.
 */
function MenuRoleGate({ path, children }: { path: string; children: React.ReactNode }) {
  const roles = effectiveCanonicalRolesForPath(menuGroups, path)
  if (!roles) {
    // Nincs menü-szerepkör (nem listázott vagy korlátlan) → nem szűkítünk route-szinten.
    return <>{children}</>
  }
  return <RoleGate canonicalRoles={roles}>{children}</RoleGate>
}

/**
 * SetupGuard — Electron-only first-run detektálás.
 *
 * Ha a telepített app még nem fut le First-Run Setup Wizard-del (nincs .env vagy
 * hiányzik a JWT_SECRET), átirányít a /setup útvonalra. Minden más kontextusban
 * (web, setup már kész, vagy már a /setup-on van) átengedi a children-t.
 */
function SetupGuard({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<'checking' | 'ok'>(() =>
    window.electronAPI?.setupCheck ? 'checking' : 'ok',
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
    return () => {
      cancelled = true
    }
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
  const defaultProtectedRoute =
    import.meta.env.VITE_APP_FLAVOR === 'central-workstation'
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
            const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/')
            const padded = base64 + '='.repeat((4 - (base64.length % 4)) % 4)
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
                    logger.warn(
                      'App',
                      `Token restore elutasítva: ${restoredRole} role nem használható ebben a programban (${appModeLabel(appMode)}).`,
                    )
                    await clearPersistedToken()
                    return
                  }
                  useAuthStore
                    .getState()
                    .login(
                      res.data,
                      token,
                      'Bearer',
                      new Date(payload.exp * 1000).toISOString(),
                      payload.activeRole ?? null,
                      payload.permissions ?? [],
                      payload.roles ?? [],
                    )
                }
              } catch (apiErr: unknown) {
                // Network error (offline) → restore from JWT payload if Electron
                const isNetworkError =
                  apiErr instanceof Error &&
                  (apiErr.message === 'Network Error' ||
                    apiErr.message.includes('ECONNREFUSED') ||
                    apiErr.message.includes('timeout'))
                if (isNetworkError && window.electronAPI) {
                  const offlineProfile = resolveOfflineRestoreProfile(payload, appMode)
                  if (!offlineProfile) {
                    logger.warn(
                      'App',
                      `Offline token restore elutasítva: nincs ${appModeLabel(appMode)} módban használható role a tárolt tokenben.`,
                    )
                    await clearPersistedToken()
                    return
                  }
                  // Offline fallback: az appMode-hoz illeszkedo aktiv role-t tartjuk meg,
                  // de permissions nelkul. Igy az ertektar app nem esik ki
                  // automatikusan, mikozben az offline jogosultsag tovabbra is minimalis.
                  useAuthStore
                    .getState()
                    .login(
                      offlineProfile.worker,
                      token,
                      'Bearer',
                      new Date(payload.exp! * 1000).toISOString(),
                      offlineProfile.activeRole,
                      [],
                      offlineProfile.roles,
                    )
                  logger.warn(
                    'App',
                    `Offline login restore — ${offlineProfile.activeRole} profil, permissions nelkul.`,
                  )
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
              <Route
                path="/cashdesk/day-open"
                element={
                  <ProtectedRoute>
                    <DayOpenPage />
                  </ProtectedRoute>
                }
              />

              {/* Protected routes */}
              <Route
                element={
                  <ProtectedRoute>
                    <RateWatcherGuard>
                      <MainLayout />
                    </RateWatcherGuard>
                  </ProtectedRoute>
                }
              >
                <Route path="/" element={<Navigate to={defaultProtectedRoute} replace />} />
                <Route path="/central-workstation" element={<CentralWorkstationPage />} />
                <Route path="/central/closing-control" element={<ClosingControlPage />} />
                <Route path="/central/received-data" element={<ReceivedDataOverviewPage />} />
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route
                  path="/mobile"
                  element={
                    <MenuRoleGate path="/mobile">
                      <MobileOverviewPage />
                    </MenuRoleGate>
                  }
                />
                <Route path="/foertektar" element={<CentralVaultDashboard />} />
                <Route
                  path="/mnb-settlement-rates"
                  element={
                    <MenuRoleGate path="/mnb-settlement-rates">
                      <MnbSettlementRatePage />
                    </MenuRoleGate>
                  }
                />
                <Route path="/rate-management/workflow" element={<RateMasterWorkflowPage />} />
                <Route path="/mnb/reports" element={<MnbReportsPage />} />
                <Route path="/statistics/cashier-kpi" element={<CashierKpiPage />} />
                <Route
                  path="/sanction"
                  element={
                    <MenuRoleGate path="/sanction">
                      <SanctionPage />
                    </MenuRoleGate>
                  }
                />
                <Route
                  path="/attendance"
                  element={
                    <MenuRoleGate path="/attendance">
                      <AttendancePage />
                    </MenuRoleGate>
                  }
                />
                <Route
                  path="/settings/permission-matrix"
                  element={
                    <MenuRoleGate path="/settings/permission-matrix">
                      <PermissionMatrixPage />
                    </MenuRoleGate>
                  }
                />
                <Route path="/vault-stocktake" element={<VaultStocktakeListPage />} />
                <Route path="/vault-stocktake/:id" element={<VaultStocktakeDetailPage />} />
                <Route
                  path="/compliance"
                  element={
                    <MenuRoleGate path="/compliance">
                      <ComplianceDashboardPage />
                    </MenuRoleGate>
                  }
                />
                <Route path="/compliance/document-shortages" element={<DocumentShortagePage />} />
                <Route
                  path="/compliance/questions"
                  element={
                    <MenuRoleGate path="/compliance/questions">
                      <ComplianceQuestionsPage />
                    </MenuRoleGate>
                  }
                />
                <Route
                  path="/compliance/transactions"
                  element={
                    <MenuRoleGate path="/compliance/transactions">
                      <ComplianceTransactionsPage />
                    </MenuRoleGate>
                  }
                />

                {/* Cashier (penztaros) routes */}
                <Route path="/cashier" element={<CashierMainMenu />} />
                <Route path="/transactions/cashier" element={<CashierTransactionPage />} />
                <Route path="/closing/wizard" element={<ClosingWizardPage />} />
                <Route path="/denomination-images" element={<DenominationImagesPage />} />

                {/* Transactions */}
                <Route path="/transactions" element={<TransactionListPage />} />
                <Route path="/transactions/new" element={<TransactionPage />} />
                <Route path="/transactions/conversion" element={<ConversionPage />} />
                <Route path="/transactions/:id" element={<TransactionPage />} />
                <Route path="/transactions/:id/storno" element={<StornoPage />} />
                {/* #954 four-eyes előfeltétel: supervisor sztornó-jóváhagyó lista. A backend
              @PreAuthorize (SUPERVISOR/MANAGER/ADMIN) a hiteles enforcement (a /workers
              mintája szerint route-szinten nem gatelünk); a menü szerepkör szerint rejti. */}
                <Route path="/stornos/approvals" element={<StornoApprovalListPage />} />

                {/* Customers */}
                <Route path="/customers" element={<CustomerListPage />} />
                <Route path="/customers/new" element={<CustomerCreatePage />} />
                <Route path="/customers/:id" element={<CustomerDetailPage />} />

                {/* Rates */}
                <Route path="/rates" element={<RatesPage />} />
                <Route
                  path="/competitor-rates"
                  element={
                    <MenuRoleGate path="/competitor-rates">
                      <CompetitorRateEntryPage />
                    </MenuRoleGate>
                  }
                />
                <Route path="/rates/main" element={<MainRateSheetPage />} />
                <Route path="/rates/creation" element={<RateCreationPage />} />

                {/* Cash desk */}
                <Route path="/cashdesk" element={<CashDeskPage />} />
                <Route path="/cashdesk/denominations" element={<DenominationPage />} />
                <Route path="/cashdesk/breaks" element={<CashDeskBreakPage />} />

                {/* Closing */}
                <Route path="/closing/wizard/:wizardId" element={<ClosingWizardPage />} />

                {/* Representatives */}
                <Route path="/representatives" element={<RepresentativeListPage />} />
                <Route
                  path="/customers/:customerId/representatives"
                  element={<RepresentativeListPage />}
                />
                <Route
                  path="/customers/:customerId/representatives/new"
                  element={<RepresentativeCreatePage />}
                />
                <Route
                  path="/customers/:customerId/representatives/:representativeId"
                  element={<RepresentativeDetailPage />}
                />

                {/* Shipments */}
                <Route path="/shipments" element={<ShipmentListPage />} />
                <Route path="/shipments/new" element={<ShipmentNewPage />} />
                <Route path="/packaging" element={<PackagingPage />} />

                {/* Bali Henriett 2. pont (2026-05-27): manuális lakossági pénztár-felrögzítés
              értéktáros által (terület-hozzárendeléssel, hogy a területi szűrt listákban
              automatikusan megjelenjen). */}
                <Route path="/branches/new-cashier" element={<NewCashierBranchPage />} />

                {/* FK-020: Pénztár Törzs Adatbázis lista (Adminisztráció menücsoport).
              Codex #1056 P1: szerepkör-gate a menü canonicalRoles-szal egyezően. */}
                <Route
                  path="/admin/branches"
                  element={
                    <RoleGate canonicalRoles={['foertektar', 'belso_ellenor', 'ugyvezeto']}>
                      <BranchPage />
                    </RoleGate>
                  }
                />
                {/* FK-021: Új iroda felrögzítése (a lista "Új pénztár" gombjáról).
              Ugyanaz a szerepkör-gate, mint a listán (a create is felügyeleti művelet). */}
                <Route
                  path="/admin/branches/new"
                  element={
                    <RoleGate canonicalRoles={['foertektar', 'belso_ellenor', 'ugyvezeto']}>
                      <BranchCreatePage />
                    </RoleGate>
                  }
                />
                {/* FK-022: Iroda adatainak szerkesztése (a lista "Szerkesztés" gombjáról).
              RBAC-mátrix (§3): a Belső ellenőr csak OLVAS — a szerkesztő oldalra nem léphet
              (a backend PUT amúgy is 403-at adna, FR-8). ADMIN a RoleGate-fallback révén átmegy. */}
                <Route
                  path="/admin/branches/:id/edit"
                  element={
                    <RoleGate canonicalRoles={['foertektar', 'ugyvezeto']}>
                      <BranchEditPage />
                    </RoleGate>
                  }
                />
                {/* FK-026: Dolgozói Törzs Adatbázis read-only lista (Adminisztráció menücsoport).
              Ugyanaz a szerepkör-gate, mint a Pénztár Törzs Adatbázisnál (olvasó szerepek). */}
                <Route
                  path="/admin/workers-database"
                  element={
                    <RoleGate canonicalRoles={['foertektar', 'belso_ellenor', 'ugyvezeto']}>
                      <WorkersDatabasePage />
                    </RoleGate>
                  }
                />

                {/* FK-ÉRTÉKTÁR (V285): új személyes értéktári munkatárs felvétele (név + jelszó). */}
                <Route path="/vault-workers/new" element={<NewVaultWorkerPage />} />

                {/* Transfers — visszaigazolás (/transfers, /transfers/:id) vs létrehozás (/transfers/new).
                    MenuRoleGate: menü-paritás (RBAC-audit minta, effectiveCanonicalRolesForPath UNIÓ). */}
                <Route
                  path="/transfers"
                  element={
                    <MenuRoleGate path="/transfers">
                      <TransferPage />
                    </MenuRoleGate>
                  }
                />
                <Route
                  path="/transfers/new"
                  element={
                    <MenuRoleGate path="/transfers/new">
                      <TransferCreatePage />
                    </MenuRoleGate>
                  }
                />
                <Route
                  path="/transfers/:id"
                  element={
                    <MenuRoleGate path="/transfers">
                      <TransferPage />
                    </MenuRoleGate>
                  }
                />
                {/* E-B8 banki workflow — backend-integrált oldal */}
                <Route path="/bank-orders" element={<BankOrderPage />} />

                {/* Reports */}
                <Route path="/reports" element={<ReportsPage />} />
                <Route path="/reports/extended" element={<ExtendedReportsPage />} />
                <Route path="/reports/handling-fee-decade" element={<HandlingFeeDecadePage />} />
                <Route path="/reports/pos-handling-fee" element={<PosHandlingFeePage />} />
                <Route path="/reports/bank-transactions" element={<BankTransactionReportPage />} />
                <Route path="/reports/cashier-turnover" element={<CashierTurnoverReportPage />} />
                <Route
                  path="/reports/recurring-customers"
                  element={<RecurringCustomerReportPage />}
                />
                <Route path="/reports/average-rate" element={<AverageRateReportPage />} />
                <Route path="/reports/daily-journal" element={<DailyJournalPage />} />
                <Route path="/reports/central" element={<CentralReportsPage />} />
                <Route path="/reports/nav" element={<NavReportPage />} />
                <Route path="/reports/live-cash-position" element={<LiveCashPositionPage />} />
                <Route path="/reports/monthly-tablo" element={<MonthlyTabloPage />} />
                <Route path="/reports/region-turnover" element={<RegionTurnoverReportPage />} />
                <Route
                  path="/reports/territory-reconciliation"
                  element={<TerritoryReconciliationPage />}
                />

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
                <Route
                  path="/settings"
                  element={
                    <MenuRoleGate path="/settings">
                      <SettingsPage />
                    </MenuRoleGate>
                  }
                />
                <Route path="/settings/penztar" element={<PenztarSettingsPage />} />

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

                {/* EXCMD b6b FR-EFM: Egyéb feladatok menü + b5 FR-KC-05: Címletezés-zárások menü */}
                <Route path="/other-tasks" element={<OtherTasksPage />} />
                <Route
                  path="/closing/denominations-menu"
                  element={<ClosingDenominationMenuPage />}
                />

                {/* Document Storage */}
                <Route path="/documents" element={<DocumentStoragePage />} />

                {/* Notifications */}
                <Route path="/notifications" element={<NotificationPage />} />

                {/* Organizational System Parameters */}
                <Route
                  path="/organizational-system-parameters"
                  element={<OrganizationalSystemParameterPage />}
                />

                {/* Branch Groups */}
                <Route path="/branch-groups" element={<BranchGroupPage />} />

                {/* Audit Log */}
                <Route
                  path="/audit-log"
                  element={
                    <MenuRoleGate path="/audit-log">
                      <AuditLogPage />
                    </MenuRoleGate>
                  }
                />

                {/* Hiba-monitor (admin/manager/supervisor) */}
                <Route
                  path="/admin/error-monitor"
                  element={
                    <MenuRoleGate path="/admin/error-monitor">
                      <ErrorMonitorPage />
                    </MenuRoleGate>
                  }
                />

                {/* V234 Audit-diagnosztika (admin/support/manager) - belso log+audit modul */}
                <Route
                  path="/admin/audit-diagnostics"
                  element={
                    <MenuRoleGate path="/admin/audit-diagnostics">
                      <AuditDiagnosticsPage />
                    </MenuRoleGate>
                  }
                />

                {/* Circulars (Körlevelek) */}
                <Route path="/circulars" element={<CircularPage />} />

                {/* Fee Packages */}
                <Route path="/fee-packages" element={<FeePackagePage />} />
                <Route
                  path="/handling-fee-config"
                  element={
                    <MenuRoleGate path="/handling-fee-config">
                      <HandlingFeeConfigPage />
                    </MenuRoleGate>
                  }
                />

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
                <Route
                  path="/camera/live"
                  element={
                    <CameraGuard>
                      <CameraLivePage />
                    </CameraGuard>
                  }
                />
                <Route
                  path="/camera/playback"
                  element={
                    <CameraGuard>
                      <CameraPlaybackPage />
                    </CameraGuard>
                  }
                />
                <Route
                  path="/camera/config"
                  element={
                    <CameraGuard>
                      <CameraConfigPage />
                    </CameraGuard>
                  }
                />
                <Route
                  path="/camera/status"
                  element={
                    <CameraGuard>
                      <CameraStatusPage />
                    </CameraGuard>
                  }
                />
                <Route
                  path="/camera/export"
                  element={
                    <CameraGuard>
                      <CameraExportPage />
                    </CameraGuard>
                  }
                />
                <Route path="/darius" element={<DariusReportPage />} />
                <Route path="/decade" element={<DecadeReportPage />} />
                <Route path="/daybook" element={<DaybookPage />} />
                <Route path="/reports/cash-flow" element={<CashFlowReportPage />} />
                <Route path="/daily-turnover" element={<DailyTurnoverPage />} />
                <Route path="/evening-closing" element={<EveningClosingPage />} />
                <Route path="/daily-checklist" element={<DailyChecklistPage />} />
                <Route path="/daily-check" element={<DailyCheckPage />} />

                {/* === Árfolyam-kezelés Routes === */}
                <Route path="/rate-management" element={<RateCreationDashboard />} />
                <Route path="/trades" element={<TradePage />} />
                <Route path="/trade" element={<Navigate to="/trades" replace />} />

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
                <Route
                  path="/police-requests"
                  element={
                    <MenuRoleGate path="/police-requests">
                      <PoliceRequestPage />
                    </MenuRoleGate>
                  }
                />
                <Route
                  path="/seal-tracking"
                  element={
                    <MenuRoleGate path="/seal-tracking">
                      <SealTrackingPage />
                    </MenuRoleGate>
                  }
                />
                <Route path="/print-templates" element={<PrintTemplatePage />} />
                <Route
                  path="/licenses"
                  element={
                    <MenuRoleGate path="/licenses">
                      <LicensePage />
                    </MenuRoleGate>
                  }
                />
                <Route
                  path="/scheduler"
                  element={
                    <MenuRoleGate path="/scheduler">
                      <SchedulerPage />
                    </MenuRoleGate>
                  }
                />
                <Route
                  path="/email-settings"
                  element={
                    <MenuRoleGate path="/email-settings">
                      <EmailPage />
                    </MenuRoleGate>
                  }
                />
                <Route
                  path="/employees"
                  element={
                    <MenuRoleGate path="/employees">
                      <EmployeePage />
                    </MenuRoleGate>
                  }
                />
                {/* Codex #1059: a /workers-t a backend SecurityConfig HTTP-matchere már szigorúan védi
              (SUPERVISOR/MANAGER/ADMIN). Egy kanonikus-szerepkörű frontend RoleGate eltérne ettől
              (false-admit/false-block a kanonikus↔angol név-eltérés miatt), ezért itt NEM gatelünk
              route-szinten — a backend a hiteles enforcement, a menü pedig full-módban rejti. */}
                <Route path="/workers" element={<WorkerPage />} />
                <Route path="/transit" element={<TransitPage />} />
                <Route path="/led-display" element={<LedDisplayPage />} />
                <Route path="/data-import" element={<DataImportPage />} />
                <Route path="/stamps" element={<StampPage />} />
                <Route path="/stock-snapshot" element={<StockSnapshotPage />} />
                <Route path="/stock-snapshots" element={<StockSnapshotPage />} />
                <Route
                  path="/rates/categories"
                  element={
                    <MenuRoleGate path="/rates/categories">
                      <RateCategoryPage />
                    </MenuRoleGate>
                  }
                />
                <Route
                  path="/rates/history"
                  element={
                    <MenuRoleGate path="/rates/history">
                      <RateHistoryPage />
                    </MenuRoleGate>
                  }
                />
                <Route path="/transfer-documents" element={<TransferDocumentPage />} />
                <Route path="/booking-export" element={<BookingExportPage />} />

                {/* PR #116: /conversion alias -> /transactions/conversion (user typed the short URL) */}
                <Route
                  path="/conversion"
                  element={<Navigate to="/transactions/conversion" replace />}
                />

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
