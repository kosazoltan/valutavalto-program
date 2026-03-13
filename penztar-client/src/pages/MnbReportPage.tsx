import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import apiClient from '@/api/client';
import { toast } from '@/hooks/useToast';

// --- Típusok ---
interface MnbCurrencyLine {
  currencyCode: string;
  buyAmount: number;
  sellAmount: number;
  buyHuf: number;
  sellHuf: number;
  avgBuyRate: number;
  avgSellRate: number;
  transactionCount: number;
}

interface MnbDailyReport {
  date: string;
  totalBuyHuf: number;
  totalSellHuf: number;
  totalTransactions: number;
  currencyLines: MnbCurrencyLine[];
}

interface MnbMonthlyReport {
  month: string;
  totalBuyHuf: number;
  totalSellHuf: number;
  totalTransactions: number;
  workingDays: number;
  currencyLines: MnbCurrencyLine[];
}

/**
 * MnbReportPage — MNB adatszolgáltatás.
 *
 * - Dátum választó, generálás
 * - Előnézet táblázat
 * - XML export
 * - Validáció
 */
export default function MnbReportPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [mode, setMode] = useState<'daily' | 'monthly'>('daily');

  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [month, setMonth] = useState(new Date().toISOString().slice(0, 7));

  const [dailyReport, setDailyReport] = useState<MnbDailyReport | null>(null);
  const [monthlyReport, setMonthlyReport] = useState<MnbMonthlyReport | null>(null);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);

  const loadDailyReport = useCallback(async () => {
    setLoading(true);
    setValidationErrors([]);
    try {
      const res = await apiClient.get(`/mnb/reports/daily?date=${date}`);
      setDailyReport(res.data);
    } catch {
      toast.error('MNB napi riport betöltése sikertelen');
    } finally {
      setLoading(false);
    }
  }, [date]);

  const loadMonthlyReport = useCallback(async () => {
    setLoading(true);
    setValidationErrors([]);
    try {
      const res = await apiClient.get(`/mnb/reports/monthly?month=${month}`);
      setMonthlyReport(res.data);
    } catch {
      toast.error('MNB havi riport betöltése sikertelen');
    } finally {
      setLoading(false);
    }
  }, [month]);

  const validateData = useCallback(async () => {
    setLoading(true);
    try {
      const res = await apiClient.get(`/mnb/reports/validate?date=${date}`);
      setValidationErrors(res.data);
      if (res.data.length === 0) {
        toast.success('Validáció sikeres — nincs hiba!');
      }
    } catch {
      toast.error('Validáció sikertelen');
    } finally {
      setLoading(false);
    }
  }, [date]);

  const exportXml = useCallback(async () => {
    try {
      const res = await apiClient.get(`/mnb/reports/daily/xml?date=${date}`, { responseType: 'blob' });
      const blob = new Blob([res.data], { type: 'application/xml' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `mnb_daily_${date}.xml`;
      a.click();
      URL.revokeObjectURL(url);
      toast.success('XML exportálva');
    } catch {
      toast.error('XML export sikertelen');
    }
  }, [date]);

  const currentLines = mode === 'daily'
    ? dailyReport?.currencyLines ?? []
    : monthlyReport?.currencyLines ?? [];

  const totalBuyHuf = mode === 'daily' ? dailyReport?.totalBuyHuf : monthlyReport?.totalBuyHuf;
  const totalSellHuf = mode === 'daily' ? dailyReport?.totalSellHuf : monthlyReport?.totalSellHuf;
  const totalTx = mode === 'daily' ? dailyReport?.totalTransactions : monthlyReport?.totalTransactions;

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">🏦 MNB Adatszolgáltatás</h1>
          <p className="text-sm text-gray-500 mt-1">Magyar Nemzeti Bank — kötelező riportok</p>
        </div>
        <button onClick={() => navigate('/menu')} className="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300">
          ← Vissza
        </button>
      </div>

      {/* Mode switch */}
      <div className="flex gap-2 mb-4">
        <button
          onClick={() => setMode('daily')}
          className={`px-4 py-2 rounded font-medium text-sm ${mode === 'daily' ? 'bg-blue-600 text-white' : 'bg-gray-100'}`}
        >
          📅 Napi
        </button>
        <button
          onClick={() => setMode('monthly')}
          className={`px-4 py-2 rounded font-medium text-sm ${mode === 'monthly' ? 'bg-blue-600 text-white' : 'bg-gray-100'}`}
        >
          📆 Havi
        </button>
      </div>

      {/* Dátum/hónap választó + gombok */}
      <div className="flex gap-2 mb-6 items-center flex-wrap">
        {mode === 'daily' ? (
          <>
            <input type="date" value={date} onChange={(e) => setDate(e.target.value)}
              className="border rounded px-3 py-2" />
            <button onClick={loadDailyReport} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
              Generálás
            </button>
            <button onClick={validateData} className="px-4 py-2 bg-yellow-500 text-white rounded hover:bg-yellow-600">
              ✅ Validáció
            </button>
            <button onClick={exportXml} className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700">
              📥 XML export
            </button>
          </>
        ) : (
          <>
            <input type="month" value={month} onChange={(e) => setMonth(e.target.value)}
              className="border rounded px-3 py-2" />
            <button onClick={loadMonthlyReport} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
              Generálás
            </button>
          </>
        )}
      </div>

      {loading && <p className="text-center text-gray-500 py-4">⏳ Betöltés...</p>}

      {/* Validáció eredmény */}
      {validationErrors.length > 0 && (
        <div className="mb-4 bg-red-50 border border-red-200 rounded-lg p-4">
          <h4 className="font-semibold text-red-800 mb-2">❌ Validációs hibák:</h4>
          <ul className="list-disc pl-5 text-sm text-red-700">
            {validationErrors.map((err, i) => <li key={i}>{err}</li>)}
          </ul>
        </div>
      )}

      {/* Összesítő kártyák */}
      {(dailyReport || monthlyReport) && !loading && (
        <div className="grid grid-cols-3 gap-4 mb-6">
          <div className="bg-white rounded-lg shadow p-4 border text-center">
            <p className="text-2xl font-bold text-green-700">
              {Number(totalBuyHuf ?? 0).toLocaleString('hu-HU')} Ft
            </p>
            <p className="text-xs text-gray-500">Összes vétel (HUF)</p>
          </div>
          <div className="bg-white rounded-lg shadow p-4 border text-center">
            <p className="text-2xl font-bold text-blue-700">
              {Number(totalSellHuf ?? 0).toLocaleString('hu-HU')} Ft
            </p>
            <p className="text-xs text-gray-500">Összes eladás (HUF)</p>
          </div>
          <div className="bg-white rounded-lg shadow p-4 border text-center">
            <p className="text-2xl font-bold text-gray-700">{totalTx ?? 0}</p>
            <p className="text-xs text-gray-500">Tranzakciók</p>
          </div>
        </div>
      )}

      {/* Valutánkénti táblázat */}
      {currentLines.length > 0 && !loading && (
        <div className="bg-white rounded-lg shadow border overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-100">
              <tr>
                <th className="px-4 py-2 text-left">Valuta</th>
                <th className="px-4 py-2 text-right">Vétel összeg</th>
                <th className="px-4 py-2 text-right">Eladás összeg</th>
                <th className="px-4 py-2 text-right">Vétel HUF</th>
                <th className="px-4 py-2 text-right">Eladás HUF</th>
                <th className="px-4 py-2 text-right">Átl. vételi árf.</th>
                <th className="px-4 py-2 text-right">Átl. eladási árf.</th>
                <th className="px-4 py-2 text-right">Trx</th>
              </tr>
            </thead>
            <tbody>
              {currentLines.map((line) => (
                <tr key={line.currencyCode} className="border-t hover:bg-gray-50">
                  <td className="px-4 py-2 font-medium">{line.currencyCode}</td>
                  <td className="px-4 py-2 text-right">{Number(line.buyAmount).toLocaleString('hu-HU', { minimumFractionDigits: 2 })}</td>
                  <td className="px-4 py-2 text-right">{Number(line.sellAmount).toLocaleString('hu-HU', { minimumFractionDigits: 2 })}</td>
                  <td className="px-4 py-2 text-right">{Number(line.buyHuf).toLocaleString('hu-HU', { minimumFractionDigits: 0 })}</td>
                  <td className="px-4 py-2 text-right">{Number(line.sellHuf).toLocaleString('hu-HU', { minimumFractionDigits: 0 })}</td>
                  <td className="px-4 py-2 text-right">{Number(line.avgBuyRate).toFixed(2)}</td>
                  <td className="px-4 py-2 text-right">{Number(line.avgSellRate).toFixed(2)}</td>
                  <td className="px-4 py-2 text-right">{line.transactionCount}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

