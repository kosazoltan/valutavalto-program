import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { useOnlineStatus } from '@/hooks/useOnlineStatus';
import type { CollectionRecord, CollectionStatus, CurrencyCode } from '@/types';

// --- Konstansok ---
const STATUS_LABELS: Record<CollectionStatus, { label: string; color: string; icon: string }> = {
  REQUESTED: { label: 'Kérelmezve', color: 'bg-blue-100 text-blue-700', icon: '📋' },
  IN_PROGRESS: { label: 'Folyamatban', color: 'bg-yellow-100 text-yellow-700', icon: '⏳' },
  COMPLETED: { label: 'Befejezve', color: 'bg-green-100 text-green-700', icon: '✅' },
  REJECTED: { label: 'Elutasítva', color: 'bg-red-100 text-red-700', icon: '❌' },
};

const MOCK_BRANCHES = [
  { code: '101', name: 'Szeged Kárász u.' },
  { code: '102', name: 'Szeged Dugonics tér' },
  { code: '103', name: 'Szeged Árkád' },
  { code: '151', name: 'Szeged Klauzál tér' },
];

const CURRENCIES: Array<CurrencyCode | 'HUF'> = ['EUR', 'USD', 'GBP', 'CHF', 'HUF'];

function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleString('hu-HU', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function formatAmount(amount: number): string {
  return amount.toLocaleString('hu-HU', { maximumFractionDigits: 0 });
}

// Mock begyűjtési rekordok
function generateMockRecords(): CollectionRecord[] {
  return [
    {
      id: 1, sourceBranchCode: '101', sourceBranchName: 'Szeged Kárász u.',
      currencyCode: 'EUR', amount: 5_000, status: 'COMPLETED',
      requestedAt: new Date(Date.now() - 3_600_000).toISOString(),
      completedAt: new Date(Date.now() - 1_800_000).toISOString(),
    },
    {
      id: 2, sourceBranchCode: '102', sourceBranchName: 'Szeged Dugonics tér',
      currencyCode: 'USD', amount: 3_000, status: 'IN_PROGRESS',
      requestedAt: new Date(Date.now() - 1_200_000).toISOString(),
      note: 'Napi záró begyűjtés',
    },
    {
      id: 3, sourceBranchCode: '103', sourceBranchName: 'Szeged Árkád',
      currencyCode: 'HUF', amount: 2_000_000, status: 'REQUESTED',
      requestedAt: new Date(Date.now() - 600_000).toISOString(),
    },
  ];
}

export default function CollectionPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const { isOnline } = useOnlineStatus();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [records, setRecords] = useState<CollectionRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Új begyűjtés form
  const [selectedBranch, setSelectedBranch] = useState('');
  const [selectedCurrency, setSelectedCurrency] = useState<CurrencyCode | 'HUF'>('EUR');
  const [amount, setAmount] = useState('');
  const [collectionNote, setCollectionNote] = useState('');
  const [isSending, setIsSending] = useState(false);
  const [feedback, setFeedback] = useState<{ success: boolean; message: string } | null>(null);

  const loadRecords = useCallback(async () => {
    try {
      // TODO: API hívás — GET /api/v1/ertektar/collections
      const mockData = generateMockRecords();
      setRecords(mockData);
    } catch (err) {
      console.error('[CollectionPage] Betöltési hiba:', err);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadRecords();
  }, [loadRecords]);

  const handleStartCollection = useCallback(async () => {
    if (!selectedBranch || !amount || parseFloat(amount) <= 0) return;

    setIsSending(true);
    setFeedback(null);

    try {
      if (!isOnline && window.electronAPI) {
        // OFFLINE mód — pending queue-ba mentés
        await window.electronAPI.savePendingCollection(
          selectedBranch,
          selectedCurrency,
          parseFloat(amount),
          collectionNote || null,
        );
      } else {
        // TODO: API hívás — POST /api/v1/ertektar/collections
        console.log('[Collection] Begyűjtés indítása:', {
          sourceBranchCode: selectedBranch,
          currencyCode: selectedCurrency,
          amount: parseFloat(amount),
          note: collectionNote,
        });
        await new Promise((resolve) => setTimeout(resolve, 800));
      }

      // Mock: hozzáadjuk a listához
      const branchInfo = MOCK_BRANCHES.find((b) => b.code === selectedBranch);
      const newRecord: CollectionRecord = {
        id: Date.now(),
        sourceBranchCode: selectedBranch,
        sourceBranchName: branchInfo?.name ?? selectedBranch,
        currencyCode: selectedCurrency,
        amount: parseFloat(amount),
        status: 'REQUESTED',
        requestedAt: new Date().toISOString(),
        note: collectionNote || undefined,
      };
      setRecords((prev) => [newRecord, ...prev]);

      const offlineSuffix = !isOnline ? ' (offline — szinkronizálódik később)' : '';
      setFeedback({
        success: true,
        message: `Begyűjtés kérelem elküldve: ${branchInfo?.name ?? selectedBranch} — ${formatAmount(parseFloat(amount))} ${selectedCurrency}${offlineSuffix}`,
      });

      // Reset
      setSelectedBranch('');
      setAmount('');
      setCollectionNote('');
    } catch (err) {
      setFeedback({
        success: false,
        message: `Hiba: ${err instanceof Error ? err.message : 'Ismeretlen hiba'}`,
      });
    } finally {
      setIsSending(false);
    }
  }, [selectedBranch, selectedCurrency, amount, collectionNote]);

  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <p className="text-gray-500">⏳ Betöltés...</p>
      </div>
    );
  }

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-4 text-white shadow-lg`}>
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">📥 Készlet begyűjtés</h1>
            <p className="text-sm text-white/80">Pénztárak készletének begyűjtése az értéktárba</p>
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
          {/* Új begyűjtés form */}
          <div className="mb-6 rounded-lg border bg-white p-4 shadow-sm">
            <h2 className="mb-4 text-lg font-semibold text-gray-700">Új begyűjtés indítása</h2>

            <div className="grid grid-cols-2 gap-4">
              {/* Pénztár választó */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">Pénztár</label>
                <select
                  value={selectedBranch}
                  onChange={(e) => setSelectedBranch(e.target.value)}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                >
                  <option value="">— Válasszon pénztárat —</option>
                  {MOCK_BRANCHES.map((b) => (
                    <option key={b.code} value={b.code}>
                      [{b.code}] {b.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Valutanem */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">Valutanem</label>
                <select
                  value={selectedCurrency}
                  onChange={(e) => setSelectedCurrency(e.target.value as CurrencyCode | 'HUF')}
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                >
                  {CURRENCIES.map((c) => (
                    <option key={c} value={c}>{c}</option>
                  ))}
                </select>
              </div>

              {/* Összeg */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">Összeg</label>
                <input
                  type="number"
                  min="0"
                  step="1"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="0"
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                />
              </div>

              {/* Megjegyzés */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">Megjegyzés</label>
                <input
                  type="text"
                  value={collectionNote}
                  onChange={(e) => setCollectionNote(e.target.value)}
                  placeholder="Opcionális..."
                  className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
                />
              </div>
            </div>

            <div className="mt-4 flex items-center gap-4">
              <button
                onClick={() => void handleStartCollection()}
                disabled={!selectedBranch || !amount || parseFloat(amount) <= 0 || isSending}
                className="rounded-lg bg-blue-600 px-6 py-2 text-sm font-bold text-white transition hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                {isSending ? '⏳ Küldés...' : '📥 Begyűjtés indítása'}
              </button>

              {feedback && (
                <span
                  className={`text-sm ${feedback.success ? 'text-green-600' : 'text-red-600'}`}
                >
                  {feedback.success ? '✅' : '❌'} {feedback.message}
                </span>
              )}
            </div>
          </div>

          {/* Begyűjtési előzmények */}
          <div className="rounded-lg border bg-white p-4 shadow-sm">
            <h2 className="mb-4 text-lg font-semibold text-gray-700">Begyűjtési előzmények</h2>

            {records.length === 0 ? (
              <p className="text-center text-gray-400">Nincs begyűjtési rekord</p>
            ) : (
              <table className="w-full text-sm">
                <thead className="border-b text-left text-gray-500">
                  <tr>
                    <th className="px-2 py-2">Pénztár</th>
                    <th className="px-2 py-2">Valuta</th>
                    <th className="px-2 py-2 text-right">Összeg</th>
                    <th className="px-2 py-2">Státusz</th>
                    <th className="px-2 py-2">Időpont</th>
                    <th className="px-2 py-2">Megjegyzés</th>
                  </tr>
                </thead>
                <tbody>
                  {records.map((record) => {
                    const statusInfo = STATUS_LABELS[record.status];
                    return (
                      <tr key={record.id} className="border-b last:border-0">
                        <td className="px-2 py-2 font-medium">
                          [{record.sourceBranchCode}] {record.sourceBranchName}
                        </td>
                        <td className="px-2 py-2">{record.currencyCode}</td>
                        <td className="px-2 py-2 text-right font-mono">
                          {formatAmount(record.amount)}
                        </td>
                        <td className="px-2 py-2">
                          <span className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${statusInfo.color}`}>
                            {statusInfo.icon} {statusInfo.label}
                          </span>
                        </td>
                        <td className="px-2 py-2 text-gray-500">
                          {formatDate(record.requestedAt)}
                        </td>
                        <td className="px-2 py-2 text-gray-400">
                          {record.note ?? '—'}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
