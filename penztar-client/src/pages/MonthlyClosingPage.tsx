import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  performMonthlyClosing,
  getMonthlyReport,
  getAllClosedMonths,
  type MonthlyClosingSummaryResponse,
} from '@/api/monthlyClosing';

interface CurrencyBreakdownEntry {
  currencyCode: string;
  buyCount: number;
  buyAmount: number;
  buyHuf: number;
  sellCount: number;
  sellAmount: number;
  sellHuf: number;
  handlingFee: number;
  // MNB készletértékelés
  mnbOfficialRate?: number;
  stockQuantity?: number;
  weightedAvgCost?: number;
  stockValueMnb?: number;
  stockValueWac?: number;
  unrealizedPnl?: number;
}

function formatHuf(value: number): string {
  return new Intl.NumberFormat('hu-HU', {
    style: 'currency',
    currency: 'HUF',
    maximumFractionDigits: 0,
  }).format(value);
}

function getCurrentYearMonth(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

export default function MonthlyClosingPage() {
  const navigate = useNavigate();
  const { user } = useAuthStore();

  const [yearMonth, setYearMonth] = useState(getCurrentYearMonth());
  const [branchId, setBranchId] = useState('');
  const [report, setReport] = useState<MonthlyClosingSummaryResponse | null>(null);
  const [breakdown, setBreakdown] = useState<CurrencyBreakdownEntry[]>([]);
  const [closedMonths, setClosedMonths] = useState<MonthlyClosingSummaryResponse[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [confirmClose, setConfirmClose] = useState(false);

  const handleLoadReport = useCallback(async () => {
    if (!branchId) {
      setError('Kérjük, adja meg az iroda azonosítót!');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const data = await getMonthlyReport(branchId, yearMonth);
      setReport(data);
      if (data.currencyBreakdown) {
        const parsed = JSON.parse(data.currencyBreakdown) as CurrencyBreakdownEntry[];
        setBreakdown(parsed);
      }
    } catch {
      setReport(null);
      setBreakdown([]);
      setError('Nincs havi zárás erre a hónapra, vagy az iroda nem található.');
    } finally {
      setLoading(false);
    }
  }, [branchId, yearMonth]);

  const handleLoadClosedMonths = useCallback(async () => {
    if (!branchId) return;
    setLoading(true);
    try {
      const data = await getAllClosedMonths(branchId);
      setClosedMonths(data);
    } catch {
      setClosedMonths([]);
    } finally {
      setLoading(false);
    }
  }, [branchId]);

  const handleClose = useCallback(async () => {
    if (!branchId || !yearMonth) return;
    setLoading(true);
    setError('');
    try {
      const data = await performMonthlyClosing(branchId, yearMonth);
      setReport(data);
      if (data.currencyBreakdown) {
        const parsed = JSON.parse(data.currencyBreakdown) as CurrencyBreakdownEntry[];
        setBreakdown(parsed);
      }
      setConfirmClose(false);
      await handleLoadClosedMonths();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Hiba a havi zárás során';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [branchId, yearMonth, handleLoadClosedMonths]);

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className="bg-blue-600 px-6 py-4 text-white shadow-lg">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">📅 Havi zárás</h1>
            <p className="text-sm text-white/80">
              {user?.fullName ?? 'Felhasználó'} | Havi forgalom összesítés és véglegesítés
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
        <div className="mx-auto max-w-5xl space-y-6">
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
                className="rounded bg-blue-500 px-4 py-2 text-sm font-medium text-white hover:bg-blue-600 disabled:opacity-50"
              >
                📊 Összesítő betöltése
              </button>
              <button
                onClick={() => void handleLoadClosedMonths()}
                disabled={loading || !branchId}
                className="rounded bg-gray-500 px-4 py-2 text-sm font-medium text-white hover:bg-gray-600 disabled:opacity-50"
              >
                📋 Lezárt hónapok
              </button>
            </div>
          </div>

          {error && (
            <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700">
              ⚠️ {error}
            </div>
          )}

          {/* Összesítő kártyák */}
          {report && (
            <div className="grid grid-cols-4 gap-4">
              <div className="rounded-lg border bg-green-50 p-4">
                <div className="text-sm text-green-600">Össz vétel (HUF)</div>
                <div className="text-xl font-bold text-green-800">
                  {formatHuf(report.totalBuyHuf)}
                </div>
              </div>
              <div className="rounded-lg border bg-blue-50 p-4">
                <div className="text-sm text-blue-600">Össz eladás (HUF)</div>
                <div className="text-xl font-bold text-blue-800">
                  {formatHuf(report.totalSellHuf)}
                </div>
              </div>
              <div className="rounded-lg border bg-purple-50 p-4">
                <div className="text-sm text-purple-600">Kezelési díj</div>
                <div className="text-xl font-bold text-purple-800">
                  {formatHuf(report.totalHandlingFee)}
                </div>
              </div>
              <div className="rounded-lg border bg-orange-50 p-4">
                <div className="text-sm text-orange-600">Tranzakciók</div>
                <div className="text-xl font-bold text-orange-800">
                  {report.transactionCount} db
                </div>
              </div>
            </div>
          )}

          {/* Valutánkénti bontás */}
          {breakdown.length > 0 && (
            <div className="rounded-lg border bg-white shadow-sm">
              <div className="border-b px-4 py-3">
                <h2 className="font-semibold text-gray-800">📊 Valutánkénti bontás</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left">Valuta</th>
                      <th className="px-4 py-2 text-right">Vétel db</th>
                      <th className="px-4 py-2 text-right">Vétel összeg</th>
                      <th className="px-4 py-2 text-right">Vétel HUF</th>
                      <th className="px-4 py-2 text-right">Eladás db</th>
                      <th className="px-4 py-2 text-right">Eladás összeg</th>
                      <th className="px-4 py-2 text-right">Eladás HUF</th>
                      <th className="px-4 py-2 text-right">Díj</th>
                    </tr>
                  </thead>
                  <tbody>
                    {breakdown.map((entry) => (
                      <tr key={entry.currencyCode} className="border-t hover:bg-gray-50">
                        <td className="px-4 py-2 font-medium">{entry.currencyCode}</td>
                        <td className="px-4 py-2 text-right">{entry.buyCount}</td>
                        <td className="px-4 py-2 text-right">{entry.buyAmount.toLocaleString('hu-HU')}</td>
                        <td className="px-4 py-2 text-right">{formatHuf(entry.buyHuf)}</td>
                        <td className="px-4 py-2 text-right">{entry.sellCount}</td>
                        <td className="px-4 py-2 text-right">{entry.sellAmount.toLocaleString('hu-HU')}</td>
                        <td className="px-4 py-2 text-right">{formatHuf(entry.sellHuf)}</td>
                        <td className="px-4 py-2 text-right">{formatHuf(entry.handlingFee)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* MNB Készletértékelés — havi zárási árfolyamok */}
          {breakdown.some((e) => e.mnbOfficialRate != null) && (
            <div className="rounded-lg border bg-white shadow-sm">
              <div className="border-b px-4 py-3">
                <h2 className="font-semibold text-gray-800">🏦 MNB Készletértékelés</h2>
                <p className="text-xs text-gray-500">Devizakészlet felértékelése MNB hivatalos középárfolyammal</p>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left">Valuta</th>
                      <th className="px-4 py-2 text-right">MNB árfolyam</th>
                      <th className="px-4 py-2 text-right">Készlet</th>
                      <th className="px-4 py-2 text-right">WAC</th>
                      <th className="px-4 py-2 text-right">Érték (MNB)</th>
                      <th className="px-4 py-2 text-right">Érték (WAC)</th>
                      <th className="px-4 py-2 text-right">Nem realizált eredmény</th>
                    </tr>
                  </thead>
                  <tbody>
                    {breakdown
                      .filter((e) => e.mnbOfficialRate != null)
                      .map((entry) => (
                        <tr key={`mnb-${entry.currencyCode}`} className="border-t hover:bg-gray-50">
                          <td className="px-4 py-2 font-medium">{entry.currencyCode}</td>
                          <td className="px-4 py-2 text-right">
                            {entry.mnbOfficialRate?.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 4 })}
                          </td>
                          <td className="px-4 py-2 text-right">
                            {entry.stockQuantity?.toLocaleString('hu-HU')}
                          </td>
                          <td className="px-4 py-2 text-right">
                            {entry.weightedAvgCost?.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 4 })}
                          </td>
                          <td className="px-4 py-2 text-right">
                            {entry.stockValueMnb != null ? formatHuf(entry.stockValueMnb) : '—'}
                          </td>
                          <td className="px-4 py-2 text-right">
                            {entry.stockValueWac != null ? formatHuf(entry.stockValueWac) : '—'}
                          </td>
                          <td className={`px-4 py-2 text-right font-semibold ${
                            (entry.unrealizedPnl ?? 0) >= 0 ? 'text-green-600' : 'text-red-600'
                          }`}>
                            {entry.unrealizedPnl != null ? formatHuf(entry.unrealizedPnl) : '—'}
                          </td>
                        </tr>
                      ))}
                    {/* Összesítő sor */}
                    <tr className="border-t-2 bg-gray-100 font-bold">
                      <td className="px-4 py-2" colSpan={4}>Összesen</td>
                      <td className="px-4 py-2 text-right">
                        {formatHuf(
                          breakdown
                            .filter((e) => e.stockValueMnb != null)
                            .reduce((sum, e) => sum + (e.stockValueMnb ?? 0), 0)
                        )}
                      </td>
                      <td className="px-4 py-2 text-right">
                        {formatHuf(
                          breakdown
                            .filter((e) => e.stockValueWac != null)
                            .reduce((sum, e) => sum + (e.stockValueWac ?? 0), 0)
                        )}
                      </td>
                      <td className={`px-4 py-2 text-right font-bold ${
                        breakdown
                          .filter((e) => e.unrealizedPnl != null)
                          .reduce((sum, e) => sum + (e.unrealizedPnl ?? 0), 0) >= 0
                            ? 'text-green-700'
                            : 'text-red-700'
                      }`}>
                        {formatHuf(
                          breakdown
                            .filter((e) => e.unrealizedPnl != null)
                            .reduce((sum, e) => sum + (e.unrealizedPnl ?? 0), 0)
                        )}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* Zárás gomb */}
          {!report && branchId && (
            <div className="rounded-lg border border-yellow-200 bg-yellow-50 p-4">
              {!confirmClose ? (
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="font-semibold text-yellow-800">⚠️ Havi zárás véglegesítése</h3>
                    <p className="text-sm text-yellow-700">
                      Ez a művelet visszavonhatatlan! A hónap lezárása után nem módosíthatók a tranzakciók.
                    </p>
                  </div>
                  <button
                    onClick={() => setConfirmClose(true)}
                    className="rounded bg-yellow-500 px-4 py-2 text-sm font-medium text-white hover:bg-yellow-600"
                  >
                    🔒 Zárás indítása
                  </button>
                </div>
              ) : (
                <div className="space-y-3">
                  <p className="font-semibold text-red-700">
                    ⛔ BIZTOSAN le akarja zárni a(z) {yearMonth} hónapot?
                  </p>
                  <p className="text-sm text-red-600">
                    Ez a művelet VISSZAVONHATATLAN! Lezárás után a havi adatok nem módosíthatók.
                  </p>
                  <div className="flex gap-3">
                    <button
                      onClick={() => void handleClose()}
                      disabled={loading}
                      className="rounded bg-red-600 px-6 py-2 text-sm font-bold text-white hover:bg-red-700 disabled:opacity-50"
                    >
                      ✅ Igen, véglegesítés
                    </button>
                    <button
                      onClick={() => setConfirmClose(false)}
                      className="rounded bg-gray-300 px-6 py-2 text-sm font-medium text-gray-700 hover:bg-gray-400"
                    >
                      ❌ Mégsem
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Lezárt hónapok lista */}
          {closedMonths.length > 0 && (
            <div className="rounded-lg border bg-white shadow-sm">
              <div className="border-b px-4 py-3">
                <h2 className="font-semibold text-gray-800">📋 Lezárt hónapok</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-2 text-left">Hónap</th>
                      <th className="px-4 py-2 text-right">Vétel HUF</th>
                      <th className="px-4 py-2 text-right">Eladás HUF</th>
                      <th className="px-4 py-2 text-right">Díj</th>
                      <th className="px-4 py-2 text-right">Tranzakciók</th>
                      <th className="px-4 py-2 text-left">Lezárva</th>
                    </tr>
                  </thead>
                  <tbody>
                    {closedMonths.map((m) => (
                      <tr key={m.id} className="border-t hover:bg-gray-50">
                        <td className="px-4 py-2 font-medium">{m.yearMonth}</td>
                        <td className="px-4 py-2 text-right">{formatHuf(m.totalBuyHuf)}</td>
                        <td className="px-4 py-2 text-right">{formatHuf(m.totalSellHuf)}</td>
                        <td className="px-4 py-2 text-right">{formatHuf(m.totalHandlingFee)}</td>
                        <td className="px-4 py-2 text-right">{m.transactionCount}</td>
                        <td className="px-4 py-2 text-gray-500">
                          {new Date(m.closedAt).toLocaleString('hu-HU')}
                        </td>
                      </tr>
                    ))}
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
