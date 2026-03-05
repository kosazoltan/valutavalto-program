import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  startClosingWizard,
  navigateClosingWizard,
  completeClosingWizard,
} from '@/api/closing';
import { getCurrencyInfo } from '@/utils/currencies';
import type {
  ClosingWizardState,
  ClosingStep,
  BalanceCheckItem,
  DiscrepancyItem,
  ClosingSummary,
  DenominationEntry,
  CurrencyCode,
} from '@/types';

const STEP_LABELS: Record<ClosingStep, string> = {
  1: 'Készlet ellenőrzés',
  2: 'Címletezés',
  3: 'Eltérés kimutatás',
  4: 'Összesítő',
  5: 'Nyomtatás & Zárás',
};

const STEP_ICONS: Record<ClosingStep, string> = {
  1: '📦',
  2: '🪙',
  3: '⚖️',
  4: '📊',
  5: '🖨️',
};

export default function ClosingPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();

  const [wizardState, setWizardState] = useState<ClosingWizardState | null>(null);
  const [currentStep, setCurrentStep] = useState<ClosingStep>(1);
  const [isLoading, setIsLoading] = useState(false);
  const [isCompleting, setIsCompleting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  // Start wizard
  const handleStart = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const state = await startClosingWizard();
      setWizardState(state);
      setCurrentStep(state.currentStep);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Napzárás indítási hiba';
      setError(`❌ ${message}`);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void handleStart();
  }, [handleStart]);

  // Navigate step
  const handleNavigate = useCallback(
    async (step: ClosingStep) => {
      if (!wizardState) return;
      // Nincs visszalépés az 5. lépésből
      if (currentStep === 5) return;

      setIsLoading(true);
      setError('');

      try {
        const state = await navigateClosingWizard(wizardState.sessionId, step);
        setWizardState(state);
        setCurrentStep(state.currentStep);
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Navigációs hiba';
        setError(`❌ ${message}`);
      } finally {
        setIsLoading(false);
      }
    },
    [wizardState, currentStep],
  );

  // Complete
  const handleComplete = useCallback(async () => {
    if (!wizardState) return;

    setIsCompleting(true);
    setError('');

    try {
      await completeClosingWizard(wizardState.sessionId);
      setSuccess('✅ Napzárás sikeresen végrehajtva!');

      // Nyomtatás trigger
      if (window.electronAPI) {
        void window.electronAPI.printReceipt(
          JSON.stringify({ type: 'closing', sessionId: wizardState.sessionId }),
        );
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Napzárás befejezési hiba';
      setError(`❌ ${message}`);
    } finally {
      setIsCompleting(false);
    }
  }, [wizardState]);

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

  const balanceCheck = wizardState?.balanceCheck ?? [];
  const denominations = wizardState?.denominations ?? [];
  const discrepancies = wizardState?.discrepancies ?? [];
  const summary = wizardState?.summary ?? null;

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🌙 Napzárás</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-4xl space-y-6">
          {/* Lépés jelző */}
          <div className="flex items-center justify-between rounded-xl border bg-white p-4">
            {([1, 2, 3, 4, 5] as ClosingStep[]).map((step) => (
              <div
                key={step}
                className={`flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium transition ${
                  step === currentStep
                    ? 'bg-blue-100 text-blue-800'
                    : step < currentStep
                      ? 'text-green-600'
                      : 'text-gray-400'
                }`}
              >
                <span>
                  {step < currentStep ? '✅' : STEP_ICONS[step]}
                </span>
                <span className="hidden sm:inline">{STEP_LABELS[step]}</span>
                <span className="sm:hidden">{step}</span>
              </div>
            ))}
          </div>

          {/* Hiba/Siker */}
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>
          )}
          {success && (
            <div className="rounded-xl border-2 border-green-300 bg-green-50 p-6 text-center">
              <p className="text-4xl">✅</p>
              <p className="mt-2 text-xl font-bold text-green-800">{success}</p>
              <button
                onClick={() => navigate('/menu')}
                className="mt-4 rounded-lg bg-green-600 px-6 py-2 text-white hover:bg-green-700"
              >
                Vissza a főmenübe
              </button>
            </div>
          )}

          {/* Tartalom — lépés alapján */}
          {!success && (
            <div className="rounded-xl border bg-white p-6">
              {isLoading ? (
                <div className="py-8 text-center text-gray-400">
                  ⏳ Betöltés...
                </div>
              ) : (
                <>
                  {/* 1. Készlet ellenőrzés */}
                  {currentStep === 1 && (
                    <Step1BalanceCheck items={balanceCheck} />
                  )}

                  {/* 2. Címletezés */}
                  {currentStep === 2 && (
                    <Step2Denominations items={denominations} />
                  )}

                  {/* 3. Eltérés kimutatás */}
                  {currentStep === 3 && (
                    <Step3Discrepancies items={discrepancies} />
                  )}

                  {/* 4. Összesítő */}
                  {currentStep === 4 && summary && (
                    <Step4Summary summary={summary} />
                  )}

                  {/* 5. Nyomtatás & Zárás */}
                  {currentStep === 5 && (
                    <Step5Finalize
                      isCompleting={isCompleting}
                      onComplete={() => void handleComplete()}
                    />
                  )}
                </>
              )}
            </div>
          )}

          {/* Navigáció gombok */}
          {!success && wizardState && !isLoading && (
            <div className="flex justify-between">
              <button
                onClick={() => {
                  if (currentStep > 1 && currentStep !== 5) {
                    void handleNavigate((currentStep - 1) as ClosingStep);
                  }
                }}
                disabled={currentStep <= 1 || currentStep === 5}
                className="rounded-lg border bg-white px-6 py-2 text-sm font-medium hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-30"
              >
                ← Vissza
              </button>
              {currentStep < 5 && (
                <button
                  onClick={() =>
                    void handleNavigate((currentStep + 1) as ClosingStep)
                  }
                  className="rounded-lg bg-blue-600 px-6 py-2 text-sm font-medium text-white hover:bg-blue-700"
                >
                  Tovább →
                </button>
              )}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

// --- Sub-components ---

function Step1BalanceCheck({ items }: { items: BalanceCheckItem[] }) {
  return (
    <div>
      <h2 className="mb-4 text-lg font-semibold text-gray-700">
        📦 Készlet ellenőrzés
      </h2>
      <p className="mb-4 text-sm text-gray-500">
        Az alábbi táblázat az aktuális és az elvárt készletet mutatja.
      </p>
      <table className="w-full">
        <thead>
          <tr className="border-b bg-gray-50 text-left text-sm font-medium text-gray-600">
            <th className="px-4 py-3">Valuta</th>
            <th className="px-4 py-3 text-right">Elvárt</th>
            <th className="px-4 py-3 text-right">Aktuális</th>
            <th className="px-4 py-3 text-right">Eltérés</th>
          </tr>
        </thead>
        <tbody>
          {items.map((item) => {
            const info =
              item.currencyCode !== 'HUF'
                ? getCurrencyInfo(item.currencyCode)
                : undefined;
            const hasDiff = item.difference !== 0;
            return (
              <tr
                key={item.currencyCode}
                className={`border-b ${hasDiff ? 'bg-red-50' : ''}`}
              >
                <td className="px-4 py-2">
                  {info?.flag ?? '🇭🇺'} {item.currencyCode}
                </td>
                <td className="px-4 py-2 text-right font-mono">
                  {item.expected.toLocaleString('hu-HU')}
                </td>
                <td className="px-4 py-2 text-right font-mono">
                  {item.actual.toLocaleString('hu-HU')}
                </td>
                <td
                  className={`px-4 py-2 text-right font-mono font-bold ${
                    hasDiff ? 'text-red-600' : 'text-green-600'
                  }`}
                >
                  {item.difference > 0 ? '+' : ''}
                  {item.difference.toLocaleString('hu-HU')}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
      {items.length === 0 && (
        <p className="py-4 text-center text-gray-400">Nincs adat.</p>
      )}
    </div>
  );
}

function Step2Denominations({ items }: { items: DenominationEntry[] }) {
  const grouped = useMemo(() => {
    const map = new Map<string, DenominationEntry[]>();
    for (const item of items) {
      const code = item.currencyCode;
      const existing = map.get(code) ?? [];
      existing.push(item);
      map.set(code, existing);
    }
    return map;
  }, [items]);

  return (
    <div>
      <h2 className="mb-4 text-lg font-semibold text-gray-700">
        🪙 Címletezés áttekintés
      </h2>
      {Array.from(grouped.entries()).map(([code, denoms]) => {
        const info =
          code !== 'HUF' ? getCurrencyInfo(code as CurrencyCode) : undefined;
        const total = denoms.reduce((s, d) => s + d.value * d.count, 0);
        return (
          <div key={code} className="mb-4">
            <h3 className="mb-2 font-semibold">
              {info?.flag ?? '🇭🇺'} {code} — Összesen:{' '}
              {total.toLocaleString('hu-HU')}
            </h3>
            <div className="flex flex-wrap gap-2">
              {denoms.map((d) => (
                <span
                  key={d.value}
                  className="rounded-lg bg-gray-100 px-3 py-1 text-sm"
                >
                  {d.value.toLocaleString('hu-HU')} × {d.count} ={' '}
                  {(d.value * d.count).toLocaleString('hu-HU')}
                </span>
              ))}
            </div>
          </div>
        );
      })}
      {items.length === 0 && (
        <p className="py-4 text-center text-gray-400">
          Nincs címletezési adat.
        </p>
      )}
    </div>
  );
}

function Step3Discrepancies({ items }: { items: DiscrepancyItem[] }) {
  const hasAny = items.length > 0;
  return (
    <div>
      <h2 className="mb-4 text-lg font-semibold text-gray-700">
        ⚖️ Eltérés kimutatás
      </h2>
      {!hasAny ? (
        <div className="rounded-lg bg-green-50 p-6 text-center">
          <p className="text-4xl">✅</p>
          <p className="mt-2 font-semibold text-green-700">
            Nincs eltérés — a készlet egyezik!
          </p>
        </div>
      ) : (
        <table className="w-full">
          <thead>
            <tr className="border-b bg-gray-50 text-left text-sm font-medium text-gray-600">
              <th className="px-4 py-3">Valuta</th>
              <th className="px-4 py-3 text-right">Elvárt</th>
              <th className="px-4 py-3 text-right">Aktuális</th>
              <th className="px-4 py-3 text-right">Eltérés</th>
              <th className="px-4 py-3 text-right">HUF eltérés</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item) => {
              const info =
                item.currencyCode !== 'HUF'
                  ? getCurrencyInfo(item.currencyCode)
                  : undefined;
              return (
                <tr key={item.currencyCode} className="border-b bg-red-50">
                  <td className="px-4 py-2">
                    {info?.flag ?? '🇭🇺'} {item.currencyCode}
                  </td>
                  <td className="px-4 py-2 text-right font-mono">
                    {item.expected.toLocaleString('hu-HU')}
                  </td>
                  <td className="px-4 py-2 text-right font-mono">
                    {item.actual.toLocaleString('hu-HU')}
                  </td>
                  <td className="px-4 py-2 text-right font-mono font-bold text-red-600">
                    {item.difference > 0 ? '+' : ''}
                    {item.difference.toLocaleString('hu-HU')}
                  </td>
                  <td className="px-4 py-2 text-right font-mono font-bold text-red-700">
                    {item.hufDifference > 0 ? '+' : ''}
                    {item.hufDifference.toLocaleString('hu-HU')} Ft
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      )}
    </div>
  );
}

function Step4Summary({ summary }: { summary: ClosingSummary }) {
  return (
    <div>
      <h2 className="mb-4 text-lg font-semibold text-gray-700">
        📊 Napi összesítő
      </h2>
      <div className="grid grid-cols-2 gap-4">
        <SummaryCard
          label="Dátum"
          value={new Date(summary.date).toLocaleDateString('hu-HU')}
        />
        <SummaryCard
          label="Összes tranzakció"
          value={summary.totalTransactions.toString()}
        />
        <SummaryCard
          label="Eladások"
          value={summary.sellCount.toString()}
        />
        <SummaryCard
          label="Vásárlások"
          value={summary.buyCount.toString()}
        />
        <SummaryCard
          label="Napi forgalom"
          value={`${summary.totalHufTurnover.toLocaleString('hu-HU')} Ft`}
          highlight
        />
        <SummaryCard
          label="Kezelési díjak"
          value={`${summary.totalFees.toLocaleString('hu-HU')} Ft`}
        />
        <SummaryCard
          label="Nyitó készlet"
          value={`${summary.openingBalance.toLocaleString('hu-HU')} Ft`}
        />
        <SummaryCard
          label="Záró készlet"
          value={`${summary.closingBalance.toLocaleString('hu-HU')} Ft`}
          highlight
        />
      </div>
    </div>
  );
}

function SummaryCard({
  label,
  value,
  highlight = false,
}: {
  label: string;
  value: string;
  highlight?: boolean;
}) {
  return (
    <div
      className={`rounded-lg p-4 ${
        highlight ? 'border-2 border-blue-200 bg-blue-50' : 'bg-gray-50'
      }`}
    >
      <p className="text-sm text-gray-500">{label}</p>
      <p
        className={`text-xl font-bold ${
          highlight ? 'text-blue-800' : 'text-gray-800'
        }`}
      >
        {value}
      </p>
    </div>
  );
}

function Step5Finalize({
  isCompleting,
  onComplete,
}: {
  isCompleting: boolean;
  onComplete: () => void;
}) {
  return (
    <div className="space-y-6 text-center">
      <div>
        <p className="text-4xl">🖨️</p>
        <h2 className="mt-2 text-lg font-semibold text-gray-700">
          Nyomtatás és napzárás véglegesítése
        </h2>
        <p className="mt-2 text-sm text-gray-500">
          A napzárás véglegesítése után nincs visszalépés. A nyomtatás
          automatikusan elindul.
        </p>
      </div>

      <div className="rounded-lg border-2 border-yellow-300 bg-yellow-50 p-4">
        <p className="font-bold text-yellow-800">
          ⚠️ FIGYELEM: Ez a művelet végleges!
        </p>
        <p className="text-sm text-yellow-700">
          A napzárás végrehajtása után a mai nap tranzakciói lezáródnak és nem
          módosíthatók.
        </p>
      </div>

      <button
        onClick={onComplete}
        disabled={isCompleting}
        className="btn-primary mx-auto bg-green-600 px-8 text-lg hover:bg-green-700 disabled:opacity-50"
      >
        {isCompleting
          ? '⏳ Napzárás végrehajtása...'
          : '🌙 Napzárás véglegesítése és nyomtatás'}
      </button>
    </div>
  );
}
