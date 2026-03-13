import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { getCashBalanceSummary, getCompanyTotals } from '@/api/cash';
import { getCurrencyInfo } from '@/utils/currencies';
import { regenerateInventory } from '@/api/inventoryRegeneration';
import type { CashBalanceSummary, CompanyTotals, RegenerationResult } from '@/types';

export default function StockPage() {
  const navigate = useNavigate();
  const { companyType, branchCode } = useAuthStore();

  const [balances, setBalances] = useState<CashBalanceSummary[]>([]);
  const [totals, setTotals] = useState<CompanyTotals | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [lastRefresh, setLastRefresh] = useState<Date | null>(null);
  const [regenResult, setRegenResult] = useState<RegenerationResult | null>(null);
  const [isRegenerating, setIsRegenerating] = useState(false);

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const isOnline = navigator.onLine;

  const fetchData = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const [balanceData, totalData] = await Promise.all([
        getCashBalanceSummary(),
        getCompanyTotals(),
      ]);
      setBalances(balanceData);
      setTotals(totalData);
      setLastRefresh(new Date());
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Készlet lekérési hiba';
      setError(`❌ ${message}`);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const handleRegenerate = useCallback(async () => {
    if (!branchCode) return;
    setIsRegenerating(true);
    setRegenResult(null);
    try {
      const result = await regenerateInventory(branchCode);
      setRegenResult(result);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Regenerálási hiba';
      setError(`❌ ${message}`);
    } finally {
      setIsRegenerating(false);
    }
  }, [branchCode]);

  useEffect(() => {
    void fetchData();
  }, [fetchData]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        navigate('/menu');
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const hufBalance = balances.find((b) => b.currencyCode === 'HUF');
  const foreignBalances = balances.filter((b) => b.currencyCode !== 'HUF');
  const totalHufValue = totals?.totalHufValue ?? 0;

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">📦 Készlet</h1>
          <div className="flex items-center gap-4">
            <span className="text-sm">
              {isOnline ? (
                <span className="text-green-200">🟢 Online</span>
              ) : (
                <span className="text-red-200">🔴 Offline</span>
              )}
            </span>
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
          {/* Forint készlet kiemelve */}
          {hufBalance && (
            <div className="rounded-xl border-2 border-green-300 bg-green-50 p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-green-700">🇭🇺 Forint készlet</p>
                  <p className="text-4xl font-bold text-green-800">
                    {hufBalance.amount.toLocaleString('hu-HU')} Ft
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-green-600">
                    Bankjegy: {hufBalance.banknoteCount.toLocaleString('hu-HU')} db
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Összérték */}
          <div className="rounded-xl border bg-blue-50 p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-blue-600">Teljes készletérték (forintban)</p>
                <p className="text-2xl font-bold text-blue-800">
                  {totalHufValue.toLocaleString('hu-HU')} Ft
                </p>
              </div>
              <div className="flex items-center gap-3">
                {lastRefresh && (
                  <p className="text-xs text-gray-500">
                    Frissítve: {lastRefresh.toLocaleTimeString('hu-HU')}
                  </p>
                )}
                <button
                  onClick={() => void fetchData()}
                  disabled={isLoading}
                  className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                >
                  {isLoading ? '⏳ Frissítés...' : '🔄 Frissítés'}
                </button>
              </div>
            </div>
          </div>

          {/* Készlet regenerálás */}
          <div className="rounded-xl border bg-amber-50 p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-amber-700">🔄 Készlet regenerálás</p>
                <p className="text-xs text-amber-600">
                  Újraszámolja a készletet a tranzakciók alapján (supervisor jogosultság)
                </p>
              </div>
              <button
                onClick={() => void handleRegenerate()}
                disabled={isRegenerating}
                className="rounded-lg bg-amber-600 px-4 py-2 text-sm font-medium text-white hover:bg-amber-700 disabled:opacity-50"
              >
                {isRegenerating ? '⏳ Regenerálás...' : '🔄 Regenerálás'}
              </button>
            </div>
            {regenResult && (
              <div className="mt-3 rounded-lg bg-white p-3">
                <p className="text-sm font-medium">
                  Eredmény: {regenResult.discrepancyCount} eltérés, {regenResult.correctedCount} javított valuta
                </p>
                {regenResult.discrepancies && regenResult.discrepancies.length > 0 && (
                  <div className="mt-2">
                    <p className="text-xs font-semibold text-red-600">Eltérések:</p>
                    {regenResult.discrepancies.map((d) => (
                      <p key={d.currencyCode} className="text-xs text-red-500">
                        {d.currencyCode}: elvárt {d.expectedAmount}, jelenlegi {d.actualAmount}, eltérés {d.difference}
                      </p>
                    ))}
                  </div>
                )}
                {regenResult.discrepancyCount === 0 && (
                  <p className="text-xs text-green-600">✅ Nincs eltérés — a készlet konzisztens.</p>
                )}
              </div>
            )}
          </div>

          {/* Hiba */}
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>
          )}

          {/* Valuta készlet táblázat */}
          <div className="overflow-hidden rounded-xl border bg-white">
            <table className="w-full">
              <thead>
                <tr className="border-b bg-gray-50 text-left text-sm font-medium text-gray-600">
                  <th className="px-4 py-3">Valuta</th>
                  <th className="px-4 py-3 text-right">Bankjegy (db)</th>
                  <th className="px-4 py-3 text-right">Összeg</th>
                  <th className="px-4 py-3 text-right">Árfolyam</th>
                  <th className="px-4 py-3 text-right">Forint érték</th>
                </tr>
              </thead>
              <tbody>
                {foreignBalances.map((balance) => {
                  const info = balance.currencyCode !== 'HUF'
                    ? getCurrencyInfo(balance.currencyCode)
                    : undefined;
                  return (
                    <tr
                      key={balance.currencyCode}
                      className="border-b transition hover:bg-gray-50"
                    >
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <span className="text-lg">{info?.flag ?? '💰'}</span>
                          <div>
                            <p className="font-medium">{balance.currencyCode}</p>
                            <p className="text-xs text-gray-500">{info?.name ?? ''}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-right font-mono">
                        {balance.banknoteCount.toLocaleString('hu-HU')}
                      </td>
                      <td className="px-4 py-3 text-right font-mono font-semibold">
                        {balance.amount.toLocaleString('hu-HU', {
                          minimumFractionDigits: 2,
                          maximumFractionDigits: 2,
                        })}
                      </td>
                      <td className="px-4 py-3 text-right font-mono text-gray-600">
                        {balance.rate > 0
                          ? balance.rate.toLocaleString('hu-HU', {
                              minimumFractionDigits: 2,
                              maximumFractionDigits: 2,
                            })
                          : '—'}
                      </td>
                      <td className="px-4 py-3 text-right font-mono font-semibold text-blue-700">
                        {balance.hufValue.toLocaleString('hu-HU')} Ft
                      </td>
                    </tr>
                  );
                })}
                {foreignBalances.length === 0 && !isLoading && (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-gray-400">
                      Nincs valutakészlet adat.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}


