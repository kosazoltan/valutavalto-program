import { Suspense, lazy, useEffect, useState } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from './stores/authStore'
import { Toaster } from './components/ui/toaster'
import ErrorBoundary from './components/ErrorBoundary'
import { api, clearPersistedToken, hasPersistedToken, loadPersistedToken } from './services/api/index'

// Layouts
import MainLayout from './layouts/MainLayout'
import AuthLayout from './layouts/AuthLayout'

// Pages
import LoginPage from './pages/auth/LoginPage'
import { logger } from './utils/logger';

const DashboardPage = lazy(() => import('./pages/DashboardPage'))
const TransactionPage = lazy(() => import('./pages/transactions/TransactionPage'))
const TransactionListPage = lazy(() => import('./pages/transactions/TransactionListPage'))
const ConversionPage = lazy(() => import('./pages/transactions/ConversionPage'))
const CashierTransactionPage = lazy(() => import('./pages/transactions/CashierTransactionPage'))
const CashierMainMenu = lazy(() => import('./pages/CashierMainMenu'))
const ClosingWizardPage = lazy(() => import('./pages/closing/ClosingWizardPage'))
const TransferPage = lazy(() => import('./pages/transfers/TransferPage'))
const CustomerListPage = lazy(() => import('./pages/customers/CustomerListPage'))
const CustomerDetailPage = lazy(() => import('./pages/customers/CustomerDetailPage'))
const CustomerCreatePage = lazy(() => import('./pages/customers/CustomerCreatePage'))
const RatesPage = lazy(() => import('./pages/rates/RatesPage'))
const RateCreationPage = lazy(() => import('./pages/rates/RateCreationPage'))
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
const PepPage = lazy(() => import('./pages/pep/PepPage'))
const RateGroupPage = lazy(() => import('./pages/rates/RateGroupPage'))
const ReservationPage = lazy(() => import('./pages/reservations/ReservationPage'))
const SuspiciousReportPage = lazy(() => import('./pages/suspicious/SuspiciousReportPage'))
const PermissionPage = lazy(() => import('./pages/settings/PermissionPage'))
const RolePage = lazy(() => import('./pages/settings/RolePage'))
const SystemParameterPage = lazy(() => import('./pages/settings/SystemParameterPage'))
const UserPage = lazy(() => import('./pages/settings/UserPage'))

// === Kamera modul ===
const CameraLivePage = lazy(() => import('./pages/camera/CameraLivePage'))
const CameraPlaybackPage = lazy(() => import('./pages/camera/CameraPlaybackPage'))
const CameraConfigPage = lazy(() => import('./pages/camera/CameraConfigPage'))
const CameraStatusPage = lazy(() => import('./pages/camera/CameraStatusPage'))
const CameraExportPage = lazy(() => import('./pages/camera/CameraExportPage'))
const DariusReportPage = lazy(() => import('./pages/darius/DariusReportPage'))
const DecadeReportPage = lazy(() => import('./pages/decade/DecadeReportPage'))

// === Árfolyam-kezelés modul ===
const RateCreationDashboard = lazy(() => import('./pages/ratemanagement/RateCreationDashboard'))

// === Treasury (Értéktári) modul ===
const TreasuryLayout = lazy(() => import('./pages/treasury/TreasuryLayout'))
const TreasuryDashboard = lazy(() => import('./pages/treasury/TreasuryDashboard'))
const StockMatrix = lazy(() => import('./pages/treasury/StockMatrix'))
const MovementManager = lazy(() => import('./pages/treasury/MovementManager'))
const RatePanel = lazy(() => import('./pages/treasury/RatePanel'))
const ReportsCirculars = lazy(() => import('./pages/treasury/ReportsCirculars'))
const BankTransactions = lazy(() => import('./pages/treasury/BankTransactions'))
const VatRefundPage = lazy(() => import('./pages/treasury/VatRefundPage'))
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

export default function App() {
  const [isRestoring, setIsRestoring] = useState(() => hasPersistedToken())

  // Desktopon és weben is megpróbáljuk visszatölteni a tárolt JWT-t.
  useEffect(() => {
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
            }
            const now = Math.floor(Date.now() / 1000)
            if (payload.exp && payload.exp > now) {
              // Token érvényes → restore auth state
              try {
                const res = await api.get('/workers/me', {
                  headers: { Authorization: `Bearer ${token}` },
                })
                if (res.data) {
                  // V57: activeRole + permissions restore a JWT payload-ból
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
                  // Offline fallback: fail-closed CASHIER-only profile
                  // SECURITY: nem bízunk a JWT role/permissions claimekben offline módban,
                  // mert a lokális token manipulálható. Fix CASHIER role + üres permissions.
                  const jwtPayload = payload as Record<string, unknown>
                  const offlineWorker = {
                    id: Number(jwtPayload.workerId) || 0,
                    workerCode: String(jwtPayload.workerCode ?? ''),
                    firstName: '',
                    lastName: '',
                    fullName: String(jwtPayload.workerName ?? ''),
                    role: 'CASHIER',  // Hardcoded — offline soha nem ad magasabb jogot
                    branchId: String(jwtPayload.branchId ?? ''),
                    branchCode: String(jwtPayload.branchCode ?? ''),
                    branchName: '',
                    companyId: String(jwtPayload.companyId ?? ''),
                    companyCode: String(jwtPayload.companyCode ?? ''),
                    companyName: '',
                  }
                  useAuthStore.getState().login(
                    offlineWorker, token, 'Bearer',
                    new Date(payload.exp! * 1000).toISOString(),
                    'CASHIER',  // Offline: fix CASHIER activeRole
                    [],         // Offline: üres permissions (fail-closed)
                    ['CASHIER'],
                  )
                  logger.warn('App', 'Offline login restore — CASHIER-only profil, korlatozott jogosultsagok.')
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
      <Suspense fallback={<RouteLoadingFallback />}>
        <Routes>
          {/* Auth routes */}
          <Route element={<AuthLayout />}>
            <Route path="/login" element={<LoginPage />} />
          </Route>

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
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<DashboardPage />} />
          
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

          {/* Transfers */}
          <Route path="/transfers" element={<TransferPage />} />
          <Route path="/transfers/:id" element={<TransferPage />} />
          
          {/* Reports */}
          <Route path="/reports" element={<ReportsPage />} />
          <Route path="/reports/extended" element={<ExtendedReportsPage />} />
          
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

          {/* Circulars (Körlevelek) */}
          <Route path="/circulars" element={<CircularPage />} />

          {/* Fee Packages */}
          <Route path="/fee-packages" element={<FeePackagePage />} />

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
            <Route path="rates" element={<RatePanel />} />
            <Route path="reports" element={<ReportsCirculars />} />
            <Route path="vat" element={<VatRefundPage />} />
          </Route>

          {/* === Kamera Routes === */}
          <Route path="/camera/live" element={<CameraLivePage />} />
          <Route path="/camera/playback" element={<CameraPlaybackPage />} />
          <Route path="/camera/config" element={<CameraConfigPage />} />
          <Route path="/camera/status" element={<CameraStatusPage />} />
          <Route path="/camera/export" element={<CameraExportPage />} />
          <Route path="/darius" element={<DariusReportPage />} />
          <Route path="/decade" element={<DecadeReportPage />} />
          <Route path="/daybook" element={<DaybookPage />} />
          <Route path="/daily-turnover" element={<DailyTurnoverPage />} />
          <Route path="/evening-closing" element={<EveningClosingPage />} />
          <Route path="/daily-checklist" element={<DailyChecklistPage />} />

          {/* === Árfolyam-kezelés Routes === */}
          <Route path="/rate-management" element={<RateCreationDashboard />} />
              <Route path="/trade" element={<Navigate to="/cashier" replace />} />

          </Route>
        </Routes>
      </Suspense>
      <Toaster />
    </ErrorBoundary>
  )
}
