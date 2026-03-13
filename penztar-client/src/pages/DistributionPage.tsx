import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { useOnlineStatus } from '@/hooks/useOnlineStatus';
import type { CurrencyCode, DistributionItem, Denomination } from '@/types';

// --- Konstansok ---
const AVAILABLE_CURRENCIES: Array<CurrencyCode | 'HUF'> = [
  'EUR', 'USD', 'GBP', 'CHF', 'CZK', 'PLN', 'RON', 'HUF',
];

// Mock alárendelt pénztárak
const MOCK_BRANCHES = [
  { code: '101', name: 'Szeged Kárász u.' },
  { code: '102', name: 'Szeged Dugonics tér' },
  { code: '103', name: 'Szeged Árkád' },
  { code: '151', name: 'Szeged Klauzál tér' },
];

interface DistributionFormItem {
  targetBranchCode: string;
  currencyCode: CurrencyCode | 'HUF';
  amount: string;
  denominations: Denomination[];
  selected: boolean;
}

function formatHuf(amount: number): string {
  return amount.toLocaleString('hu-HU', { maximumFractionDigits: 0 });
}

export default function DistributionPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const { isOnline } = useOnlineStatus();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [currencyCode, setCurrencyCode] = useState<CurrencyCode | 'HUF'>('EUR');
  const [note, setNote] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [result, setResult] = useState<{ success: boolean; message: string } | null>(null);

  const [formItems, setFormItems] = useState<DistributionFormItem[]>(
    MOCK_BRANCHES.map((b) => ({
      targetBranchCode: b.code,
      currencyCode: 'EUR',
      amount: '',
      denominations: [],
      selected: false,
    })),
  );

  const handleToggleBranch = useCallback((idx: number) => {
    setFormItems((prev) =>
      prev.map((item, i) =>
        i === idx ? { ...item, selected: !item.selected } : item,
      ),
    );
  }, []);

  const handleAmountChange = useCallback((idx: number, value: string) => {
    setFormItems((prev) =>
      prev.map((item, i) =>
        i === idx ? { ...item, amount: value } : item,
      ),
    );
  }, []);

  const handleCurrencyChange = useCallback((code: CurrencyCode | 'HUF') => {
    setCurrencyCode(code);
    setFormItems((prev) =>
      prev.map((item) => ({ ...item, currencyCode: code })),
    );
  }, []);

  const selectedItems = formItems.filter((item) => item.selected && parseFloat(item.amount) > 0);
  const totalAmount = selectedItems.reduce((sum, item) => sum + (parseFloat(item.amount) || 0), 0);

  const handleSend = useCallback(async () => {
    if (selectedItems.length === 0) return;

    setIsSending(true);
    setResult(null);

    try {
      const _items: DistributionItem[] = selectedItems.map((item) => ({
        targetBranchCode: item.targetBranchCode,
        currencyCode: item.currencyCode,
        amount: parseFloat(item.amount),
        denominations: item.denominations.length > 0 ? item.denominations : undefined,
      }));

      if (!isOnline && window.electronAPI) {
        // OFFLINE mód — pending_distributions-be mentés
        for (const item of _items) {
          await window.electronAPI.savePendingDistribution(
            item.targetBranchCode,
            item.currencyCode,
            item.amount,
            item.denominations ? JSON.stringify(item.denominations) : null,
            note || null,
          );
        }
        setResult({
          success: true,
          message: `${selectedItems.length} pénztárnak rögzítve (offline — szinkronizálódik később) — összesen ${formatHuf(totalAmount)} ${currencyCode}`,
        });
      } else {
        // ONLINE mód — API hívás
        // TODO(api): API hívás — POST /api/v1/ertektar/distribution — backend Értéktár modul szükséges
        console.log('[Distribution] Batch küldés:', _items, 'Megjegyzés:', note);
        await new Promise((resolve) => setTimeout(resolve, 1_000));

        setResult({
          success: true,
          message: `${selectedItems.length} pénztárnak sikeresen kiküldve — összesen ${formatHuf(totalAmount)} ${currencyCode}`,
        });
      }

      // Form reset
      setFormItems((prev) =>
        prev.map((item) => ({ ...item, selected: false, amount: '' })),
      );
      setNote('');
    } catch (err: unknown) {
      setResult({
        success: false,
        message: `Hiba: ${err instanceof Error ? err.message : 'Ismeretlen hiba'}`,
      });
    } finally {
      setIsSending(false);
    }
  }, [selectedItems, totalAmount, currencyCode, note]);

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-4 text-white shadow-lg`}>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">📦 Valuta szétosztás</h1>
            <p className="text-sm text-white/80">Pénztárak felé történő batch átadás</p>
          </div>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm font-medium text-white transition hover:bg-white/30"
          >
            ← Vissza
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-4xl">
          {/* Valutanem választó */}
          <div className="mb-6 rounded-lg border bg-white p-4 shadow-sm">
            <h2 className="mb-3 text-lg font-semibold text-gray-700">Valutanem</h2>
            <div className="flex flex-wrap gap-2">
              {AVAILABLE_CURRENCIES.map((code) => (
                <button
                  key={code}
                  onClick={() => handleCurrencyChange(code)}
                  className={`rounded-lg border-2 px-4 py-2 text-sm font-medium transition ${
                    currencyCode === code
                      ? 'border-blue-500 bg-blue-50 text-blue-700'
                      : 'border-gray-200 bg-white text-gray-600 hover:border-gray-300'
                  }`}
                >
                  {code}
                </button>
              ))}
            </div>
          </div>

          {/* Pénztár lista — multi-select + összeg */}
          <div className="mb-6 rounded-lg border bg-white p-4 shadow-sm">
            <h2 className="mb-3 text-lg font-semibold text-gray-700">Célpénztárak</h2>
            <div className="space-y-3">
              {MOCK_BRANCHES.map((branch, idx) => {
                const formItem = formItems[idx];
                if (!formItem) return null;
                return (
                  <div
                    key={branch.code}
                    className={`flex items-center gap-4 rounded-lg border-2 p-3 transition ${
                      formItem.selected
                        ? 'border-blue-300 bg-blue-50'
                        : 'border-gray-200 bg-white'
                    }`}
                  >
                    <label className="flex cursor-pointer items-center gap-2">
                      <input
                        type="checkbox"
                        checked={formItem.selected}
                        onChange={() => handleToggleBranch(idx)}
                        className="h-5 w-5 rounded border-gray-300 text-blue-600"
                      />
                      <span className="font-medium text-gray-700">
                        [{branch.code}] {branch.name}
                      </span>
                    </label>
                    <div className="ml-auto flex items-center gap-2">
                      <input
                        type="number"
                        min="0"
                        step="1"
                        placeholder="Összeg"
                        value={formItem.amount}
                        onChange={(e) => handleAmountChange(idx, e.target.value)}
                        disabled={!formItem.selected}
                        className="w-40 rounded-lg border border-gray-300 px-3 py-2 text-right text-sm disabled:bg-gray-100"
                      />
                      <span className="text-sm font-medium text-gray-500">{currencyCode}</span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Megjegyzés */}
          <div className="mb-6 rounded-lg border bg-white p-4 shadow-sm">
            <label className="mb-2 block text-sm font-medium text-gray-700">Megjegyzés (opcionális)</label>
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              rows={2}
              className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
              placeholder="Pl.: Heti feltöltés, sürgős pótlás..."
            />
          </div>

          {/* Összesítő + Küldés */}
          <div className="rounded-lg border bg-white p-4 shadow-sm">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">
                  Kiválasztva: <strong>{selectedItems.length}</strong> pénztár
                </p>
                <p className="text-lg font-bold text-gray-800">
                  Összesen: {formatHuf(totalAmount)} {currencyCode}
                </p>
              </div>
              <button
                onClick={() => void handleSend()}
                disabled={selectedItems.length === 0 || isSending}
                className="rounded-lg bg-blue-600 px-6 py-3 text-sm font-bold text-white transition hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                {isSending ? '⏳ Küldés...' : '📤 Batch küldés'}
              </button>
            </div>

            {/* Eredmény */}
            {result && (
              <div
                className={`mt-4 rounded-lg p-3 text-sm ${
                  result.success
                    ? 'bg-green-50 text-green-700 border border-green-200'
                    : 'bg-red-50 text-red-700 border border-red-200'
                }`}
              >
                {result.success ? '✅' : '❌'} {result.message}
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}


