import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import apiClient from '@/api/client';
import { toast } from '@/hooks/useToast';

// --- Típusok ---
interface AmlReportEntry {
  id: string;
  customerId: string | null;
  transactionId: number | null;
  reportType: string;
  riskLevel: string;
  amountHuf: number;
  currencyCode: string | null;
  originalAmount: number | null;
  customerName: string | null;
  documentType: string | null;
  documentNumber: string | null;
  workerNotes: string | null;
  status: string;
  createdBy: string | null;
  createdAt: string;
}

interface CustomerRiskProfile {
  customerId: string;
  customerName: string | null;
  riskLevel: string;
  last30DaysTotal: number;
  last30DaysTransactionCount: number;
  dailyTotal: number;
  dailyTransactionCount: number;
  annualTotal: number;
  structuringDetected: boolean;
  highFrequency: boolean;
  highVolume: boolean;
}

interface AmlDailySummary {
  date: string;
  totalReports: number;
  pendingReports: number;
  submittedReports: number;
  flaggedReports: number;
  standardChecks: number;
  enhancedChecks: number;
  suspiciousChecks: number;
  thresholdChecks: number;
  totalAmountHuf: number;
}

// --- Szín kódolás ---
const statusColors: Record<string, string> = {
  DRAFT: 'bg-yellow-100 text-yellow-800 border-yellow-300',
  SUBMITTED: 'bg-blue-100 text-blue-800 border-blue-300',
  ACKNOWLEDGED: 'bg-green-100 text-green-800 border-green-300',
  FLAGGED: 'bg-red-100 text-red-800 border-red-300',
};

const riskColors: Record<string, string> = {
  LOW: 'bg-green-100 text-green-800',
  MEDIUM: 'bg-yellow-100 text-yellow-800',
  HIGH: 'bg-orange-100 text-orange-800',
  CRITICAL: 'bg-red-100 text-red-800',
};

function getStatusColor(status: string): string {
  return statusColors[status] ?? 'bg-gray-100 text-gray-700 border-gray-300';
}

function getRiskColor(risk: string): string {
  return riskColors[risk] ?? 'bg-gray-100 text-gray-700';
}

/**
 * AmlPage — Pénzmosás elleni (AML) modul.
 *
 * - Függő bejelentések lista
 * - Ügyfél kockázati profil
 * - Új bejelentés form
 * - Napi összesítő dashboard
 */
export default function AmlPage() {
  const navigate = useNavigate();
  const [tab, setTab] = useState<'pending' | 'risk' | 'new' | 'summary'>('pending');
  const [loading, setLoading] = useState(false);

  // Pending reports
  const [pendingReports, setPendingReports] = useState<AmlReportEntry[]>([]);

  // Risk profile
  const [riskCustomerId, setRiskCustomerId] = useState('');
  const [riskProfile, setRiskProfile] = useState<CustomerRiskProfile | null>(null);

  // New report form
  const [newReport, setNewReport] = useState({
    customerId: '',
    reportType: 'STANDARD',
    riskLevel: 'LOW',
    amountHuf: '',
    currencyCode: '',
    originalAmount: '',
    customerName: '',
    documentType: '',
    documentNumber: '',
    workerNotes: '',
  });

  // Daily summary
  const [summaryDate, setSummaryDate] = useState(new Date().toISOString().slice(0, 10));
  const [summary, setSummary] = useState<AmlDailySummary | null>(null);

  // --- API hívások ---
  const loadPending = useCallback(async () => {
    setLoading(true);
    try {
      const res = await apiClient.get('/aml/pending');
      setPendingReports(res.data);
    } catch (err) {
      toast.error('Függő bejelentések betöltése sikertelen');
    } finally {
      setLoading(false);
    }
  }, []);

  const loadRiskProfile = useCallback(async () => {
    if (!riskCustomerId.trim()) return;
    setLoading(true);
    try {
      const res = await apiClient.get(`/aml/customer-risk/${riskCustomerId}`);
      setRiskProfile(res.data);
    } catch (err) {
      toast.error('Kockázati profil betöltése sikertelen');
    } finally {
      setLoading(false);
    }
  }, [riskCustomerId]);

  const submitNewReport = useCallback(async () => {
    setLoading(true);
    try {
      await apiClient.post('/aml/report', {
        ...newReport,
        amountHuf: Number(newReport.amountHuf) || 0,
        originalAmount: newReport.originalAmount ? Number(newReport.originalAmount) : null,
      });
      toast.success('AML bejelentés létrehozva');
      setNewReport({
        customerId: '', reportType: 'STANDARD', riskLevel: 'LOW',
        amountHuf: '', currencyCode: '', originalAmount: '',
        customerName: '', documentType: '', documentNumber: '', workerNotes: '',
      });
    } catch (err) {
      toast.error('Bejelentés létrehozása sikertelen');
    } finally {
      setLoading(false);
    }
  }, [newReport]);

  const loadSummary = useCallback(async () => {
    setLoading(true);
    try {
      const res = await apiClient.get(`/aml/summary?date=${summaryDate}`);
      setSummary(res.data);
    } catch (err) {
      toast.error('Napi összesítő betöltése sikertelen');
    } finally {
      setLoading(false);
    }
  }, [summaryDate]);

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">🛡️ AML — Pénzmosás elleni modul</h1>
          <p className="text-sm text-gray-500 mt-1">2017. évi LIII. tv. szerinti kötelezettségek</p>
        </div>
        <button onClick={() => navigate('/menu')} className="px-4 py-2 bg-gray-200 rounded hover:bg-gray-300">
          ← Vissza
        </button>
      </div>

      {/* Tab-ok */}
      <div className="flex gap-2 mb-6 border-b pb-2">
        {[
          { key: 'pending' as const, label: '📋 Függő bejelentések', action: loadPending },
          { key: 'risk' as const, label: '👤 Kockázati profil' },
          { key: 'new' as const, label: '➕ Új bejelentés' },
          { key: 'summary' as const, label: '📊 Napi összesítő', action: loadSummary },
        ].map((t) => (
          <button
            key={t.key}
            onClick={() => { setTab(t.key); if (t.action) t.action(); }}
            className={`px-4 py-2 rounded-t font-medium text-sm transition ${
              tab === t.key ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* Loading */}
      {loading && <p className="text-center text-gray-500 py-4">⏳ Betöltés...</p>}

      {/* Függő bejelentések */}
      {tab === 'pending' && !loading && (
        <div className="space-y-3">
          {pendingReports.length === 0 ? (
            <p className="text-gray-500 text-center py-8">Nincs függő bejelentés.</p>
          ) : (
            pendingReports.map((r) => (
              <div key={r.id} className="bg-white rounded-lg shadow p-4 border">
                <div className="flex items-center justify-between">
                  <div>
                    <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium border ${getStatusColor(r.status)}`}>
                      {r.status}
                    </span>
                    <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ml-2 ${getRiskColor(r.riskLevel)}`}>
                      {r.riskLevel}
                    </span>
                    <span className="ml-2 text-sm text-gray-600">{r.reportType}</span>
                  </div>
                  <span className="text-sm text-gray-400">{new Date(r.createdAt).toLocaleString('hu-HU')}</span>
                </div>
                <div className="mt-2 text-sm">
                  <p><strong>Összeg:</strong> {Number(r.amountHuf).toLocaleString('hu-HU')} Ft</p>
                  {r.customerName && <p><strong>Ügyfél:</strong> {r.customerName} ({r.customerId})</p>}
                  {r.workerNotes && <p className="text-gray-500 mt-1">{r.workerNotes}</p>}
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* Kockázati profil */}
      {tab === 'risk' && !loading && (
        <div className="max-w-xl">
          <div className="flex gap-2 mb-4">
            <input
              type="text"
              value={riskCustomerId}
              onChange={(e) => setRiskCustomerId(e.target.value)}
              placeholder="Ügyfél azonosító..."
              className="flex-1 border rounded px-3 py-2"
            />
            <button onClick={loadRiskProfile} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
              Lekérés
            </button>
          </div>
          {riskProfile && (
            <div className="bg-white rounded-lg shadow p-6 border">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold">{riskProfile.customerName ?? riskProfile.customerId}</h3>
                <span className={`px-3 py-1 rounded-full text-sm font-bold ${getRiskColor(riskProfile.riskLevel)}`}>
                  {riskProfile.riskLevel}
                </span>
              </div>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div><strong>30 nap összeg:</strong> {Number(riskProfile.last30DaysTotal).toLocaleString('hu-HU')} Ft</div>
                <div><strong>30 nap trx:</strong> {riskProfile.last30DaysTransactionCount} db</div>
                <div><strong>Napi összeg:</strong> {Number(riskProfile.dailyTotal).toLocaleString('hu-HU')} Ft</div>
                <div><strong>Napi trx:</strong> {riskProfile.dailyTransactionCount} db</div>
                <div><strong>Éves összeg:</strong> {Number(riskProfile.annualTotal).toLocaleString('hu-HU')} Ft</div>
              </div>
              <div className="mt-4 flex gap-2 flex-wrap">
                {riskProfile.structuringDetected && (
                  <span className="px-2 py-1 bg-red-100 text-red-800 rounded text-xs font-medium">⚠️ Structuring gyanú</span>
                )}
                {riskProfile.highFrequency && (
                  <span className="px-2 py-1 bg-orange-100 text-orange-800 rounded text-xs font-medium">⚡ Magas gyakoriság</span>
                )}
                {riskProfile.highVolume && (
                  <span className="px-2 py-1 bg-orange-100 text-orange-800 rounded text-xs font-medium">💰 Magas volumen</span>
                )}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Új bejelentés */}
      {tab === 'new' && !loading && (
        <div className="max-w-xl bg-white rounded-lg shadow p-6 border">
          <h3 className="text-lg font-semibold mb-4">Új AML bejelentés</h3>
          <div className="space-y-3">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Típus</label>
                <select
                  value={newReport.reportType}
                  onChange={(e) => setNewReport({ ...newReport, reportType: e.target.value })}
                  className="w-full border rounded px-3 py-2"
                >
                  <option value="STANDARD">Azonosítás (300K+)</option>
                  <option value="ENHANCED">Fokozott (4.5M+)</option>
                  <option value="THRESHOLD">Bejelentés (2M+)</option>
                  <option value="SUSPICIOUS">Gyanús</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Kockázat</label>
                <select
                  value={newReport.riskLevel}
                  onChange={(e) => setNewReport({ ...newReport, riskLevel: e.target.value })}
                  className="w-full border rounded px-3 py-2"
                >
                  <option value="LOW">Alacsony</option>
                  <option value="MEDIUM">Közepes</option>
                  <option value="HIGH">Magas</option>
                  <option value="CRITICAL">Kritikus</option>
                </select>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Összeg (HUF)</label>
              <input type="number" value={newReport.amountHuf}
                onChange={(e) => setNewReport({ ...newReport, amountHuf: e.target.value })}
                className="w-full border rounded px-3 py-2" placeholder="0" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Ügyfél kód</label>
                <input type="text" value={newReport.customerId}
                  onChange={(e) => setNewReport({ ...newReport, customerId: e.target.value })}
                  className="w-full border rounded px-3 py-2" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Ügyfél neve</label>
                <input type="text" value={newReport.customerName}
                  onChange={(e) => setNewReport({ ...newReport, customerName: e.target.value })}
                  className="w-full border rounded px-3 py-2" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Okmány típus</label>
                <input type="text" value={newReport.documentType}
                  onChange={(e) => setNewReport({ ...newReport, documentType: e.target.value })}
                  className="w-full border rounded px-3 py-2" placeholder="SZEMELYI / UTLEVEL" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Okmányszám</label>
                <input type="text" value={newReport.documentNumber}
                  onChange={(e) => setNewReport({ ...newReport, documentNumber: e.target.value })}
                  className="w-full border rounded px-3 py-2" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Valuta</label>
                <input type="text" value={newReport.currencyCode}
                  onChange={(e) => setNewReport({ ...newReport, currencyCode: e.target.value })}
                  className="w-full border rounded px-3 py-2" placeholder="EUR" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Eredeti összeg</label>
                <input type="number" value={newReport.originalAmount}
                  onChange={(e) => setNewReport({ ...newReport, originalAmount: e.target.value })}
                  className="w-full border rounded px-3 py-2" />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Megjegyzés</label>
              <textarea value={newReport.workerNotes}
                onChange={(e) => setNewReport({ ...newReport, workerNotes: e.target.value })}
                className="w-full border rounded px-3 py-2" rows={3} />
            </div>
            <button onClick={submitNewReport} className="w-full py-2 bg-blue-600 text-white rounded hover:bg-blue-700 font-medium">
              📝 Bejelentés létrehozása
            </button>
          </div>
        </div>
      )}

      {/* Napi összesítő */}
      {tab === 'summary' && !loading && (
        <div className="max-w-2xl">
          <div className="flex gap-2 mb-4">
            <input type="date" value={summaryDate}
              onChange={(e) => setSummaryDate(e.target.value)}
              className="border rounded px-3 py-2" />
            <button onClick={loadSummary} className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">
              Lekérés
            </button>
          </div>
          {summary && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                <div className="bg-white rounded-lg shadow p-4 border text-center">
                  <p className="text-2xl font-bold text-gray-900">{summary.totalReports}</p>
                  <p className="text-xs text-gray-500">Összes bejelentés</p>
                </div>
                <div className="bg-yellow-50 rounded-lg shadow p-4 border border-yellow-200 text-center">
                  <p className="text-2xl font-bold text-yellow-700">{summary.pendingReports}</p>
                  <p className="text-xs text-gray-500">Függő</p>
                </div>
                <div className="bg-blue-50 rounded-lg shadow p-4 border border-blue-200 text-center">
                  <p className="text-2xl font-bold text-blue-700">{summary.submittedReports}</p>
                  <p className="text-xs text-gray-500">Beküldött</p>
                </div>
                <div className="bg-red-50 rounded-lg shadow p-4 border border-red-200 text-center">
                  <p className="text-2xl font-bold text-red-700">{summary.flaggedReports}</p>
                  <p className="text-xs text-gray-500">Megjelölt</p>
                </div>
              </div>
              <div className="bg-white rounded-lg shadow p-4 border">
                <h4 className="font-semibold mb-2">Típus szerinti bontás</h4>
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div>Azonosítás (STANDARD): <strong>{summary.standardChecks}</strong></div>
                  <div>Fokozott (ENHANCED): <strong>{summary.enhancedChecks}</strong></div>
                  <div>Gyanús (SUSPICIOUS): <strong>{summary.suspiciousChecks}</strong></div>
                  <div>Küszöb (THRESHOLD): <strong>{summary.thresholdChecks}</strong></div>
                </div>
                <div className="mt-3 pt-3 border-t">
                  <p className="text-lg font-bold">
                    Összeg: {Number(summary.totalAmountHuf).toLocaleString('hu-HU')} Ft
                  </p>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
