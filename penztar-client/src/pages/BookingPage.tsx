import { useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import {
  downloadDailyCsv,
  downloadMonthlyCsv,
  downloadInventoryCsv,
} from '@/api/booking';

type BookingType = 'daily' | 'monthly' | 'inventory';

function getTodayStr(): string {
  return new Date().toISOString().slice(0, 10);
}

function getCurrentYearMonth(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

function downloadBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

export default function BookingPage() {
  const navigate = useNavigate();
  const { user } = useAuthStore();

  const [bookingType, setBookingType] = useState<BookingType>('daily');
  const [branchId, setBranchId] = useState('');
  const [date, setDate] = useState(getTodayStr());
  const [month, setMonth] = useState(getCurrentYearMonth());
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleDownload = useCallback(async () => {
    if (!branchId) {
      setError('Kérjük, adja meg az iroda azonosítót!');
      return;
    }
    setLoading(true);
    setError('');
    setSuccess('');
    try {
      let blob: Blob;
      let filename: string;

      switch (bookingType) {
        case 'daily':
          blob = await downloadDailyCsv(branchId, date);
          filename = `konyveles-napi-${date}.csv`;
          break;
        case 'monthly':
          blob = await downloadMonthlyCsv(branchId, month);
          filename = `konyveles-havi-${month}.csv`;
          break;
        case 'inventory':
          blob = await downloadInventoryCsv(branchId, date);
          filename = `keszlet-${date}.csv`;
          break;
      }

      downloadBlob(blob, filename);
      setSuccess(`Fájl letöltve: ${filename}`);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Hiba a letöltés során';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [branchId, bookingType, date, month]);

  const BOOKING_TYPES: { key: BookingType; label: string; icon: string }[] = [
    { key: 'daily', label: 'Napi könyvelés', icon: '📅' },
    { key: 'monthly', label: 'Havi könyvelés', icon: '📊' },
    { key: 'inventory', label: 'Készlet kimutatás', icon: '📦' },
  ];

  return (
    <div className="flex h-screen flex-col">
      <header className="bg-teal-600 px-6 py-4 text-white shadow-lg">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">📑 Könyvelési export</h1>
            <p className="text-sm text-white/80">
              {user?.fullName ?? 'Felhasználó'} | CSV export napi/havi bontásban
            </p>
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
        <div className="mx-auto max-w-3xl space-y-6">
          {/* Típus választó */}
          <div className="grid grid-cols-3 gap-4">
            {BOOKING_TYPES.map((bt) => (
              <button
                key={bt.key}
                onClick={() => setBookingType(bt.key)}
                className={`rounded-lg border-2 p-4 text-center transition ${
                  bookingType === bt.key
                    ? 'border-teal-500 bg-teal-50'
                    : 'border-gray-200 bg-white hover:border-teal-300'
                }`}
              >
                <span className="text-2xl">{bt.icon}</span>
                <div className="mt-1 text-sm font-medium">{bt.label}</div>
              </button>
            ))}
          </div>

          {/* Szűrők */}
          <div className="rounded-lg border bg-white p-4 shadow-sm">
            <div className="flex flex-wrap items-end gap-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700">Iroda ID</label>
                <input
                  type="text"
                  value={branchId}
                  onChange={(e) => setBranchId(e.target.value)}
                  placeholder="pl. 550e8400-e29b-..."
                  className="w-72 rounded border px-3 py-2 text-sm"
                />
              </div>
              {bookingType === 'monthly' ? (
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">Hónap</label>
                  <input
                    type="month"
                    value={month}
                    onChange={(e) => setMonth(e.target.value)}
                    className="rounded border px-3 py-2 text-sm"
                  />
                </div>
              ) : (
                <div>
                  <label className="mb-1 block text-sm font-medium text-gray-700">Dátum</label>
                  <input
                    type="date"
                    value={date}
                    onChange={(e) => setDate(e.target.value)}
                    className="rounded border px-3 py-2 text-sm"
                  />
                </div>
              )}
            </div>
          </div>

          {/* Letöltés gombok */}
          <div className="flex gap-4">
            <button
              onClick={() => void handleDownload()}
              disabled={loading || !branchId}
              className="flex-1 rounded-lg bg-teal-500 px-6 py-3 text-sm font-bold text-white hover:bg-teal-600 disabled:opacity-50"
            >
              📥 Letöltés CSV
            </button>
          </div>

          {error && (
            <div className="rounded-lg border border-red-200 bg-red-50 p-3 text-sm text-red-700">
              ⚠️ {error}
            </div>
          )}
          {success && (
            <div className="rounded-lg border border-green-200 bg-green-50 p-3 text-sm text-green-700">
              ✅ {success}
            </div>
          )}

          {/* Info */}
          <div className="rounded-lg border bg-gray-50 p-4 text-sm text-gray-600">
            <h3 className="mb-2 font-semibold">ℹ️ Formátum információ</h3>
            <ul className="list-inside list-disc space-y-1">
              <li>UTF-8 kódolás BOM-mal (Excel kompatibilis)</li>
              <li>Pontosvessző (;) szeparátor</li>
              <li>Napi: bizonylat-szintű részletezés</li>
              <li>Havi: az adott hónap összes tranzakciója</li>
              <li>Készlet: valutánkénti készlet összesítő</li>
            </ul>
          </div>
        </div>
      </main>
    </div>
  );
}
