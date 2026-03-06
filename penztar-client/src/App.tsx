import { useEffect, useState } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { setAuthToken, loadPersistedToken } from '@/api/client';
import { useAppMode } from '@/hooks/useAppMode';
import ErrorBoundary from '@/components/ErrorBoundary';
import ToastContainer from '@/components/Toast';
import LoginPage from '@/pages/LoginPage';
import MainMenu from '@/pages/MainMenu';
import SellPage from '@/pages/SellPage';
import BuyPage from '@/pages/BuyPage';
import StockPage from '@/pages/StockPage';
import DenomPage from '@/pages/DenomPage';
import TransferPage from '@/pages/TransferPage';
import StornoPage from '@/pages/StornoPage';
import ClosingPage from '@/pages/ClosingPage';
import RatesPage from '@/pages/RatesPage';
import CircularPage from '@/pages/CircularPage';
import CustomerPage from '@/pages/CustomerPage';
import ReportsPage from '@/pages/ReportsPage';
import SettingsPage from '@/pages/SettingsPage';
// Speciális funkciók
import ReservationPage from '@/pages/ReservationPage';
import HrkPage from '@/pages/HrkPage';
import EveningClosingPage from '@/pages/EveningClosingPage';
// Értéktár képernyők
import ErtektarDashboard from '@/pages/ErtektarDashboard';
import DistributionPage from '@/pages/DistributionPage';
import CollectionPage from '@/pages/CollectionPage';
import ConsolidatedReportsPage from '@/pages/ConsolidatedReportsPage';
// Batch 2B képernyők
import SupervisorPage from '@/pages/SupervisorPage';
import WorkerManagementPage from '@/pages/WorkerManagementPage';
import ReceiptSearchPage from '@/pages/ReceiptSearchPage';
import StampPage from '@/pages/StampPage';
// Batch 2C — új képernyők
import RateApprovalPage from '@/pages/RateApprovalPage';
import DailyReportPage from '@/pages/DailyReportPage';
import PolicePage from '@/pages/PolicePage';
// Vezetői képernyők
import MonthlyClosingPage from '@/pages/MonthlyClosingPage';
import CommissionPage from '@/pages/CommissionPage';
import BookingPage from '@/pages/BookingPage';
import ProfitPage from '@/pages/ProfitPage';
// Batch 3 — Dekádjelentés + Verseny
import DecadeReportPage from '@/pages/DecadeReportPage';
import CompetitionPage from '@/pages/CompetitionPage';
// Batch 4 — Trade + Dashboard
import TradePage from '@/pages/TradePage';
import DashboardPage from '@/pages/DashboardPage';
// Batch 4B — Backup + Nyomtatási sablonok
import BackupPage from '@/pages/BackupPage';
import PrintTemplatePage from '@/pages/PrintTemplatePage';
// Batch 6A — Pénztárnyitás + Kalkulátor
import SessionOpenPage from '@/pages/SessionOpenPage';
import CalculatorPage from '@/pages/CalculatorPage';
// Batch 6B — Audit napló
import AuditLogPage from '@/pages/AuditLogPage';

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return <>{children}</>;
}

export default function App() {
  const [isRestoring, setIsRestoring] = useState(true);
  const { mode, isLoading: isModeLoading } = useAppMode();

  // M1: Token restore — betöltéskor ellenőrizzük van-e tárolt JWT
  useEffect(() => {
    const restoreToken = async () => {
      try {
        const token = await loadPersistedToken();
        if (token) {
          // JWT alapvető validáció: van-e 3 szekció és nem járt-e le
          const parts = token.split('.');
          if (parts.length === 3 && parts[1]) {
            const payload = JSON.parse(atob(parts[1])) as { exp?: number };
            const now = Math.floor(Date.now() / 1000);
            if (payload.exp && payload.exp > now) {
              setAuthToken(token);
            }
          }
        }
      } catch (err) {
        console.error('[App] Token restore hiba:', err);
      } finally {
        setIsRestoring(false);
      }
    };
    void restoreToken();
  }, []);

  if (isRestoring || isModeLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <p className="text-gray-500">⏳ Betöltés...</p>
      </div>
    );
  }

  return (
    <ErrorBoundary>
    <ToastContainer />
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route
        path="/menu"
        element={
          <ProtectedRoute>
            <MainMenu />
          </ProtectedRoute>
        }
      />
      <Route
        path="/sell"
        element={
          <ProtectedRoute>
            <SellPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/buy"
        element={
          <ProtectedRoute>
            <BuyPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/stock"
        element={
          <ProtectedRoute>
            <StockPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/denom"
        element={
          <ProtectedRoute>
            <DenomPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/transfer"
        element={
          <ProtectedRoute>
            <TransferPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/storno"
        element={
          <ProtectedRoute>
            <StornoPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/closing"
        element={
          <ProtectedRoute>
            <ClosingPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/circulars"
        element={
          <ProtectedRoute>
            <CircularPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/rates"
        element={
          <ProtectedRoute>
            <RatesPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/customer"
        element={
          <ProtectedRoute>
            <CustomerPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/lists"
        element={
          <ProtectedRoute>
            <ReportsPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/settings"
        element={
          <ProtectedRoute>
            <SettingsPage />
          </ProtectedRoute>
        }
      />

      {/* Speciális funkciók */}
      <Route
        path="/reservation"
        element={
          <ProtectedRoute>
            <ReservationPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/hrk"
        element={
          <ProtectedRoute>
            <HrkPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/evening-closing"
        element={
          <ProtectedRoute>
            <EveningClosingPage />
          </ProtectedRoute>
        }
      />

      {/* Vezetői funkciók */}
      <Route
        path="/monthly-closing"
        element={
          <ProtectedRoute>
            <MonthlyClosingPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/commissions"
        element={
          <ProtectedRoute>
            <CommissionPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/booking"
        element={
          <ProtectedRoute>
            <BookingPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/profit"
        element={
          <ProtectedRoute>
            <ProfitPage />
          </ProtectedRoute>
        }
      />

      {/* Batch 2C — Napi jelentés + Police (mindkét módban elérhető) */}
      <Route
        path="/daily-report"
        element={
          <ProtectedRoute>
            <DailyReportPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/police"
        element={
          <ProtectedRoute>
            <PolicePage />
          </ProtectedRoute>
        }
      />

      {/* Értéktár route-ok — csak 'ertektar' módban elérhetők, de route mindig regisztrálva */}
      {mode === 'ertektar' && (
        <>
          <Route
            path="/ertektar"
            element={
              <ProtectedRoute>
                <ErtektarDashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/ertektar/distribution"
            element={
              <ProtectedRoute>
                <DistributionPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/ertektar/collection"
            element={
              <ProtectedRoute>
                <CollectionPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/ertektar/reports"
            element={
              <ProtectedRoute>
                <ConsolidatedReportsPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/ertektar/rate-approval"
            element={
              <ProtectedRoute>
                <RateApprovalPage />
              </ProtectedRoute>
            }
          />
        </>
      )}

      {/* Batch 2B route-ok */}
      <Route
        path="/supervisor"
        element={
          <ProtectedRoute>
            <SupervisorPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/worker-management"
        element={
          <ProtectedRoute>
            <WorkerManagementPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/receipt-search"
        element={
          <ProtectedRoute>
            <ReceiptSearchPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/stamps"
        element={
          <ProtectedRoute>
            <StampPage />
          </ProtectedRoute>
        }
      />

      {/* Batch 3 route-ok */}
      <Route
        path="/decade-report"
        element={
          <ProtectedRoute>
            <DecadeReportPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/competition"
        element={
          <ProtectedRoute>
            <CompetitionPage />
          </ProtectedRoute>
        }
      />

      {/* Batch 4B route-ok */}
      <Route
        path="/backup"
        element={
          <ProtectedRoute>
            <BackupPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/print-templates"
        element={
          <ProtectedRoute>
            <PrintTemplatePage />
          </ProtectedRoute>
        }
      />

      {/* Batch 4 route-ok */}
      <Route
        path="/trade"
        element={
          <ProtectedRoute>
            <TradePage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/dashboard"
        element={
          <ProtectedRoute>
            <DashboardPage />
          </ProtectedRoute>
        }
      />

      {/* Batch 6B — Audit napló */}
      <Route
        path="/audit"
        element={
          <ProtectedRoute>
            <AuditLogPage />
          </ProtectedRoute>
        }
      />

      {/* Batch 6A route-ok */}
      <Route
        path="/session-open"
        element={
          <ProtectedRoute>
            <SessionOpenPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/calculator"
        element={
          <ProtectedRoute>
            <CalculatorPage />
          </ProtectedRoute>
        }
      />

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
    </ErrorBoundary>
  );
}
