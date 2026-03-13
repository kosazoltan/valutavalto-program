import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  getPendingApprovals,
  approveRateChange,
  rejectRateChange,
  requestRateChange,
} from '@/api/rateApproval';
import type { RateApproval, CurrencyCode } from '@/types';

const CURRENCY_OPTIONS: CurrencyCode[] = [
  'EUR', 'USD', 'GBP', 'CHF', 'CZK', 'PLN', 'RON', 'HRK', 'RSD', 'BAM',
  'BGN', 'DKK', 'NOK', 'SEK', 'CAD', 'AUD', 'NZD', 'JPY', 'CNY', 'TRY',
  'UAH', 'RUB', 'ILS', 'BRL', 'MXN', 'THB',
];

export default function RateApprovalPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [approvals, setApprovals] = useState<RateApproval[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  // Form state
  const [showForm, setShowForm] = useState(false);
  const [formBranchId, setFormBranchId] = useState('');
  const [formCurrency, setFormCurrency] = useState<CurrencyCode>('EUR');
  const [formBuyRate, setFormBuyRate] = useState('');
  const [formSellRate, setFormSellRate] = useState('');
  const [formReason, setFormReason] = useState('');

  const fetchApprovals = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const data = await getPendingApprovals();
      setApprovals(data);
    } catch {
      const msg = err instanceof Error ? err.message : 'Hiba a lekérdezés során';
      setError(`❌ ${msg}`);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchApprovals();
  }, [fetchApprovals]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const handleApprove = async (id: string) => {
    try {
      await approveRateChange(id);
      setSuccessMsg('✅ Árfolyam változtatás jóváhagyva!');
      void fetchApprovals();
    } catch {
      const msg = err instanceof Error ? err.message : 'Jóváhagyási hiba';
      setError(`❌ ${msg}`);
    }
  };

  const handleReject = async (id: string) => {
    const reason = prompt('Elutasítás indoka:');
    if (!reason) return;
    try {
      await rejectRateChange(id, reason);
      setSuccessMsg('⛔ Árfolyam változtatás elutasítva.');
      void fetchApprovals();
    } catch {
      const msg = err instanceof Error ? err.message : 'Elutasítási hiba';
      setError(`❌ ${msg}`);
    }
  };

  const handleSubmitForm = async () => {
    if (!formBranchId || !formBuyRate || !formSellRate) {
      setError('❌ Minden mező kitöltése kötelező!');
      return;
    }
    try {
      await requestRateChange({
        branchId: formBranchId,
        currencyCode: formCurrency,
        newBuyRate: parseFloat(formBuyRate),
        newSellRate: parseFloat(formSellRate),
        reason: formReason || undefined,
      });
      setSuccessMsg('✅ Árfolyam változtatási kérelem létrehozva!');
      setShowForm(false);
      setFormBranchId('');
      setFormBuyRate('');
      setFormSellRate('');
      setFormReason('');
      void fetchApprovals();
    } catch {
      const msg = err instanceof Error ? err.message : 'Kérelem létrehozási hiba';
      setError(`❌ ${msg}`);
    }
  };

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">📊 Árfolyam engedélyezés</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-5xl space-y-6">
          {/* Hibaüzenet / Siker */}
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>
          )}
          {successMsg && (
            <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">{successMsg}</div>
          )}

          {/* Új kérelem gomb */}
          <div className="flex justify-end">
            <button
              onClick={() => setShowForm(!showForm)}
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              {showForm ? '✖ Mégse' : '➕ Új árfolyam beállítás'}
            </button>
          </div>

          {/* Új kérelem form */}
          {showForm && (
            <div className="rounded-xl border-2 border-indigo-200 bg-indigo-50 p-6">
              <h2 className="mb-4 text-lg font-semibold text-indigo-800">Új árfolyam beállítás</h2>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Iroda azonosító (UUID)</label>
                  <input
                    type="text"
                    value={formBranchId}
                    onChange={(e) => setFormBranchId(e.target.value)}
                    placeholder="pl. 550e8400-e29b-41d4-a716-..."
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Valutanem</label>
                  <select
                    value={formCurrency}
                    onChange={(e) => setFormCurrency(e.target.value as CurrencyCode)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  >
                    {CURRENCY_OPTIONS.map((c) => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Új vételi árfolyam</label>
                  <input
                    type="number"
                    step="0.0001"
                    value={formBuyRate}
                    onChange={(e) => setFormBuyRate(e.target.value)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Új eladási árfolyam</label>
                  <input
                    type="number"
                    step="0.0001"
                    value={formSellRate}
                    onChange={(e) => setFormSellRate(e.target.value)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
                <div className="col-span-2">
                  <label className="block text-sm font-medium text-gray-700">Megjegyzés (opcionális)</label>
                  <input
                    type="text"
                    value={formReason}
                    onChange={(e) => setFormReason(e.target.value)}
                    className="mt-1 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                  />
                </div>
              </div>
              <div className="mt-4 flex justify-end">
                <button
                  onClick={() => void handleSubmitForm()}
                  className="rounded-lg bg-indigo-600 px-6 py-2 text-sm font-medium text-white hover:bg-indigo-700"
                >
                  📤 Kérelem küldés
                </button>
              </div>
            </div>
          )}

          {/* Függő jóváhagyások */}
          <div className="overflow-hidden rounded-xl border bg-white">
            <div className="border-b bg-gray-50 px-4 py-3">
              <h2 className="text-lg font-semibold text-gray-700">
                ⏳ Függő jóváhagyások ({approvals.length})
              </h2>
            </div>
            <table className="w-full">
              <thead>
                <tr className="border-b bg-gray-50 text-left text-sm font-medium text-gray-600">
                  <th className="px-4 py-3">Iroda</th>
                  <th className="px-4 py-3">Valuta</th>
                  <th className="px-4 py-3 text-right">Régi vétel</th>
                  <th className="px-4 py-3 text-right">Régi eladás</th>
                  <th className="px-4 py-3 text-right">Új vétel</th>
                  <th className="px-4 py-3 text-right">Új eladás</th>
                  <th className="px-4 py-3">Kérte</th>
                  <th className="px-4 py-3 text-center">Műveletek</th>
                </tr>
              </thead>
              <tbody>
                {approvals.map((a) => (
                  <tr key={a.id} className="border-b transition hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm font-medium">{a.branchName}</td>
                    <td className="px-4 py-3 text-sm font-semibold">{a.currencyCode}</td>
                    <td className="px-4 py-3 text-right font-mono text-sm text-gray-500">
                      {a.oldBuyRate?.toFixed(4) ?? '—'}
                    </td>
                    <td className="px-4 py-3 text-right font-mono text-sm text-gray-500">
                      {a.oldSellRate?.toFixed(4) ?? '—'}
                    </td>
                    <td className="px-4 py-3 text-right font-mono text-sm font-semibold text-green-700">
                      {a.newBuyRate.toFixed(4)}
                    </td>
                    <td className="px-4 py-3 text-right font-mono text-sm font-semibold text-blue-700">
                      {a.newSellRate.toFixed(4)}
                    </td>
                    <td className="px-4 py-3 text-sm">{a.requestedByName ?? '—'}</td>
                    <td className="px-4 py-3 text-center">
                      <div className="flex justify-center gap-2">
                        <button
                          onClick={() => void handleApprove(a.id)}
                          className="rounded bg-green-600 px-3 py-1 text-xs font-medium text-white hover:bg-green-700"
                        >
                          ✅ Engedélyezés
                        </button>
                        <button
                          onClick={() => void handleReject(a.id)}
                          className="rounded bg-red-600 px-3 py-1 text-xs font-medium text-white hover:bg-red-700"
                        >
                          ⛔ Visszavonás
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {approvals.length === 0 && !isLoading && (
                  <tr>
                    <td colSpan={8} className="px-4 py-8 text-center text-gray-400">
                      Nincs függő árfolyam jóváhagyás.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}

