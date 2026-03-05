import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  prepareEveningClosing,
  sendEveningPackage,
  getEveningClosingStatus,
} from '@/api/eveningClosing';
import type { EveningClosingData, EveningClosingStatus } from '@/types';

type ProgressStep = 'idle' | 'collecting' | 'packaging' | 'sending' | 'done';

export default function EveningClosingPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [closingData, setClosingData] = useState<EveningClosingData | null>(null);
  const [progressStep, setProgressStep] = useState<ProgressStep>('idle');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  // Betöltés: van-e már mai esti zárás?
  useEffect(() => {
    const loadStatus = async () => {
      try {
        const data = await getEveningClosingStatus();
        setClosingData(data);
        setProgressStep('done');
      } catch {
        // Nincs még mai zárás — OK
        setClosingData(null);
      } finally {
        setIsLoading(false);
      }
    };
    void loadStatus();
  }, []);

  // Esti zárás indítása
  const handleStartClosing = useCallback(async () => {
    setError('');
    setSuccess('');

    try {
      // 1. Gyűjtés
      setProgressStep('collecting');
      await new Promise((r) => setTimeout(r, 500)); // UI feedback

      // 2. Csomagolás
      setProgressStep('packaging');
      const data = await prepareEveningClosing();
      setClosingData(data);

      setProgressStep('done');
      setSuccess('✅ Esti zárás előkészítve! Küldésre kész.');
    } catch {
      setError('❌ Esti zárás előkészítése sikertelen.');
      setProgressStep('idle');
    }
  }, []);

  // Csomag küldése
  const handleSend = useCallback(async () => {
    if (!closingData) return;

    setError('');
    setSuccess('');

    try {
      setProgressStep('sending');
      const data = await sendEveningPackage(closingData.id);
      setClosingData(data);
      setProgressStep('done');
      setSuccess('✅ Csomag sikeresen elküldve a szervernek!');
    } catch {
      setError('❌ Csomag küldés sikertelen.');
      setProgressStep('done');
    }
  }, [closingData]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const statusLabels: Record<EveningClosingStatus, { label: string; color: string }> = {
    PREPARING: { label: '🔄 Készül', color: 'bg-yellow-100 text-yellow-700' },
    READY: { label: '✅ Kész', color: 'bg-green-100 text-green-700' },
    SENT: { label: '📤 Elküldve', color: 'bg-blue-100 text-blue-700' },
    CONFIRMED: { label: '✅ Visszaigazolva', color: 'bg-purple-100 text-purple-700' },
  };

  const progressSteps: { key: ProgressStep; label: string }[] = [
    { key: 'collecting', label: 'Adatok összegyűjtése' },
    { key: 'packaging', label: 'Csomag összeállítása' },
    { key: 'sending', label: 'Küldés a szervernek' },
  ];

  const getStepIndex = (step: ProgressStep): number => {
    const map: Record<ProgressStep, number> = {
      idle: -1,
      collecting: 0,
      packaging: 1,
      sending: 2,
      done: 3,
    };
    return map[step];
  };

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🌙 Esti Zárás</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-3xl space-y-6">
          {/* Visszajelzések */}
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>
          )}
          {success && (
            <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">{success}</div>
          )}

          {isLoading ? (
            <p className="text-center text-gray-500">⏳ Betöltés...</p>
          ) : (
            <>
              {/* Progressbar */}
              {progressStep !== 'idle' && (
                <div className="rounded-xl border bg-white p-6">
                  <h2 className="mb-4 text-lg font-semibold text-gray-700">Folyamat</h2>
                  <div className="space-y-3">
                    {progressSteps.map((step, idx) => {
                      const currentIdx = getStepIndex(progressStep);
                      const isDone = currentIdx > idx;
                      const isActive = currentIdx === idx;

                      return (
                        <div key={step.key} className="flex items-center gap-3">
                          <div
                            className={`flex h-8 w-8 items-center justify-center rounded-full text-sm font-bold ${
                              isDone
                                ? 'bg-green-500 text-white'
                                : isActive
                                  ? 'bg-blue-500 text-white'
                                  : 'bg-gray-200 text-gray-500'
                            }`}
                          >
                            {isDone ? '✓' : idx + 1}
                          </div>
                          <span
                            className={`text-sm ${
                              isDone
                                ? 'font-medium text-green-700'
                                : isActive
                                  ? 'font-medium text-blue-700'
                                  : 'text-gray-400'
                            }`}
                          >
                            {step.label}
                            {isActive && ' ...'}
                          </span>
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Összesítő */}
              {closingData && (
                <div className="rounded-xl border bg-white p-6">
                  <div className="mb-4 flex items-center justify-between">
                    <h2 className="text-lg font-semibold text-gray-700">
                      📊 Zárás összesítő — {closingData.closingDate}
                    </h2>
                    <span
                      className={`rounded-full px-3 py-1 text-sm font-medium ${
                        statusLabels[closingData.status].color
                      }`}
                    >
                      {statusLabels[closingData.status].label}
                    </span>
                  </div>

                  <div className="grid grid-cols-3 gap-4">
                    <div className="rounded-lg bg-blue-50 p-4 text-center">
                      <p className="text-sm text-gray-500">Tranzakciók</p>
                      <p className="text-2xl font-bold text-blue-700">
                        {closingData.transactionCount}
                      </p>
                    </div>
                    <div className="rounded-lg bg-green-50 p-4 text-center">
                      <p className="text-sm text-gray-500">Vásárlás (HUF)</p>
                      <p className="text-2xl font-bold text-green-700">
                        {closingData.totalBuyHuf.toLocaleString('hu-HU')}
                      </p>
                    </div>
                    <div className="rounded-lg bg-orange-50 p-4 text-center">
                      <p className="text-sm text-gray-500">Eladás (HUF)</p>
                      <p className="text-2xl font-bold text-orange-700">
                        {closingData.totalSellHuf.toLocaleString('hu-HU')}
                      </p>
                    </div>
                  </div>

                  {/* Küldés gomb */}
                  {closingData.status === 'READY' && (
                    <button
                      onClick={handleSend}
                      className="mt-6 w-full rounded-xl bg-blue-600 py-3 text-lg font-bold text-white hover:bg-blue-700"
                    >
                      📤 Csomag küldése a szervernek
                    </button>
                  )}

                  {/* Küldés info */}
                  {closingData.sentAt && (
                    <div className="mt-4 rounded-lg bg-blue-50 p-3 text-sm text-blue-700">
                      📤 Elküldve: {new Date(closingData.sentAt).toLocaleString('hu-HU')}
                    </div>
                  )}
                  {closingData.confirmedAt && (
                    <div className="mt-2 rounded-lg bg-purple-50 p-3 text-sm text-purple-700">
                      ✅ Visszaigazolva:{' '}
                      {new Date(closingData.confirmedAt).toLocaleString('hu-HU')}
                    </div>
                  )}
                </div>
              )}

              {/* Indítás gomb */}
              {!closingData && progressStep === 'idle' && (
                <div className="rounded-xl border bg-white p-8 text-center">
                  <h2 className="mb-2 text-xl font-semibold text-gray-700">
                    🌙 Esti zárás még nem indult
                  </h2>
                  <p className="mb-6 text-gray-500">
                    Az esti zárás összegyűjti a napi adatokat és előkészíti küldésre a
                    szervernek.
                  </p>
                  <button
                    onClick={handleStartClosing}
                    className={`rounded-xl px-8 py-4 text-lg font-bold text-white ${
                      isBestChange
                        ? 'bg-red-600 hover:bg-red-700'
                        : 'bg-orange-500 hover:bg-orange-600'
                    }`}
                  >
                    🌙 Esti zárás indítása
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      </main>
    </div>
  );
}
