import React, { useState, useEffect } from 'react';
import { api } from '@/services/api';

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
  const [circulars, setCirculars] = useState<Circular[]>([]);
  const [unacknowledged, setUnacknowledged] = useState<Circular[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('active');
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [selectedCircular, setSelectedCircular] = useState<Circular | null>(null);
  const [showViewDialog, setShowViewDialog] = useState(false);

  useEffect(() => {
    loadCirculars();
    loadUnacknowledged();
  }, [activeTab]);

  const loadCirculars = async () => {
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
    } catch (error) {
      console.error('Failed to load circulars:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadUnacknowledged = async () => {
    try {
      const response = await api.get('/circulars/unacknowledged');
      setUnacknowledged(response?.data || []);
    } catch (error) {
      console.error('Failed to load unacknowledged:', error);
    }
  };

  const handlePublish = async (id: number) => {
    if (window.confirm('Biztosan közzéteszi a dokumentumot?')) {
      try {
        await api.post(`/circulars/${id}/publish`);
        loadCirculars();
      } catch (error) {
        console.error('Failed to publish:', error);
      }
    }
  };

  const handleArchive = async (id: number) => {
    if (window.confirm('Biztosan archiválja a dokumentumot?')) {
      try {
        await api.post(`/circulars/${id}/archive`);
        loadCirculars();
      } catch (error) {
        console.error('Failed to archive:', error);
      }
    }
  };

  const handleAcknowledge = async (id: number) => {
    try {
      await api.post(`/circulars/${id}/acknowledge`);
      loadCirculars();
      loadUnacknowledged();
    } catch (error) {
      console.error('Failed to acknowledge:', error);
    }
  };

  const filteredCirculars = circulars.filter(c =>
    c.circularNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    c.title?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleCreateSubmit = async (formData: {
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
      loadCirculars();
    } catch (error) {
      console.error('Failed to create circular:', error);
    }
  };

  return (
    <div className="container mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">Körlevelek és Szabályzatok</h1>
          <p className="text-gray-500">Vállalati dokumentumok kezelése</p>
        </div>
        <button
          onClick={() => setShowCreateDialog(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          + Új dokumentum
        </button>
      </div>

      {unacknowledged.length > 0 && (
        <div className="mb-6 p-4 border border-orange-500 rounded bg-orange-50">
          <h3 className="font-semibold text-orange-700 mb-2">
            Elolvasásra váró dokumentumok ({unacknowledged.length})
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
                    Megnyitás
                  </button>
                  <button
                    onClick={() => handleAcknowledge(circular.id)}
                    className="px-3 py-1 text-sm bg-green-600 text-white rounded hover:bg-green-700"
                  >
                    Értettem
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="mb-6">
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
            Nincsenek dokumentumok ebben a kategóriában
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-3 text-left">Szám</th>
                <th className="p-3 text-left">Cím</th>
                <th className="p-3 text-left">Típus</th>
                <th className="p-3 text-left">Kategória</th>
                <th className="p-3 text-left">Verzió</th>
                <th className="p-3 text-left">Hatályos</th>
                <th className="p-3 text-left">Visszaigazolás</th>
                <th className="p-3 text-left">Státusz</th>
                <th className="p-3 text-left">Műveletek</th>
              </tr>
            </thead>
            <tbody>
              {filteredCirculars.map((circular) => (
                <tr key={circular.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-mono">{circular.circularNumber}</td>
                  <td className="p-3">{circular.title}</td>
                  <td className="p-3">{typeLabels[circular.circularType] || circular.circularType}</td>
                  <td className="p-3">{categoryLabels[circular.category] || circular.category}</td>
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
                        Megtekint
                      </button>
                      {circular.status === 'DRAFT' && (
                        <button
                          onClick={() => handlePublish(circular.id)}
                          className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                        >
                          Közzététel
                        </button>
                      )}
                      {circular.status === 'PUBLISHED' && (
                        <button
                          onClick={() => handleArchive(circular.id)}
                          className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                        >
                          Archiválás
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
          <div className="bg-white rounded-lg p-6 max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">Új dokumentum létrehozása</h2>
            <CreateCircularForm
              onSubmit={handleCreateSubmit}
              onCancel={() => setShowCreateDialog(false)}
            />
          </div>
        </div>
      )}

      {showViewDialog && selectedCircular && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-4xl w-full max-h-[80vh] overflow-y-auto">
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
          <label className="block text-sm font-medium mb-1">Cím *</label>
          <input
            type="text"
            value={formData.title}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, title: e.target.value })}
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Típus *</label>
          <select
            value={formData.circularType}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, circularType: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="CIRCULAR">Körlevél</option>
            <option value="REGULATION">Szabályzat</option>
            <option value="GUIDELINE">Irányelv</option>
            <option value="NOTIFICATION">Értesítés</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Kategória *</label>
          <select
            value={formData.category}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, category: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="COMPLIANCE">Megfelelőség</option>
            <option value="OPERATIONAL">Működési</option>
            <option value="HR">HR</option>
            <option value="SECURITY">Biztonság</option>
            <option value="TECHNICAL">Technikai</option>
            <option value="OTHER">Egyéb</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Hatályba lépés *</label>
          <input
            type="date"
            value={formData.effectiveDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, effectiveDate: e.target.value })}
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Lejárat (opcionális)</label>
          <input
            type="date"
            value={formData.expiryDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, expiryDate: e.target.value })}
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="col-span-2">
          <label className="block text-sm font-medium mb-1">Tartalom *</label>
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

function CircularView({
  circular,
  onAcknowledge,
  onClose,
}: {
  circular: Circular;
  onAcknowledge: () => void;
  onClose: () => void;
}) {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-3 gap-4 text-sm">
        <div>
          <label className="text-gray-500">Dokumentum szám</label>
          <p className="font-mono">{circular.circularNumber}</p>
        </div>
        <div>
          <label className="text-gray-500">Típus</label>
          <p>{typeLabels[circular.circularType]}</p>
        </div>
        <div>
          <label className="text-gray-500">Verzió</label>
          <p>v{circular.version}</p>
        </div>
        <div>
          <label className="text-gray-500">Kategória</label>
          <p>{categoryLabels[circular.category]}</p>
        </div>
        <div>
          <label className="text-gray-500">Hatályos</label>
          <p>{new Date(circular.effectiveDate).toLocaleDateString('hu-HU')}</p>
        </div>
        <div>
          <label className="text-gray-500">Státusz</label>
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
          Bezárás
        </button>
        {circular.status === 'PUBLISHED' && (
          <button
            onClick={onAcknowledge}
            className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
          >
            Elolvastam és megértettem
          </button>
        )}
      </div>
    </div>
  );
}
