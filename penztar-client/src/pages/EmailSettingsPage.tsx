import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  getEmailAccounts,
  createEmailAccount,
  updateEmailAccount,
  deleteEmailAccount,
  startOAuthFlow,
} from '@/api/email';
import type { EmailAccount } from '@/types/email';

const ALLOWED_ROLES = ['CHIEF_VAULT', 'REGIONAL_MGR', 'DIRECTOR'];

export default function EmailSettingsPage() {
  const navigate = useNavigate();
  const { companyType, activeRole } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [accounts, setAccounts] = useState<EmailAccount[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Új fiók form
  const [showNewForm, setShowNewForm] = useState(false);
  const [newGmailAddress, setNewGmailAddress] = useState('');
  const [newDisplayName, setNewDisplayName] = useState('');
  const [creating, setCreating] = useState(false);

  // Szerkesztés
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editDisplayName, setEditDisplayName] = useState('');

  const canManage = activeRole ? ALLOWED_ROLES.includes(activeRole) : false;

  const loadAccounts = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getEmailAccounts();
      setAccounts(data);
    } catch {
      setError('Nem sikerült betölteni az email fiókokat.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadAccounts();
  }, [loadAccounts]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/email');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  const handleCreateAccount = useCallback(async () => {
    if (!newGmailAddress.trim()) {
      setError('Gmail cím megadása kötelező!');
      return;
    }
    setCreating(true);
    setError('');
    try {
      const created = await createEmailAccount({
        gmailAddress: newGmailAddress.trim(),
        displayName: newDisplayName.trim() || undefined,
        isActive: true,
      });
      setSuccess('Fiók létrehozva! OAuth hitelesítés indítása...');
      setShowNewForm(false);
      setNewGmailAddress('');
      setNewDisplayName('');
      await loadAccounts();

      // OAuth flow indítás
      const { authUrl } = await startOAuthFlow(created.id);
      window.location.href = authUrl;
    } catch {
      setError('Nem sikerült létrehozni az email fiókot.');
    } finally {
      setCreating(false);
    }
  }, [newGmailAddress, newDisplayName, loadAccounts]);

  const handleSaveDisplayName = useCallback(
    async (accountId: string) => {
      setError('');
      try {
        const account = accounts.find((a) => a.id === accountId);
        if (!account) return;
        await updateEmailAccount(accountId, {
          ...account,
          displayName: editDisplayName.trim() || undefined,
        });
        setEditingId(null);
        setSuccess('Megjelenítési név frissítve!');
        await loadAccounts();
      } catch {
        setError('Nem sikerült frissíteni a megjelenítési nevet.');
      }
    },
    [editDisplayName, accounts, loadAccounts],
  );

  const handleToggleActive = useCallback(
    async (account: EmailAccount) => {
      setError('');
      try {
        await updateEmailAccount(account.id, {
          ...account,
          isActive: !account.isActive,
        });
        setSuccess(
          account.isActive ? 'Fiók deaktiválva.' : 'Fiók aktiválva.',
        );
        await loadAccounts();
      } catch {
        setError('Nem sikerült módosítani a fiók állapotát.');
      }
    },
    [loadAccounts],
  );

  const handleDeleteAccount = useCallback(
    async (accountId: string) => {
      if (!window.confirm('Biztosan törli ezt az email fiókot? Ez a művelet nem vonható vissza!')) return;
      setError('');
      try {
        await deleteEmailAccount(accountId);
        setSuccess('Email fiók törölve!');
        await loadAccounts();
      } catch {
        setError('Nem sikerült törölni az email fiókot.');
      }
    },
    [loadAccounts],
  );

  const formatDate = (dateStr?: string) => {
    if (!dateStr) return 'Nincs adat';
    try {
      return new Date(dateStr).toLocaleString('hu-HU');
    } catch {
      return dateStr;
    }
  };

  const getOrgLabel = (account: EmailAccount) => {
    if (account.branchId) return `🏦 Pénztár (branch: ${account.branchId})`;
    if (account.vaultTerritoryId)
      return `🏛️ Értéktári terület (#${account.vaultTerritoryId})`;
    if (account.ownCompanyId) return `🏢 Saját cég (${account.ownCompanyId})`;
    if (account.workerId) return `👤 Személyes (worker #${account.workerId})`;
    return '—';
  };

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">⚙️ Email beállítások</h1>
          <button
            onClick={() => navigate('/email')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-2xl">
          {!canManage && (
            <div className="mb-6 rounded-lg border border-yellow-200 bg-yellow-50 p-4">
              <p className="text-sm text-yellow-800">
                ⚠️ Email fiókok kezeléséhez Értéktárvezető, Területi vezető
                vagy Igazgató jogosultság szükséges.
              </p>
            </div>
          )}

          {error && (
            <div className="mb-6 rounded-lg border border-red-200 bg-red-50 p-4">
              <p className="text-sm text-red-800">{error}</p>
              <button
                onClick={() => setError('')}
                className="mt-1 text-xs text-red-500 underline"
              >
                Bezárás
              </button>
            </div>
          )}

          {success && (
            <div className="mb-6 rounded-lg border border-green-200 bg-green-50 p-4">
              <p className="text-sm text-green-800">{success}</p>
              <button
                onClick={() => setSuccess('')}
                className="mt-1 text-xs text-green-500 underline"
              >
                Bezárás
              </button>
            </div>
          )}

          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-500 border-t-transparent" />
            </div>
          ) : accounts.length === 0 && !showNewForm ? (
            <div className="py-12 text-center">
              <p className="mb-4 text-lg text-gray-600">
                Nincs csatlakoztatott email fiók
              </p>
              {canManage && (
                <button
                  onClick={() => setShowNewForm(true)}
                  className="rounded-lg bg-blue-600 px-6 py-3 text-white transition-colors hover:bg-blue-700"
                >
                  📧 Új Gmail fiók hozzáadása
                </button>
              )}
            </div>
          ) : (
            <div className="space-y-4">
              <h2 className="text-lg font-semibold text-gray-900">
                Csatlakoztatott fiókok
              </h2>

              {accounts.map((account) => (
                <div
                  key={account.id}
                  className={`rounded-lg border p-4 ${
                    account.isActive
                      ? 'border-gray-200 bg-white'
                      : 'border-gray-100 bg-gray-50 opacity-60'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <p className="font-medium text-gray-900">
                        {account.gmailAddress}
                      </p>

                      {/* Display name — szerkesztés */}
                      {editingId === account.id ? (
                        <div className="mt-1 flex items-center gap-2">
                          <input
                            type="text"
                            value={editDisplayName}
                            onChange={(e) => setEditDisplayName(e.target.value)}
                            placeholder="Megjelenítési név"
                            className="rounded border border-gray-300 px-2 py-1 text-sm"
                            autoFocus
                            onKeyDown={(e) => {
                              if (e.key === 'Enter')
                                void handleSaveDisplayName(account.id);
                              if (e.key === 'Escape') setEditingId(null);
                            }}
                          />
                          <button
                            onClick={() =>
                              void handleSaveDisplayName(account.id)
                            }
                            className="text-sm text-blue-600 hover:underline"
                          >
                            Mentés
                          </button>
                          <button
                            onClick={() => setEditingId(null)}
                            className="text-sm text-gray-400 hover:underline"
                          >
                            Mégse
                          </button>
                        </div>
                      ) : (
                        <p className="text-sm text-gray-500">
                          {account.displayName ?? 'Nincs megjelenítési név'}
                          {canManage && (
                            <button
                              onClick={() => {
                                setEditingId(account.id);
                                setEditDisplayName(
                                  account.displayName ?? '',
                                );
                              }}
                              className="ml-2 text-xs text-blue-500 hover:underline"
                            >
                              ✏️ Szerkesztés
                            </button>
                          )}
                        </p>
                      )}

                      {/* Állapot */}
                      <p className="mt-1 text-xs text-gray-400">
                        Állapot:{' '}
                        {account.isActive ? (
                          <span className="text-green-600">✅ Aktív</span>
                        ) : (
                          <span className="text-red-600">❌ Inaktív</span>
                        )}
                      </p>

                      {/* Szervezeti egység */}
                      <p className="mt-0.5 text-xs text-gray-400">
                        Hozzárendelés: {getOrgLabel(account)}
                      </p>

                      {/* Utolsó szinkronizáció */}
                      <p className="mt-0.5 text-xs text-gray-400">
                        Utolsó szinkronizáció:{' '}
                        {formatDate(account.lastSyncAt)}
                      </p>
                    </div>

                    {canManage && (
                      <div className="ml-4 flex flex-col gap-2">
                        <button
                          onClick={() => void handleToggleActive(account)}
                          className={`rounded-lg px-3 py-1.5 text-sm transition-colors ${
                            account.isActive
                              ? 'bg-yellow-100 text-yellow-700 hover:bg-yellow-200'
                              : 'bg-green-100 text-green-700 hover:bg-green-200'
                          }`}
                        >
                          {account.isActive ? '⏸️ Deaktiválás' : '▶️ Aktiválás'}
                        </button>
                        <button
                          onClick={async () => {
                            try {
                              const { authUrl } = await startOAuthFlow(
                                account.id,
                              );
                              window.location.href = authUrl;
                            } catch {
                              setError('OAuth hiba.');
                            }
                          }}
                          className="rounded-lg bg-gray-100 px-3 py-1.5 text-sm text-gray-700 transition-colors hover:bg-gray-200"
                        >
                          🔄 Újrahitelesítés
                        </button>
                        <button
                          onClick={() => void handleDeleteAccount(account.id)}
                          className="rounded-lg bg-red-100 px-3 py-1.5 text-sm text-red-700 transition-colors hover:bg-red-200"
                        >
                          🗑️ Törlés
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              ))}

              {/* Új fiók form */}
              {showNewForm && canManage && (
                <div className="rounded-lg border-2 border-dashed border-blue-300 bg-blue-50 p-4">
                  <h3 className="mb-3 font-medium text-blue-800">
                    Új Gmail fiók hozzáadása
                  </h3>
                  <div className="space-y-3">
                    <div>
                      <label className="mb-1 block text-sm font-medium text-gray-700">
                        Gmail cím *
                      </label>
                      <input
                        type="email"
                        value={newGmailAddress}
                        onChange={(e) => setNewGmailAddress(e.target.value)}
                        placeholder="pelda@gmail.com"
                        className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
                      />
                    </div>
                    <div>
                      <label className="mb-1 block text-sm font-medium text-gray-700">
                        Megjelenítési név
                      </label>
                      <input
                        type="text"
                        value={newDisplayName}
                        onChange={(e) => setNewDisplayName(e.target.value)}
                        placeholder="pl. Központi iroda"
                        className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:outline-none"
                      />
                    </div>
                    <div className="flex gap-2">
                      <button
                        onClick={() => void handleCreateAccount()}
                        disabled={creating}
                        className="rounded-lg bg-blue-600 px-4 py-2 text-sm text-white transition-colors hover:bg-blue-700 disabled:opacity-50"
                      >
                        {creating ? '⏳ Létrehozás...' : '✅ Létrehozás és hitelesítés'}
                      </button>
                      <button
                        onClick={() => {
                          setShowNewForm(false);
                          setNewGmailAddress('');
                          setNewDisplayName('');
                        }}
                        className="rounded-lg bg-gray-200 px-4 py-2 text-sm text-gray-700 transition-colors hover:bg-gray-300"
                      >
                        Mégse
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {canManage && !showNewForm && (
                <button
                  onClick={() => setShowNewForm(true)}
                  className="mt-4 rounded-lg bg-blue-600 px-4 py-2 text-sm text-white transition-colors hover:bg-blue-700"
                >
                  + Új Gmail fiók hozzáadása
                </button>
              )}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
