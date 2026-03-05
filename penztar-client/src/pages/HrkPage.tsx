import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { hrkHandover, hrkReceive, getHrkJournal, closeHrkDaily } from '@/api/hrk';
import { getForeignCurrencies } from '@/utils/currencies';
import type { HrkTransaction, HrkType } from '@/types';

type TabMode = 'handover' | 'receive' | 'journal';

export default function HrkPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const currencies = getForeignCurrencies();

  const [activeTab, setActiveTab] = useState<TabMode>('handover');

  // --- Form mezők ---
  const [currencyCode, setCurrencyCode] = useState<string>('EUR');
  const [amount, setAmount] = useState('');
  const [hufAmount, setHufAmount] = useState('');
  const [bankAccountNumber, setBankAccountNumber] = useState('');
  const [note, setNote] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // --- Napló ---
  const [journal, setJournal] = useState<HrkTransaction[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [dailySummary, setDailySummary] = useState<HrkTransaction[] | null>(null);

  // Napló betöltés
  const loadJournal = useCallback(async () => {
    setIsLoading(true);
    try {
      const data = await getHrkJournal();
      setJournal(data);
    } catch {
      console.error('[HrkPage] Napló betöltés hiba');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    if (activeTab === 'journal') {
      void loadJournal();
    }
  }, [activeTab, loadJournal]);

  // Form beküldés
  const handleSubmit = useCallback(
    async (type: HrkType) => {
      const amountNum = parseFloat(amount);
      const hufNum = parseFloat(hufAmount);
      if (isNaN(amountNum) || amountNum <= 0 || isNaN(hufNum) || hufNum <= 0) {
        setError('Összeg és forint összeg megadása kötelező.');
        return;
      }

      setIsSubmitting(true);
      setError('');
      setSuccess('');

      try {
        const request = {
          currencyCode,
          amount: amountNum,
          hufAmount: hufNum,
          bankAccountNumber: bankAccountNumber || undefined,
          note: note || undefined,
        };

        const result =
          type === 'HANDOVER'
            ? await hrkHandover(request)
            : await hrkReceive(request);

        const typeLabel = type === 'HANDOVER' ? 'Átadás' : 'Átvétel';
        setSuccess(
          `✅ HRK ${typeLabel} sikeres! Bizonylat: ${result.reference} — ${result.amount} ${result.currencyCode}`,
        );

        // Reset
        setAmount('');
        setHufAmount('');
        setNote('');
      } catch {
        setError('❌ Művelet sikertelen. Próbálja újra.');
      } finally {
        setIsSubmitting(false);
      }
    },
    [currencyCode, amount, hufAmount, bankAccountNumber, note],
  );

  // Napi zárás
  const handleDailyClose = useCallback(async () => {
    try {
      const data = await closeHrkDaily();
      setDailySummary(data);
      setSuccess('✅ Napi HRK zárás elkészült.');
    } catch {
      setError('❌ Napi zárás sikertelen.');
    }
  }, []);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const formatDate = (dateStr: string) => {
    try {
      return new Date(dateStr).toLocaleString('hu-HU');
    } catch {
      return dateStr;
    }
  };

  const typeLabels: Record<HrkType, string> = {
    HANDOVER: '📤 Átadás',
    RECEIVE: '📥 Átvétel',
  };

  // Currency options — HUF + foreign
  const currencyOptions: string[] = ['HUF', ...currencies.map((c) => c.code)];

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🏦 Házipénztári Kezelés (HRK)</h1>
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
            onClick={() => setActiveTab('handover')}
            className={`border-b-2 px-4 py-3 text-sm font-medium ${
              activeTab === 'handover'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            📤 Átadás (pénztár → bank)
          </button>
          <button
            onClick={() => setActiveTab('receive')}
            className={`border-b-2 px-4 py-3 text-sm font-medium ${
              activeTab === 'receive'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            📥 Átvétel (bank → pénztár)
          </button>
          <button
            onClick={() => setActiveTab('journal')}
            className={`border-b-2 px-4 py-3 text-sm font-medium ${
              activeTab === 'journal'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            📒 Napló
          </button>
        </div>
      </div>

      <main className="flex-1 overflow-auto p-6">
        {/* Visszajelzések */}
        {error && (
          <div className="mx-auto mb-4 max-w-4xl rounded-lg bg-red-50 p-3 text-sm text-red-700">
            {error}
          </div>
        )}
        {success && (
          <div className="mx-auto mb-4 max-w-4xl rounded-lg bg-green-50 p-3 text-sm text-green-700">
            {success}
          </div>
        )}

        {(activeTab === 'handover' || activeTab === 'receive') ? (
          /* === ÁTADÁS / ÁTVÉTEL FORM === */
          <div className="mx-auto max-w-lg space-y-4">
            <div className="rounded-xl border bg-white p-6">
              <h2 className="mb-4 text-lg font-semibold text-gray-700">
                {activeTab === 'handover'
                  ? '📤 HRK Átadás — Pénztár → Bank'
                  : '📥 HRK Átvétel — Bank → Pénztár'}
              </h2>

              {/* Valutanem */}
              <div className="mb-4">
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Valutanem
                </label>
                <select
                  value={currencyCode}
                  onChange={(e) => setCurrencyCode(e.target.value)}
                  className="input-field"
                >
                  {currencyOptions.map((code) => (
                    <option key={code} value={code}>
                      {code}
                    </option>
                  ))}
                </select>
              </div>

              {/* Összeg */}
              <div className="mb-4">
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Összeg ({currencyCode})
                </label>
                <input
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="input-field text-right text-xl font-bold"
                  placeholder="0.00"
                  step="0.01"
                  min="0"
                />
              </div>

              {/* Forint összeg */}
              <div className="mb-4">
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Forint összeg (HUF)
                </label>
                <input
                  type="number"
                  value={hufAmount}
                  onChange={(e) => setHufAmount(e.target.value)}
                  className="input-field text-right text-xl font-bold"
                  placeholder="0"
                  step="1"
                  min="0"
                />
              </div>

              {/* Bankszámlaszám */}
              <div className="mb-4">
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Bankszámlaszám
                </label>
                <input
                  type="text"
                  value={bankAccountNumber}
                  onChange={(e) => setBankAccountNumber(e.target.value)}
                  className="input-field"
                  placeholder="11111111-22222222-33333333"
                />
              </div>

              {/* Megjegyzés */}
              <div className="mb-6">
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Megjegyzés
                </label>
                <textarea
                  value={note}
                  onChange={(e) => setNote(e.target.value)}
                  className="input-field"
                  rows={2}
                  placeholder="Opcionális megjegyzés..."
                />
              </div>

              {/* Gomb */}
              <button
                onClick={() =>
                  void handleSubmit(activeTab === 'handover' ? 'HANDOVER' : 'RECEIVE')
                }
                disabled={isSubmitting}
                className={`btn-primary w-full text-lg ${
                  isBestChange
                    ? 'bg-red-600 hover:bg-red-700'
                    : 'bg-orange-500 hover:bg-orange-600'
                } disabled:cursor-not-allowed disabled:opacity-50`}
              >
                {isSubmitting
                  ? '⏳ Feldolgozás...'
                  : activeTab === 'handover'
                    ? '📤 Átadás véglegesítése'
                    : '📥 Átvétel véglegesítése'}
              </button>
            </div>
          </div>
        ) : (
          /* === NAPLÓ === */
          <div className="mx-auto max-w-6xl">
            {/* Napi zárás gomb */}
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-gray-700">📒 HRK Napló</h2>
              <div className="flex gap-2">
                <button
                  onClick={loadJournal}
                  className="rounded-lg bg-blue-100 px-4 py-2 text-sm text-blue-700 hover:bg-blue-200"
                >
                  🔄 Frissítés
                </button>
                <button
                  onClick={handleDailyClose}
                  className="rounded-lg bg-purple-100 px-4 py-2 text-sm text-purple-700 hover:bg-purple-200"
                >
                  📊 Napi zárás
                </button>
              </div>
            </div>

            {/* Napi összesítő */}
            {dailySummary && (
              <div className="mb-4 rounded-xl border bg-purple-50 p-4">
                <h3 className="mb-2 font-semibold text-purple-700">📊 Napi HRK összesítő</h3>
                <p className="text-sm text-gray-600">
                  Tranzakciók száma: {dailySummary.length}
                </p>
              </div>
            )}

            {/* Táblázat */}
            {isLoading ? (
              <p className="text-center text-gray-500">⏳ Betöltés...</p>
            ) : journal.length === 0 ? (
              <p className="text-center text-gray-500">Nincs HRK tranzakció.</p>
            ) : (
              <div className="overflow-auto rounded-xl border bg-white">
                <table className="w-full text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-4 py-3 text-left">Bizonylat</th>
                      <th className="px-4 py-3 text-center">Irány</th>
                      <th className="px-4 py-3 text-right">Valuta</th>
                      <th className="px-4 py-3 text-right">Összeg</th>
                      <th className="px-4 py-3 text-right">HUF összeg</th>
                      <th className="px-4 py-3 text-left">Bankszámla</th>
                      <th className="px-4 py-3 text-center">Státusz</th>
                      <th className="px-4 py-3 text-center">Dátum</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y">
                    {journal.map((tx) => (
                      <tr key={tx.id} className="hover:bg-gray-50">
                        <td className="px-4 py-3 font-mono text-xs">{tx.reference}</td>
                        <td className="px-4 py-3 text-center text-xs">
                          {typeLabels[tx.type]}
                        </td>
                        <td className="px-4 py-3 text-right font-medium">{tx.currencyCode}</td>
                        <td className="px-4 py-3 text-right">
                          {tx.amount.toLocaleString('hu-HU')}
                        </td>
                        <td className="px-4 py-3 text-right">
                          {tx.hufAmount.toLocaleString('hu-HU')} Ft
                        </td>
                        <td className="px-4 py-3 text-xs">{tx.bankAccountNumber ?? '—'}</td>
                        <td className="px-4 py-3 text-center">
                          <span
                            className={`rounded-full px-2 py-1 text-xs ${
                              tx.status === 'COMPLETED'
                                ? 'bg-green-100 text-green-700'
                                : tx.status === 'PENDING'
                                  ? 'bg-yellow-100 text-yellow-700'
                                  : 'bg-red-100 text-red-700'
                            }`}
                          >
                            {tx.status}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-center text-xs">
                          {formatDate(tx.createdAt)}
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
    </div>
  );
}
