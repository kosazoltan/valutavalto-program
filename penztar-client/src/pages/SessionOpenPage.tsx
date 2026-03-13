import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { openSession, validateSessionOpen } from '@/api/sessionOpen';
import { getCurrencyInfo } from '@/utils/currencies';
import type { SessionData, CurrencyCode } from '@/types';

export default function SessionOpenPage() {
  const navigate = useNavigate();
  const { user, companyType } = useAuthStore();

  const [warnings, setWarnings] = useState<string[]>([]);
  const [sessionData, setSessionData] = useState<SessionData | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isOpening, setIsOpening] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  // Validáció betöltése
  const loadValidation = useCallback(async () => {
    if (!user) return;
    setIsLoading(true);
    setError('');
    try {
      // branchCode → branchId mapping: a user.branchCode-ot küldjük
      const warns = await validateSessionOpen(user.branchCode);
      setWarnings(warns);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Validációs hiba';
      setError(`❌ ${message}`);
    } finally {
      setIsLoading(false);
    }
  }, [user]);

  useEffect(() => {
    void loadValidation();
  }, [loadValidation]);

  // Nyitás
  const handleOpen = useCallback(async () => {
    if (!user) return;
    setIsOpening(true);
    setError('');
    try {
      const data = await openSession({
        workerId: user.id,
        branchId: user.branchCode,
      });
      setSessionData(data);
      setSuccess('✅ Pénztár sikeresen megnyitva!');
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Nyitási hiba';
      setError(`❌ ${message}`);
    } finally {
      setIsOpening(false);
    }
  }, [user]);

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
          <h1 className="text-xl font-bold">🔓 Pénztárnyitás</h1>
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
          {/* Hiba */}
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>
          )}

          {/* Siker */}
          {success && sessionData && (
            <div className="rounded-xl border-2 border-green-300 bg-green-50 p-6 text-center">
              <p className="text-4xl">✅</p>
              <p className="mt-2 text-xl font-bold text-green-800">{success}</p>
              <p className="mt-1 text-sm text-green-600">
                {sessionData.branchName} — {sessionData.workerName} — {sessionData.sessionDate}
              </p>
              <button
                onClick={() => navigate('/menu')}
                className="mt-4 rounded-lg bg-green-600 px-6 py-2 text-white hover:bg-green-700"
              >
                Tovább a főmenübe
              </button>
            </div>
          )}

          {/* Figyelmeztetések */}
          {!success && warnings.length > 0 && (
            <div className="rounded-xl border-2 border-yellow-300 bg-yellow-50 p-4">
              <h3 className="mb-2 font-bold text-yellow-800">⚠️ Figyelmeztetések</h3>
              <ul className="space-y-1">
                {warnings.map((w, i) => (
                  <li key={i} className="text-sm text-yellow-700">{w}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Nyitó készlet áttekintés */}
          {!success && sessionData && sessionData.openingBalances && (
            <div className="rounded-xl border bg-white p-6">
              <h2 className="mb-4 text-lg font-semibold text-gray-700">💰 Nyitó készlet</h2>
              <table className="w-full">
                <thead>
                  <tr className="border-b bg-gray-50 text-left text-sm font-medium text-gray-600">
                    <th className="px-4 py-3">Valuta</th>
                    <th className="px-4 py-3 text-right">Összeg</th>
                  </tr>
                </thead>
                <tbody>
                  {Object.entries(sessionData.openingBalances).map(([code, amount]) => {
                    const info = code !== 'HUF' ? getCurrencyInfo(code as CurrencyCode) : undefined;
                    return (
                      <tr key={code} className="border-b">
                        <td className="px-4 py-2">
                          {info?.flag ?? '🇭🇺'} {code}
                        </td>
                        <td className="px-4 py-2 text-right font-mono">
                          {amount.toLocaleString('hu-HU')}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Nyitás gomb */}
          {!success && (
            <div className="rounded-xl border bg-white p-6 text-center">
              <h2 className="mb-2 text-lg font-semibold text-gray-700">Napi munkamenet megnyitása</h2>
              <p className="mb-4 text-sm text-gray-500">
                Pénztáros: <strong>{user?.fullName ?? '—'}</strong> | Iroda: <strong>{user?.branchCode ?? '—'}</strong>
              </p>

              {isLoading ? (
                <p className="py-4 text-gray-400">⏳ Validáció...</p>
              ) : (
                <button
                  onClick={() => void handleOpen()}
                  disabled={isOpening}
                  className="rounded-lg bg-blue-600 px-8 py-3 text-lg font-medium text-white hover:bg-blue-700 disabled:opacity-50"
                >
                  {isOpening ? '⏳ Nyitás...' : '🔓 Pénztár megnyitása'}
                </button>
              )}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}


