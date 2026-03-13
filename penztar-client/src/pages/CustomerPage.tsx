import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import apiClient from '@/api/client';
import DocumentScanner from '@/components/DocumentScanner';
import type { CustomerDetail, CustomerCreateRequest, TransactionListItem, CustomerStats, CustomerRanking } from '@/types';

type TabView = 'search' | 'detail' | 'create' | 'edit' | 'stats' | 'vip';

export default function CustomerPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [tab, setTab] = useState<TabView>('search');
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<CustomerDetail[]>([]);
  const [selectedCustomer, setSelectedCustomer] = useState<CustomerDetail | null>(null);
  const [transactions, setTransactions] = useState<TransactionListItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [showScanner, setShowScanner] = useState(false);
  const [customerStats, setCustomerStats] = useState<CustomerStats | null>(null);
  const [vipList, setVipList] = useState<CustomerRanking[]>([]);
  const [isLoadingStats, setIsLoadingStats] = useState(false);
  const [isLoadingVip, setIsLoadingVip] = useState(false);

  // Form state
  const [formData, setFormData] = useState<CustomerCreateRequest>({
    name: '',
    documentType: 'PERSONAL_ID',
    documentNumber: '',
    nationality: 'HU',
    birthDate: '',
    birthPlace: '',
    address: '',
    motherName: '',
    taxNumber: '',
    idCardNumber: '',
    idCardExpiry: '',
    passportNumber: '',
    passportExpiry: '',
    phone: '',
    email: '',
  });

  const handleSearch = useCallback(async () => {
    if (!searchQuery.trim()) return;
    setIsLoading(true);
    setError('');
    try {
      const response = await apiClient.get<CustomerDetail[]>('/customers/search', {
        params: { query: searchQuery },
      });
      setSearchResults(response.data);
    } catch (err: unknown) {
      console.error('[CustomerPage] Keresés hiba:', err);
      setError('Keresés sikertelen. Próbálja újra.');
    } finally {
      setIsLoading(false);
    }
  }, [searchQuery]);

  const handleSelectCustomer = useCallback(async (customer: CustomerDetail) => {
    setSelectedCustomer(customer);
    setTab('detail');
    // Tranzakció történet betöltése
    try {
      const response = await apiClient.get<TransactionListItem[]>(
        `/customers/${customer.id}/transactions`,
      );
      setTransactions(response.data);
    } catch (err: unknown) {
      console.error('[CustomerPage] Tranzakció történet hiba:', err);
      setTransactions([]);
    }
  }, []);

  const handleCreate = useCallback(async () => {
    if (isSubmitting) return;
    setIsSubmitting(true);
    setError('');
    setSuccess('');
    try {
      const response = await apiClient.post<CustomerDetail>('/customers', formData);
      setSelectedCustomer(response.data);
      setSuccess('✅ Ügyfél sikeresen rögzítve!');
      setTab('detail');
    } catch (err: unknown) {
      console.error('[CustomerPage] Rögzítés hiba:', err);
      setError('Ügyfél rögzítés sikertelen. Próbálja újra.');
    } finally {
      setIsSubmitting(false);
    }
  }, [formData, isSubmitting]);

  const handleUpdate = useCallback(async () => {
    if (!selectedCustomer || isSubmitting) return;
    setIsSubmitting(true);
    setError('');
    setSuccess('');
    try {
      const response = await apiClient.put<CustomerDetail>(
        `/customers/${selectedCustomer.id}`,
        formData,
      );
      setSelectedCustomer(response.data);
      setSuccess('✅ Ügyfél adatok frissítve!');
      setTab('detail');
    } catch (err: unknown) {
      console.error('[CustomerPage] Módosítás hiba:', err);
      setError('Ügyfél módosítás sikertelen. Próbálja újra.');
    } finally {
      setIsSubmitting(false);
    }
  }, [selectedCustomer, formData, isSubmitting]);

  const startEdit = useCallback(() => {
    if (!selectedCustomer) return;
    setFormData({
      name: selectedCustomer.name,
      documentType: selectedCustomer.documentType,
      documentNumber: selectedCustomer.documentNumber,
      nationality: selectedCustomer.nationality,
      birthDate: selectedCustomer.birthDate,
      birthPlace: selectedCustomer.birthPlace,
      address: selectedCustomer.address,
      motherName: selectedCustomer.motherName,
      taxNumber: selectedCustomer.taxNumber ?? '',
      idCardNumber: selectedCustomer.idCardNumber ?? '',
      idCardExpiry: selectedCustomer.idCardExpiry ?? '',
      passportNumber: selectedCustomer.passportNumber ?? '',
      passportExpiry: selectedCustomer.passportExpiry ?? '',
      phone: selectedCustomer.phone ?? '',
      email: selectedCustomer.email ?? '',
    });
    setTab('edit');
  }, [selectedCustomer]);

  const startCreate = useCallback(() => {
    setFormData({
      name: '',
      documentType: 'PERSONAL_ID',
      documentNumber: '',
      nationality: 'HU',
      birthDate: '',
      birthPlace: '',
      address: '',
      motherName: '',
      taxNumber: '',
      idCardNumber: '',
      idCardExpiry: '',
      passportNumber: '',
      passportExpiry: '',
      phone: '',
      email: '',
    });
    setError('');
    setSuccess('');
    setTab('create');
  }, []);

  const loadCustomerStats = useCallback(async (customerId: number) => {
    setIsLoadingStats(true);
    try {
      const response = await apiClient.get<CustomerStats>(`/customers/${customerId}/stats`);
      setCustomerStats(response.data);
      setTab('stats');
    } catch (err: unknown) {
      console.error('[CustomerPage] Statisztika hiba:', err);
      setError('Statisztika betöltés sikertelen.');
    } finally {
      setIsLoadingStats(false);
    }
  }, []);

  const loadVipList = useCallback(async () => {
    setIsLoadingVip(true);
    try {
      const response = await apiClient.get<CustomerRanking[]>('/customers/top', {
        params: { limit: 20 },
      });
      setVipList(response.data);
      setTab('vip');
    } catch (err: unknown) {
      console.error('[CustomerPage] VIP lista hiba:', err);
      setError('VIP lista betöltés sikertelen.');
    } finally {
      setIsLoadingVip(false);
    }
  }, []);

  const updateField = useCallback(<K extends keyof CustomerCreateRequest>(
    field: K,
    value: CustomerCreateRequest[K],
  ) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  }, []);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (tab === 'detail' || tab === 'create' || tab === 'edit' || tab === 'stats' || tab === 'vip') {
          setTab('search');
          setError('');
          setSuccess('');
        } else {
          navigate('/menu');
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate, tab]);

  const documentTypeLabels: Record<string, string> = {
    PERSONAL_ID: 'Személyi igazolvány',
    PASSPORT: 'Útlevél',
    DRIVING_LICENSE: 'Vezetői engedély',
  };

  const renderForm = (mode: 'create' | 'edit') => (
    <div className="mx-auto max-w-2xl space-y-4">
      <div className="rounded-xl border bg-white p-6">
        <h2 className="mb-4 text-lg font-bold text-gray-800">
          {mode === 'create' ? '➕ Új ügyfél rögzítés' : '✏️ Ügyfél módosítás'}
        </h2>
        <div className="grid grid-cols-2 gap-4">
          <div className="col-span-2">
            <label className="mb-1 block text-sm font-medium text-gray-700">Név *</label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => updateField('name', e.target.value)}
              className="input-field"
              placeholder="Teljes név"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Okmány típus *</label>
            <select
              value={formData.documentType}
              onChange={(e) => updateField('documentType', e.target.value as CustomerCreateRequest['documentType'])}
              className="input-field"
            >
              <option value="PERSONAL_ID">Személyi igazolvány</option>
              <option value="PASSPORT">Útlevél</option>
              <option value="DRIVING_LICENSE">Vezetői engedély</option>
            </select>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Okmányszám *</label>
            <input
              type="text"
              value={formData.documentNumber}
              onChange={(e) => updateField('documentNumber', e.target.value)}
              className="input-field"
              placeholder="123456AB"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Állampolgárság</label>
            <input
              type="text"
              value={formData.nationality}
              onChange={(e) => updateField('nationality', e.target.value)}
              className="input-field"
              placeholder="HU"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Születési dátum *</label>
            <input
              type="date"
              value={formData.birthDate}
              onChange={(e) => updateField('birthDate', e.target.value)}
              className="input-field"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Születési hely</label>
            <input
              type="text"
              value={formData.birthPlace}
              onChange={(e) => updateField('birthPlace', e.target.value)}
              className="input-field"
              placeholder="Budapest"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Anyja neve</label>
            <input
              type="text"
              value={formData.motherName}
              onChange={(e) => updateField('motherName', e.target.value)}
              className="input-field"
              placeholder="Anyja neve"
            />
          </div>
          <div className="col-span-2">
            <label className="mb-1 block text-sm font-medium text-gray-700">Lakcím</label>
            <input
              type="text"
              value={formData.address}
              onChange={(e) => updateField('address', e.target.value)}
              className="input-field"
              placeholder="1011 Budapest, Fő utca 1."
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Adószám</label>
            <input
              type="text"
              value={formData.taxNumber ?? ''}
              onChange={(e) => updateField('taxNumber', e.target.value)}
              className="input-field"
              placeholder="12345678-1-11"
            />
          </div>

          {/* Külön okmányszámok */}
          <div className="col-span-2 mt-2 border-t pt-3">
            <h3 className="mb-2 text-sm font-semibold text-gray-600">📄 Okmányok (külön)</h3>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Személyi ig. szám</label>
            <input
              type="text"
              value={formData.idCardNumber ?? ''}
              onChange={(e) => updateField('idCardNumber', e.target.value)}
              className="input-field"
              placeholder="123456AB"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Személyi ig. lejárat</label>
            <input
              type="date"
              value={formData.idCardExpiry ?? ''}
              onChange={(e) => updateField('idCardExpiry', e.target.value)}
              className="input-field"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Útlevél szám</label>
            <input
              type="text"
              value={formData.passportNumber ?? ''}
              onChange={(e) => updateField('passportNumber', e.target.value)}
              className="input-field"
              placeholder="BA1234567"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Útlevél lejárat</label>
            <input
              type="date"
              value={formData.passportExpiry ?? ''}
              onChange={(e) => updateField('passportExpiry', e.target.value)}
              className="input-field"
            />
          </div>

          {/* Kontakt adatok */}
          <div className="col-span-2 mt-2 border-t pt-3">
            <h3 className="mb-2 text-sm font-semibold text-gray-600">📞 Elérhetőségek</h3>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Telefonszám</label>
            <input
              type="tel"
              value={formData.phone ?? ''}
              onChange={(e) => updateField('phone', e.target.value)}
              className="input-field"
              placeholder="+36 30 123 4567"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">E-mail cím</label>
            <input
              type="email"
              value={formData.email ?? ''}
              onChange={(e) => updateField('email', e.target.value)}
              className="input-field"
              placeholder="pelda@gmail.com"
            />
          </div>
        </div>

        {error && (
          <div className="mt-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">⚠️ {error}</div>
        )}
        {success && (
          <div className="mt-4 rounded-lg bg-green-50 p-3 text-sm text-green-700">{success}</div>
        )}

        <div className="mt-6 flex gap-3">
          <button
            onClick={() => void (mode === 'create' ? handleCreate() : handleUpdate())}
            disabled={isSubmitting || !formData.name || !formData.documentNumber}
            className={`btn-primary ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'} disabled:opacity-50`}
          >
            {isSubmitting ? '⏳ Mentés...' : mode === 'create' ? '💾 Rögzítés' : '💾 Mentés'}
          </button>
          <button
            onClick={() => { setTab('search'); setError(''); setSuccess(''); }}
            className="rounded-lg border px-4 py-2 text-gray-700 hover:bg-gray-50"
          >
            Mégsem
          </button>
        </div>
      </div>
    </div>
  );

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">👤 Ügyfél kezelés</h1>
          <button
            onClick={() => tab !== 'search' ? setTab('search') : navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← {tab !== 'search' ? 'Vissza' : 'Vissza (ESC)'}
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        {tab === 'search' && (
          <div className="mx-auto max-w-3xl space-y-4">
            {/* Keresés */}
            <div className="flex gap-3">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyDown={(e) => { if (e.key === 'Enter') void handleSearch(); }}
                className="input-field flex-1"
                placeholder="Keresés: név, okmányszám, adószám..."
                autoFocus
              />
              <button
                onClick={() => void handleSearch()}
                disabled={isLoading}
                className={`btn-primary ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'} disabled:opacity-50`}
              >
                {isLoading ? '⏳' : '🔍 Keresés'}
              </button>
              <button
                onClick={startCreate}
                className="rounded-lg border bg-green-50 px-4 py-2 text-green-700 hover:bg-green-100"
              >
                ➕ Új ügyfél
              </button>
              <button
                onClick={() => void loadVipList()}
                disabled={isLoadingVip}
                className="rounded-lg border bg-purple-50 px-4 py-2 text-purple-700 hover:bg-purple-100"
              >
                {isLoadingVip ? '⏳' : '⭐'} VIP Top
              </button>
            </div>

            {error && (
              <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">⚠️ {error}</div>
            )}

            {/* Találatok */}
            {searchResults.length > 0 ? (
              <div className="space-y-2">
                {searchResults.map((customer) => (
                  <button
                    key={customer.id}
                    onClick={() => void handleSelectCustomer(customer)}
                    className="w-full rounded-xl border bg-white p-4 text-left transition hover:bg-gray-50"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="font-semibold text-gray-800">{customer.name}</h3>
                        <p className="text-sm text-gray-500">
                          {documentTypeLabels[customer.documentType] ?? customer.documentType}: {customer.documentNumber}
                          {customer.taxNumber && ` | Adószám: ${customer.taxNumber}`}
                        </p>
                      </div>
                      <span className="text-gray-400">→</span>
                    </div>
                  </button>
                ))}
              </div>
            ) : searchQuery && !isLoading ? (
              <div className="py-10 text-center text-gray-400">
                <p>Nincs találat a keresésre.</p>
              </div>
            ) : null}
          </div>
        )}

        {tab === 'detail' && selectedCustomer && (
          <div className="mx-auto max-w-3xl space-y-4">
            {/* Ügyfél adatok */}
            <div className="rounded-xl border bg-white p-6">
              <div className="flex items-start justify-between">
                <h2 className="text-xl font-bold text-gray-800">{selectedCustomer.name}</h2>
                <div className="flex gap-2">
                  <button
                    onClick={() => void loadCustomerStats(selectedCustomer.id)}
                    disabled={isLoadingStats}
                    className="rounded-lg bg-purple-100 px-3 py-1 text-sm text-purple-700 hover:bg-purple-200"
                  >
                    {isLoadingStats ? '⏳' : '📊'} Statisztika
                  </button>
                  <button
                    onClick={startEdit}
                    className="rounded-lg bg-blue-100 px-3 py-1 text-sm text-blue-700 hover:bg-blue-200"
                  >
                    ✏️ Módosítás
                  </button>
                </div>
              </div>
              <div className="mt-4 grid grid-cols-2 gap-3 text-sm">
                <div>
                  <span className="text-gray-500">Okmány típus:</span>
                  <p className="font-medium">{documentTypeLabels[selectedCustomer.documentType] ?? selectedCustomer.documentType}</p>
                </div>
                <div>
                  <span className="text-gray-500">Okmányszám:</span>
                  <p className="font-medium">{selectedCustomer.documentNumber}</p>
                </div>
                <div>
                  <span className="text-gray-500">Születési dátum:</span>
                  <p className="font-medium">{new Date(selectedCustomer.birthDate).toLocaleDateString('hu-HU')}</p>
                </div>
                <div>
                  <span className="text-gray-500">Születési hely:</span>
                  <p className="font-medium">{selectedCustomer.birthPlace}</p>
                </div>
                <div>
                  <span className="text-gray-500">Anyja neve:</span>
                  <p className="font-medium">{selectedCustomer.motherName}</p>
                </div>
                <div>
                  <span className="text-gray-500">Állampolgárság:</span>
                  <p className="font-medium">{selectedCustomer.nationality}</p>
                </div>
                <div className="col-span-2">
                  <span className="text-gray-500">Lakcím:</span>
                  <p className="font-medium">{selectedCustomer.address}</p>
                </div>
                {selectedCustomer.taxNumber && (
                  <div>
                    <span className="text-gray-500">Adószám:</span>
                    <p className="font-medium">{selectedCustomer.taxNumber}</p>
                  </div>
                )}
                {selectedCustomer.idCardNumber && (
                  <div>
                    <span className="text-gray-500">Személyi ig. szám:</span>
                    <p className="font-medium">{selectedCustomer.idCardNumber}</p>
                  </div>
                )}
                {selectedCustomer.idCardExpiry && (
                  <div>
                    <span className="text-gray-500">Személyi ig. lejárat:</span>
                    <p className="font-medium">{new Date(selectedCustomer.idCardExpiry).toLocaleDateString('hu-HU')}</p>
                  </div>
                )}
                {selectedCustomer.passportNumber && (
                  <div>
                    <span className="text-gray-500">Útlevél szám:</span>
                    <p className="font-medium">{selectedCustomer.passportNumber}</p>
                  </div>
                )}
                {selectedCustomer.passportExpiry && (
                  <div>
                    <span className="text-gray-500">Útlevél lejárat:</span>
                    <p className="font-medium">{new Date(selectedCustomer.passportExpiry).toLocaleDateString('hu-HU')}</p>
                  </div>
                )}
                {selectedCustomer.phone && (
                  <div>
                    <span className="text-gray-500">Telefonszám:</span>
                    <p className="font-medium">{selectedCustomer.phone}</p>
                  </div>
                )}
                {selectedCustomer.email && (
                  <div>
                    <span className="text-gray-500">E-mail:</span>
                    <p className="font-medium">{selectedCustomer.email}</p>
                  </div>
                )}
              </div>
            </div>

            {/* Okmány szkennelés gomb */}
            <div className="rounded-xl border bg-white p-4">
              <button
                onClick={() => setShowScanner(true)}
                className="btn-primary w-full bg-indigo-600 hover:bg-indigo-700"
              >
                📷 Okmány szkennelés
              </button>
            </div>

            {/* Tranzakció történet */}
            <div className="rounded-xl border bg-white p-6">
              <h3 className="mb-3 font-semibold text-gray-700">📋 Tranzakció történet</h3>
              {transactions.length > 0 ? (
                <div className="max-h-80 overflow-auto">
                  <table className="w-full text-sm">
                    <thead className="border-b text-left text-gray-500">
                      <tr>
                        <th className="pb-2">Dátum</th>
                        <th className="pb-2">Típus</th>
                        <th className="pb-2">Valuta</th>
                        <th className="pb-2 text-right">Összeg</th>
                        <th className="pb-2 text-right">HUF</th>
                      </tr>
                    </thead>
                    <tbody>
                      {transactions.map((tx) => (
                        <tr key={tx.id} className="border-b last:border-0">
                          <td className="py-2">{new Date(tx.createdAt).toLocaleDateString('hu-HU')}</td>
                          <td className="py-2">
                            <span className={tx.type === 'SELL' ? 'text-red-600' : 'text-green-600'}>
                              {tx.type === 'SELL' ? '💰 Eladás' : '🛒 Vásárlás'}
                            </span>
                          </td>
                          <td className="py-2">{tx.currencyCode}</td>
                          <td className="py-2 text-right font-mono">{tx.foreignAmount.toFixed(2)}</td>
                          <td className="py-2 text-right font-mono">
                            {tx.roundedHufAmount.toLocaleString('hu-HU')} Ft
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <p className="text-sm text-gray-400">Nincs korábbi tranzakció.</p>
              )}
            </div>
          </div>
        )}

        {tab === 'create' && renderForm('create')}
        {tab === 'edit' && renderForm('edit')}

        {tab === 'stats' && customerStats && (
          <div className="mx-auto max-w-2xl space-y-4">
            <div className="rounded-xl border bg-white p-6">
              <h2 className="mb-4 text-lg font-bold text-gray-800">📊 Ügyfél statisztika</h2>
              <h3 className="mb-3 text-base font-semibold text-gray-700">{customerStats.customerName}</h3>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div className="rounded-lg bg-blue-50 p-3">
                  <span className="text-gray-500">Összes tranzakció</span>
                  <p className="text-xl font-bold text-blue-700">{customerStats.totalTransactions}</p>
                </div>
                <div className="rounded-lg bg-green-50 p-3">
                  <span className="text-gray-500">Összes forgalom (HUF)</span>
                  <p className="text-xl font-bold text-green-700">
                    {customerStats.totalVolumeHuf?.toLocaleString('hu-HU')} Ft
                  </p>
                </div>
                <div className="rounded-lg bg-purple-50 p-3">
                  <span className="text-gray-500">Átlag összeg</span>
                  <p className="text-xl font-bold text-purple-700">
                    {customerStats.averageAmount?.toLocaleString('hu-HU')} Ft
                  </p>
                </div>
                <div className="rounded-lg bg-orange-50 p-3">
                  <span className="text-gray-500">Preferált valuta</span>
                  <p className="text-xl font-bold text-orange-700">{customerStats.preferredCurrency ?? '-'}</p>
                </div>
                <div>
                  <span className="text-gray-500">Első látogatás:</span>
                  <p className="font-medium">{customerStats.firstVisit ? new Date(customerStats.firstVisit).toLocaleDateString('hu-HU') : '-'}</p>
                </div>
                <div>
                  <span className="text-gray-500">Utolsó látogatás:</span>
                  <p className="font-medium">{customerStats.lastVisit ? new Date(customerStats.lastVisit).toLocaleDateString('hu-HU') : '-'}</p>
                </div>
              </div>
              <div className="mt-4">
                <button
                  onClick={() => setTab('detail')}
                  className="rounded-lg border px-4 py-2 text-gray-700 hover:bg-gray-50"
                >
                  ← Vissza az ügyfélhez
                </button>
              </div>
            </div>
          </div>
        )}

        {tab === 'vip' && (
          <div className="mx-auto max-w-3xl space-y-4">
            <div className="rounded-xl border bg-white p-6">
              <h2 className="mb-4 text-lg font-bold text-gray-800">⭐ Top ügyfelek</h2>
              {vipList.length > 0 ? (
                <div className="max-h-96 overflow-auto">
                  <table className="w-full text-sm">
                    <thead className="border-b text-left text-gray-500">
                      <tr>
                        <th className="pb-2">#</th>
                        <th className="pb-2">Név</th>
                        <th className="pb-2 text-right">Tranzakciók</th>
                        <th className="pb-2 text-right">Forgalom (HUF)</th>
                      </tr>
                    </thead>
                    <tbody>
                      {vipList.map((item) => (
                        <tr key={item.rank} className="border-b last:border-0">
                          <td className="py-2">
                            {item.rank <= 3 ? ['🥇', '🥈', '🥉'][item.rank - 1] : item.rank}
                          </td>
                          <td className="py-2 font-medium">{item.customerName}</td>
                          <td className="py-2 text-right font-mono">{item.transactionCount}</td>
                          <td className="py-2 text-right font-mono">
                            {item.totalVolumeHuf?.toLocaleString('hu-HU')} Ft
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <p className="text-sm text-gray-400">Nincs adat.</p>
              )}
              <div className="mt-4">
                <button
                  onClick={() => setTab('search')}
                  className="rounded-lg border px-4 py-2 text-gray-700 hover:bg-gray-50"
                >
                  ← Vissza a kereséshez
                </button>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Okmány szkenner modal */}
      {showScanner && selectedCustomer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-[700px] rounded-xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h3 className="text-lg font-bold">📷 Okmány szkennelés</h3>
              <button onClick={() => setShowScanner(false)} className="text-gray-400 hover:text-gray-600">✕</button>
            </div>
            <DocumentScanner
              transactionId={String(selectedCustomer.id)}
              onScanned={() => {
                setShowScanner(false);
                setSuccess('✅ Okmány sikeresen mentve!');
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
}


