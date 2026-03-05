import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useRateStore } from '@/stores/rateStore';
import { useAuthStore } from '@/stores/authStore';
import { getForeignCurrencies, getCurrencyInfo } from '@/utils/currencies';
import {
  createReservation,
  getReservations,
  redeemReservation,
  cancelReservation,
} from '@/api/reservations';
import CustomerSearch from '@/components/CustomerSearch';
import CurrencySelector from '@/components/CurrencySelector';
import type {
  CurrencyCode,
  Customer,
  Reservation,
  ReservationStatus,
} from '@/types';

type TabMode = 'new' | 'list';

export default function ReservationPage() {
  const navigate = useNavigate();
  const { getSellRate, fetchRates, rates } = useRateStore();
  const { companyType } = useAuthStore();

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const currencies = getForeignCurrencies();

  // --- Tab ---
  const [activeTab, setActiveTab] = useState<TabMode>('new');

  // --- Új foglalás ---
  const [selectedCurrency, setSelectedCurrency] = useState<CurrencyCode | null>(null);
  const [amount, setAmount] = useState('');
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [showCustomerSearch, setShowCustomerSearch] = useState(false);
  const [expiresInMinutes, setExpiresInMinutes] = useState(120);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // --- Lista ---
  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [statusFilter, setStatusFilter] = useState<ReservationStatus | ''>('ACTIVE');
  const [isLoading, setIsLoading] = useState(false);
  const [cancelReason, setCancelReason] = useState('');
  const [cancellingId, setCancellingId] = useState<number | null>(null);

  // Árfolyam
  useEffect(() => {
    if (rates.length === 0) {
      void fetchRates();
    }
  }, [rates.length, fetchRates]);

  const sellRate = selectedCurrency ? getSellRate(selectedCurrency) : 0;
  const unit = selectedCurrency ? (getCurrencyInfo(selectedCurrency)?.unit ?? 1) : 1;
  const amountNum = parseFloat(amount) || 0;
  const hufAmount = sellRate > 0 && amountNum > 0 ? (amountNum / unit) * sellRate : 0;

  // Lista betöltés
  const loadReservations = useCallback(async () => {
    setIsLoading(true);
    try {
      const result = await getReservations(
        statusFilter !== '' ? statusFilter : undefined,
      );
      setReservations(result);
    } catch {
      console.error('[ReservationPage] Lista betöltés hiba');
    } finally {
      setIsLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    if (activeTab === 'list') {
      void loadReservations();
    }
  }, [activeTab, loadReservations]);

  // Új foglalás
  const handleCreate = useCallback(async () => {
    if (!selectedCurrency || !customer || amountNum <= 0 || isSubmitting) return;

    setIsSubmitting(true);
    setError('');
    setSuccess('');

    try {
      const result = await createReservation({
        customerId: customer.id,
        currencyCode: selectedCurrency,
        amount: amountNum,
        rate: sellRate,
        hufAmount: Math.round(hufAmount),
        expiresInMinutes,
      });

      setSuccess(
        `✅ Foglalás rögzítve! Bizonylat: ${result.receiptNumber} — ${result.amount} ${selectedCurrency}`,
      );
      setAmount('');
      setCustomer(null);
      setSelectedCurrency(null);
    } catch {
      setError('❌ Foglalás sikertelen. Próbálja újra.');
    } finally {
      setIsSubmitting(false);
    }
  }, [selectedCurrency, customer, amountNum, sellRate, hufAmount, expiresInMinutes, isSubmitting]);

  // Beváltás
  const handleRedeem = useCallback(async (id: number) => {
    try {
      const result = await redeemReservation(id);
      setSuccess(
        `✅ Beváltás sikeres! Tranzakció: ${result.transactionReceiptNumber}`,
      );
      void loadReservations();
    } catch {
      setError('❌ Beváltás sikertelen.');
    }
  }, [loadReservations]);

  // Törlés
  const handleCancel = useCallback(async (id: number) => {
    if (!cancelReason.trim()) {
      setError('Az indoklás megadása kötelező a törléshez.');
      return;
    }
    try {
      await cancelReservation(id, cancelReason);
      setSuccess('✅ Foglalás törölve.');
      setCancellingId(null);
      setCancelReason('');
      void loadReservations();
    } catch {
      setError('❌ Törlés sikertelen.');
    }
  }, [cancelReason, loadReservations]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const canSubmit =
    selectedCurrency !== null && customer !== null && amountNum > 0 && sellRate > 0;

  const formatDate = (dateStr: string) => {
    try {
      return new Date(dateStr).toLocaleString('hu-HU');
    } catch {
      return dateStr;
    }
  };

  const statusLabels: Record<ReservationStatus, string> = {
    ACTIVE: '🟢 Aktív',
    COMPLETED: '✅ Beváltva',
    EXPIRED: '⏰ Lejárt',
    CANCELLED: '❌ Törölve',
  };

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">📋 Foglalás</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      {/* Tab választó */}
      <div className="border-b bg-gray-50 px-6">
        <div className="flex gap-4">
          <button
            onClick={() => setActiveTab('new')}
            className={`border-b-2 px-4 py-3 text-sm font-medium ${
              activeTab === 'new'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            ➕ Új foglalás
          </button>
          <button
            onClick={() => setActiveTab('list')}
            className={`border-b-2 px-4 py-3 text-sm font-medium ${
              activeTab === 'list'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            📋 Foglalások listája
          </button>
        </div>
      </div>

      <main className="flex-1 overflow-auto p-6">
        {/* Visszajelzések */}
        {error && (
          <div className="mx-auto mb-4 max-w-6xl rounded-lg bg-red-50 p-3 text-sm text-red-700">
            {error}
          </div>
        )}
        {success && (
          <div className="mx-auto mb-4 max-w-6xl rounded-lg bg-green-50 p-3 text-sm text-green-700">
            {success}
          </div>
        )}

        {activeTab === 'new' ? (
          /* === ÚJ FOGLALÁS === */
          <div className="mx-auto grid max-w-6xl grid-cols-3 gap-6">
            {/* BAL — Valuta */}
            <div className="col-span-1">
              <h2 className="mb-3 text-lg font-semibold text-gray-700">Valutanem</h2>
              <div className="max-h-[500px] overflow-auto rounded-xl border bg-white p-3">
                <CurrencySelector
                  currencies={currencies}
                  selected={selectedCurrency}
                  onSelect={setSelectedCurrency}
                  rates={rates}
                  rateType="sell"
                />
              </div>
            </div>

            {/* KÖZÉP — Összeg */}
            <div className="col-span-1 space-y-4">
              {selectedCurrency && (
                <div className="rounded-xl border bg-blue-50 p-4">
                  <p className="text-sm text-gray-500">Foglalási árfolyam</p>
                  <p className="text-3xl font-bold text-blue-700">
                    {sellRate.toFixed(2)} Ft
                    {unit > 1 && (
                      <span className="ml-2 text-base text-gray-500">
                        / {unit} {selectedCurrency}
                      </span>
                    )}
                  </p>
                </div>
              )}

              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  {selectedCurrency ?? 'Deviza'} összeg
                </label>
                <input
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="input-field text-right text-2xl font-bold"
                  placeholder="0.00"
                  step="0.01"
                  min="0"
                  disabled={!selectedCurrency}
                />
              </div>

              {hufAmount > 0 && (
                <div className="rounded-xl border bg-green-50 p-4">
                  <div className="flex justify-between text-lg font-bold text-green-700">
                    <span>HUF érték:</span>
                    <span>{Math.round(hufAmount).toLocaleString('hu-HU')} Ft</span>
                  </div>
                </div>
              )}

              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Lejárati idő (perc)
                </label>
                <select
                  value={expiresInMinutes}
                  onChange={(e) => setExpiresInMinutes(parseInt(e.target.value, 10))}
                  className="input-field"
                >
                  <option value={60}>1 óra</option>
                  <option value={120}>2 óra (alapértelmezett)</option>
                  <option value={180}>3 óra</option>
                  <option value={240}>4 óra</option>
                  <option value={480}>8 óra</option>
                  <option value={1440}>24 óra</option>
                </select>
              </div>
            </div>

            {/* JOBB — Ügyfél + Véglegesítés */}
            <div className="col-span-1 space-y-4">
              <div className="rounded-xl border bg-white p-4">
                <div className="flex items-center justify-between">
                  <h3 className="font-semibold text-gray-700">👤 Ügyfél (kötelező)</h3>
                  <button
                    onClick={() => setShowCustomerSearch(true)}
                    className="rounded-lg bg-blue-100 px-3 py-1 text-sm text-blue-700 hover:bg-blue-200"
                  >
                    Keresés
                  </button>
                </div>
                {customer ? (
                  <div className="mt-2 space-y-1 text-sm">
                    <p className="font-medium">{customer.name}</p>
                    <p className="text-gray-500">
                      {customer.documentType}: {customer.documentNumber}
                    </p>
                    <button
                      onClick={() => setCustomer(null)}
                      className="text-xs text-red-500 hover:text-red-700"
                    >
                      ✕ Törlés
                    </button>
                  </div>
                ) : (
                  <p className="mt-2 text-sm text-gray-400">Nincs kiválasztva</p>
                )}
              </div>

              <button
                onClick={handleCreate}
                disabled={!canSubmit || isSubmitting}
                className={`btn-primary w-full text-lg ${
                  isBestChange
                    ? 'bg-red-600 hover:bg-red-700'
                    : 'bg-orange-500 hover:bg-orange-600'
                } disabled:cursor-not-allowed disabled:opacity-50`}
              >
                {isSubmitting
                  ? '⏳ Feldolgozás...'
                  : `📋 Foglalás rögzítése — ${Math.round(hufAmount).toLocaleString('hu-HU')} Ft`}
              </button>
            </div>
          </div>
        ) : (
          /* === FOGLALÁSOK LISTÁJA === */
          <div className="mx-auto max-w-6xl">
            {/* Szűrő */}
            <div className="mb-4 flex items-center gap-4">
              <label className="text-sm font-medium text-gray-700">Státusz:</label>
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value as ReservationStatus | '')}
                className="rounded-lg border px-3 py-2 text-sm"
              >
                <option value="">Összes</option>
                <option value="ACTIVE">Aktív</option>
                <option value="COMPLETED">Beváltva</option>
                <option value="EXPIRED">Lejárt</option>
                <option value="CANCELLED">Törölve</option>
              </select>
              <button
                onClick={loadReservations}
                className="rounded-lg bg-blue-100 px-4 py-2 text-sm text-blue-700 hover:bg-blue-200"
              >
                🔄 Frissítés
              </button>
            </div>

            {/* Táblázat */}
            {isLoading ? (
              <p className="text-center text-gray-500">⏳ Betöltés...</p>
            ) : reservations.length === 0 ? (
              <p className="text-center text-gray-500">Nincs találat.</p>
            ) : (
              <div className="overflow-auto rounded-xl border bg-white">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left">Bizonylat</th>
                      <th className="px-4 py-3 text-left">Ügyfél</th>
                      <th className="px-4 py-3 text-right">Valuta</th>
                      <th className="px-4 py-3 text-right">Összeg</th>
                      <th className="px-4 py-3 text-right">Árfolyam</th>
                      <th className="px-4 py-3 text-center">Lejárat</th>
                      <th className="px-4 py-3 text-center">Státusz</th>
                      <th className="px-4 py-3 text-center">Műveletek</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y">
                    {reservations.map((r) => (
                      <tr key={r.id} className="hover:bg-gray-50">
                        <td className="px-4 py-3 font-mono text-xs">{r.receiptNumber}</td>
                        <td className="px-4 py-3">{r.customerName}</td>
                        <td className="px-4 py-3 text-right font-medium">{r.currencyCode}</td>
                        <td className="px-4 py-3 text-right">
                          {r.amount.toLocaleString('hu-HU')}
                        </td>
                        <td className="px-4 py-3 text-right">{r.rate.toFixed(2)}</td>
                        <td className="px-4 py-3 text-center text-xs">
                          {formatDate(r.expiresAt)}
                        </td>
                        <td className="px-4 py-3 text-center text-xs">
                          {statusLabels[r.status]}
                        </td>
                        <td className="px-4 py-3 text-center">
                          {r.status === 'ACTIVE' && (
                            <div className="flex justify-center gap-2">
                              <button
                                onClick={() => void handleRedeem(r.id)}
                                className="rounded bg-green-100 px-2 py-1 text-xs text-green-700 hover:bg-green-200"
                              >
                                ✅ Beváltás
                              </button>
                              {cancellingId === r.id ? (
                                <div className="flex gap-1">
                                  <input
                                    type="text"
                                    value={cancelReason}
                                    onChange={(e) => setCancelReason(e.target.value)}
                                    placeholder="Indok..."
                                    className="w-24 rounded border px-2 py-1 text-xs"
                                  />
                                  <button
                                    onClick={() => void handleCancel(r.id)}
                                    className="rounded bg-red-100 px-2 py-1 text-xs text-red-700"
                                  >
                                    OK
                                  </button>
                                  <button
                                    onClick={() => setCancellingId(null)}
                                    className="rounded bg-gray-100 px-2 py-1 text-xs"
                                  >
                                    ✕
                                  </button>
                                </div>
                              ) : (
                                <button
                                  onClick={() => setCancellingId(r.id)}
                                  className="rounded bg-red-100 px-2 py-1 text-xs text-red-700 hover:bg-red-200"
                                >
                                  ❌ Törlés
                                </button>
                              )}
                            </div>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </main>

      {/* Ügyfél keresés modal */}
      {showCustomerSearch && (
        <CustomerSearch
          onSelect={(c) => {
            setCustomer(c);
            setShowCustomerSearch(false);
          }}
          onClose={() => setShowCustomerSearch(false)}
        />
      )}
    </div>
  );
}
