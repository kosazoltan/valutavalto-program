import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeftRight,
  Calculator,
  Printer,
  X,
  AlertCircle,
} from 'lucide-react'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal } from '../../utils/numberFormat'
import { transactionApi } from '../../services/api/index'
import type { BuyRequest, SellRequest, Transaction } from '../../services/api/index'
import { roundHuf } from '../../utils/rounding'
import { toast } from '../../components/ui/toaster'
import { saveAndSyncPendingBuySell } from '../../utils/electronTransactions'
import ReceiptPrint from '../../components/ReceiptPrint'
import { useAuthStore } from '../../stores/authStore'

import { useTransactionRates } from './hooks/useTransactionRates'
import type { CurrencyRate } from './hooks/useTransactionRates'
import { useIdentificationLevel } from './hooks/useIdentificationLevel'
import CurrencySelector from './components/CurrencySelector'
import CurrencySearchInput from './components/CurrencySearchInput'
import CustomerPanel from './components/LegacyCustomerPanel'
import type { Customer } from './components/LegacyCustomerPanel'
import { useTranslation } from 'react-i18next'

export default function TransactionPage() {
  const { t } = useTranslation()
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
  const [savedTransaction, setSavedTransaction] = useState<Transaction | null>(null)

  // Auth store for receipt info
  const { user } = useAuthStore()

  // Identification logic
  const { identificationLevel, requiresSourceVerification } = useIdentificationLevel(hufAmount)

  // Auto-select first currency when rates load
  useEffect(() => {
    const firstCurrency = currencyRates[0]
    if (firstCurrency && !selectedCurrency) {
      setSelectedCurrency(firstCurrency)
    }
  }, [currencyRates, selectedCurrency])

  // Focus on foreign amount input on mount (only if user hasn't focused elsewhere)
  useEffect(() => {
    const timerId = setTimeout(() => {
      const active = document.activeElement
      // Don't steal focus if the user already clicked/tabbed into another input
      if (active && active.tagName === 'INPUT' && active !== foreignAmountRef.current) return
      foreignAmountRef.current?.focus()
    }, 100)
    return () => clearTimeout(timerId)
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
        const nextHufAmount = roundHuf((amount / unit) * rate).toString()
        if (hufAmount !== nextHufAmount) {
          setHufAmount(nextHufAmount)
        }
      }
    } else if (lastEdited === 'huf' && hufAmount) {
      const amount = parseFloat(hufAmount.replace(',', '.').replace(/\s/g, ''))
      if (!isNaN(amount)) {
        const result = ((amount / rate) * unit).toFixed(2).replace('.', ',')
        if (foreignAmount !== result) {
          setForeignAmount(result)
        }
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
      
              // PR #116: 3-agu toast - sikeres sync / server-error / offline queue
              if (outcome.allSavedSynced) {
                toast.success('Tranzakció sikeresen rögzítve!', 'A tétel azonnal szinkronizálva lett.')
              } else if (outcome.syncErrors && outcome.syncErrors.length > 0) {
                // Server-oldali hiba (pl. rate mismatch, insufficient balance)
                const firstError = outcome.syncErrors[0]
                toast.error('Szinkron hiba - a tranzakció lokálisan mentve, de a szerver elutasitotta', firstError)
              } else {
                toast.warning('Offline mentés megtörtént', 'A tranzakció helyi queue-ba került, később szinkronizálódik.')
              }
            }
      else if (transactionType === 'BUY') {
                const request: BuyRequest = {
                  currencyId: parseInt(selectedCurrency.id),
                  currencyAmount: foreignNum,
                  customExchangeRate: rate,
                  ...customerData,
                }
                const result = await transactionApi.buy(request)
                setSavedTransaction(result)
                toast.success('Vétel tranzakció sikeresen mentve!', `Bizonylat szám: ${result.receiptNumber}`)
              }
      else {
                const request: SellRequest = {
                  currencyId: parseInt(selectedCurrency.id),
                  currencyAmount: foreignNum,
                  customExchangeRate: rate,
                  ...customerData,
                }
                const result = await transactionApi.sell(request)
                setSavedTransaction(result)
                toast.success('Eladás tranzakció sikeresen mentve!', `Bizonylat szám: ${result.receiptNumber}`)
              }

      // Don't navigate away — let user print receipt first
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Ismeretlen hiba'
      const axiosError = error as { response?: { data?: { message?: string } } }
      const serverMessage = axiosError?.response?.data?.message
      toast.error('Hiba a tranzakció mentése során!', serverMessage || message)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleSaveAndPrint = async () => {
    try {
      // Ha mar mentve van, csak a nyomtatast mutatjuk
      if (savedTransaction) return
      // Egyebkent eloszor mentunk, a mentes utan a savedTransaction allapot
      // automatikusan megjeleníti a ReceiptPrint modalt
      await handleSubmit()
    } catch (error) {
      toast.error(
        'Hiba a mentés és nyomtatás során!',
        error instanceof Error ? error.message : 'Ismeretlen hiba',
      )
    }
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
          {t('misc.ujTranzakcio')}
        </h1>
        <div className="flex gap-2">
          <button onClick={() => navigate('/transactions')} className="form-button flex items-center gap-1" title="Mégsem (Esc)">
            <X size={16} />{t('common.cancel')}
          </button>
          <button
            onClick={handleSaveAndPrint}
            disabled={isSubmitting}
            className="form-button-primary flex items-center gap-1 disabled:opacity-50 disabled:cursor-not-allowed"
            data-action="save"
            data-testid="tx-save-print"
          >
            <Printer size={16} />
            {isSubmitting ? 'Mentés...' : 'Mentés és nyomtatás'}
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
            {t('transactions.tranzakcioAdatok')}
          </h2>

          {/* Transaction type toggle */}
          <div className="flex gap-1 mb-3">
            <button
              onClick={() => setTransactionType('BUY')}
              onKeyDown={(e) => { if (e.key === 'ArrowRight' || e.key === ' ') { e.preventDefault(); setTransactionType('SELL') } }}
              data-testid="tx-type-buy"
              className={`flex-1 py-2 text-center font-semibold border rounded-l focus:outline-none focus:ring-2 focus:ring-primary ${
                transactionType === 'BUY' ? 'bg-green-600 text-white border-green-700' : 'bg-gray-100 border-form-border hover:bg-gray-200'
              }`}
            >
              {t('transactions.vetel')}
              <div className="text-xs font-normal">{t('transactions.ugyfelElad')}{selectedCurrency?.code || 'devizát'})</div>
            </button>
            <button
              onClick={() => setTransactionType('SELL')}
              onKeyDown={(e) => { if (e.key === 'ArrowLeft' || e.key === ' ') { e.preventDefault(); setTransactionType('BUY') } }}
              data-testid="tx-type-sell"
              className={`flex-1 py-2 text-center font-semibold border rounded-r focus:outline-none focus:ring-2 focus:ring-primary ${
                transactionType === 'SELL' ? 'bg-blue-600 text-white border-blue-700' : 'bg-gray-100 border-form-border hover:bg-gray-200'
              }`}
            >
              {t('transactions.eladas')}
              <div className="text-xs font-normal">{t('transactions.ugyfelVesz')}{selectedCurrency?.code || 'devizát'})</div>
            </button>
          </div>

          {/* Currency quick search */}
          <CurrencySearchInput
            currencyRates={currencyRates}
            onSelect={handleCurrencySelect}
          />

          {/* Current rate display */}
          <div className="form-group-box pt-4 mb-3">
            <span className="form-group-box-title">{t('transactions.alkalmazottArfolyam')}</span>
            <div className="text-center">
              <span className="text-3xl font-bold font-mono text-primary">{formatDecimal(currentRate, 2, 2)}</span>
              <span className="ml-2 text-gray-500">{t('transactions.huf1')}{selectedCurrency?.code || ''}</span>
            </div>
          </div>

          {/* Amount inputs */}
          <div className="space-y-3">
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">{selectedCurrency?.code || 'Deviza'} {t('transactions.osszeg')}</span>
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
                data-testid="tx-foreign-amount"
              />
            </div>
            <div className="text-center text-gray-400">
              <ArrowLeftRight size={24} className="mx-auto" />
            </div>
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">{t('stornos.hufOsszeg')}</span>
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
                data-testid="tx-huf-amount"
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
                <strong>{t('transactions.forrasokIgazolasaSzukseges')}</strong>
                <div className="text-xs mt-1">{t('transactions.3500000FtFelettiTranzakcio')}</div>
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

      {/* Receipt print modal */}
      {savedTransaction && (
        <ReceiptPrint
          transaction={savedTransaction}
          companyName={user?.companyName || 'Exclusive Best Change Zrt.'}
          companyAddress={''}
          companyTaxNumber={''}
          branchName={user?.branchName || ''}
          workerName={user?.fullName || ''}
          onClose={() => {
            setSavedTransaction(null)
            navigate('/transactions')
          }}
        />
      )}

      {/* Keyboard shortcuts help */}
      <div className="text-xs text-gray-500 p-2 bg-gray-50 rounded border">
        <div className="font-semibold mb-1">{t('transactions.billentyuzetHasznalat')}</div>
        <div className="grid grid-cols-3 gap-2">
          <div>{t('transactions.escMegsem')}</div>
          <div>{t('transactions.18DevizaValasztas')}</div>
          <div>{t('transactions.DevizaNavigacio')}</div>
          <div>{t('transactions.enterKovetkezoMezo')}</div>
          <div>{t('transactions.enterGombrolMuveletVegrehajtas')}</div>
          <div>{t('transactions.tabMezokKozottiLepes')}</div>
        </div>
      </div>
    </div>
  )
}
