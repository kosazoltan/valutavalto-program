import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  getWorkers,
  createWorker,
  updateWorker,
  resetWorkerPassword,
  getWorkerAttendance,
  startWorkerBreak,
  endWorkerBreak,
} from '@/api/workers';
import type { WorkerDetail, WorkerAttendance } from '@/types';

type TabView = 'list' | 'create' | 'edit' | 'attendance' | 'breaks';

export default function WorkerManagementPage() {
  const navigate = useNavigate();
  const { companyType, user } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [tab, setTab] = useState<TabView>('list');
  const [workers, setWorkers] = useState<WorkerDetail[]>([]);
  const [selectedWorker, setSelectedWorker] = useState<WorkerDetail | null>(null);
  const [attendance, setAttendance] = useState<WorkerAttendance[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Form state
  const [formCode, setFormCode] = useState('');
  const [formName, setFormName] = useState('');
  const [formEmail, setFormEmail] = useState('');
  const [formPhone, setFormPhone] = useState('');
  const [formRole, setFormRole] = useState<string>('CASHIER');
  const [formPassword, setFormPassword] = useState('');
  const [formActive, setFormActive] = useState(true);

  // Jelszó reset
  const [resetPwWorkerId, setResetPwWorkerId] = useState<number | null>(null);
  const [resetPwValue, setResetPwValue] = useState('');

  const loadWorkers = useCallback(async () => {
    setIsLoading(true);
    try {
      const data = await getWorkers();
      setWorkers(data);
    } catch (err) {
      console.error('[WorkerMgmt] Betöltés hiba:', err);
      setError('Dolgozók betöltése sikertelen.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadWorkers();
  }, [loadWorkers]);

  const handleCreate = useCallback(async () => {
    if (!formCode || !formName || !formPassword) {
      setError('Kód, név és jelszó kötelező!');
      return;
    }
    setError('');
    setSuccess('');
    try {
      await createWorker({
        companyId: user?.companyId?.toString() ?? '',
        branchId: '',
        code: formCode,
        name: formName,
        password: formPassword,
        role: formRole,
        phone: formPhone || undefined,
        email: formEmail || undefined,
      });
      setSuccess('✅ Új pénztáros létrehozva!');
      setTab('list');
      void loadWorkers();
      setFormCode(''); setFormName(''); setFormPassword('');
      setFormEmail(''); setFormPhone(''); setFormRole('CASHIER');
    } catch {
      setError('❌ Létrehozás sikertelen.');
    }
  }, [formCode, formName, formPassword, formRole, formPhone, formEmail, user, loadWorkers]);

  const handleUpdate = useCallback(async () => {
    if (!selectedWorker) return;
    setError('');
    setSuccess('');
    try {
      await updateWorker(selectedWorker.id, {
        name: formName || undefined,
        role: formRole || undefined,
        phone: formPhone || undefined,
        email: formEmail || undefined,
        active: formActive,
      });
      setSuccess('✅ Pénztáros adatai frissítve!');
      setTab('list');
      void loadWorkers();
    } catch {
      setError('❌ Módosítás sikertelen.');
    }
  }, [selectedWorker, formName, formRole, formPhone, formEmail, formActive, loadWorkers]);

  const handleResetPassword = useCallback(async () => {
    if (!resetPwWorkerId || !resetPwValue) return;
    setError('');
    setSuccess('');
    try {
      await resetWorkerPassword(resetPwWorkerId, resetPwValue);
      setSuccess('✅ Jelszó sikeresen resetelve!');
      setResetPwWorkerId(null);
      setResetPwValue('');
    } catch {
      setError('❌ Jelszó reset sikertelen.');
    }
  }, [resetPwWorkerId, resetPwValue]);

  const handleSelectForEdit = useCallback((w: WorkerDetail) => {
    setSelectedWorker(w);
    setFormCode(w.code);
    setFormName(w.name);
    setFormEmail(w.email ?? '');
    setFormPhone(w.phone ?? '');
    setFormRole(w.role);
    setFormActive(w.active);
    setTab('edit');
  }, []);

  const handleShowAttendance = useCallback(async (w: WorkerDetail) => {
    setSelectedWorker(w);
    setTab('attendance');
    try {
      const data = await getWorkerAttendance(w.id);
      setAttendance(data.content);
    } catch {
      setError('Jelenlét napló betöltése sikertelen.');
    }
  }, []);

  const handleStartBreak = useCallback(async (workerId: number) => {
    try {
      await startWorkerBreak(workerId, 'Supervisor által engedélyezett szünet');
      setSuccess('✅ Szünet elindítva!');
      void loadWorkers();
    } catch {
      setError('❌ Szünet indítás sikertelen.');
    }
  }, [loadWorkers]);

  const handleEndBreak = useCallback(async (workerId: number) => {
    try {
      await endWorkerBreak(workerId);
      setSuccess('✅ Szünet befejezve!');
      void loadWorkers();
    } catch {
      setError('❌ Szünet befejezés sikertelen.');
    }
  }, [loadWorkers]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (tab !== 'list') {
          setTab('list');
          setError('');
          setSuccess('');
        } else {
          navigate('/menu');
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate, tab]);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">👥 Pénztáros kezelés</h1>
          <div className="flex gap-2">
            {tab !== 'list' && (
              <button onClick={() => { setTab('list'); setError(''); setSuccess(''); }}
                className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
                ← Lista
              </button>
            )}
            <button onClick={() => navigate('/menu')}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
              ← Vissza (ESC)
            </button>
          </div>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-6xl">
          {error && <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>}
          {success && <div className="mb-4 rounded-lg bg-green-50 p-3 text-sm text-green-700">{success}</div>}

          {/* Lista nézet */}
          {tab === 'list' && (
            <>
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-lg font-semibold text-gray-700">Pénztárosok</h2>
                <button onClick={() => { setTab('create'); setFormCode(''); setFormName(''); setFormPassword(''); }}
                  className="rounded-lg bg-green-600 px-4 py-2 text-sm text-white hover:bg-green-700">
                  ➕ Új pénztáros
                </button>
              </div>
              {isLoading ? (
                <p className="text-gray-400">⏳ Betöltés...</p>
              ) : (
                <div className="overflow-auto rounded-lg border">
                  <table className="min-w-full text-sm">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Kód</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Név</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Email</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Szerep</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Státusz</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Utolsó belépés</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Műveletek</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y">
                      {workers.map((w) => (
                        <tr key={w.id} className="hover:bg-gray-50">
                          <td className="px-3 py-2 font-mono">{w.code}</td>
                          <td className="px-3 py-2 font-medium">{w.name}</td>
                          <td className="px-3 py-2 text-gray-500">{w.email ?? '—'}</td>
                          <td className="px-3 py-2">
                            <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                              w.role === 'ADMIN' ? 'bg-red-100 text-red-700'
                                : w.role === 'MANAGER' ? 'bg-blue-100 text-blue-700'
                                : w.role === 'SUPERVISOR' ? 'bg-purple-100 text-purple-700'
                                : 'bg-gray-100 text-gray-700'
                            }`}>{w.role}</span>
                          </td>
                          <td className="px-3 py-2">
                            {w.active
                              ? <span className="text-green-600">✅ Aktív</span>
                              : <span className="text-red-500">❌ Inaktív</span>
                            }
                          </td>
                          <td className="px-3 py-2 text-xs text-gray-400">
                            {w.lastLoginAt ? new Date(w.lastLoginAt).toLocaleString('hu-HU') : '—'}
                          </td>
                          <td className="px-3 py-2">
                            <div className="flex gap-1">
                              <button onClick={() => handleSelectForEdit(w)}
                                className="rounded bg-blue-100 px-2 py-1 text-xs text-blue-700 hover:bg-blue-200">
                                ✏️
                              </button>
                              <button onClick={() => { setResetPwWorkerId(w.id); setResetPwValue(''); }}
                                className="rounded bg-yellow-100 px-2 py-1 text-xs text-yellow-700 hover:bg-yellow-200">
                                🔑
                              </button>
                              <button onClick={() => handleShowAttendance(w)}
                                className="rounded bg-gray-100 px-2 py-1 text-xs text-gray-700 hover:bg-gray-200">
                                📋
                              </button>
                              <button onClick={() => handleStartBreak(w.id)}
                                className="rounded bg-green-100 px-2 py-1 text-xs text-green-700 hover:bg-green-200">
                                ☕
                              </button>
                              <button onClick={() => handleEndBreak(w.id)}
                                className="rounded bg-orange-100 px-2 py-1 text-xs text-orange-700 hover:bg-orange-200">
                                ⏹️
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {/* Jelszó reset modal */}
              {resetPwWorkerId !== null && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                  <div className="w-96 rounded-xl bg-white p-6 shadow-xl">
                    <h3 className="mb-4 text-lg font-bold">🔑 Jelszó reset</h3>
                    <input type="password" value={resetPwValue}
                      onChange={(e) => setResetPwValue(e.target.value)}
                      className="input-field mb-4 w-full" placeholder="Új jelszó" autoFocus />
                    <div className="flex gap-2">
                      <button onClick={handleResetPassword}
                        className="btn-primary flex-1 bg-yellow-600 hover:bg-yellow-700">
                        Jelszó reset
                      </button>
                      <button onClick={() => setResetPwWorkerId(null)}
                        className="flex-1 rounded-lg border px-4 py-2 text-sm hover:bg-gray-50">
                        Mégse
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </>
          )}

          {/* Létrehozás nézet */}
          {tab === 'create' && (
            <div className="max-w-lg space-y-4">
              <h2 className="text-lg font-bold text-gray-800">➕ Új pénztáros felvétele</h2>
              <input type="text" value={formCode} onChange={(e) => setFormCode(e.target.value)}
                className="input-field w-full" placeholder="Pénztáros kód (pl. P001)" />
              <input type="text" value={formName} onChange={(e) => setFormName(e.target.value)}
                className="input-field w-full" placeholder="Teljes név" />
              <input type="email" value={formEmail} onChange={(e) => setFormEmail(e.target.value)}
                className="input-field w-full" placeholder="Email (opcionális)" />
              <input type="tel" value={formPhone} onChange={(e) => setFormPhone(e.target.value)}
                className="input-field w-full" placeholder="Telefon (opcionális)" />
              <select value={formRole} onChange={(e) => setFormRole(e.target.value)}
                className="input-field w-full">
                <option value="CASHIER">Pénztáros</option>
                <option value="SUPERVISOR">Főnök</option>
                <option value="MANAGER">Vezető</option>
                <option value="ADMIN">Rendszergazda</option>
              </select>
              <input type="password" value={formPassword}
                onChange={(e) => setFormPassword(e.target.value)}
                className="input-field w-full" placeholder="Jelszó" />
              <button onClick={handleCreate}
                className="btn-primary w-full bg-green-600 hover:bg-green-700">
                ✅ Létrehozás
              </button>
            </div>
          )}

          {/* Szerkesztés nézet */}
          {tab === 'edit' && selectedWorker && (
            <div className="max-w-lg space-y-4">
              <h2 className="text-lg font-bold text-gray-800">✏️ Pénztáros módosítás: {selectedWorker.code}</h2>
              <input type="text" value={formName} onChange={(e) => setFormName(e.target.value)}
                className="input-field w-full" placeholder="Teljes név" />
              <input type="email" value={formEmail} onChange={(e) => setFormEmail(e.target.value)}
                className="input-field w-full" placeholder="Email" />
              <input type="tel" value={formPhone} onChange={(e) => setFormPhone(e.target.value)}
                className="input-field w-full" placeholder="Telefon" />
              <select value={formRole} onChange={(e) => setFormRole(e.target.value)}
                className="input-field w-full">
                <option value="CASHIER">Pénztáros</option>
                <option value="SUPERVISOR">Főnök</option>
                <option value="MANAGER">Vezető</option>
                <option value="ADMIN">Rendszergazda</option>
              </select>
              <label className="flex items-center gap-2">
                <input type="checkbox" checked={formActive}
                  onChange={(e) => setFormActive(e.target.checked)} />
                <span className="text-sm text-gray-700">Aktív</span>
              </label>
              <button onClick={handleUpdate}
                className="btn-primary w-full bg-blue-600 hover:bg-blue-700">
                💾 Mentés
              </button>
            </div>
          )}

          {/* Jelenlét napló nézet */}
          {tab === 'attendance' && selectedWorker && (
            <div className="space-y-4">
              <h2 className="text-lg font-bold text-gray-800">
                📋 Jelenlét napló: {selectedWorker.name} ({selectedWorker.code})
              </h2>
              {attendance.length === 0 ? (
                <p className="text-sm text-gray-400">Nincs jelenlét adat.</p>
              ) : (
                <div className="overflow-auto rounded-lg border">
                  <table className="min-w-full text-sm">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Belépés</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Kilépés</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">IP cím</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y">
                      {attendance.map((a) => (
                        <tr key={a.id} className="hover:bg-gray-50">
                          <td className="px-3 py-2">{new Date(a.loginAt).toLocaleString('hu-HU')}</td>
                          <td className="px-3 py-2">
                            {a.logoutAt ? new Date(a.logoutAt).toLocaleString('hu-HU') : '—'}
                          </td>
                          <td className="px-3 py-2 text-xs text-gray-400">{a.ipAddress ?? '—'}</td>
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
