import { useState, useEffect, useRef } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import TransactionReadOnlyView from './TransactionReadOnlyView'
import { ArrowLeftRight, Calculator, Printer, X, AlertCircle } from 'lucide-react'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal } from '../../utils/numberFormat'
import { receiptApi, transactionApi } from '../../services/api/index'
import type { BuyRequest, SellRequest, Transaction } from '../../services/api/index'
import { api } from '../../services/api/client'
import { roundHuf } from '../../utils/rounding'
import { toast } from '../../components/ui/toaster'
import { saveAndSyncPendingBuySell } from '../../utils/electronTransactions'
import { logger } from '../../utils/logger'
import ReceiptPrint from '../../components/ReceiptPrint'
import AmlApproverModal, { toApprovalCustomer } from '../../components/auth/AmlApproverModal'
import { useAuthStore } from '../../stores/authStore'

import { useTransactionRates } from './hooks/useTransactionRates'
import type { CurrencyRate } from './hooks/useTransactionRates'
import { useIdentificationLevel } from './hooks/useIdentificationLevel'
import CurrencySelector from './components/CurrencySelector'
import CurrencySearchInput from './components/CurrencySearchInput'
import CustomerPanel from './components/CustomerPanel'
import type { CustomerPanelData } from './components/CustomerPanel'
import type { AmlCheckResultDto } from '../../services/api/transactions'
import { useTranslation } from 'react-i18next'
import {
  getBandForAmount,
  isWithinBand,
  isWithinHardLimit,
  getHardLimitMessage,
} from '../../utils/rateBands'
import RateAuthDialog from './components/RateAuthDialog'

export default function TransactionPage() {
  // FK-071 FR-4: a /transactions/:id route READ-ONLY nézetet ad (a 👁 gomb célja),
  // a felviteli űrlap csak a paraméter nélküli /transactions/new route-on nyílik.
  // Külön al-komponensek: a hook-sorrend így route-váltásnál is stabil marad.
  const { id: routeId } = useParams<{ id: string }>()
  if (routeId) {
    return <TransactionReadOnlyView transactionId={routeId} />
  }
  return <TransactionEntryPage />
}

function TransactionEntryPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const { currencyRates, rawExchangeRates, electronQueueAvailable } = useTransactionRates()

  // Refs for keyboard navigation
  const foreignAmountRef = useRef<HTMLInputElement>(null)
  const hufAmountRef = useRef<HTMLInputElement>(null)

  // Transaction state
  const [transactionType, setTransactionType] = useState<'BUY' | 'SELL'>('BUY')
  const [selectedCurrency, setSelectedCurrency] = useState<CurrencyRate | null>(null)
  const [foreignAmount, setForeignAmount] = useState('')
  const [hufAmount, setHufAmount] = useState('')
  const [lastEdited, setLastEdited] = useState<'foreign' | 'huf'>('foreign')

  // Customer state (managed by CustomerPanel)
  const customerDataRef = useRef<CustomerPanelData | null>(null)
  const amlResultRef = useRef<AmlCheckResultDto | null>(null)
  const approverWorkerIdRef = useRef<number | null>(null)
  const approvalSessionIdRef = useRef<string | null>(null)
  const amlPrecheckInFlightRef = useRef(false)
  const [amlBlocked, setAmlBlocked] = useState(false)
  const [showAmlApprover, setShowAmlApprover] = useState(false)
  const [amlApprovalReason, setAmlApprovalReason] = useState('')

  // Devizastátusz
  const [foreignStatus, setForeignStatus] = useState<'DOMESTIC' | 'FOREIGN'>('FOREIGN')

  // Custom rate state
  const [customRate, setCustomRate] = useState<number | null>(null)
  const [editingRate, setEditingRate] = useState(false)
  const [rateText, setRateText] = useState('')
  const rateInputRef = useRef<HTMLInputElement>(null)

  // Rate auth dialog state
  const [showRateAuth, setShowRateAuth] = useState(false)
  const [rateAuthPendingRate, setRateAuthPendingRate] = useState(0)
  const rateAuthApprovedRef = useRef(false)

  // Submission state
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [savedTransaction, setSavedTransaction] = useState<Transaction | null>(null)

  // Auth store for receipt info
  const { user } = useAuthStore()
  const worker = useAuthStore((s) => s.worker)

  // Identification logic
  const { identificationLevel, minimumLevel, setIdentificationLevel, requiresSourceVerification } =
    useIdentificationLevel(hufAmount)

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

  const rateObj = selectedCurrency
    ? rawExchangeRates.find((r) => r.currencyCode === selectedCurrency.code)
    : undefined

  const baseRate = selectedCurrency
    ? transactionType === 'BUY'
      ? selectedCurrency.buyRate
      : selectedCurrency.sellRate
    : 0

  const effectiveRate =
    customRate ??
    (() => {
      if (!rateObj) return baseRate
      const foreignNum = parseFloat((foreignAmount || '0').replace(',', '.')) || 0
      if (foreignNum <= 0) return baseRate
      const unit = selectedCurrency?.unit || 1
      const baseAmountHuf = (foreignNum / unit) * baseRate
      const band = getBandForAmount(
        rateObj,
        transactionType === 'BUY' ? 'buy' : 'sell',
        baseAmountHuf,
      )
      return band.tierRate
    })()

  const currentRate = effectiveRate

  // Calculate amounts using the effective rate (custom or tier-based)
  useEffect(() => {
    if (!selectedCurrency || currentRate <= 0) return

    const unit = selectedCurrency.unit || 1

    if (lastEdited === 'foreign' && foreignAmount) {
      const amount = parseFloat(foreignAmount.replace(',', '.'))
      if (!isNaN(amount)) {
        const nextHufAmount = roundHuf((amount / unit) * currentRate).toString()
        if (hufAmount !== nextHufAmount) {
          setHufAmount(nextHufAmount)
        }
      }
    } else if (lastEdited === 'huf' && hufAmount) {
      const amount = parseFloat(hufAmount.replace(',', '.').replace(/\s/g, ''))
      if (!isNaN(amount)) {
        const result = ((amount / currentRate) * unit).toFixed(2).replace('.', ',')
        if (foreignAmount !== result) {
          setForeignAmount(result)
        }
      }
    }
  }, [foreignAmount, hufAmount, selectedCurrency, currentRate, lastEdited])

  // Keyboard shortcuts
  // Lint-audit 2026-08-09 (react-hooks/exhaustive-deps): a `handleCancel` sima
  // fuggveny-deklaracio, ezert MINDEN renderben uj referencia — a deps-ben tartva
  // a keydown listener minden renderben le-fel csatolodott. Ref-en keresztul
  // hivjuk, igy a listener egyszer regisztral, de mindig a FRISS closure-t hasznalja
  // (ugyanaz a minta, mint a CashierTransactionPage `isSubmittingRef`-je).
  const handleCancelRef = useRef(handleCancel)
  handleCancelRef.current = handleCancel

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') void handleCancelRef.current()
      if (e.key >= '1' && e.key <= '8' && !e.ctrlKey && !e.altKey) {
        const target = e.target as HTMLElement
        if (
          target.tagName !== 'INPUT' &&
          target.tagName !== 'TEXTAREA' &&
          !target.isContentEditable
        ) {
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
  }, [currencyRates])

  const switchTransactionType = (type: 'BUY' | 'SELL') => {
    setTransactionType(type)
    setCustomRate(null)
    rateAuthApprovedRef.current = false
  }

  const handleCurrencySelect = (currency: CurrencyRate) => {
    setSelectedCurrency(currency)
    setCustomRate(null)
    rateAuthApprovedRef.current = false
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

  const handleRateChange = (value: string) => {
    setRateText(value)
    const cleaned = value.replace(/[^0-9.,]/g, '').replace(',', '.')
    const parsed = parseFloat(cleaned)
    if (!isNaN(parsed) && parsed > 0) {
      setCustomRate(parsed)
    } else {
      setCustomRate(null)
    }
  }

  const handleRateBlur = () => {
    setEditingRate(false)
    if (customRate == null || !rateObj) return
    const mode = transactionType === 'BUY' ? ('buy' as const) : ('sell' as const)
    const foreignNum = parseFloat((foreignAmount || '0').replace(',', '.')) || 0
    const unit = selectedCurrency?.unit || 1
    const baseAmountHuf = (foreignNum / unit) * baseRate

    if (!isWithinHardLimit(customRate, rateObj.officialRate, mode)) {
      toast.error(
        'Árfolyam meghaladja a hard limitet',
        getHardLimitMessage(mode, rateObj.officialRate!),
      )
      setCustomRate(null)
      return
    }

    if (rateAuthApprovedRef.current) return

    if (!isWithinBand(rateObj, customRate, mode, baseAmountHuf)) {
      setRateAuthPendingRate(customRate)
      setShowRateAuth(true)
    }
  }

  const handleHufAmountKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault()
      if (identificationLevel !== 'SIMPLE' && !customerDataRef.current?.name?.trim()) {
        const el = document.querySelector<HTMLInputElement>('[data-testid="customer-name-input"]')
        el?.focus()
      } else {
        setTimeout(
          () => document.querySelector<HTMLButtonElement>('[data-action="save"]')?.focus(),
          50,
        )
      }
    }
  }

  async function handleCancel() {
    const foreignNum = parseFloat(foreignAmount.replace(',', '.')) || 0
    const hufNum = parseFloat(hufAmount.replace(/\s/g, '').replace(',', '.')) || 0
    const cd = customerDataRef.current
    const hasDraftTransaction = Boolean(foreignAmount || hufAmount || customRate != null || cd)
    if (hasDraftTransaction) {
      if (!confirm('Biztosan elveti a tranzakciot?')) return
      try {
        const receipt = await receiptApi.createCancelledTransaction({
          mode: transactionType,
          reason: 'USER_CANCELLED',
          customerName: cd?.name,
          customerDocumentNumber: cd?.documentNumber,
          lines: [
            {
              currencyCode: selectedCurrency?.code,
              foreignAmount: foreignNum > 0 ? foreignNum : undefined,
              rate: currentRate > 0 ? currentRate : undefined,
              hufAmount: hufNum > 0 ? hufNum : undefined,
            },
          ],
        })
        toast.info('Megszakított bizonylat rögzítve', `Bizonylat: ${receipt.receiptNumber}`)
      } catch (error) {
        logger.warn('TransactionPage', 'Cancelled transaction receipt could not be recorded', error)
        toast.warning(
          'Megszakítás lokálisan elvetve',
          'A megszakított bizonylat szerveroldali rögzítése nem sikerült. Ellenőrizze a kapcsolatot.',
        )
      }
    }
    navigate('/transactions')
  }

  const resetAmlApproval = () => {
    approverWorkerIdRef.current = null
    approvalSessionIdRef.current = null
  }

  const handleSubmit = async () => {
    if (!selectedCurrency || isSubmitting) return

    const foreignNum = parseFloat(foreignAmount.replace(',', '.')) || 0
    const hufNum = parseFloat(hufAmount.replace(/\s/g, '').replace(',', '.')) || 0
    if (foreignNum <= 0 || hufNum <= 0) {
      toast.warning('Érvénytelen összeg', 'Kérem adjon meg érvényes összeget!')
      return
    }

    // Cashier-minta: fokozatos Pmt. azonosítási kapu (:765-789).
    const cd = customerDataRef.current
    const aml = amlResultRef.current
    if (identificationLevel !== 'SIMPLE') {
      if (!cd?.name?.trim()) {
        toast.warning(
          'Ügyfél azonosítás kötelező',
          '100.000 Ft feletti tranzakcióhoz ügyfél azonosítás KÖTELEZŐ!',
        )
        return
      }
      if (identificationLevel === 'SIMPLIFIED' && (!cd?.birthPlace || !cd?.birthDate)) {
        toast.warning(
          'Egyszerűsített azonosítás hiányos',
          '100.000 Ft felett születési hely és születési idő is KÖTELEZŐ!',
        )
        return
      }
      if (
        identificationLevel === 'FULL' &&
        (!cd?.documentNumber?.trim() ||
          !cd?.birthPlace ||
          !cd?.birthDate ||
          !cd?.motherName ||
          !cd?.address)
      ) {
        toast.warning(
          'Teljes azonosítás kötelező',
          '300.000 Ft felett teljes ügyféladatsor szükséges (okmányszám, születési hely/idő, anyja neve, lakcím)!',
        )
        return
      }
    }
    if (aml?.blocked) {
      toast.error('Tranzakcio blokkolt', 'AML szabalysertes — a tranzakcio nem rogzitheto!')
      return
    }

    if (approverWorkerIdRef.current == null) {
      if (amlPrecheckInFlightRef.current) return
      amlPrecheckInFlightRef.current = true
      try {
        const checkRes = await api.post('/aml-approval/check-required', {
          amountHuf: hufNum,
          customerId: cd?.id || undefined,
          customerName: cd?.name || undefined,
          documentNumber: cd?.documentNumber || undefined,
          currencyCode: selectedCurrency.code,
          customerNationality: cd?.nationality || undefined,
        })
        if (checkRes.data?.requiresApproval) {
          approvalSessionIdRef.current = crypto.randomUUID()
          setAmlApprovalReason(
            typeof checkRes.data?.reason === 'string' ? checkRes.data.reason : '',
          )
          setShowAmlApprover(true)
          return
        }
      } catch (err) {
        logger.warn('TransactionPage', 'AML approval pre-check hiba (nem blokkoló)', err)
      } finally {
        amlPrecheckInFlightRef.current = false
      }
    }

    setIsSubmitting(true)
    try {
      // Cashier-minta: REST AML payload (:880-933), S1-ben approver mezők nélkül.
      const customerData = cd
        ? {
            ...(cd.id ? { customerId: cd.id } : {}),
            customerName: cd.name || undefined,
            customerDocumentNumber: cd.documentNumber || undefined,
            customerDocumentType: cd.documentType || undefined,
            customerNationality: cd.nationality || undefined,
            customerBirthPlace: cd.birthPlace || undefined,
            customerBirthDate: cd.birthDate || undefined,
            customerMotherName: cd.motherName || undefined,
            customerAddress: cd.address || undefined,
            customerIsPep: cd.isPep,
            sourceOfFunds: cd.sourceOfFunds,
            sourceOfFundsDocType: cd.sourceOfFundsDocType,
            sourceOfFundsDocDate: cd.sourceOfFundsDocDate,
            customerOnOwnBehalf: cd.onOwnBehalf,
            customerActorName: cd.actorName,
            customerPepKind: cd.pepKind ?? undefined,
            customerActorBirthPlace: cd.actorIdentity?.birthPlace,
            customerActorBirthDate: cd.actorIdentity?.birthDate,
            customerActorMotherName: cd.actorIdentity?.motherName,
            customerActorNationality: cd.actorIdentity?.nationality,
            customerActorDocumentType: cd.actorIdentity?.documentType,
            customerActorDocumentNumber: cd.actorIdentity?.documentNumber,
            customerActorAddress: cd.actorIdentity?.address,
            approverWorkerId: approverWorkerIdRef.current ?? undefined,
            approvalSessionId: approvalSessionIdRef.current ?? undefined,
            isLegalEntityCustomer: cd.isLegalEntity ?? undefined,
            legalEntityName: cd.legalEntityName,
            legalEntitySeat: cd.legalEntitySeat,
            legalEntityTaxNumber: cd.legalEntityTaxNumber,
            legalDeedNumber: cd.legalDeedNumber,
            beneficialOwners: cd.beneficialOwners?.map((o) => ({
              name: o.name,
              address: o.address || undefined,
              birthPlace: o.birthPlace || undefined,
              birthDate: o.birthDate || undefined,
              nationality: o.nationality || undefined,
              residenceAbroad: o.residenceAbroad || undefined,
              interestNature: o.interestNature || undefined,
              interestExtent: o.interestExtent || undefined,
              isPep: o.isPep,
            })),
          }
        : {}

      const rate = currentRate

      if (electronQueueAvailable) {
        const actorIdentity = cd?.actorIdentity ?? null
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
            customerIdentifier: cd?.documentNumber ?? null,
            customerName: cd?.name ?? null,
            customerDocumentNumber: cd?.documentNumber ?? null,
            customerAddress: cd?.address ?? null,
            foreignStatus,
            customerBirthPlace: cd?.birthPlace ?? null,
            customerBirthDate: cd?.birthDate ?? null,
            customerMotherName: cd?.motherName ?? null,
            customerNationality: cd?.nationality ?? null,
            customerDocumentType: cd?.documentType ?? null,
            sourceOfFunds: cd?.sourceOfFunds ?? null,
            customerIsPep: cd?.isPep ?? null,
            customerOnOwnBehalf: cd?.onOwnBehalf ?? null,
            customerActorName: cd?.actorName ?? null,
            customerPepKind: cd?.pepKind ?? null,
            customerActorBirthPlace: actorIdentity?.birthPlace ?? null,
            customerActorBirthDate: actorIdentity?.birthDate ?? null,
            customerActorMotherName: actorIdentity?.motherName ?? null,
            customerActorNationality: actorIdentity?.nationality ?? null,
            customerActorDocumentType: actorIdentity?.documentType ?? null,
            customerActorDocumentNumber: actorIdentity?.documentNumber ?? null,
            customerActorAddress: actorIdentity?.address ?? null,
            approverWorkerId: approverWorkerIdRef.current,
            approvalSessionId: approvalSessionIdRef.current,
            isLegalEntityCustomer: cd?.isLegalEntity ?? null,
            legalEntityName: cd?.legalEntityName || null,
            legalEntitySeat: cd?.legalEntitySeat || null,
            legalEntityTaxNumber: cd?.legalEntityTaxNumber || null,
            legalDeedNumber: cd?.legalDeedNumber || null,
            beneficialOwnersJson: cd?.beneficialOwners?.length
              ? JSON.stringify(cd.beneficialOwners)
              : null,
            denominations: null,
          },
        ])

        // PR #116 + FKH-032 FR-4: 3-agu toast — azonnal konyvelve / konkret hiba / offline queue
        if (outcome.allSavedSynced) {
          toast.success('Tranzakció sikeresen rögzítve!', 'A tétel azonnal könyvelve lett.')
        } else if (outcome.syncErrors && outcome.syncErrors.length > 0) {
          // Server-oldali hiba (pl. rate mismatch, insufficient balance) — a célzott
          // azonnali kísérlet tétel-szintű, konkrét oka.
          const firstError = outcome.syncErrors[0]
          toast.error('Azonnali könyvelés sikertelen — a tranzakció lokálisan mentve', firstError)
        } else {
          toast.warning(
            'Offline mentés megtörtént',
            'A tranzakció helyi queue-ba került, később szinkronizálódik.',
          )
        }
        resetAmlApproval()
      } else if (transactionType === 'BUY') {
        const request: BuyRequest = {
          currencyId: parseInt(selectedCurrency.id),
          currencyAmount: foreignNum,
          customExchangeRate: rate,
          foreignStatus,
          ...customerData,
        }
        const result = await transactionApi.buy(request)
        setSavedTransaction(result)
        resetAmlApproval()
        toast.success(
          'Vétel tranzakció sikeresen mentve!',
          `Bizonylat szám: ${result.receiptNumber}`,
        )
      } else {
        const request: SellRequest = {
          currencyId: parseInt(selectedCurrency.id),
          currencyAmount: foreignNum,
          customExchangeRate: rate,
          foreignStatus,
          ...customerData,
        }
        const result = await transactionApi.sell(request)
        setSavedTransaction(result)
        resetAmlApproval()
        toast.success(
          'Eladás tranzakció sikeresen mentve!',
          `Bizonylat szám: ${result.receiptNumber}`,
        )
      }

      // Don't navigate away — let user print receipt first
    } catch (error: unknown) {
      resetAmlApproval()
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

  const approvalForeignNum = parseFloat(foreignAmount.replace(',', '.')) || 0
  const approvalHufNum = parseFloat(hufAmount.replace(/\s/g, '').replace(',', '.')) || 0

  return (
    <div className="space-y-3">
      {/* Page header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <ArrowLeftRight />
          {t('misc.ujTranzakcio')}
        </h1>
        <div className="flex gap-2">
          <button
            onClick={() => {
              void handleCancel()
            }}
            className="form-button flex items-center gap-1"
            title="Mégsem (Esc)"
          >
            <X size={16} />
            {t('common.cancel')}
          </button>
          <button
            onClick={handleSaveAndPrint}
            disabled={isSubmitting || amlBlocked}
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
              onClick={() => switchTransactionType('BUY')}
              onKeyDown={(e) => {
                if (e.key === 'ArrowRight' || e.key === ' ') {
                  e.preventDefault()
                  switchTransactionType('SELL')
                }
              }}
              data-testid="tx-type-buy"
              className={`flex-1 py-2 text-center font-semibold border rounded-l focus:outline-none focus:ring-2 focus:ring-primary ${
                transactionType === 'BUY'
                  ? 'bg-green-600 text-white border-green-700'
                  : 'bg-gray-100 border-form-border hover:bg-gray-200'
              }`}
            >
              {t('transactions.vetel')}
              <div className="text-xs font-normal">
                {t('transactions.ugyfelElad')}
                {selectedCurrency?.code || 'devizát'})
              </div>
            </button>
            <button
              onClick={() => switchTransactionType('SELL')}
              onKeyDown={(e) => {
                if (e.key === 'ArrowLeft' || e.key === ' ') {
                  e.preventDefault()
                  switchTransactionType('BUY')
                }
              }}
              data-testid="tx-type-sell"
              className={`flex-1 py-2 text-center font-semibold border rounded-r focus:outline-none focus:ring-2 focus:ring-primary ${
                transactionType === 'SELL'
                  ? 'bg-blue-600 text-white border-blue-700'
                  : 'bg-gray-100 border-form-border hover:bg-gray-200'
              }`}
            >
              {t('transactions.eladas')}
              <div className="text-xs font-normal">
                {t('transactions.ugyfelVesz')}
                {selectedCurrency?.code || 'devizát'})
              </div>
            </button>
          </div>

          {/* Currency quick search */}
          <CurrencySearchInput currencyRates={currencyRates} onSelect={handleCurrencySelect} />

          {/* Current rate display — editable */}
          <div className="form-group-box pt-4 mb-3">
            <span className="form-group-box-title">{t('transactions.alkalmazottArfolyam')}</span>
            <div className="text-center flex items-center justify-center gap-2">
              <input
                ref={rateInputRef}
                value={editingRate ? rateText : formatDecimal(currentRate, 2, 2)}
                onChange={(e) => handleRateChange(e.target.value)}
                onFocus={(e) => {
                  setEditingRate(true)
                  setRateText(formatDecimal(currentRate, 2, 2))
                  e.target.select()
                }}
                onBlur={handleRateBlur}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault()
                    rateInputRef.current?.blur()
                  }
                  if (e.key === 'Escape') {
                    setCustomRate(null)
                    setEditingRate(false)
                  }
                }}
                type="text"
                inputMode="decimal"
                className="w-40 text-center text-3xl font-bold font-mono bg-transparent border-2 border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:border-transparent h-12"
                style={
                  {
                    color: 'var(--primary)',
                    '--tw-ring-color': 'var(--primary)',
                  } as React.CSSProperties
                }
              />
              <span className="text-gray-500">
                {t('transactions.huf1')}
                {selectedCurrency?.code || ''}
              </span>
            </div>
          </div>

          {/* Amount inputs */}
          <div className="space-y-3">
            <div className="form-group-box pt-4">
              <span className="form-group-box-title">
                {selectedCurrency?.code || 'Deviza'} {t('transactions.osszeg')}
              </span>
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

          {/* Devizastátusz választó */}
          <div className="form-group-box pt-4">
            <span className="form-group-box-title">Devizastátusz</span>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setForeignStatus('FOREIGN')}
                className={`flex-1 py-2 px-3 rounded-lg text-sm font-semibold border-2 transition-all ${
                  foreignStatus === 'FOREIGN'
                    ? 'border-blue-500 bg-blue-50 text-blue-700'
                    : 'border-gray-200 bg-white text-gray-600 hover:border-blue-300'
                }`}
              >
                Külföldi
              </button>
              <button
                type="button"
                onClick={() => setForeignStatus('DOMESTIC')}
                className={`flex-1 py-2 px-3 rounded-lg text-sm font-semibold border-2 transition-all ${
                  foreignStatus === 'DOMESTIC'
                    ? 'border-green-500 bg-green-50 text-green-700'
                    : 'border-gray-200 bg-white text-gray-600 hover:border-green-300'
                }`}
              >
                Belföldi
              </button>
            </div>
          </div>

          {/* Identification warnings */}
          {identificationLevel !== 'SIMPLE' && (
            <div
              className={`mt-3 p-2 rounded text-sm flex items-start gap-2 ${
                identificationLevel === 'FULL'
                  ? 'bg-red-50 border border-red-200 text-red-700'
                  : 'bg-yellow-50 border border-yellow-200 text-yellow-700'
              }`}
            >
              <AlertCircle size={18} className="flex-shrink-0 mt-0.5" />
              <div>
                <strong>
                  {identificationLevel === 'FULL'
                    ? 'Teljes azonosítás szükséges!'
                    : 'Egyszerűsített azonosítás szükséges!'}
                </strong>
                <div className="text-xs mt-1">
                  {identificationLevel === 'FULL'
                    ? '300.000 Ft feletti tranzakció'
                    : '100.000 - 300.000 Ft közötti tranzakció'}
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
          identificationLevel={identificationLevel}
          minimumLevel={minimumLevel}
          onLevelChange={setIdentificationLevel}
          requiresSourceVerification={requiresSourceVerification}
          hufTotal={parseFloat(hufAmount.replace(/\s/g, '').replace(',', '.')) || 0}
          onCustomerReady={(data) => {
            customerDataRef.current = data
          }}
          onAmlResult={(result) => {
            amlResultRef.current = result
            setAmlBlocked(result?.blocked ?? false)
          }}
        />
      </div>

      {/* Rate auth dialog */}
      <RateAuthDialog
        isOpen={showRateAuth}
        onSuccess={() => {
          rateAuthApprovedRef.current = true
          setShowRateAuth(false)
        }}
        onCancel={() => {
          setShowRateAuth(false)
          setCustomRate(null)
        }}
        customRate={rateAuthPendingRate}
        currencyCode={selectedCurrency?.code || ''}
        mode={transactionType === 'BUY' ? 'buy' : 'sell'}
      />

      <AmlApproverModal
        open={showAmlApprover}
        currentWorkerId={worker?.id ?? 0}
        reason={amlApprovalReason}
        sessionId={approvalSessionIdRef.current ?? ''}
        customerName={customerDataRef.current?.name ?? undefined}
        details={{
          branchCode: worker?.branchCode ?? undefined,
          branchName: worker?.branchName ?? undefined,
          totalHuf: approvalHufNum,
          lines: selectedCurrency
            ? [
                {
                  currencyCode: selectedCurrency.code,
                  amount: approvalForeignNum,
                  rate: currentRate,
                  hufValue: approvalHufNum,
                },
              ]
            : [],
          customer: toApprovalCustomer(customerDataRef.current),
        }}
        onApproved={(workerId, name) => {
          approverWorkerIdRef.current = workerId
          setShowAmlApprover(false)
          toast.info('AML jóváhagyás megerősítve', `Engedélyező: ${name}`)
          void handleSubmit()
        }}
        onCancel={() => setShowAmlApprover(false)}
      />

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
