import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import apiClient from '@/api/client';
import type { Competition, CompetitionEntry, CreateCompetitionRequest } from '@/types';

export default function CompetitionPage() {
  const navigate = useNavigate();
  const { companyType, user } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const isAdmin = user?.role === 'ADMIN' || user?.role === 'MANAGER';

  const [competitions, setCompetitions] = useState<Competition[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [leaderboard, setLeaderboard] = useState<CompetitionEntry[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [showCreate, setShowCreate] = useState(false);
  const [creating, setCreating] = useState(false);

  // Új verseny form
  const [newName, setNewName] = useState('');
  const [newStart, setNewStart] = useState('');
  const [newEnd, setNewEnd] = useState('');
  const [newRules, setNewRules] = useState('');

  const fetchCompetitions = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await apiClient.get<Competition[]>('/competitions');
      setCompetitions(response.data);
    } catch {
      setError('Versenyek betöltése sikertelen.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  const fetchLeaderboard = useCallback(async (id: string) => {
    try {
      const response = await apiClient.get<CompetitionEntry[]>(`/competitions/${id}/leaderboard`);
      setLeaderboard(response.data);
    } catch {
      setError('Rangsor betöltése sikertelen.');
    }
  }, []);

  useEffect(() => {
    void fetchCompetitions();
  }, [fetchCompetitions]);

  useEffect(() => {
    if (selectedId) {
      void fetchLeaderboard(selectedId);
    }
  }, [selectedId, fetchLeaderboard]);

  const handleCreate = async () => {
    if (!newName || !newStart || !newEnd) return;
    setCreating(true);
    try {
      const req: CreateCompetitionRequest = {
        competitionName: newName,
        startDate: newStart,
        endDate: newEnd,
        rules: newRules || undefined,
      };
      await apiClient.post('/competitions', req);
      setShowCreate(false);
      setNewName('');
      setNewStart('');
      setNewEnd('');
      setNewRules('');
      void fetchCompetitions();
    } catch {
      setError('Verseny létrehozás sikertelen.');
    } finally {
      setCreating(false);
    }
  };

  const handleCalculate = async (id: string) => {
    try {
      await apiClient.post(`/competitions/${id}/calculate`);
      void fetchLeaderboard(id);
    } catch {
      setError('Pontszámítás sikertelen.');
    }
  };

  const getRankEmoji = (rank: number): string => {
    if (rank === 1) return '🥇';
    if (rank === 2) return '🥈';
    if (rank === 3) return '🥉';
    return `${rank}.`;
  };

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/menu');
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate]);

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🏆 Pénztáros verseny</h1>
          <div className="flex gap-2">
            {isAdmin && (
              <button onClick={() => setShowCreate(true)}
                className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
                ➕ Új verseny
              </button>
            )}
            <button onClick={() => navigate('/menu')}
              className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
              ← Vissza (ESC)
            </button>
          </div>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-5xl space-y-4">
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">⚠️ {error}</div>
          )}

          {/* Új verseny form */}
          {showCreate && (
            <div className="rounded-xl border bg-white p-4 shadow">
              <h3 className="mb-3 font-semibold text-gray-700">➕ Új verseny indítása</h3>
              <div className="flex flex-wrap gap-3">
                <div>
                  <label className="mb-1 block text-xs text-gray-500">Verseny neve</label>
                  <input type="text" value={newName} onChange={(e) => setNewName(e.target.value)}
                    className="input-field w-60" placeholder="Pl. Tavaszi sprint" />
                </div>
                <div>
                  <label className="mb-1 block text-xs text-gray-500">Kezdés</label>
                  <input type="date" value={newStart} onChange={(e) => setNewStart(e.target.value)}
                    className="input-field" />
                </div>
                <div>
                  <label className="mb-1 block text-xs text-gray-500">Befejezés</label>
                  <input type="date" value={newEnd} onChange={(e) => setNewEnd(e.target.value)}
                    className="input-field" />
                </div>
                <div>
                  <label className="mb-1 block text-xs text-gray-500">Szabályok</label>
                  <input type="text" value={newRules} onChange={(e) => setNewRules(e.target.value)}
                    className="input-field w-60" placeholder="Opcionális" />
                </div>
              </div>
              <div className="mt-3 flex gap-2">
                <button onClick={() => void handleCreate()} disabled={creating}
                  className={`btn-primary ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'}`}>
                  {creating ? '⏳ Mentés...' : '💾 Mentés'}
                </button>
                <button onClick={() => setShowCreate(false)}
                  className="rounded-lg border px-4 py-2 text-sm text-gray-600 hover:bg-gray-50">
                  Mégse
                </button>
              </div>
            </div>
          )}

          {/* Versenyek listája */}
          {isLoading ? (
            <div className="flex items-center justify-center py-20">
              <p className="text-gray-500">⏳ Betöltés...</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              {competitions.map((c) => (
                <div key={c.id}
                  className={`cursor-pointer rounded-xl border p-4 transition ${
                    selectedId === c.id ? 'border-blue-500 bg-blue-50' : 'bg-white hover:border-gray-300'
                  }`}
                  onClick={() => setSelectedId(c.id)}>
                  <div className="flex items-center justify-between">
                    <h3 className="font-semibold text-gray-800">🏆 {c.competitionName}</h3>
                    <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                      c.status === 'ACTIVE' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600'
                    }`}>
                      {c.status === 'ACTIVE' ? '▶️ Aktív' : '✅ Lezárt'}
                    </span>
                  </div>
                  <p className="mt-1 text-sm text-gray-500">
                    {c.startDate} — {c.endDate}
                  </p>
                  {c.rules && (
                    <p className="mt-1 text-xs text-gray-400">📋 {c.rules}</p>
                  )}
                  {isAdmin && c.status === 'ACTIVE' && (
                    <button onClick={(e) => { e.stopPropagation(); void handleCalculate(c.id); }}
                      className="mt-2 rounded bg-blue-100 px-3 py-1 text-xs text-blue-700 hover:bg-blue-200">
                      🔄 Pontok újraszámolása
                    </button>
                  )}
                </div>
              ))}
            </div>
          )}

          {/* Leaderboard */}
          {selectedId && leaderboard.length > 0 && (
            <div className="rounded-xl border bg-white p-4">
              <h3 className="mb-3 font-semibold text-gray-700">🏅 Rangsor</h3>
              <table className="w-full text-sm">
                <thead className="border-b text-left text-gray-500">
                  <tr>
                    <th className="pb-2 pl-4">Helyezés</th>
                    <th className="pb-2">Pénztáros</th>
                    <th className="pb-2 text-right">Forgalom (HUF)</th>
                    <th className="pb-2 text-right">Tranzakciók</th>
                    <th className="pb-2 text-right">Pontszám</th>
                  </tr>
                </thead>
                <tbody>
                  {leaderboard.map((entry) => (
                    <tr key={entry.id} className="border-b last:border-0">
                      <td className="py-2 pl-4 text-lg">{getRankEmoji(entry.rank)}</td>
                      <td className="py-2 font-medium">{entry.workerName}</td>
                      <td className="py-2 text-right font-mono">
                        {entry.totalVolume.toLocaleString('hu-HU')} Ft
                      </td>
                      <td className="py-2 text-right">{entry.transactionCount}</td>
                      <td className="py-2 text-right font-mono font-bold text-blue-600">
                        {entry.score.toLocaleString('hu-HU', { maximumFractionDigits: 1 })}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {selectedId && leaderboard.length === 0 && (
            <div className="py-10 text-center text-gray-400">
              <p>Még nincs rangsor ehhez a versenyhez. Számíttasd ki a pontokat!</p>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
