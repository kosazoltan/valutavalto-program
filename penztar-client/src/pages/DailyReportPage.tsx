import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { generateDailyReport, getDailyReport } from '@/api/dailyReport';
import type { DailyReportData } from '@/types';

function formatDate(d: Date): string {
  return d.toISOString().split('T')[0] ?? '';
}

function formatHuf(n: number): string {
  return n.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

interface CurrencyBreakdown {
  [key: string]: {
    buy?: number;
    buyHuf?: number;
    sell?: number;
    sellHuf?: number;
    fee?: number;
  };
}

export default function DailyReportPage() {
  const navigate = useNavigate();
  const { companyType, branchCode } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [date, setDate] = useState(formatDate(new Date()));
  const [report, setReport] = useState<DailyReportData | null>(null);
  const [breakdown, setBreakdown] = useState<CurrencyBreakdown>({});
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const parseReportData = useCallback((data: string | null) => {
    if (!data) return {};
    try {
      return JSON.parse(data) as CurrencyBreakdown;
    } catch {
      return {};
    }
  }, []);

  const handleGenerate = useCallback(async () => {
    if (!branchCode) return;
    setIsLoading(true);
    setError('');
    try {
      const data = await generateDailyReport(branchCode, date);
      setReport(data);
      setBreakdown(parseReportData(data.reportData));
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Hiba a jelentés generálásakor';
      setError(`❌ ${msg}`);
    } finally {
      setIsLoading(false);
    }
  }, [branchCode, date, parseReportData]);

  const handleFetch = useCallback(async () => {
    if (!branchCode) return;
    setIsLoading(true);
    setError('');
    try {
      const data = await getDailyReport(branchCode, date);
      setReport(data);
      setBreakdown(parseReportData(data.reportData));
    } catch {
      // Ha nincs korábbi — generálunk
      void handleGenerate();
    } finally {
      setIsLoading(false);
    }
  }, [branchCode, date, parseReportData, handleGenerate]);

  useEffect(() => {
    void handleFetch();
  }, [handleFetch]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const handlePrint = () => {
    window.print();
  };

  const currencyEntries = Object.entries(breakdown);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white print:hidden`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">📋 Napi jelentés</h1>
          <div className="flex items-center gap-3">
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="rounded-lg border border-white/30 bg-white/10 px-3 py-1 text-sm text-white"
            />
            <button
              onClick={() => void handleGenerate()}
              disabled={isLoading}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30 disabled:opacity-50"
            >
              {isLoading ? '⏳ Generálás...' : '🔄 Generálás'}
            </button>
            <button
              onClick={() => navigate('/menu')}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
            >
              ← Vissza (ESC)
            </button>
          </div>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-5xl space-y-6">
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700 print:hidden">{error}</div>
          )}

          {report && (
            <>
              {/* Összesítő fejléc */}
              <div className="rounded-xl border-2 border-blue-200 bg-blue-50 p-6">
                <div className="mb-4 flex items-center justify-between">
                  <h2 className="text-lg font-semibold text-blue-800">
                    📊 Napi összesítő — {report.branchName ?? report.branchCode}
                  </h2>
                  <span className="text-sm text-blue-600">{report.reportDate}</span>
                </div>
                <div className="grid grid-cols-5 gap-4">
                  <div className="rounded-lg bg-white p-3">
                    <p className="text-xs text-gray-500">Tranzakciók</p>
                    <p className="text-2xl font-bold text-gray-800">{report.transactionCount}</p>
                  </div>
                  <div className="rounded-lg bg-white p-3">
                    <p className="text-xs text-gray-500">Vétel (Ft)</p>
                    <p className="text-lg font-bold text-green-700">{formatHuf(report.totalBuyHuf)}</p>
                  </div>
                  <div className="rounded-lg bg-white p-3">
                    <p className="text-xs text-gray-500">Eladás (Ft)</p>
                    <p className="text-lg font-bold text-blue-700">{formatHuf(report.totalSellHuf)}</p>
                  </div>
                  <div className="rounded-lg bg-white p-3">
                    <p className="text-xs text-gray-500">Kezelési díj (Ft)</p>
                    <p className="text-lg font-bold text-orange-700">{formatHuf(report.totalFeeHuf)}</p>
                  </div>
                  <div className="rounded-lg bg-white p-3">
                    <p className="text-xs text-gray-500">Profit (Ft)</p>
                    <p className={`text-lg font-bold ${report.totalProfit >= 0 ? 'text-green-700' : 'text-red-700'}`}>
                      {formatHuf(report.totalProfit)}
                    </p>
                  </div>
                </div>
              </div>

              {/* Valutánkénti bontás */}
              <div className="overflow-hidden rounded-xl border bg-white">
                <div className="border-b bg-gray-50 px-4 py-3">
                  <h3 className="text-lg font-semibold text-gray-700">💱 Forgalom valutánként</h3>
                </div>
                <table className="w-full">
                  <thead>
                    <tr className="border-b bg-gray-50 text-left text-sm font-medium text-gray-600">
                      <th className="px-4 py-3">Valuta</th>
                      <th className="px-4 py-3 text-right">Vétel (deviza)</th>
                      <th className="px-4 py-3 text-right">Vétel (Ft)</th>
                      <th className="px-4 py-3 text-right">Eladás (deviza)</th>
                      <th className="px-4 py-3 text-right">Eladás (Ft)</th>
                      <th className="px-4 py-3 text-right">Kezelési díj</th>
                    </tr>
                  </thead>
                  <tbody>
                    {currencyEntries.map(([code, data]) => (
                      <tr key={code} className="border-b transition hover:bg-gray-50">
                        <td className="px-4 py-3 font-semibold">{code}</td>
                        <td className="px-4 py-3 text-right font-mono">
                          {data.buy != null ? formatHuf(data.buy) : '—'}
                        </td>
                        <td className="px-4 py-3 text-right font-mono text-green-700">
                          {data.buyHuf != null ? formatHuf(data.buyHuf) : '—'}
                        </td>
                        <td className="px-4 py-3 text-right font-mono">
                          {data.sell != null ? formatHuf(data.sell) : '—'}
                        </td>
                        <td className="px-4 py-3 text-right font-mono text-blue-700">
                          {data.sellHuf != null ? formatHuf(data.sellHuf) : '—'}
                        </td>
                        <td className="px-4 py-3 text-right font-mono text-orange-600">
                          {data.fee != null ? formatHuf(data.fee) : '—'}
                        </td>
                      </tr>
                    ))}
                    {currencyEntries.length === 0 && (
                      <tr>
                        <td colSpan={6} className="px-4 py-8 text-center text-gray-400">
                          Nincs forgalmi adat erre a napra.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>

              {/* Státusz */}
              <div className="rounded-lg border bg-gray-50 p-4">
                <div className="flex items-center justify-between">
                  <div className="text-sm text-gray-600">
                    {report.submitted ? (
                      <span className="text-green-700">
                        ✅ Beküldve: {report.submittedAt ?? '—'} ({report.submittedByName ?? '—'})
                      </span>
                    ) : (
                      <span className="text-yellow-700">⏳ Még nincs beküldve</span>
                    )}
                  </div>
                  <button
                    onClick={handlePrint}
                    className="rounded-lg bg-gray-700 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800 print:hidden"
                  >
                    🖨️ Nyomtatás
                  </button>
                </div>
              </div>
            </>
          )}

          {!report && !isLoading && (
            <div className="rounded-xl border-2 border-dashed border-gray-300 p-12 text-center">
              <p className="text-lg text-gray-400">Válassz dátumot és kattints a "Generálás" gombra!</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
