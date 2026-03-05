import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { getDashboardSummary, type DashboardSummary } from '@/api/dashboard';
import { getUnreadNotifications, type NotificationData } from '@/api/notifications';

export default function DashboardPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [notifications, setNotifications] = useState<NotificationData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [sum, notifs] = await Promise.all([
        getDashboardSummary(),
        getUnreadNotifications(),
      ]);
      setSummary(sum);
      setNotifications(notifs);
    } catch {
      setError('Dashboard adatok betöltése sikertelen.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const formatHuf = (n: number | undefined) =>
    (n ?? 0).toLocaleString('hu-HU', { maximumFractionDigits: 0 }) + ' Ft';

  // Currency bar chart max value
  const currencyEntries = summary ? Object.entries(summary.currencyVolumes) : [];
  const maxVolume = currencyEntries.reduce((max, [, v]) => Math.max(max, v), 1);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">📊 Dashboard</h1>
          <button onClick={() => navigate('/menu')} className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-6xl">
          {error && <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">⚠️ {error}</div>}

          {loading ? (
            <p className="text-gray-500">⏳ Dashboard betöltése...</p>
          ) : summary ? (
            <>
              {/* 4 Summary cards */}
              <div className="mb-6 grid grid-cols-4 gap-4">
                <div className="rounded-xl border bg-white p-4 text-center shadow-sm">
                  <div className="text-3xl">💰</div>
                  <div className="mt-2 text-2xl font-bold text-blue-600">{formatHuf(summary.todayVolume)}</div>
                  <div className="text-sm text-gray-500">Mai forgalom</div>
                </div>
                <div className="rounded-xl border bg-white p-4 text-center shadow-sm">
                  <div className="text-3xl">🏦</div>
                  <div className="mt-2 text-2xl font-bold text-green-600">{summary.activeBranches}</div>
                  <div className="text-sm text-gray-500">Aktív irodák</div>
                </div>
                <div className="rounded-xl border bg-white p-4 text-center shadow-sm">
                  <div className="text-3xl">📋</div>
                  <div className="mt-2 text-2xl font-bold text-purple-600">{summary.openTransactions}</div>
                  <div className="text-sm text-gray-500">Napi tranzakciók</div>
                </div>
                <div className="rounded-xl border bg-white p-4 text-center shadow-sm">
                  <div className="text-3xl">🔔</div>
                  <div className={`mt-2 text-2xl font-bold ${summary.alertCount > 0 ? 'text-red-600' : 'text-gray-400'}`}>
                    {summary.alertCount}
                  </div>
                  <div className="text-sm text-gray-500">Riasztások</div>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-6">
                {/* Currency volume bars */}
                <div className="rounded-xl border bg-white p-6">
                  <h3 className="mb-4 font-semibold text-gray-700">📈 Valutánkénti forgalom</h3>
                  {currencyEntries.length === 0 ? (
                    <p className="text-gray-400 text-sm">Nincs mai forgalom.</p>
                  ) : (
                    <div className="space-y-2">
                      {currencyEntries
                        .sort((a, b) => b[1] - a[1])
                        .map(([code, volume]) => (
                          <div key={code} className="flex items-center gap-3">
                            <span className="w-10 text-sm font-medium text-gray-600">{code}</span>
                            <div className="flex-1">
                              <div
                                className="h-5 rounded bg-blue-400"
                                style={{ width: `${Math.max((volume / maxVolume) * 100, 2)}%` }}
                              />
                            </div>
                            <span className="w-28 text-right text-xs text-gray-500">{formatHuf(volume)}</span>
                          </div>
                        ))}
                    </div>
                  )}
                </div>

                {/* Recent transactions */}
                <div className="rounded-xl border bg-white p-6">
                  <h3 className="mb-4 font-semibold text-gray-700">🕐 Utolsó tranzakciók</h3>
                  {summary.recentTransactions.length === 0 ? (
                    <p className="text-gray-400 text-sm">Nincs mai tranzakció.</p>
                  ) : (
                    <div className="space-y-2">
                      {summary.recentTransactions.map((tx) => (
                        <div key={tx.id} className="flex items-center justify-between rounded border px-3 py-2 text-sm">
                          <div>
                            <span className={`font-medium ${tx.type === 'SELL' ? 'text-red-600' : 'text-green-600'}`}>
                              {tx.type === 'SELL' ? 'E' : 'V'}
                            </span>
                            {' '}{tx.receiptNumber}
                          </div>
                          <div className="text-gray-500">
                            {tx.amount?.toLocaleString()} {tx.currencyCode}
                          </div>
                          <div className="text-gray-400">{formatHuf(tx.hufAmount)}</div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Sync status per branch */}
                <div className="rounded-xl border bg-white p-6">
                  <h3 className="mb-4 font-semibold text-gray-700">🔄 Szinkronizáció státusz</h3>
                  {summary.branchSyncStatuses.length === 0 ? (
                    <p className="text-gray-400 text-sm">Nincs iroda adat.</p>
                  ) : (
                    <div className="space-y-2">
                      {summary.branchSyncStatuses.map((bs) => (
                        <div key={bs.branchCode} className="flex items-center justify-between rounded border px-3 py-2 text-sm">
                          <div className="font-medium">{bs.branchCode} — {bs.branchName}</div>
                          <span className={`rounded-full px-2 py-0.5 text-xs ${
                            bs.status === 'OK' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                          }`}>
                            {bs.status === 'OK' ? '🟢 OK' : '🔴 Hiba'}
                          </span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Notifications */}
                <div className="rounded-xl border bg-white p-6">
                  <h3 className="mb-4 font-semibold text-gray-700">🔔 Rendszer értesítések</h3>
                  {notifications.length === 0 ? (
                    <p className="text-gray-400 text-sm">Nincs olvasatlan értesítés.</p>
                  ) : (
                    <div className="space-y-2">
                      {notifications.slice(0, 10).map((n) => (
                        <div key={n.id} className="rounded border px-3 py-2 text-sm">
                          <div className="flex justify-between">
                            <span className="font-medium">{n.title}</span>
                            <span className="text-xs text-gray-400">
                              {new Date(n.createdAt).toLocaleString('hu-HU')}
                            </span>
                          </div>
                          <div className="text-xs text-gray-500 mt-0.5">{n.message}</div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </>
          ) : null}
        </div>
      </main>
    </div>
  );
}
