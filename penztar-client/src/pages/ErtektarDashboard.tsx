import { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { useOnlineStatus } from '@/hooks/useOnlineStatus';
import type { SubordinateBranch, BranchOnlineStatus } from '@/types';

// --- Konstansok ---
const REFRESH_INTERVAL_MS = 30_000;
const WARNING_THRESHOLD_MS = 5 * 60 * 1_000; // 5 perc
const OFFLINE_THRESHOLD_MS = 60 * 60 * 1_000; // 1 óra

// --- Státusz jelzők ---
const STATUS_COLORS: Record<BranchOnlineStatus, { bg: string; dot: string; label: string }> = {
  online: { bg: 'bg-green-50 border-green-200', dot: '🟢', label: 'Online' },
  warning: { bg: 'bg-yellow-50 border-yellow-200', dot: '🟡', label: 'Offline >5p' },
  offline: { bg: 'bg-red-50 border-red-200', dot: '🔴', label: 'Offline >1ó' },
};

function resolveOnlineStatus(lastSyncAt: string | null): BranchOnlineStatus {
  if (!lastSyncAt) return 'offline';
  const elapsed = Date.now() - new Date(lastSyncAt).getTime();
  if (elapsed < WARNING_THRESHOLD_MS) return 'online';
  if (elapsed < OFFLINE_THRESHOLD_MS) return 'warning';
  return 'offline';
}

function formatHuf(amount: number): string {
  return amount.toLocaleString('hu-HU', { maximumFractionDigits: 0 });
}

function formatLastSync(lastSyncAt: string | null): string {
  if (!lastSyncAt) return 'Soha';
  const date = new Date(lastSyncAt);
  return date.toLocaleString('hu-HU', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}

// --- Mock adat (amíg nincs API) ---
function generateMockBranches(): SubordinateBranch[] {
  return [
    {
      code: '101', name: 'Szeged Kárász u.', companyId: -1,
      lastSyncAt: new Date(Date.now() - 60_000).toISOString(),
      onlineStatus: 'online', cashBalances: [], totalHufValue: 2_450_000, dailyTurnover: 850_000,
    },
    {
      code: '102', name: 'Szeged Dugonics tér', companyId: -1,
      lastSyncAt: new Date(Date.now() - 8 * 60_000).toISOString(),
      onlineStatus: 'warning', cashBalances: [], totalHufValue: 1_800_000, dailyTurnover: 620_000,
    },
    {
      code: '103', name: 'Szeged Árkád', companyId: -1,
      lastSyncAt: new Date(Date.now() - 90 * 60_000).toISOString(),
      onlineStatus: 'offline', cashBalances: [], totalHufValue: 3_100_000, dailyTurnover: 0,
    },
    {
      code: '151', name: 'Szeged Klauzál tér', companyId: -4,
      lastSyncAt: new Date(Date.now() - 30_000).toISOString(),
      onlineStatus: 'online', cashBalances: [], totalHufValue: 1_200_000, dailyTurnover: 430_000,
    },
  ];
}

// --- Egyszerű oszlopdiagram (div-based) ---
function BarChart({ data }: { data: Array<{ label: string; value: number }> }) {
  const maxValue = Math.max(...data.map((d) => d.value), 1);

  return (
    <div className="flex items-end gap-2" style={{ height: 120 }}>
      {data.map((item) => {
        const height = Math.max((item.value / maxValue) * 100, 4);
        return (
          <div key={item.label} className="flex flex-1 flex-col items-center gap-1">
            <span className="text-xs text-gray-500">{formatHuf(item.value)}</span>
            <div
              className="w-full rounded-t bg-blue-500 transition-all duration-300"
              style={{ height: `${height}%` }}
            />
            <span className="text-xs font-medium text-gray-700">{item.label}</span>
          </div>
        );
      })}
    </div>
  );
}

// --- Fő komponens ---
export default function ErtektarDashboard() {
  const navigate = useNavigate();
  const { companyType, branchCode } = useAuthStore();
  const [branches, setBranches] = useState<SubordinateBranch[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isOfflineData, setIsOfflineData] = useState(false);
  const [offlineTimestamp, setOfflineTimestamp] = useState<string | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const { isOnline } = useOnlineStatus();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const loadBranches = useCallback(async () => {
    try {
      if (!isOnline && window.electronAPI) {
        // OFFLINE mód — cached_branch_status-ból töltünk
        const cachedStatuses = await window.electronAPI.getCachedBranchStatuses();
        const timestamp = await window.electronAPI.getCachedBranchStatusTimestamp();

        if (cachedStatuses.length > 0) {
          const offlineBranches: SubordinateBranch[] = cachedStatuses.map((cs) => ({
            code: cs.branch_code,
            name: cs.branch_name,
            companyId: cs.company_id ?? -1,
            lastSyncAt: cs.last_sync_at,
            onlineStatus: resolveOnlineStatus(cs.last_sync_at),
            cashBalances: [],
            totalHufValue: cs.total_huf_value,
            dailyTurnover: cs.daily_turnover,
          }));
          setBranches(offlineBranches);
          setIsOfflineData(true);
          setOfflineTimestamp(timestamp);
        } else {
          // Ha nincs cached adat sem → fallback mock
          const mockData = generateMockBranches();
          const updated = mockData.map((b) => ({
            ...b,
            onlineStatus: resolveOnlineStatus(b.lastSyncAt),
          }));
          setBranches(updated);
          setIsOfflineData(true);
          setOfflineTimestamp(null);
        }
      } else {
        // ONLINE mód — API hívás (vagy mock ha nincs API)
        // TODO(api): Valódi API hívás — GET /api/v1/ertektar/branches — backend Értéktár modul szükséges
        const mockData = generateMockBranches();
        const updated = mockData.map((b) => ({
          ...b,
          onlineStatus: resolveOnlineStatus(b.lastSyncAt),
        }));
        setBranches(updated);
        setIsOfflineData(false);
        setOfflineTimestamp(null);
      }
    } catch (err) {
      console.error('[ÉrtéktárDashboard] Betöltési hiba:', err);
    } finally {
      setIsLoading(false);
    }
  }, [isOnline]);

  useEffect(() => {
    void loadBranches();
    intervalRef.current = setInterval(() => {
      void loadBranches();
    }, REFRESH_INTERVAL_MS);

    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [loadBranches]);

  // Összesítések
  const totalHufValue = branches.reduce((sum, b) => sum + b.totalHufValue, 0);
  const totalDailyTurnover = branches.reduce((sum, b) => sum + b.dailyTurnover, 0);
  const onlineCount = branches.filter((b) => b.onlineStatus === 'online').length;
  const warningCount = branches.filter((b) => b.onlineStatus === 'warning').length;
  const offlineCount = branches.filter((b) => b.onlineStatus === 'offline').length;

  const chartData = branches.map((b) => ({
    label: b.code,
    value: b.dailyTurnover,
  }));

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <p className="text-gray-500">⏳ Betöltés...</p>
      </div>
    );
  }

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-4 text-white shadow-lg`}>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">
              {isBestChange ? '💱 Best Change' : '💎 Expressz'} — Értéktár
            </h1>
            <p className="text-sm text-white/80">Értéktár kód: {branchCode}</p>
          </div>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm font-medium text-white transition hover:bg-white/30"
          >
            ← Vissza a menübe
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        {/* Offline figyelmeztető sáv */}
        {isOfflineData && (
          <div className="mb-4 rounded-lg border-2 border-yellow-400 bg-yellow-50 p-3 text-center">
            <p className="font-bold text-yellow-800">
              📡 Offline adatok
              {offlineTimestamp && (
                <span className="ml-2 font-normal text-yellow-700">
                  (utolsó frissítés: {new Date(offlineTimestamp).toLocaleString('hu-HU', { hour: '2-digit', minute: '2-digit' })})
                </span>
              )}
            </p>
          </div>
        )}

        {/* Összesítő kártyák */}
        <div className="mb-6 grid grid-cols-4 gap-4">
          <div className="rounded-lg border bg-white p-4 shadow-sm">
            <p className="text-sm text-gray-500">Összes készlet</p>
            <p className="text-2xl font-bold text-gray-900">{formatHuf(totalHufValue)} Ft</p>
          </div>
          <div className="rounded-lg border bg-white p-4 shadow-sm">
            <p className="text-sm text-gray-500">Napi forgalom</p>
            <p className="text-2xl font-bold text-blue-600">{formatHuf(totalDailyTurnover)} Ft</p>
          </div>
          <div className="rounded-lg border bg-white p-4 shadow-sm">
            <p className="text-sm text-gray-500">Pénztárak</p>
            <p className="text-lg font-bold">
              <span className="text-green-600">{onlineCount} 🟢</span>
              {warningCount > 0 && <span className="ml-2 text-yellow-600">{warningCount} 🟡</span>}
              {offlineCount > 0 && <span className="ml-2 text-red-600">{offlineCount} 🔴</span>}
            </p>
          </div>
          <div className="rounded-lg border bg-white p-4 shadow-sm">
            <p className="text-sm text-gray-500">Összesen</p>
            <p className="text-2xl font-bold text-gray-900">{branches.length} pénztár</p>
          </div>
        </div>

        {/* Napi forgalom diagram */}
        <div className="mb-6 rounded-lg border bg-white p-4 shadow-sm">
          <h2 className="mb-4 text-lg font-semibold text-gray-700">📊 Napi forgalom pénztáranként</h2>
          <BarChart data={chartData} />
        </div>

        {/* Pénztár kártyák */}
        <h2 className="mb-4 text-lg font-semibold text-gray-700">🏦 Alárendelt pénztárak</h2>
        <div className="grid grid-cols-2 gap-4">
          {branches.map((branch) => {
            const status = STATUS_COLORS[branch.onlineStatus];
            return (
              <div
                key={branch.code}
                className={`rounded-lg border-2 p-4 shadow-sm ${status.bg}`}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-lg font-bold text-gray-800">
                      {status.dot} {branch.name}
                    </h3>
                    <p className="text-sm text-gray-500">Kód: {branch.code}</p>
                  </div>
                  <span className="rounded-full bg-white px-3 py-1 text-xs font-medium text-gray-700 shadow-sm">
                    {status.label}
                  </span>
                </div>
                <div className="mt-3 grid grid-cols-3 gap-2 text-sm">
                  <div>
                    <p className="text-gray-500">Készlet</p>
                    <p className="font-semibold">{formatHuf(branch.totalHufValue)} Ft</p>
                  </div>
                  <div>
                    <p className="text-gray-500">Napi forgalom</p>
                    <p className="font-semibold">{formatHuf(branch.dailyTurnover)} Ft</p>
                  </div>
                  <div>
                    <p className="text-gray-500">Utolsó sync</p>
                    <p className="font-semibold">{formatLastSync(branch.lastSyncAt)}</p>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </main>
    </div>
  );
}
