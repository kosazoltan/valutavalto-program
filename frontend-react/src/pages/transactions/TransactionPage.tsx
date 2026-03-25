import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeftRight,
  Calculator,
  Printer,
  Save,
  X,
  AlertCircle,
} from 'lucide-react'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal } from '../../utils/numberFormat'
import { transactionApi } from '../../services/api/index'
import type { BuyRequest, SellRequest } from '../../services/api/index'
import { roundHuf } from '../../utils/rounding'
import { toast } from '../../components/ui/toaster'
import { saveAndSyncPendingBuySell } from '../../utils/electronTransactions'

import { useTransactionRates } from './hooks/useTransactionRates'
import type { CurrencyRate } from './hooks/useTransactionRates'
import { useIdentificationLevel } from './hooks/useIdentificationLevel'
import CurrencySelector from './components/CurrencySelector'
import CustomerPanel from './components/CustomerPanel'
import type { Customer } from './components/CustomerPanel'

export default function TransactionPage() {
  const navigate = useNavigate()
  const { currencyRates, electronQueueAvailable } = useTransactionRates()

  // Refs for keyboard navigation
  const foreignAmountRef = useRef<HTMLInputElement>(null)
  const hufAmountRef = useRef<HTMLInputElement>(null)

  // Transaction state
  const [transactionType, setTransactionType] = useState<'BUY' | 'SELL'>('BUY')
  const [selectedCurrency, setSelectedCurrency] = useState<CurrencyRate | null>(null)
  const [foreignAmount, setForeignAmount] = useState('')
  const [hufAmount, setHufAmount] = useState('')
  const [lastEdited, setLastEdited] = useState<'foreign' | 'huf'>('foreign')

  // Customer state
  const [customer, setCustomer] = useState<Customer | null>(null)
  const [customerAddress, setCustomerAddress] = useState('')

  // Submission state
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Identification logic
  const { identificationLevel, requiresSourceVerification } = useIdentificationLevel(hufAmount)

  // Auto-select first currency when rates load
  useEffect(() => {
    const firstCurrency = currencyRates[0]
    if (firstCurrency && !selectedCurrency) {
      setSelectedCurrency(firstCurrency)
    }
  }, [currencyRates, selectedCurrency])

  // Focus on foreign amount input on mount
  useEffect(() => {
    setTimeout(() => foreignAmountRef.current?.focus(), 100)
  }, [])

  // Calculate amounts
  useEffect(() => {
    if (!selectedCurrency) return

    const rate = transactionType === 'BUY'
      ? selectedCurrency.buyRate
      : selectedCurrency.sellRate
    const unit = selectedCurrency.unit || 1

    if (lastEdited === 'foreign' && foreignAmount) {
      const amount = parseFloat(foreignAmount.replace(',', '.'))
      if (!isNaN(amount)) {
        setHufAmount(roundHuf((amount / unit) * rate).toString())
      }
    } else if (lastEdited === 'huf' && hufAmount) {
      const amount = parseFloat(hufAmount.replace(',', '.').replace(/\s/g, ''))
      if (!isNaN(amount)) {
        const result = ((amount / rate) * unit).toFixed(2).replace('.', ',')
        setForeignAmount(result)
      }
    }
  }, [foreignAmount, hufAmount, selectedCurrency, transactionType, lastEdited])

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') navigate('/transactions')
      if (e.key >= '1' && e.key <= '8' && !e.ctrlKey && !e.altKey) {
        const target = e.target as HTMLElement
        if (target.tagName !== 'INPUT' && target.tagName !== 'TEXTAREA' && !target.isContentEditable) {
          const index = parseInt(e.key, 10) - 1
          if (currencyRates[index]) {
            setSelectedCurrency(currencyRates[index])
            setTimeout(() => foreignAmountRef.current?.focus(), 50)
          }
        }
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [currencyRates, navigate])

  const handleCurrencySelect = (currency: CurrencyRate) => {
    setSelectedCurrency(currency)
    setTimeout(() => foreignAmountRef.current?.focus(), 50)
  }

  const handleForeignAmountChange = (value: string) => {
    setForeignAmount(value)
    setLastEdited('foreign')
  }

  const handleHufAmountChange = (value: string) => {
    setHufAmount(value)
    setLastEdited('huf')
  }

  const handleForeignAmountKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      hufAmountRef.current?.focus()
    }
  }

  const handleHufAmountKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      if (identificationLevel !== 'SIMPLE' && !customer) {
        const el = document.querySelector<HTMLInputElement>('[data-field="customer-name"]')
        el?.focus()
      } else {
        setTimeout(() => document.querySelector<HTMLButtonElement>('[data-action="save"]')?.focus(), 50)
      }
    }
  }

  const handleSubmit = async () => {
    if (!selectedCurrency || isSubmitting) return

    const foreignNum = parseFloat(foreignAmount.replace(',', '.')) || 0
    const hufNum = parseFloat(hufAmount.replace(/\s/g, '').replace(',', '.')) || 0
    if (foreignNum <= 0 || hufNum <= 0) {
      toast.warning('Érvénytelen összeg', 'Kérem adjon meg érvényes összeget!')
      return
    }

    if (identificationLevel !== 'SIMPLE' && !customer) {
      toast.warning('Azonosítás szükséges', 'Ügyfél azonosítás szükséges ehhez az összeghez!')
      return
    }

    setIsSubmitting(true)
    try {
      const customerData = customer ? {
        customerId: customer.id,
        customerName: customer.name,
        customerDocumentNumber: customer.documentNumber,
        customerNationality: customer.nationality,
      } : {}

      const rate = transactionType === 'BUY'
        ? selectedCurrency.buyRate
        : selectedCurrency.sellRate

      if (electronQueueAvailable) {
        const outcome = await saveAndSyncPendingBuySell([
          {
            type: transactionType,
            currencyCode: selectedCurrency.code,
            foreignAmount: foreignNum,
            hufAmount: hufNum,
            roundedHufAmount: roundHuf(hufNum),
            rate,
            handlingFee: null,
            discountPercent: null,
            customerIdentifier: customer?.documentNumber ?? null,
            customerName: customer?.name ?? null,
            customerDocumentNumber: customer?.documentNumber ?? null,
            customerAddress: customerAddress || null,
            denominations: null,
          },
        ])

        if (outcome.allSavedSynced) {
          toast.success('Tranzakció sikeresen rögzítve!', 'A tétel azonnal szinkronizálva lett.')
        } else {
          toast.warning('Offline mentés megtörtént', 'A tranzakció helyi queue-ba került, később szinkronizálódik.')
        }
      } else {
        if (transactionType === 'BUY') {
          const request: BuyRequest = {
            currencyId: parseInt(selectedCurrency.id),
            currencyAmount: foreignNum,
            customExchangeRate: rate,
            ...customerData,
          }
          const result = await transactionApi.buy(request)
          toast.success('Vétel tranzakció sikeresen mentve!', `Bizonylat szám: ${result.receiptNumber}`)
        } else {
          const request: SellRequest = {
            currencyId: parseInt(selectedCurrency.id),
            currencyAmount: foreignNum,
            customExchangeRate: rate,
            ...customerData,
          }
          const result = await transactionApi.sell(request)
          toast.success('Eladás tranzakció sikeresen mentve!', `Bizonylat szám: ${result.receiptNumber}`)
        }
      }

      navigate('/transactions')
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Ismeretlen hiba'
      const axiosError = error as { response?: { data?: { message?: string } } }
      const serverMessage = axiosError?.response?.data?.message
      toast.error('Hiba a tranzakció mentése során!', serverMessage || message)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handlePrint = () => {
    if (typeof window === 'undefined' || typeof window.print !== 'function') {
      toast.error('Nyomtatás nem elérhető ezen a környezeten')
      return
    }
    window.print()
  }

  const currentRate = selectedCurrency
    ? (transactionType === 'BUY' ? selectedCurrency.buyRate : selectedCurrency.sellRate)
    : 0

  return (
    <div className="space-y-3">
      {/* Page header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <ArrowLeftRight />
          Új tranzakció
        </h1>
        <div className="flex gap-2">
          <button onClick={() => navigate('/transactions')} className="form-button flex items-center gap-1" title="Mégsem (Esc)">
            <X size={16} /> Mégsem
          </button>
          <button onClick={handlePrint} className="form-button flex items-center gap-1" title="Nyomtatás">
            <Printer size={16} /> Nyomtatás
          </button>
          <button
            onClick={handleSubmit}
            disabled={isSubmitting}
            className="form-button-primary flex items-center gap-1 disabled:opacity-50 disabled:cursor-not-allowed"
            data-action="save"
          >
            <Save size={16} />
            {isSubmitting ? 'Mentés...' : 'Mentés'}
          </button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3">
        {/* Left: Currency selection */}
        <CurrencySelector
          currencyRates={currencyRates}
          selectedCurrency={selectedCurrency}
          onSelect={handleCurrencySelect}
        />

        {/* Center: Transaction details */}
        <div className="form-panel">
          <h2 className="font-semibold mb-2 pb-1 border-b flex items-center gap-2">
            <Calculator size={18} />
            Tranzakció adatok
          </h2>

          {/* Transaction type toggle */}
          <div className="flex gap-1 mb-3">
            <button
              onClick={() => setTransactionType('BUY')}
              onKeyDown={(e) => { if (e.key === 'ArrowRight' || e.key === ' ') { e.preventDefault(); setTransactionType('SELL') } }}
              className={`flex-1 py-2 text-center font-semibold border rounded-l focus:outline-none focus:ring-2 focus:ring-primary ${
                transactionType === 'BUY' ? 'bg-green-600 text-white border-green-700' : 'bg-gray-100 border-form-border hover:bg-gray-200'
              }`}
            >
              VÉTEL
              <div className="text-xs font-normal">(Ügyfél elad {selectedCurrency?.code || 'devizát'})</div>
            </button>
            <button
              onClick={() => setTransactionType('SELL')}
              onKeyDown={(e) => { if (e.key === 'ArrowLeft' || e.key === ' ') { e.preventDefault(); setTransactionType('BUY') } }}
              className={`flex-1 py-2 text-center font-semibold border rounded-r focus:outline-none focus:ring-2 focus:ring-primary ${
                transactionType === 'SELL' ? 'bg-blue-600 text-white border-blue-700' : 'bg-gray-100 border-form-border hover:bg-gray-200'
              }`}
            >
              ELADÁS
              <div className="text-xs font-normal">(Ügyfél vesz {selectedCurrency?.code || 'devizát'})</div>
            </button>
          </div>

          {/* Current rate display */}
          <div className="form-group-box pt-4 mb-3">
            <span className="form-group-box-title">Alkalmazott árfolyam</span>
            <div className="text-center">
              <span className="text-3xl font-bold font-mono text-primary">{formatDecimal(currentRate, 2, 2)}</span>
              <span className="ml-2 text-gray-500">HUF / 1 {selectedCurrency?.code || ''}</span>
            </div>
          </div>

          {/* Amount inputs */}
          <div className="space-y-3">
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">{selectedCurrency?.code || 'Deviza'} összeg</span>
              <NumberInput
                ref={foreignAmountRef}
                value={foreignAmount}
                onChange={handleForeignAmountChange}
                onKeyDown={handleForeignAmountKeyDown}
                className="form-input w-full text-xl text-right h-12 focus:ring-2 focus:ring-primary"
                placeholder="0,00"
                allowDecimals={true}
                allowNegative={false}
                autoFocus
                step="0.01"
              />
            </div>
            <div className="text-center text-gray-400">
              <ArrowLeftRight size={24} className="mx-auto" />
            </div>
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">HUF összeg</span>
              <NumberInput
                ref={hufAmountRef}
                value={hufAmount}
                onChange={handleHufAmountChange}
                onKeyDown={handleHufAmountKeyDown}
                className="form-input w-full text-xl text-right h-12 focus:ring-2 focus:ring-primary"
                placeholder="0,00"
                allowDecimals={true}
                allowNegative={false}
                min={0}
                step="0.01"
              />
            </div>
          </div>

          {/* Identification warnings */}
          {identificationLevel !== 'SIMPLE' && (
            <div className={`mt-3 p-2 rounded text-sm flex items-start gap-2 ${
              identificationLevel === 'FULL'
                ? 'bg-red-50 border border-red-200 text-red-700'
                : 'bg-yellow-50 border border-yellow-200 text-yellow-700'
            }`}>
              <AlertCircle size={18} className="flex-shrink-0 mt-0.5" />
              <div>
                <strong>{identificationLevel === 'FULL' ? 'Teljes azonosítás szükséges!' : 'Egyszerűsített azonosítás szükséges!'}</strong>
                <div className="text-xs mt-1">
                  {identificationLevel === 'FULL' ? '300.000 Ft feletti tranzakció' : '100.000 - 300.000 Ft közötti tranzakció'}
                </div>
              </div>
            </div>
          )}
          {requiresSourceVerification && (
            <div className="mt-2 p-2 rounded bg-red-100 border border-red-300 text-red-800 text-sm flex items-start gap-2">
              <AlertCircle size={18} className="flex-shrink-0 mt-0.5" />
              <div>
                <strong>Források igazolása szükséges!</strong>
                <div className="text-xs mt-1">3.500.000 Ft feletti tranzakció</div>
              </div>
            </div>
          )}
        </div>

        {/* Right: Customer panel */}
        <CustomerPanel
          customer={customer}
          onCustomerChange={setCustomer}
          identificationLevel={identificationLevel}
          selectedCurrencyCode={selectedCurrency?.code || ''}
          onCustomerAddressChange={setCustomerAddress}
        />
      </div>

      {/* Keyboard shortcuts help */}
      <div className="text-xs text-gray-500 p-2 bg-gray-50 rounded border">
        <div className="font-semibold mb-1">Billentyűzet használat:</div>
        <div className="grid grid-cols-3 gap-2">
          <div>Esc - Mégsem</div>
          <div>1-8 - Deviza választás</div>
          <div>↑↓ - Deviza navigáció</div>
          <div>Enter - Következő mező</div>
          <div>Enter (gombról) - Művelet végrehajtás</div>
          <div>Tab - Mezők közötti lépés</div>
        </div>
      </div>
    </div>
  )
}
