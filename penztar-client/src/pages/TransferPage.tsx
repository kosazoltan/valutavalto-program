import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  createTransfer,
  getPendingTransfers,
  receiveTransfer,
  rejectTransfer,
  getBranches,
} from '@/api/transfers';
import { CURRENCIES, getCurrencyInfo } from '@/utils/currencies';
import type {
  CurrencyCode,
  Transfer,
  Branch,
  TransferStatus,
} from '@/types';

type ActiveTab = 'send' | 'receive';

const STATUS_LABELS: Record<TransferStatus, string> = {
  PENDING: '⏳ Függőben',
  RECEIVED: '✅ Átvéve',
  REJECTED: '❌ Elutasítva',
  CANCELLED: '🚫 Visszavonva',
};

const STATUS_COLORS: Record<TransferStatus, string> = {
  PENDING: 'bg-yellow-100 text-yellow-800',
  RECEIVED: 'bg-green-100 text-green-800',
  REJECTED: 'bg-red-100 text-red-800',
  CANCELLED: 'bg-gray-100 text-gray-800',
};

export default function TransferPage() {
  const navigate = useNavigate();
  const { companyType, branchCode } = useAuthStore();

  const [activeTab, setActiveTab] = useState<ActiveTab>('send');

  // Átadás form
  const [targetBranch, setTargetBranch] = useState('');
  const [sendCurrency, setSendCurrency] = useState<CurrencyCode | 'HUF'>('HUF');
  const [sendAmount, setSendAmount] = useState('');
  const [sendNote, setSendNote] = useState('');
  const [isSending, setIsSending] = useState(false);

  // Átvétel lista
  const [pendingTransfers, setPendingTransfers] = useState<Transfer[]>([]);
  const [branches, setBranches] = useState<Branch[]>([]);
  const [isLoadingPending, setIsLoadingPending] = useState(false);
  const [processingId, setProcessingId] = useState<number | null>(null);

  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const availableBranches = useMemo(
    () => branches.filter((b) => b.code !== branchCode),
    [branches, branchCode],
  );

  // Load branches & pending transfers
  const fetchData = useCallback(async () => {
    setIsLoadingPending(true);
    try {
      const [branchData, transferData] = await Promise.all([
        getBranches(),
        getPendingTransfers(),
      ]);
      setBranches(branchData);
      setPendingTransfers(transferData);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Adatlekérési hiba';
      setError(`❌ ${message}`);
    } finally {
      setIsLoadingPending(false);
    }
  }, []);

  useEffect(() => {
    void fetchData();
  }, [fetchData]);

  // Átadás küldés
  const handleSend = useCallback(async () => {
    const amount = parseFloat(sendAmount);
    if (!targetBranch || isNaN(amount) || amount <= 0) return;

    setIsSending(true);
    setError('');
    setSuccess('');

    try {
      const result = await createTransfer({
        targetBranchCode: targetBranch,
        currencyCode: sendCurrency,
        amount,
        note: sendNote || undefined,
      });

      setSuccess(
        `✅ Átadás sikeres! Bizonylat: ${result.receiptNumber} — ${amount.toLocaleString('hu-HU')} ${sendCurrency} → Pénztár ${targetBranch}`,
      );

      // Reset
      setTargetBranch('');
      setSendAmount('');
      setSendNote('');
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Átadási hiba';
      setError(`❌ ${message}`);
    } finally {
      setIsSending(false);
    }
  }, [targetBranch, sendCurrency, sendAmount, sendNote]);

  // Átvétel
  const handleReceive = useCallback(
    async (id: number) => {
      setProcessingId(id);
      setError('');
      setSuccess('');

      try {
        // A transfer.amount az elvárt összeg — átvételkor megerősítjük
        const transfer = pendingTransfers.find((t) => t.id === id);
        await receiveTransfer(id, transfer?.amount ?? 0);
        setSuccess('✅ Átadás átvéve!');
        void fetchData();
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Átvételi hiba';
        setError(`❌ ${message}`);
      } finally {
        setProcessingId(null);
      }
    },
    [fetchData, pendingTransfers],
  );

  // Elutasítás
  const handleReject = useCallback(
    async (id: number) => {
      const reason = window.prompt('Elutasítás oka:');
      if (!reason) return;

      setProcessingId(id);
      setError('');
      setSuccess('');

      try {
        await rejectTransfer(id, reason);
        setSuccess('✅ Átadás elutasítva.');
        void fetchData();
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : 'Elutasítási hiba';
        setError(`❌ ${message}`);
      } finally {
        setProcessingId(null);
      }
    },
    [fetchData],
  );

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        navigate('/menu');
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const canSend =
    targetBranch !== '' &&
    parseFloat(sendAmount) > 0;

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🔄 Átadás-átvétel</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-4xl space-y-6">
          {/* Tab választó */}
          <div className="flex gap-2 rounded-xl border bg-white p-1">
            <button
              onClick={() => { setActiveTab('send'); setError(''); setSuccess(''); }}
              className={`flex-1 rounded-lg py-2 text-sm font-semibold transition ${
                activeTab === 'send'
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              📤 Átadás
            </button>
            <button
              onClick={() => { setActiveTab('receive'); setError(''); setSuccess(''); }}
              className={`flex-1 rounded-lg py-2 text-sm font-semibold transition ${
                activeTab === 'receive'
                  ? 'bg-blue-600 text-white'
                  : 'text-gray-600 hover:bg-gray-100'
              }`}
            >
              📥 Átvétel
              {pendingTransfers.length > 0 && (
                <span className="ml-2 rounded-full bg-red-500 px-2 py-0.5 text-xs text-white">
                  {pendingTransfers.length}
                </span>
              )}
            </button>
          </div>

          {/* Üzenetek */}
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>
          )}
          {success && (
            <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">
              {success}
            </div>
          )}

          {/* ÁTADÁS TAB */}
          {activeTab === 'send' && (
            <div className="space-y-4 rounded-xl border bg-white p-6">
              <h2 className="text-lg font-semibold text-gray-700">📤 Átadás indítása</h2>

              {/* Célpénztár */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Célpénztár
                </label>
                <select
                  value={targetBranch}
                  onChange={(e) => setTargetBranch(e.target.value)}
                  className="input-field"
                >
                  <option value="">— Válasszon pénztárat —</option>
                  {availableBranches.map((b) => (
                    <option key={b.code} value={b.code}>
                      {b.code} — {b.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Valutanem */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Valutanem
                </label>
                <select
                  value={sendCurrency}
                  onChange={(e) => setSendCurrency(e.target.value as CurrencyCode | 'HUF')}
                  className="input-field"
                >
                  {CURRENCIES.map((c) => (
                    <option key={c.code} value={c.code}>
                      {c.flag} {c.code} — {c.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Összeg */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Összeg
                </label>
                <input
                  type="number"
                  value={sendAmount}
                  onChange={(e) => setSendAmount(e.target.value)}
                  className="input-field text-right text-xl font-bold"
                  placeholder="0"
                  min="0"
                  step="1"
                />
              </div>

              {/* Megjegyzés */}
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">
                  Megjegyzés (opcionális)
                </label>
                <textarea
                  value={sendNote}
                  onChange={(e) => setSendNote(e.target.value)}
                  className="input-field min-h-[60px] resize-none"
                  placeholder="Megjegyzés..."
                />
              </div>

              <button
                onClick={() => void handleSend()}
                disabled={!canSend || isSending}
                className="btn-primary w-full bg-blue-600 text-lg hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {isSending
                  ? '⏳ Küldés...'
                  : `📤 Átadás küldése — ${parseFloat(sendAmount || '0').toLocaleString('hu-HU')} ${sendCurrency}`}
              </button>
            </div>
          )}

          {/* ÁTVÉTEL TAB */}
          {activeTab === 'receive' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <h2 className="text-lg font-semibold text-gray-700">
                  📥 Bejövő átadások
                </h2>
                <button
                  onClick={() => void fetchData()}
                  disabled={isLoadingPending}
                  className="rounded-lg bg-gray-100 px-3 py-1 text-sm hover:bg-gray-200"
                >
                  🔄 Frissítés
                </button>
              </div>

              {isLoadingPending && (
                <div className="text-center text-gray-400">⏳ Betöltés...</div>
              )}

              {!isLoadingPending && pendingTransfers.length === 0 && (
                <div className="rounded-xl border bg-white p-8 text-center text-gray-400">
                  Nincs bejövő átadás.
                </div>
              )}

              {pendingTransfers.map((transfer) => {
                const info =
                  transfer.currencyCode !== 'HUF'
                    ? getCurrencyInfo(transfer.currencyCode as CurrencyCode)
                    : undefined;
                const isProcessing = processingId === transfer.id;
                return (
                  <div
                    key={transfer.id}
                    className="rounded-xl border bg-white p-4 space-y-3"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-sm text-gray-500">
                          Bizonylat: <span className="font-mono font-semibold">{transfer.receiptNumber}</span>
                        </p>
                        <p className="text-lg font-bold">
                          {info?.flag ?? '🇭🇺'}{' '}
                          {transfer.amount.toLocaleString('hu-HU')} {transfer.currencyCode}
                        </p>
                      </div>
                      <span
                        className={`rounded-full px-3 py-1 text-xs font-medium ${STATUS_COLORS[transfer.status]}`}
                      >
                        {STATUS_LABELS[transfer.status]}
                      </span>
                    </div>

                    <div className="flex gap-4 text-sm text-gray-500">
                      <span>Forrás: Pénztár {transfer.sourceBranchCode}</span>
                      <span>Pénztáros: {transfer.cashierName}</span>
                      <span>
                        {new Date(transfer.createdAt).toLocaleString('hu-HU')}
                      </span>
                    </div>

                    {transfer.note && (
                      <p className="text-sm text-gray-600">
                        💬 {transfer.note}
                      </p>
                    )}

                    {transfer.status === 'PENDING' && (
                      <div className="flex gap-2 pt-2">
                        <button
                          onClick={() => void handleReceive(transfer.id)}
                          disabled={isProcessing}
                          className="btn-primary flex-1 bg-green-600 hover:bg-green-700 disabled:opacity-50"
                        >
                          {isProcessing ? '⏳...' : '✅ Elfogadás'}
                        </button>
                        <button
                          onClick={() => void handleReject(transfer.id)}
                          disabled={isProcessing}
                          className="flex-1 rounded-lg border border-red-300 bg-red-50 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-100 disabled:opacity-50"
                        >
                          {isProcessing ? '⏳...' : '❌ Elutasítás'}
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}


