import { useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { useSessionStore } from '@/stores/sessionStore';
import { useAppMode } from '@/hooks/useAppMode';
import type { MenuItem, PageRoute } from '@/types';

const MENU_ITEMS: MenuItem[] = [
  { key: 'F1', label: 'Eladás', icon: '💰', route: '/sell', hotkey: 'F1' },
  { key: 'F2', label: 'Vásárlás', icon: '🛒', route: '/buy', hotkey: 'F2' },
  { key: 'F3', label: 'Készlet', icon: '📦', route: '/stock', hotkey: 'F3' },
  { key: 'F4', label: 'Címletezés', icon: '🪙', route: '/denom', hotkey: 'F4' },
  { key: 'F5', label: 'Átadás-átvétel', icon: '🔄', route: '/transfer', hotkey: 'F5' },
  { key: 'F6', label: 'Stornó', icon: '↩️', route: '/storno', hotkey: 'F6' },
  { key: 'F7', label: 'Nap zárás', icon: '🌙', route: '/closing', hotkey: 'F7' },
  { key: 'F8', label: 'Körlevél', icon: '📨', route: '/circulars', hotkey: 'F8' },
  { key: 'F9', label: 'Árfolyamok', icon: '📊', route: '/rates', hotkey: 'F9' },
  { key: 'F10', label: 'Ügyfél', icon: '👤', route: '/customer', hotkey: 'F10' },
  { key: 'F11', label: 'Listák', icon: '📋', route: '/lists', hotkey: 'F11' },
  { key: 'F12', label: 'Beállítások', icon: '⚙️', route: '/settings', hotkey: 'F12' },
];

// Speciális funkciók menüpontok
const SPECIAL_ITEMS: MenuItem[] = [
  { key: 'SP1', label: 'Foglalás', icon: '📋', route: '/reservation', hotkey: 'Ctrl+F' },
  { key: 'SP2', label: 'HRK (Házipénztár)', icon: '🏦', route: '/hrk', hotkey: 'Ctrl+H' },
  { key: 'SP3', label: 'Esti zárás', icon: '🌙', route: '/evening-closing', hotkey: 'Ctrl+E' },
];

// Értéktár extra menüpontok
const ERTEKTAR_ITEMS: MenuItem[] = [
  { key: 'ET1', label: 'Értéktár áttekintő', icon: '🏦', route: '/ertektar', hotkey: 'Ctrl+1' },
  { key: 'ET2', label: 'Szétosztás', icon: '📦', route: '/ertektar/distribution', hotkey: 'Ctrl+2' },
  { key: 'ET3', label: 'Begyűjtés', icon: '📥', route: '/ertektar/collection', hotkey: 'Ctrl+3' },
  { key: 'ET4', label: 'Összevont riportok', icon: '📊', route: '/ertektar/reports', hotkey: 'Ctrl+4' },
];

export default function MainMenu() {
  const navigate = useNavigate();
  const { user, companyType, branchCode, clearAuth } = useAuthStore();
  const { isOnline, currentTime, updateTime } = useSessionStore();
  const { mode } = useAppMode();
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const isErtektar = mode === 'ertektar';
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const modeLabel = isErtektar ? 'Értéktár' : 'Pénztár';

  const handleNavigate = useCallback(
    (route: PageRoute) => {
      navigate(route);
    },
    [navigate],
  );

  const handleLogout = useCallback(() => {
    clearAuth();
    navigate('/login');
  }, [clearAuth, navigate]);

  // Gyorsbillentyűk (F1-F12 + Ctrl+1-4 értéktár módban)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const fKeyMatch = e.key.match(/^F(\d{1,2})$/);
      if (fKeyMatch) {
        const fNum = parseInt(fKeyMatch[1]!, 10);
        if (fNum >= 1 && fNum <= 12) {
          e.preventDefault();
          const item = MENU_ITEMS[fNum - 1];
          if (item) {
            handleNavigate(item.route);
          }
        }
      }

      // Speciális funkciók: Ctrl+F, Ctrl+H, Ctrl+E
      if (e.ctrlKey && !e.shiftKey && !e.altKey) {
        const keyLower = e.key.toLowerCase();
        if (keyLower === 'f') {
          e.preventDefault();
          handleNavigate('/reservation');
        } else if (keyLower === 'h') {
          e.preventDefault();
          handleNavigate('/hrk');
        } else if (keyLower === 'e') {
          e.preventDefault();
          handleNavigate('/evening-closing');
        }
      }

      // Értéktár gyorsbillentyűk: Ctrl+1..4
      if (isErtektar && e.ctrlKey && !e.shiftKey && !e.altKey) {
        const num = parseInt(e.key, 10);
        if (num >= 1 && num <= 4) {
          e.preventDefault();
          const ertektarItem = ERTEKTAR_ITEMS[num - 1];
          if (ertektarItem) {
            handleNavigate(ertektarItem.route);
          }
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleNavigate, isErtektar]);

  // Óra frissítés másodpercenként
  useEffect(() => {
    updateTime();
    timerRef.current = setInterval(updateTime, 1000);
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [updateTime]);

  // Online/offline figyelés
  useEffect(() => {
    const { setOnline } = useSessionStore.getState();
    const handleOnline = () => setOnline(true);
    const handleOffline = () => setOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-4 text-white shadow-lg`}>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">
              {isBestChange ? '💱 Best Change' : '💎 Expressz'} — {modeLabel}
            </h1>
            <p className="text-sm text-white/80">
              {user?.fullName ?? 'Pénztáros'} | {modeLabel}: {branchCode}
            </p>
          </div>
          <button
            onClick={handleLogout}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm font-medium text-white transition hover:bg-white/30"
          >
            🚪 Kijelentkezés
          </button>
        </div>
      </header>

      {/* Menü gombok */}
      <main className="flex-1 overflow-auto p-6">
        {/* Értéktár extra gombok */}
        {isErtektar && (
          <div className="mx-auto mb-6 max-w-4xl">
            <h2 className="mb-3 text-lg font-semibold text-gray-600">🏦 Értéktár funkciók</h2>
            <div className="grid grid-cols-4 gap-4">
              {ERTEKTAR_ITEMS.map((item) => (
                <button
                  key={item.key}
                  onClick={() => handleNavigate(item.route)}
                  className="menu-btn h-28 border-2 border-indigo-200 bg-indigo-50 hover:bg-indigo-100"
                >
                  <span className="menu-btn-icon">{item.icon}</span>
                  <span className="menu-btn-label text-indigo-800">{item.label}</span>
                  <span className="menu-btn-hotkey text-indigo-500">{item.hotkey}</span>
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Pénztár menü gombok (F1-F12) */}
        <div className="mx-auto max-w-4xl">
          {isErtektar && (
            <h2 className="mb-3 text-lg font-semibold text-gray-600">💰 Pénztár funkciók</h2>
          )}
          <div className="grid grid-cols-4 gap-4">
            {MENU_ITEMS.map((item) => (
              <button
                key={item.key}
                onClick={() => handleNavigate(item.route)}
                className="menu-btn h-32"
              >
                <span className="menu-btn-icon">{item.icon}</span>
                <span className="menu-btn-label">{item.label}</span>
                <span className="menu-btn-hotkey">{item.hotkey}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Speciális funkciók */}
        <div className="mx-auto mt-6 max-w-4xl">
          <h2 className="mb-3 text-lg font-semibold text-gray-600">⚡ Speciális funkciók</h2>
          <div className="grid grid-cols-3 gap-4">
            {SPECIAL_ITEMS.map((item) => (
              <button
                key={item.key}
                onClick={() => handleNavigate(item.route)}
                className="menu-btn h-28 border-2 border-purple-200 bg-purple-50 hover:bg-purple-100"
              >
                <span className="menu-btn-icon">{item.icon}</span>
                <span className="menu-btn-label text-purple-800">{item.label}</span>
                <span className="menu-btn-hotkey text-purple-500">{item.hotkey}</span>
              </button>
            ))}
          </div>
        </div>
      </main>

      {/* Állapotsor */}
      <footer className="status-bar">
        <span>
          👤 {user?.fullName ?? '—'} | 🏦 {modeLabel}: {branchCode}
        </span>
        <span>
          {isOnline ? (
            <span className="text-green-600">🟢 Online</span>
          ) : (
            <span className="text-red-600">🔴 Offline</span>
          )}
          {' | '}
          🕐 {currentTime}
        </span>
      </footer>
    </div>
  );
}
