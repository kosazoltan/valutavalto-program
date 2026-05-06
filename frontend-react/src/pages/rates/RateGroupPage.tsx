import React, { useState, useEffect } from 'react';
import { api } from '@/services/api/index';
import { logger } from '../../utils/logger';
import { useTranslation } from 'react-i18next'

interface RateGroup {
  id: number;
  code: string;
  name: string;
  description?: string;
  discountType: string;
  buyDiscount: number;
  sellDiscount: number;
  minTransactionAmount?: number;
  maxTransactionAmount?: number;
  isActive: boolean;
  priority: number;
  customerCount: number;
  createdAt: string;
}

interface DiscountTier {
  id: number;
  name: string;
  rateGroupId?: number;
  currencyId?: number;
  currencyCode?: string;
  minAmount: number;
  maxAmount?: number;
  buyDiscountPoints: number;
  sellDiscountPoints: number;
  isActive: boolean;
}

const discountTypeLabels: Record<string, string> = {
  POINT: 'Pont',
  PERCENT: 'Százalék',
  FIXED: 'Fix összeg',
};

export default function RateGroupPage() {
  const { t } = useTranslation()
  const [rateGroups, setRateGroups] = useState<RateGroup[]>([]);
  const [discountTiers, setDiscountTiers] = useState<DiscountTier[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('groups');
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateGroupDialog, setShowCreateGroupDialog] = useState(false);
  const [editingGroup, setEditingGroup] = useState<RateGroup | null>(null);

  useEffect(() => {
    if (activeTab === 'groups') {
      loadRateGroups();
    } else {
      loadDiscountTiers();
    }
  }, [activeTab]);

  const loadRateGroups = async () => {
    setLoading(true);
    try {
      const response = await api.get('/rate-groups');
      setRateGroups(response?.data || []);
    } catch (error) {
      logger.error('RateGroupPage', 'Failed to load rate groups:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadDiscountTiers = async () => {
    setLoading(true);
    try {
      const response = await api.get('/rate-groups/discount-tiers');
      setDiscountTiers(response?.data || []);
    } catch (error) {
      logger.error('RateGroupPage', 'Failed to load discount tiers:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteGroup = async (id: number) => {
    if (window.confirm('Biztosan törli az árfolyamcsoportot?')) {
      try {
        await api.delete(`/rate-groups/${id}`);
        loadRateGroups();
      } catch (error) {
        logger.error('RateGroupPage', 'Failed to delete rate group:', error);
      }
    }
  };

  const handleDeleteTier = async (id: number) => {
    if (window.confirm('Biztosan törli a kedvezményszintet?')) {
      try {
        await api.delete(`/rate-groups/discount-tiers/${id}`);
        loadDiscountTiers();
      } catch (error) {
        logger.error('RateGroupPage', 'Failed to delete discount tier:', error);
      }
    }
  };

  const handleSaveGroup = async (formData: {
    code: string;
    name: string;
    description: string;
    discountType: string;
    buyDiscount: string;
    sellDiscount: string;
    priority: string;
    isActive: boolean;
  }) => {
    try {
      const payload = {
        ...formData,
        buyDiscount: parseFloat(formData.buyDiscount),
        sellDiscount: parseFloat(formData.sellDiscount),
        priority: parseInt(formData.priority),
      };

      if (editingGroup) {
        await api.put(`/rate-groups/${editingGroup.id}`, payload);
      } else {
        await api.post('/rate-groups', payload);
      }
      setShowCreateGroupDialog(false);
      setEditingGroup(null);
      loadRateGroups();
    } catch (error) {
      logger.error('RateGroupPage', 'Failed to save rate group:', error);
    }
  };

  const filteredGroups = rateGroups.filter(g =>
    g.code?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    g.name?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredTiers = discountTiers.filter(t =>
    t.name?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3">
        <div>
          <h1 className="text-lg font-bold">{t('rates.arfolyamcsoportok')}</h1>
          <p className="text-gray-500">{t('rates.ugyfelcsoportokKedvezmenyesArfolyamai')}</p>
        </div>
        <button
          type="button"
          onClick={() => {
            setEditingGroup(null);
            setShowCreateGroupDialog(true);
          }}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          {t('rates.ujCsoport')}
        </button>
      </div>

      <div className="mb-3">
        <input
          type="text"
          placeholder="Keresés..."
          value={searchTerm}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => setSearchTerm(e.target.value)}
          className="w-full p-2 border rounded"
        />
      </div>

      <div className="mb-4 flex gap-2">
        <button
          type="button"
          onClick={() => setActiveTab('groups')}
          className={`px-4 py-2 rounded ${activeTab === 'groups' ? 'bg-blue-600 text-white' : 'bg-gray-100 hover:bg-gray-200'}`}
        >
          {t('rates.csoportok')}
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('tiers')}
          className={`px-4 py-2 rounded ${activeTab === 'tiers' ? 'bg-blue-600 text-white' : 'bg-gray-100 hover:bg-gray-200'}`}
        >
          {t('rates.kedvezmenyszintek')}
        </button>
      </div>

      {activeTab === 'groups' ? (
        <div className="bg-white rounded border">
          {loading ? (
            <div className="text-center py-8">Betöltés...</div>
          ) : filteredGroups.length === 0 ? (
            <div className="text-center py-8 text-gray-500">{t('rates.nincsenekArfolyamcsoportok')}</div>
          ) : (
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="p-3 text-left">{t('common.code')}</th>
                  <th className="p-3 text-left">{t('common.name')}</th>
                  <th className="p-3 text-left">{t('rates.kedvTipus')}</th>
                  <th className="p-3 text-left">{t('cashier.buy')}</th>
                  <th className="p-3 text-left">{t('cashier.sell')}</th>
                  <th className="p-3 text-left">{t('rates.prioritas')}</th>
                  <th className="p-3 text-left">{t('archiving.ugyfelek')}</th>
                  <th className="p-3 text-left">{t('common.status')}</th>
                  <th className="p-3 text-left">{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filteredGroups.map((group) => (
                  <tr key={group.id} className="border-t hover:bg-gray-50">
                    <td className="p-3 font-mono">{group.code}</td>
                    <td className="p-3">{group.name}</td>
                    <td className="p-3">{discountTypeLabels[group.discountType] || group.discountType}</td>
                    <td className="p-3">
                      {group.discountType === 'PERCENT' ? `${group.buyDiscount}%` : group.buyDiscount}
                    </td>
                    <td className="p-3">
                      {group.discountType === 'PERCENT' ? `${group.sellDiscount}%` : group.sellDiscount}
                    </td>
                    <td className="p-3">{group.priority}</td>
                    <td className="p-3">{group.customerCount || 0}</td>
                    <td className="p-3">
                      <span className={`px-2 py-1 text-xs text-white rounded ${group.isActive ? 'bg-green-500' : 'bg-gray-500'}`}>
                        {group.isActive ? 'Aktív' : 'Inaktív'}
                      </span>
                    </td>
                    <td className="p-3">
                      <div className="flex gap-2">
                        <button
                          type="button"
                          onClick={() => {
                            setEditingGroup(group);
                            setShowCreateGroupDialog(true);
                          }}
                          className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                        >
                          {t('common.edit')}
                        </button>
                        <button
                          type="button"
                          onClick={() => handleDeleteGroup(group.id)}
                          className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700"
                        >
                          {t('common.delete')}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      ) : (
        <div className="bg-white rounded border">
          {loading ? (
            <div className="text-center py-8">Betöltés...</div>
          ) : filteredTiers.length === 0 ? (
            <div className="text-center py-8 text-gray-500">{t('rates.nincsenekKedvezmenyszintek')}</div>
          ) : (
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="p-3 text-left">{t('common.name')}</th>
                  <th className="p-3 text-left">{t('common.currency')}</th>
                  <th className="p-3 text-left">{t('rates.minOsszeg')}</th>
                  <th className="p-3 text-left">{t('rates.maxOsszeg')}</th>
                  <th className="p-3 text-left">{t('rates.vetelKedv')}</th>
                  <th className="p-3 text-left">{t('rates.eladasKedv')}</th>
                  <th className="p-3 text-left">{t('common.status')}</th>
                  <th className="p-3 text-left">{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filteredTiers.map((tier) => (
                  <tr key={tier.id} className="border-t hover:bg-gray-50">
                    <td className="p-3">{tier.name}</td>
                    <td className="p-3">{tier.currencyCode || 'Összes'}</td>
                    <td className="p-3">{tier.minAmount?.toLocaleString()}</td>
                    <td className="p-3">{tier.maxAmount?.toLocaleString() || '∞'}</td>
                    <td className="p-3">{tier.buyDiscountPoints} {t('rates.pt')}</td>
                    <td className="p-3">{tier.sellDiscountPoints} {t('rates.pt')}</td>
                    <td className="p-3">
                      <span className={`px-2 py-1 text-xs text-white rounded ${tier.isActive ? 'bg-green-500' : 'bg-gray-500'}`}>
                        {tier.isActive ? 'Aktív' : 'Inaktív'}
                      </span>
                    </td>
                    <td className="p-3">
                      <button
                        type="button"
                        onClick={() => handleDeleteTier(tier.id)}
                        className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700"
                      >
                        {t('common.delete')}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {showCreateGroupDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-4 max-w-2xl w-full">
            <h2 className="text-xl font-bold mb-4">
              {editingGroup ? 'Árfolyamcsoport szerkesztése' : 'Új árfolyamcsoport'}
            </h2>
            <RateGroupForm
              group={editingGroup}
              onSubmit={handleSaveGroup}
              onCancel={() => {
                setShowCreateGroupDialog(false);
                setEditingGroup(null);
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
}

function RateGroupForm({
  group,
  onSubmit,
  onCancel,
}: {
  group: RateGroup | null;
  onSubmit: (data: {
    code: string;
    name: string;
    description: string;
    discountType: string;
    buyDiscount: string;
    sellDiscount: string;
    priority: string;
    isActive: boolean;
  }) => void;
  onCancel: () => void;
}) {
  const { t } = useTranslation()
  const [formData, setFormData] = useState({
    code: group?.code || '',
    name: group?.name || '',
    description: group?.description || '',
    discountType: group?.discountType || 'POINT',
    buyDiscount: group?.buyDiscount?.toString() || '0',
    sellDiscount: group?.sellDiscount?.toString() || '0',
    priority: group?.priority?.toString() || '0',
    isActive: group?.isActive ?? true,
  });

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="code" className="block text-sm font-medium mb-1">{t('common.codeRequired')}</label>
          <input
            id="code"
            type="text"
            value={formData.code}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, code: e.target.value })}
            placeholder="pl. VIP, GOLD"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label htmlFor="name" className="block text-sm font-medium mb-1">{t('common.nameRequired')}</label>
          <input
            id="name"
            type="text"
            value={formData.name}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, name: e.target.value })}
            placeholder="pl. VIP ügyfelek"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div className="col-span-2">
          <label htmlFor="description" className="block text-sm font-medium mb-1">{t('common.description')}</label>
          <input
            id="description"
            type="text"
            value={formData.description}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, description: e.target.value })}
            placeholder="Csoport leírása"
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="discountType" className="block text-sm font-medium mb-1">{t('rates.kedvezmenyTipusa')}</label>
          <select
            id="discountType"
            value={formData.discountType}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, discountType: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="POINT">{t('rates.pontArfolyampont')}</option>
            <option value="PERCENT">{t('fees.szazalek')}</option>
            <option value="FIXED">{t('rates.fixOsszegFt')}</option>
          </select>
        </div>
        <div>
          <label htmlFor="priority" className="block text-sm font-medium mb-1">{t('rates.prioritas')}</label>
          <input
            id="priority"
            type="number"
            value={formData.priority}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, priority: e.target.value })}
            placeholder="0"
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="buyDiscount" className="block text-sm font-medium mb-1">{t('rates.vetelKedvezmeny')}</label>
          <input
            id="buyDiscount"
            type="number"
            step="0.01"
            value={formData.buyDiscount}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, buyDiscount: e.target.value })}
            placeholder="0"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label htmlFor="sellDiscount" className="block text-sm font-medium mb-1">{t('rates.eladasKedvezmeny')}</label>
          <input
            id="sellDiscount"
            type="number"
            step="0.01"
            value={formData.sellDiscount}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, sellDiscount: e.target.value })}
            placeholder="0"
            className="w-full p-2 border rounded"
            required
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
          <label htmlFor="isActive" className="text-sm font-medium">{t('common.active')}</label>
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
          {group ? 'Mentés' : 'Létrehozás'}
        </button>
      </div>
    </form>
  );
}
