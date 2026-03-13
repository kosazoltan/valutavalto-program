import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { toast } from '@/hooks/useToast';
import { checkStorno, executeStorno } from '@/api/stornos';
import { getCurrencyInfo } from '@/utils/currencies';
import { generateQRCode } from '@/utils/qrcode';
import ReceiptPreviewModal from '@/components/ReceiptPreviewModal';
import type { StornoCheck, CurrencyCode, PrintReceiptData } from '@/types';

export default function StornoPage() {
  const navigate = useNavigate();
  const { companyType, user, branchCode } = useAuthStore();

  const [receiptSearch, setReceiptSearch] = useState('');
  const [stornoCheck, setStornoCheck] = useState<StornoCheck | null>(null);
  const [reason, setReason] = useState('');
  const [supervisorPassword, setSupervisorPassword] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [isExecuting, setIsExecuting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // QR kód és bizonylat preview state-ek
  const [qrCodeDataUrl, setQrCodeDataUrl] = useState<string | null>(null);
  const [showReceiptPreview, setShowReceiptPreview] = useState(false);
  const [pendingReceiptData, setPendingReceiptData] = useState<PrintReceiptData | null>(null);

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  // Keresés
  const handleSearch = useCallback(async () => {
    const trimmed = receiptSearch.trim();
    if (!trimmed) return;

    // Parse receiptNumber → transactionId (a bizonylat szám alapján keresünk)
    // A szerver a transactionId-t várja
    const idMatch = /\d+/.exec(trimmed);
    const transactionId = idMatch ? parseInt(idMatch[0], 10) : NaN;

    if (isNaN(transactionId)) {
      setError('❌ Érvénytelen bizonylat szám vagy tranzakció azonosító');
      return;
    }

    setIsSearching(true);
    setError('');
    setSuccess('');
    setStornoCheck(null);

    try {
      const workerId = user?.id ?? 0;
      const result = await checkStorno(transactionId, workerId);
      setStornoCheck(result);
    } catch {
      const message = err instanceof Error ? err.message : 'Keresési hiba';
      setError(`❌ ${message}`);
    } finally {
      setIsSearching(false);
    }
  }, [receiptSearch]);

  // Stornó végrehajtás
  const handleExecute = useCallback(async () => {
    if (!stornoCheck || !reason.trim()) return;

    setIsExecuting(true);
    setError('');
    setSuccess('');

    try {
      const workerId = user?.id ?? 0;
      const result = await executeStorno(
        {
          transactionId: stornoCheck.transaction.id,
          reason: reason.trim(),
          supervisorPassword: stornoCheck.requiresSupervisor
            ? supervisorPassword
            : undefined,
        },
        workerId,
      );

      const tx = stornoCheck.transaction;
      const receiptNumber = result.newReceiptNumber;

      setSuccess(
        `✅ Stornó sikeres! Új bizonylat: ${receiptNumber}`,
      );

      // QR kód generálás a stornó bizonylatra
      try {
        const taxNumber = companyType === 'BEST_CHANGE' ? '32313332-2-02' : '14040535-2-02';
        
        const qrData = await generateQRCode({
          bizonylatSzam: receiptNumber,
          datum: new Date().toISOString().slice(0, 10),
          osszeg: tx.roundedHufAmount,
          valuta: tx.currencyCode,
          adoszam: taxNumber,
          penztarKod: parseInt(branchCode, 10),
        });
        setQrCodeDataUrl(qrData);
      } catch (qrErr) {
        console.error('[StornoPage] QR kód generálás hiba:', qrErr);
      }

      // Stornó bizonylat adatok összeállítása
      const now = new Date();
      const receiptData: PrintReceiptData = {
        type: 'storno',
        companyType: companyType ?? 'BEST_CHANGE',
        receiptNumber,
        branchCode: branchCode, // Dinamikus érték
        cashierName: user?.fullName ?? 'Pénztáros', // Bejelentkezett user
        date: now.toISOString().slice(0, 10),
        time: now.toTimeString().slice(0, 8),
        currencyCode: tx.currencyCode,
        foreignAmount: tx.foreignAmount,
        rate: tx.rate,
        hufAmount: tx.hufAmount,
        roundedHufAmount: tx.roundedHufAmount,
        stornoReason: reason.trim(),
        originalReceiptNumber: tx.receiptNumber, // Eredeti bizonylat száma
      };

      setPendingReceiptData(receiptData);
      setShowReceiptPreview(true);

      // Reset
      setStornoCheck(null);
      setReceiptSearch('');
      setReason('');
      setSupervisorPassword('');
    } catch {
      const message = err instanceof Error ? err.message : 'Stornó végrehajtási hiba';
      setError(`❌ ${message}`);
      toast.error(`Stornó hiba: ${message}`);
    } finally {
      setIsExecuting(false);
    }
  }, [stornoCheck, reason, supervisorPassword, companyType, branchCode, user]);

  // Nyomtatás callback
  const handlePrint = useCallback(async () => {
    if (!pendingReceiptData || !window.electronAPI) {
      console.error('[StornoPage] Nincs bizonylat adat vagy Electron API nem elérhető');
      toast.error('Nyomtatási hiba: Electron API nem elérhető');
      return;
    }

    try {
      await window.electronAPI.printReceipt(JSON.stringify(pendingReceiptData));
      console.log('[StornoPage] Stornó bizonylat nyomtatás sikeres:', pendingReceiptData.receiptNumber);
      toast.success('Stornó bizonylat nyomtatva!');
    } catch {
      console.error('[StornoPage] Nyomtatási hiba:', err);
      const errorMessage = err instanceof Error ? err.message : 'Ismeretlen hiba';
      toast.error(`Nyomtatási hiba: ${errorMessage}`);
    }
  }, [pendingReceiptData]);

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

  const tx = stornoCheck?.transaction;
  const currencyInfo = tx
    ? getCurrencyInfo(tx.currencyCode as CurrencyCode)
    : undefined;
  const canExecute =
    stornoCheck?.canStorno === true &&
    reason.trim() !== '' &&
    (!stornoCheck.requiresSupervisor || supervisorPassword.trim() !== '');

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">↩️ Stornó</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-2xl space-y-6">
          {/* Keresés */}
          <div className="rounded-xl border bg-white p-6">
            <h2 className="mb-4 text-lg font-semibold text-gray-700">
              🔍 Tranzakció keresése
            </h2>
            <div className="flex gap-3">
              <input
                type="text"
                value={receiptSearch}
                onChange={(e) => setReceiptSearch(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    void handleSearch();
                  }
                }}
                className="input-field flex-1"
                placeholder="Bizonylat szám vagy tranzakció ID..."
                autoFocus
              />
              <button
                onClick={() => void handleSearch()}
                disabled={isSearching || !receiptSearch.trim()}
                className="rounded-lg bg-blue-600 px-6 py-2 font-medium text-white hover:bg-blue-700 disabled:opacity-50"
              >
                {isSearching ? '⏳...' : '🔍 Keresés'}
              </button>
            </div>
          </div>

          {/* Hiba/Siker */}
          {error && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>
          )}
          {success && (
            <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">
              {success}
            </div>
          )}

          {/* Tranzakció részletek */}
          {stornoCheck && tx && (
            <div className="space-y-4 rounded-xl border bg-white p-6">
              <h2 className="text-lg font-semibold text-gray-700">
                📋 Tranzakció részletei
              </h2>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-500">Bizonylat szám</p>
                  <p className="font-mono font-bold">{tx.receiptNumber}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Típus</p>
                  <p className="font-semibold">
                    {tx.type === 'SELL' ? '💰 Eladás' : '🛒 Vásárlás'}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Valuta</p>
                  <p className="font-semibold">
                    {currencyInfo?.flag ?? ''} {tx.currencyCode}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Deviza összeg</p>
                  <p className="font-mono font-bold">
                    {tx.foreignAmount.toLocaleString('hu-HU', {
                      minimumFractionDigits: 2,
                    })}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Forint összeg</p>
                  <p className="font-mono font-bold">
                    {tx.roundedHufAmount.toLocaleString('hu-HU')} Ft
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Árfolyam</p>
                  <p className="font-mono">{tx.rate.toFixed(2)}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Dátum</p>
                  <p className="text-sm">
                    {new Date(tx.createdAt).toLocaleString('hu-HU')}
                  </p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Pénztár</p>
                  <p className="text-sm">{tx.branchCode}</p>
                </div>
              </div>

              {/* Stornó nem lehetséges */}
              {!stornoCheck.canStorno && (
                <div className="rounded-lg border-2 border-red-300 bg-red-50 p-4">
                  <p className="font-bold text-red-700">
                    ⛔ Stornó nem végezhető el
                  </p>
                  {stornoCheck.reason && (
                    <p className="text-sm text-red-600">{stornoCheck.reason}</p>
                  )}
                </div>
              )}

              {/* Stornó form */}
              {stornoCheck.canStorno && (
                <div className="space-y-4 border-t pt-4">
                  <div>
                    <label className="mb-1 block text-sm font-medium text-gray-700">
                      Stornó oka *
                    </label>
                    <textarea
                      value={reason}
                      onChange={(e) => setReason(e.target.value)}
                      className="input-field min-h-[80px] resize-none"
                      placeholder="Adja meg a stornó okát..."
                    />
                  </div>

                  {stornoCheck.requiresSupervisor && (
                    <div className="rounded-lg border-2 border-yellow-300 bg-yellow-50 p-4">
                      <p className="mb-2 text-sm font-bold text-yellow-800">
                        🔑 Supervisor jóváhagyás szükséges
                      </p>
                      <input
                        type="password"
                        value={supervisorPassword}
                        onChange={(e) => setSupervisorPassword(e.target.value)}
                        className="input-field"
                        placeholder="Supervisor jelszó..."
                      />
                    </div>
                  )}

                  <button
                    onClick={() => void handleExecute()}
                    disabled={!canExecute || isExecuting}
                    className="btn-primary w-full bg-red-600 text-lg hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    {isExecuting
                      ? '⏳ Feldolgozás...'
                      : '↩️ Stornó végrehajtása'}
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </main>

      {/* Stornó bizonylat előnézet modal */}
      <ReceiptPreviewModal
        isOpen={showReceiptPreview}
        onClose={() => setShowReceiptPreview(false)}
        receiptData={pendingReceiptData}
        qrCodeDataUrl={qrCodeDataUrl}
        onPrint={handlePrint}
      />
    </div>
  );
}

