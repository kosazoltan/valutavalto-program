import { useState, useCallback, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { login } from '@/api/auth';

export default function LoginPage() {
  const navigate = useNavigate();
  const { setBranchCode, setAuth, branchCode, companyType } = useAuthStore();

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [localBranchCode, setLocalBranchCode] = useState(branchCode);
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const isBestChange = companyType === 'BEST_CHANGE';
  const companyName = isBestChange
    ? 'Best Change'
    : 'Expressz Ékszerház';
  const accentColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const accentHover = isBestChange ? 'hover:bg-red-700' : 'hover:bg-orange-600';

  const handleBranchCodeChange = useCallback(
    (value: string) => {
      setLocalBranchCode(value);
      if (value.length >= 2) {
        setBranchCode(value);
      }
    },
    [setBranchCode],
  );

  const handleSubmit = useCallback(
    async (e: FormEvent) => {
      e.preventDefault();
      setError('');
      setIsLoading(true);

      try {
        const response = await login({
          branchCode: localBranchCode,
          username,
          password,
        });
        setAuth(response.user, response.token, response.refreshToken);
        navigate('/menu');
      } catch (err) {
        if (err instanceof Error) {
          setError('Hibás felhasználónév vagy jelszó');
        } else {
          setError('Kapcsolódási hiba. Ellenőrizze a hálózatot.');
        }
      } finally {
        setIsLoading(false);
      }
    },
    [localBranchCode, username, password, setAuth, navigate],
  );

  return (
    <div className="flex h-screen items-center justify-center bg-gradient-to-br from-gray-100 to-gray-200">
      <div className="w-full max-w-md rounded-2xl bg-white p-8 shadow-2xl">
        {/* Cég logó / fejléc */}
        <div className={`-mx-8 -mt-8 mb-8 rounded-t-2xl ${accentColor} px-8 py-6`}>
          <h1 className="text-center text-3xl font-bold text-white">
            {isBestChange ? '💱' : '💎'} {companyName}
          </h1>
          <p className="mt-1 text-center text-sm text-white/80">
            Valutaváltó Pénztár
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Pénztár kód */}
          <div>
            <label
              htmlFor="branchCode"
              className="mb-1 block text-sm font-medium text-gray-700"
            >
              Pénztár kód
            </label>
            <input
              id="branchCode"
              type="text"
              value={localBranchCode}
              onChange={(e) => handleBranchCodeChange(e.target.value)}
              className="input-field"
              placeholder="pl. 101"
              required
              autoFocus
            />
          </div>

          {/* Felhasználónév */}
          <div>
            <label
              htmlFor="username"
              className="mb-1 block text-sm font-medium text-gray-700"
            >
              Felhasználónév
            </label>
            <input
              id="username"
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className="input-field"
              placeholder="Felhasználónév"
              required
            />
          </div>

          {/* Jelszó */}
          <div>
            <label
              htmlFor="password"
              className="mb-1 block text-sm font-medium text-gray-700"
            >
              Jelszó
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="input-field"
              placeholder="Jelszó"
              required
            />
          </div>

          {/* Hibaüzenet */}
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">
              ⚠️ {error}
            </div>
          )}

          {/* Bejelentkezés gomb */}
          <button
            type="submit"
            disabled={isLoading}
            className={`btn-primary w-full ${accentColor} ${accentHover} disabled:opacity-50`}
          >
            {isLoading ? '⏳ Bejelentkezés...' : '🔑 Bejelentkezés'}
          </button>
        </form>

        {/* Verzió */}
        <p className="mt-6 text-center text-xs text-gray-400">
          Valuta Pénztár v1.0.0 — Pénztár: {localBranchCode}
        </p>
      </div>
    </div>
  );
}
