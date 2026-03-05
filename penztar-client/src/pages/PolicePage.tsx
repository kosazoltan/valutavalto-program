import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  createPoliceRequest,
  getPoliceRequests,
  processPoliceRequest,
} from '@/api/police';
import type { PoliceRequestData } from '@/types';

function formatDate(d: Date): string {
  return d.toISOString().split('T')[0] ?? '';
}

const STATUS_LABELS: Record<string, string> = {
  RECEIVED: '📥 Beérkezett',
  PROCESSING: '⏳ Feldolgozás alatt',
  COMPLETED: '✅ Feldolgozva',
  REJECTED: '⛔ Elutasítva',
};

export default function PolicePage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [requests, setRequests] = useState<PoliceRequestData[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  // Form state
  const [showForm, setShowForm] = useState(false);
  const [formNumber, setFormNumber] = useState('');
  const [formDate, setFormDate] = useState(formatDate(new Date()));
  const [formOfficer, setFormOfficer] = useState('');
  const [formCustomerName, setFormCustomerName] = useState('');
  const [formDocNumber, setFormDocNumber] = useState('');
  const [formDateFrom, setFormDateFrom] = useState('');
  const [formDateTo, setFormDateTo] = useState('');

  // Detail
  const [selectedRequest, setSelectedRequest] = useState<PoliceRequestData | null>(null);

  const fetchRequests = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const data = await getPoliceRequests();
      setRequests(data.content);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Hiba a lekérdezés során';
      setError(`❌ ${msg}`);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchRequests();
  }, [fetchRequests]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (selectedRequest) {
          setSelectedRequest(null);
        } else {
          navigate('/menu');
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate, selectedRequest]);

  const handleCreate = async () => {
    if (!formNumber || !formOfficer) {
      setError('❌ Az iktatószám és a rendőr megnevezése kötelező!');
      return;
    }
    try {
      await createPoliceRequest({
        requestNumber: formNumber,
        requestDate: formDate,
        requestedBy: formOfficer,
        customerName: formCustomerName || undefined,
        documentNumber: formDocNumber || undefined,
        dateRangeFrom: formDateFrom || undefined,
        dateRangeTo: formDateTo || undefined,
      });
      setSuccessMsg('✅ Adatkérés rögzítve!');
      setShowForm(false);
      setFormNumber('');
      setFormOfficer('');
      setFormCustomerName('');
      setFormDocNumber('');
      setFormDateFrom('');
      setFormDateTo('');
      void fetchRequests();
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Hiba a létrehozás során';
      setError(`❌ ${msg}`);
    }
  };

  const handleProcess = async (id: string) => {
    try {
      const result = await processPoliceRequest(id);
      setSuccessMsg('✅ Feldolgozás kész!');
      setSelectedRequest(result);
      void fetchRequests();
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Hiba a feldolgozás során';
      setError(`❌ ${msg}`);
    }
  };

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🚔 Rendőrségi adatkérés</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-5xl space-y-6">
          {error && <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>}
          {successMsg && <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">{successMsg}</div>}

          {/* Részlet nézet */}
          {selectedRequest && (
            <div className="rounded-xl border-2 border-blue-200 bg-blue-50 p-6">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-lg font-semibold text-blue-800">
                  📋 Adatkérés #{selectedRequest.requestNumber}
                </h2>
                <button
                  onClick={() => setSelectedRequest(null)}
                  className="text-sm text-blue-600 hover:text-blue-800"
                >
                  ✖ Bezárás
                </button>
              </div>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div><strong>Iktatószám:</strong> {selectedRequest.requestNumber}</div>
                <div><strong>Dátum:</strong> {selectedRequest.requestDate}</div>
                <div><strong>Rendőr:</strong> {selectedRequest.requestedBy}</div>
                <div><strong>Státusz:</strong> {STATUS_LABELS[selectedRequest.status] ?? selectedRequest.status}</div>
                <div><strong>Ügyfél neve:</strong> {selectedRequest.customerName ?? '—'}</div>
                <div><strong>Okmányszám:</strong> {selectedRequest.documentNumber ?? '—'}</div>
                <div><strong>Időszak:</strong> {selectedRequest.dateRangeFrom ?? '—'} – {selectedRequest.dateRangeTo ?? '—'}</div>
                <div><strong>Feldolgozva:</strong> {selectedRequest.completedAt ?? '—'}</div>
              </div>
              {selectedRequest.responseData && (
                <div className="mt-4">
                  <h3 className="mb-2 font-semibold text-blue-700">📊 Találatok:</h3>
                  <pre className="max-h-64 overflow-auto rounded-lg bg-white p-3 text-xs">
                    {JSON.stringify(JSON.parse(selectedRequest.responseData), null, 2)}
                  </pre>
                </div>
              )}
              {selectedRequest.status === 'RECEIVED' && (
                <div className="mt-4">
                  <button
                    onClick={() => void handleProcess(selectedRequest.id)}
                    className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
                  >
                    🔍 Feldolgozás indítása
                  </button>
                </div>
              )}
              <div className="mt-4">
                <button
                  onClick={() => window.print()}
                  className="rounded-lg bg-gray-700 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800"
                >
                  🖨️ Válasz nyomtatás
                </button>
              </div>
            </div>
          )}

          {/* Új kérés gomb */}
          <div className="flex justify-end">
            <button
              onClick={() => setShowForm(!showForm)}
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              {showForm ? '✖ Mégse' : '➕ Új adatkérés'}
            </button>
          </div>

          {/* Új adatkérés form */}
          {showForm && (
            <div className="rounded-xl border-2 border-indigo-200 bg-indigo-50 p-6">
              <h2 className="mb-4 text-lg font-semibold text-indigo-800">Új rendőrségi adatkérés</h2>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Iktatószám *</label>
                  <input
                    type="text"
                    value={formNumber}
                    onChange={(e) => setFormNumber(e.target.value)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Kérés dátuma *</label>
                  <input
                    type="date"
                    value={formDate}
                    onChange={(e) => setFormDate(e.target.value)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Rendőr neve / jelvényszám *</label>
                  <input
                    type="text"
                    value={formOfficer}
                    onChange={(e) => setFormOfficer(e.target.value)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Ügyfél neve</label>
                  <input
                    type="text"
                    value={formCustomerName}
                    onChange={(e) => setFormCustomerName(e.target.value)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Okmányszám</label>
                  <input
                    type="text"
                    value={formDocNumber}
                    onChange={(e) => setFormDocNumber(e.target.value)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Időszak kezdete</label>
                  <input
                    type="date"
                    value={formDateFrom}
                    onChange={(e) => setFormDateFrom(e.target.value)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Időszak vége</label>
                  <input
                    type="date"
                    value={formDateTo}
                    onChange={(e) => setFormDateTo(e.target.value)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
              </div>
              <div className="mt-4 flex justify-end">
                <button
                  onClick={() => void handleCreate()}
                  className="rounded-lg bg-indigo-600 px-6 py-2 text-sm font-medium text-white hover:bg-indigo-700"
                >
                  📤 Rögzítés
                </button>
              </div>
            </div>
          )}

          {/* Lista */}
          <div className="overflow-hidden rounded-xl border bg-white">
            <div className="border-b bg-gray-50 px-4 py-3">
              <h2 className="text-lg font-semibold text-gray-700">📜 Adatkérések listája</h2>
            </div>
            <table className="w-full">
              <thead>
                <tr className="border-b bg-gray-50 text-left text-sm font-medium text-gray-600">
                  <th className="px-4 py-3">Iktatószám</th>
                  <th className="px-4 py-3">Dátum</th>
                  <th className="px-4 py-3">Rendőr</th>
                  <th className="px-4 py-3">Ügyfél</th>
                  <th className="px-4 py-3">Státusz</th>
                  <th className="px-4 py-3 text-center">Műveletek</th>
                </tr>
              </thead>
              <tbody>
                {requests.map((r) => (
                  <tr key={r.id} className="border-b transition hover:bg-gray-50">
                    <td className="px-4 py-3 font-mono text-sm font-semibold">{r.requestNumber}</td>
                    <td className="px-4 py-3 text-sm">{r.requestDate}</td>
                    <td className="px-4 py-3 text-sm">{r.requestedBy}</td>
                    <td className="px-4 py-3 text-sm">{r.customerName ?? '—'}</td>
                    <td className="px-4 py-3 text-sm">{STATUS_LABELS[r.status] ?? r.status}</td>
                    <td className="px-4 py-3 text-center">
                      <div className="flex justify-center gap-2">
                        <button
                          onClick={() => setSelectedRequest(r)}
                          className="rounded bg-blue-600 px-3 py-1 text-xs font-medium text-white hover:bg-blue-700"
                        >
                          📋 Részletek
                        </button>
                        {r.status === 'RECEIVED' && (
                          <button
                            onClick={() => void handleProcess(r.id)}
                            className="rounded bg-green-600 px-3 py-1 text-xs font-medium text-white hover:bg-green-700"
                          >
                            🔍 Feldolgozás
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
                {requests.length === 0 && !isLoading && (
                  <tr>
                    <td colSpan={6} className="px-4 py-8 text-center text-gray-400">
                      Nincs rendőrségi adatkérés.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}
