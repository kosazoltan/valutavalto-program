import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import apiClient from '@/api/client';
import { toast } from '@/hooks/useToast';

// --- Típusok ---
interface NavReportableTransaction {
  transactionId: number;
  receiptNumber: string;
  transactionType: string;
  transactionDate: string;
  transactionTime: string;
  currencyCode: string | null;
  currencyAmount: number;
  exchangeRate: number;
  hufAmount: number;
  customerId: string | null;
  customerName: string | null;
  customerAddress: string | null;
  customerDocumentNumber: string | null;
}

interface NavReport {
  date: string;
  reportableTransactionCount: number;
  totalAmountHuf: number;
  transactions: NavReportableTransaction[];
}

/**
 * NavReportPage — NAV adatszolgáltatás.
 *
 * - Napi jelenthető tranzakciók (2M+ Ft)
 * - CSV export
 * - Összesítő kártyák
 */
export default function NavReportPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [date, setDate] = useState(new Date().toISOString().slice(0, 10));
  const [report, setReport] = useState<NavReport | null>(null);

  const loadReport = useCallback(async () => {
    setLoading(true);
    try {
      const res = await apiClient.get(`/nav-reports/daily?date=${date}`);
      setReport(res.data);
    } catch (err) {
      toast.error('NAV riport betöltése sikertelen');
    } finally {
      setLoading(false);
    }
  }, [date]);

  const exportCsv = useCallback(async () => {
    try {
      const res = await apiClient.get(`/nav-reports/csv?date=${date}`, { responseType: 'blob' });
      const blob = new Blob([res.data], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `nav_report_${date}.csv`;
      a.click();
      URL.revokeObjectURL(url);
      toast.success('CSV exportálva');
    } catch (err) {
      toast.error('CSV export sikertelen');
    }
  }, [date]);

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">📊 NAV Adatszolgáltatás</h1>
          <p className="text-sm text-gray-500 mt-1">2M+ Ft tranzakciók jelentése a NAV felé</p>
        </div>
        <button onClick={() => navigate('/menu')} className="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300">
          ← Vissza
        </button>
      </div>

      {/* Dátum + gombok */}
      <div className="flex gap-2 mb-6 items-center">
        <input type="date" value={date} onChange={(e) => setDate(e.target.value)}
          className="border rounded px-3 py-2" />
        <button onClick={loadReport} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
          Lekérés
        </button>
        <button onClick={exportCsv} className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700">
          📥 CSV export
        </button>
      </div>

      {loading && <p className="text-center text-gray-500 py-4">⏳ Betöltés...</p>}

      {/* Összesítő kártyák */}
      {report && !loading && (
        <>
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div className="bg-white rounded-lg shadow p-4 border text-center">
              <p className="text-3xl font-bold text-blue-700">{report.reportableTransactionCount}</p>
              <p className="text-xs text-gray-500">Jelenthető tranzakció</p>
            </div>
            <div className="bg-white rounded-lg shadow p-4 border text-center">
              <p className="text-3xl font-bold text-green-700">
                {Number(report.totalAmountHuf).toLocaleString('hu-HU')} Ft
              </p>
              <p className="text-xs text-gray-500">Összes összeg</p>
            </div>
          </div>

          {/* Tranzakciók lista */}
          {report.transactions.length === 0 ? (
            <p className="text-gray-500 text-center py-8">Nincs 2M+ Ft tranzakció ezen a napon.</p>
          ) : (
            <div className="bg-white rounded-lg shadow border overflow-x-auto">
              <table className="w-full text-sm">
                <thead className="bg-gray-100">
                  <tr>
                    <th className="px-3 py-2 text-left">Bizonylat</th>
                    <th className="px-3 py-2 text-left">Típus</th>
                    <th className="px-3 py-2 text-left">Idő</th>
                    <th className="px-3 py-2 text-left">Valuta</th>
                    <th className="px-3 py-2 text-right">Összeg</th>
                    <th className="px-3 py-2 text-right">Árfolyam</th>
                    <th className="px-3 py-2 text-right">HUF</th>
                    <th className="px-3 py-2 text-left">Ügyfél</th>
                    <th className="px-3 py-2 text-left">Okmányszám</th>
                  </tr>
                </thead>
                <tbody>
                  {report.transactions.map((tx) => (
                    <tr key={tx.transactionId} className="border-t hover:bg-gray-50">
                      <td className="px-3 py-2 font-mono text-xs">{tx.receiptNumber}</td>
                      <td className="px-3 py-2">{tx.transactionType}</td>
                      <td className="px-3 py-2 text-xs">{tx.transactionTime?.slice(0, 5)}</td>
                      <td className="px-3 py-2">{tx.currencyCode}</td>
                      <td className="px-3 py-2 text-right">
                        {Number(tx.currencyAmount).toLocaleString('hu-HU', { minimumFractionDigits: 2 })}
                      </td>
                      <td className="px-3 py-2 text-right">{Number(tx.exchangeRate).toFixed(2)}</td>
                      <td className="px-3 py-2 text-right font-bold">
                        {Number(tx.hufAmount).toLocaleString('hu-HU')} Ft
                      </td>
                      <td className="px-3 py-2 text-xs">{tx.customerName ?? '-'}</td>
                      <td className="px-3 py-2 text-xs">{tx.customerDocumentNumber ?? '-'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </div>
  );
}
