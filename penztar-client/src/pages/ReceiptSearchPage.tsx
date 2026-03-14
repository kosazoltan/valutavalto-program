import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import { searchReceipts, getReceiptDetail } from '@/api/receipts';
import { generateQRCode } from '@/utils/qrcode';
import type { ReceiptSearchResult, ReceiptDetail } from '@/types';

export default function ReceiptSearchPage() {
  const navigate = useNavigate();
  const { companyType } = useAuthStore();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  // Keresés mezők
  const [number, setNumber] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [type, setType] = useState('');
  const [minAmount, setMinAmount] = useState('');
  const [maxAmount, setMaxAmount] = useState('');
  const [customer, setCustomer] = useState('');

  // Eredmények
  const [results, setResults] = useState<ReceiptSearchResult[]>([]);
  const [totalPages, setTotalPages] = useState(0);
  const [currentPage, setCurrentPage] = useState(0);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  // Részletek modal
  const [detail, setDetail] = useState<ReceiptDetail | null>(null);
  const [showDetail, setShowDetail] = useState(false);
  const [qrCodeUrl, setQrCodeUrl] = useState<string | null>(null);

  const handleSearch = useCallback(async (page = 0) => {
    setIsLoading(true);
    setError('');
    try {
      const data = await searchReceipts({
        number: number || undefined,
        dateFrom: dateFrom || undefined,
        dateTo: dateTo || undefined,
        type: type || undefined,
        minAmount: minAmount ? parseFloat(minAmount) : undefined,
        maxAmount: maxAmount ? parseFloat(maxAmount) : undefined,
        customer: customer || undefined,
        page,
        size: 20,
      });
      setResults(data.content);
      setTotalPages(data.totalPages);
      setCurrentPage(data.number);
    } catch (err: unknown) {
      console.error('[ReceiptSearch] Keresés hiba:', err);
      setError('Keresés sikertelen. Próbálja újra.');
    } finally {
      setIsLoading(false);
    }
  }, [number, dateFrom, dateTo, type, minAmount, maxAmount, customer]);

  const handleShowDetail = useCallback(async (id: number) => {
    try {
      const data = await getReceiptDetail(id);
      setDetail(data);
      setShowDetail(true);

      // QR kód generálás
      try {
        const qr = await generateQRCode({
          bizonylatSzam: data.receiptNumber,
          datum: data.transactionDate,
          osszeg: data.hufAmount,
          valuta: data.currencyCode,
          adoszam: data.qrData ?? '',
          penztarKod: data.branchCode ? parseInt(data.branchCode, 10) : 0,
        });
        setQrCodeUrl(qr);
      } catch (err: unknown) {
        setQrCodeUrl(null);
      }
    } catch (err: unknown) {
      setError('Bizonylat részletek betöltése sikertelen.');
    }
  }, []);

  const handleReprint = useCallback(() => {
    if (!detail) return;
    if (window.electronAPI) {
      void window.electronAPI.printReceipt(JSON.stringify(detail));
    }
  }, [detail]);

  const handleStorno = useCallback(() => {
    if (!detail) return;
    navigate(`/storno?txId=${detail.id}`);
  }, [detail, navigate]);

  // ESC → vissza
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (showDetail) {
          setShowDetail(false);
        } else {
          navigate('/menu');
        }
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [navigate, showDetail]);

  const typeOptions = [
    { value: '', label: 'Összes' },
    { value: 'SELL', label: 'Eladás (E)' },
    { value: 'BUY', label: 'Vétel (V)' },
    { value: 'VIGNETTE', label: 'Autópálya matrica (A)' },
    { value: 'REVERSAL', label: 'Sztornó (S)' },
    { value: 'CONVERSION', label: 'Konverzió' },
  ];

  return (
    <div className="flex h-screen flex-col">
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">🔍 Bizonylat kereső</h1>
          <button onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30">
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto max-w-7xl">
          {/* Keresés form */}
          <div className="mb-6 rounded-xl border bg-white p-4">
            <h2 className="mb-3 font-semibold text-gray-700">Keresési feltételek</h2>
            <div className="grid grid-cols-4 gap-3">
              <input type="text" value={number} onChange={(e) => setNumber(e.target.value)}
                className="input-field" placeholder="Bizonylat szám" />
              <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)}
                className="input-field" />
              <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)}
                className="input-field" />
              <select value={type} onChange={(e) => setType(e.target.value)} className="input-field">
                {typeOptions.map((o) => (
                  <option key={o.value} value={o.value}>{o.label}</option>
                ))}
              </select>
              <input type="number" value={minAmount}
                onChange={(e) => setMinAmount(e.target.value)}
                className="input-field" placeholder="Min. összeg (Ft)" />
              <input type="number" value={maxAmount}
                onChange={(e) => setMaxAmount(e.target.value)}
                className="input-field" placeholder="Max. összeg (Ft)" />
              <input type="text" value={customer}
                onChange={(e) => setCustomer(e.target.value)}
                className="input-field" placeholder="Ügyfél neve" />
              <button onClick={() => handleSearch(0)}
                disabled={isLoading}
                className="btn-primary bg-blue-600 hover:bg-blue-700 disabled:opacity-50">
                {isLoading ? '⏳ Keresés...' : '🔍 Keresés'}
              </button>
            </div>
          </div>

          {error && <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">{error}</div>}

          {/* Találati lista */}
          {results.length > 0 && (
            <div className="overflow-auto rounded-lg border bg-white">
              <table className="min-w-full text-sm">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-3 py-2 text-left font-medium text-gray-600">Szám</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-600">Dátum</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-600">Típus</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-600">Valuta</th>
                    <th className="px-3 py-2 text-right font-medium text-gray-600">Összeg</th>
                    <th className="px-3 py-2 text-right font-medium text-gray-600">HUF</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-600">Ügyfél</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-600">Pénztáros</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-600">Státusz</th>
                    <th className="px-3 py-2 text-left font-medium text-gray-600" />
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {results.map((r) => (
                    <tr key={r.id} className="cursor-pointer hover:bg-blue-50"
                      onClick={() => handleShowDetail(r.id)}>
                      <td className="px-3 py-2 font-mono text-xs">{r.receiptNumber}</td>
                      <td className="px-3 py-2 text-xs">{r.transactionDate}</td>
                      <td className="px-3 py-2">{r.transactionTypeDisplay}</td>
                      <td className="px-3 py-2 font-medium">{r.currencyCode}</td>
                      <td className="px-3 py-2 text-right font-mono">{r.currencyAmount?.toLocaleString('hu-HU')}</td>
                      <td className="px-3 py-2 text-right font-mono font-semibold">
                        {r.hufAmount?.toLocaleString('hu-HU')} Ft
                      </td>
                      <td className="px-3 py-2 text-xs">{r.customerName ?? '—'}</td>
                      <td className="px-3 py-2 text-xs">{r.cashierName}</td>
                      <td className="px-3 py-2">
                        <span className={`rounded-full px-2 py-0.5 text-xs ${
                          r.status === 'COMPLETED' ? 'bg-green-100 text-green-700'
                            : r.status === 'REVERSED' ? 'bg-red-100 text-red-700'
                            : 'bg-gray-100 text-gray-700'
                        }`}>{r.status}</span>
                      </td>
                      <td className="px-3 py-2">
                        <button className="text-blue-600 hover:text-blue-800 text-xs">Részletek →</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>

              {/* Lapozás */}
              {totalPages > 1 && (
                <div className="flex items-center justify-center gap-2 border-t p-3">
                  <button onClick={() => handleSearch(currentPage - 1)}
                    disabled={currentPage === 0}
                    className="rounded border px-3 py-1 text-sm disabled:opacity-30">
                    ← Előző
                  </button>
                  <span className="text-sm text-gray-500">
                    {currentPage + 1} / {totalPages}
                  </span>
                  <button onClick={() => handleSearch(currentPage + 1)}
                    disabled={currentPage >= totalPages - 1}
                    className="rounded border px-3 py-1 text-sm disabled:opacity-30">
                    Következő →
                  </button>
                </div>
              )}
            </div>
          )}

          {results.length === 0 && !isLoading && (
            <p className="mt-4 text-center text-gray-400">
              Adjon meg keresési feltételt és nyomja meg a Keresés gombot.
            </p>
          )}
        </div>
      </main>

      {/* Részletek modal */}
      {showDetail && detail && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="max-h-[80vh] w-[700px] overflow-auto rounded-xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h3 className="text-lg font-bold">📄 Bizonylat: {detail.receiptNumber}</h3>
              <button onClick={() => setShowDetail(false)}
                className="text-gray-400 hover:text-gray-600">✕</button>
            </div>

            {/* Fejléc */}
            <div className="mb-4 grid grid-cols-2 gap-4 rounded-lg bg-gray-50 p-4 text-sm">
              <div>
                <p><span className="text-gray-500">Dátum:</span> {detail.transactionDate} {detail.transactionTime}</p>
                <p><span className="text-gray-500">Típus:</span> {detail.transactionTypeDisplay}</p>
                <p><span className="text-gray-500">Státusz:</span> {detail.status}</p>
                <p><span className="text-gray-500">Pénztáros:</span> {detail.cashierName}</p>
                <p><span className="text-gray-500">Iroda:</span> {detail.branchCode}</p>
              </div>
              <div>
                <p><span className="text-gray-500">Valuta:</span> {detail.currencyCode}</p>
                <p><span className="text-gray-500">Összeg:</span> {detail.currencyAmount?.toLocaleString('hu-HU')} {detail.currencyCode}</p>
                <p><span className="text-gray-500">HUF:</span> <strong>{detail.hufAmount?.toLocaleString('hu-HU')} Ft</strong></p>
                <p><span className="text-gray-500">Árfolyam:</span> {detail.exchangeRate}</p>
                <p><span className="text-gray-500">Kezelési díj:</span> {detail.handlingFee?.toLocaleString('hu-HU')} Ft</p>
              </div>
            </div>

            {/* Ügyfél */}
            {detail.customerName && (
              <div className="mb-4 rounded-lg border p-3 text-sm">
                <p className="font-medium">👤 Ügyfél: {detail.customerName}</p>
                {detail.customerAddress && <p className="text-gray-500">{detail.customerAddress}</p>}
                {detail.customerDocumentNumber && (
                  <p className="text-gray-500">Okmány: {detail.customerDocumentNumber}</p>
                )}
              </div>
            )}

            {/* Tételsorok */}
            {detail.lines && detail.lines.length > 0 && (
              <div className="mb-4">
                <h4 className="mb-2 font-medium text-gray-700">Tételsorok</h4>
                <table className="w-full text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-2 py-1 text-left">#</th>
                      <th className="px-2 py-1 text-left">Valuta</th>
                      <th className="px-2 py-1 text-right">Árfolyam</th>
                      <th className="px-2 py-1 text-right">Db</th>
                      <th className="px-2 py-1 text-right">HUF érték</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y">
                    {detail.lines.map((l) => (
                      <tr key={l.lineNumber}>
                        <td className="px-2 py-1">{l.lineNumber}</td>
                        <td className="px-2 py-1">{l.currencyCode}</td>
                        <td className="px-2 py-1 text-right font-mono">{l.appliedRate}</td>
                        <td className="px-2 py-1 text-right font-mono">{l.banknoteCount}</td>
                        <td className="px-2 py-1 text-right font-mono">
                          {l.hufValue?.toLocaleString('hu-HU')} Ft
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            {/* QR kód */}
            {qrCodeUrl && (
              <div className="mb-4 text-center">
                <img src={qrCodeUrl} alt="QR kód" className="mx-auto h-24 w-24" />
              </div>
            )}

            {/* Gombok */}
            <div className="flex gap-3">
              <button onClick={handleReprint}
                className="btn-primary flex-1 bg-blue-600 hover:bg-blue-700">
                🖨️ Újranyomtatás
              </button>
              <button onClick={handleStorno}
                className="flex-1 rounded-lg border-2 border-red-300 bg-red-50 px-4 py-2 text-sm font-medium text-red-700 hover:bg-red-100">
                ↩️ Stornó
              </button>
              <button onClick={() => setShowDetail(false)}
                className="flex-1 rounded-lg border px-4 py-2 text-sm hover:bg-gray-50">
                Bezárás
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}


