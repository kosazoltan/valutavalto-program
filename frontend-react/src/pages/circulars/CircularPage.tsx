import React, { useState, useEffect, useCallback } from 'react';
import { api } from '@/services/api/index';
import { safeArray } from '@/utils/safeArray';
import { useTranslation } from 'react-i18next'

interface Circular {
  id: number;
  circularNumber: string;
  title: string;
  circularType: string;
  category: string;
  content: string;
  version: number;
  status: string;
  effectiveDate: string;
  expiryDate?: string;
  createdBy: string;
  publishedAt?: string;
  acknowledgedCount: number;
  totalWorkerCount: number;
  createdAt: string;
}

const statusColors: Record<string, string> = {
  DRAFT: 'bg-gray-500',
  PUBLISHED: 'bg-green-500',
  ARCHIVED: 'bg-yellow-500',
  SUPERSEDED: 'bg-blue-500',
};

const statusLabels: Record<string, string> = {
  DRAFT: 'Piszkozat',
  PUBLISHED: 'Közzétéve',
  ARCHIVED: 'Archivált',
  SUPERSEDED: 'Felülírt',
};

const typeLabels: Record<string, string> = {
  CIRCULAR: 'Körlevél',
  REGULATION: 'Szabályzat',
  GUIDELINE: 'Irányelv',
  NOTIFICATION: 'Értesítés',
};

const categoryLabels: Record<string, string> = {
  COMPLIANCE: 'Megfelelőség',
  OPERATIONAL: 'Működési',
  HR: 'HR',
  SECURITY: 'Biztonság',
  TECHNICAL: 'Technikai',
  OTHER: 'Egyéb',
};

export default function CircularPage() {
  const { t } = useTranslation()
  const [circulars, setCirculars] = useState<Circular[]>([]);
  const [unacknowledged, setUnacknowledged] = useState<Circular[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('active');
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [selectedCircular, setSelectedCircular] = useState<Circular | null>(null);
  const [showViewDialog, setShowViewDialog] = useState(false);

  const loadCirculars = useCallback(async () => {
    setLoading(true);
    try {
      let response;
      if (activeTab === 'active') {
        response = await api.get('/circulars/active');
      } else if (activeTab === 'archived') {
        response = await api.get('/circulars/archived');
      } else {
        response = await api.get(`/circulars/type/${activeTab.toUpperCase()}`);
      }
      setCirculars(response?.data || []);
    } catch {
      setCirculars([]);
    } finally {
      setLoading(false);
    }
  }, [activeTab]);

  const loadUnacknowledged = useCallback(async () => {
    try {
      // Per-worker: saját nem nyugtázott körlevelek (legacy paritás)
      const response = await api.get('/circulars/my-unacknowledged');
      setUnacknowledged(response?.data || []);
    } catch {
      // Fallback: régi endpoint
      try {
        const response = await api.get('/circulars/unacknowledged');
        setUnacknowledged(response?.data || []);
      } catch {
        setUnacknowledged([]);
      }
    }
  }, []);

  useEffect(() => {
    void loadCirculars();
    void loadUnacknowledged();
  }, [loadCirculars, loadUnacknowledged]);

  const handlePublish = useCallback(async (id: number) => {
    if (window.confirm('Biztosan közzéteszi a dokumentumot?')) {
      try {
        await api.post(`/circulars/${id}/publish`);
        void loadCirculars();
      } catch {
        // Intentional noop: page reload keeps UX consistent.
      }
    }
  }, [loadCirculars]);

  const handleArchive = useCallback(async (id: number) => {
    if (window.confirm('Biztosan archiválja a dokumentumot?')) {
      try {
        await api.post(`/circulars/${id}/archive`);
        void loadCirculars();
      } catch {
        // Intentional noop: page reload keeps UX consistent.
      }
    }
  }, [loadCirculars]);

  const handleAcknowledge = useCallback(async (id: number) => {
    try {
      // Per-worker nyugtázás (legacy AT.xxx fájl megfelelő)
      await api.post(`/circulars/${id}/acknowledge-worker`);
      void loadCirculars();
      void loadUnacknowledged();
    } catch {
      // Fallback: régi acknowledge endpoint
      try {
        await api.post(`/circulars/${id}/acknowledge`);
        void loadCirculars();
        void loadUnacknowledged();
      } catch {
        // Intentional noop
      }
    }
  }, [loadCirculars, loadUnacknowledged]);

  const filteredCirculars = safeArray<Circular>(circulars).filter(c =>
    c.circularNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.title?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleCreateSubmit = useCallback(async (formData: {
    title: string;
    circularType: string;
    category: string;
    content: string;
    effectiveDate: string;
    expiryDate: string;
  }) => {
    try {
      await api.post('/circulars', {
        ...formData,
        effectiveDate: formData.effectiveDate + 'T00:00:00',
        expiryDate: formData.expiryDate ? formData.expiryDate + 'T23:59:59' : null,
      });
      setShowCreateDialog(false);
      void loadCirculars();
    } catch {
      // Intentional noop: page reload keeps UX consistent.
    }
  }, [loadCirculars]);

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3">
        <div>
          <h1 className="text-lg font-bold">{t('circulars.korlevelekEsSzabalyzatok')}</h1>
          <p className="text-gray-500">{t('circulars.vallalatiDokumentumokKezelese')}</p>
        </div>
        <button
          onClick={() => setShowCreateDialog(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          {t('circulars.ujDokumentum')}
        </button>
      </div>

      {unacknowledged.length > 0 && (
        <div className="mb-3 p-4 border border-orange-500 rounded bg-orange-50">
          <h3 className="font-semibold text-orange-700 mb-2">
            {t('circulars.elolvasasraVaroDokumentumok')}{unacknowledged.length})
          </h3>
          <div className="space-y-2">
            {unacknowledged.map((circular) => (
              <div
                key={circular.id}
                className="flex items-center justify-between p-3 bg-white rounded border"
              >
                <div>
                  <span className="font-mono text-sm mr-2">{circular.circularNumber}</span>
                  <span className="font-medium">{circular.title}</span>
                  <span className="ml-2 px-2 py-0.5 text-xs bg-gray-100 rounded">
                    {typeLabels[circular.circularType]}
                  </span>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => {
                      setSelectedCircular(circular);
                      setShowViewDialog(true);
                    }}
                    className="px-3 py-1 text-sm border rounded hover:bg-gray-50"
                  >
                    {t('circulars.megnyitas')}
                  </button>
                  <button
                    onClick={() => handleAcknowledge(circular.id)}
                    className="px-3 py-1 text-sm bg-green-600 text-white rounded hover:bg-green-700"
                  >
                    {t('circulars.ertettem')}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="mb-3">
        <input
          type="text"
          placeholder="Keresés szám vagy cím alapján..."
          value={searchTerm}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchTerm(e.target.value)}
          className="w-full p-2 border rounded"
        />
      </div>

      <div className="mb-4 flex gap-2">
        {['active', 'circular', 'regulation', 'archived'].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 rounded ${
              activeTab === tab ? 'bg-blue-600 text-white' : 'bg-gray-100 hover:bg-gray-200'
            }`}
          >
            {tab === 'active' ? 'Aktív' : tab === 'circular' ? 'Körlevelek' : tab === 'regulation' ? 'Szabályzatok' : 'Archivált'}
          </button>
        ))}
      </div>

      <div className="bg-white rounded border">
        {loading ? (
          <div className="text-center py-8">Betöltés...</div>
        ) : filteredCirculars.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            {t('circulars.nincsenekDokumentumokEbbenAKategoriaban')}
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-3 text-left">{t('circulars.szam')}</th>
                <th className="p-3 text-left">{t('common.address')}</th>
                <th className="p-3 text-left">{t('common.type')}</th>
                <th className="p-3 text-left">{t('common.category')}</th>
                <th className="p-3 text-left">{t('circulars.verzio')}</th>
                <th className="p-3 text-left">{t('circulars.hatalyos')}</th>
                <th className="p-3 text-left">{t('circulars.visszaigazolas')}</th>
                <th className="p-3 text-left">{t('common.status')}</th>
                <th className="p-3 text-left">{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filteredCirculars.map((circular) => (
                <tr key={circular.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-mono">{circular.circularNumber}</td>
                  <td className="p-3">{circular.title}</td>
                  <td className="p-3">{typeLabels[circular.circularType] || circular.circularType}</td>
                  <td className="p-3">{categoryLabels[circular.category] || circular.category}</td>
                  {/* eslint-disable-next-line i18next/no-literal-string */}
                  <td className="p-3">v{circular.version}</td>
                  <td className="p-3">
                    {new Date(circular.effectiveDate).toLocaleDateString('hu-HU')}
                    {circular.expiryDate && (
                      <span className="text-gray-500">
                        {' - '}{new Date(circular.expiryDate).toLocaleDateString('hu-HU')}
                      </span>
                    )}
                  </td>
                  <td className="p-3">
                    {circular.acknowledgedCount}/{circular.totalWorkerCount}
                  </td>
                  <td className="p-3">
                    <span className={`px-2 py-1 text-xs text-white rounded ${statusColors[circular.status]}`}>
                      {statusLabels[circular.status] || circular.status}
                    </span>
                  </td>
                  <td className="p-3">
                    <div className="flex gap-2">
                      <button
                        onClick={() => {
                          setSelectedCircular(circular);
                          setShowViewDialog(true);
                        }}
                        className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                      >
                        {t('circulars.megtekint')}
                      </button>
                      {circular.status === 'DRAFT' && (
                        <button
                          onClick={() => handlePublish(circular.id)}
                          className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                        >
                          {t('circulars.kozzetetel')}
                        </button>
                      )}
                      {circular.status === 'PUBLISHED' && (
                        <button
                          onClick={() => handleArchive(circular.id)}
                          className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                        >
                          {t('archiving.archivalas')}
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {showCreateDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">{t('circulars.ujDokumentumLetrehozasa')}</h2>
            <CreateCircularForm
              onSubmit={handleCreateSubmit}
              onCancel={() => setShowCreateDialog(false)}
            />
          </div>
        </div>
      )}

      {showViewDialog && selectedCircular && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 max-w-4xl w-full max-h-[80vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">{selectedCircular.title}</h2>
            <CircularView
              circular={selectedCircular}
              onAcknowledge={() => {
                handleAcknowledge(selectedCircular.id);
                setShowViewDialog(false);
              }}
              onClose={() => setShowViewDialog(false)}
            />
          </div>
        </div>
      )}
    </div>
  );
}

function CreateCircularForm({
  onSubmit,
  onCancel,
}: {
  onSubmit: (data: {
    title: string;
    circularType: string;
    category: string;
    content: string;
    effectiveDate: string;
    expiryDate: string;
  }) => void;
  onCancel: () => void;
}) {
  const { t } = useTranslation()
  const [formData, setFormData] = useState({
    title: '',
    circularType: 'CIRCULAR',
    category: 'OPERATIONAL',
    content: '',
    effectiveDate: new Date().toISOString().split('T')[0] || '',
    expiryDate: '',
  });

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div className="col-span-2">
          <label className="block text-sm font-medium mb-1">{t('circulars.cim')}</label>
          <input
            type="text"
            value={formData.title}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, title: e.target.value })}
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">{t('circulars.tipus')}</label>
          <select
            value={formData.circularType}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, circularType: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="CIRCULAR">{t('circulars.korlevel')}</option>
            <option value="REGULATION">{t('circulars.szabalyzat')}</option>
            <option value="GUIDELINE">{t('circulars.iranyelv')}</option>
            <option value="NOTIFICATION">{t('circulars.ertesites')}</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">{t('circulars.kategoria')}</label>
          <select
            value={formData.category}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, category: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="COMPLIANCE">{t('circulars.megfeleloseg')}</option>
            <option value="OPERATIONAL">{t('circulars.mukodesi')}</option>
            <option value="HR">HR</option>
            <option value="SECURITY">{t('circulars.biztonsag')}</option>
            <option value="TECHNICAL">{t('circulars.technikai')}</option>
            <option value="OTHER">{t('common.other')}</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">{t('circulars.hatalybaLepes')}</label>
          <input
            type="date"
            value={formData.effectiveDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, effectiveDate: e.target.value })}
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">{t('circulars.lejaratOpcionalis')}</label>
          <input
            type="date"
            value={formData.expiryDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, expiryDate: e.target.value })}
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="col-span-2">
          <label className="block text-sm font-medium mb-1">{t('circulars.tartalom')}</label>
          <textarea
            value={formData.content}
            onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setFormData({ ...formData, content: e.target.value })}
            placeholder="A dokumentum szövege..."
            rows={10}
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

function CircularView({
  circular,
  onAcknowledge,
  onClose,
}: {
  circular: Circular;
  onAcknowledge: () => void;
  onClose: () => void;
}) {
  const { t } = useTranslation()
  return (
    <div className="space-y-3">
      <div className="grid grid-cols-3 gap-4 text-sm">
        <div>
          <label className="text-gray-500">{t('circulars.dokumentumSzam')}</label>
          <p className="font-mono">{circular.circularNumber}</p>
        </div>
        <div>
          <label className="text-gray-500">{t('cashier.receiptType')}</label>
          <p>{typeLabels[circular.circularType]}</p>
        </div>
        <div>
          <label className="text-gray-500">{t('circulars.verzio')}</label>
          {/* eslint-disable-next-line i18next/no-literal-string */}
          <p>v{circular.version}</p>
        </div>
        <div>
          <label className="text-gray-500">{t('common.category')}</label>
          <p>{categoryLabels[circular.category]}</p>
        </div>
        <div>
          <label className="text-gray-500">{t('circulars.hatalyos')}</label>
          <p>{new Date(circular.effectiveDate).toLocaleDateString('hu-HU')}</p>
        </div>
        <div>
          <label className="text-gray-500">{t('common.status')}</label>
          <span className={`px-2 py-1 text-xs text-white rounded ${statusColors[circular.status]}`}>
            {statusLabels[circular.status]}
          </span>
        </div>
      </div>

      <div className="border-t pt-4">
        <div className="whitespace-pre-wrap">{circular.content}</div>
      </div>

      <div className="border-t pt-4 flex justify-between">
        <button
          onClick={onClose}
          className="px-4 py-2 border rounded hover:bg-gray-50"
        >
          {t('common.close')}
        </button>
        {circular.status === 'PUBLISHED' && (
          <button
            onClick={onAcknowledge}
            className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
          >
            {t('circulars.elolvastamEsMegertettem')}
          </button>
        )}
      </div>
    </div>
  );
}
