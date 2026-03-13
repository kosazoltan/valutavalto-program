import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { useOnlineStatus } from '@/hooks/useOnlineStatus';
import type { BranchDailyReport, ConsolidatedReport } from '@/types';

// --- Segédfüggvények ---
function formatHuf(amount: number): string {
  return amount.toLocaleString('hu-HU', { maximumFractionDigits: 0 });
}

function todayStr(): string {
  return new Date().toISOString().slice(0, 10);
}

function weekAgoStr(): string {
  const d = new Date();
  d.setDate(d.getDate() - 7);
  return d.toISOString().slice(0, 10);
}

// Mock adat generálás
function generateMockReport(dateFrom: string, dateTo: string): ConsolidatedReport {
  const branches: BranchDailyReport[] = [
    {
      branchCode: '101', branchName: 'Szeged Kárász u.', date: dateFrom,
      sellCount: 45, buyCount: 32, totalTransactions: 77,
      sellHufVolume: 12_500_000, buyHufVolume: 8_300_000, totalHufTurnover: 20_800_000,
      totalFees: 125_000,
    },
    {
      branchCode: '102', branchName: 'Szeged Dugonics tér', date: dateFrom,
      sellCount: 28, buyCount: 15, totalTransactions: 43,
      sellHufVolume: 7_200_000, buyHufVolume: 4_100_000, totalHufTurnover: 11_300_000,
      totalFees: 68_000,
    },
    {
      branchCode: '103', branchName: 'Szeged Árkád', date: dateFrom,
      sellCount: 52, buyCount: 41, totalTransactions: 93,
      sellHufVolume: 15_800_000, buyHufVolume: 11_200_000, totalHufTurnover: 27_000_000,
      totalFees: 162_000,
    },
    {
      branchCode: '151', branchName: 'Szeged Klauzál tér', date: dateFrom,
      sellCount: 18, buyCount: 12, totalTransactions: 30,
      sellHufVolume: 4_500_000, buyHufVolume: 2_900_000, totalHufTurnover: 7_400_000,
      totalFees: 44_000,
    },
  ];

  const totals = branches.reduce(
    (acc, b) => ({
      totalTransactions: acc.totalTransactions + b.totalTransactions,
      totalSellCount: acc.totalSellCount + b.sellCount,
      totalBuyCount: acc.totalBuyCount + b.buyCount,
      totalHufTurnover: acc.totalHufTurnover + b.totalHufTurnover,
      totalFees: acc.totalFees + b.totalFees,
    }),
    { totalTransactions: 0, totalSellCount: 0, totalBuyCount: 0, totalHufTurnover: 0, totalFees: 0 },
  );

  return { dateFrom, dateTo, branches, totals };
}

// CSV export
function exportToCsv(report: ConsolidatedReport): void {
  const headers = ['Pénztár kód', 'Pénztár név', 'Eladás db', 'Vásárlás db', 'Össz. tranzakció', 'Eladás HUF', 'Vásárlás HUF', 'Össz. forgalom HUF', 'Díjak HUF'];
  const rows = report.branches.map((b) => [
    b.branchCode,
    b.branchName,
    b.sellCount,
    b.buyCount,
    b.totalTransactions,
    b.sellHufVolume,
    b.buyHufVolume,
    b.totalHufTurnover,
    b.totalFees,
  ]);

  // Összesítő sor
  rows.push([
    '',
    'ÖSSZESEN',
    report.totals.totalSellCount,
    report.totals.totalBuyCount,
    report.totals.totalTransactions,
    '', '',
    report.totals.totalHufTurnover,
    report.totals.totalFees,
  ]);

  const csvContent = [
    headers.join(';'),
    ...rows.map((row) => row.join(';')),
  ].join('\n');

  const blob = new Blob([`\uFEFF${csvContent}`], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `osszevont-riport-${report.dateFrom}-${report.dateTo}.csv`;
  link.click();
  URL.revokeObjectURL(url);
}

export default function ConsolidatedReportsPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const { isOnline } = useOnlineStatus();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [dateFrom, setDateFrom] = useState(weekAgoStr());
  const [dateTo, setDateTo] = useState(todayStr());
  const [report, setReport] = useState<ConsolidatedReport | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleLoad = useCallback(async () => {
    setIsLoading(true);
    try {
      // TODO(api): API hívás — GET /api/v1/ertektar/reports/consolidated?from=...&to=... — backend Értéktár modul szükséges
      await new Promise((resolve) => setTimeout(resolve, 500));
      const mockReport = generateMockReport(dateFrom, dateTo);
      setReport(mockReport);
    } catch (err: unknown) {
      console.error('[ConsolidatedReports] Betöltési hiba:', err);
    } finally {
      setIsLoading(false);
    }
  }, [dateFrom, dateTo]);

  const handleExportCsv = useCallback(() => {
    if (report) exportToCsv(report);
  }, [report]);

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-4 text-white shadow-lg`}>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">📊 Összevont riportok</h1>
            <p className="text-sm text-white/80">Összes pénztár összesített forgalma</p>
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
        <div className="mx-auto max-w-5xl">
          {/* Dátum szűrő */}
          <div className="mb-6 flex items-end gap-4 rounded-lg border bg-white p-4 shadow-sm">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">Dátumtól</label>
              <input
                type="date"
                value={dateFrom}
                onChange={(e) => setDateFrom(e.target.value)}
                className="rounded-lg border border-gray-300 px-3 py-2 text-sm"
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">Dátumig</label>
              <input
                type="date"
                value={dateTo}
                onChange={(e) => setDateTo(e.target.value)}
                className="rounded-lg border border-gray-300 px-3 py-2 text-sm"
              />
            </div>
            <button
              onClick={() => void handleLoad()}
              disabled={isLoading}
              className="rounded-lg bg-blue-600 px-6 py-2 text-sm font-bold text-white transition hover:bg-blue-700 disabled:bg-gray-300"
            >
              {isLoading ? '⏳ Betöltés...' : '🔍 Lekérdezés'}
            </button>
            {report && (
              <>
                <button
                  onClick={handleExportCsv}
                  className="rounded-lg bg-green-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-green-700"
                >
                  📋 CSV export
                </button>
              </>
            )}
          </div>

          {/* Riport táblázat */}
          {report && (
            <>
              {/* Offline figyelmeztetés */}
              {!isOnline && (
                <div className="mb-4 rounded-lg border-2 border-yellow-400 bg-yellow-50 p-3 text-center">
                  <p className="font-bold text-yellow-800">
                    ⚠️ Offline riport — nem végleges
                  </p>
                  <p className="text-sm text-yellow-700">
                    Az adatok a legutolsó gyorsítótárazott állapotot tükrözik. Online visszacsatlakozás után frissüljön!
                  </p>
                </div>
              )}

              {/* Összesítő kártyák */}
              <div className="mb-6 grid grid-cols-4 gap-4">
                <div className="rounded-lg border bg-white p-4 shadow-sm">
                  <p className="text-sm text-gray-500">Összes tranzakció</p>
                  <p className="text-2xl font-bold text-gray-900">{report.totals.totalTransactions}</p>
                </div>
                <div className="rounded-lg border bg-white p-4 shadow-sm">
                  <p className="text-sm text-gray-500">Eladás / Vásárlás</p>
                  <p className="text-lg font-bold">
                    <span className="text-blue-600">{report.totals.totalSellCount}</span>
                    {' / '}
                    <span className="text-orange-600">{report.totals.totalBuyCount}</span>
                  </p>
                </div>
                <div className="rounded-lg border bg-white p-4 shadow-sm">
                  <p className="text-sm text-gray-500">Összes forgalom</p>
                  <p className="text-2xl font-bold text-green-600">{formatHuf(report.totals.totalHufTurnover)} Ft</p>
                </div>
                <div className="rounded-lg border bg-white p-4 shadow-sm">
                  <p className="text-sm text-gray-500">Díjbevétel</p>
                  <p className="text-2xl font-bold text-purple-600">{formatHuf(report.totals.totalFees)} Ft</p>
                </div>
              </div>

              {/* Részletes táblázat */}
              <div className="rounded-lg border bg-white p-4 shadow-sm">
                <h2 className="mb-4 text-lg font-semibold text-gray-700">Pénztáranként bontott forgalom</h2>
                <table className="w-full text-sm">
                  <thead className="border-b bg-gray-50 text-left text-gray-600">
                    <tr>
                      <th className="px-3 py-2">Pénztár</th>
                      <th className="px-3 py-2 text-right">Eladás</th>
                      <th className="px-3 py-2 text-right">Vásárlás</th>
                      <th className="px-3 py-2 text-right">Össz. trx</th>
                      <th className="px-3 py-2 text-right">Eladás HUF</th>
                      <th className="px-3 py-2 text-right">Vásárlás HUF</th>
                      <th className="px-3 py-2 text-right">Forgalom</th>
                      <th className="px-3 py-2 text-right">Díjak</th>
                    </tr>
                  </thead>
                  <tbody>
                    {report.branches.map((branch) => (
                      <tr key={branch.branchCode} className="border-b last:border-0 hover:bg-gray-50">
                        <td className="px-3 py-2 font-medium">
                          [{branch.branchCode}] {branch.branchName}
                        </td>
                        <td className="px-3 py-2 text-right">{branch.sellCount}</td>
                        <td className="px-3 py-2 text-right">{branch.buyCount}</td>
                        <td className="px-3 py-2 text-right font-semibold">{branch.totalTransactions}</td>
                        <td className="px-3 py-2 text-right font-mono">{formatHuf(branch.sellHufVolume)}</td>
                        <td className="px-3 py-2 text-right font-mono">{formatHuf(branch.buyHufVolume)}</td>
                        <td className="px-3 py-2 text-right font-mono font-semibold text-green-600">
                          {formatHuf(branch.totalHufTurnover)}
                        </td>
                        <td className="px-3 py-2 text-right font-mono">{formatHuf(branch.totalFees)}</td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot className="border-t-2 bg-gray-100 font-bold">
                    <tr>
                      <td className="px-3 py-2">ÖSSZESEN</td>
                      <td className="px-3 py-2 text-right">{report.totals.totalSellCount}</td>
                      <td className="px-3 py-2 text-right">{report.totals.totalBuyCount}</td>
                      <td className="px-3 py-2 text-right">{report.totals.totalTransactions}</td>
                      <td className="px-3 py-2 text-right" colSpan={2}></td>
                      <td className="px-3 py-2 text-right font-mono text-green-700">
                        {formatHuf(report.totals.totalHufTurnover)}
                      </td>
                      <td className="px-3 py-2 text-right font-mono text-purple-700">
                        {formatHuf(report.totals.totalFees)}
                      </td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            </>
          )}

          {!report && !isLoading && (
            <div className="mt-12 text-center text-gray-400">
              <p className="text-4xl">📊</p>
              <p className="mt-2 text-lg">Válasszon dátumtartományt és kattintson a Lekérdezés gombra</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}


