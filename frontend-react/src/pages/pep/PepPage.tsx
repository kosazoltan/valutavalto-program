import React, { useState, useEffect } from 'react';
import { api } from '@/services/api';

interface PoliticallyExposedPerson {
  id: number;
  customerId: string;
  customerName: string;
  documentNumber: string;
  pepCategory: string;
  positionType: string;
  positionDescription?: string;
  country: string;
  appointmentStartDate?: string;
  appointmentEndDate?: string;
  sourceOfWealth?: string;
  sourceOfFunds?: string;
  requiresEdd: boolean;
  requiresApproval: boolean;
  maxAmountWithoutApproval?: number;
  reviewDate?: string;
  notes?: string;
  isActive: boolean;
  createdAt: string;
}

const pepCategoryLabels: Record<string, string> = {
  DIRECT: 'Közvetlen PEP',
  FAMILY: 'Családtag',
  ASSOCIATE: 'Közeli kapcsolat',
};

const positionTypeLabels: Record<string, string> = {
  HEAD_OF_STATE: 'Államfő',
  GOVERNMENT_MEMBER: 'Kormánytag',
  PARLIAMENT_MEMBER: 'Parlamenti képviselő',
  SUPREME_COURT_MEMBER: 'Legfelsőbb bírósági tag',
  CENTRAL_BANK_MEMBER: 'Jegybanki vezető',
  AMBASSADOR: 'Nagykövet',
  MILITARY_OFFICER: 'Magas rangú tiszt',
  STATE_ENTERPRISE_EXECUTIVE: 'Állami vállalat vezetője',
  POLITICAL_PARTY_LEADER: 'Politikai párt vezetője',
  INTERNATIONAL_ORG_LEADER: 'Nemzetközi szervezet vezetője',
};

const pepCategoryColors: Record<string, string> = {
  DIRECT: 'bg-red-500',
  FAMILY: 'bg-orange-500',
  ASSOCIATE: 'bg-yellow-500',
};

export default function PepPage() {
  const [pepList, setPepList] = useState<PoliticallyExposedPerson[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('active');
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [selectedPep, setSelectedPep] = useState<PoliticallyExposedPerson | null>(null);
  const [showDetailDialog, setShowDetailDialog] = useState(false);
  const [editingPep, setEditingPep] = useState<PoliticallyExposedPerson | null>(null);
  const [reviewDue, setReviewDue] = useState<PoliticallyExposedPerson[]>([]);

  useEffect(() => {
    loadPepList();
    loadReviewDue();
  }, [activeTab]);

  const loadPepList = async () => {
    setLoading(true);
    try {
      let response;
      if (activeTab === 'active') {
        response = await api.get('/pep/active');
      } else if (activeTab === 'direct') {
        response = await api.get('/pep/category/DIRECT');
      } else if (activeTab === 'family') {
        response = await api.get('/pep/category/FAMILY');
      } else if (activeTab === 'associate') {
        response = await api.get('/pep/category/ASSOCIATE');
      } else {
        response = await api.get('/pep');
      }
      setPepList(response?.data || []);
    } catch (error) {
      console.error('Failed to load PEP list:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadReviewDue = async () => {
    try {
      const response = await api.get('/pep/review-due');
      setReviewDue(response?.data || []);
    } catch (error) {
      console.error('Failed to load review due:', error);
    }
  };

  const handleSave = async (formData: {
    customerId: string;
    customerName: string;
    documentNumber: string;
    pepCategory: string;
    positionType: string;
    positionDescription: string;
    country: string;
    appointmentStartDate: string;
    appointmentEndDate: string;
    sourceOfWealth: string;
    sourceOfFunds: string;
    requiresEdd: boolean;
    requiresApproval: boolean;
    maxAmountWithoutApproval: string;
    reviewDate: string;
    notes: string;
    isActive: boolean;
  }) => {
    try {
      const payload = {
        ...formData,
        appointmentStartDate: formData.appointmentStartDate ? formData.appointmentStartDate + 'T00:00:00' : null,
        appointmentEndDate: formData.appointmentEndDate ? formData.appointmentEndDate + 'T00:00:00' : null,
        reviewDate: formData.reviewDate ? formData.reviewDate + 'T00:00:00' : null,
        maxAmountWithoutApproval: formData.maxAmountWithoutApproval
          ? parseFloat(formData.maxAmountWithoutApproval)
          : null,
      };

      if (editingPep) {
        await api.put(`/pep/${editingPep.id}`, payload);
      } else {
        await api.post('/pep', payload);
      }
      setShowCreateDialog(false);
      setEditingPep(null);
      loadPepList();
    } catch (error) {
      console.error('Failed to save PEP:', error);
    }
  };

  const filteredPepList = pepList.filter(p =>
    p.customerName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.documentNumber?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="container mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">PEP Nyilvántartás</h1>
          <p className="text-gray-500">Politikailag kitett személyek kezelése (Pmt. 4. § (1) d))</p>
        </div>
        <button
          type="button"
          onClick={() => {
            setEditingPep(null);
            setShowCreateDialog(true);
          }}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          + Új PEP regisztráció
        </button>
      </div>

      {reviewDue.length > 0 && (
        <div className="mb-6 p-4 border border-orange-500 rounded bg-orange-50">
          <h3 className="font-semibold text-orange-700 mb-2">
            Felülvizsgálat szükséges ({reviewDue.length})
          </h3>
          <div className="space-y-1">
            {reviewDue.slice(0, 3).map(pep => (
              <div key={pep.id} className="text-sm">
                <span className="font-medium">{pep.customerName}</span>
                <span className="text-gray-500 ml-2">
                  - {pep.reviewDate && new Date(pep.reviewDate).toLocaleDateString('hu-HU')}
                </span>
              </div>
            ))}
            {reviewDue.length > 3 && (
              <div className="text-sm text-gray-500">
                és további {reviewDue.length - 3} személy...
              </div>
            )}
          </div>
        </div>
      )}

      <div className="grid grid-cols-4 gap-4 mb-6">
        <div className="p-4 bg-white rounded border">
          <p className="text-sm text-gray-500">Összes PEP</p>
          <p className="text-2xl font-bold">{pepList.length}</p>
        </div>
        <div className="p-4 bg-white rounded border">
          <p className="text-sm text-gray-500">Közvetlen PEP</p>
          <p className="text-2xl font-bold text-red-600">
            {pepList.filter(p => p.pepCategory === 'DIRECT').length}
          </p>
        </div>
        <div className="p-4 bg-white rounded border">
          <p className="text-sm text-gray-500">EDD szükséges</p>
          <p className="text-2xl font-bold text-orange-600">
            {pepList.filter(p => p.requiresEdd).length}
          </p>
        </div>
        <div className="p-4 bg-white rounded border">
          <p className="text-sm text-gray-500">Felülvizsgálandó</p>
          <p className="text-2xl font-bold text-yellow-600">{reviewDue.length}</p>
        </div>
      </div>

      <div className="mb-6">
        <input
          type="text"
          placeholder="Keresés név vagy okmányszám alapján..."
          value={searchTerm}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchTerm(e.target.value)}
          className="w-full p-2 border rounded"
        />
      </div>

      <div className="mb-4 flex gap-2">
        {['active', 'direct', 'family', 'associate'].map((tab) => (
          <button
            key={tab}
            type="button"
            onClick={() => setActiveTab(tab)}
            className={`px-4 py-2 rounded ${activeTab === tab ? 'bg-blue-600 text-white' : 'bg-gray-100 hover:bg-gray-200'}`}
          >
            {tab === 'active' ? 'Aktív' : tab === 'direct' ? 'Közvetlen PEP' : tab === 'family' ? 'Családtag' : 'Közeli kapcsolat'}
          </button>
        ))}
      </div>

      <div className="bg-white rounded border">
        {loading ? (
          <div className="text-center py-8">Betöltés...</div>
        ) : filteredPepList.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            Nincsenek PEP személyek ebben a kategóriában
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-3 text-left">Név</th>
                <th className="p-3 text-left">Okmányszám</th>
                <th className="p-3 text-left">Kategória</th>
                <th className="p-3 text-left">Pozíció</th>
                <th className="p-3 text-left">Ország</th>
                <th className="p-3 text-left">EDD</th>
                <th className="p-3 text-left">Jóváhagyás</th>
                <th className="p-3 text-left">Felülvizsgálat</th>
                <th className="p-3 text-left">Műveletek</th>
              </tr>
            </thead>
            <tbody>
              {filteredPepList.map((pep) => (
                <tr key={pep.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-medium">{pep.customerName}</td>
                  <td className="p-3 font-mono">{pep.documentNumber}</td>
                  <td className="p-3">
                    <span className={`px-2 py-1 text-xs text-white rounded ${pepCategoryColors[pep.pepCategory]}`}>
                      {pepCategoryLabels[pep.pepCategory] || pep.pepCategory}
                    </span>
                  </td>
                  <td className="p-3">
                    <div className="max-w-[200px] truncate" title={positionTypeLabels[pep.positionType]}>
                      {positionTypeLabels[pep.positionType] || pep.positionType}
                    </div>
                  </td>
                  <td className="p-3">{pep.country}</td>
                  <td className="p-3">
                    {pep.requiresEdd ? (
                      <span className="px-2 py-1 text-xs text-white rounded bg-orange-500">Szükséges</span>
                    ) : (
                      <span className="px-2 py-1 text-xs border rounded">Nem</span>
                    )}
                  </td>
                  <td className="p-3">
                    {pep.requiresApproval ? (
                      <div>
                        <span className="px-2 py-1 text-xs text-white rounded bg-red-500">Igen</span>
                        {pep.maxAmountWithoutApproval && (
                          <div className="text-xs text-gray-500 mt-1">
                            &lt; {pep.maxAmountWithoutApproval?.toLocaleString()} Ft
                          </div>
                        )}
                      </div>
                    ) : (
                      <span className="px-2 py-1 text-xs border rounded">Nem</span>
                    )}
                  </td>
                  <td className="p-3">
                    {pep.reviewDate && (
                      <div className={new Date(pep.reviewDate) < new Date() ? 'text-red-500' : ''}>
                        {new Date(pep.reviewDate).toLocaleDateString('hu-HU')}
                      </div>
                    )}
                  </td>
                  <td className="p-3">
                    <div className="flex gap-2">
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedPep(pep);
                          setShowDetailDialog(true);
                        }}
                        className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                      >
                        Részletek
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setEditingPep(pep);
                          setShowCreateDialog(true);
                        }}
                        className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                      >
                        Szerkesztés
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {showDetailDialog && selectedPep && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-3xl w-full max-h-[80vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">PEP részletei - {selectedPep.customerName}</h2>
            <PepDetail pep={selectedPep} onClose={() => setShowDetailDialog(false)} />
          </div>
        </div>
      )}

      {showCreateDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">
              {editingPep ? 'PEP szerkesztése' : 'Új PEP személy regisztrálása'}
            </h2>
            <PepForm
              pep={editingPep}
              onSubmit={handleSave}
              onCancel={() => {
                setShowCreateDialog(false);
                setEditingPep(null);
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
}

function PepForm({
  pep,
  onSubmit,
  onCancel,
}: {
  pep: PoliticallyExposedPerson | null;
  onSubmit: (data: {
    customerId: string;
    customerName: string;
    documentNumber: string;
    pepCategory: string;
    positionType: string;
    positionDescription: string;
    country: string;
    appointmentStartDate: string;
    appointmentEndDate: string;
    sourceOfWealth: string;
    sourceOfFunds: string;
    requiresEdd: boolean;
    requiresApproval: boolean;
    maxAmountWithoutApproval: string;
    reviewDate: string;
    notes: string;
    isActive: boolean;
  }) => void;
  onCancel: () => void;
}) {
  const [formData, setFormData] = useState({
    customerId: pep?.customerId || '',
    customerName: pep?.customerName || '',
    documentNumber: pep?.documentNumber || '',
    pepCategory: pep?.pepCategory || 'DIRECT',
    positionType: pep?.positionType || 'GOVERNMENT_MEMBER',
    positionDescription: pep?.positionDescription || '',
    country: pep?.country || 'HU',
    appointmentStartDate: pep?.appointmentStartDate?.split('T')[0] || '',
    appointmentEndDate: pep?.appointmentEndDate?.split('T')[0] || '',
    sourceOfWealth: pep?.sourceOfWealth || '',
    sourceOfFunds: pep?.sourceOfFunds || '',
    requiresEdd: pep?.requiresEdd ?? true,
    requiresApproval: pep?.requiresApproval ?? true,
    maxAmountWithoutApproval: pep?.maxAmountWithoutApproval?.toString() || '',
    reviewDate: pep?.reviewDate?.split('T')[0] || '',
    notes: pep?.notes || '',
    isActive: pep?.isActive ?? true,
  });

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="customerName" className="block text-sm font-medium mb-1">Ügyfél neve *</label>
          <input
            id="customerName"
            type="text"
            value={formData.customerName}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, customerName: e.target.value })}
            placeholder="Teljes név"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label htmlFor="documentNumber" className="block text-sm font-medium mb-1">Okmányszám *</label>
          <input
            id="documentNumber"
            type="text"
            value={formData.documentNumber}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, documentNumber: e.target.value })}
            placeholder="Személyi ig. vagy útlevél szám"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label htmlFor="pepCategory" className="block text-sm font-medium mb-1">PEP kategória *</label>
          <select
            id="pepCategory"
            value={formData.pepCategory}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, pepCategory: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="DIRECT">Közvetlen PEP</option>
            <option value="FAMILY">Családtag</option>
            <option value="ASSOCIATE">Közeli kapcsolat</option>
          </select>
        </div>
        <div>
          <label htmlFor="positionType" className="block text-sm font-medium mb-1">Pozíció típusa *</label>
          <select
            id="positionType"
            value={formData.positionType}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, positionType: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="HEAD_OF_STATE">Államfő</option>
            <option value="GOVERNMENT_MEMBER">Kormánytag</option>
            <option value="PARLIAMENT_MEMBER">Parlamenti képviselő</option>
            <option value="SUPREME_COURT_MEMBER">Legfelsőbb bírósági tag</option>
            <option value="CENTRAL_BANK_MEMBER">Jegybanki vezető</option>
            <option value="AMBASSADOR">Nagykövet</option>
            <option value="MILITARY_OFFICER">Magas rangú tiszt</option>
            <option value="STATE_ENTERPRISE_EXECUTIVE">Állami vállalat vezetője</option>
            <option value="POLITICAL_PARTY_LEADER">Politikai párt vezetője</option>
            <option value="INTERNATIONAL_ORG_LEADER">Nemzetközi szervezet vezetője</option>
          </select>
        </div>
        <div className="col-span-2">
          <label htmlFor="positionDescription" className="block text-sm font-medium mb-1">Pozíció leírása</label>
          <input
            id="positionDescription"
            type="text"
            value={formData.positionDescription}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, positionDescription: e.target.value })}
            placeholder="pl. Pénzügyminisztérium államtitkára"
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="country" className="block text-sm font-medium mb-1">Ország *</label>
          <input
            id="country"
            type="text"
            value={formData.country}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, country: e.target.value })}
            maxLength={3}
            placeholder="HU"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label htmlFor="reviewDate" className="block text-sm font-medium mb-1">Felülvizsgálat dátuma</label>
          <input
            id="reviewDate"
            type="date"
            value={formData.reviewDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, reviewDate: e.target.value })}
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="appointmentStartDate" className="block text-sm font-medium mb-1">Kinevezés kezdete</label>
          <input
            id="appointmentStartDate"
            type="date"
            value={formData.appointmentStartDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, appointmentStartDate: e.target.value })}
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="appointmentEndDate" className="block text-sm font-medium mb-1">Kinevezés vége</label>
          <input
            id="appointmentEndDate"
            type="date"
            value={formData.appointmentEndDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, appointmentEndDate: e.target.value })}
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="col-span-2">
          <label htmlFor="sourceOfWealth" className="block text-sm font-medium mb-1">Vagyon eredete</label>
          <textarea
            id="sourceOfWealth"
            value={formData.sourceOfWealth}
            onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setFormData({ ...formData, sourceOfWealth: e.target.value })}
            rows={2}
            placeholder="Vagyon forrásának leírása"
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="col-span-2">
          <label htmlFor="sourceOfFunds" className="block text-sm font-medium mb-1">Pénzeszközök forrása</label>
          <textarea
            id="sourceOfFunds"
            value={formData.sourceOfFunds}
            onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setFormData({ ...formData, sourceOfFunds: e.target.value })}
            rows={2}
            placeholder="Tranzakciókhoz használt pénzeszközök forrása"
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="flex items-center gap-2">
          <input
            id="requiresEdd"
            type="checkbox"
            checked={formData.requiresEdd}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, requiresEdd: e.target.checked })}
            className="h-4 w-4"
          />
          <label htmlFor="requiresEdd" className="text-sm font-medium">Fokozott átvilágítás (EDD) szükséges</label>
        </div>
        <div className="flex items-center gap-2">
          <input
            id="requiresApproval"
            type="checkbox"
            checked={formData.requiresApproval}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, requiresApproval: e.target.checked })}
            className="h-4 w-4"
          />
          <label htmlFor="requiresApproval" className="text-sm font-medium">Vezetői jóváhagyás szükséges</label>
        </div>
        {formData.requiresApproval && (
          <div>
            <label htmlFor="maxAmountWithoutApproval" className="block text-sm font-medium mb-1">Jóváhagyás nélküli max összeg (Ft)</label>
            <input
              id="maxAmountWithoutApproval"
              type="number"
              value={formData.maxAmountWithoutApproval}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, maxAmountWithoutApproval: e.target.value })}
              placeholder="pl. 500000"
              className="w-full p-2 border rounded"
            />
          </div>
        )}
        <div className="col-span-2">
          <label htmlFor="notes" className="block text-sm font-medium mb-1">Megjegyzések</label>
          <textarea
            id="notes"
            value={formData.notes}
            onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setFormData({ ...formData, notes: e.target.value })}
            rows={3}
            placeholder="Egyéb megjegyzések"
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="flex items-center gap-2">
          <input
            id="isActive"
            type="checkbox"
            checked={formData.isActive}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, isActive: e.target.checked })}
            className="h-4 w-4"
          />
          <label htmlFor="isActive" className="text-sm font-medium">Aktív</label>
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
          {pep ? 'Mentés' : 'Regisztrálás'}
        </button>
      </div>
    </form>
  );
}

function PepDetail({ pep, onClose }: { pep: PoliticallyExposedPerson; onClose: () => void }) {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-3 gap-4">
        <div>
          <p className="text-gray-500 text-sm">Ügyfél neve</p>
          <p className="font-medium">{pep.customerName}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Okmányszám</p>
          <p className="font-mono">{pep.documentNumber}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Kategória</p>
          <span className={`px-2 py-1 text-xs text-white rounded ${pepCategoryColors[pep.pepCategory]}`}>
            {pepCategoryLabels[pep.pepCategory]}
          </span>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Pozíció típusa</p>
          <p>{positionTypeLabels[pep.positionType]}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Pozíció leírása</p>
          <p>{pep.positionDescription || '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Ország</p>
          <p>{pep.country}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Kinevezés kezdete</p>
          <p>{pep.appointmentStartDate ? new Date(pep.appointmentStartDate).toLocaleDateString('hu-HU') : '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Kinevezés vége</p>
          <p>{pep.appointmentEndDate ? new Date(pep.appointmentEndDate).toLocaleDateString('hu-HU') : '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Következő felülvizsgálat</p>
          <p className={pep.reviewDate && new Date(pep.reviewDate) < new Date() ? 'text-red-500 font-semibold' : ''}>
            {pep.reviewDate ? new Date(pep.reviewDate).toLocaleDateString('hu-HU') : '-'}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <p className="text-gray-500 text-sm">Vagyon eredete</p>
          <p className="whitespace-pre-wrap">{pep.sourceOfWealth || '-'}</p>
        </div>
        <div>
          <p className="text-gray-500 text-sm">Pénzeszközök forrása</p>
          <p className="whitespace-pre-wrap">{pep.sourceOfFunds || '-'}</p>
        </div>
      </div>

      <div className="flex gap-4">
        <div className="flex items-center gap-2">
          <p className="text-gray-500 text-sm">EDD szükséges:</p>
          {pep.requiresEdd ? (
            <span className="px-2 py-1 text-xs text-white rounded bg-orange-500">Igen</span>
          ) : (
            <span className="px-2 py-1 text-xs border rounded">Nem</span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <p className="text-gray-500 text-sm">Jóváhagyás szükséges:</p>
          {pep.requiresApproval ? (
            <span className="px-2 py-1 text-xs text-white rounded bg-red-500">Igen</span>
          ) : (
            <span className="px-2 py-1 text-xs border rounded">Nem</span>
          )}
        </div>
        {pep.requiresApproval && pep.maxAmountWithoutApproval && (
          <div className="flex items-center gap-2">
            <p className="text-gray-500 text-sm">Limit nélküli max:</p>
            <span>{pep.maxAmountWithoutApproval.toLocaleString()} Ft</span>
          </div>
        )}
      </div>

      {pep.notes && (
        <div>
          <p className="text-gray-500 text-sm">Megjegyzések</p>
          <p className="whitespace-pre-wrap">{pep.notes}</p>
        </div>
      )}

      <div className="text-sm text-gray-500">
        Létrehozva: {new Date(pep.createdAt).toLocaleString('hu-HU')}
      </div>

      <div className="flex justify-end">
        <button
          type="button"
          onClick={onClose}
          className="px-4 py-2 border rounded hover:bg-gray-50"
        >
          Bezárás
        </button>
      </div>
    </div>
  );
}
