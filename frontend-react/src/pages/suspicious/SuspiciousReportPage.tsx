import React, { useState, useEffect } from 'react';
import { api } from '@/services/api';

interface SuspiciousReport {
  id: number;
  reportNumber: string;
  customerName: string;
  customerDocumentNumber: string;
  transactionId?: number;
  reportType: string;
  suspicionReason: string;
  description: string;
  detectedAmount: number;
  status: string;
  reporterName: string;
  submissionDeadline: string;
  createdAt: string;
  submittedAt?: string;
}

const statusColors: Record<string, string> = {
  DRAFT: 'bg-gray-500',
  PENDING_REVIEW: 'bg-yellow-500',
  APPROVED: 'bg-blue-500',
  REJECTED: 'bg-red-500',
  SUBMITTED: 'bg-green-500',
  ACKNOWLEDGED: 'bg-emerald-600',
};

const statusLabels: Record<string, string> = {
  DRAFT: 'Piszkozat',
  PENDING_REVIEW: 'Jóváhagyásra vár',
  APPROVED: 'Jóváhagyva',
  REJECTED: 'Elutasítva',
  SUBMITTED: 'Beküldve',
  ACKNOWLEDGED: 'Visszaigazolva',
};

const reportTypeLabels: Record<string, string> = {
  SUSPICIOUS_TRANSACTION: 'Gyanús tranzakció',
  STRUCTURING: 'Strukturálás',
  UNUSUAL_PATTERN: 'Szokatlan minta',
  BLACKLIST_MATCH: 'Tiltólista egyezés',
  PEP_TRANSACTION: 'PEP tranzakció',
  THRESHOLD_EXCEEDED: 'Határérték túllépés',
  OTHER: 'Egyéb',
};

export default function SuspiciousReportPage() {
  const [reports, setReports] = useState<SuspiciousReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('pending');
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [selectedReport, setSelectedReport] = useState<SuspiciousReport | null>(null);
  const [showDetailDialog, setShowDetailDialog] = useState(false);

  useEffect(() => {
    loadReports();
  }, [activeTab]);

  const loadReports = async () => {
    setLoading(true);
    try {
      let response;
      if (activeTab === 'pending') {
        response = await api.get('/suspicious-reports/pending');
      } else if (activeTab === 'deadline') {
        response = await api.get('/suspicious-reports/deadline-approaching?daysAhead=3');
      } else {
        response = await api.get(`/suspicious-reports/status/${activeTab.toUpperCase()}`);
      }
      setReports(response?.data || []);
    } catch (error) {
      console.error('Failed to load reports:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmitForReview = async (id: number) => {
    try {
      await api.post(`/suspicious-reports/${id}/submit-review`);
      loadReports();
    } catch (error) {
      console.error('Failed to submit for review:', error);
    }
  };

  const handleApprove = async (id: number) => {
    const notes = prompt('Jóváhagyási megjegyzés (opcionális):');
    try {
      await api.post(`/suspicious-reports/${id}/approve`, { notes });
      loadReports();
    } catch (error) {
      console.error('Failed to approve report:', error);
    }
  };

  const handleReject = async (id: number) => {
    const reason = prompt('Elutasítás oka:');
    if (reason) {
      try {
        await api.post(`/suspicious-reports/${id}/reject`, { reason });
        loadReports();
      } catch (error) {
        console.error('Failed to reject report:', error);
      }
    }
  };

  const handleSubmitToAuthority = async (id: number) => {
    if (window.confirm('Biztosan beküldi a bejelentést a NAV felé?')) {
      try {
        await api.post(`/suspicious-reports/${id}/submit-authority`);
        loadReports();
      } catch (error) {
        console.error('Failed to submit to authority:', error);
      }
    }
  };

  const filteredReports = reports.filter(r =>
    r.reportNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.customerName?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getDaysUntilDeadline = (deadline: string) => {
    const diff = new Date(deadline).getTime() - new Date().getTime();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  return (
    <div className="container mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">Gyanús ügyletek (Pmt.)</h1>
          <p className="text-gray-500">Pénzmosás elleni bejelentések kezelése</p>
        </div>
        <button
          onClick={() => setShowCreateDialog(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          + Új bejelentés
        </button>
      </div>

      <div className="mb-6">
        <input
          type="text"
          placeholder="Keresés szám vagy ügyfél alapján..."
          value={searchTerm}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchTerm(e.target.value)}
          className="w-full p-2 border rounded"
        />
      </div>

      <div className="mb-4 flex gap-2">
        {[
          { key: 'pending', label: 'Függőben' },
          { key: 'deadline', label: 'Lejáró határidő' },
          { key: 'approved', label: 'Jóváhagyott' },
          { key: 'submitted', label: 'Beküldött' },
        ].map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`px-4 py-2 rounded ${
              activeTab === tab.key ? 'bg-blue-600 text-white' : 'bg-gray-100 hover:bg-gray-200'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className="bg-white rounded border">
        {loading ? (
          <div className="text-center py-8">Betöltés...</div>
        ) : filteredReports.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            Nincsenek bejelentések ebben a kategóriában
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-3 text-left">Szám</th>
                <th className="p-3 text-left">Ügyfél</th>
                <th className="p-3 text-left">Típus</th>
                <th className="p-3 text-left">Összeg</th>
                <th className="p-3 text-left">Határidő</th>
                <th className="p-3 text-left">Státusz</th>
                <th className="p-3 text-left">Műveletek</th>
              </tr>
            </thead>
            <tbody>
              {filteredReports.map((report) => {
                const daysUntil = getDaysUntilDeadline(report.submissionDeadline);
                return (
                  <tr key={report.id} className="border-t hover:bg-gray-50">
                    <td className="p-3 font-mono">{report.reportNumber}</td>
                    <td className="p-3">
                      <div>{report.customerName || '-'}</div>
                      <div className="text-xs text-gray-500">
                        {report.customerDocumentNumber}
                      </div>
                    </td>
                    <td className="p-3">{reportTypeLabels[report.reportType] || report.reportType}</td>
                    <td className="p-3">{report.detectedAmount?.toLocaleString()} Ft</td>
                    <td className="p-3">
                      <div className={daysUntil <= 3 ? 'text-red-500 font-semibold' : ''}>
                        {new Date(report.submissionDeadline).toLocaleDateString('hu-HU')}
                      </div>
                      {daysUntil <= 3 && (
                        <div className="text-xs text-red-500">
                          {daysUntil <= 0 ? 'Lejárt!' : `${daysUntil} nap`}
                        </div>
                      )}
                    </td>
                    <td className="p-3">
                      <span className={`px-2 py-1 text-xs text-white rounded ${statusColors[report.status]}`}>
                        {statusLabels[report.status] || report.status}
                      </span>
                    </td>
                    <td className="p-3">
                      <div className="flex gap-2">
                        <button
                          onClick={() => {
                            setSelectedReport(report);
                            setShowDetailDialog(true);
                          }}
                          className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                        >
                          Részletek
                        </button>
                        {report.status === 'DRAFT' && (
                          <button
                            onClick={() => handleSubmitForReview(report.id)}
                            className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                          >
                            Jóváhagyásra
                          </button>
                        )}
                        {report.status === 'PENDING_REVIEW' && (
                          <>
                            <button
                              onClick={() => handleApprove(report.id)}
                              className="px-2 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700"
                            >
                              Jóváhagy
                            </button>
                            <button
                              onClick={() => handleReject(report.id)}
                              className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700"
                            >
                              Elutasít
                            </button>
                          </>
                        )}
                        {report.status === 'APPROVED' && (
                          <button
                            onClick={() => handleSubmitToAuthority(report.id)}
                            className="px-2 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700"
                          >
                            NAV-nak küld
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {showCreateDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">Új gyanús ügylet bejelentés</h2>
            <CreateReportForm
              onSuccess={() => {
                setShowCreateDialog(false);
                loadReports();
              }}
              onCancel={() => setShowCreateDialog(false)}
            />
          </div>
        </div>
      )}

      {showDetailDialog && selectedReport && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-3xl w-full max-h-[80vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">Bejelentés részletei - {selectedReport.reportNumber}</h2>
            <ReportDetail report={selectedReport} onClose={() => setShowDetailDialog(false)} />
          </div>
        </div>
      )}
    </div>
  );
}

function CreateReportForm({
  onSuccess,
  onCancel,
}: {
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const [formData, setFormData] = useState({
    customerId: '',
    customerName: '',
    customerDocumentNumber: '',
    transactionId: '',
    reportType: 'SUSPICIOUS_TRANSACTION',
    suspicionReason: '',
    description: '',
    detectedAmount: '',
    riskLevel: 'MEDIUM',
  });

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    try {
      await api.post('/suspicious-reports', {
        ...formData,
        detectedAmount: parseFloat(formData.detectedAmount) || 0,
        transactionId: formData.transactionId ? parseInt(formData.transactionId) : null,
      });
      onSuccess();
    } catch (error) {
      console.error('Failed to create report:', error);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium mb-1">Ügyfél neve *</label>
          <input
            type="text"
            value={formData.customerName}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, customerName: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Okmány száma *</label>
          <input
            type="text"
            value={formData.customerDocumentNumber}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, customerDocumentNumber: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Bejelentés típusa *</label>
          <select
            value={formData.reportType}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              setFormData({ ...formData, reportType: e.target.value })
            }
            className="w-full p-2 border rounded"
          >
            <option value="SUSPICIOUS_TRANSACTION">Gyanús tranzakció</option>
            <option value="STRUCTURING">Strukturálás</option>
            <option value="UNUSUAL_PATTERN">Szokatlan minta</option>
            <option value="BLACKLIST_MATCH">Tiltólista egyezés</option>
            <option value="PEP_TRANSACTION">PEP tranzakció</option>
            <option value="THRESHOLD_EXCEEDED">Határérték túllépés</option>
            <option value="OTHER">Egyéb</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Kockázati szint</label>
          <select
            value={formData.riskLevel}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              setFormData({ ...formData, riskLevel: e.target.value })
            }
            className="w-full p-2 border rounded"
          >
            <option value="LOW">Alacsony</option>
            <option value="MEDIUM">Közepes</option>
            <option value="HIGH">Magas</option>
            <option value="CRITICAL">Kritikus</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Tranzakció ID (opcionális)</label>
          <input
            type="number"
            value={formData.transactionId}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, transactionId: e.target.value })
            }
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Észlelt összeg (Ft)</label>
          <input
            type="number"
            value={formData.detectedAmount}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, detectedAmount: e.target.value })
            }
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="col-span-2">
          <label className="block text-sm font-medium mb-1">Gyanú oka *</label>
          <input
            type="text"
            value={formData.suspicionReason}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, suspicionReason: e.target.value })
            }
            placeholder="Rövid összefoglaló a gyanú okáról"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div className="col-span-2">
          <label className="block text-sm font-medium mb-1">Részletes leírás *</label>
          <textarea
            value={formData.description}
            onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) =>
              setFormData({ ...formData, description: e.target.value })
            }
            placeholder="A gyanús tevékenység részletes leírása..."
            rows={4}
            className="w-full p-2 border rounded"
            required
          />
        </div>
      </div>
      <div className="flex justify-end gap-2">
        <button
          type="button"
          onClick={onCancel}
          className="px-4 py-2 border rounded hover:bg-gray-50"
        >
          Mégse
        </button>
        <button
          type="submit"
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Létrehozás
        </button>
      </div>
    </form>
  );
}

function ReportDetail({
  report,
  onClose,
}: {
  report: SuspiciousReport;
  onClose: () => void;
}) {
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="text-gray-500 text-sm">Bejelentés száma</label>
          <p className="font-mono">{report.reportNumber}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">Státusz</label>
          <p>
            <span className={`px-2 py-1 text-xs text-white rounded ${statusColors[report.status]}`}>
              {statusLabels[report.status] || report.status}
            </span>
          </p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">Ügyfél neve</label>
          <p>{report.customerName}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">Okmány száma</label>
          <p>{report.customerDocumentNumber}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">Bejelentés típusa</label>
          <p>{reportTypeLabels[report.reportType] || report.reportType}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">Észlelt összeg</label>
          <p>{report.detectedAmount?.toLocaleString()} Ft</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">Beküldési határidő</label>
          <p>{new Date(report.submissionDeadline).toLocaleDateString('hu-HU')}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">Létrehozva</label>
          <p>{new Date(report.createdAt).toLocaleString('hu-HU')}</p>
        </div>
      </div>
      <div>
        <label className="text-gray-500 text-sm">Gyanú oka</label>
        <p>{report.suspicionReason}</p>
      </div>
      <div>
        <label className="text-gray-500 text-sm">Részletes leírás</label>
        <p className="whitespace-pre-wrap">{report.description}</p>
      </div>
      <div>
        <label className="text-gray-500 text-sm">Bejelentő</label>
        <p>{report.reporterName}</p>
      </div>
      {report.submittedAt && (
        <div>
          <label className="text-gray-500 text-sm">Beküldve</label>
          <p>{new Date(report.submittedAt).toLocaleString('hu-HU')}</p>
        </div>
      )}
      <div className="border-t pt-4">
        <button
          onClick={onClose}
          className="px-4 py-2 border rounded hover:bg-gray-50"
        >
          Bezárás
        </button>
      </div>
    </div>
  );
}
