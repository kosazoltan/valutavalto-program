import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from './stores/authStore'
import { Toaster } from './components/ui/toaster'

// Layouts
import MainLayout from './layouts/MainLayout'
import AuthLayout from './layouts/AuthLayout'

// Pages
import LoginPage from './pages/auth/LoginPage'
import DashboardPage from './pages/DashboardPage'
import TransactionPage from './pages/transactions/TransactionPage'
import TransactionListPage from './pages/transactions/TransactionListPage'
import ConversionPage from './pages/transactions/ConversionPage'
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
import ClosingWizardPage from './pages/closing/ClosingWizardPage'
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
import PosTerminalPage from './pages/pos/PosTerminalPage'
import NavIntegrationPage from './pages/nav/NavIntegrationPage'
import DocumentStoragePage from './pages/documents/DocumentStoragePage'
import NotificationPage from './pages/notifications/NotificationPage'
import OrganizationalSystemParameterPage from './pages/organizations/OrganizationalSystemParameterPage'
import BranchGroupPage from './pages/branches/BranchGroupPage'

// === Moduláris Feature Pages (v2) ===
import { ReportsV2Page } from './features/reporting/ReportsV2Page'
import { ComplianceV2Page } from './features/compliance/ComplianceV2Page'
import { ExportV2Page } from './features/export/ExportV2Page'
import { MnbRatesV2Page } from './features/integration/MnbRatesV2Page'
import { NavV2Page } from './features/integration/nav/NavV2Page'

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated)
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />
  }
  
  return <>{children}</>
}

export default function App() {
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
          <Route path="/closing/wizard" element={<ClosingWizardPage />} />
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

          {/* === Moduláris Feature Routes (v2) === */}
          {/* Reporting v2 */}
          <Route path="/reports-v2" element={<ReportsV2Page />} />

          {/* Compliance v2 */}
          <Route path="/compliance-v2" element={<ComplianceV2Page />} />

          {/* Export v2 */}
          <Route path="/export-v2" element={<ExportV2Page />} />

          {/* MNB Rates v2 */}
          <Route path="/mnb-rates-v2" element={<MnbRatesV2Page />} />

          {/* NAV Integration v2 */}
          <Route path="/nav-v2" element={<NavV2Page />} />
        </Route>
      </Routes>
      <Toaster />
    </>
  )
}
