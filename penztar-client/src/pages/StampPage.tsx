import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  getStampInventory,
  receiveStampBatch,
  assignStamp,
  getUsedStamps,
} from '@/api/stamps';
import type { StampBatch, StampAssignment } from '@/types';

type TabView = 'inventory' | 'receive' | 'assign' | 'used';

export default function StampPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [tab, setTab] = useState<TabView>('inventory');
  const [batches, setBatches] = useState<StampBatch[]>([]);
  const [usedStamps, setUsedStamps] = useState<StampAssignment[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Új batch form
  const [batchBranchId, setBatchBranchId] = useState('');
  const [batchPrefix, setBatchPrefix] = useState('');
  const [batchStart, setBatchStart] = useState('');
  const [batchEnd, setBatchEnd] = useState('');
  const [batchNote, setBatchNote] = useState('');

  // Hozzárendelés form
  const [assignSerial, setAssignSerial] = useState('');
  const [assignTxId, setAssignTxId] = useState('');

  const loadInventory = useCallback(async () => {
    setIsLoading(true);
    try {
      const data = await getStampInventory();
      setBatches(data);
    } catch (err: unknown) {
      console.error('[Stamp] Készlet betöltése hiba:', err);
      setError('Matrica készlet betöltése sikertelen.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  const loadUsed = useCallback(async () => {
    setIsLoading(true);
    try {
      const data = await getUsedStamps();
      setUsedStamps(data);
    } catch (err: unknown) {
      console.error('[Stamp] Felhasznált betöltése hiba:', err);
      setError('Felhasznált matricák betöltése sikertelen.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadInventory();
  }, [loadInventory]);

  useEffect(() => {
    if (tab === 'used') {
      void loadUsed();
    }
  }, [tab, loadUsed]);

  const handleReceive = useCallback(async () => {
    if (!batchBranchId || !batchPrefix || !batchStart || !batchEnd) {
      setError('Minden mező kitöltése kötelező!');
      return;
    }
    const start = parseInt(batchStart, 10);
    const end = parseInt(batchEnd, 10);
    if (end < start) {
      setError('A záró sorszám nem lehet kisebb a kezdőnél!');
      return;
    }
    setError('');
    setSuccess('');
    try {
      await receiveStampBatch({
        branchId: batchBranchId,
        serialPrefix: batchPrefix,
        serialStart: start,
        serialEnd: end,
        note: batchNote || undefined,
      });
      setSuccess(`✅ Matrica batch felvéve: ${batchPrefix}-${batchStart} — ${batchPrefix}-${batchEnd}`);
      setBatchPrefix('');
      setBatchStart('');
      setBatchEnd('');
      setBatchNote('');
      setTab('inventory');
      void loadInventory();
    } catch (err: unknown) {
      setError('❌ Batch felvétel sikertelen.');
    }
  }, [batchBranchId, batchPrefix, batchStart, batchEnd, batchNote, loadInventory]);

  const handleAssign = useCallback(async () => {
    if (!assignSerial || !assignTxId) {
      setError('Sorszám és tranzakció ID kötelező!');
      return;
    }
    setError('');
    setSuccess('');
    try {
      await assignStamp({
        serialNumber: assignSerial,
        transactionId: parseInt(assignTxId, 10),
      });
      setSuccess(`✅ Matrica hozzárendelve: ${assignSerial} → Tranzakció #${assignTxId}`);
      setAssignSerial('');
      setAssignTxId('');
      void loadInventory();
    } catch (err: unknown) {
      setError('❌ Hozzárendelés sikertelen.');
    }
  }, [assignSerial, assignTxId, loadInventory]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const tabItems: { key: TabView; label: string; icon: string }[] = [
    { key: 'inventory', label: 'Készlet', icon: '📦' },
    { key: 'receive', label: 'Új batch', icon: '➕' },
    { key: 'assign', label: 'Hozzárendelés', icon: '🔗' },
    { key: 'used', label: 'Felhasznált', icon: '✅' },
  ];

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🏷️ Matrica pénztár</h1>
          <button onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex flex-1 overflow-hidden">
        {/* Tabs */}
        <nav className="w-48 border-r bg-gray-50 p-3">
          {tabItems.map((t) => (
            <button key={t.key}
              onClick={() => { setTab(t.key); setError(''); setSuccess(''); }}
              className={`mb-1 w-full rounded-lg px-3 py-2 text-left text-sm transition ${
                tab === t.key
                  ? 'bg-amber-100 font-semibold text-amber-800'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}>
              {t.icon} {t.label}
            </button>
          ))}
        </nav>

        <div className="flex-1 overflow-auto p-6">
          {error && <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>}
          {success && <div className="mb-4 rounded-lg bg-green-50 p-3 text-sm text-green-700">{success}</div>}

          {/* Készlet */}
          {tab === 'inventory' && (
            <div>
              <h2 className="mb-4 text-lg font-bold text-gray-800">📦 Matrica készlet</h2>
              {isLoading ? (
                <p className="text-gray-400">⏳ Betöltés...</p>
              ) : batches.length === 0 ? (
                <p className="text-gray-400">Nincs matrica készlet. Vegyen fel új batch-et!</p>
              ) : (
                <div className="overflow-auto rounded-lg border">
                  <table className="min-w-full text-sm">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Előtag</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Tartomány</th>
                        <th className="px-3 py-2 text-right font-medium text-gray-600">Összes</th>
                        <th className="px-3 py-2 text-right font-medium text-gray-600">Felhasznált</th>
                        <th className="px-3 py-2 text-right font-medium text-gray-600">Szabad</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Felvétel dátum</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Megjegyzés</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y">
                      {batches.map((b) => {
                        const free = b.totalCount - b.usedCount;
                        return (
                          <tr key={b.id} className="hover:bg-gray-50">
                            <td className="px-3 py-2 font-mono font-bold">{b.serialPrefix}</td>
                            <td className="px-3 py-2 font-mono text-xs">
                              {b.serialPrefix}-{String(b.serialStart).padStart(6, '0')} — {b.serialPrefix}-{String(b.serialEnd).padStart(6, '0')}
                            </td>
                            <td className="px-3 py-2 text-right">{b.totalCount}</td>
                            <td className="px-3 py-2 text-right text-red-600">{b.usedCount}</td>
                            <td className="px-3 py-2 text-right font-bold text-green-600">{free}</td>
                            <td className="px-3 py-2 text-xs text-gray-500">
                              {new Date(b.receivedAt).toLocaleDateString('hu-HU')}
                            </td>
                            <td className="px-3 py-2 text-xs text-gray-400">{b.note ?? '—'}</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* Új batch */}
          {tab === 'receive' && (
            <div className="max-w-lg space-y-4">
              <h2 className="text-lg font-bold text-gray-800">➕ Új matrica batch felvétele</h2>
              <input type="text" value={batchBranchId}
                onChange={(e) => setBatchBranchId(e.target.value)}
                className="input-field w-full" placeholder="Iroda ID (UUID)" />
              <input type="text" value={batchPrefix}
                onChange={(e) => setBatchPrefix(e.target.value.toUpperCase())}
                className="input-field w-full" placeholder="Sorszám előtag (pl. AA)" maxLength={5} />
              <div className="grid grid-cols-2 gap-3">
                <input type="number" value={batchStart}
                  onChange={(e) => setBatchStart(e.target.value)}
                  className="input-field" placeholder="Kezdő sorszám" min="1" />
                <input type="number" value={batchEnd}
                  onChange={(e) => setBatchEnd(e.target.value)}
                  className="input-field" placeholder="Záró sorszám" min="1" />
              </div>
              {batchStart && batchEnd && parseInt(batchEnd) >= parseInt(batchStart) && (
                <p className="text-sm text-gray-500">
                  Összesen: <strong>{parseInt(batchEnd) - parseInt(batchStart) + 1}</strong> db matrica
                </p>
              )}
              <input type="text" value={batchNote}
                onChange={(e) => setBatchNote(e.target.value)}
                className="input-field w-full" placeholder="Megjegyzés (opcionális)" />
              <button onClick={handleReceive}
                className="btn-primary w-full bg-amber-600 hover:bg-amber-700">
                📦 Batch felvétele
              </button>
            </div>
          )}

          {/* Hozzárendelés */}
          {tab === 'assign' && (
            <div className="max-w-lg space-y-4">
              <h2 className="text-lg font-bold text-gray-800">🔗 Matrica hozzárendelés</h2>
              <p className="text-sm text-gray-500">
                Rendelje hozzá a matrica sorszámot egy tranzakcióhoz.
              </p>
              <input type="text" value={assignSerial}
                onChange={(e) => setAssignSerial(e.target.value.toUpperCase())}
                className="input-field w-full" placeholder="Matrica sorszám (pl. AA-000001)" />
              <input type="number" value={assignTxId}
                onChange={(e) => setAssignTxId(e.target.value)}
                className="input-field w-full" placeholder="Tranzakció ID" />
              <button onClick={handleAssign}
                className="btn-primary w-full bg-amber-600 hover:bg-amber-700">
                🔗 Hozzárendelés
              </button>
            </div>
          )}

          {/* Felhasznált */}
          {tab === 'used' && (
            <div>
              <h2 className="mb-4 text-lg font-bold text-gray-800">✅ Felhasznált matricák</h2>
              {isLoading ? (
                <p className="text-gray-400">⏳ Betöltés...</p>
              ) : usedStamps.length === 0 ? (
                <p className="text-gray-400">Még nincs felhasznált matrica.</p>
              ) : (
                <div className="overflow-auto rounded-lg border">
                  <table className="min-w-full text-sm">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Sorszám</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Tranzakció ID</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Hozzárendelő</th>
                        <th className="px-3 py-2 text-left font-medium text-gray-600">Dátum</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y">
                      {usedStamps.map((s) => (
                        <tr key={s.id} className="hover:bg-gray-50">
                          <td className="px-3 py-2 font-mono font-bold">{s.serialNumber}</td>
                          <td className="px-3 py-2">{s.transactionId ?? '—'}</td>
                          <td className="px-3 py-2 text-gray-500">{s.assignedBy ?? '—'}</td>
                          <td className="px-3 py-2 text-xs text-gray-400">
                            {new Date(s.assignedAt).toLocaleString('hu-HU')}
                          </td>
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


