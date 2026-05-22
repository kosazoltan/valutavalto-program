import { useEffect, useState, useCallback } from 'react';
import { api } from '@/services/api/index';
import { safeArray } from '@/utils/safeArray';

interface CurrencyLine {
  currencyCode: string;
  currencyName: string;
  opening: number;
  income: number;
  expense: number;
  closing: number;
}

interface LiveCashPosition {
  branchId: string;
  date: string;
  lines: CurrencyLine[];
  handlingFeeHuf: number;
}

const fmt = (n: number) => (n ?? 0).toLocaleString('hu-HU');

export default function LiveCashPositionPage() {
  const [data, setData] = useState<LiveCashPosition | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await api.get('/reports/live-cash-position');
      setData(response?.data ?? null);
    } catch {
      setError('A pillanatnyi pénztárállás lekérése sikertelen.');
      setData(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const lines = safeArray<CurrencyLine>(data?.lines);

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3 print:hidden">
        <h1 className="text-lg font-bold">Pillanatnyi pénztárállás</h1>
        <div className="flex gap-2">
          <button onClick={() => void load()} className="px-3 py-2 bg-gray-100 rounded hover:bg-gray-200">
            Frissítés
          </button>
          <button onClick={() => window.print()} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
            Nyomtatás
          </button>
        </div>
      </div>

      {data?.date && (
        <div className="mb-2 text-sm text-gray-600">Dátum: {new Date(data.date).toLocaleDateString('hu-HU')}</div>
      )}

      {loading ? (
        <div className="text-center py-8">Betöltés...</div>
      ) : error ? (
        <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded">{error}</div>
      ) : lines.length === 0 ? (
        <div className="text-center py-8 text-gray-500">Nincs mai napi pénztármozgás.</div>
      ) : (
        <div className="bg-white rounded border">
          <table className="w-full text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-2 text-left">VNEM</th>
                <th className="p-2 text-left">Valuta neve</th>
                <th className="p-2 text-right">Nyitó</th>
                <th className="p-2 text-right">Bevétel</th>
                <th className="p-2 text-right">Kiadás</th>
                <th className="p-2 text-right">Záró</th>
              </tr>
            </thead>
            <tbody>
              {lines.map((l) => (
                <tr key={l.currencyCode} className="border-t">
                  <td className="p-2 font-mono">{l.currencyCode}</td>
                  <td className="p-2">{l.currencyName}</td>
                  <td className="p-2 text-right">{fmt(l.opening)}</td>
                  <td className="p-2 text-right">{fmt(l.income)}</td>
                  <td className="p-2 text-right">{fmt(l.expense)}</td>
                  <td className="p-2 text-right font-semibold">{fmt(l.closing)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="p-3 border-t bg-gray-50 text-right text-sm">
            Kezelési díj (mai egyenleg): <strong>{fmt(data?.handlingFeeHuf ?? 0)} Ft</strong>
          </div>
        </div>
      )}
    </div>
  );
}
