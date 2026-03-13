import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  supervisorAuthenticate,
  getSystemParams,
  overrideRate,
  overrideFee,
} from '@/api/supervisor';
import type { SystemParam } from '@/types';

type SupervisorTab = 'rate' | 'fee' | 'storno' | 'limit' | 'break' | 'params';

export default function SupervisorPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [password, setPassword] = useState('');
  const [authError, setAuthError] = useState('');
  const [activeTab, setActiveTab] = useState<SupervisorTab>('rate');

  // Árfolyam felülbírálat
  const [rateCurrency, setRateCurrency] = useState('');
  const [rateBuy, setRateBuy] = useState('');
  const [rateSell, setRateSell] = useState('');
  const [rateReason, setRateReason] = useState('');
  const [rateBranchId, setRateBranchId] = useState('');

  // Díj felülbírálat
  const [feeTxId, setFeeTxId] = useState('');
  const [feeAmount, setFeeAmount] = useState('');
  const [feeReason, setFeeReason] = useState('');

  // Rendszer paraméterek
  const [params, setParams] = useState<SystemParam[]>([]);

  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleLogin = useCallback(async () => {
    setAuthError('');
    try {
      const result = await supervisorAuthenticate(password);
      if (result.authenticated) {
        setIsAuthenticated(true);
        setPassword('');
      } else {
        setAuthError('Hibás supervisor jelszó!');
      }
    } catch (err: unknown) {
      setAuthError('Hitelesítési hiba. Próbálja újra.');
    }
  }, [password]);

  const loadParams = useCallback(async () => {
    try {
      const data = await getSystemParams();
      setParams(data);
    } catch (err: unknown) {
      console.error('[Supervisor] Paraméterek betöltése hiba:', err);
    }
  }, []);

  useEffect(() => {
    if (isAuthenticated && activeTab === 'params') {
      void loadParams();
    }
  }, [isAuthenticated, activeTab, loadParams]);

  const handleOverrideRate = useCallback(async () => {
    if (!rateCurrency || !rateBuy || !rateSell || !rateReason) {
      setError('Minden mező kitöltése kötelező!');
      return;
    }
    setIsSubmitting(true);
    setError('');
    setMessage('');
    try {
      await overrideRate({
        branchId: rateBranchId,
        currency: rateCurrency,
        newBuyRate: parseFloat(rateBuy),
        newSellRate: parseFloat(rateSell),
        reason: rateReason,
      });
      setMessage('✅ Árfolyam felülbírálva!');
      setRateCurrency('');
      setRateBuy('');
      setRateSell('');
      setRateReason('');
    } catch (err: unknown) {
      setError('❌ Árfolyam felülbírálás sikertelen.');
    } finally {
      setIsSubmitting(false);
    }
  }, [rateCurrency, rateBuy, rateSell, rateReason, rateBranchId]);

  const handleOverrideFee = useCallback(async () => {
    if (!feeTxId || !feeAmount || !feeReason) {
      setError('Minden mező kitöltése kötelező!');
      return;
    }
    setIsSubmitting(true);
    setError('');
    setMessage('');
    try {
      await overrideFee({
        transactionId: parseInt(feeTxId, 10),
        newFee: parseFloat(feeAmount),
        reason: feeReason,
      });
      setMessage('✅ Kezelési díj felülbírálva!');
      setFeeTxId('');
      setFeeAmount('');
      setFeeReason('');
    } catch (err: unknown) {
      setError('❌ Díj felülbírálás sikertelen.');
    } finally {
      setIsSubmitting(false);
    }
  }, [feeTxId, feeAmount, feeReason]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  // Supervisor belépés képernyő
  if (!isAuthenticated) {
    return (
      <div className="flex h-screen flex-col">
        <header className={`${headerColor} px-6 py-3 text-white`}>
          <div className="flex items-center justify-between">
            <h1 className="text-xl font-bold">🔐 Supervisor mód</h1>
            <button onClick={() => navigate('/menu')}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
              ← Vissza (ESC)
            </button>
          </div>
        </header>
        <main className="flex flex-1 items-center justify-center">
          <div className="w-96 rounded-xl border bg-white p-8 shadow-lg">
            <h2 className="mb-6 text-center text-xl font-bold text-gray-800">
              🔒 Supervisor bejelentkezés
            </h2>
            <p className="mb-4 text-center text-sm text-gray-500">
              Adja meg a supervisor jelszót a speciális funkciók eléréséhez.
            </p>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') void handleLogin(); }}
              className="input-field mb-4 w-full text-center text-lg"
              placeholder="Supervisor jelszó"
              autoFocus
            />
            {authError && (
              <p className="mb-4 text-center text-sm text-red-600">{authError}</p>
            )}
            <button onClick={handleLogin}
              className="btn-primary w-full bg-purple-600 hover:bg-purple-700">
              🔓 Belépés
            </button>
          </div>
        </main>
      </div>
    );
  }

  const tabs: { key: SupervisorTab; label: string; icon: string }[] = [
    { key: 'rate', label: 'Árfolyam módosítás', icon: '📊' },
    { key: 'fee', label: 'Díj felülbírálat', icon: '💰' },
    { key: 'storno', label: 'Stornó engedély', icon: '↩️' },
    { key: 'limit', label: 'Napi limit', icon: '📈' },
    { key: 'break', label: 'Szünet engedély', icon: '☕' },
    { key: 'params', label: 'Rendszer paraméterek', icon: '⚙️' },
  ];

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🔐 Supervisor mód</h1>
          <button onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex flex-1 overflow-hidden">
        {/* Oldalsáv — funkciók */}
        <nav className="w-56 border-r bg-gray-50 p-3">
          {tabs.map((t) => (
            <button
              key={t.key}
              onClick={() => { setActiveTab(t.key); setError(''); setMessage(''); }}
              className={`mb-1 w-full rounded-lg px-3 py-2 text-left text-sm transition ${
                activeTab === t.key
                  ? 'bg-purple-100 font-semibold text-purple-800'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              {t.icon} {t.label}
            </button>
          ))}
        </nav>

        {/* Tartalom */}
        <div className="flex-1 overflow-auto p-6">
          {message && (
            <div className="mb-4 rounded-lg bg-green-50 p-3 text-sm text-green-700">{message}</div>
          )}
          {error && (
            <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>
          )}

          {/* Árfolyam módosítás */}
          {activeTab === 'rate' && (
            <div className="max-w-lg space-y-4">
              <h2 className="text-lg font-bold text-gray-800">📊 Árfolyam kézi módosítás</h2>
              <p className="text-sm text-gray-500">
                Egy valutára ideiglenesen módosíthatja az árfolyamot. Audit log-ba kerül!
              </p>
              <input type="text" value={rateBranchId}
                onChange={(e) => setRateBranchId(e.target.value)}
                className="input-field w-full" placeholder="Iroda ID (UUID)" />
              <input type="text" value={rateCurrency}
                onChange={(e) => setRateCurrency(e.target.value.toUpperCase())}
                className="input-field w-full" placeholder="Valutanem (pl. EUR)" maxLength={3} />
              <div className="grid grid-cols-2 gap-3">
                <input type="number" value={rateBuy}
                  onChange={(e) => setRateBuy(e.target.value)}
                  className="input-field" placeholder="Új vételi árf." step="0.01" />
                <input type="number" value={rateSell}
                  onChange={(e) => setRateSell(e.target.value)}
                  className="input-field" placeholder="Új eladási árf." step="0.01" />
              </div>
              <input type="text" value={rateReason}
                onChange={(e) => setRateReason(e.target.value)}
                className="input-field w-full" placeholder="Indoklás (kötelező)" />
              <button onClick={handleOverrideRate} disabled={isSubmitting}
                className="btn-primary w-full bg-purple-600 hover:bg-purple-700 disabled:opacity-50">
                {isSubmitting ? '⏳ Feldolgozás...' : '📊 Árfolyam felülbírálás'}
              </button>
            </div>
          )}

          {/* Díj felülbírálat */}
          {activeTab === 'fee' && (
            <div className="max-w-lg space-y-4">
              <h2 className="text-lg font-bold text-gray-800">💰 Kezelési díj felülbírálat</h2>
              <p className="text-sm text-gray-500">
                Egy tranzakció kezelési díját módosíthatja. Audit log-ba kerül!
              </p>
              <input type="number" value={feeTxId}
                onChange={(e) => setFeeTxId(e.target.value)}
                className="input-field w-full" placeholder="Tranzakció ID" />
              <input type="number" value={feeAmount}
                onChange={(e) => setFeeAmount(e.target.value)}
                className="input-field w-full" placeholder="Új díj összeg (Ft)" step="1" />
              <input type="text" value={feeReason}
                onChange={(e) => setFeeReason(e.target.value)}
                className="input-field w-full" placeholder="Indoklás (kötelező)" />
              <button onClick={handleOverrideFee} disabled={isSubmitting}
                className="btn-primary w-full bg-purple-600 hover:bg-purple-700 disabled:opacity-50">
                {isSubmitting ? '⏳ Feldolgozás...' : '💰 Díj felülbírálás'}
              </button>
            </div>
          )}

          {/* Stornó engedély */}
          {activeTab === 'storno' && (
            <div className="max-w-lg space-y-4">
              <h2 className="text-lg font-bold text-gray-800">↩️ Stornó engedélyezés</h2>
              <p className="text-sm text-gray-500">
                A Stornó oldalon automatikusan kéri a supervisor jelszót, ha szükséges.
                Ez a funkció a StornoPage-ről érhető el közvetlenül.
              </p>
              <div className="rounded-lg border-2 border-yellow-300 bg-yellow-50 p-4">
                <p className="font-medium text-yellow-800">
                  ⚠️ A stornó engedélyezés a Stornó (F6) képernyőn keresztül működik.
                </p>
                <p className="mt-1 text-sm text-yellow-700">
                  Ha supervisor jóváhagyás szükséges, ott fog megjelenni a jelszókérés.
                </p>
              </div>
            </div>
          )}

          {/* Napi limit */}
          {activeTab === 'limit' && (
            <div className="max-w-lg space-y-4">
              <h2 className="text-lg font-bold text-gray-800">📈 Napi limit felülírás</h2>
              <p className="text-sm text-gray-500">
                Egy ügyfélre vonatkozó napi limit felülbírálása (AML küszöb).
              </p>
              <div className="rounded-lg border-2 border-blue-300 bg-blue-50 p-4">
                <p className="font-medium text-blue-800">
                  ℹ️ Ez a funkció a jövőbeli AML modul részeként kerül megvalósításra.
                </p>
              </div>
            </div>
          )}

          {/* Szünet engedély */}
          {activeTab === 'break' && (
            <div className="max-w-lg space-y-4">
              <h2 className="text-lg font-bold text-gray-800">☕ Pénztáros szünet engedélyezés</h2>
              <p className="text-sm text-gray-500">
                A Pénztáros kezelés (Ctrl+W) oldalon engedélyezheti a szünetet.
              </p>
              <div className="rounded-lg border-2 border-green-300 bg-green-50 p-4">
                <p className="font-medium text-green-800">
                  ✅ A szünet kezelés a Pénztáros kezelés oldalon (Ctrl+W) érhető el.
                </p>
                <button onClick={() => navigate('/worker-management')}
                  className="mt-2 rounded-lg bg-green-600 px-4 py-2 text-sm text-white hover:bg-green-700">
                  Ugrás a Pénztáros kezeléshez →
                </button>
              </div>
            </div>
          )}

          {/* Rendszer paraméterek */}
          {activeTab === 'params' && (
            <div className="space-y-4">
              <h2 className="text-lg font-bold text-gray-800">⚙️ Rendszer paraméterek (csak olvasás)</h2>
              {params.length === 0 ? (
                <p className="text-sm text-gray-400">Nincsenek paraméterek vagy betöltés alatt...</p>
              ) : (
                <div className="overflow-auto rounded-lg border">
                  <table className="min-w-full text-sm">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Kulcs</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Érték</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Kategória</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Leírás</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y">
                      {params.map((p) => (
                        <tr key={p.id} className="hover:bg-gray-50">
                          <td className="px-3 py-2 font-mono text-xs">{p.key}</td>
                          <td className="px-3 py-2">{p.value}</td>
                          <td className="px-3 py-2 text-gray-500">{p.category}</td>
                          <td className="px-3 py-2 text-xs text-gray-400">{p.description}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}


