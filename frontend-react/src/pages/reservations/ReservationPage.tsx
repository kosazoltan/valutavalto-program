import React, { useState, useEffect } from 'react';
import { api } from '@/services/api';

interface Reservation {
  id: number;
  reservationNumber: string;
  customerName: string;
  transactionType: string;
  sourceCurrencyCode: string;
  targetCurrencyCode: string;
  sourceAmount: number;
  targetAmount: number;
  guaranteedRate: number;
  depositAmount: number;
  status: string;
  expiryDate: string;
  createdAt: string;
}

const statusColors: Record<string, string> = {
  PENDING: 'bg-yellow-500',
  CONFIRMED: 'bg-blue-500',
  FULFILLED: 'bg-green-500',
  CANCELLED: 'bg-red-500',
  EXPIRED: 'bg-gray-500',
  REFUNDED: 'bg-purple-500',
};

const statusLabels: Record<string, string> = {
  PENDING: 'Függőben',
  CONFIRMED: 'Megerősítve',
  FULFILLED: 'Teljesítve',
  CANCELLED: 'Lemondva',
  EXPIRED: 'Lejárt',
  REFUNDED: 'Visszafizetve',
};

export default function ReservationPage() {
  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('active');
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateDialog, setShowCreateDialog] = useState(false);

  useEffect(() => {
    loadReservations();
  }, [activeTab]);

  const loadReservations = async () => {
    setLoading(true);
    try {
      const branchId = localStorage.getItem('branchId') || '';
      let response;
      if (activeTab === 'active') {
        response = await api.get(`/reservations/branch/${branchId}/active`);
      } else if (activeTab === 'today') {
        response = await api.get(`/reservations/branch/${branchId}/today`);
      } else if (activeTab === 'expiring') {
        response = await api.get(`/reservations/branch/${branchId}/expiring?hoursAhead=4`);
      }
      setReservations(response?.data || []);
    } catch (error) {
      console.error('Failed to load reservations:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleConfirm = async (id: number) => {
    try {
      await api.post(`/reservations/${id}/confirm`);
      loadReservations();
    } catch (error) {
      console.error('Failed to confirm reservation:', error);
    }
  };

  const handleCancel = async (id: number) => {
    const reason = prompt('Lemondás oka:');
    if (reason) {
      try {
        await api.post(`/reservations/${id}/cancel?reason=${encodeURIComponent(reason)}`);
        loadReservations();
      } catch (error) {
        console.error('Failed to cancel reservation:', error);
      }
    }
  };

  const handleFulfill = async (id: number) => {
    try {
      await api.post(`/reservations/${id}/fulfill`);
      loadReservations();
    } catch (error) {
      console.error('Failed to fulfill reservation:', error);
    }
  };

  const filteredReservations = reservations.filter(r =>
    r.reservationNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.customerName?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="container mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Foglalók kezelése</h1>
        <button
          onClick={() => setShowCreateDialog(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          + Új foglaló
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
          { key: 'active', label: 'Aktív foglalók' },
          { key: 'today', label: 'Mai foglalók' },
          { key: 'expiring', label: 'Hamarosan lejáró' },
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
        ) : filteredReservations.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            Nincsenek foglalók ebben a kategóriában
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-3 text-left">Foglaló szám</th>
                <th className="p-3 text-left">Ügyfél</th>
                <th className="p-3 text-left">Típus</th>
                <th className="p-3 text-left">Összeg</th>
                <th className="p-3 text-left">Árfolyam</th>
                <th className="p-3 text-left">Letét</th>
                <th className="p-3 text-left">Lejárat</th>
                <th className="p-3 text-left">Státusz</th>
                <th className="p-3 text-left">Műveletek</th>
              </tr>
            </thead>
            <tbody>
              {filteredReservations.map((reservation) => (
                <tr key={reservation.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-mono">{reservation.reservationNumber}</td>
                  <td className="p-3">{reservation.customerName || '-'}</td>
                  <td className="p-3">{reservation.transactionType === 'BUY' ? 'Vétel' : 'Eladás'}</td>
                  <td className="p-3">
                    {reservation.sourceAmount} {reservation.sourceCurrencyCode} →{' '}
                    {reservation.targetAmount} {reservation.targetCurrencyCode}
                  </td>
                  <td className="p-3">{reservation.guaranteedRate?.toFixed(4)}</td>
                  <td className="p-3">{reservation.depositAmount?.toLocaleString()} Ft</td>
                  <td className="p-3">
                    {new Date(reservation.expiryDate).toLocaleString('hu-HU')}
                  </td>
                  <td className="p-3">
                    <span className={`px-2 py-1 text-xs text-white rounded ${statusColors[reservation.status]}`}>
                      {statusLabels[reservation.status] || reservation.status}
                    </span>
                  </td>
                  <td className="p-3">
                    <div className="flex gap-2">
                      {reservation.status === 'PENDING' && (
                        <>
                          <button
                            onClick={() => handleConfirm(reservation.id)}
                            className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                          >
                            Megerősít
                          </button>
                          <button
                            onClick={() => handleCancel(reservation.id)}
                            className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700"
                          >
                            Lemond
                          </button>
                        </>
                      )}
                      {reservation.status === 'CONFIRMED' && (
                        <button
                          onClick={() => handleFulfill(reservation.id)}
                          className="px-2 py-1 text-xs border rounded hover:bg-gray-50"
                        >
                          Teljesít
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
          <div className="bg-white rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">Új foglaló létrehozása</h2>
            <CreateReservationForm
              onSuccess={() => {
                setShowCreateDialog(false);
                loadReservations();
              }}
              onCancel={() => setShowCreateDialog(false)}
            />
          </div>
        </div>
      )}
    </div>
  );
}

function CreateReservationForm({
  onSuccess,
  onCancel,
}: {
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const [formData, setFormData] = useState({
    customerName: '',
    transactionType: 'BUY',
    sourceCurrencyId: '',
    targetCurrencyId: '',
    sourceAmount: '',
    guaranteedRate: '',
    depositAmount: '',
    validityHours: '24',
  });

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    try {
      await api.post('/reservations', {
        ...formData,
        sourceAmount: parseFloat(formData.sourceAmount),
        guaranteedRate: parseFloat(formData.guaranteedRate),
        depositAmount: parseFloat(formData.depositAmount),
        validityHours: parseInt(formData.validityHours),
      });
      onSuccess();
    } catch (error) {
      console.error('Failed to create reservation:', error);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium mb-1">Ügyfél neve</label>
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
          <label className="block text-sm font-medium mb-1">Tranzakció típusa</label>
          <select
            value={formData.transactionType}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              setFormData({ ...formData, transactionType: e.target.value })
            }
            className="w-full p-2 border rounded"
          >
            <option value="BUY">Vétel</option>
            <option value="SELL">Eladás</option>
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Összeg</label>
          <input
            type="number"
            step="0.01"
            value={formData.sourceAmount}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, sourceAmount: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Garantált árfolyam</label>
          <input
            type="number"
            step="0.0001"
            value={formData.guaranteedRate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, guaranteedRate: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Letét összege (Ft)</label>
          <input
            type="number"
            value={formData.depositAmount}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, depositAmount: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">Érvényesség (óra)</label>
          <select
            value={formData.validityHours}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              setFormData({ ...formData, validityHours: e.target.value })
            }
            className="w-full p-2 border rounded"
          >
            <option value="4">4 óra</option>
            <option value="8">8 óra</option>
            <option value="24">24 óra</option>
            <option value="48">48 óra</option>
          </select>
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
