import { useEffect, useState, useCallback } from 'react';
import { api } from '@/services/api/index';
import { safeArray } from '@/utils/safeArray';

interface CurrencyLine {
  currencyCode: string;
  currencyName: string;
  openingStock: number;
  closingStock: number;
  totalBuyAmount: number;
  totalSellAmount: number;
  totalBuyHuf: number;
  totalSellHuf: number;
  avgBuyRate: number;
  avgSellRate: number;
  mnbRate?: number;
}

interface TransferLine {
  currencyCode: string;
  currencyName: string;
  receivedAmount: number;
  sentAmount: number;
  netAmount: number;
}

interface MonthlyReportFull {
  yearMonth: string;
  branchCode: string;
  branchName: string;
  closingBalanceHuf: number;
  closingBalanceForeign: number;
  closingBalanceTotal: number;
  currencyLines: CurrencyLine[];
  totalBuyHuf: number;
  totalSellHuf: number;
  cashTurnoverHuf: number;
  cardTurnoverHuf: number;
  transactionCount: number;
  buyCount: number;
  sellCount: number;
  reversalCount: number;
  wuHufBalance: number;
  afaBalance: number;
  handlingFeeBalance: number;
  ecommerceBalance: number;
  transferLines: TransferLine[];
  workingDays: number;
  closedDays: number;
}

const fmt = (n: number) => n.toLocaleString('hu-HU');

// Helyi (nem UTC) dátumból képzett YYYY-MM, hogy a hónap első óráiban
// időzóna miatt ne az előző hónapot adja vissza (Sourcery/Copilot bug_risk).
const currentMonth = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
};

export default function MonthlyTabloPage() {
  const [yearMonth, setYearMonth] = useState(currentMonth());
  const [data, setData] = useState<MonthlyReportFull | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    const branchId = localStorage.getItem('branchId') || '';
    if (!branchId) {
      setError('Hiányzó iroda azonosító.');
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const response = await api.get(`/closing/monthly/${branchId}/${yearMonth}/full`);
      setData(response?.data ?? null);
    } catch {
      setError('A havi tabló lekérése sikertelen.');
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [yearMonth]);

  useEffect(() => {
    void load();
  }, [load]);

  const lines = safeArray<CurrencyLine>(data?.currencyLines);
  const transfers = safeArray<TransferLine>(data?.transferLines);

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3 print:hidden">
        <h1 className="text-lg font-bold">Havi tabló</h1>
        <div className="flex gap-2 items-center">
          <input
            type="month"
            value={yearMonth}
            onChange={(e) => setYearMonth(e.target.value)}
            className="p-2 border rounded"
          />
          <button onClick={() => window.print()} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
            Nyomtatás
          </button>
        </div>
      </div>

      {loading ? (
        <div className="text-center py-8">Betöltés...</div>
      ) : error ? (
        <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded">{error}</div>
      ) : !data ? (
        <div className="text-center py-8 text-gray-500">Nincs adat.</div>
      ) : (
        <div className="space-y-4">
          <div className="text-sm text-gray-600">
            {data.branchCode} – {data.branchName} | {data.yearMonth} | Munkanapok: {data.workingDays} (lezárt: {data.closedDays})
          </div>

          {/* Valutánkénti forgalom */}
          <div className="bg-white rounded border">
            <table className="w-full text-sm">
              <thead className="bg-gray-50">
                <tr>
                  <th className="p-2 text-left">VNEM</th>
                  <th className="p-2 text-right">Nyitó</th>
                  <th className="p-2 text-right">Vétel</th>
                  <th className="p-2 text-right">Eladás</th>
                  <th className="p-2 text-right">Záró</th>
                  <th className="p-2 text-right">Vétel (Ft)</th>
                  <th className="p-2 text-right">Eladás (Ft)</th>
                  <th className="p-2 text-right">MNB</th>
                </tr>
              </thead>
              <tbody>
                {lines.map((l) => (
                  <tr key={l.currencyCode} className="border-t">
                    <td className="p-2 font-mono">{l.currencyCode}</td>
                    <td className="p-2 text-right">{fmt(l.openingStock)}</td>
                    <td className="p-2 text-right">{fmt(l.totalBuyAmount)}</td>
                    <td className="p-2 text-right">{fmt(l.totalSellAmount)}</td>
                    <td className="p-2 text-right">{fmt(l.closingStock)}</td>
                    <td className="p-2 text-right">{fmt(l.totalBuyHuf)}</td>
                    <td className="p-2 text-right">{fmt(l.totalSellHuf)}</td>
                    <td className="p-2 text-right">{l.mnbRate?.toFixed(4)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Összesítők */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            <div className="p-3 bg-white border rounded"><div className="text-xs text-gray-500">Összes vétel (Ft)</div><div className="font-bold">{fmt(data.totalBuyHuf)}</div></div>
            <div className="p-3 bg-white border rounded"><div className="text-xs text-gray-500">Összes eladás (Ft)</div><div className="font-bold">{fmt(data.totalSellHuf)}</div></div>
            <div className="p-3 bg-white border rounded"><div className="text-xs text-gray-500">Készpénzes forgalom</div><div className="font-bold">{fmt(data.cashTurnoverHuf)}</div></div>
            <div className="p-3 bg-white border rounded"><div className="text-xs text-gray-500">Bankkártyás forgalom</div><div className="font-bold">{fmt(data.cardTurnoverHuf)}</div></div>
            <div className="p-3 bg-white border rounded"><div className="text-xs text-gray-500">Tranzakciók</div><div className="font-bold">{data.transactionCount} (V:{data.buyCount} E:{data.sellCount} S:{data.reversalCount})</div></div>
            <div className="p-3 bg-white border rounded"><div className="text-xs text-gray-500">Kezelési díj</div><div className="font-bold">{fmt(data.handlingFeeBalance)} Ft</div></div>
            <div className="p-3 bg-white border rounded"><div className="text-xs text-gray-500">WU egyenleg</div><div className="font-bold">{fmt(data.wuHufBalance)} Ft</div></div>
            <div className="p-3 bg-white border rounded"><div className="text-xs text-gray-500">ÁFA / E-ker</div><div className="font-bold">{fmt(data.afaBalance)} / {fmt(data.ecommerceBalance)} Ft</div></div>
          </div>

          {/* Pénztárak közötti mozgás */}
          {transfers.length > 0 && (
            <div className="bg-white rounded border">
              <div className="p-2 font-semibold bg-gray-50">Pénztárak közötti mozgás</div>
              <table className="w-full text-sm">
                <thead className="bg-gray-50">
                  <tr><th className="p-2 text-left">VNEM</th><th className="p-2 text-right">Átvett</th><th className="p-2 text-right">Átadott</th><th className="p-2 text-right">Nettó</th></tr>
                </thead>
                <tbody>
                  {transfers.map((tr) => (
                    <tr key={tr.currencyCode} className="border-t">
                      <td className="p-2 font-mono">{tr.currencyCode}</td>
                      <td className="p-2 text-right">{fmt(tr.receivedAmount)}</td>
                      <td className="p-2 text-right">{fmt(tr.sentAmount)}</td>
                      <td className="p-2 text-right">{fmt(tr.netAmount)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          <div className="p-3 bg-gray-50 border rounded text-right text-sm">
            Záró készlet: HUF <strong>{fmt(data.closingBalanceHuf)}</strong> + deviza(HUF-ban) {fmt(data.closingBalanceForeign)} = <strong>{fmt(data.closingBalanceTotal)} Ft</strong>
          </div>
        </div>
      )}
    </div>
  );
}
