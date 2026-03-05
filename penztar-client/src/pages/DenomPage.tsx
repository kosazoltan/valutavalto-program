import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { getDenominations, saveDenominationsBulk } from '@/api/denominations';
import { CURRENCIES } from '@/utils/currencies';
import type { CurrencyCode, DenominationEntry } from '@/types';

/** Alapértelmezett címletek valutanemenként */
const DEFAULT_DENOMS: Record<string, number[]> = {
  HUF: [20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5],
  EUR: [500, 200, 100, 50, 20, 10, 5, 2, 1],
  USD: [100, 50, 20, 10, 5, 2, 1],
  GBP: [50, 20, 10, 5, 2, 1],
  CHF: [1000, 200, 100, 50, 20, 10, 5, 2, 1],
  CZK: [5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1],
  PLN: [500, 200, 100, 50, 20, 10, 5, 2, 1],
  RON: [500, 200, 100, 50, 10, 5, 1],
  DKK: [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1],
  NOK: [1000, 500, 200, 100, 50, 20, 10, 5, 1],
  SEK: [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1],
  CAD: [100, 50, 20, 10, 5, 2, 1],
  AUD: [100, 50, 20, 10, 5, 2, 1],
  JPY: [10000, 5000, 2000, 1000, 500, 100, 50, 10, 5, 1],
  CNY: [100, 50, 20, 10, 5, 1],
  TRY: [200, 100, 50, 20, 10, 5, 1],
  RUB: [5000, 2000, 1000, 500, 200, 100, 50, 10, 5, 2, 1],
  BGN: [100, 50, 20, 10, 5, 2, 1],
  HRK: [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1],
  RSD: [5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1],
  BAM: [200, 100, 50, 20, 10, 5, 2, 1],
  UAH: [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1],
  ILS: [200, 100, 50, 20, 10, 5, 2, 1],
  THB: [1000, 500, 100, 50, 20, 10, 5, 2, 1],
  BRL: [200, 100, 50, 20, 10, 5, 2, 1],
  MXN: [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1],
  NZD: [100, 50, 20, 10, 5, 2, 1],
};

function getDefaultDenoms(code: string): number[] {
  return DEFAULT_DENOMS[code] ?? [100, 50, 20, 10, 5, 2, 1];
}

export default function DenomPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();

  const [selectedCurrency, setSelectedCurrency] = useState<CurrencyCode | 'HUF'>('HUF');
  const [counts, setCounts] = useState<Record<number, number>>({});
  const [serverDenoms, setServerDenoms] = useState<DenominationEntry[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const denomValues = useMemo(() => getDefaultDenoms(selectedCurrency), [selectedCurrency]);

  // Fetch when currency changes
  const fetchDenoms = useCallback(async (code: string) => {
    setIsLoading(true);
    setError('');
    try {
      const data = await getDenominations(code);
      setServerDenoms(data);
      // Inicializálás a szerver adatokból
      const init: Record<number, number> = {};
      for (const v of getDefaultDenoms(code)) {
        const serverEntry = data.find((d) => d.value === v);
        init[v] = serverEntry?.count ?? 0;
      }
      setCounts(init);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Címletezés lekérési hiba';
      setError(`❌ ${message}`);
      // Inicializálás nullákkal
      const init: Record<number, number> = {};
      for (const v of getDefaultDenoms(code)) {
        init[v] = 0;
      }
      setCounts(init);
      setServerDenoms([]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchDenoms(selectedCurrency);
  }, [selectedCurrency, fetchDenoms]);

  const handleCurrencyChange = useCallback((code: CurrencyCode | 'HUF') => {
    setSelectedCurrency(code);
    setSuccess('');
    setError('');
  }, []);

  const handleCountChange = useCallback((value: number, count: string) => {
    const num = parseInt(count, 10);
    setCounts((prev) => ({
      ...prev,
      [value]: isNaN(num) || num < 0 ? 0 : num,
    }));
  }, []);

  const total = useMemo(() => {
    return denomValues.reduce((sum, v) => sum + v * (counts[v] ?? 0), 0);
  }, [counts, denomValues]);

  const handleSave = useCallback(async () => {
    setIsSaving(true);
    setError('');
    setSuccess('');
    try {
      const denomData = denomValues.map((v) => ({
        value: v,
        count: counts[v] ?? 0,
      }));
      await saveDenominationsBulk({
        currencyCode: selectedCurrency,
        denominations: denomData,
      });
      setSuccess(`✅ Címletezés mentve: ${selectedCurrency}`);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Mentési hiba';
      setError(`❌ ${message}`);
    } finally {
      setIsSaving(false);
    }
  }, [selectedCurrency, denomValues, counts]);

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

  // Suppress unused variable warning
  void serverDenoms;

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🪙 Címletezés</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto grid max-w-5xl grid-cols-3 gap-6">
          {/* BAL — Valutanem választó */}
          <div className="col-span-1">
            <h2 className="mb-3 text-lg font-semibold text-gray-700">Valutanem</h2>
            <div className="max-h-[600px] space-y-1 overflow-auto rounded-xl border bg-white p-3">
              {CURRENCIES.map((c) => (
                <button
                  key={c.code}
                  onClick={() => handleCurrencyChange(c.code as CurrencyCode | 'HUF')}
                  className={`flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left transition ${
                    selectedCurrency === c.code
                      ? 'bg-blue-100 text-blue-800 font-semibold'
                      : 'hover:bg-gray-50'
                  }`}
                >
                  <span>{c.flag}</span>
                  <span>{c.code}</span>
                  <span className="text-xs text-gray-500">{c.name}</span>
                </button>
              ))}
            </div>
          </div>

          {/* KÖZÉP + JOBB — Címletezés tábla */}
          <div className="col-span-2 space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-700">
                {selectedCurrency} címletek
              </h2>
              {isLoading && (
                <span className="text-sm text-gray-400">⏳ Betöltés...</span>
              )}
            </div>

            <div className="overflow-hidden rounded-xl border bg-white">
              <table className="w-full">
                <thead>
                  <tr className="border-b bg-gray-50 text-left text-sm font-medium text-gray-600">
                    <th className="px-4 py-3">Címlet</th>
                    <th className="px-4 py-3 text-center">Darabszám</th>
                    <th className="px-4 py-3 text-right">Összeg</th>
                  </tr>
                </thead>
                <tbody>
                  {denomValues.map((value) => {
                    const count = counts[value] ?? 0;
                    return (
                      <tr key={value} className="border-b transition hover:bg-gray-50">
                        <td className="px-4 py-2 font-semibold">
                          {value.toLocaleString('hu-HU')} {selectedCurrency}
                        </td>
                        <td className="px-4 py-2 text-center">
                          <input
                            type="number"
                            value={count}
                            onChange={(e) => handleCountChange(value, e.target.value)}
                            className="w-24 rounded border px-2 py-1 text-center font-mono"
                            min="0"
                          />
                        </td>
                        <td className="px-4 py-2 text-right font-mono font-semibold">
                          {(value * count).toLocaleString('hu-HU')}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* Összesítés */}
            <div className="rounded-xl border bg-blue-50 p-4">
              <div className="flex items-center justify-between">
                <span className="text-lg font-bold text-blue-800">
                  Összesen: {total.toLocaleString('hu-HU')} {selectedCurrency}
                </span>
                <button
                  onClick={() => void handleSave()}
                  disabled={isSaving}
                  className="rounded-lg bg-blue-600 px-6 py-2 font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                >
                  {isSaving ? '⏳ Mentés...' : '💾 Mentés'}
                </button>
              </div>
            </div>

            {/* Üzenetek */}
            {error && (
              <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>
            )}
            {success && (
              <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">
                {success}
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
