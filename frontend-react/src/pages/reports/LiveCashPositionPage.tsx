import { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
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
  const navigate = useNavigate();
  const [data, setData] = useState<LiveCashPosition | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  // FR-PA-04: külön "Kezelési díj nyomtatása" — ilyenkor csak a díj-blokk nyomtatódik (CSS print-mód).
  const [feePrintOnly, setFeePrintOnly] = useState(false);

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

  // FR-PA-04: a díj-only nyomtatás a state beállítása UTÁN fut (a CSS print-osztály már érvényes), majd visszaáll.
  useEffect(() => {
    if (!feePrintOnly) return;
    window.print();
    setFeePrintOnly(false);
  }, [feePrintOnly]);

  // FR-PA-04: "VISSZA A FŐMENÜRE (Escape)".
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate(-1);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [navigate]);

  const lines = safeArray<CurrencyLine>(data?.lines);
  const feeHuf = data?.handlingFeeHuf ?? 0;

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3 print:hidden">
        <h1 className="text-lg font-bold">A PILLANATNYI PÉNZTÁRÁLLÁS KIMUTATÁSA</h1>
        <div className="flex gap-2">
          <button onClick={() => void load()} className="px-3 py-2 bg-gray-100 rounded hover:bg-gray-200">
            Frissítés
          </button>
          <button onClick={() => window.print()} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
            Pillanatnyi állás kinyomtatása
          </button>
          <button onClick={() => setFeePrintOnly(true)} className="px-4 py-2 bg-emerald-600 text-white rounded hover:bg-emerald-700">
            Kezelési díj nyomtatása
          </button>
          <button onClick={() => navigate(-1)} className="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300">
            Vissza (Esc)
          </button>
        </div>
      </div>

      {data?.date && (
        <div className="mb-2 text-sm text-gray-600">Dátum: {data.date}</div>
      )}

      {/* FR-PA-04: külön kezelési-díj bizonylat — csak fee-print módban látszik (egyébként a teljes táblázat). */}
      {feePrintOnly ? (
        <div className="bg-white rounded border p-4">
          <h2 className="text-base font-bold mb-2">KEZELÉSI DÍJ KIMUTATÁS</h2>
          {data?.date && <div className="text-sm text-gray-600 mb-2">Dátum: {data.date}</div>}
          <div className="text-right text-sm">
            Kezelési díj (mai egyenleg): <strong>{fmt(feeHuf)} Ft</strong>
          </div>
        </div>
      ) : loading ? (
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
                <th className="p-2 text-left">VALUTA NEVE</th>
                <th className="p-2 text-right">NYITÓ</th>
                <th className="p-2 text-right">BEVÉTEL</th>
                <th className="p-2 text-right">KIADÁS</th>
                <th className="p-2 text-right">KEZ-I DÍJ</th>
                <th className="p-2 text-right">ZÁRÓ</th>
              </tr>
            </thead>
            <tbody>
              {lines.map((l) => {
                const isHuf = l.currencyCode === 'HUF';
                return (
                  // FR-PA-03: a HUF sort zölddel kiemeljük, a deviza-sorok ZÁRÓ értékét pirossal formázzuk.
                  <tr key={l.currencyCode} className={`border-t ${isHuf ? 'bg-green-50' : ''}`}>
                    <td className="p-2 font-mono">{l.currencyCode}</td>
                    <td className="p-2">{l.currencyName}</td>
                    <td className="p-2 text-right">{fmt(l.opening)}</td>
                    <td className="p-2 text-right">{fmt(l.income)}</td>
                    <td className="p-2 text-right">{fmt(l.expense)}</td>
                    {/* KEZ-I DÍJ: a kezelési díj HUF-alapú subledger-egyenleg, ezért a HUF soron jelenik meg
                        (a devizasorokon nincs külön per-valuta díj-attribúció az adatmodellben). */}
                    <td className="p-2 text-right">{isHuf ? fmt(feeHuf) : ''}</td>
                    <td className={`p-2 text-right font-semibold ${isHuf ? 'text-green-700' : 'text-red-600'}`}>
                      {fmt(l.closing)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          <div className="p-3 border-t bg-gray-50 text-right text-sm">
            Kezelési díj (mai egyenleg): <strong>{fmt(feeHuf)} Ft</strong>
          </div>
        </div>
      )}
    </div>
  );
}
