import { useEffect, useState } from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from './stores/authStore'
import { Toaster } from './components/ui/toaster'
import { api, clearPersistedToken, hasPersistedToken, loadPersistedToken } from './services/api'

// Layouts
import MainLayout from './layouts/MainLayout'
import AuthLayout from './layouts/AuthLayout'

// Pages
import LoginPage from './pages/auth/LoginPage'
import DashboardPage from './pages/DashboardPage'
import TransactionPage from './pages/transactions/TransactionPage'
import TransactionListPage from './pages/transactions/TransactionListPage'
import ConversionPage from './pages/transactions/ConversionPage'
import CashierTransactionPage from './pages/transactions/CashierTransactionPage'
import CashierMainMenu from './pages/CashierMainMenu'
import ClosingWizardPage from './pages/closing/ClosingWizardPage'
import TransferPage from './pages/transfers/TransferPage'
import CustomerListPage from './pages/customers/CustomerListPage'
import CustomerDetailPage from './pages/customers/CustomerDetailPage'
import CustomerCreatePage from './pages/customers/CustomerCreatePage'
import RatesPage from './pages/rates/RatesPage'
import RateCreationPage from './pages/rates/RateCreationPage'
import CashDeskPage from './pages/cashdesk/CashDeskPage'
import DenominationPage from './pages/cashdesk/DenominationPage'
import ReportsPage from './pages/reports/ReportsPage'
import SettingsPage from './pages/settings/SettingsPage'
import StornoPage from './pages/stornos/StornoPage'
import RepresentativeListPage from './pages/representatives/RepresentativeListPage'
import ShipmentListPage from './pages/shipments/ShipmentListPage'
import WorkerCommissionPage from './pages/commissions/WorkerCommissionPage'
import WorkstationPage from './pages/workstations/WorkstationPage'
import ContributionPage from './pages/contributions/ContributionPage'
import CashDeskBreakPage from './pages/cashdesk/CashDeskBreakPage'
import LoggingPage from './pages/logging/LoggingPage'
import OrganizationPage from './pages/organizations/OrganizationPage'
import OwnCompanyPage from './pages/company/OwnCompanyPage'
import ReceiptPage from './pages/receipts/ReceiptPage'
import HandoverSheetPage from './pages/handover/HandoverSheetPage'
import ExtendedReportsPage from './pages/reports/ExtendedReportsPage'
import FeePage from './pages/fees/FeePage'
import BlacklistPage from './pages/blacklist/BlacklistPage'
import AnonymousReportPage from './pages/reports/AnonymousReportPage'
import CommissionRatePage from './pages/commissions/CommissionRatePage'
import ArchivingPage from './pages/archiving/ArchivingPage'
import ExchangeRateDisplayPage from './pages/display/ExchangeRateDisplayPage'
import SynchronizationPage from './pages/sync/SynchronizationPage'
import LocalQueuePage from './pages/sync/LocalQueuePage'
import PosTerminalPage from './pages/pos/PosTerminalPage'
import NavIntegrationPage from './pages/nav/NavIntegrationPage'
import DocumentStoragePage from './pages/documents/DocumentStoragePage'
import NotificationPage from './pages/notifications/NotificationPage'
import OrganizationalSystemParameterPage from './pages/organizations/OrganizationalSystemParameterPage'
import BranchGroupPage from './pages/branches/BranchGroupPage'
import AuditLogPage from './pages/audit/AuditLogPage'
import CircularPage from './pages/circulars/CircularPage'
import FeePackagePage from './pages/fees/FeePackagePage'
import PepPage from './pages/pep/PepPage'
import RateGroupPage from './pages/rates/RateGroupPage'
import ReservationPage from './pages/reservations/ReservationPage'
import SuspiciousReportPage from './pages/suspicious/SuspiciousReportPage'
import PermissionPage from './pages/settings/PermissionPage'
import RolePage from './pages/settings/RolePage'
import SystemParameterPage from './pages/settings/SystemParameterPage'
import UserPage from './pages/settings/UserPage'

// === Kamera modul ===
import CameraLivePage from './pages/camera/CameraLivePage'
import CameraPlaybackPage from './pages/camera/CameraPlaybackPage'
import CameraConfigPage from './pages/camera/CameraConfigPage'
import CameraStatusPage from './pages/camera/CameraStatusPage'
import CameraExportPage from './pages/camera/CameraExportPage'
import DariusReportPage from './pages/darius/DariusReportPage'

// === Árfolyam-kezelés modul ===
import RateCreationDashboard from './pages/ratemanagement/RateCreationDashboard'

// === Treasury (Értéktári) modul ===
import TreasuryLayout from './pages/treasury/TreasuryLayout'
import TreasuryDashboard from './pages/treasury/TreasuryDashboard'
import StockMatrix from './pages/treasury/StockMatrix'
import MovementManager from './pages/treasury/MovementManager'
import RatePanel from './pages/treasury/RatePanel'
import ReportsCirculars from './pages/treasury/ReportsCirculars'
import BankTransactions from './pages/treasury/BankTransactions'

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
            const payload = JSON.parse(atob(parts[1])) as {
              exp?: number
              activeRole?: string
              permissions?: string[]
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
                  )
                }
              } catch {
                // Token szerver oldalon érvénytelen
                await clearPersistedToken()
              }
            } else {
              await clearPersistedToken()
            }
          } else {
            await clearPersistedToken()
          }
        }
      } catch (err) {
        console.error('[App] Token restore hiba:', err)
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
    <>
      <Routes>
        {/* Auth routes */}
        <Route element={<AuthLayout />}>
          <Route path="/login" element={<LoginPage />} />
        </Route>

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
          </Route>

          {/* === Kamera Routes === */}
          <Route path="/camera/live" element={<CameraLivePage />} />
          <Route path="/camera/playback" element={<CameraPlaybackPage />} />
          <Route path="/camera/config" element={<CameraConfigPage />} />
          <Route path="/camera/status" element={<CameraStatusPage />} />
          <Route path="/camera/export" element={<CameraExportPage />} />
          <Route path="/darius" element={<DariusReportPage />} />

          {/* === Árfolyam-kezelés Routes === */}
          <Route path="/rate-management" element={<RateCreationDashboard />} />

        </Route>
      </Routes>
      <Toaster />
    </>
  )
}
