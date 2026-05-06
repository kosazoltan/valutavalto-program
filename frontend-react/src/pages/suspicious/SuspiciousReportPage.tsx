import React, { useState, useEffect, useCallback } from 'react';
import { api } from '@/services/api/index';
import { safeArray } from '@/utils/safeArray';
import { useTranslation } from 'react-i18next'

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
  const { t } = useTranslation()
  const [reports, setReports] = useState<SuspiciousReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('pending');
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [selectedReport, setSelectedReport] = useState<SuspiciousReport | null>(null);
  const [showDetailDialog, setShowDetailDialog] = useState(false);

  const loadReports = useCallback(async () => {
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
      setReports(safeArray<SuspiciousReport>(response?.data));
    } catch {
      setReports([]);
    } finally {
      setLoading(false);
    }
  }, [activeTab]);

  useEffect(() => {
    void loadReports();
  }, [loadReports]);

  const handleSubmitForReview = useCallback(async (id: number) => {
    try {
      await api.post(`/suspicious-reports/${id}/submit-review`);
      void loadReports();
    } catch {
      // Intentional noop: list remains visible.
    }
  }, [loadReports]);

  const handleApprove = useCallback(async (id: number) => {
    const notes = prompt('Jóváhagyási megjegyzés (opcionális):');
    try {
      await api.post(`/suspicious-reports/${id}/approve`, { notes });
      void loadReports();
    } catch {
      // Intentional noop: list remains visible.
    }
  }, [loadReports]);

  const handleReject = useCallback(async (id: number) => {
    const reason = prompt('Elutasítás oka:');
    if (reason) {
      try {
        await api.post(`/suspicious-reports/${id}/reject`, { reason });
        void loadReports();
      } catch {
        // Intentional noop: list remains visible.
      }
    }
  }, [loadReports]);

  const handleSubmitToAuthority = useCallback(async (id: number) => {
    if (window.confirm('Biztosan beküldi a bejelentést a NAV felé?')) {
      try {
        await api.post(`/suspicious-reports/${id}/submit-authority`);
        void loadReports();
      } catch {
        // Intentional noop: list remains visible.
      }
    }
  }, [loadReports]);

  const filteredReports = reports.filter(r =>
    r.reportNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.customerName?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getDaysUntilDeadline = (deadline: string) => {
    const diff = new Date(deadline).getTime() - new Date().getTime();
    return Math.ceil(diff / (1000 * 60 * 60 * 24));
  };

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3">
        <div>
          <h1 className="text-lg font-bold">Gyanús ügyletek (Pmt.)</h1>
          <p className="text-gray-500">{t('suspicious.penzmosasElleniBejelentesekKezelese')}</p>
        </div>
        <button
          onClick={() => setShowCreateDialog(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          {t('suspicious.ujBejelentes')}
        </button>
      </div>

      <div className="mb-3">
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
            {t('suspicious.nincsenekBejelentesekEbbenAKategoriaban')}
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-3 text-left">{t('circulars.szam')}</th>
                <th className="p-3 text-left">{t('common.customer')}</th>
                <th className="p-3 text-left">{t('common.type')}</th>
                <th className="p-3 text-left">{t('common.amount')}</th>
                <th className="p-3 text-left">{t('suspicious.hatarido')}</th>
                <th className="p-3 text-left">{t('common.status')}</th>
                <th className="p-3 text-left">{t('common.actions')}</th>
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
                    <td className="p-3">{report.detectedAmount?.toLocaleString()} {t('components.ft')}</td>
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
                          {t('common.details')}
                        </button>
                        {report.status === 'DRAFT' && (
                          <button
                            onClick={() => handleSubmitForReview(report.id)}
                            className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                          >
                            {t('suspicious.jovahagyasra')}
                          </button>
                        )}
                        {report.status === 'PENDING_REVIEW' && (
                          <>
                            <button
                              onClick={() => handleApprove(report.id)}
                              className="px-2 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700"
                            >
                              {t('suspicious.jovahagy')}
                            </button>
                            <button
                              onClick={() => handleReject(report.id)}
                              className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700"
                            >
                              {t('suspicious.elutasit')}
                            </button>
                          </>
                        )}
                        {report.status === 'APPROVED' && (
                          <button
                            onClick={() => handleSubmitToAuthority(report.id)}
                            className="px-2 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700"
                          >
                            {t('suspicious.navNakKuld')}
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
          <div className="bg-white rounded-lg p-4 max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">{t('suspicious.ujGyanusUgyletBejelentes')}</h2>
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
          <div className="bg-white rounded-lg p-4 max-w-3xl w-full max-h-[80vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">{t('suspicious.bejelentesReszletei')}{selectedReport.reportNumber}</h2>
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
  const { t } = useTranslation()
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
    } catch {
      // Intentional noop: form remains visible for correction.
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium mb-1">{t('pep.ugyfelNeve2')}</label>
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
          <label className="block text-sm font-medium mb-1">{t('suspicious.okmanySzama')}</label>
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
          <label className="block text-sm font-medium mb-1">{t('suspicious.bejelentesTipusa')}</label>
          <select
            value={formData.reportType}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              setFormData({ ...formData, reportType: e.target.value })
            }
            className="w-full p-2 border rounded"
          >
            <option value="SUSPICIOUS_TRANSACTION">{t('reports.gyanusTranzakcio')}</option>
            <option value="STRUCTURING">{t('suspicious.strukturalas')}</option>
            <option value="UNUSUAL_PATTERN">{t('suspicious.szokatlanMinta')}</option>
            <option value="BLACKLIST_MATCH">{t('suspicious.tiltolistaEgyezes')}</option>
            <option value="PEP_TRANSACTION">{t('suspicious.pepTranzakcio')}</option>
            <option value="THRESHOLD_EXCEEDED">{t('suspicious.hatarertekTullepes')}</option>
            <option value="OTHER">{t('common.other')}</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">{t('suspicious.kockazatiSzint')}</label>
          <select
            value={formData.riskLevel}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              setFormData({ ...formData, riskLevel: e.target.value })
            }
            className="w-full p-2 border rounded"
          >
            <option value="LOW">{t('suspicious.alacsony')}</option>
            <option value="MEDIUM">{t('suspicious.kozepes')}</option>
            <option value="HIGH">{t('suspicious.magas')}</option>
            <option value="CRITICAL">{t('suspicious.kritikus')}</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">{t('suspicious.tranzakcioIdOpcionalis')}</label>
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
          <label className="block text-sm font-medium mb-1">{t('suspicious.eszleltOsszegFt')}</label>
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
          <label className="block text-sm font-medium mb-1">{t('suspicious.gyanuOka')}</label>
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
          <label className="block text-sm font-medium mb-1">{t('suspicious.reszletesLeiras')}</label>
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
          {t('common.cancel')}
        </button>
        <button
          type="submit"
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          {t('common.create')}
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
  const { t } = useTranslation()
  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="text-gray-500 text-sm">{t('suspicious.bejelentesSzama')}</label>
          <p className="font-mono">{report.reportNumber}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">{t('common.status')}</label>
          <p>
            <span className={`px-2 py-1 text-xs text-white rounded ${statusColors[report.status]}`}>
              {statusLabels[report.status] || report.status}
            </span>
          </p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">{t('pep.ugyfelNeve')}</label>
          <p>{report.customerName}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">{t('suspicious.okmanySzama2')}</label>
          <p>{report.customerDocumentNumber}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">{t('suspicious.bejelentesTipusa2')}</label>
          <p>{reportTypeLabels[report.reportType] || report.reportType}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">{t('suspicious.eszleltOsszeg')}</label>
          <p>{report.detectedAmount?.toLocaleString()} {t('components.ft')}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">{t('suspicious.bekuldesiHatarido')}</label>
          <p>{new Date(report.submissionDeadline).toLocaleDateString('hu-HU')}</p>
        </div>
        <div>
          <label className="text-gray-500 text-sm">{t('common.createdAt')}</label>
          <p>{new Date(report.createdAt).toLocaleString('hu-HU')}</p>
        </div>
      </div>
      <div>
        <label className="text-gray-500 text-sm">{t('suspicious.gyanuOka2')}</label>
        <p>{report.suspicionReason}</p>
      </div>
      <div>
        <label className="text-gray-500 text-sm">{t('suspicious.reszletesLeiras2')}</label>
        <p className="whitespace-pre-wrap">{report.description}</p>
      </div>
      <div>
        <label className="text-gray-500 text-sm">{t('suspicious.bejelento')}</label>
        <p>{report.reporterName}</p>
      </div>
      {report.submittedAt && (
        <div>
          <label className="text-gray-500 text-sm">{t('mnb.bekuldve')}</label>
          <p>{new Date(report.submittedAt).toLocaleString('hu-HU')}</p>
        </div>
      )}
      <div className="border-t pt-4">
        <button
          onClick={onClose}
          className="px-4 py-2 border rounded hover:bg-gray-50"
        >
          {t('common.close')}
        </button>
      </div>
    </div>
  );
}
