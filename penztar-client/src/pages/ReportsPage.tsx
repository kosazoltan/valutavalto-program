import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import apiClient from '@/api/client';
import type { DailySummary, TransactionListItem, ReportFilter, CurrencyCode } from '@/types';

type TabView = 'daily' | 'transactions';

function todayStr(): string {
  return new Date().toISOString().split('T')[0] ?? '';
}

export default function ReportsPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [tab, setTab] = useState<TabView>('daily');
  const [dailySummary, setDailySummary] = useState<DailySummary | null>(null);
  const [transactions, setTransactions] = useState<TransactionListItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  // Szűrők
  const [filter, setFilter] = useState<ReportFilter>({
    dateFrom: todayStr(),
    dateTo: todayStr(),
  });
  const [filterType, setFilterType] = useState<string>('');
  const [filterCurrency, setFilterCurrency] = useState<string>('');

  const fetchDailySummary = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const response = await apiClient.get<DailySummary>('/reports/daily-summary');
      setDailySummary(response.data);
    } catch (err) {
      console.error('[ReportsPage] Napi összesítő hiba:', err);
      setError('Napi összesítő betöltése sikertelen.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  const fetchTransactions = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const params: Record<string, string> = {
        dateFrom: filter.dateFrom,
        dateTo: filter.dateTo,
      };
      if (filterType) params['type'] = filterType;
      if (filterCurrency) params['currencyCode'] = filterCurrency;

      const response = await apiClient.get<TransactionListItem[]>('/reports/transactions', { params });
      setTransactions(response.data);
    } catch (err) {
      console.error('[ReportsPage] Tranzakció lista hiba:', err);
      setError('Tranzakció lista betöltése sikertelen.');
    } finally {
      setIsLoading(false);
    }
  }, [filter, filterType, filterCurrency]);

  useEffect(() => {
    if (tab === 'daily') {
      void fetchDailySummary();
    } else {
      void fetchTransactions();
    }
  }, [tab, fetchDailySummary, fetchTransactions]);

  const handleExportCsv = useCallback(() => {
    if (transactions.length === 0) return;

    const header = 'Bizonylat;Dátum;Típus;Valuta;Deviza összeg;HUF összeg;Díj;Pénztáros;Ügyfél\n';
    const rows = transactions.map((tx) =>
      [
        tx.receiptNumber,
        new Date(tx.createdAt).toLocaleDateString('hu-HU'),
        tx.type === 'SELL' ? 'Eladás' : 'Vásárlás',
        tx.currencyCode,
        tx.foreignAmount.toFixed(2),
        tx.roundedHufAmount.toString(),
        tx.fee.toString(),
        tx.cashierName,
        tx.customerName ?? '',
      ].join(';'),
    ).join('\n');

    const csv = '\uFEFF' + header + rows; // UTF-8 BOM for Excel
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `tranzakciok_${filter.dateFrom}_${filter.dateTo}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  }, [transactions, filter]);

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

  const totalFees = transactions.reduce((sum, tx) => sum + tx.fee, 0);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">📋 Listák / Riportok</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        {/* Tab váltó */}
        <div className="mx-auto mb-4 flex max-w-5xl gap-2">
          <button
            onClick={() => setTab('daily')}
            className={`rounded-lg px-4 py-2 text-sm font-medium transition ${
              tab === 'daily' ? (isBestChange ? 'bg-red-600 text-white' : 'bg-orange-500 text-white') : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            📊 Napi összesítő
          </button>
          <button
            onClick={() => setTab('transactions')}
            className={`rounded-lg px-4 py-2 text-sm font-medium transition ${
              tab === 'transactions' ? (isBestChange ? 'bg-red-600 text-white' : 'bg-orange-500 text-white') : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
            }`}
          >
            📄 Tranzakció lista
          </button>
        </div>

        {error && (
          <div className="mx-auto mb-4 max-w-5xl rounded-lg bg-red-50 p-3 text-sm text-red-700">
            ⚠️ {error}
          </div>
        )}

        {isLoading ? (
          <div className="flex items-center justify-center py-20">
            <p className="text-gray-500">⏳ Betöltés...</p>
          </div>
        ) : tab === 'daily' ? (
          /* Napi összesítő */
          dailySummary ? (
            <div className="mx-auto max-w-5xl space-y-4">
              <div className="grid grid-cols-4 gap-4">
                <div className="rounded-xl border bg-white p-4 text-center">
                  <p className="text-sm text-gray-500">Összes tranzakció</p>
                  <p className="text-3xl font-bold text-gray-800">{dailySummary.totalTransactions}</p>
                </div>
                <div className="rounded-xl border bg-red-50 p-4 text-center">
                  <p className="text-sm text-gray-500">Eladás</p>
                  <p className="text-3xl font-bold text-red-600">{dailySummary.sellCount}</p>
                </div>
                <div className="rounded-xl border bg-green-50 p-4 text-center">
                  <p className="text-sm text-gray-500">Vásárlás</p>
                  <p className="text-3xl font-bold text-green-600">{dailySummary.buyCount}</p>
                </div>
                <div className="rounded-xl border bg-blue-50 p-4 text-center">
                  <p className="text-sm text-gray-500">Forgalom (HUF)</p>
                  <p className="text-2xl font-bold text-blue-600">
                    {dailySummary.totalHufTurnover.toLocaleString('hu-HU')} Ft
                  </p>
                </div>
              </div>

              {/* Kezelési díj összesítő */}
              <div className="rounded-xl border bg-white p-4">
                <h3 className="mb-2 font-semibold text-gray-700">💰 Kezelési díj összesítő</h3>
                <p className="text-2xl font-bold text-green-600">
                  {dailySummary.totalFees.toLocaleString('hu-HU')} Ft
                </p>
              </div>

              {/* Valutánkénti bontás */}
              {dailySummary.currencyBreakdown.length > 0 && (
                <div className="rounded-xl border bg-white p-4">
                  <h3 className="mb-3 font-semibold text-gray-700">💱 Valutánkénti bontás</h3>
                  <table className="w-full text-sm">
                    <thead className="border-b text-left text-gray-500">
                      <tr>
                        <th className="pb-2">Valuta</th>
                        <th className="pb-2 text-right">Eladás (db)</th>
                        <th className="pb-2 text-right">Eladás összeg</th>
                        <th className="pb-2 text-right">Vásárlás (db)</th>
                        <th className="pb-2 text-right">Vásárlás összeg</th>
                      </tr>
                    </thead>
                    <tbody>
                      {dailySummary.currencyBreakdown.map((item) => (
                        <tr key={item.currencyCode} className="border-b last:border-0">
                          <td className="py-2 font-medium">{item.currencyCode}</td>
                          <td className="py-2 text-right">{item.sellCount}</td>
                          <td className="py-2 text-right font-mono">{item.sellVolume.toFixed(2)}</td>
                          <td className="py-2 text-right">{item.buyCount}</td>
                          <td className="py-2 text-right font-mono">{item.buyVolume.toFixed(2)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          ) : (
            <div className="py-20 text-center text-gray-400">
              <p className="text-4xl">📊</p>
              <p className="mt-2">Nincs mai összesítő adat.</p>
            </div>
          )
        ) : (
          /* Tranzakció lista */
          <div className="mx-auto max-w-5xl space-y-4">
            {/* Szűrők */}
            <div className="flex flex-wrap items-end gap-3 rounded-xl border bg-white p-4">
              <div>
                <label className="mb-1 block text-xs text-gray-500">Dátumtól</label>
                <input
                  type="date"
                  value={filter.dateFrom}
                  onChange={(e) => setFilter((f) => ({ ...f, dateFrom: e.target.value }))}
                  className="input-field"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs text-gray-500">Dátumig</label>
                <input
                  type="date"
                  value={filter.dateTo}
                  onChange={(e) => setFilter((f) => ({ ...f, dateTo: e.target.value }))}
                  className="input-field"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs text-gray-500">Típus</label>
                <select
                  value={filterType}
                  onChange={(e) => setFilterType(e.target.value)}
                  className="input-field"
                >
                  <option value="">Mind</option>
                  <option value="SELL">Eladás</option>
                  <option value="BUY">Vásárlás</option>
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs text-gray-500">Valuta</label>
                <input
                  type="text"
                  value={filterCurrency}
                  onChange={(e) => setFilterCurrency(e.target.value.toUpperCase() as CurrencyCode | '')}
                  className="input-field w-20"
                  placeholder="EUR"
                  maxLength={3}
                />
              </div>
              <button
                onClick={() => void fetchTransactions()}
                className={`btn-primary ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'}`}
              >
                🔍 Szűrés
              </button>
              <button
                onClick={handleExportCsv}
                disabled={transactions.length === 0}
                className="rounded-lg border bg-green-50 px-4 py-2 text-sm text-green-700 hover:bg-green-100 disabled:opacity-50"
              >
                📥 CSV export
              </button>
            </div>

            {/* Kezelési díj összesítő */}
            {transactions.length > 0 && totalFees > 0 && (
              <div className="rounded-xl border bg-yellow-50 p-3 text-sm">
                <span className="font-medium text-yellow-800">
                  💰 Kezelési díj összesen: {totalFees.toLocaleString('hu-HU')} Ft
                </span>
                <span className="ml-2 text-yellow-600">({transactions.length} tranzakció)</span>
              </div>
            )}

            {/* Tranzakció táblázat */}
            {transactions.length > 0 ? (
              <div className="overflow-auto rounded-xl border bg-white">
                <table className="w-full text-sm">
                  <thead className="border-b bg-gray-50 text-left text-gray-500">
                    <tr>
                      <th className="px-4 py-3">Bizonylat</th>
                      <th className="px-4 py-3">Dátum</th>
                      <th className="px-4 py-3">Típus</th>
                      <th className="px-4 py-3">Valuta</th>
                      <th className="px-4 py-3 text-right">Összeg</th>
                      <th className="px-4 py-3 text-right">HUF</th>
                      <th className="px-4 py-3 text-right">Díj</th>
                      <th className="px-4 py-3">Pénztáros</th>
                    </tr>
                  </thead>
                  <tbody>
                    {transactions.map((tx) => (
                      <tr key={tx.id} className="border-b last:border-0 hover:bg-gray-50">
                        <td className="px-4 py-2 font-mono text-xs">{tx.receiptNumber}</td>
                        <td className="px-4 py-2">{new Date(tx.createdAt).toLocaleString('hu-HU')}</td>
                        <td className="px-4 py-2">
                          <span className={tx.type === 'SELL' ? 'text-red-600' : 'text-green-600'}>
                            {tx.type === 'SELL' ? 'Eladás' : 'Vásárlás'}
                          </span>
                        </td>
                        <td className="px-4 py-2 font-medium">{tx.currencyCode}</td>
                        <td className="px-4 py-2 text-right font-mono">{tx.foreignAmount.toFixed(2)}</td>
                        <td className="px-4 py-2 text-right font-mono">
                          {tx.roundedHufAmount.toLocaleString('hu-HU')} Ft
                        </td>
                        <td className="px-4 py-2 text-right font-mono">
                          {tx.fee > 0 ? `${tx.fee.toLocaleString('hu-HU')} Ft` : '-'}
                        </td>
                        <td className="px-4 py-2 text-xs text-gray-500">{tx.cashierName}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <div className="py-10 text-center text-gray-400">
                <p>Nincs tranzakció a megadott szűrőkkel.</p>
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
}
