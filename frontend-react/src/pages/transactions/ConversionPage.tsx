import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  RefreshCw,
  ArrowRightLeft,
  Save,
  X,
  AlertCircle,
  CheckCircle,
  Calculator
} from 'lucide-react'
import {
  transactionApi,
  currencyApi,
  exchangeRateApi,
  Currency,
  ExchangeRate,
  ConversionRequest
} from '../../services/api'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal, formatInteger } from '../../utils/numberFormat'
import { getErrorMessage } from '../../utils/errorHandling'

/**
 * Konverziós tranzakció oldal
 *
 * Legacy: UJKONVERZIO form (Unit3.pas)
 * 2 lépéses folyamat:
 * 1. Forrás valuta kiválasztása és összeg megadása -> HUF érték számítás
 * 2. Cél valuta kiválasztása -> Kapott valuta összeg számítás
 *
 * Ügyfél A valutából B valutába vált, a HUF csak közvetítő számítási alap
 */
export default function ConversionPage() {
  const navigate = useNavigate()

  // State
  const [currencies, setCurrencies] = useState<Currency[]>([])
  const [rates, setRates] = useState<ExchangeRate[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  // Conversion data
  const [fromCurrencyId, setFromCurrencyId] = useState<number | null>(null)
  const [toCurrencyId, setToCurrencyId] = useState<number | null>(null)
  const [fromAmount, setFromAmount] = useState<string>('')
  const [toAmount, setToAmount] = useState<string>('')
  const [hufAmount, setHufAmount] = useState<number>(0)
  const [conversionRate, setConversionRate] = useState<number>(0)

  // Customer data (optional for conversion)
  const [customerName, setCustomerName] = useState('')
  const [notes, setNotes] = useState('')

  // Step tracking (like legacy 2-step process)
  const [step, setStep] = useState<1 | 2>(1)

  // Load currencies and rates on mount
  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true)
        const [currencyData, rateData] = await Promise.all([
          currencyApi.getActive(),
          exchangeRateApi.list()
        ])

        // Filter out HUF from conversion currencies
        const filteredCurrencies = currencyData.filter((c: Currency) => c.code !== 'HUF')
        setCurrencies(filteredCurrencies)
        setRates(rateData)

        // Select first currency as default
        if (filteredCurrencies.length >= 2 && filteredCurrencies[0] && filteredCurrencies[1]) {
          setFromCurrencyId(filteredCurrencies[0].id)
          setToCurrencyId(filteredCurrencies[1].id)
        }
      } catch (err) {
        setError(getErrorMessage(err))
      } finally {
        setLoading(false)
      }
    }

    void loadData()
  }, [])

  // Get rate for a currency
  const getRate = (currencyId: number | null): ExchangeRate | undefined => {
    if (!currencyId) return undefined
    return rates.find(r => r.currencyId === currencyId)
  }

  // Calculate conversion when inputs change
  useEffect(() => {
    if (!fromCurrencyId || !fromAmount) {
      setHufAmount(0)
      setToAmount('')
      setConversionRate(0)
      return
    }

    const fromRate = getRate(fromCurrencyId)
    if (!fromRate) return

    const amount = parseFloat(fromAmount.replace(',', '.').replace(/\s/g, '')) || 0
    if (amount <= 0) return

    // Calculate HUF value using buy rate (customer sells this currency)
    const huf = amount * fromRate.baseBuyRate
    setHufAmount(Math.round(huf))

    // Calculate to amount if target currency selected
    if (toCurrencyId) {
      const toRate = getRate(toCurrencyId)
      if (toRate) {
        // Calculate target amount using sell rate (customer buys this currency)
        const result = huf / toRate.baseSellRate
        setToAmount(result.toFixed(2).replace('.', ','))

        // Direct conversion rate
        const directRate = fromRate.baseBuyRate / toRate.baseSellRate
        setConversionRate(directRate)
      }
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fromCurrencyId, toCurrencyId, fromAmount, rates])

  // Get currency by id
  const getCurrency = (id: number | null): Currency | undefined => {
    if (!id) return undefined
    return currencies.find(c => c.id === id)
  }

  // Handle step 1 completion (source currency selected)
  const handleStep1Complete = () => {
    if (!fromCurrencyId || !fromAmount) {
      setError('Válassza ki a forrás valutát és adja meg az összeget!')
      return
    }

    const amount = parseFloat(fromAmount.replace(',', '.').replace(/\s/g, '')) || 0
    if (amount <= 0) {
      setError('Adjon meg pozitív összeget!')
      return
    }

    setError(null)
    setStep(2)
  }

  // Handle conversion submit
  const handleSubmit = async () => {
    if (!fromCurrencyId || !toCurrencyId) {
      setError('Válassza ki mindkét valutát!')
      return
    }

    if (fromCurrencyId === toCurrencyId) {
      setError('A forrás és cél valuta nem lehet ugyanaz!')
      return
    }

    const amount = parseFloat(fromAmount.replace(',', '.').replace(/\s/g, '')) || 0
    if (amount <= 0) {
      setError('Adjon meg pozitív összeget!')
      return
    }

    try {
      setLoading(true)
      setError(null)

      const request: ConversionRequest = {
        fromCurrencyId,
        toCurrencyId,
        fromAmount: amount,
        customerName: customerName || undefined,
        notes: notes || undefined
      }

      const result = await transactionApi.conversion(request)

      setSuccess(`Konverzió sikeres! Bizonylat: ${result.receiptNumber}`)

      // Reset after 2 seconds
      setTimeout(() => {
        navigate('/transactions')
      }, 2000)
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  // Reset form
  const handleReset = () => {
    setStep(1)
    setFromAmount('')
    setToAmount('')
    setHufAmount(0)
    setConversionRate(0)
    setError(null)
    setSuccess(null)
    setCustomerName('')
    setNotes('')
  }

  const fromCurrency = getCurrency(fromCurrencyId)
  const toCurrency = getCurrency(toCurrencyId)
  const fromRate = getRate(fromCurrencyId)
  const toRate = getRate(toCurrencyId)

  if (loading && currencies.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="animate-spin text-blue-600" size={32} />
      </div>
    )
  }

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <ArrowRightLeft />
          Valuta konverzió
        </h1>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => navigate('/transactions')}
            className="form-button flex items-center gap-1"
          >
            <X size={16} />
            Mégsem
          </button>
          <button
            type="button"
            onClick={handleReset}
            className="form-button flex items-center gap-1"
          >
            <RefreshCw size={16} />
            Újrakezdés
          </button>
        </div>
      </div>

      {/* Error/Success messages */}
      {error && (
        <div className="form-panel bg-red-50 border-red-200 flex items-center gap-2 text-red-700">
          <AlertCircle size={18} />
          <span>{error}</span>
        </div>
      )}

      {success && (
        <div className="form-panel bg-green-50 border-green-200 flex items-center gap-2 text-green-700">
          <CheckCircle size={18} />
          <span>{success}</span>
        </div>
      )}

      {/* Step indicator */}
      <div className="flex items-center justify-center gap-4 py-2">
        <div className={`flex items-center gap-2 px-4 py-2 rounded-full ${
          step === 1 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
        }`}>
          <span className="font-bold">1</span>
          <span>Forrás valuta</span>
        </div>
        <ArrowRightLeft className="text-gray-400" />
        <div className={`flex items-center gap-2 px-4 py-2 rounded-full ${
          step === 2 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
        }`}>
          <span className="font-bold">2</span>
          <span>Cél valuta</span>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {/* Left: Source currency */}
        <div className={`form-panel ${step === 1 ? 'ring-2 ring-blue-500' : ''}`}>
          <h2 className="font-semibold mb-3 text-green-700 flex items-center gap-2">
            <span className="bg-green-100 px-2 py-1 rounded">VESZEK</span>
            Forrás valuta (ügyfél elad)
          </h2>

          <div className="space-y-3">
            <div>
              <label htmlFor="from-currency" className="form-label">Forrás deviza</label>
              <select
                id="from-currency"
                value={fromCurrencyId ?? ''}
                onChange={(e) => setFromCurrencyId(e.target.value ? Number(e.target.value) : null)}
                className="form-input w-full"
                disabled={step === 2}
              >
                <option value="">-- Válassz valutát --</option>
                {currencies.map(c => (
                  <option key={c.id} value={c.id} disabled={c.id === toCurrencyId}>
                    {c.code} - {c.name}
                  </option>
                ))}
              </select>
            </div>

            {fromRate && (
              <div className="text-sm text-gray-600 bg-gray-50 p-2 rounded">
                <div className="flex justify-between">
                  <span>Vételi árfolyam:</span>
                  <span className="font-mono font-semibold text-green-600">
                    {formatDecimal(fromRate.baseBuyRate, 2, 4)}
                  </span>
                </div>
              </div>
            )}

            <div>
              <label htmlFor="from-amount" className="form-label">Összeg ({fromCurrency?.code || 'valuta'})</label>
              <NumberInput
                id="from-amount"
                value={fromAmount}
                onChange={setFromAmount}
                className="form-input w-full text-xl text-right"
                placeholder="0,00"
                allowDecimals={true}
                allowNegative={false}
                disabled={step === 2}
              />
            </div>

            {step === 1 && (
              <button
                type="button"
                onClick={handleStep1Complete}
                className="form-button-primary w-full"
                disabled={!fromCurrencyId || !fromAmount}
              >
                Tovább a cél valutához →
              </button>
            )}
          </div>
        </div>

        {/* Center: Calculation summary */}
        <div className="form-panel bg-gradient-to-b from-blue-50 to-white">
          <h2 className="font-semibold mb-3 flex items-center gap-2">
            <Calculator />
            Számítás
          </h2>

          <div className="space-y-4">
            {/* HUF intermediate value */}
            <div className="text-center p-3 bg-white rounded border">
              <div className="text-sm text-gray-500 mb-1">HUF érték (köztes)</div>
              <div className="text-2xl font-bold font-mono text-blue-600">
                {formatInteger(hufAmount)} Ft
              </div>
            </div>

            {/* Conversion rate */}
            {conversionRate > 0 && fromCurrency && toCurrency && (
              <div className="text-center p-3 bg-white rounded border">
                <div className="text-sm text-gray-500 mb-1">Konverziós árfolyam</div>
                <div className="text-lg font-bold font-mono">
                  1 {fromCurrency.code} = {formatDecimal(conversionRate, 4, 6)} {toCurrency.code}
                </div>
              </div>
            )}

            {/* Summary */}
            {fromAmount && toAmount && fromCurrency && toCurrency && (
              <div className="p-4 bg-green-50 rounded border border-green-200">
                <div className="text-center">
                  <div className="text-lg">
                    <span className="font-bold text-green-700">{fromAmount}</span>
                    <span className="text-gray-600"> {fromCurrency.code}</span>
                  </div>
                  <ArrowRightLeft className="mx-auto my-2 text-green-600" />
                  <div className="text-xl">
                    <span className="font-bold text-blue-700">{toAmount}</span>
                    <span className="text-gray-600"> {toCurrency.code}</span>
                  </div>
                </div>
              </div>
            )}

            {/* Optional customer/notes */}
            {step === 2 && (
              <div className="space-y-2 pt-2 border-t">
                <div>
                  <label htmlFor="customer-name" className="form-label text-sm">Ügyfél neve (opcionális)</label>
                  <input
                    id="customer-name"
                    type="text"
                    value={customerName}
                    onChange={(e) => setCustomerName(e.target.value)}
                    className="form-input w-full text-sm"
                    placeholder="Ügyfél neve..."
                  />
                </div>
                <div>
                  <label htmlFor="notes" className="form-label text-sm">Megjegyzés</label>
                  <input
                    id="notes"
                    type="text"
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    className="form-input w-full text-sm"
                    placeholder="Megjegyzés..."
                  />
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Right: Target currency */}
        <div className={`form-panel ${step === 2 ? 'ring-2 ring-blue-500' : 'opacity-75'}`}>
          <h2 className="font-semibold mb-3 text-blue-700 flex items-center gap-2">
            <span className="bg-blue-100 px-2 py-1 rounded">ELADOK</span>
            Cél valuta (ügyfél vesz)
          </h2>

          <div className="space-y-3">
            <div>
              <label htmlFor="to-currency" className="form-label">Cél deviza</label>
              <select
                id="to-currency"
                value={toCurrencyId ?? ''}
                onChange={(e) => setToCurrencyId(e.target.value ? Number(e.target.value) : null)}
                className="form-input w-full"
                disabled={step === 1}
              >
                <option value="">-- Válassz valutát --</option>
                {currencies.map(c => (
                  <option key={c.id} value={c.id} disabled={c.id === fromCurrencyId}>
                    {c.code} - {c.name}
                  </option>
                ))}
              </select>
            </div>

            {toRate && (
              <div className="text-sm text-gray-600 bg-gray-50 p-2 rounded">
                <div className="flex justify-between">
                  <span>Eladási árfolyam:</span>
                  <span className="font-mono font-semibold text-red-600">
                    {formatDecimal(toRate.baseSellRate, 2, 4)}
                  </span>
                </div>
              </div>
            )}

            <div>
              <label htmlFor="to-amount" className="form-label">Kapott összeg ({toCurrency?.code || 'valuta'})</label>
              <div className="form-input w-full text-xl text-right bg-gray-50 font-mono font-bold text-blue-600">
                {toAmount || '0,00'}
              </div>
            </div>

            {step === 2 && (
              <div className="space-y-2">
                <button
                  type="button"
                  onClick={() => setStep(1)}
                  className="form-button w-full"
                >
                  ← Vissza
                </button>
                <button
                  type="button"
                  onClick={handleSubmit}
                  className="form-button-primary w-full flex items-center justify-center gap-2"
                  disabled={loading || !toCurrencyId}
                >
                  {loading ? <RefreshCw size={16} className="animate-spin" /> : <Save size={16} />}
                  Konverzió végrehajtása
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Info panel */}
      <div className="form-panel bg-yellow-50 border-yellow-200 text-sm text-yellow-800">
        <div className="flex items-start gap-2">
          <AlertCircle size={18} className="flex-shrink-0 mt-0.5" />
          <div>
            <strong>Konverzió menete:</strong>
            <ul className="list-disc ml-4 mt-1">
              <li>Válassza ki a forrás valutát (amit az ügyfél elad)</li>
              <li>Adja meg az összeget</li>
              <li>Válassza ki a cél valutát (amit az ügyfél kap)</li>
              <li>A rendszer automatikusan kiszámolja a kapott összeget</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  )
}
