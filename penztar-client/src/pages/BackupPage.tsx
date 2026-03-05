import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { createBackup, restoreBackup, getBackupHistory } from '@/api/backup';
import type { BackupRecordData, BackupType } from '@/types';

export default function BackupPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [records, setRecords] = useState<BackupRecordData[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [restoring, setRestoring] = useState<string | null>(null);
  const [confirmRestore, setConfirmRestore] = useState<string | null>(null);
  const [confirmStep, setConfirmStep] = useState(0);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const loadHistory = useCallback(async () => {
    try {
      const result = await getBackupHistory(0, 50);
      setRecords(result.content);
    } catch (err) {
      console.error('[BackupPage] Betöltési hiba:', err);
      setError('Mentés előzmények betöltése sikertelen.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadHistory();
  }, [loadHistory]);

  const handleCreate = useCallback(async (type: BackupType = 'FULL') => {
    if (creating) return;
    setCreating(true);
    setError('');
    setSuccess('');

    try {
      await createBackup(type);
      setSuccess(`✅ ${type} mentés sikeresen létrehozva!`);
      await loadHistory();
    } catch (err) {
      console.error('[BackupPage] Mentés hiba:', err);
      setError('Mentés létrehozása sikertelen.');
    } finally {
      setCreating(false);
    }
  }, [creating, loadHistory]);

  const handleRestore = useCallback(async (id: string) => {
    if (confirmRestore !== id) {
      setConfirmRestore(id);
      setConfirmStep(1);
      return;
    }

    if (confirmStep === 1) {
      setConfirmStep(2);
      return;
    }

    // Második megerősítés után indítjuk
    setRestoring(id);
    setError('');
    setSuccess('');

    try {
      await restoreBackup(id);
      setSuccess('✅ Visszaállítás sikeresen elindítva!');
    } catch (err) {
      console.error('[BackupPage] Visszaállítás hiba:', err);
      setError('Visszaállítás sikertelen.');
    } finally {
      setRestoring(null);
      setConfirmRestore(null);
      setConfirmStep(0);
    }
  }, [confirmRestore, confirmStep]);

  const cancelRestore = useCallback(() => {
    setConfirmRestore(null);
    setConfirmStep(0);
  }, []);

  const formatSize = (bytes: number | null): string => {
    if (!bytes) return '—';
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / 1048576).toFixed(1)} MB`;
  };

  const formatDate = (iso: string | null): string => {
    if (!iso) return '—';
    return new Date(iso).toLocaleString('hu-HU');
  };

  const statusLabel = (status: string): string => {
    switch (status) {
      case 'RUNNING': return '⏳ Folyamatban';
      case 'COMPLETED': return '✅ Kész';
      case 'FAILED': return '❌ Sikertelen';
      default: return status;
    }
  };

  const typeLabel = (type: string): string => {
    switch (type) {
      case 'FULL': return 'Teljes';
      case 'INCREMENTAL': return 'Inkrementális';
      case 'TABLES_ONLY': return 'Táblák';
      default: return type;
    }
  };

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/settings');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">💾 Backup / Visszaállítás</h1>
          <button
            onClick={() => navigate('/settings')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-4xl space-y-6">
          {/* Akciók */}
          <div className="rounded-xl border bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-700">📦 Új mentés</h2>
            <div className="flex gap-3">
              <button
                onClick={() => void handleCreate('FULL')}
                disabled={creating}
                className={`btn-primary ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'} disabled:opacity-50`}
              >
                {creating ? '⏳ Mentés...' : '🗄️ Teljes mentés'}
              </button>
              <button
                onClick={() => void handleCreate('TABLES_ONLY')}
                disabled={creating}
                className="rounded-lg border bg-gray-100 px-4 py-2 text-sm hover:bg-gray-200 disabled:opacity-50"
              >
                📋 Csak táblák
              </button>
            </div>
          </div>

          {/* Üzenetek */}
          {success && (
            <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">{success}</div>
          )}
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">⚠️ {error}</div>
          )}

          {/* Mentések listája */}
          <div className="rounded-xl border bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-700">📜 Mentés előzmények</h2>

            {loading ? (
              <p className="text-gray-500">⏳ Betöltés...</p>
            ) : records.length === 0 ? (
              <p className="text-gray-400">Nincs mentés előzmény.</p>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead>
                    <tr className="border-b text-gray-500">
                      <th className="pb-2 pr-4">Időpont</th>
                      <th className="pb-2 pr-4">Típus</th>
                      <th className="pb-2 pr-4">Méret</th>
                      <th className="pb-2 pr-4">Státusz</th>
                      <th className="pb-2">Művelet</th>
                    </tr>
                  </thead>
                  <tbody>
                    {records.map((rec) => (
                      <tr key={rec.id} className="border-b last:border-0">
                        <td className="py-2 pr-4">{formatDate(rec.startedAt)}</td>
                        <td className="py-2 pr-4">{typeLabel(rec.backupType)}</td>
                        <td className="py-2 pr-4">{formatSize(rec.fileSizeBytes)}</td>
                        <td className="py-2 pr-4">{statusLabel(rec.status)}</td>
                        <td className="py-2">
                          {rec.status === 'COMPLETED' && (
                            <div className="flex gap-2">
                              {confirmRestore === rec.id ? (
                                <>
                                  <button
                                    onClick={() => void handleRestore(rec.id)}
                                    disabled={restoring === rec.id}
                                    className="rounded bg-red-600 px-3 py-1 text-xs text-white hover:bg-red-700"
                                  >
                                    {confirmStep === 1
                                      ? '⚠️ Megerősítés (1/2)'
                                      : restoring === rec.id
                                        ? '⏳ Visszaállítás...'
                                        : '🔴 VÉGLEGES visszaállítás (2/2)'}
                                  </button>
                                  <button
                                    onClick={cancelRestore}
                                    className="rounded bg-gray-200 px-3 py-1 text-xs hover:bg-gray-300"
                                  >
                                    Mégsem
                                  </button>
                                </>
                              ) : (
                                <button
                                  onClick={() => void handleRestore(rec.id)}
                                  className="rounded bg-blue-100 px-3 py-1 text-xs text-blue-700 hover:bg-blue-200"
                                >
                                  🔄 Visszaállítás
                                </button>
                              )}
                            </div>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
