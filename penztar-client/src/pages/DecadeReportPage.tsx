import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import apiClient from '@/api/client';
import type { DecadeReport } from '@/types';

export default function DecadeReportPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [reports, setReports] = useState<DecadeReport[]>([]);
  const [year, setYear] = useState(new Date().getFullYear());
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [generating, setGenerating] = useState(false);
  const [genDecade, setGenDecade] = useState(1);

  const fetchReports = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const response = await apiClient.get<{ content: DecadeReport[] }>('/decade-reports', {
        params: { branchId: '', year },
      });
      setReports(response.data.content ?? []);
    } catch {
      setError('Dekádjelentések betöltése sikertelen.');
    } finally {
      setIsLoading(false);
    }
  }, [year]);

  useEffect(() => {
    void fetchReports();
  }, [fetchReports]);

  const handleGenerate = async () => {
    setGenerating(true);
    try {
      await apiClient.post('/decade-reports/generate', {
        branchId: '',
        year,
        decade: genDecade,
      });
      void fetchReports();
    } catch {
      setError('Generálás sikertelen.');
    } finally {
      setGenerating(false);
    }
  };

  const handleClose = async (id: string) => {
    try {
      await apiClient.post(`/decade-reports/${id}/close`);
      void fetchReports();
    } catch {
      setError('Lezárás sikertelen.');
    }
  };

  const decadeLabel = (decade: number): string => {
    const month = Math.ceil(decade / 3);
    const part = ((decade - 1) % 3) + 1;
    const monthNames = ['Jan', 'Feb', 'Már', 'Ápr', 'Máj', 'Jún', 'Júl', 'Aug', 'Sze', 'Okt', 'Nov', 'Dec'];
    const partLabel = part === 1 ? '1-10.' : part === 2 ? '11-20.' : '21-hó vége';
    return `${monthNames[month - 1] ?? month}. ${partLabel}`;
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">📅 Dekádjelentés (10 napos összesítő)</h1>
          <button onClick={() => navigate('/menu')} className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-5xl space-y-4">
          {/* Év választó + Generálás */}
          <div className="flex items-end gap-3 rounded-xl border bg-white p-4">
            <div>
              <label className="mb-1 block text-xs text-gray-500">Év</label>
              <input type="number" value={year} onChange={(e) => setYear(Number(e.target.value))}
                className="input-field w-24" min={2020} max={2100} />
            </div>
            <div>
              <label className="mb-1 block text-xs text-gray-500">Dekád (1-36)</label>
              <input type="number" value={genDecade} onChange={(e) => setGenDecade(Number(e.target.value))}
                className="input-field w-20" min={1} max={36} />
            </div>
            <button onClick={() => void handleGenerate()} disabled={generating}
              className={`btn-primary ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'}`}>
              {generating ? '⏳ Generálás...' : '📊 Generálás'}
            </button>
          </div>

          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">⚠️ {error}</div>
          )}

          {isLoading ? (
            <div className="flex items-center justify-center py-20">
              <p className="text-gray-500">⏳ Betöltés...</p>
            </div>
          ) : reports.length > 0 ? (
            <div className="overflow-auto rounded-xl border bg-white">
              <table className="w-full text-sm">
                <thead className="border-b bg-gray-50 text-left text-gray-500">
                  <tr>
                    <th className="px-4 py-3">Dekád</th>
                    <th className="px-4 py-3">Időszak</th>
                    <th className="px-4 py-3 text-right">Vételi forgalom</th>
                    <th className="px-4 py-3 text-right">Eladási forgalom</th>
                    <th className="px-4 py-3 text-right">Kezelési díj</th>
                    <th className="px-4 py-3 text-right">Tranzakciók</th>
                    <th className="px-4 py-3">Státusz</th>
                    <th className="px-4 py-3">Művelet</th>
                  </tr>
                </thead>
                <tbody>
                  {reports.map((r) => (
                    <tr key={r.id} className="border-b last:border-0 hover:bg-gray-50">
                      <td className="px-4 py-2 font-medium">{r.decade}</td>
                      <td className="px-4 py-2 text-gray-600">{decadeLabel(r.decade)}</td>
                      <td className="px-4 py-2 text-right font-mono text-green-600">
                        {r.totalBuyHuf.toLocaleString('hu-HU')} Ft
                      </td>
                      <td className="px-4 py-2 text-right font-mono text-red-600">
                        {r.totalSellHuf.toLocaleString('hu-HU')} Ft
                      </td>
                      <td className="px-4 py-2 text-right font-mono">
                        {r.totalHandlingFee.toLocaleString('hu-HU')} Ft
                      </td>
                      <td className="px-4 py-2 text-right">{r.transactionCount}</td>
                      <td className="px-4 py-2">
                        <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                          r.status === 'CLOSED'
                            ? 'bg-green-100 text-green-800'
                            : 'bg-yellow-100 text-yellow-800'
                        }`}>
                          {r.status === 'CLOSED' ? '🔒 Lezárt' : '📝 Tervezet'}
                        </span>
                      </td>
                      <td className="px-4 py-2">
                        {r.status === 'DRAFT' && (
                          <button onClick={() => void handleClose(r.id)}
                            className="rounded bg-green-100 px-3 py-1 text-xs text-green-700 hover:bg-green-200">
                            🔒 Lezárás
                          </button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="py-20 text-center text-gray-400">
              <p className="text-4xl">📅</p>
              <p className="mt-2">Nincs dekádjelentés ehhez az évhez.</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
