import { useState, useEffect, useRef } from 'react'
import { useNavigate } from 'react-router-dom'
import CustomerPanel from './components/CustomerPanel'
import type { CustomerPanelData } from './components/CustomerPanel'
import { useIdentificationLevel } from './hooks/useIdentificationLevel'
import {
  RefreshCw,
  ArrowRightLeft,
  Save,
  X,
  AlertCircle,
  CheckCircle,
  Calculator,
} from 'lucide-react'
import {
  transactionApi,
  currencyApi,
  exchangeRateApi,
  cashBalanceApi,
  Currency,
  ExchangeRate,
  ConversionRequest,
} from '../../services/api/index'
import { NumberInput } from '../../components/NumberInput'
import { formatDecimal, formatInteger } from '../../utils/numberFormat'
import { getErrorMessage } from '../../utils/errorHandling'
import { roundHuf } from '../../utils/rounding'
import {
  buildConversionRequestFromSelection,
  buildFallbackCurrenciesFromCachedRates,
  getElectronCachedRates,
  isElectronQueueAvailable,
  mapCachedRatesToExchangeRates,
  saveAndSyncPendingConversion,
} from '../../utils/electronTransactions'
import { useTranslation } from 'react-i18next'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'
import { useAuthStore } from '../../stores/authStore'
import AmlApproverModal, { toApprovalCustomer } from '../../components/auth/AmlApproverModal'
import i18n from '../../i18n'

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
  const { t } = useTranslation()
  const navigate = useNavigate()
  const electronQueueAvailable = isElectronQueueAvailable()

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
  // HIBA 2026-05-26 (#4): visszajáró forint (a cél-összegre fel nem használt HUF-fedezet)
  const [returnedHuf, setReturnedHuf] = useState<number>(0)
  // HIBA 2026-05-26 (#2): ügyfél deviza-státusza (alap: külföldi)
  const [foreignStatus, setForeignStatus] = useState<'DOMESTIC' | 'FOREIGN'>('FOREIGN')

  // Customer data (optional for conversion)
  const [customerName, setCustomerName] = useState('')
  const [notes, setNotes] = useState('')

  // HIBA 2026-05-26 (#3): a konverzió Pmt. azonosítási küszöbe a vétel + eladás EGYÜTTES
  // HUF-összege alapján dönt (a konverzió valójában egy vétel + egy eladás), nem csak a
  // forrás-oldal alapján. amlAmount = BUY(hufAmount) + SELL(usedHuf). Codex P1 (#858): ha a
  // cél-összeg lefelé módosul, a SELL leg kisebb, ezért a visszajárót levonjuk a 2×-ből —
  // nem becsüljük felül a sub-limit konverziókat.
  const amlAmount = Math.max(0, hufAmount * 2 - returnedHuf)

  // V235 + V236 (2026-05-19 HIBA #19): Pmt. azonositas a Konverzioba is.
  // 100k+ HUF aggregalt -> SIMPLIFIED, 300k+ -> FULL azonositas (Pmt. tv. 6.§).
  const customerDataRef = useRef<CustomerPanelData | null>(null)
  const { identificationLevel, minimumLevel, setIdentificationLevel, requiresSourceVerification } =
    useIdentificationLevel(String(amlAmount))

  // AML felsovezetoi jovahagyas (2026-06-04) — a buy/sell flow-val azonos minta (ref a re-invoke-hoz).
  const worker = useAuthStore((s) => s.worker)
  const approverWorkerIdRef = useRef<number | null>(null)
  // Codex P1 (receipt-scoping): a jovahagyas-session azonosito (a grant ehhez kotodik).
  const approvalSessionIdRef = useRef<string | null>(null)
  const amlPrecheckInFlightRef = useRef(false)
  const [showAmlApprover, setShowAmlApprover] = useState(false)
  const [amlApprovalReason, setAmlApprovalReason] = useState('')

  // Track which field was last edited to prevent useEffect from overwriting manual toAmount edits
  const lastEditedField = useRef<'from' | 'to'>('from')

  // Step tracking (like legacy 2-step process)
  const [step, setStep] = useState<1 | 2>(1)

  // Load currencies and rates on mount
  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true)
        if (electronQueueAvailable) {
          const cachedRates = await getElectronCachedRates()
          if (cachedRates.length > 0) {
            let activeCurrencies: Currency[] = []

            try {
              activeCurrencies = await currencyApi.getActive()
            } catch {
              activeCurrencies = []
            }

            const fallbackCurrencies = buildFallbackCurrenciesFromCachedRates(cachedRates)
            const currencyByCode = new Map(
              activeCurrencies
                .filter((currency) => currency.code !== 'HUF')
                .map((currency) => [currency.code, currency]),
            )

            const filteredCurrencies = fallbackCurrencies.map((currency) => {
              const matched = currencyByCode.get(currency.code)
              return matched ?? currency
            })

            setCurrencies(filteredCurrencies)
            setRates(mapCachedRatesToExchangeRates(cachedRates, activeCurrencies))

            if (filteredCurrencies.length >= 2 && filteredCurrencies[0] && filteredCurrencies[1]) {
              setFromCurrencyId(filteredCurrencies[0].id)
              setToCurrencyId(filteredCurrencies[1].id)
            }
            return
          }
        }

        const [currencyData, rateData] = await Promise.all([
          currencyApi.getActive(),
          exchangeRateApi.list(),
        ])

        const filteredCurrencies = currencyData.filter((c: Currency) => c.code !== 'HUF')
        setCurrencies(filteredCurrencies)
        setRates(rateData)

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
  }, [electronQueueAvailable])

  // Get rate for a currency
  const getRate = (currencyId: number | null): ExchangeRate | undefined => {
    if (!currencyId) return undefined
    return rates.find((r) => r.currencyId === currencyId)
  }

  // Calculate conversion when inputs change.
  // HIBA 2026-05-26 (#5): a FORRÁS az anchor — a cél-összeg módosítása NEM írja felül a
  // forrást; a maradék forint-fedezet visszajáróként jelenik meg (handleToAmountChange).
  useEffect(() => {
    if (!fromCurrencyId || !fromAmount) {
      setHufAmount(0)
      setToAmount('')
      setConversionRate(0)
      setReturnedHuf(0)
      return
    }

    const fromRate = getRate(fromCurrencyId)
    if (!fromRate) return

    const amount = parseFloat(fromAmount.replace(',', '.').replace(/\s/g, '')) || 0
    if (amount <= 0) return

    // Calculate HUF value using buy rate (customer sells this currency)
    const huf = roundHuf(amount * fromRate.baseBuyRate)
    setHufAmount(huf)

    // Only recalculate toAmount when the FROM field was last edited.
    // When the TO field was edited (handleToAmountChange), we must NOT overwrite it.
    if (toCurrencyId && lastEditedField.current === 'from') {
      const toRate = getRate(toCurrencyId)
      if (toRate && toRate.baseSellRate > 0) {
        // Maximális cél-összeg (lefelé kerekítve) — ennyit fedez a forrás.
        const maxTo = Math.floor((huf / toRate.baseSellRate) * 100) / 100
        setToAmount(maxTo.toFixed(2).replace('.', ','))
        // Visszajáró = a flooring-maradék forintban (általában kicsi).
        const usedHuf = Math.round(maxTo * toRate.baseSellRate)
        setReturnedHuf(Math.max(0, roundHuf(huf - usedHuf)))

        const directRate = fromRate.baseBuyRate / toRate.baseSellRate
        setConversionRate(directRate)
      } else {
        setToAmount('')
        setConversionRate(0)
        setReturnedHuf(0)
      }
    } else if (!toCurrencyId) {
      setToAmount('')
      setConversionRate(0)
      setReturnedHuf(0)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps -- getRate/roundHuf are derived from `rates` already in deps
  }, [fromCurrencyId, toCurrencyId, fromAmount, rates])

  // Get currency by id
  const getCurrency = (id: number | null): Currency | undefined => {
    if (!id) return undefined
    return currencies.find((c) => c.id === id)
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

      const fromCurrency = getCurrency(fromCurrencyId)
      const toCurrency = getCurrency(toCurrencyId)
      if (!fromCurrency || !toCurrency) {
        setError('A kiválasztott valuták nem érvényesek!')
        return
      }

      // A pénztáros által (esetleg lefelé módosított) cél-összeg.
      const toVal = parseFloat(toAmount.replace(',', '.').replace(/\s/g, '')) || 0
      if (toVal <= 0) {
        setError('A kapott (cél) összegnek nagyobbnak kell lennie 0-nál!')
        return
      }

      // HIBA 2026-05-26 (#1): kliens-oldali készlet-előellenőrzés — a pénztár nem könyvelhet
      // olyan konverziót, amihez nincs elég cél valuta (kifizetés), illetve nincs elég HUF a
      // visszajáróhoz. Fail-closed: ha nem ellenőrizhető, nem engedjük tovább (offline outbox
      // különben csak sync-kor bukna el).
      try {
        const balances = await cashBalanceApi.list()
        const insufficient: string[] = []
        const toBal = balances.find((b) => b.currencyCode === toCurrency.code)
        const toAvailable = toBal?.currentBalance ?? 0
        if (toVal > toAvailable) {
          insufficient.push(
            `${toCurrency.code}: ${toVal} kifizetés kérne, csak ${toAvailable} érhető el`,
          )
        }
        if (returnedHuf > 0) {
          const hufBal = balances.find((b) => b.currencyCode === 'HUF')
          const hufAvailable = hufBal?.currentBalance ?? 0
          if (returnedHuf > hufAvailable) {
            insufficient.push(
              `HUF visszajáró: ${returnedHuf.toLocaleString('hu-HU')} Ft kérne, csak ${hufAvailable.toLocaleString('hu-HU')} Ft érhető el`,
            )
          }
        }
        if (insufficient.length > 0) {
          setError('Nincs elég készlet a konverzióhoz: ' + insufficient.join(' | '))
          return
        }
      } catch (stockErr) {
        // Copilot #858: a konkrét hibát is megjelenítjük (pl. lejárt munkamenet / hálózat),
        // ne csak generikus üzenetet — így a pénztáros tudja, mi a teendő.
        setError(
          'A készlet nem ellenőrizhető (' + getErrorMessage(stockErr) + '). Próbálja újra később.',
        )
        return
      }

      // HIBA 2026-05-26 (#3): a Pmt. azonositas a vétel+eladás EGYÜTTES (2×) HUF alapján.
      const cd = customerDataRef.current
      // 100k+ aggregalt HUF eseten ha nincs customer panel-bol adat, blokkoljuk
      if (amlAmount >= 100_000 && !cd) {
        setError(
          '100.000 Ft feletti (együttes) konverzióhoz kötelező az ügyfél azonosítása (Pmt. tv. 6.§)',
        )
        return
      }
      const effectiveCustomerName = cd?.name?.trim() || customerName.trim() || null

      // AML felsovezetoi jovahagyas pre-check (2026-06-04): a konverzio AML-alapja az EGYUTTES
      // amlAmount (vetel + eladas). Ha approval kell, a modal elkeri az engedelyezot a rogzites elott.
      // Offline/hiba eseten nem blokkol (a backend a hiteles kapu). A re-invoke utan az approverWorkerIdRef
      // mar be van allitva, igy a pre-check atugorja a modalt.
      if (approverWorkerIdRef.current == null) {
        if (amlPrecheckInFlightRef.current) return
        amlPrecheckInFlightRef.current = true
        try {
          const checkRes = await api.post('/aml-approval/check-required', {
            amountHuf: amlAmount,
            customerId: cd?.id ? String(cd.id) : undefined,
            customerName: effectiveCustomerName || undefined,
            documentNumber: cd?.documentNumber || undefined,
            currencyCode: fromCurrency.code,
            customerNationality: cd?.nationality || undefined,
          })
          if (checkRes.data?.requiresApproval) {
            approvalSessionIdRef.current = crypto.randomUUID()
            setAmlApprovalReason(
              typeof checkRes.data?.reason === 'string' ? checkRes.data.reason : '',
            )
            setShowAmlApprover(true)
            return // a modal onApproved-ja beallitja az approverWorkerId-t es ujrahivja a submitet
          }
        } catch (err) {
          logger.warn('ConversionPage', 'AML approval pre-check hiba (nem blokkolo):', err)
        } finally {
          amlPrecheckInFlightRef.current = false
        }
      }

      if (electronQueueAvailable) {
        // V235 + V236 (Codex P1 #695): teljes Pmt. customer-snapshot atadasa
        // az Electron offline outbox-nak — onOwnBehalf=false eseten az actor
        // identity-vel egyutt. A korabbi payload csak 3 customer mezot kuldott.
        const actorIdentity = cd?.actorIdentity ?? null
        const outcome = await saveAndSyncPendingConversion({
          fromCurrencyId,
          fromCurrencyCode: fromCurrency.code,
          toCurrencyId,
          toCurrencyCode: toCurrency.code,
          fromAmount: amount,
          calculatedHufAmount: hufAmount,
          calculatedToAmount: toVal,
          conversionRate,
          foreignStatus,
          handlingFee: null,
          customerId: cd?.id ? String(cd.id) : null,
          customerName: effectiveCustomerName,
          customerDocumentNumber: cd?.documentNumber ?? null,
          note: notes || null,
          // V229 100k+ alapmezok
          customerAddress: cd?.address ?? null,
          customerNationality: cd?.nationality ?? null,
          customerBirthPlace: cd?.birthPlace ?? null,
          customerBirthDate: cd?.birthDate ?? null,
          customerMotherName: cd?.motherName ?? null,
          customerDocumentType: cd?.documentType ?? null,
          // V229 300k+ JOGCIM
          sourceOfFunds: cd?.sourceOfFunds ?? null,
          customerIsPep: cd?.isPep ?? null,
          customerOnOwnBehalf: cd?.onOwnBehalf ?? null,
          customerActorName: cd?.actorName ?? null,
          // V235 PEP minoseg (HIBA #15)
          customerPepKind: cd?.pepKind ?? null,
          // V235 actor teljes azonositasa (HIBA #17)
          customerActorBirthPlace: actorIdentity?.birthPlace ?? null,
          customerActorBirthDate: actorIdentity?.birthDate ?? null,
          customerActorMotherName: actorIdentity?.motherName ?? null,
          customerActorNationality: actorIdentity?.nationality ?? null,
          customerActorDocumentType: actorIdentity?.documentType ?? null,
          customerActorDocumentNumber: actorIdentity?.documentNumber ?? null,
          customerActorAddress: actorIdentity?.address ?? null,
          // AML felsovezetoi jovahagyas: a jovahagyo workerId (NULL ha nem kellett).
          approverWorkerId: approverWorkerIdRef.current,
          approvalSessionId: approvalSessionIdRef.current,
        })

        const changeMsg =
          returnedHuf > 0 ? ` Visszajáró: ${returnedHuf.toLocaleString('hu-HU')} Ft.` : ''
        if (outcome.allSavedSynced) {
          setSuccess('Konverzió sikeresen rögzítve és szinkronizálva!' + changeMsg)
        } else {
          setSuccess('Konverzió helyben mentve. A szinkron a háttérben folytatódik.' + changeMsg)
        }
      } else {
        const baseRequest: ConversionRequest = buildConversionRequestFromSelection({
          fromCurrencyId,
          fromCurrencyCode: fromCurrency.code,
          toCurrencyId,
          toCurrencyCode: toCurrency.code,
          fromAmount: amount,
          toAmount: toVal,
          foreignStatus,
          customerName: effectiveCustomerName || undefined,
          notes: notes || undefined,
        })

        // V235 + V236 a teljes Pmt. customer-snapshot atadasa a backendnek
        const request: ConversionRequest = cd
          ? {
              ...baseRequest,
              customerId: cd.id ? String(cd.id) : undefined,
              customerAddress: cd.address || undefined,
              customerDocumentNumber: cd.documentNumber || undefined,
              customerNationality: cd.nationality || undefined,
              customerBirthPlace: cd.birthPlace || undefined,
              customerBirthDate: cd.birthDate || undefined,
              customerMotherName: cd.motherName || undefined,
              customerDocumentType: cd.documentType || undefined,
              sourceOfFunds: cd.sourceOfFunds || undefined,
              customerIsPep: cd.isPep,
              customerOnOwnBehalf: cd.onOwnBehalf,
              customerActorName: cd.actorName || undefined,
              customerPepKind: cd.pepKind ?? undefined,
              customerActorBirthPlace: cd.actorIdentity?.birthPlace,
              customerActorBirthDate: cd.actorIdentity?.birthDate,
              customerActorMotherName: cd.actorIdentity?.motherName,
              customerActorNationality: cd.actorIdentity?.nationality,
              customerActorDocumentType: cd.actorIdentity?.documentType,
              customerActorDocumentNumber: cd.actorIdentity?.documentNumber,
              customerActorAddress: cd.actorIdentity?.address,
              // AML felsovezetoi jovahagyas: a jovahagyo workerId a REST conversion request-be.
              approverWorkerId: approverWorkerIdRef.current ?? undefined,
              approvalSessionId: approvalSessionIdRef.current ?? undefined,
            }
          : baseRequest

        const result = await transactionApi.conversion(request)
        const changeMsg =
          returnedHuf > 0 ? ` Visszajáró: ${returnedHuf.toLocaleString('hu-HU')} Ft.` : ''
        setSuccess(`Konverzió sikeres! Bizonylat: ${result.receiptNumber}.${changeMsg}`)
      }

      // AML jovahagyas: a kovetkezo konverzio friss jovahagyas-allapotrol induljon.
      approverWorkerIdRef.current = null
      approvalSessionIdRef.current = null

      // Reset after 2 seconds
      setTimeout(() => {
        navigate('/transactions')
      }, 2000)
    } catch (err) {
      setError(getErrorMessage(err))
      // Codex P2: hiba esetén érvénytelenítjük a jóváhagyást (különben szerkesztés után ugyanazzal a
      // granttal/session-nel másik konverzió mehetne — receipt-scoping szivárgás). Újra: friss pre-check.
      approverWorkerIdRef.current = null
      approvalSessionIdRef.current = null
    } finally {
      setLoading(false)
    }
  }

  // HIBA 2026-05-26 (#5): a cél-összeg módosítása NEM módosítja a forrást. A forrás (és így
  // a köztes HUF) változatlan; ha a pénztáros lefelé módosítja a célt (címletezéshez), a
  // maradék forint-fedezet VISSZAJÁR (returnedHuf), amit feltüntetünk. A cél nem lehet több
  // a forrás-fedezetből számolt maximumnál — a felső határra vágjuk.
  const handleToAmountChange = (value: string) => {
    lastEditedField.current = 'to'

    if (!toCurrencyId || !fromCurrencyId) {
      setToAmount(value)
      return
    }

    const toRate = getRate(toCurrencyId)
    const fromRate = getRate(fromCurrencyId)
    if (!toRate || !fromRate || fromRate.baseBuyRate <= 0 || toRate.baseSellRate <= 0) {
      setToAmount(value)
      return
    }

    let toVal = parseFloat(value.replace(',', '.').replace(/\s/g, '')) || 0
    if (toVal <= 0) {
      setToAmount(value)
      setReturnedHuf(0)
      return
    }

    // Felső határ: a forrás-fedezetből számolt maximum (a forrást SOHA nem módosítjuk).
    const maxTo = Math.floor((hufAmount / toRate.baseSellRate) * 100) / 100
    if (toVal > maxTo) {
      toVal = maxTo
      setToAmount(maxTo.toFixed(2).replace('.', ','))
    } else {
      setToAmount(value)
    }

    const usedHuf = Math.round(toVal * toRate.baseSellRate)
    setReturnedHuf(Math.max(0, roundHuf(hufAmount - usedHuf)))

    const directRate = fromRate.baseBuyRate / toRate.baseSellRate
    setConversionRate(directRate)
  }

  const handleReset = () => {
    lastEditedField.current = 'from'
    setStep(1)
    setFromAmount('')
    setToAmount('')
    setHufAmount(0)
    setConversionRate(0)
    setReturnedHuf(0)
    setForeignStatus('FOREIGN')
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
          {t('transactions.valutaKonverzio')}
        </h1>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={() => navigate('/transactions')}
            className="form-button flex items-center gap-1"
          >
            <X size={16} />
            {t('common.cancel')}
          </button>
          <button
            type="button"
            onClick={handleReset}
            className="form-button flex items-center gap-1"
          >
            <RefreshCw size={16} />
            {t('transactions.ujrakezdes')}
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
        <div
          className={`flex items-center gap-2 px-4 py-2 rounded-full ${
            step === 1 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
          }`}
        >
          <span className="font-bold">{i18n.t('literals.1-2')}</span>
          <span>{t('transactions.forrasValuta')}</span>
        </div>
        <ArrowRightLeft className="text-gray-400" />
        <div
          className={`flex items-center gap-2 px-4 py-2 rounded-full ${
            step === 2 ? 'bg-blue-600 text-white' : 'bg-gray-200 text-gray-600'
          }`}
        >
          <span className="font-bold">{i18n.t('literals.2-2')}</span>
          <span>{t('transactions.celValuta')}</span>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {/* Left: Source currency */}
        <div className={`form-panel ${step === 1 ? 'ring-2 ring-blue-500' : ''}`}>
          <h2 className="font-semibold mb-3 text-green-700 flex items-center gap-2">
            <span className="bg-green-100 px-2 py-1 rounded">{i18n.t('literals.veszek')}</span>
            {t('transactions.forrasValutaUgyfelElad')}
          </h2>

          <div className="space-y-3">
            <div>
              <label htmlFor="from-currency" className="form-label">
                {t('transactions.forrasDeviza')}
              </label>
              <select
                id="from-currency"
                value={fromCurrencyId ?? ''}
                onChange={(e) => {
                  lastEditedField.current = 'from'
                  setFromCurrencyId(e.target.value ? Number(e.target.value) : null)
                }}
                className="form-input w-full"
                disabled={step === 2}
              >
                <option value="">{t('cashdesk.valasszValutat')}</option>
                {currencies.map((c) => (
                  <option key={c.id} value={c.id} disabled={c.id === toCurrencyId}>
                    {c.code}
                    {i18n.t('literals.lit-17')}
                    {c.name}
                  </option>
                ))}
              </select>
            </div>

            {fromRate && (
              <div className="text-sm text-gray-600 bg-gray-50 p-2 rounded">
                <div className="flex justify-between">
                  <span>{t('transactions.veteliArfolyam')}</span>
                  <span className="font-mono font-semibold text-green-600">
                    {formatDecimal(fromRate.baseBuyRate, 2, 4)}
                  </span>
                </div>
              </div>
            )}

            <div>
              <label htmlFor="from-amount" className="form-label">
                {t('transactions.osszeg')}
                {fromCurrency?.code || 'valuta'}
                {i18n.t('literals.lit-2')}
              </label>
              <NumberInput
                id="from-amount"
                value={fromAmount}
                onChange={(v) => {
                  lastEditedField.current = 'from'
                  setFromAmount(v)
                }}
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
                {t('transactions.tovabbACelValutahoz')}
              </button>
            )}
          </div>
        </div>

        {/* Center: Calculation summary */}
        <div className="form-panel bg-gradient-to-b from-blue-50 to-white">
          <h2 className="font-semibold mb-3 flex items-center gap-2">
            <Calculator />
            {t('fees.szamitas')}
          </h2>

          <div className="space-y-4">
            {/* HUF intermediate value */}
            <div className="text-center p-3 bg-white rounded border">
              <div className="text-sm text-gray-500 mb-1">{t('transactions.hufErtekKoztes')}</div>
              <div className="text-lg font-bold font-mono text-blue-600">
                {formatInteger(hufAmount)} {t('common.ft')}
              </div>
            </div>

            {/* Conversion rate */}
            {conversionRate > 0 && fromCurrency && toCurrency && (
              <div className="text-center p-3 bg-white rounded border">
                <div className="text-sm text-gray-500 mb-1">
                  {t('transactions.konverziosArfolyam')}
                </div>
                <div className="text-lg font-bold font-mono">
                  {i18n.t('literals.1-3')}
                  {fromCurrency.code}
                  {i18n.t('literals.lit-53')}
                  {formatDecimal(conversionRate, 4, 6)} {toCurrency.code}
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

            {/* HIBA 2026-05-26 (#4): visszajáró forint a cél-összeg lefelé módosításakor */}
            {returnedHuf > 0 && (
              <div className="p-3 bg-amber-50 rounded border border-amber-300 text-center">
                <div className="text-sm text-amber-700 mb-1">
                  {i18n.t('literals.visszajaro-forint')}
                </div>
                <div className="text-xl font-bold font-mono text-amber-700">
                  {formatInteger(returnedHuf)} {t('common.ft')}
                </div>
              </div>
            )}

            {/* Optional customer/notes */}
            {step === 2 && (
              <div className="space-y-2 pt-2 border-t">
                <div>
                  <label htmlFor="customer-name" className="form-label text-sm">
                    {t('transactions.ugyfelNeveOpcionalis')}
                  </label>
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
                  <label htmlFor="notes" className="form-label text-sm">
                    {t('common.note')}
                  </label>
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
            <span className="bg-blue-100 px-2 py-1 rounded">{i18n.t('literals.eladok')}</span>
            {t('transactions.celValutaUgyfelVesz')}
          </h2>

          <div className="space-y-3">
            <div>
              <label htmlFor="to-currency" className="form-label">
                {t('transactions.celDeviza')}
              </label>
              <select
                id="to-currency"
                value={toCurrencyId ?? ''}
                onChange={(e) => {
                  lastEditedField.current = 'from'
                  setToCurrencyId(e.target.value ? Number(e.target.value) : null)
                }}
                className="form-input w-full"
                disabled={step === 1}
              >
                <option value="">{t('cashdesk.valasszValutat')}</option>
                {currencies.map((c) => (
                  <option key={c.id} value={c.id} disabled={c.id === fromCurrencyId}>
                    {c.code}
                    {i18n.t('literals.lit-17')}
                    {c.name}
                  </option>
                ))}
              </select>
            </div>

            {toRate && (
              <div className="text-sm text-gray-600 bg-gray-50 p-2 rounded">
                <div className="flex justify-between">
                  <span>{t('transactions.eladasiArfolyam')}</span>
                  <span className="font-mono font-semibold text-red-600">
                    {formatDecimal(toRate.baseSellRate, 2, 4)}
                  </span>
                </div>
              </div>
            )}

            <div>
              <label htmlFor="to-amount" className="form-label">
                {t('transactions.kapottOsszeg')}
                {toCurrency?.code || 'valuta'}
                {i18n.t('literals.lit-2')}
              </label>
              <NumberInput
                id="to-amount"
                value={toAmount}
                onChange={handleToAmountChange}
                className="form-input w-full text-xl text-right font-mono font-bold text-blue-600"
                placeholder="0,00"
                allowDecimals={true}
                allowNegative={false}
                disabled={step === 1 || !toCurrencyId}
              />
              <p className="text-xs text-gray-500 mt-1">
                {t('transactions.cimletezeshezModosithatoToAmount', 'Címletezéshez módosítható')}
              </p>
            </div>

            {/* HIBA 2026-05-26 (#2): ügyfél deviza-státusza (belföldi / külföldi) */}
            {step === 2 && (
              <div>
                <span className="form-label block mb-1">
                  {i18n.t('literals.ugyfel-deviza-statusza')}
                </span>
                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => setForeignStatus('FOREIGN')}
                    className={`flex-1 px-3 py-2 rounded border text-sm font-semibold ${
                      foreignStatus === 'FOREIGN'
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'bg-white text-gray-600 border-gray-300'
                    }`}
                  >
                    {i18n.t('literals.kulfoldi-k')}
                  </button>
                  <button
                    type="button"
                    onClick={() => setForeignStatus('DOMESTIC')}
                    className={`flex-1 px-3 py-2 rounded border text-sm font-semibold ${
                      foreignStatus === 'DOMESTIC'
                        ? 'bg-blue-600 text-white border-blue-600'
                        : 'bg-white text-gray-600 border-gray-300'
                    }`}
                  >
                    {i18n.t('literals.belfoldi-b')}
                  </button>
                </div>
              </div>
            )}

            {step === 2 && (
              <div className="space-y-2">
                {/* HIBA 2026-05-26 (#3): a Pmt. azonosítási küszöb a vétel + eladás EGYÜTTES
                    (2×) HUF-összegén alapul. 100k+ -> SIMPLIFIED, 300k+ -> FULL. */}
                {amlAmount >= 100_000 && (
                  <div className="rounded-md border border-gray-200 dark:border-gray-700 p-2 bg-white dark:bg-gray-800">
                    <CustomerPanel
                      identificationLevel={identificationLevel}
                      minimumLevel={minimumLevel}
                      onLevelChange={setIdentificationLevel}
                      requiresSourceVerification={requiresSourceVerification}
                      hufTotal={amlAmount}
                      onCustomerReady={(data) => {
                        customerDataRef.current = data
                      }}
                    />
                  </div>
                )}
                <button type="button" onClick={() => setStep(1)} className="form-button w-full">
                  {t('transactions.Vissza')}
                </button>
                <button
                  type="button"
                  onClick={handleSubmit}
                  className="form-button-primary w-full flex items-center justify-center gap-2"
                  disabled={loading || !toCurrencyId}
                >
                  {loading ? <RefreshCw size={16} className="animate-spin" /> : <Save size={16} />}
                  {t('transactions.konverzioVegrehajtasa')}
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
            <strong>{t('transactions.konverzioMenete')}</strong>
            <ul className="list-disc ml-4 mt-1">
              <li>{t('transactions.valasszaKiAForrasValutatAmitAzUgyfelElad')}</li>
              <li>{t('transactions.adjaMegAzOsszeget')}</li>
              <li>{t('transactions.valasszaKiACelValutatAmitAzUgyfelKap')}</li>
              <li>{t('transactions.aRendszerAutomatikusanKiszamoljaAKapottOsszeget')}</li>
            </ul>
          </div>
        </div>
      </div>

      {/* AML felsovezetoi jovahagyas modal — a pre-check trigger nyitja, ha approval kell */}
      <AmlApproverModal
        open={showAmlApprover}
        currentWorkerId={worker?.id ?? 0}
        reason={amlApprovalReason}
        sessionId={approvalSessionIdRef.current ?? ''}
        // Codex P1: a single-use grant a jóváhagyott ügyfélhez kötött — ugyanaz a customerName mint amit a
        // konverzió-tranzakció visz (effectiveCustomerName logika: customer-panel név, vagy a kézi mező).
        customerName={customerDataRef.current?.name?.trim() || customerName.trim() || undefined}
        /* EXCMD b3 FR-AUTH-01..05: engedélykérő adatlap — a konverzió két lába soros bontásként */
        details={{
          branchCode: worker?.branchCode ?? undefined,
          branchName: worker?.branchName ?? undefined,
          totalHuf: amlAmount,
          lines: [
            fromCurrencyId != null && getRate(fromCurrencyId)
              ? {
                  currencyCode: currencies.find((c) => c.id === fromCurrencyId)?.code ?? '?',
                  amount: parseFloat(fromAmount.replace(',', '.').replace(/\s/g, '')) || 0,
                  rate: getRate(fromCurrencyId)?.baseBuyRate ?? 0,
                  hufValue: hufAmount,
                }
              : null,
            toCurrencyId != null && getRate(toCurrencyId)
              ? {
                  currencyCode: currencies.find((c) => c.id === toCurrencyId)?.code ?? '?',
                  amount: parseFloat(toAmount.replace(',', '.').replace(/\s/g, '')) || 0,
                  rate: getRate(toCurrencyId)?.baseSellRate ?? 0,
                  // Codex P2 + Copilot (#1089): a cél-lábon a TÉNYLEGESEN felhasznált HUF
                  // (a visszajáró levonva) — manuálisan csökkentett cél-összegnél is hű
                  hufValue: Math.max(0, hufAmount - returnedHuf),
                }
              : null,
          ].filter(Boolean) as Array<{
            currencyCode: string
            amount: number
            rate: number
            hufValue: number
          }>,
          customer: toApprovalCustomer(customerDataRef.current),
        }}
        onApproved={(workerId, name) => {
          approverWorkerIdRef.current = workerId
          setShowAmlApprover(false)
          setSuccess(`AML jóváhagyás megerősítve. Engedélyező: ${name}`)
          void handleSubmit()
        }}
        onCancel={() => setShowAmlApprover(false)}
      />
    </div>
  )
}
