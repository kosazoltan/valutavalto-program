import React, { useState, useEffect } from 'react';
import { api } from '@/services/api';

interface FeePackage {
  id: number;
  code: string;
  name: string;
  description?: string;
  buyFeeType: string;
  buyFeeValue: number;
  buyFeeMin: number;
  buyFeeMax?: number;
  sellFeeType: string;
  sellFeeValue: number;
  sellFeeMin: number;
  sellFeeMax?: number;
  handlingFee: number;
  expressFee: number;
  offHoursSurcharge: number;
  isDefault: boolean;
  isActive: boolean;
  customerCount: number;
  createdAt: string;
}

export default function FeePackagePage() {
  const [feePackages, setFeePackages] = useState<FeePackage[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [editingPackage, setEditingPackage] = useState<FeePackage | null>(null);

  useEffect(() => {
    loadFeePackages();
  }, []);

  const loadFeePackages = async () => {
    setLoading(true);
    try {
      const response = await api.get('/fee-packages');
      setFeePackages(response?.data || []);
    } catch (error) {
      console.error('Failed to load fee packages:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (window.confirm('Biztosan törli a díjcsomagot?')) {
      try {
        await api.delete(`/fee-packages/${id}`);
        loadFeePackages();
      } catch (error) {
        console.error('Failed to delete fee package:', error);
      }
    }
  };

  const handleSetDefault = async (id: number) => {
    try {
      await api.post(`/fee-packages/${id}/set-default`);
      loadFeePackages();
    } catch (error) {
      console.error('Failed to set default:', error);
    }
  };

  const handleSave = async (formData: {
    code: string;
    name: string;
    description: string;
    buyFeeType: string;
    buyFeeValue: string;
    buyFeeMin: string;
    buyFeeMax: string;
    sellFeeType: string;
    sellFeeValue: string;
    sellFeeMin: string;
    sellFeeMax: string;
    handlingFee: string;
    expressFee: string;
    offHoursSurcharge: string;
    isActive: boolean;
  }) => {
    try {
      const payload = {
        ...formData,
        buyFeeValue: parseFloat(formData.buyFeeValue),
        buyFeeMin: parseFloat(formData.buyFeeMin),
        buyFeeMax: formData.buyFeeMax ? parseFloat(formData.buyFeeMax) : null,
        sellFeeValue: parseFloat(formData.sellFeeValue),
        sellFeeMin: parseFloat(formData.sellFeeMin),
        sellFeeMax: formData.sellFeeMax ? parseFloat(formData.sellFeeMax) : null,
        handlingFee: parseFloat(formData.handlingFee),
        expressFee: parseFloat(formData.expressFee),
        offHoursSurcharge: parseFloat(formData.offHoursSurcharge),
      };

      if (editingPackage) {
        await api.put(`/fee-packages/${editingPackage.id}`, payload);
      } else {
        await api.post('/fee-packages', payload);
      }
      setShowCreateDialog(false);
      setEditingPackage(null);
      loadFeePackages();
    } catch (error) {
      console.error('Failed to save fee package:', error);
    }
  };

  const filteredPackages = feePackages.filter(p =>
    p.code?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    p.name?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const formatFee = (type: string, value: number, min: number, max?: number) => {
    if (type === 'PERCENT') {
      return `${value}% (min: ${min?.toLocaleString()} Ft${max ? `, max: ${max.toLocaleString()} Ft` : ''})`;
    }
    return `${value?.toLocaleString()} Ft`;
  };

  return (
    <div className="container mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold">Díjcsomagok</h1>
          <p className="text-gray-500">Tranzakciós díjak és költségek kezelése</p>
        </div>
        <button
          type="button"
          onClick={() => {
            setEditingPackage(null);
            setShowCreateDialog(true);
          }}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          + Új díjcsomag
        </button>
      </div>

      <div className="mb-6">
        <input
          type="text"
          placeholder="Keresés kód vagy név alapján..."
          value={searchTerm}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchTerm(e.target.value)}
          className="w-full p-2 border rounded"
        />
      </div>

      <div className="bg-white rounded border">
        {loading ? (
          <div className="text-center py-8">Betöltés...</div>
        ) : filteredPackages.length === 0 ? (
          <div className="text-center py-8 text-gray-500">Nincsenek díjcsomagok</div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-3 text-left">Kód</th>
                <th className="p-3 text-left">Név</th>
                <th className="p-3 text-left">Vételi díj</th>
                <th className="p-3 text-left">Eladási díj</th>
                <th className="p-3 text-left">Kezelési díj</th>
                <th className="p-3 text-left">Expressz</th>
                <th className="p-3 text-left">Ügyfelek</th>
                <th className="p-3 text-left">Státusz</th>
                <th className="p-3 text-left">Műveletek</th>
              </tr>
            </thead>
            <tbody>
              {filteredPackages.map((pkg) => (
                <tr key={pkg.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-mono">{pkg.code}</td>
                  <td className="p-3">
                    <div className="flex items-center gap-2">
                      {pkg.name}
                      {pkg.isDefault && (
                        <span className="px-2 py-0.5 text-xs bg-blue-100 text-blue-800 rounded">Alapért.</span>
                      )}
                    </div>
                  </td>
                  <td className="p-3 text-sm">
                    {formatFee(pkg.buyFeeType, pkg.buyFeeValue, pkg.buyFeeMin, pkg.buyFeeMax)}
                  </td>
                  <td className="p-3 text-sm">
                    {formatFee(pkg.sellFeeType, pkg.sellFeeValue, pkg.sellFeeMin, pkg.sellFeeMax)}
                  </td>
                  <td className="p-3">{pkg.handlingFee?.toLocaleString()} Ft</td>
                  <td className="p-3">{pkg.expressFee?.toLocaleString()} Ft</td>
                  <td className="p-3">{pkg.customerCount || 0}</td>
                  <td className="p-3">
                    <span className={`px-2 py-1 text-xs text-white rounded ${pkg.isActive ? 'bg-green-500' : 'bg-gray-500'}`}>
                      {pkg.isActive ? 'Aktív' : 'Inaktív'}
                    </span>
                  </td>
                  <td className="p-3">
                    <div className="flex gap-2">
                      {!pkg.isDefault && (
                        <button
                          type="button"
                          onClick={() => handleSetDefault(pkg.id)}
                          className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                          title="Alapértelmezetté tétel"
                        >
                          Alapért.
                        </button>
                      )}
                      <button
                        type="button"
                        onClick={() => {
                          setEditingPackage(pkg);
                          setShowCreateDialog(true);
                        }}
                        className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                      >
                        Szerkesztés
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDelete(pkg.id)}
                        disabled={pkg.isDefault}
                        className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700 disabled:opacity-50"
                      >
                        Törlés
                      </button>
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
            <h2 className="text-xl font-bold mb-4">
              {editingPackage ? 'Díjcsomag szerkesztése' : 'Új díjcsomag létrehozása'}
            </h2>
            <FeePackageForm
              feePackage={editingPackage}
              onSubmit={handleSave}
              onCancel={() => {
                setShowCreateDialog(false);
                setEditingPackage(null);
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
}

function FeePackageForm({
  feePackage,
  onSubmit,
  onCancel,
}: {
  feePackage: FeePackage | null;
  onSubmit: (data: {
    code: string;
    name: string;
    description: string;
    buyFeeType: string;
    buyFeeValue: string;
    buyFeeMin: string;
    buyFeeMax: string;
    sellFeeType: string;
    sellFeeValue: string;
    sellFeeMin: string;
    sellFeeMax: string;
    handlingFee: string;
    expressFee: string;
    offHoursSurcharge: string;
    isActive: boolean;
  }) => void;
  onCancel: () => void;
}) {
  const [formData, setFormData] = useState({
    code: feePackage?.code || '',
    name: feePackage?.name || '',
    description: feePackage?.description || '',
    buyFeeType: feePackage?.buyFeeType || 'PERCENT',
    buyFeeValue: feePackage?.buyFeeValue?.toString() || '0',
    buyFeeMin: feePackage?.buyFeeMin?.toString() || '0',
    buyFeeMax: feePackage?.buyFeeMax?.toString() || '',
    sellFeeType: feePackage?.sellFeeType || 'PERCENT',
    sellFeeValue: feePackage?.sellFeeValue?.toString() || '0',
    sellFeeMin: feePackage?.sellFeeMin?.toString() || '0',
    sellFeeMax: feePackage?.sellFeeMax?.toString() || '',
    handlingFee: feePackage?.handlingFee?.toString() || '0',
    expressFee: feePackage?.expressFee?.toString() || '0',
    offHoursSurcharge: feePackage?.offHoursSurcharge?.toString() || '0',
    isActive: feePackage?.isActive ?? true,
  });

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="code" className="block text-sm font-medium mb-1">Kód *</label>
          <input
            id="code"
            type="text"
            value={formData.code}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, code: e.target.value })}
            placeholder="pl. STANDARD, VIP"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label htmlFor="name" className="block text-sm font-medium mb-1">Név *</label>
          <input
            id="name"
            type="text"
            value={formData.name}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, name: e.target.value })}
            placeholder="pl. Alap díjcsomag"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div className="col-span-2">
          <label htmlFor="description" className="block text-sm font-medium mb-1">Leírás</label>
          <input
            id="description"
            type="text"
            value={formData.description}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, description: e.target.value })}
            placeholder="Csomag leírása"
            className="w-full p-2 border rounded"
          />
        </div>
      </div>

      <hr className="my-4" />
      <h3 className="font-semibold">Vételi díjak</h3>
      <div className="grid grid-cols-4 gap-4">
        <div>
          <label htmlFor="buyFeeType" className="block text-sm font-medium mb-1">Típus</label>
          <select
            id="buyFeeType"
            value={formData.buyFeeType}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, buyFeeType: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="FIXED">Fix összeg</option>
            <option value="PERCENT">Százalék</option>
          </select>
        </div>
        <div>
          <label htmlFor="buyFeeValue" className="block text-sm font-medium mb-1">
            Érték {formData.buyFeeType === 'PERCENT' ? '(%)' : '(Ft)'}
          </label>
          <input
            id="buyFeeValue"
            type="number"
            step="0.01"
            value={formData.buyFeeValue}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, buyFeeValue: e.target.value })}
            placeholder="0"
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="buyFeeMin" className="block text-sm font-medium mb-1">Minimum (Ft)</label>
          <input
            id="buyFeeMin"
            type="number"
            value={formData.buyFeeMin}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, buyFeeMin: e.target.value })}
            placeholder="0"
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="buyFeeMax" className="block text-sm font-medium mb-1">Maximum (Ft)</label>
          <input
            id="buyFeeMax"
            type="number"
            value={formData.buyFeeMax}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, buyFeeMax: e.target.value })}
            placeholder="Nincs limit"
            className="w-full p-2 border rounded"
          />
        </div>
      </div>

      <hr className="my-4" />
      <h3 className="font-semibold">Eladási díjak</h3>
      <div className="grid grid-cols-4 gap-4">
        <div>
          <label htmlFor="sellFeeType" className="block text-sm font-medium mb-1">Típus</label>
          <select
            id="sellFeeType"
            value={formData.sellFeeType}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, sellFeeType: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="FIXED">Fix összeg</option>
            <option value="PERCENT">Százalék</option>
          </select>
        </div>
        <div>
          <label htmlFor="sellFeeValue" className="block text-sm font-medium mb-1">
            Érték {formData.sellFeeType === 'PERCENT' ? '(%)' : '(Ft)'}
          </label>
          <input
            id="sellFeeValue"
            type="number"
            step="0.01"
            value={formData.sellFeeValue}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, sellFeeValue: e.target.value })}
            placeholder="0"
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="sellFeeMin" className="block text-sm font-medium mb-1">Minimum (Ft)</label>
          <input
            id="sellFeeMin"
            type="number"
            value={formData.sellFeeMin}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, sellFeeMin: e.target.value })}
            placeholder="0"
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="sellFeeMax" className="block text-sm font-medium mb-1">Maximum (Ft)</label>
          <input
            id="sellFeeMax"
            type="number"
            value={formData.sellFeeMax}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, sellFeeMax: e.target.value })}
            placeholder="Nincs limit"
            className="w-full p-2 border rounded"
          />
        </div>
      </div>

      <hr className="my-4" />
      <h3 className="font-semibold">Egyéb díjak</h3>
      <div className="grid grid-cols-3 gap-4">
        <div>
          <label htmlFor="handlingFee" className="block text-sm font-medium mb-1">Kezelési díj (Ft)</label>
          <input
            id="handlingFee"
            type="number"
            value={formData.handlingFee}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, handlingFee: e.target.value })}
            placeholder="0"
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="expressFee" className="block text-sm font-medium mb-1">Expressz díj (Ft)</label>
          <input
            id="expressFee"
            type="number"
            value={formData.expressFee}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, expressFee: e.target.value })}
            placeholder="0"
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="offHoursSurcharge" className="block text-sm font-medium mb-1">Munkaidőn kívüli pótdíj (Ft)</label>
          <input
            id="offHoursSurcharge"
            type="number"
            value={formData.offHoursSurcharge}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, offHoursSurcharge: e.target.value })}
            placeholder="0"
            className="w-full p-2 border rounded"
          />
        </div>
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
          {feePackage ? 'Mentés' : 'Létrehozás'}
        </button>
      </div>
    </form>
  );
}
