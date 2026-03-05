import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  getPendingTrades,
  getTradeHistory,
  proposeTrade,
  acceptTrade,
  rejectTrade,
  completeTrade,
  cancelTrade,
  type TradeDto,
} from '@/api/trades';

type Tab = 'pending' | 'new' | 'history';

export default function TradePage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [tab, setTab] = useState<Tab>('pending');
  const [pending, setPending] = useState<TradeDto[]>([]);
  const [history, setHistory] = useState<TradeDto[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Form state
  const [toBranchId, setToBranchId] = useState('');
  const [currencyCode, setCurrencyCode] = useState('EUR');
  const [amount, setAmount] = useState('');
  const [rate, setRate] = useState('1');
  const [notes, setNotes] = useState('');

  // History filters
  const [histFrom, setHistFrom] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() - 30);
    return d.toISOString().slice(0, 10);
  });
  const [histTo, setHistTo] = useState(() => new Date().toISOString().slice(0, 10));

  const loadPending = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getPendingTrades();
      setPending(data);
    } catch {
      setError('Nem sikerült betölteni a függő ajánlatokat.');
    } finally {
      setLoading(false);
    }
  }, []);

  const loadHistory = useCallback(async () => {
    setLoading(true);
    try {
      const res = await getTradeHistory(histFrom, histTo);
      setHistory(res.content);
    } catch {
      setError('Nem sikerült betölteni a történetet.');
    } finally {
      setLoading(false);
    }
  }, [histFrom, histTo]);

  useEffect(() => {
    void loadPending();
  }, [loadPending]);

  useEffect(() => {
    if (tab === 'history') {
      void loadHistory();
    }
  }, [tab, loadHistory]);

  const handlePropose = async () => {
    if (!toBranchId || !amount) {
      setError('Cél iroda és összeg kötelező!');
      return;
    }
    setError('');
    setSuccess('');
    try {
      await proposeTrade({
        fromBranchId: '', // Backend uses SecurityUtils
        toBranchId,
        currencyCode,
        amount: parseFloat(amount),
        rate: parseFloat(rate) || 1,
        notes: notes || undefined,
      });
      setSuccess('✅ Trade ajánlat elküldve!');
      setToBranchId('');
      setAmount('');
      setNotes('');
      void loadPending();
      setTab('pending');
    } catch {
      setError('Ajánlat küldése sikertelen.');
    }
  };

  const handleAction = async (id: string, action: 'accept' | 'reject' | 'complete' | 'cancel') => {
    setError('');
    setSuccess('');
    try {
      if (action === 'accept') await acceptTrade(id);
      else if (action === 'reject') await rejectTrade(id, 'Elutasítva');
      else if (action === 'complete') await completeTrade(id);
      else if (action === 'cancel') await cancelTrade(id);
      setSuccess(`✅ Trade ${action === 'accept' ? 'elfogadva' : action === 'reject' ? 'elutasítva' : action === 'complete' ? 'teljesítve' : 'törölve'}!`);
      void loadPending();
    } catch {
      setError(`Trade ${action} sikertelen.`);
    }
  };

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const statusBadge = (status: string) => {
    const colors: Record<string, string> = {
      PROPOSED: 'bg-yellow-100 text-yellow-800',
      ACCEPTED: 'bg-blue-100 text-blue-800',
      REJECTED: 'bg-red-100 text-red-800',
      COMPLETED: 'bg-green-100 text-green-800',
      CANCELLED: 'bg-gray-100 text-gray-800',
    };
    return (
      <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${colors[status] ?? 'bg-gray-100'}`}>
        {status}
      </span>
    );
  };

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🔄 Devizakereskedés (Trade)</h1>
          <button onClick={() => navigate('/menu')} className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-4xl">
          {/* Tab bar */}
          <div className="mb-4 flex gap-2">
            {(['pending', 'new', 'history'] as Tab[]).map((t) => (
              <button
                key={t}
                onClick={() => setTab(t)}
                className={`rounded-lg px-4 py-2 text-sm font-medium transition ${
                  tab === t ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {t === 'pending' ? '📋 Függő ajánlatok' : t === 'new' ? '➕ Új ajánlat' : '📜 Történet'}
              </button>
            ))}
          </div>

          {error && <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">⚠️ {error}</div>}
          {success && <div className="mb-4 rounded-lg bg-green-50 p-3 text-sm text-green-700">{success}</div>}

          {/* Pending trades */}
          {tab === 'pending' && (
            <div className="rounded-xl border bg-white p-6">
              <h2 className="mb-4 text-lg font-semibold">📋 Függő ajánlatok</h2>
              {loading ? (
                <p className="text-gray-500">⏳ Betöltés...</p>
              ) : pending.length === 0 ? (
                <p className="text-gray-400">Nincsenek függő ajánlatok.</p>
              ) : (
                <div className="space-y-3">
                  {pending.map((t) => (
                    <div key={t.id} className="flex items-center justify-between rounded-lg border p-4">
                      <div>
                        <div className="font-medium">
                          {t.fromBranchName} → {t.toBranchName}
                        </div>
                        <div className="text-sm text-gray-500">
                          {t.amount.toLocaleString()} {t.currencyCode} | Árfolyam: {t.rate}
                        </div>
                        {t.notes && <div className="text-xs text-gray-400 mt-1">{t.notes}</div>}
                        <div className="text-xs text-gray-400">{new Date(t.proposedAt).toLocaleString('hu-HU')}</div>
                      </div>
                      <div className="flex items-center gap-2">
                        {statusBadge(t.status)}
                        {t.status === 'PROPOSED' && (
                          <>
                            <button
                              onClick={() => void handleAction(t.id, 'accept')}
                              className="rounded bg-green-500 px-3 py-1 text-xs text-white hover:bg-green-600"
                            >
                              ✅ Elfogad
                            </button>
                            <button
                              onClick={() => void handleAction(t.id, 'reject')}
                              className="rounded bg-red-500 px-3 py-1 text-xs text-white hover:bg-red-600"
                            >
                              ❌ Elutasít
                            </button>
                          </>
                        )}
                        {t.status === 'ACCEPTED' && (
                          <button
                            onClick={() => void handleAction(t.id, 'complete')}
                            className="rounded bg-blue-500 px-3 py-1 text-xs text-white hover:bg-blue-600"
                          >
                            🏁 Teljesít
                          </button>
                        )}
                        {(t.status === 'PROPOSED' || t.status === 'ACCEPTED') && (
                          <button
                            onClick={() => void handleAction(t.id, 'cancel')}
                            className="rounded bg-gray-400 px-3 py-1 text-xs text-white hover:bg-gray-500"
                          >
                            🗑️ Töröl
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* New trade form */}
          {tab === 'new' && (
            <div className="rounded-xl border bg-white p-6">
              <h2 className="mb-4 text-lg font-semibold">➕ Új trade ajánlat</h2>
              <div className="space-y-4">
                <div>
                  <label className="mb-1 block text-sm text-gray-500">Cél iroda (UUID)</label>
                  <input
                    type="text"
                    value={toBranchId}
                    onChange={(e) => setToBranchId(e.target.value)}
                    className="input-field"
                    placeholder="Cél iroda ID"
                  />
                </div>
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="mb-1 block text-sm text-gray-500">Valuta</label>
                    <select value={currencyCode} onChange={(e) => setCurrencyCode(e.target.value)} className="input-field">
                      {['EUR', 'USD', 'GBP', 'CHF', 'CZK', 'PLN', 'RON', 'HRK', 'RSD', 'BAM', 'UAH', 'TRY'].map((c) => (
                        <option key={c} value={c}>{c}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="mb-1 block text-sm text-gray-500">Összeg</label>
                    <input
                      type="number"
                      value={amount}
                      onChange={(e) => setAmount(e.target.value)}
                      className="input-field"
                      placeholder="0.00"
                    />
                  </div>
                  <div>
                    <label className="mb-1 block text-sm text-gray-500">Árfolyam</label>
                    <input
                      type="number"
                      value={rate}
                      onChange={(e) => setRate(e.target.value)}
                      className="input-field"
                      step="0.01"
                    />
                  </div>
                </div>
                <div>
                  <label className="mb-1 block text-sm text-gray-500">Megjegyzés</label>
                  <textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    className="input-field"
                    rows={2}
                  />
                </div>
                <button
                  onClick={() => void handlePropose()}
                  className={`btn-primary w-full ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'}`}
                >
                  📤 Ajánlat küldése
                </button>
              </div>
            </div>
          )}

          {/* History */}
          {tab === 'history' && (
            <div className="rounded-xl border bg-white p-6">
              <h2 className="mb-4 text-lg font-semibold">📜 Trade történet</h2>
              <div className="mb-4 flex gap-4">
                <div>
                  <label className="mb-1 block text-xs text-gray-500">Dátumtól</label>
                  <input type="date" value={histFrom} onChange={(e) => setHistFrom(e.target.value)} className="input-field" />
                </div>
                <div>
                  <label className="mb-1 block text-xs text-gray-500">Dátumig</label>
                  <input type="date" value={histTo} onChange={(e) => setHistTo(e.target.value)} className="input-field" />
                </div>
              </div>
              {loading ? (
                <p className="text-gray-500">⏳ Betöltés...</p>
              ) : history.length === 0 ? (
                <p className="text-gray-400">Nincs trade az adott időszakban.</p>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b text-left text-gray-500">
                        <th className="py-2">Dátum</th>
                        <th>Honnan</th>
                        <th>Hová</th>
                        <th>Valuta</th>
                        <th className="text-right">Összeg</th>
                        <th>Státusz</th>
                      </tr>
                    </thead>
                    <tbody>
                      {history.map((t) => (
                        <tr key={t.id} className="border-b hover:bg-gray-50">
                          <td className="py-2">{new Date(t.proposedAt).toLocaleDateString('hu-HU')}</td>
                          <td>{t.fromBranchName}</td>
                          <td>{t.toBranchName}</td>
                          <td>{t.currencyCode}</td>
                          <td className="text-right">{t.amount.toLocaleString()}</td>
                          <td>{statusBadge(t.status)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
