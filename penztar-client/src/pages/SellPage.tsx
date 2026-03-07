import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useRateStore } from '@/stores/rateStore';
import { useAuthStore } from '@/stores/authStore';
import { toast } from '@/hooks/useToast';
import { sellCurrency } from '@/api/transactions';
import { getActiveCurrencies, type CurrencyDto } from '@/api/currencies';
import { screenCustomer } from '@/api/sanctions';
import { roundHuf } from '@/utils/rounding';
import { checkAmlLimits, AML_IDENTIFICATION_LIMIT } from '@/utils/validation';
import { getForeignCurrencies, getCurrencyInfo } from '@/utils/currencies';
import { generateQRCode } from '@/utils/qrcode';
import { useOnlineStatus } from '@/hooks/useOnlineStatus';
import CurrencySelector from '@/components/CurrencySelector';
import CustomerSearch from '@/components/CustomerSearch';
import DenomGrid from '@/components/DenomGrid';
import SanctionAlert from '@/components/SanctionAlert';
import ReceiptPreviewModal from '@/components/ReceiptPreviewModal';
import type { CurrencyCode, Customer, Denomination, SanctionScreeningResult, PrintReceiptData } from '@/types';

type InputMode = 'foreign' | 'huf';

export default function SellPage() {
  const navigate = useNavigate();
  const { getSellRate, fetchRates, rates } = useRateStore();
  const { companyType, user, branchCode } = useAuthStore();

  const [selectedCurrency, setSelectedCurrency] = useState<CurrencyCode | null>(null);
  const [currencyList, setCurrencyList] = useState<CurrencyDto[]>([]);

  useEffect(() => {
    getActiveCurrencies()
      .then(setCurrencyList)
      .catch(() => {
        toast.error('Nem sikerült betölteni a valuták listáját. Próbálja újra!');
      });
  }, []);
  const [foreignAmount, setForeignAmount] = useState('');
  const [hufAmount, setHufAmount] = useState('');
  const [inputMode, setInputMode] = useState<InputMode>('foreign');
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [showCustomerSearch, setShowCustomerSearch] = useState(false);
  const [denominations, setDenominations] = useState<Denomination[]>([]);
  const [showDenom, setShowDenom] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Szankciós szűrés state-ek
  const [sanctionResult, setSanctionResult] = useState<SanctionScreeningResult | null>(null);
  const [sanctionChecked, setSanctionChecked] = useState(false);
  const [sanctionApproved, setSanctionApproved] = useState(false);
  const [isScreening, setIsScreening] = useState(false);

  // QR kód state
  const [qrCodeDataUrl, setQrCodeDataUrl] = useState<string | null>(null);

  // Bizonylat preview modal state
  const [showReceiptPreview, setShowReceiptPreview] = useState(false);
  const [pendingReceiptData, setPendingReceiptData] = useState<PrintReceiptData | null>(null);

  const { isOnline } = useOnlineStatus();
  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';

  const currencies = useMemo(() => getForeignCurrencies(), []);
  const currencyInfo = selectedCurrency ? getCurrencyInfo(selectedCurrency) : null;

  // Árfolyam betöltés
  useEffect(() => {
    if (rates.length === 0) {
      void fetchRates();
    }
  }, [rates.length, fetchRates]);

  // Árfolyam a kiválasztott valutához
  const sellRate = selectedCurrency ? getSellRate(selectedCurrency) : 0;
  const unit = currencyInfo?.unit ?? 1;

  // Automatikus számítás
  useEffect(() => {
    if (!selectedCurrency || sellRate === 0) return;

    if (inputMode === 'foreign') {
      const foreign = parseFloat(foreignAmount);
      if (!isNaN(foreign) && foreign > 0) {
        const huf = (foreign / unit) * sellRate;
        setHufAmount(Math.round(huf).toString());
      } else {
        setHufAmount('');
      }
    } else {
      const huf = parseFloat(hufAmount);
      if (!isNaN(huf) && huf > 0) {
        const foreign = (huf / sellRate) * unit;
        setForeignAmount(foreign.toFixed(2));
      } else {
        setForeignAmount('');
      }
    }
  }, [foreignAmount, hufAmount, inputMode, sellRate, selectedCurrency, unit]);

  const hufNumeric = parseFloat(hufAmount) || 0;
  const roundedHuf = roundHuf(hufNumeric);
  const roundingDiff = roundedHuf - hufNumeric;
  const amlCheck = checkAmlLimits(hufNumeric);

  // Ügyfél kötelező ellenőrzés
  const customerRequired = amlCheck.requiresIdentification;

  // Szankciós szűrés: CONFIRMED → tiltás, POSSIBLE → supervisor kell
  const sanctionBlocked = sanctionResult?.riskLevel === 'CONFIRMED';
  const sanctionNeedsApproval = sanctionResult?.riskLevel === 'POSSIBLE' && !sanctionApproved;

  const canSubmit =
    selectedCurrency !== null &&
    currencyList.length > 0 &&
    parseFloat(foreignAmount) > 0 &&
    hufNumeric > 0 &&
    (!customerRequired || customer !== null) &&
    !sanctionBlocked &&
    !sanctionNeedsApproval;

  const handleForeignChange = useCallback((value: string) => {
    setInputMode('foreign');
    setForeignAmount(value);
  }, []);

  const handleHufChange = useCallback((value: string) => {
    setInputMode('huf');
    setHufAmount(value);
  }, []);

  // Szankciós szűrés végrehajtása — ügyfél változásakor
  const handleSanctionScreen = useCallback(async (customerName: string, docNumber?: string) => {
    if (!customerName || !isOnline) {
      setSanctionResult(null);
      setSanctionChecked(false);
      setSanctionApproved(false);
      return;
    }

    setIsScreening(true);
    try {
      const result = await screenCustomer({
        name: customerName,
        documentNumber: docNumber,
      });
      setSanctionResult(result);
      setSanctionChecked(true);
      setSanctionApproved(false);

      if (result.riskLevel === 'CLEAR') {
        console.log('[SellPage] Szankciós szűrés: CLEAR — nincs találat');
      } else {
        console.warn(`[SellPage] Szankciós szűrés: ${result.riskLevel} — ${result.matches.length} találat!`);
      }
    } catch (err) {
      console.error('[SellPage] Szankciós szűrés hiba:', err);
      // Ha a szűrés nem elérhető, ne blokkoljuk a tranzakciót, de jelezzünk
      setSanctionResult(null);
      setSanctionChecked(false);
    } finally {
      setIsScreening(false);
    }
  }, [isOnline]);

  // Ügyfél változásakor automatikus szankciós szűrés
  useEffect(() => {
    if (customer) {
      void handleSanctionScreen(customer.name, customer.documentNumber);
    } else {
      setSanctionResult(null);
      setSanctionChecked(false);
      setSanctionApproved(false);
    }
  }, [customer, handleSanctionScreen]);

  const handleSubmit = useCallback(async () => {
    if (!selectedCurrency || !canSubmit || isSubmitting) return;

    // Szankciós szűrés KÖTELEZŐ ellenőrzés — online módban
    if (customer && isOnline && !sanctionChecked) {
      setError('❌ Szankciós szűrés nem történt meg. Kérjük várjon.');
      return;
    }

    setIsSubmitting(true);
    setError('');
    setSuccess('');

    try {
      let receiptNumber = '';

      if (isOnline) {
        // Online mód — normál API hívás
        const result = await sellCurrency({
          currencyId: currencyList.find(c => c.code === selectedCurrency)?.id ?? 0,
          currencyAmount: parseFloat(foreignAmount),
          currencyCode: selectedCurrency,
          hufAmount: hufNumeric,
          roundedHufAmount: roundedHuf,
          rate: sellRate,
          customerId: customer?.id,
          denominations: denominations.length > 0 ? denominations : undefined,
        });

        receiptNumber = result.receiptNumber;

        setSuccess(
          `✅ Eladás sikeres! Bizonylat: ${result.receiptNumber} — ${result.foreignAmount} ${selectedCurrency} = ${result.roundedHufAmount.toLocaleString('hu-HU')} Ft`,
        );
      } else {
        // Offline mód — mentés pending_transactions-be
        if (window.electronAPI) {
          await window.electronAPI.savePendingTransaction(
            'SELL',
            selectedCurrency,
            parseFloat(foreignAmount),
            hufNumeric,
            roundedHuf,
            sellRate,
            customer?.id ?? null,
            denominations.length > 0 ? JSON.stringify(denominations) : null,
          );
        }

        receiptNumber = `OFF-${Date.now()}`;

        setSuccess(
          `✅ Eladás rögzítve — ${parseFloat(foreignAmount)} ${selectedCurrency} = ${roundedHuf.toLocaleString('hu-HU')} Ft (offline — szinkronizálódik később)`,
        );
      }

      // QR kód generálás a bizonylatra
      try {
        // Cég adószám: companyType alapján
        const taxNumber = companyType === 'BEST_CHANGE' ? '32313332-2-02' : '14040535-2-02';
        
        const qrData = await generateQRCode({
          bizonylatSzam: receiptNumber,
          datum: new Date().toISOString().slice(0, 10),
          osszeg: roundedHuf,
          valuta: selectedCurrency,
          adoszam: taxNumber, // Dinamikus érték companyType alapján
          penztarKod: parseInt(branchCode, 10), // Branch code → pénztárgép kód
        });
        setQrCodeDataUrl(qrData);
      } catch (qrErr) {
        console.error('[SellPage] QR kód generálás hiba:', qrErr);
      }

      // Bizonylat preview modal megjelenítése
      const now = new Date();
      const receiptData: PrintReceiptData = {
        type: 'sell',
        companyType: companyType ?? 'BEST_CHANGE',
        receiptNumber,
        branchCode: branchCode, // Dinamikus érték authStore-ból
        cashierName: user?.fullName ?? 'Pénztáros', // Bejelentkezett user neve
        date: now.toISOString().slice(0, 10),
        time: now.toTimeString().slice(0, 8),
        currencyCode: selectedCurrency,
        foreignAmount: parseFloat(foreignAmount),
        rate: sellRate,
        hufAmount: hufNumeric,
        roundedHufAmount: roundedHuf,
        roundingDiff: roundingDiff,
        customerName: customer?.name,
        customerDocType: customer?.documentType,
        customerDocNumber: customer?.documentNumber,
      };

      setPendingReceiptData(receiptData);
      setShowReceiptPreview(true);

      // Reset (de QR kódot és receipt data-t megtartjuk)
      setForeignAmount('');
      setHufAmount('');
      setCustomer(null);
      setDenominations([]);
      setSanctionResult(null);
      setSanctionChecked(false);
      setSanctionApproved(false);
    } catch (err) {
      // L2: Error message leak — teljes hiba csak console-ba
      console.error('[SellPage] Tranzakció hiba:', err);
      setError('❌ Tranzakció sikertelen. Próbálja újra.');
    } finally {
      setIsSubmitting(false);
    }
  }, [
    selectedCurrency,
    canSubmit,
    isSubmitting,
    isOnline,
    foreignAmount,
    hufNumeric,
    roundedHuf,
    sellRate,
    customer,
    denominations,
    sanctionChecked,
  ]);

  // Nyomtatás callback — Electron IPC hívás
  const handlePrint = useCallback(async () => {
    if (!pendingReceiptData || !window.electronAPI) {
      console.error('[SellPage] Nincs bizonylat adat vagy Electron API nem elérhető');
      toast.error('Nyomtatási hiba: Electron API nem elérhető');
      return;
    }

    try {
      await window.electronAPI.printReceipt(JSON.stringify(pendingReceiptData));
      console.log('[SellPage] Bizonylat nyomtatás sikeres:', pendingReceiptData.receiptNumber);
      toast.success('Bizonylat nyomtatva!');
    } catch (err) {
      console.error('[SellPage] Nyomtatási hiba:', err);
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

  return (
    <div className="flex h-screen flex-col">
      {/* Fejléc */}
      <header className={`${headerColor} px-6 py-3 text-white`}>
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold">💰 Deviza Eladás</h1>
          <button
            onClick={() => navigate('/menu')}
            className="rounded-lg bg-white/20 px-4 py-2 text-sm hover:bg-white/30"
          >
            ← Vissza (ESC)
          </button>
        </div>
      </header>

      <main className="flex-1 overflow-auto p-6">
        <div className="mx-auto grid max-w-6xl grid-cols-3 gap-6">
          {/* BAL — Valutanem választó */}
          <div className="col-span-1">
            <h2 className="mb-3 text-lg font-semibold text-gray-700">
              Válasszon valutanemet
            </h2>
            <div className="max-h-[600px] overflow-auto rounded-xl border bg-white p-3">
              <CurrencySelector
                currencies={currencies}
                selected={selectedCurrency}
                onSelect={setSelectedCurrency}
                rates={rates}
                rateType="sell"
              />
            </div>
          </div>

          {/* KÖZÉP — Összeg bevitel + számítás */}
          <div className="col-span-1 space-y-4">
            {/* Árfolyam */}
            {selectedCurrency && (
              <div className="rounded-xl border bg-blue-50 p-4">
                <p className="text-sm text-gray-500">Eladási árfolyam</p>
                <p className="text-3xl font-bold text-blue-700">
                  {sellRate.toFixed(2)} Ft
                  {unit > 1 && (
                    <span className="ml-2 text-base text-gray-500">
                      / {unit} {selectedCurrency}
                    </span>
                  )}
                </p>
              </div>
            )}

            {/* Deviza összeg */}
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                {selectedCurrency ?? 'Deviza'} összeg
              </label>
              <input
                type="number"
                value={foreignAmount}
                onChange={(e) => handleForeignChange(e.target.value)}
                className="input-field text-right text-2xl font-bold"
                placeholder="0.00"
                step="0.01"
                min="0"
                disabled={!selectedCurrency}
              />
            </div>

            {/* Forint összeg */}
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                Forint összeg
              </label>
              <input
                type="number"
                value={hufAmount}
                onChange={(e) => handleHufChange(e.target.value)}
                className="input-field text-right text-2xl font-bold"
                placeholder="0"
                step="1"
                min="0"
                disabled={!selectedCurrency}
              />
            </div>

            {/* Kerekítés */}
            {hufNumeric > 0 && (
              <div className="rounded-xl border bg-green-50 p-4">
                <div className="flex justify-between">
                  <span className="text-sm text-gray-600">Kerekítés előtt:</span>
                  <span className="font-mono">
                    {hufNumeric.toLocaleString('hu-HU')} Ft
                  </span>
                </div>
                <div className="flex justify-between text-lg font-bold text-green-700">
                  <span>Fizetendő:</span>
                  <span>{roundedHuf.toLocaleString('hu-HU')} Ft</span>
                </div>
                {roundingDiff !== 0 && (
                  <div className="mt-1 flex justify-between text-xs text-gray-500">
                    <span>Kerekítés:</span>
                    <span>
                      {roundingDiff > 0 ? '+' : ''}
                      {roundingDiff} Ft
                    </span>
                  </div>
                )}
              </div>
            )}

            {/* AML figyelmeztetés */}
            {customerRequired && !customer && (
              <div className="rounded-xl border-2 border-yellow-400 bg-yellow-50 p-4">
                <p className="font-bold text-yellow-800">
                  ⚠️ Ügyfél azonosítás KÖTELEZŐ!
                </p>
                <p className="text-sm text-yellow-700">
                  {AML_IDENTIFICATION_LIMIT.toLocaleString('hu-HU')} Ft feletti
                  tranzakció.
                </p>
              </div>
            )}

            {amlCheck.requiresReporting && (
              <div className="rounded-xl border-2 border-red-400 bg-red-50 p-3">
                <p className="text-sm font-bold text-red-700">
                  🚨 NAV bejelentés szükséges (1.000.000 Ft felett)
                </p>
              </div>
            )}
          </div>

          {/* JOBB — Ügyfél + Címletezés + Véglegesítés */}
          <div className="col-span-1 space-y-4">
            {/* Ügyfél */}
            <div className="rounded-xl border bg-white p-4">
              <div className="flex items-center justify-between">
                <h3 className="font-semibold text-gray-700">👤 Ügyfél</h3>
                <button
                  onClick={() => setShowCustomerSearch(true)}
                  className="rounded-lg bg-blue-100 px-3 py-1 text-sm text-blue-700 hover:bg-blue-200"
                >
                  Keresés
                </button>
              </div>
              {customer ? (
                <div className="mt-2 space-y-1 text-sm">
                  <p className="font-medium">{customer.name}</p>
                  <p className="text-gray-500">
                    {customer.documentType}: {customer.documentNumber}
                  </p>
                  <button
                    onClick={() => setCustomer(null)}
                    className="text-xs text-red-500 hover:text-red-700"
                  >
                    ✕ Törlés
                  </button>
                </div>
              ) : (
                <p className="mt-2 text-sm text-gray-400">Nincs kiválasztva</p>
              )}
            </div>

            {/* Címletezés gomb */}
            <button
              onClick={() => setShowDenom(true)}
              className="w-full rounded-xl border bg-white p-4 text-left hover:bg-gray-50"
            >
              <h3 className="font-semibold text-gray-700">🪙 Címletezés</h3>
              <p className="text-sm text-gray-400">
                {denominations.length > 0
                  ? `${denominations.length} tétel megadva`
                  : 'Bankjegy összetétel megadása'}
              </p>
            </button>

            {/* Szankciós szűrés eredmény */}
            {isScreening && (
              <div className="rounded-lg border bg-blue-50 p-3 text-sm text-blue-700">
                ⏳ Szankciós szűrés folyamatban...
              </div>
            )}
            {sanctionResult && sanctionResult.riskLevel !== 'CLEAR' && (
              <SanctionAlert
                result={sanctionResult}
                onSupervisorApprove={() => setSanctionApproved(true)}
                onBlock={() => {
                  setCustomer(null);
                  setSanctionResult(null);
                  setSanctionChecked(false);
                  setSanctionApproved(false);
                }}
              />
            )}

            {/* Véglegesítés */}
            {error && (
              <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">
                {error}
              </div>
            )}
            {success && (
              <div className="rounded-lg bg-green-50 p-3 text-sm text-green-700">
                {success}
              </div>
            )}

            {/* QR kód megjelenítés a sikeres tranzakció után */}
            {qrCodeDataUrl && (
              <div className="rounded-lg border bg-white p-3 text-center">
                <p className="mb-2 text-xs font-medium text-gray-500">Bizonylat QR kód</p>
                <img
                  src={qrCodeDataUrl}
                  alt="Bizonylat QR kód"
                  className="mx-auto h-32 w-32"
                />
                <button
                  onClick={() => setQrCodeDataUrl(null)}
                  className="mt-2 text-xs text-gray-400 hover:text-gray-600"
                >
                  ✕ Bezárás
                </button>
              </div>
            )}

            <button
              onClick={handleSubmit}
              disabled={!canSubmit || isSubmitting}
              className={`btn-primary w-full text-lg ${
                isBestChange
                  ? 'bg-red-600 hover:bg-red-700'
                  : 'bg-orange-500 hover:bg-orange-600'
              } disabled:cursor-not-allowed disabled:opacity-50`}
            >
              {isSubmitting
                ? '⏳ Feldolgozás...'
                : `💰 Eladás véglegesítése — ${roundedHuf.toLocaleString('hu-HU')} Ft`}
            </button>
          </div>
        </div>
      </main>

      {/* Ügyfél keresés modal */}
      {showCustomerSearch && (
        <CustomerSearch
          onSelect={(c) => {
            setCustomer(c);
            setShowCustomerSearch(false);
          }}
          onClose={() => setShowCustomerSearch(false)}
        />
      )}

      {/* Címletezés modal */}
      {showDenom && (
        <DenomGrid
          currencyCode="HUF"
          onSave={(d) => {
            setDenominations(d);
            setShowDenom(false);
          }}
          onClose={() => setShowDenom(false)}
        />
      )}

      {/* Bizonylat előnézet modal */}
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
