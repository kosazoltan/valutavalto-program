import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  calculateAllCommissions,
  approveCommission,
  getCommissionReport,
  type CommissionCalculationResponse,
} from '@/api/commissions';

function formatHuf(value: number): string {
  return new Intl.NumberFormat('hu-HU', {
    style: 'currency',
    currency: 'HUF',
    maximumFractionDigits: 0,
  }).format(value);
}

function formatPercent(value: number): string {
  return (value * 100).toFixed(2) + '%';
}

function getCurrentYearMonth(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

const STATUS_LABELS: Record<string, { label: string; color: string }> = {
  CALCULATED: { label: 'Számítva', color: 'bg-yellow-100 text-yellow-800' },
  APPROVED: { label: 'Jóváhagyva', color: 'bg-green-100 text-green-800' },
  PAID: { label: 'Kifizetve', color: 'bg-blue-100 text-blue-800' },
};

export default function CommissionPage() {
  const navigate = useNavigate();
  const { user } = useAuthStore();

  const [yearMonth, setYearMonth] = useState(getCurrentYearMonth());
  const [branchId, setBranchId] = useState('');
  const [commissions, setCommissions] = useState<CommissionCalculationResponse[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleLoadReport = useCallback(async () => {
    if (!branchId) {
      setError('Kérjük, adja meg az iroda azonosítót!');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const data = await getCommissionReport(branchId, yearMonth);
      setCommissions(data);
    } catch {
      setCommissions([]);
      setError('Nincs jutalék adat erre az időszakra.');
    } finally {
      setLoading(false);
    }
  }, [branchId, yearMonth]);

  const handleCalculateAll = useCallback(async () => {
    if (!branchId) return;
    setLoading(true);
    setError('');
    setSuccess('');
    try {
      const data = await calculateAllCommissions(branchId, yearMonth);
      setCommissions(data);
      setSuccess(`${data.length} pénztáros jutaléka kiszámítva.`);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Hiba a számítás során';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [branchId, yearMonth]);

  const handleApprove = useCallback(async (id: string) => {
    setLoading(true);
    setError('');
    try {
      const updated = await approveCommission(id);
      setCommissions((prev) =>
        prev.map((c) => (c.id === updated.id ? updated : c)),
      );
      setSuccess('Jutalék jóváhagyva.');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Hiba a jóváhagyás során';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, []);

  // Összesítő
  const totals = commissions.reduce(
    (acc, c) => ({
      totalVolume: acc.totalVolume + c.totalVolumeHuf,
      totalCommission: acc.totalCommission + c.netCommission,
      totalTx: acc.totalTx + c.totalTransactions,
    }),
    { totalVolume: 0, totalCommission: 0, totalTx: 0 },
  );

  return (
    <div className="flex h-screen flex-col">
      <header className="bg-indigo-600 px-6 py-4 text-white shadow-lg">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">💰 Jutalék számítás</h1>
            <p className="text-sm text-white/80">
              {user?.fullName ?? 'Felhasználó'} | Havi jutalék elszámolás
            </p>
          </div>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm font-medium text-white transition hover:bg-white/30"
          >
            ← Vissza
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-6xl space-y-6">
          {/* Szűrők */}
          <div className="rounded-lg border bg-white p-4 shadow-sm">
            <div className="flex flex-wrap items-end gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">Iroda ID</label>
                <input
                  type="text"
                  value={branchId}
                  onChange={(e) => setBranchId(e.target.value)}
                  placeholder="pl. 550e8400-e29b-..."
                  className="w-72 rounded border px-3 py-2 text-sm"
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">Hónap</label>
                <input
                  type="month"
                  value={yearMonth}
                  onChange={(e) => setYearMonth(e.target.value)}
                  className="rounded border px-3 py-2 text-sm"
                />
              </div>
              <button
                onClick={() => void handleLoadReport()}
                disabled={loading}
                className="rounded bg-indigo-500 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-600 disabled:opacity-50"
              >
                📊 Riport betöltése
              </button>
              <button
                onClick={() => void handleCalculateAll()}
                disabled={loading || !branchId}
                className="rounded bg-green-500 px-4 py-2 text-sm font-medium text-white hover:bg-green-600 disabled:opacity-50"
              >
                🔢 Számítás indítása
              </button>
            </div>
          </div>

          {error && (
            <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700">
              ⚠️ {error}
            </div>
          )}
          {success && (
            <div className="rounded-lg border border-green-200 bg-green-50 p-3 text-sm text-green-700">
              ✅ {success}
            </div>
          )}

          {/* Összesítő kártyák */}
          {commissions.length > 0 && (
            <div className="grid grid-cols-3 gap-4">
              <div className="rounded-lg border bg-indigo-50 p-4">
                <div className="text-sm text-indigo-600">Össz forgalom</div>
                <div className="text-xl font-bold text-indigo-800">
                  {formatHuf(totals.totalVolume)}
                </div>
              </div>
              <div className="rounded-lg border bg-green-50 p-4">
                <div className="text-sm text-green-600">Össz jutalék</div>
                <div className="text-xl font-bold text-green-800">
                  {formatHuf(totals.totalCommission)}
                </div>
              </div>
              <div className="rounded-lg border bg-orange-50 p-4">
                <div className="text-sm text-orange-600">Tranzakciók</div>
                <div className="text-xl font-bold text-orange-800">
                  {totals.totalTx} db
                </div>
              </div>
            </div>
          )}

          {/* Pénztárosok táblázat */}
          {commissions.length > 0 && (
            <div className="rounded-lg border bg-white shadow-sm">
              <div className="border-b px-4 py-3">
                <h2 className="font-semibold text-gray-800">👥 Pénztárosok jutaléka</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left">Dolgozó ID</th>
                      <th className="px-4 py-2 text-right">Tranzakciók</th>
                      <th className="px-4 py-2 text-right">Forgalom (HUF)</th>
                      <th className="px-4 py-2 text-right">Kulcs</th>
                      <th className="px-4 py-2 text-right">Jutalék</th>
                      <th className="px-4 py-2 text-right">Bónusz</th>
                      <th className="px-4 py-2 text-right">Nettó jutalék</th>
                      <th className="px-4 py-2 text-center">Státusz</th>
                      <th className="px-4 py-2 text-center">Művelet</th>
                    </tr>
                  </thead>
                  <tbody>
                    {commissions.map((c) => {
                      const statusInfo = STATUS_LABELS[c.status] ?? { label: c.status, color: 'bg-gray-100' };
                      return (
                        <tr key={c.id} className="border-t hover:bg-gray-50">
                          <td className="px-4 py-2 font-mono">{c.workerId}</td>
                          <td className="px-4 py-2 text-right">{c.totalTransactions}</td>
                          <td className="px-4 py-2 text-right">{formatHuf(c.totalVolumeHuf)}</td>
                          <td className="px-4 py-2 text-right">{formatPercent(c.commissionRate)}</td>
                          <td className="px-4 py-2 text-right">{formatHuf(c.commissionAmount)}</td>
                          <td className="px-4 py-2 text-right">{formatHuf(c.bonusAmount)}</td>
                          <td className="px-4 py-2 text-right font-bold">{formatHuf(c.netCommission)}</td>
                          <td className="px-4 py-2 text-center">
                            <span className={`rounded-full px-2 py-1 text-xs font-medium ${statusInfo.color}`}>
                              {statusInfo.label}
                            </span>
                          </td>
                          <td className="px-4 py-2 text-center">
                            {c.status === 'CALCULATED' && (
                              <button
                                onClick={() => void handleApprove(c.id)}
                                disabled={loading}
                                className="rounded bg-green-500 px-3 py-1 text-xs text-white hover:bg-green-600 disabled:opacity-50"
                              >
                                ✅ Jóváhagyás
                              </button>
                            )}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
