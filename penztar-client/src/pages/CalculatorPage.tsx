import { useState, useEffect, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { convertCurrency, getRoundingRules } from '@/api/calculator';
import { getForeignCurrencies } from '@/utils/currencies';
import type { CalculationResult, RoundingRule } from '@/types';

export default function CalculatorPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();

  const [fromCurrency, setFromCurrency] = useState<string>('EUR');
  const [toCurrency, setToCurrency] = useState<string>('HUF');
  const [amount, setAmount] = useState('');
  const [direction, setDirection] = useState<'BUY' | 'SELL'>('BUY');
  const [result, setResult] = useState<CalculationResult | null>(null);
  const [rules, setRules] = useState<RoundingRule[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const foreignCurrencies = getForeignCurrencies();

  // Kerekítési szabályok betöltése
  useEffect(() => {
    void (async () => {
      try {
        const data = await getRoundingRules();
        setRules(data);
      } catch {
        // Nem kritikus hiba
      }
    })();
  }, []);

  // Élő számítás debounce-szal
  const doCalculation = useCallback(async () => {
    const numAmount = parseFloat(amount);
    if (!amount || isNaN(numAmount) || numAmount <= 0) {
      setResult(null);
      return;
    }

    setIsLoading(true);
    setError('');
    try {
      const data = await convertCurrency({
        fromCurrency,
        toCurrency,
        amount: numAmount,
        direction,
      });
      setResult(data);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Számítási hiba';
      setError(`❌ ${message}`);
      setResult(null);
    } finally {
      setIsLoading(false);
    }
  }, [amount, fromCurrency, toCurrency, direction]);

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      void doCalculation();
    }, 300);
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [doCalculation]);

  // Irány csere
  const swapCurrencies = () => {
    setFromCurrency(toCurrency);
    setToCurrency(fromCurrency);
  };

  // Aktuális kerekítési szabály
  const currentRule = rules.find(
    (r) => r.currencyCode === (fromCurrency === 'HUF' ? toCurrency : fromCurrency),
  );

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🔢 Deviza kalkulátor</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-2xl space-y-6">
          {/* Irány toggle */}
          <div className="flex items-center justify-center gap-4">
            <button
              onClick={() => setDirection('BUY')}
              className={`rounded-lg px-6 py-2 text-sm font-medium transition ${
                direction === 'BUY'
                  ? 'bg-green-600 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              💰 Vétel (ügyfél elad)
            </button>
            <button
              onClick={() => setDirection('SELL')}
              className={`rounded-lg px-6 py-2 text-sm font-medium transition ${
                direction === 'SELL'
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              💸 Eladás (ügyfél vesz)
            </button>
          </div>

          {/* Kalkulátor */}
          <div className="rounded-xl border bg-white p-6">
            <div className="grid grid-cols-[1fr_auto_1fr] items-end gap-4">
              {/* Forrás */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-600">Forrás valuta</label>
                <select
                  value={fromCurrency}
                  onChange={(e) => setFromCurrency(e.target.value)}
                  className="w-full rounded-lg border bg-gray-50 px-3 py-2 text-sm"
                >
                  <option value="HUF">🇭🇺 HUF</option>
                  {foreignCurrencies.map((c) => (
                    <option key={c.code} value={c.code}>
                      {c.flag} {c.code}
                    </option>
                  ))}
                </select>
              </div>

              {/* Csere gomb */}
              <button
                onClick={swapCurrencies}
                className="mb-0.5 rounded-full bg-gray-100 p-2 text-lg hover:bg-gray-200"
                title="Csere"
              >
                ⇄
              </button>

              {/* Cél */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-600">Cél valuta</label>
                <select
                  value={toCurrency}
                  onChange={(e) => setToCurrency(e.target.value)}
                  className="w-full rounded-lg border bg-gray-50 px-3 py-2 text-sm"
                >
                  <option value="HUF">🇭🇺 HUF</option>
                  {foreignCurrencies.map((c) => (
                    <option key={c.code} value={c.code}>
                      {c.flag} {c.code}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* Összeg input */}
            <div className="mt-4">
              <label className="mb-1 block text-sm font-medium text-gray-600">Összeg</label>
              <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                placeholder="Adja meg az összeget..."
                className="w-full rounded-lg border px-4 py-3 text-lg font-mono focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                min="0"
                step="0.01"
              />
            </div>
          </div>

          {/* Eredmény */}
          {isLoading && (
            <div className="text-center text-gray-400">⏳ Számítás...</div>
          )}

          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>
          )}

          {result && !isLoading && (
            <div className="rounded-xl border-2 border-blue-200 bg-blue-50 p-6">
              <div className="text-center">
                <p className="text-sm text-gray-500">Eredmény</p>
                <p className="text-3xl font-bold text-blue-800">
                  {result.toAmount.toLocaleString('hu-HU', { maximumFractionDigits: 4 })}{' '}
                  {result.toCurrency}
                </p>
                <div className="mt-3 flex items-center justify-center gap-4 text-sm text-gray-500">
                  <span>Árfolyam: {result.appliedRate.toLocaleString('hu-HU', { maximumFractionDigits: 4 })}</span>
                  {result.spread > 0 && (
                    <span>Spread: {result.spread.toLocaleString('hu-HU', { maximumFractionDigits: 4 })}</span>
                  )}
                </div>
                {result.roundingInfo && (
                  <p className="mt-1 text-xs text-gray-400">{result.roundingInfo}</p>
                )}
              </div>
            </div>
          )}

          {/* Kerekítési szabály info */}
          {currentRule && (
            <div className="rounded-xl border bg-white p-4">
              <h3 className="mb-2 text-sm font-semibold text-gray-600">📐 Kerekítési szabály</h3>
              <div className="grid grid-cols-3 gap-2 text-sm">
                <div className="rounded bg-gray-50 p-2">
                  <p className="text-xs text-gray-400">Pontosság</p>
                  <p className="font-mono font-bold">{currentRule.precisionValue}</p>
                </div>
                <div className="rounded bg-gray-50 p-2">
                  <p className="text-xs text-gray-400">Kis összeg (&lt;{currentRule.smallThreshold})</p>
                  <p className="font-mono font-bold text-green-600">↑ {currentRule.smallRounding}</p>
                </div>
                <div className="rounded bg-gray-50 p-2">
                  <p className="text-xs text-gray-400">Nagy összeg (&gt;{currentRule.largeThreshold})</p>
                  <p className="font-mono font-bold text-red-600">↓ {currentRule.largeRounding}</p>
                </div>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
