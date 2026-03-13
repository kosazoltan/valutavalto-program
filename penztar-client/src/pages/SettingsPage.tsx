import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { getAllSystemParams, updateSystemParam, type SystemParamData } from '@/api/systemParams';
import type { PrinterInfo } from '@/types/electron';

export default function SettingsPage() {
  const navigate = useNavigate();
  const { companyType, branchCode, clearAuth } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [serverUrl, setServerUrl] = useState('');
  const [printers, setPrinters] = useState<PrinterInfo[]>([]);
  const [selectedPrinter, setSelectedPrinter] = useState('');
  const [pendingCount, setPendingCount] = useState(0);
  const [appVersion, setAppVersion] = useState('');
  const [isSyncing, setIsSyncing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  // System params state
  const [sysParams, setSysParams] = useState<SystemParamData[]>([]);
  const [activeParamCat, setActiveParamCat] = useState('GENERAL');
  const [editingParam, setEditingParam] = useState<string | null>(null);
  const [editValue, setEditValue] = useState('');
  const paramCategories = ['GENERAL', 'RATES', 'FEES', 'LIMITS', 'SYNC', 'PRINT', 'SECURITY'] as const;

  // Betöltés
  useEffect(() => {
    const loadSettings = async () => {
      if (!window.electronAPI) return;

      try {
        const [url, printer, version, count] = await Promise.all([
          window.electronAPI.getConfig('server_url'),
          window.electronAPI.getConfig('selected_printer'),
          window.electronAPI.getAppVersion(),
          window.electronAPI.getPendingTransactionCount(),
        ]);
        setServerUrl(url ?? import.meta.env.VITE_API_URL ?? 'http://localhost:8080/api/v1');
        setSelectedPrinter(printer ?? '');
        setAppVersion(version);
        setPendingCount(count);
      } catch {
        console.error('[SettingsPage] Betöltési hiba:', err);
      }

      try {
        const printerList = await window.electronAPI.getPrinters();
        setPrinters(printerList);
      } catch {
        console.error('[SettingsPage] Nyomtató lista hiba:', err);
      }
    };

    void loadSettings();

    // Load system params
    const loadParams = async () => {
      try {
        const data = await getAllSystemParams();
        setSysParams(data);
      } catch {
        // System params may not be available for non-admin users
      }
    };
    void loadParams();
  }, []);

  const handleSave = useCallback(async () => {
    if (isSaving) return;
    setIsSaving(true);
    setError('');
    setSuccess('');

    try {
      if (window.electronAPI) {
        await window.electronAPI.setConfig('server_url', serverUrl);
        await window.electronAPI.setConfig('selected_printer', selectedPrinter);
      }
      setSuccess('✅ Beállítások mentve!');
    } catch {
      console.error('[SettingsPage] Mentés hiba:', err);
      setError('Beállítások mentése sikertelen.');
    } finally {
      setIsSaving(false);
    }
  }, [serverUrl, selectedPrinter, isSaving]);

  const handleSync = useCallback(async () => {
    if (isSyncing) return;
    setIsSyncing(true);
    setError('');
    setSuccess('');

    try {
      if (window.electronAPI) {
        const synced = await window.electronAPI.syncOffline();
        const remaining = await window.electronAPI.getPendingTransactionCount();
        setPendingCount(remaining);
        setSuccess(`✅ ${synced} tranzakció szinkronizálva! Hátralévő: ${remaining}`);
      }
    } catch {
      console.error('[SettingsPage] Szinkronizáció hiba:', err);
      setError('Szinkronizáció sikertelen. Próbálja újra.');
    } finally {
      setIsSyncing(false);
    }
  }, [isSyncing]);

  const handleLogout = useCallback(() => {
    clearAuth();
    navigate('/login');
  }, [clearAuth, navigate]);

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

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">⚙️ Beállítások</h1>
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
          {/* Pénztár kód */}
          <div className="rounded-xl border bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-700">🏦 Pénztár</h2>
            <div>
              <label className="mb-1 block text-sm text-gray-500">Pénztár kód</label>
              <input
                type="text"
                value={branchCode}
                readOnly
                className="input-field bg-gray-100 cursor-not-allowed"
              />
              <p className="mt-1 text-xs text-gray-400">Csak olvasható — bejelentkezéskor kerül beállításra.</p>
            </div>
          </div>

          {/* Szerver URL */}
          <div className="rounded-xl border bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-700">🌐 Szerver</h2>
            <div>
              <label className="mb-1 block text-sm text-gray-500">Szerver URL</label>
              <input
                type="text"
                value={serverUrl}
                onChange={(e) => setServerUrl(e.target.value)}
                className="input-field font-mono text-sm"
                placeholder="http://localhost:8080/api/v1"
              />
            </div>
          </div>

          {/* Nyomtató */}
          <div className="rounded-xl border bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-700">🖨️ Nyomtató</h2>
            <div>
              <label className="mb-1 block text-sm text-gray-500">Nyomtató választás</label>
              <select
                value={selectedPrinter}
                onChange={(e) => setSelectedPrinter(e.target.value)}
                className="input-field"
              >
                <option value="">— Válasszon nyomtatót —</option>
                {printers.map((p) => (
                  <option key={p.name} value={p.name}>
                    {p.displayName || p.name}
                    {p.isDefault ? ' (alapértelmezett)' : ''}
                  </option>
                ))}
              </select>
              {printers.length === 0 && (
                <p className="mt-1 text-xs text-gray-400">Nem találhatók nyomtatók.</p>
              )}
            </div>
          </div>

          {/* Nyelv */}
          <div className="rounded-xl border bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-700">🌍 Nyelv</h2>
            <div>
              <select className="input-field" disabled>
                <option>Magyar</option>
              </select>
              <p className="mt-1 text-xs text-gray-400">Jelenleg csak magyar nyelv elérhető.</p>
            </div>
          </div>

          {/* Rendszer paraméterek */}
          {sysParams.length > 0 && (
            <div className="rounded-xl border bg-white p-6">
              <h2 className="mb-4 text-lg font-semibold text-gray-700">📋 Rendszer paraméterek</h2>
              {/* Category tabs */}
              <div className="mb-4 flex flex-wrap gap-1">
                {paramCategories.map((cat) => (
                  <button
                    key={cat}
                    onClick={() => setActiveParamCat(cat)}
                    className={`rounded px-3 py-1 text-xs font-medium transition ${
                      activeParamCat === cat
                        ? 'bg-blue-600 text-white'
                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                    }`}
                  >
                    {cat}
                  </button>
                ))}
              </div>
              {/* Params list */}
              <div className="space-y-2">
                {sysParams
                  .filter((p) => p.category === activeParamCat)
                  .map((p) => (
                    <div key={p.id} className="flex items-center justify-between rounded border px-3 py-2">
                      <div className="flex-1">
                        <div className="text-sm font-medium text-gray-700">{p.parameterKey}</div>
                        {p.description && (
                          <div className="text-xs text-gray-400">{p.description}</div>
                        )}
                      </div>
                      {editingParam === p.parameterKey ? (
                        <div className="flex items-center gap-2">
                          <input
                            type="text"
                            value={editValue}
                            onChange={(e) => setEditValue(e.target.value)}
                            className="w-40 rounded border px-2 py-1 text-sm"
                            autoFocus
                          />
                          <button
                            onClick={() => {
                              void (async () => {
                                try {
                                  await updateSystemParam(p.parameterKey, editValue);
                                  setSysParams((prev) =>
                                    prev.map((sp) =>
                                      sp.parameterKey === p.parameterKey
                                        ? { ...sp, parameterValue: editValue }
                                        : sp
                                    )
                                  );
                                  setEditingParam(null);
                                  setSuccess('✅ Paraméter mentve!');
                                } catch {
                                  setError('Paraméter mentése sikertelen.');
                                }
                              })();
                            }}
                            className="rounded bg-green-500 px-2 py-1 text-xs text-white hover:bg-green-600"
                          >
                            ✅
                          </button>
                          <button
                            onClick={() => setEditingParam(null)}
                            className="rounded bg-gray-300 px-2 py-1 text-xs hover:bg-gray-400"
                          >
                            ✖
                          </button>
                        </div>
                      ) : (
                        <div className="flex items-center gap-2">
                          <span className="text-sm text-gray-600">{p.parameterValue}</span>
                          <button
                            onClick={() => {
                              setEditingParam(p.parameterKey);
                              setEditValue(p.parameterValue);
                            }}
                            className="rounded bg-blue-100 px-2 py-1 text-xs text-blue-700 hover:bg-blue-200"
                          >
                            ✏️
                          </button>
                        </div>
                      )}
                    </div>
                  ))}
                {sysParams.filter((p) => p.category === activeParamCat).length === 0 && (
                  <p className="text-sm text-gray-400">Nincs paraméter ebben a kategóriában.</p>
                )}
              </div>
            </div>
          )}

          {/* Offline adatok */}
          <div className="rounded-xl border bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-700">📡 Offline adatok</h2>
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Szinkronizálatlan tranzakciók:</p>
                <p className={`text-2xl font-bold ${pendingCount > 0 ? 'text-orange-600' : 'text-green-600'}`}>
                  {pendingCount}
                </p>
              </div>
              <button
                onClick={() => void handleSync()}
                disabled={isSyncing || pendingCount === 0}
                className={`btn-primary ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'} disabled:opacity-50`}
              >
                {isSyncing ? '⏳ Szinkronizálás...' : '🔄 Szinkronizálás most'}
              </button>
            </div>
          </div>

          {/* Mentés gomb */}
          {success && (
            <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">{success}</div>
          )}
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">⚠️ {error}</div>
          )}

          <button
            onClick={() => void handleSave()}
            disabled={isSaving}
            className={`btn-primary w-full ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'} disabled:opacity-50`}
          >
            {isSaving ? '⏳ Mentés...' : '💾 Beállítások mentése'}
          </button>

          {/* Verzió + kijelentkezés */}
          <div className="flex items-center justify-between rounded-xl border bg-gray-50 p-4">
            <p className="text-sm text-gray-500">
              Valuta Pénztár v{appVersion || '1.0.0'}
            </p>
            <button
              onClick={handleLogout}
              className="rounded-lg bg-red-100 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-200"
            >
              🚪 Kijelentkezés
            </button>
          </div>
        </div>
      </main>
    </div>
  );
}

