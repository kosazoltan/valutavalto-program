import React, { useState, useEffect, useCallback } from 'react';
import { api } from '@/services/api/index';
import { customerApi, type Customer } from '@/services/api/transactions';
import { safeArray } from '@/utils/safeArray';
import { useTranslation } from 'react-i18next'

// A backend ReservationDto részleges leképezése (a UI által használt mezők) —
// backend/.../dto/reservation/ReservationDto.java.
interface Reservation {
  id: number;
  customerId: number | null;
  customerName: string | null;
  branchId: string;
  branchName: string | null;
  currencyCode: string;
  reservedAmount: number;
  exchangeRate: number;
  depositAmount: number;
  status: string;
  expiresAt: string;
  createdAt: string;
  fulfilledAt: string | null;
  cancelledAt: string | null;
  receiptNumber: string | null;
  cancellationReason: string | null;
  refundAmount: number | null;
  notes: string | null;
  expired: boolean;
}

// Backend ReservationStatus enum értékei.
const statusColors: Record<string, string> = {
  ACTIVE: 'bg-blue-500',
  FULFILLED: 'bg-green-500',
  CANCELLED_BY_CUSTOMER: 'bg-red-500',
  CANCELLED_BY_COMPANY: 'bg-orange-500',
  EXPIRED: 'bg-gray-500',
};

const statusLabels: Record<string, string> = {
  ACTIVE: 'Aktív',
  FULFILLED: 'Teljesítve',
  CANCELLED_BY_CUSTOMER: 'Ügyfél lemondta',
  CANCELLED_BY_COMPANY: 'EBC lemondta',
  EXPIRED: 'Lejárt',
};

const EXPIRING_SOON_HOURS = 4;

export default function ReservationPage() {
  const { t } = useTranslation()
  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'active' | 'expiring' | 'expired'>('active');
  const [searchTerm, setSearchTerm] = useState('');
  const [showCreateDialog, setShowCreateDialog] = useState(false);

  const loadReservations = useCallback(async () => {
    setLoading(true);
    try {
      const branchId = localStorage.getItem('branchId') || '';
      let data: Reservation[] = [];
      if (activeTab === 'expired') {
        const response = await api.get('/reservations/expired');
        data = response?.data || [];
      } else {
        // A backend UUID branchId-t vár; üres érték → 400. Ilyenkor üres lista (nincs hívás).
        if (!branchId) {
          setReservations([]);
          return;
        }
        // active + expiring egyaránt az aktív listából (a backend nem ad külön végpontot)
        const response = await api.get('/reservations/active', { params: { branchId } });
        data = response?.data || [];
        if (activeTab === 'expiring') {
          const limit = Date.now() + EXPIRING_SOON_HOURS * 3600 * 1000;
          data = safeArray<Reservation>(data).filter(
            (r) => new Date(r.expiresAt).getTime() <= limit
          );
        }
      }
      setReservations(data);
    } catch {
      setReservations([]);
    } finally {
      setLoading(false);
    }
  }, [activeTab]);

  useEffect(() => {
    void loadReservations();
  }, [loadReservations]);

  const handleFulfill = useCallback(async (id: number) => {
    try {
      await api.post(`/reservations/${id}/fulfill`);
      void loadReservations();
    } catch {
      // A lista látható marad; a hiba-visszajelzést a backend toast adja.
    }
  }, [loadReservations]);

  const handleCancelByCustomer = useCallback(async (id: number) => {
    const reason = prompt('Lemondás oka (ügyfél miatt — a letét nem jár vissza):');
    if (reason === null || !reason.trim()) return;
    try {
      await api.post(`/reservations/${id}/cancel-by-customer`, { reason: reason.trim() });
      void loadReservations();
    } catch {
      // noop
    }
  }, [loadReservations]);

  const handleCancelByCompany = useCallback(async (id: number) => {
    const reason = prompt('Lemondás oka (EBC miatt — dupla letét-visszafizetés, supervisor jóváhagyás):');
    if (reason === null || !reason.trim()) return;
    const supervisorWorkerId = Number(localStorage.getItem('workerId')) || undefined;
    if (!supervisorWorkerId) {
      // A backend kötelezővé teszi a supervisorWorkerId-t az EBC-stornóhoz.
      alert('Hiányzó supervisor azonosító — jelentkezzen be újra a jóváhagyáshoz.');
      return;
    }
    try {
      await api.post(`/reservations/${id}/cancel-by-company`, { reason: reason.trim(), supervisorWorkerId });
      void loadReservations();
    } catch {
      // noop
    }
  }, [loadReservations]);

  // G14: Foglaló-bizonylat (átvétel / visszafizetés) PDF letöltése.
  const handleDownloadReceipt = useCallback(async (id: number, refund: boolean) => {
    try {
      const response = await api.get(`/reservations/${id}/receipt`, {
        params: { refund },
        responseType: 'blob',
      });
      const url = URL.createObjectURL(response.data as Blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `foglalo-${refund ? 'visszafizetes' : 'atvetel'}-${id}.pdf`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    } catch {
      // A hiba-visszajelzést a backend toast adja.
    }
  }, []);

  const filteredReservations = safeArray<Reservation>(reservations).filter((r) => {
    const term = searchTerm.toLowerCase();
    return (
      (r.receiptNumber || '').toLowerCase().includes(term) ||
      (r.customerName || '').toLowerCase().includes(term) ||
      String(r.id).includes(term)
    );
  });

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-3">
        <h1 className="text-lg font-bold">{t('reservations.foglalokKezelese')}</h1>
        <button
          onClick={() => setShowCreateDialog(true)}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          {t('reservations.ujFoglalo')}
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
          { key: 'active' as const, label: 'Aktív foglalók' },
          { key: 'expiring' as const, label: `Hamarosan lejáró (${EXPIRING_SOON_HOURS}h)` },
          { key: 'expired' as const, label: 'Lejárt foglalók' },
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
            {t('reservations.nincsenekFoglalokEbbenAKategoriaban')}
          </div>
        ) : (
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-3 text-left">{t('reservations.foglaloSzam')}</th>
                <th className="p-3 text-left">{t('common.customer')}</th>
                <th className="p-3 text-left">{t('common.amount')}</th>
                <th className="p-3 text-left">{t('cashier.exchangeRate')}</th>
                <th className="p-3 text-left">{t('reservations.letet')}</th>
                <th className="p-3 text-left">{t('components.lejarat')}</th>
                <th className="p-3 text-left">{t('common.status')}</th>
                <th className="p-3 text-left">{t('common.actions')}</th>
              </tr>
            </thead>
            <tbody>
              {filteredReservations.map((reservation) => (
                <tr key={reservation.id} className="border-t hover:bg-gray-50">
                  <td className="p-3 font-mono">{reservation.receiptNumber || `#${reservation.id}`}</td>
                  <td className="p-3">{reservation.customerName || '-'}</td>
                  <td className="p-3">
                    {reservation.reservedAmount?.toLocaleString('hu-HU')} {reservation.currencyCode}
                  </td>
                  <td className="p-3">{reservation.exchangeRate?.toFixed(4)}</td>
                  <td className="p-3">{reservation.depositAmount?.toLocaleString('hu-HU')} {t('components.ft')}</td>
                  <td className="p-3">
                    {reservation.expiresAt ? new Date(reservation.expiresAt).toLocaleString('hu-HU') : '-'}
                  </td>
                  <td className="p-3">
                    <span className={`px-2 py-1 text-xs text-white rounded ${statusColors[reservation.status] || 'bg-gray-400'}`}>
                      {statusLabels[reservation.status] || reservation.status}
                    </span>
                  </td>
                  <td className="p-3">
                    <div className="flex gap-2 flex-wrap">
                      {reservation.status === 'ACTIVE' && (
                        <>
                          <button
                            onClick={() => handleFulfill(reservation.id)}
                            className="px-2 py-1 text-xs bg-green-600 text-white rounded hover:bg-green-700"
                          >
                            {t('reservations.teljesit')}
                          </button>
                          <button
                            onClick={() => handleCancelByCustomer(reservation.id)}
                            className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700"
                          >
                            {t('reservations.ugyfelLemondas')}
                          </button>
                          <button
                            onClick={() => handleCancelByCompany(reservation.id)}
                            className="px-2 py-1 text-xs bg-orange-600 text-white rounded hover:bg-orange-700"
                          >
                            {t('reservations.ebcLemondas')}
                          </button>
                          <button
                            onClick={() => handleDownloadReceipt(reservation.id, false)}
                            className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                          >
                            {t('reservations.bizonylat')}
                          </button>
                        </>
                      )}
                      {(reservation.status === 'CANCELLED_BY_CUSTOMER'
                        || reservation.status === 'CANCELLED_BY_COMPANY'
                        || reservation.status === 'EXPIRED') && (
                        <button
                          onClick={() => handleDownloadReceipt(reservation.id, true)}
                          className="px-2 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700"
                        >
                          {t('reservations.visszafizetesBizonylat')}
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
          <div className="bg-white rounded-lg p-4 max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <h2 className="text-xl font-bold mb-4">{t('reservations.ujFoglaloLetrehozasa')}</h2>
            <CreateReservationForm
              onSuccess={() => {
                setShowCreateDialog(false);
                void loadReservations();
              }}
              onCancel={() => setShowCreateDialog(false)}
            />
          </div>
        </div>
      )}
    </div>
  );
}

interface CurrencyOption {
  code?: string;
  currencyCode?: string;
  name?: string;
}

function CreateReservationForm({
  onSuccess,
  onCancel,
}: {
  onSuccess: () => void;
  onCancel: () => void;
}) {
  const { t } = useTranslation()
  const [customerSearch, setCustomerSearch] = useState('');
  const [customerResults, setCustomerResults] = useState<Customer[]>([]);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [currencies, setCurrencies] = useState<CurrencyOption[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    currencyCode: '',
    amount: '',
    exchangeRate: '',
    validityHours: '24',
    notes: '',
  });

  useEffect(() => {
    void (async () => {
      try {
        const response = await api.get('/currencies');
        setCurrencies(safeArray<CurrencyOption>(response?.data));
      } catch {
        setCurrencies([]);
      }
    })();
  }, []);

  useEffect(() => {
    if (!customerSearch.trim()) {
      setCustomerResults([]);
      return;
    }
    const timer = setTimeout(() => {
      void (async () => {
        try {
          const results = await customerApi.search(customerSearch.trim());
          setCustomerResults(safeArray<Customer>(results));
        } catch {
          setCustomerResults([]);
        }
      })();
    }, 400);
    return () => clearTimeout(timer);
  }, [customerSearch]);

  const toLocalDateTime = (hoursAhead: number): string => {
    const d = new Date(Date.now() + hoursAhead * 3600 * 1000);
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:00`;
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    if (!selectedCustomer) {
      setError('Válasszon ügyfelet a keresőből!');
      return;
    }
    setSubmitting(true);
    try {
      await api.post('/reservations', {
        customerId: selectedCustomer.id,
        currencyCode: formData.currencyCode,
        amount: parseFloat(formData.amount),
        exchangeRate: parseFloat(formData.exchangeRate),
        expiresAt: toLocalDateTime(parseInt(formData.validityHours, 10)),
        notes: formData.notes || undefined,
      });
      onSuccess();
    } catch {
      setError('A foglaló létrehozása sikertelen. Ellenőrizze az adatokat.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && <div className="p-2 bg-red-100 text-red-700 rounded text-sm">{error}</div>}

      <div>
        <label className="block text-sm font-medium mb-1">{t('pep.ugyfelNeve')}</label>
        {selectedCustomer ? (
          <div className="flex items-center justify-between p-2 border rounded bg-green-50">
            <span>{selectedCustomer.name} {selectedCustomer.customerCode ? `(${selectedCustomer.customerCode})` : ''}</span>
            <button type="button" onClick={() => setSelectedCustomer(null)} className="text-xs text-red-600">
              {t('common.cancel')}
            </button>
          </div>
        ) : (
          <>
            <input
              type="text"
              value={customerSearch}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setCustomerSearch(e.target.value)}
              placeholder="Ügyfél keresése név alapján..."
              className="w-full p-2 border rounded"
            />
            {customerResults.length > 0 && (
              <ul className="border rounded mt-1 max-h-40 overflow-y-auto">
                {customerResults.map((c) => (
                  <li key={c.id}>
                    <button
                      type="button"
                      onClick={() => { setSelectedCustomer(c); setCustomerResults([]); setCustomerSearch(''); }}
                      className="w-full text-left p-2 hover:bg-gray-100"
                    >
                      {c.name} {c.customerCode ? `(${c.customerCode})` : ''}
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </>
        )}
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium mb-1">{t('common.currency')}</label>
          <select
            value={formData.currencyCode}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              setFormData({ ...formData, currencyCode: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          >
            <option value="">—</option>
            {currencies.map((c) => {
              const code = c.code || c.currencyCode || '';
              return code ? <option key={code} value={code}>{code}{c.name ? ` – ${c.name}` : ''}</option> : null;
            })}
          </select>
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">{t('cashier.amount')}</label>
          <input
            type="number"
            step="0.01"
            value={formData.amount}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, amount: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">{t('reservations.garantaltArfolyam')}</label>
          <input
            type="number"
            step="0.0001"
            value={formData.exchangeRate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
              setFormData({ ...formData, exchangeRate: e.target.value })
            }
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label className="block text-sm font-medium mb-1">{t('reservations.ervenyessegOra')}</label>
          <select
            value={formData.validityHours}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              setFormData({ ...formData, validityHours: e.target.value })
            }
            className="w-full p-2 border rounded"
          >
            <option value="4">{t('reservations.4Ora')}</option>
            <option value="8">{t('reservations.8Ora')}</option>
            <option value="24">{t('reservations.24Ora')}</option>
            <option value="48">{t('reservations.48Ora')}</option>
          </select>
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium mb-1">{t('reservations.megjegyzes')}</label>
        <input
          type="text"
          value={formData.notes}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            setFormData({ ...formData, notes: e.target.value })
          }
          className="w-full p-2 border rounded"
        />
      </div>

      <div className="flex justify-end gap-2">
        <button type="button" onClick={onCancel} className="px-4 py-2 border rounded hover:bg-gray-50">
          {t('common.cancel')}
        </button>
        <button
          type="submit"
          disabled={submitting}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
        >
          {t('common.create')}
        </button>
      </div>
    </form>
  );
}
