import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { getEmailAccounts, startOAuthFlow } from '@/api/email';
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

  const handleAddAccount = useCallback(async () => {
    try {
      // Először kell egy fiók — ha nincs, létrehozunk egyet
      let accountId: string;
      if (accounts.length > 0) {
        accountId = accounts[0]!.id;
      } else {
        // Az OAuth flow fogja létrehozni a fiókot a backend oldalon
        // Használjuk az első lépést: üres accountId-val nem megy,
        // ezért a backend-nek kell kezelnie az account létrehozást
        setError('Kérem vegye fel a kapcsolatot az adminisztrátorral az email fiók létrehozásához.');
        return;
      }
      const { authUrl } = await startOAuthFlow(accountId);
      window.location.href = authUrl;
    } catch {
      setError('Nem sikerült elindítani az OAuth hitelesítést.');
    }
  }, [accounts]);

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
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6">
              <p className="text-sm text-yellow-800">
                ⚠️ Email fiókok kezeléséhez Értéktárvezető, Területi vezető vagy
                Igazgató jogosultság szükséges.
              </p>
            </div>
          )}

          {error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
              <p className="text-sm text-red-800">{error}</p>
            </div>
          )}

          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin h-8 w-8 border-4 border-blue-500 border-t-transparent rounded-full" />
            </div>
          ) : accounts.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-lg text-gray-600 mb-4">
                Nincs csatlakoztatott email fiók
              </p>
              {canManage && (
                <button
                  onClick={handleAddAccount}
                  className="px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  📧 Gmail fiók hozzáadása
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
                  className="bg-white border border-gray-200 rounded-lg p-4 flex items-center justify-between"
                >
                  <div>
                    <p className="font-medium text-gray-900">
                      {account.gmailAddress}
                    </p>
                    {account.displayName && (
                      <p className="text-sm text-gray-500">
                        {account.displayName}
                      </p>
                    )}
                    <p className="text-xs text-gray-400 mt-1">
                      Állapot:{' '}
                      {account.isActive ? (
                        <span className="text-green-600">✅ Aktív</span>
                      ) : (
                        <span className="text-red-600">❌ Inaktív</span>
                      )}
                    </p>
                  </div>
                  {canManage && (
                    <div className="flex gap-2">
                      <button
                        onClick={async () => {
                          try {
                            const { authUrl } = await startOAuthFlow(account.id);
                            window.location.href = authUrl;
                          } catch {
                            setError('OAuth hiba.');
                          }
                        }}
                        className="px-3 py-1.5 text-sm bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                      >
                        🔄 Újrahitelesítés
                      </button>
                    </div>
                  )}
                </div>
              ))}

              {canManage && (
                <button
                  onClick={handleAddAccount}
                  className="mt-4 px-4 py-2 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
                >
                  + Gmail fiók hozzáadása
                </button>
              )}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
