import { useState, useEffect, useMemo, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/authStore';
import apiClient from '@/api/client';
import type { CurrencyCode, ExchangeRate, Customer } from '@/types';
import { getCurrencyInfo } from '@/utils/currencies';
import { AML_IDENTIFICATION_LIMIT } from '@/utils/validation';

/**
 * KonverziĂł oldal â€” valutaâ†’valuta csere.
 *
 * Legacy: ARFVALT â€” a Delphi rendszerben kĂĽlĂ¶n modul volt,
 * cross-rate szĂˇmĂ­tĂˇssal (forrĂˇsâ†’HUFâ†’cĂ©l ĂˇttĂ©telen).
 *
 * FunkciĂłk:
 * - ForrĂˇs Ă©s cĂ©l valuta kivĂˇlasztĂˇs
 * - Cross-rate automatikus szĂˇmĂ­tĂˇs
 * - Bizonylat elĹ‘nĂ©zet + nyomtatĂˇs
 * - Offline mĂłd (SQLite cache)
 */
export default function ConversionPage() {
  const navigate = useNavigate();
  const { user, companyType } = useAuthStore();

  // Valuta vĂˇlasztĂˇs
  const [sourceCurrency, setSourceCurrency] = useState<CurrencyCode>('EUR');
  const [targetCurrency, setTargetCurrency] = useState<CurrencyCode>('USD');
  const [sourceAmount, setSourceAmount] = useState('');
  const [rates, setRates] = useState<ExchangeRate[]>([]);

  // ĂśgyfĂ©l
  const [customerId, setCustomerId] = useState<number | null>(null);
  const [customerName, setCustomerName] = useState('');
  const [customerSearch, setCustomerSearch] = useState('');
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [showCustomerSearch, setShowCustomerSearch] = useState(false);

  // Ăllapot
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const isBestChange = companyType === 'BEST_CHANGE';
  const headerColor = isBestChange ? 'bg-red-600' : 'bg-orange-500';
  const btnColor = isBestChange ? 'bg-red-600 hover:bg-red-700' : 'bg-orange-500 hover:bg-orange-600';

  // Ărfolyamok betĂ¶ltĂ©se
  useEffect(() => {
    const loadRates = async () => {
      try {
        const res = await apiClient.get('/rates/current');
        setRates(res.data ?? []);
      } catch (err: unknown) {
        setError('Ărfolyamok betĂ¶ltĂ©se sikertelen');
      }
    };
    void loadRates();
  }, []);

  // Cross-rate szĂˇmĂ­tĂˇs
  const sourceRate = useMemo(() => rates.find(r => r.currencyCode === sourceCurrency), [rates, sourceCurrency]);
  const targetRate = useMemo(() => rates.find(r => r.currencyCode === targetCurrency), [rates, targetCurrency]);

  const crossRate = useMemo(() => {
    if (!sourceRate || !targetRate) return null;
    // Cross-rate = (forrĂˇs vĂ©teli HUF / forrĂˇs unit) / (cĂ©l eladĂˇsi HUF / cĂ©l unit)
    const sourceHufPerUnit = sourceRate.buyRate / sourceRate.unit;
    const targetHufPerUnit = targetRate.sellRate / targetRate.unit;
    return sourceHufPerUnit / targetHufPerUnit;
  }, [sourceRate, targetRate]);

  const sourceAmountNum = parseFloat(sourceAmount) || 0;

  const targetAmount = useMemo(() => {
    if (!crossRate || sourceAmountNum <= 0) return 0;
    return Math.floor(sourceAmountNum * crossRate * 100) / 100; // 2 tizedesjegy
  }, [crossRate, sourceAmountNum]);

  // HUF ellenĂ©rtĂ©k (ĂˇtlĂˇthatĂłsĂˇghoz)
  const hufEquivalent = useMemo(() => {
    if (!sourceRate || sourceAmountNum <= 0) return 0;
    return Math.round(sourceAmountNum * sourceRate.buyRate / sourceRate.unit);
  }, [sourceRate, sourceAmountNum]);

  // ElĂ©rhetĹ‘ valutĂˇk (HUF nĂ©lkĂĽl)
  const availableCurrencies = useMemo(() => {
    return rates
      .filter(r => r.currencyCode !== 'HUF')
      .map(r => r.currencyCode)
      .sort();
  }, [rates]);

  // Valuta csere
  const handleSwap = useCallback(() => {
    setSourceCurrency(targetCurrency);
    setTargetCurrency(sourceCurrency);
    setSourceAmount('');
  }, [sourceCurrency, targetCurrency]);

  // ĂśgyfĂ©l keresĂ©s
  const searchCustomers = useCallback(async (query: string) => {
    if (query.length < 2) return;
    try {
      const res = await apiClient.get(`/customers/search?q=${encodeURIComponent(query)}&limit=10`);
      setCustomers(res.data ?? []);
    } catch (err: unknown) {
      setCustomers([]);
    }
  }, []);

  // KonverziĂł vĂ©grehajtĂˇs
  const handleConvert = useCallback(async () => {
    if (sourceAmountNum <= 0) {
      setError('Adjon meg Ă©rvĂ©nyes Ă¶sszeget!');
      return;
    }
    if (sourceCurrency === targetCurrency) {
      setError('A forrĂˇs Ă©s cĂ©l valuta nem lehet azonos!');
      return;
    }
    if (!sourceRate || !targetRate || !crossRate) {
      setError('Ărfolyam nem elĂ©rhetĹ‘!');
      return;
    }

    setIsSubmitting(true);
    setError('');
    try {
      const res = await apiClient.post('/transactions/conversion', {
        sourceCurrencyCode: sourceCurrency,
        targetCurrencyCode: targetCurrency,
        sourceAmount: sourceAmountNum,
        targetAmount,
        crossRate,
        hufEquivalent,
        customerId,
      });

      setSuccess(
        `âś… KonverziĂł sikeres! ${sourceAmountNum} ${sourceCurrency} â†’ ${targetAmount} ${targetCurrency} ` +
        `(Bizonylat: ${res.data?.receiptNumber ?? 'â€”'})`
      );
      setSourceAmount('');
      setCustomerId(null);
      setCustomerName('');
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'KonverziĂł sikertelen';
      setError(`âťŚ ${msg}`);
    } finally {
      setIsSubmitting(false);
    }
  }, [sourceAmountNum, sourceCurrency, targetCurrency, sourceRate, targetRate, crossRate, targetAmount, hufEquivalent, customerId]);

  // Valuta kivĂˇlasztĂł komponens
  const CurrencySelect = ({ value, onChange, label }: {
    value: CurrencyCode;
    onChange: (v: CurrencyCode) => void;
    label: string;
  }) => (
    <div>
      <label className="block text-sm font-medium text-gray-600 mb-1">{label}</label>
      <select
        value={value}
        onChange={(e) => onChange(e.target.value as CurrencyCode)}
        className="w-full px-3 py-3 text-lg font-semibold bg-white border border-gray-300 
          rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20"
      >
        {availableCurrencies.map(code => {
          const info = getCurrencyInfo(code);
          return (
            <option key={code} value={code}>
              {info?.flag ?? ''} {code} â€” {info?.name ?? code}
            </option>
          );
        })}
      </select>
    </div>
  );

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className={`${headerColor} text-white px-6 py-4 flex items-center justify-between`}>
        <div className="flex items-center gap-3">
          <button onClick={() => navigate('/')} className="hover:opacity-80 text-2xl">â†</button>
          <h1 className="text-xl font-bold">đź”„ Valuta KonverziĂł</h1>
        </div>
        <div className="text-sm opacity-80">
          {user?.fullName} â€˘ {user?.branchCode}
        </div>
      </div>

      <div className="max-w-2xl mx-auto p-6">
        {/* HibaĂĽzenet */}
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg p-4 mb-4">
            {error}
          </div>
        )}
        {success && (
          <div className="bg-green-50 border border-green-200 text-green-700 rounded-lg p-4 mb-4">
            {success}
          </div>
        )}

        {/* KonverziĂłs panel */}
        <div className="bg-white rounded-xl shadow-sm border p-6 mb-4">
          <div className="grid grid-cols-2 gap-6">
            {/* ForrĂˇs */}
            <div>
              <CurrencySelect value={sourceCurrency} onChange={setSourceCurrency} label="ForrĂˇs valuta" />
              <div className="mt-3">
                <label className="block text-sm font-medium text-gray-600 mb-1">Ă–sszeg</label>
                <input
                  type="number"
                  value={sourceAmount}
                  onChange={(e) => { setSourceAmount(e.target.value); setError(''); setSuccess(''); }}
                  placeholder="0.00"
                  className="w-full px-4 py-3 text-2xl font-mono text-right bg-white border 
                    border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20"
                  autoFocus
                />
                {sourceRate && (
                  <p className="text-xs text-gray-400 mt-1 text-right">
                    VĂ©teli: {sourceRate.buyRate.toLocaleString('hu-HU')} / {sourceRate.unit} {sourceCurrency}
                  </p>
                )}
              </div>
            </div>

            {/* Csere gomb (kĂ¶zĂ©pen) */}
            <div className="col-span-2 flex justify-center -my-2">
              <button
                onClick={handleSwap}
                className="w-12 h-12 rounded-full bg-gray-100 hover:bg-gray-200 
                  flex items-center justify-center text-xl transition-all hover:scale-110"
                title="ValutĂˇk cserĂ©je"
              >
                â‡„
              </button>
            </div>

            {/* CĂ©l */}
            <div>
              <CurrencySelect value={targetCurrency} onChange={setTargetCurrency} label="CĂ©l valuta" />
              <div className="mt-3">
                <label className="block text-sm font-medium text-gray-600 mb-1">Kapott Ă¶sszeg</label>
                <div className="w-full px-4 py-3 text-2xl font-mono text-right bg-gray-50 
                  border border-gray-200 rounded-lg text-gray-700">
                  {targetAmount > 0 ? targetAmount.toFixed(2) : 'â€”'}
                </div>
                {targetRate && (
                  <p className="text-xs text-gray-400 mt-1 text-right">
                    EladĂˇsi: {targetRate.sellRate.toLocaleString('hu-HU')} / {targetRate.unit} {targetCurrency}
                  </p>
                )}
              </div>
            </div>
          </div>

          {/* Cross-rate info */}
          {crossRate && sourceAmountNum > 0 && (
            <div className="mt-6 p-4 bg-blue-50 rounded-lg border border-blue-100">
              <div className="grid grid-cols-3 gap-4 text-center">
                <div>
                  <p className="text-xs text-gray-500">Cross-rate</p>
                  <p className="text-lg font-semibold text-blue-700">
                    1 {sourceCurrency} = {crossRate.toFixed(4)} {targetCurrency}
                  </p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">HUF ellenĂ©rtĂ©k</p>
                  <p className="text-lg font-semibold text-gray-700">
                    {hufEquivalent.toLocaleString('hu-HU')} Ft
                  </p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">FordĂ­tott rate</p>
                  <p className="text-lg font-semibold text-gray-500">
                    1 {targetCurrency} = {(1 / crossRate).toFixed(4)} {sourceCurrency}
                  </p>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* ĂśgyfĂ©l kivĂˇlasztĂˇs (AML limit felett kĂ¶telezĹ‘) */}
        <div className="bg-white rounded-xl shadow-sm border p-6 mb-4">
          <h3 className="font-semibold text-gray-700 mb-3">đź‘¤ ĂśgyfĂ©l (opcionĂˇlis)</h3>
          {customerId ? (
            <div className="flex items-center justify-between bg-green-50 p-3 rounded-lg">
              <span className="text-green-700 font-medium">{customerName}</span>
              <button
                onClick={() => { setCustomerId(null); setCustomerName(''); }}
                className="text-sm text-red-500 hover:text-red-700"
              >
                âś• TĂ¶rlĂ©s
              </button>
            </div>
          ) : (
            <div className="relative">
              <input
                type="text"
                value={customerSearch}
                onChange={(e) => {
                  setCustomerSearch(e.target.value);
                  void searchCustomers(e.target.value);
                  setShowCustomerSearch(true);
                }}
                onFocus={() => setShowCustomerSearch(true)}
                placeholder="KeresĂ©s nĂ©v, igazolvĂˇny szĂˇm..."
                className="w-full px-3 py-2 border border-gray-300 rounded-lg 
                  focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20"
              />
              {showCustomerSearch && customers.length > 0 && (
                <div className="absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-60 overflow-y-auto">
                  {customers.map(c => (
                    <button
                      key={c.id}
                      onClick={() => {
                        setCustomerId(c.id);
                        setCustomerName(c.name);
                        setShowCustomerSearch(false);
                        setCustomerSearch('');
                      }}
                      className="w-full text-left px-3 py-2 hover:bg-gray-50 border-b last:border-0"
                    >
                      <span className="font-medium">{c.name}</span>
                      {c.documentNumber && (
                        <span className="text-xs text-gray-400 ml-2">{c.documentNumber}</span>
                      )}
                    </button>
                  ))}
                </div>
              )}
            </div>
          )}
          {hufEquivalent >= AML_IDENTIFICATION_LIMIT && !customerId && (
            <p className="text-amber-600 text-sm mt-2">
              âš ď¸Ź 5.000.000 Ft feletti konverziĂłnĂˇl az ĂĽgyfĂ©l azonosĂ­tĂˇs KĂ–TELEZĹ (AML)!
            </p>
          )}
        </div>

        {/* KonverziĂł gomb */}
        <button
          onClick={handleConvert}
          disabled={isSubmitting || sourceAmountNum <= 0 || !crossRate}
          className={`w-full py-4 text-xl font-bold text-white rounded-xl shadow-lg
            transition-all duration-200 hover:scale-[1.02] active:scale-[0.98]
            disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100
            ${btnColor}`}
        >
          {isSubmitting ? 'âŹł FeldolgozĂˇs...' : `đź”„ KonvertĂˇlĂˇs: ${sourceAmountNum || 0} ${sourceCurrency} â†’ ${targetCurrency}`}
        </button>
      </div>
    </div>
  );
}








