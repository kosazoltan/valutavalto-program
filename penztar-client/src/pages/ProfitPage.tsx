import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  getDailyProfit,
  getMonthlyProfit,
  type ProfitReportResponse,
  type ProfitCurrencyEntry,
} from '@/api/profit';

type PeriodType = 'daily' | 'monthly';

function formatHuf(value: number): string {
  return new Intl.NumberFormat('hu-HU', {
    style: 'currency',
    currency: 'HUF',
    maximumFractionDigits: 0,
  }).format(value);
}

function getTodayStr(): string {
  return new Date().toISOString().slice(0, 10);
}

function getCurrentYearMonth(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

export default function ProfitPage() {
  const navigate = useNavigate();
  const { user } = useAuthStore();

  const [periodType, setPeriodType] = useState<PeriodType>('daily');
  const [branchId, setBranchId] = useState('');
  const [date, setDate] = useState(getTodayStr());
  const [month, setMonth] = useState(getCurrentYearMonth());
  const [report, setReport] = useState<ProfitReportResponse | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLoad = useCallback(async () => {
    if (!branchId) {
      setError('Kérjük, adja meg az iroda azonosítót!');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const data =
        periodType === 'daily'
          ? await getDailyProfit(branchId, date)
          : await getMonthlyProfit(branchId, month);
      setReport(data);
    } catch {
      setReport(null);
      setError('Nem sikerült betölteni a haszon adatokat.');
    } finally {
      setLoading(false);
    }
  }, [branchId, periodType, date, month]);

  // Egyszerű div-based oszlopdiagram
  const maxProfit = report
    ? Math.max(
        ...report.profitByCurrency.map((c) => Math.abs(c.profit)),
        1,
      )
    : 1;

  return (
    <div className="flex h-screen flex-col">
      <header className="bg-emerald-600 px-6 py-4 text-white shadow-lg">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">📈 Haszon számítás</h1>
            <p className="text-sm text-white/80">
              {user?.fullName ?? 'Felhasználó'} | Bevétel, kiadás, haszon elemzés
            </p>
          </div>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm font-medium text-white transition hover:bg-white/30"
          >
            ← Vissza
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-5xl space-y-6">
          {/* Időszak választó */}
          <div className="rounded-lg border bg-white p-4 shadow-sm">
            <div className="flex flex-wrap items-end gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">Iroda ID</label>
                <input
                  type="text"
                  value={branchId}
                  onChange={(e) => setBranchId(e.target.value)}
                  placeholder="pl. 550e8400-e29b-..."
                  className="w-72 rounded border px-3 py-2 text-sm"
                />
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => setPeriodType('daily')}
                  className={`rounded px-3 py-2 text-sm font-medium ${
                    periodType === 'daily'
                      ? 'bg-emerald-500 text-white'
                      : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                  }`}
                >
                  📅 Napi
                </button>
                <button
                  onClick={() => setPeriodType('monthly')}
                  className={`rounded px-3 py-2 text-sm font-medium ${
                    periodType === 'monthly'
                      ? 'bg-emerald-500 text-white'
                      : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                  }`}
                >
                  📊 Havi
                </button>
              </div>
              {periodType === 'daily' ? (
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">Dátum</label>
                  <input
                    type="date"
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                    className="rounded border px-3 py-2 text-sm"
                  />
                </div>
              ) : (
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">Hónap</label>
                  <input
                    type="month"
                    value={month}
                    onChange={(e) => setMonth(e.target.value)}
                    className="rounded border px-3 py-2 text-sm"
                  />
                </div>
              )}
              <button
                onClick={() => void handleLoad()}
                disabled={loading}
                className="rounded bg-emerald-500 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-600 disabled:opacity-50"
              >
                📊 Számítás
              </button>
            </div>
          </div>

          {error && (
            <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700">
              ⚠️ {error}
            </div>
          )}

          {/* Összesítő kártyák */}
          {report && (
            <div className="grid grid-cols-4 gap-4">
              <div className="rounded-lg border bg-green-50 p-4">
                <div className="text-sm text-green-600">Bevétel (spread)</div>
                <div className={`text-xl font-bold ${report.revenue >= 0 ? 'text-green-800' : 'text-red-800'}`}>
                  {formatHuf(report.revenue)}
                </div>
              </div>
              <div className="rounded-lg border bg-red-50 p-4">
                <div className="text-sm text-red-600">Kiadás (díjak)</div>
                <div className="text-xl font-bold text-red-800">
                  {formatHuf(report.expenses)}
                </div>
              </div>
              <div className="rounded-lg border bg-blue-50 p-4">
                <div className="text-sm text-blue-600">Bruttó haszon</div>
                <div className={`text-xl font-bold ${report.grossProfit >= 0 ? 'text-blue-800' : 'text-red-800'}`}>
                  {formatHuf(report.grossProfit)}
                </div>
              </div>
              <div className="rounded-lg border bg-purple-50 p-4">
                <div className="text-sm text-purple-600">Nettó haszon</div>
                <div className={`text-xl font-bold ${report.netProfit >= 0 ? 'text-purple-800' : 'text-red-800'}`}>
                  {formatHuf(report.netProfit)}
                </div>
              </div>
            </div>
          )}

          {/* Valutánkénti bontás */}
          {report && report.profitByCurrency.length > 0 && (
            <div className="rounded-lg border bg-white shadow-sm">
              <div className="border-b px-4 py-3">
                <h2 className="font-semibold text-gray-800">💱 Valutánkénti bontás</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left">Valuta</th>
                      <th className="px-4 py-2 text-right">Vétel db</th>
                      <th className="px-4 py-2 text-right">Eladás db</th>
                      <th className="px-4 py-2 text-right">Vétel HUF</th>
                      <th className="px-4 py-2 text-right">Eladás HUF</th>
                      <th className="px-4 py-2 text-right">Bevétel</th>
                      <th className="px-4 py-2 text-right">Díj</th>
                      <th className="px-4 py-2 text-right">Haszon</th>
                    </tr>
                  </thead>
                  <tbody>
                    {report.profitByCurrency.map((entry: ProfitCurrencyEntry) => (
                      <tr key={entry.currencyCode} className="border-t hover:bg-gray-50">
                        <td className="px-4 py-2 font-medium">{entry.currencyCode}</td>
                        <td className="px-4 py-2 text-right">{entry.buyCount}</td>
                        <td className="px-4 py-2 text-right">{entry.sellCount}</td>
                        <td className="px-4 py-2 text-right">{formatHuf(entry.buyHuf)}</td>
                        <td className="px-4 py-2 text-right">{formatHuf(entry.sellHuf)}</td>
                        <td className="px-4 py-2 text-right">{formatHuf(entry.revenue)}</td>
                        <td className="px-4 py-2 text-right">{formatHuf(entry.fees)}</td>
                        <td className={`px-4 py-2 text-right font-bold ${entry.profit >= 0 ? 'text-green-700' : 'text-red-700'}`}>
                          {formatHuf(entry.profit)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Egyszerű oszlopdiagram */}
          {report && report.profitByCurrency.length > 0 && (
            <div className="rounded-lg border bg-white p-4 shadow-sm">
              <h2 className="mb-4 font-semibold text-gray-800">📊 Haszon diagram</h2>
              <div className="flex items-end gap-2" style={{ height: '200px' }}>
                {report.profitByCurrency.map((entry: ProfitCurrencyEntry) => {
                  const barHeight = Math.max(
                    Math.abs(entry.profit) / maxProfit * 160,
                    4,
                  );
                  const isPositive = entry.profit >= 0;
                  return (
                    <div key={entry.currencyCode} className="flex flex-1 flex-col items-center">
                      <div className="mb-1 text-xs font-medium">
                        {formatHuf(entry.profit)}
                      </div>
                      <div
                        className={`w-full max-w-[40px] rounded-t ${isPositive ? 'bg-emerald-500' : 'bg-red-500'}`}
                        style={{ height: `${barHeight}px` }}
                      />
                      <div className="mt-1 text-xs text-gray-600">{entry.currencyCode}</div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
