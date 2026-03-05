import { useEffect, useState } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { setAuthToken, loadPersistedToken } from '@/api/client';
import { useAppMode } from '@/hooks/useAppMode';
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
        </>
      )}

      <Route path="*" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}
