import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { useRateStore } from '@/stores/rateStore';
import { getRateHistory } from '@/api/rates';
import { getForeignCurrencies, getCurrencyInfo } from '@/utils/currencies';
import type { CurrencyCode, ExchangeRateHistory } from '@/types';

export default function RatesPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const { rates, lastUpdate, fetchRates, isLoading: ratesLoading } = useRateStore();

  const [selectedCurrency, setSelectedCurrency] = useState<CurrencyCode | null>(null);
  const [history, setHistory] = useState<ExchangeRateHistory[]>([]);
  const [isLoadingHistory, setIsLoadingHistory] = useState(false);

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const currencies = useMemo(() => getForeignCurrencies(), []);

  // Load rates on mount
  useEffect(() => {
    if (rates.length === 0) {
      void fetchRates();
    }
  }, [rates.length, fetchRates]);

  // Load history when currency selected
  useEffect(() => {
    if (!selectedCurrency) {
      setHistory([]);
      return;
    }

    const loadHistory = async () => {
      setIsLoadingHistory(true);
      try {
        const to = new Date().toISOString().split('T')[0]!;
        const fromDate = new Date();
        fromDate.setDate(fromDate.getDate() - 30);
        const from = fromDate.toISOString().split('T')[0]!;
        const data = await getRateHistory(selectedCurrency, from, to);
        setHistory(data);
      } catch {
        setHistory([]);
      } finally {
        setIsLoadingHistory(false);
      }
    };

    void loadHistory();
  }, [selectedCurrency]);

  const handleRefresh = useCallback(() => {
    void fetchRates();
  }, [fetchRates]);

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

  // Egyszerű szöveges mini-grafikon az árfolyam történethez
  const historyChart = useMemo(() => {
    if (history.length < 2) return null;
    const buyRates = history.map((h) => h.buyRate);
    const minRate = Math.min(...buyRates);
    const maxRate = Math.max(...buyRates);
    const range = maxRate - minRate || 1;
    return history.map((h) => ({
      date: h.date,
      buyRate: h.buyRate,
      sellRate: h.sellRate,
      mnbRate: h.mnbMiddleRate,
      barHeight: Math.round(((h.buyRate - minRate) / range) * 100),
    }));
  }, [history]);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">📊 Árfolyamok</h1>
          <div className="flex items-center gap-4">
            {lastUpdate && (
              <span className="text-xs text-white/70">
                Frissítve: {new Date(lastUpdate).toLocaleTimeString('hu-HU')}
              </span>
            )}
            <button
              onClick={handleRefresh}
              disabled={ratesLoading}
              className="rounded-lg bg-white/20 px-3 py-1 text-sm hover:bg-white/30 disabled:opacity-50"
            >
              {ratesLoading ? '⏳...' : '🔄 Frissítés'}
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
        <div className="mx-auto max-w-6xl space-y-6">
          {/* Árfolyam táblázat */}
          <div className="overflow-hidden rounded-xl border bg-white">
            <table className="w-full">
              <thead>
                <tr className="border-b bg-gray-50 text-left text-sm font-medium text-gray-600">
                  <th className="px-4 py-3">Valuta</th>
                  <th className="px-4 py-3 text-right">Vétel</th>
                  <th className="px-4 py-3 text-right">Eladás</th>
                  <th className="px-4 py-3 text-right">Spread</th>
                  <th className="px-4 py-3 text-right">Utolsó frissítés</th>
                  <th className="px-4 py-3 text-center">Történet</th>
                </tr>
              </thead>
              <tbody>
                {currencies.map((c) => {
                  const rate = rates.find((r) => r.currencyCode === c.code);
                  const isSelected = selectedCurrency === c.code;
                  if (!rate) return null;

                  const spread = rate.sellRate - rate.buyRate;

                  return (
                    <tr
                      key={c.code}
                      className={`border-b transition ${
                        isSelected
                          ? 'bg-blue-50'
                          : 'hover:bg-gray-50'
                      }`}
                    >
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          <span className="text-lg">{c.flag}</span>
                          <div>
                            <p className="font-medium">{c.code}</p>
                            <p className="text-xs text-gray-500">
                              {c.name}
                              {c.unit > 1 && ` (${c.unit})`}
                            </p>
                          </div>
                        </div>
                      </td>
                      <td className="px-4 py-3 text-right font-mono font-semibold text-green-700">
                        {rate.buyRate.toFixed(2)}
                      </td>
                      <td className="px-4 py-3 text-right font-mono font-semibold text-red-700">
                        {rate.sellRate.toFixed(2)}
                      </td>
                      <td className="px-4 py-3 text-right font-mono text-sm text-gray-500">
                        {spread.toFixed(2)}
                      </td>
                      <td className="px-4 py-3 text-right text-xs text-gray-400">
                        {new Date(rate.updatedAt).toLocaleString('hu-HU', {
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </td>
                      <td className="px-4 py-3 text-center">
                        <button
                          onClick={() =>
                            setSelectedCurrency(
                              isSelected ? null : (c.code as CurrencyCode),
                            )
                          }
                          className={`rounded-lg px-3 py-1 text-xs font-medium transition ${
                            isSelected
                              ? 'bg-blue-600 text-white'
                              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                          }`}
                        >
                          {isSelected ? '✕ Bezár' : '📈 Történet'}
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          {/* Árfolyam történet */}
          {selectedCurrency && (
            <div className="rounded-xl border bg-white p-6">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-lg font-semibold text-gray-700">
                  📈 {getCurrencyInfo(selectedCurrency)?.flag ?? ''}{' '}
                  {selectedCurrency} — Árfolyam történet (30 nap)
                </h2>
                {isLoadingHistory && (
                  <span className="text-sm text-gray-400">⏳ Betöltés...</span>
                )}
              </div>

              {/* Mini bar chart */}
              {historyChart && historyChart.length > 0 ? (
                <div className="space-y-4">
                  {/* Grafikon */}
                  <div className="flex items-end gap-1 rounded-lg bg-gray-50 p-4" style={{ height: 200 }}>
                    {historyChart.map((point) => (
                      <div
                        key={point.date}
                        className="group relative flex-1"
                        style={{ height: '100%' }}
                      >
                        <div
                          className="absolute bottom-0 w-full rounded-t bg-blue-400 transition group-hover:bg-blue-600"
                          style={{ height: `${Math.max(point.barHeight, 5)}%` }}
                        />
                        <div className="absolute bottom-full left-1/2 mb-1 hidden -translate-x-1/2 whitespace-nowrap rounded bg-gray-800 px-2 py-1 text-xs text-white group-hover:block">
                          {point.date}: {point.buyRate.toFixed(2)}
                        </div>
                      </div>
                    ))}
                  </div>

                  {/* Táblázat */}
                  <div className="max-h-60 overflow-auto">
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="border-b text-left text-gray-500">
                          <th className="px-3 py-2">Dátum</th>
                          <th className="px-3 py-2 text-right">Vétel</th>
                          <th className="px-3 py-2 text-right">Eladás</th>
                          <th className="px-3 py-2 text-right">MNB közép</th>
                        </tr>
                      </thead>
                      <tbody>
                        {[...historyChart].reverse().map((point) => (
                          <tr key={point.date} className="border-b">
                            <td className="px-3 py-2 font-mono text-xs">
                              {point.date}
                            </td>
                            <td className="px-3 py-2 text-right font-mono text-green-700">
                              {point.buyRate.toFixed(2)}
                            </td>
                            <td className="px-3 py-2 text-right font-mono text-red-700">
                              {point.sellRate.toFixed(2)}
                            </td>
                            <td className="px-3 py-2 text-right font-mono text-blue-700">
                              {point.mnbRate.toFixed(2)}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              ) : (
                !isLoadingHistory && (
                  <p className="py-4 text-center text-gray-400">
                    Nincs történeti adat az elmúlt 30 napból.
                  </p>
                )
              )}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
