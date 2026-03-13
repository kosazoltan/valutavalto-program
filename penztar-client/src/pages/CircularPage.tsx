import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import apiClient from '@/api/client';
import type { Circular } from '@/types';

export default function CircularPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const [circulars, setCirculars] = useState<Circular[]>([]);
  const [selectedCircular, setSelectedCircular] = useState<Circular | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isAcknowledging, setIsAcknowledging] = useState(false);
  const [error, setError] = useState('');

  const fetchCirculars = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const response = await apiClient.get<Circular[]>('/circulars');
      setCirculars(response.data);
    } catch {
      console.error('[CircularPage] Betöltési hiba:', err);
      setError('Körlevelek betöltése sikertelen.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchCirculars();
  }, [fetchCirculars]);

  const handleAcknowledge = useCallback(async (id: number) => {
    if (isAcknowledging) return;
    setIsAcknowledging(true);
    try {
      await apiClient.post(`/circulars/${id}/acknowledge`);
      setCirculars((prev) =>
        prev.map((c) =>
          c.id === id ? { ...c, acknowledged: true, acknowledgedAt: new Date().toISOString() } : c,
        ),
      );
      if (selectedCircular?.id === id) {
        setSelectedCircular((prev) =>
          prev ? { ...prev, acknowledged: true, acknowledgedAt: new Date().toISOString() } : null,
        );
      }
    } catch {
      console.error('[CircularPage] Tudomásul vétel hiba:', err);
      setError('Tudomásul vétel sikertelen. Próbálja újra.');
    } finally {
      setIsAcknowledging(false);
    }
  }, [isAcknowledging, selectedCircular]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (selectedCircular) {
          setSelectedCircular(null);
        } else {
          navigate('/menu');
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate, selectedCircular]);

  const unreadCount = circulars.filter((c) => !c.acknowledged).length;

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">
            📨 Körlevél
            {unreadCount > 0 && (
              <span className="ml-2 rounded-full bg-yellow-400 px-2 py-0.5 text-xs font-bold text-black">
                {unreadCount}
              </span>
            )}
          </h1>
          <button
            onClick={() => selectedCircular ? setSelectedCircular(null) : navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← {selectedCircular ? 'Vissza a listához' : 'Vissza (ESC)'}
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        {error && (
          <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
            ⚠️ {error}
          </div>
        )}

        {isLoading ? (
          <div className="flex items-center justify-center py-20">
            <p className="text-gray-500">⏳ Körlevelek betöltése...</p>
          </div>
        ) : selectedCircular ? (
          /* Körlevél részletes nézet */
          <div className="mx-auto max-w-3xl">
            <div className="rounded-xl border bg-white p-6 shadow-sm">
              <div className="mb-4 border-b pb-4">
                <h2 className="text-xl font-bold text-gray-800">{selectedCircular.subject}</h2>
                <div className="mt-2 flex items-center gap-4 text-sm text-gray-500">
                  <span>👤 {selectedCircular.sender}</span>
                  <span>📅 {new Date(selectedCircular.sentAt).toLocaleDateString('hu-HU')}</span>
                  {selectedCircular.acknowledged ? (
                    <span className="text-green-600">✅ Tudomásul véve</span>
                  ) : (
                    <span className="text-orange-600">⏳ Olvasatlan</span>
                  )}
                </div>
              </div>
              <div className="prose prose-sm max-w-none whitespace-pre-wrap text-gray-700">
                {selectedCircular.body}
              </div>
              {!selectedCircular.acknowledged && (
                <div className="mt-6 border-t pt-4">
                  <button
                    onClick={() => void handleAcknowledge(selectedCircular.id)}
                    disabled={isAcknowledging}
                    className={`btn-primary ${isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600'} disabled:opacity-50`}
                  >
                    {isAcknowledging ? '⏳ Feldolgozás...' : '✅ Tudomásul vettem'}
                  </button>
                </div>
              )}
            </div>
          </div>
        ) : (
          /* Körlevél lista */
          <div className="mx-auto max-w-3xl space-y-2">
            {circulars.length === 0 ? (
              <div className="py-20 text-center text-gray-400">
                <p className="text-4xl">📭</p>
                <p className="mt-2">Nincsenek körlevelek.</p>
              </div>
            ) : (
              circulars.map((circular) => (
                <button
                  key={circular.id}
                  onClick={() => setSelectedCircular(circular)}
                  className={`w-full rounded-xl border p-4 text-left transition hover:bg-gray-50 ${
                    !circular.acknowledged ? 'border-l-4 border-l-blue-500 bg-blue-50/50' : 'bg-white'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className={`font-semibold ${!circular.acknowledged ? 'text-blue-900' : 'text-gray-700'}`}>
                        {!circular.acknowledged && '🔵 '}
                        {circular.subject}
                      </h3>
                      <p className="mt-1 text-sm text-gray-500">
                        {circular.sender} — {new Date(circular.sentAt).toLocaleDateString('hu-HU')}
                      </p>
                    </div>
                    {circular.acknowledged && (
                      <span className="text-xs text-green-600">✅</span>
                    )}
                  </div>
                </button>
              ))
            )}
          </div>
        )}
      </main>
    </div>
  );
}

