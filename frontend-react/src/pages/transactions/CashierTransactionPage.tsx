import { useState, useEffect, useRef, useCallback, forwardRef } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useHotkeys } from 'react-hotkeys-hook'
import { useFKeyHotkey } from '../../hooks/useFKeyHotkey'
import { AlertTriangle } from 'lucide-react'
import { HotkeyBar } from '../../components/cashier/HotkeyBar'
import { useCompanyTheme } from '../../contexts/CompanyThemeContext'
import {
  transactionApi,
  exchangeRateApi,
  dailySessionApi,
  cashBalanceApi,
  receiptApi,
  handlingFeeConfigApi,
  discountThresholdApi,
  incomeSourceDocApi,
} from '../../services/api/index'
import type { HandlingFeeConfig } from '../../services/api/index'
import { computeHandlingFee } from '../../utils/handlingFee'
import { api } from '../../services/api/client'
import AmlApproverModal, { toApprovalCustomer } from '../../components/auth/AmlApproverModal'
import SuspicionReportModal from '../../components/SuspicionReportModal'
import type {
  BuyRequest,
  SellRequest,
  TransactionLineRequest,
  ExchangeRate,
  CashierCustomRateQuota,
} from '../../services/api/index'
import { roundHuf, multiLinePayable } from '../../utils/rounding'
import { toast } from '../../components/ui/toaster'
import {
  getElectronCachedRates,
  isElectronQueueAvailable,
  mapCachedRatesToExchangeRates,
  recordLocalAuditEvent,
  saveAndSyncPendingBuySell,
} from '../../utils/electronTransactions'
import type { PendingBuySellInput } from '../../utils/electronTransactions'
import { logger } from '../../utils/logger'
import { isElectron } from '../../utils/electron'
import ReceiptPreviewModal from '../../components/electron/ReceiptPreviewModal'
import type { PrintReceiptData } from '../../types/receipt'
import { useAuthStore } from '../../stores/authStore'
import CustomerPanel from './components/CustomerPanel'
import type { CustomerPanelData } from './components/CustomerPanel'
import { CurrencyAutocomplete } from '../../components/cashier/CurrencyAutocomplete'
import { useIdentificationLevel } from './hooks/useIdentificationLevel'
import type { AmlCheckResultDto } from '../../services/api/transactions'
import { useTranslation } from 'react-i18next'
import {
  getBandForAmount,
  isWithinBand,
  isWithinHardLimit,
  getHardLimitMessage,
} from '../../utils/rateBands'
import RateAuthDialog from './components/RateAuthDialog'
import { getErrorMessage } from '../../utils/errorHandling'
import { sanitizeSyncErrorMessage } from '../../utils/syncErrorSanitizer'
import IncomeSourceDocCapture from '../../components/documents/IncomeSourceDocCapture'
import ComplianceQuestionsBlock from './components/ComplianceQuestionsBlock'

/**
 * Penztaros Eladas/Vetel kepernyoje — 6 soros valuta tabla.
 *
 * Legacy: ELADAS.DLL + VASARLAS.DLL
 * - Max 6 valutasor/bizonylat
 * - Arfolyam/100 * bankjegy = forint (JPY /1000)
 * - Tab/Enter navigacio sorok kozott
 * - F1=Vetel, F2=Eladas, F5=Storno, F8=Arfolyam, F9=Kedvezmeny, Esc=Megse
 *   (v2.3.40 B13 align: F1/F2 -- előtte F2/F3 volt, ami konfúziót okozott
 *    a Főmenü F1=Vétel/F2=Eladás-hoz képest)
 */

const MAX_LINES = 6
const SIMPLIFIED_IDENTIFICATION_LIMIT = 100_000
const RATE_STALE_MS = 5 * 60 * 1000 // 5 perc

let _rowIdSeq = 0

type ForeignStatus = 'DOMESTIC' | 'FOREIGN'

interface TransactionRow {
  id: string
  currencyCode: string
  currencyName: string
  exchangeRate: number
  quantity: string
  hufValue: number
  /**
   * Devizastatusz tetel-szinten (V226, 2026-05-14):
   * 'FOREIGN' = kulfoldi (default), 'DOMESTIC' = belfoldi.
   * Tetel-szinten valaszthato, bizonylaton tetelenkent megjelenik.
   */
  foreignStatus: ForeignStatus
}

interface IncomeProofEmailPayload {
  imageBase64: string
  mimeType: 'image/jpeg'
  transactionRef?: string
  customerName?: string
  hufAmount?: number
}

const emptyRow = (): TransactionRow => ({
  id: `row-${++_rowIdSeq}`,
  currencyCode: '',
  currencyName: '',
  exchangeRate: 0,
  quantity: '',
  hufValue: 0,
  foreignStatus: 'FOREIGN', // Default: kulfoldi (penzvalto-bran a leggyakoribb)
})

const RateInput = forwardRef<
  HTMLInputElement,
  {
    rate: number
    onChange: (val: string) => void
    onKeyDown: (e: React.KeyboardEvent) => void
    onFocus: () => void
    onRateBlur?: () => void
    disabled: boolean
  }
>(({ rate, onChange, onKeyDown, onFocus, onRateBlur, disabled }, ref) => {
  const [editing, setEditing] = useState(false)
  const [text, setText] = useState('')

  const display = rate ? rate.toFixed(2) : ''

  return (
    <input
      ref={ref}
      value={editing ? text : display}
      onChange={(e) => {
        setText(e.target.value)
        onChange(e.target.value)
      }}
      onKeyDown={onKeyDown}
      onFocus={(e) => {
        setEditing(true)
        setText(display)
        onFocus()
        e.target.select()
      }}
      onBlur={() => {
        setEditing(false)
        onRateBlur?.()
      }}
      type="text"
      inputMode="decimal"
      className="w-28 h-8 text-right font-mono text-base font-semibold bg-transparent border-2 border-gray-300 dark:border-gray-600 rounded focus:ring-2 focus:border-transparent"
      style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
      placeholder="-"
      disabled={disabled}
    />
  )
})
RateInput.displayName = 'RateInput'

export default function CashierTransactionPage() {
  const { t } = useTranslation()
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const { theme: _theme } = useCompanyTheme()
  const electronQueueAvailable = isElectronQueueAvailable()

  // Daily session guard
  const [sessionOpen, setSessionOpen] = useState<boolean | null>(null)

  // Transaction state
  const [mode, setMode] = useState<'buy' | 'sell'>('buy')
  const [rows, setRows] = useState<TransactionRow[]>(Array.from({ length: MAX_LINES }, emptyRow))
  const [activeRow, setActiveRow] = useState(0)
  const [activeField, setActiveField] = useState<'currency' | 'rate' | 'quantity'>('currency')

  // Customer state (managed by CustomerPanel)
  const customerDataRef = useRef<CustomerPanelData | null>(null)
  // FS-10 S3: compliance-kérdés blokk — CSAK mentett (id-s) ügyfélnél él.
  // A ref nem triggerel renderet, ezért a customerId-t state-ben tükrözzük.
  const [complianceCustomerId, setComplianceCustomerId] = useState<number | null>(null)
  // EXCMD b9-korlevelek FR-03: gyanú-bejelentés (SAR) modal
  const [showSuspicionModal, setShowSuspicionModal] = useState(false)
  const amlResultRef = useRef<AmlCheckResultDto | null>(null)
  const incomeProofBase64Ref = useRef<string | null>(null)
  const [incomeProofRequired, setIncomeProofRequired] = useState(false)
  const [showIncomeProofModal, setShowIncomeProofModal] = useState(false)
  const [showIncomeProofSendModal, setShowIncomeProofSendModal] = useState(false)
  const [incomeProofSending, setIncomeProofSending] = useState(false)
  const [incomeProofSendError, setIncomeProofSendError] = useState<string | null>(null)
  const [incomeProofPendingPayload, setIncomeProofPendingPayload] =
    useState<IncomeProofEmailPayload | null>(null)

  // Fees
  const [handlingFee, setHandlingFee] = useState(0)
  const [discount, setDiscount] = useState(0)
  const [showFeeDialog, setShowFeeDialog] = useState(false)
  const [feeInput, setFeeInput] = useState('')
  const [discountInput, setDiscountInput] = useState('')
  const [discountApprovalInfo, setDiscountApprovalInfo] = useState<{
    requiredLevel?: string
    workerLevel?: string
    maxAllowedPercent?: number
    canApprove?: boolean
    exceedsMaxCap?: boolean
  } | null>(null)
  const [discountApprovalLoading, setDiscountApprovalLoading] = useState(false)
  const [discountApprovalError, setDiscountApprovalError] = useState<string | null>(null)
  // FK-KEZDÍJ (2026-06-02): kezelési díj módosítás (override). A szerver validálja az engedély-
  // mátrixot; itt csak a kliens-választás (típus/jogcím/kártyaszám) — HALF/WAIVED-nél a szerver
  // számolja a végösszeget, SPECIAL-nál a feeInput az egyedi díj.
  const [feeOverrideType, setFeeOverrideType] = useState<'' | 'HALF' | 'WAIVED' | 'SPECIAL'>('')
  const [feeOverrideReason, setFeeOverrideReason] = useState<
    '' | 'DIRECTOR_APPROVAL' | 'CUSTOMER_CARD' | 'PROMOTION'
  >('')
  const [cardNumber, setCardNumber] = useState('')
  // FK-KEZDIJ B.1 (2026-06-12, user-kérés): a díj a "Kezelési költség beállítások" konfig
  // szerint AUTOMATIKUSAN számolódik (ezrelékes/sávos) — a szerver eddig is ezzel könyvelt,
  // de a képernyő/helyi bizonylat 0-t mutatott. A konfigot a pénztáros read-only kérheti le.
  const [feeConfig, setFeeConfig] = useState<HandlingFeeConfig | null>(null)
  const [autoFeeDiscountLabel, setAutoFeeDiscountLabel] = useState<string | null>(null)

  // Exchange rates from API
  const [exchangeRates, setExchangeRates] = useState<ExchangeRate[]>([])
  const ratesLoadedAtRef = useRef<number>(0)

  // Submission state. Codex P1 #586 iter-6: a `isSubmitting` state PLUS `isSubmittingRef`
  // tukrozve. A handleSubmit useCallback NEM memo-zi az `isSubmitting`-et a deps-be (egyebkent
  // minden submit-nel re-create-ne a fuggvenyt, ami a child re-render-cascade-et okoz).
  // A ref-bol olvasva mindig a friss erteket latjuk a guard-ban.
  const [isSubmitting, setIsSubmittingState] = useState(false)
  const isSubmittingRef = useRef(false)
  // AML felsovezetoi jovahagyas (2026-06-04): a jovahagyo workerId a re-invoke-olt handleSubmit
  // szamara ref-ben (mint az isSubmittingRef, hogy a memoizalt closure friss erteket lasson);
  // a modal nyitas-allapota es a kivalto indok state-ben.
  const approverWorkerIdRef = useRef<number | null>(null)
  // Codex P1 (receipt-scoping): a jovahagyas-session azonosito — a modal megnyitasakor generaljuk, a
  // grant (verify-approver) ehhez kotodik, es a tranzakcio(k) UGYANEZT viszik, igy a maradek grant-
  // felhasznalasok NEM szivaroghatnak masik nyugtara.
  const approvalSessionIdRef = useRef<string | null>(null)
  // Copilot review: a pre-check (aml-approval/check-required) az isSubmitting guard ELOTT fut, ezert
  // gyors dupla-submit parhuzamos pre-checket/modalt nyithatna. Ez a ref biztositja, hogy egyszerre
  // csak egy pre-check fusson, amig nincs jovahagyo.
  const amlPrecheckInFlightRef = useRef(false)
  const [showAmlApprover, setShowAmlApprover] = useState(false)
  const [amlApprovalReason, setAmlApprovalReason] = useState('')
  // Helper: state + ref atomi sync. MINDEN setIsSubmitting hivas ezt hasznalja.
  const setIsSubmitting = useCallback((value: boolean) => {
    isSubmittingRef.current = value
    setIsSubmittingState(value)
  }, [])

  // Receipt print state — queue for multi-line transactions
  const [showReceiptModal, setShowReceiptModal] = useState(false)
  const [receiptData, setReceiptData] = useState<PrintReceiptData | null>(null)
  const receiptQueueRef = useRef<PrintReceiptData[]>([])
  // Track whether user attempted to print in current modal-cycle (Sourcery #311+#312):
  // - true → print-toast already gave feedback, no close-toast needed
  // - false → user just viewed/Esc-d → toast.info on close
  // Reset ON OPEN to prevent state leaks from previous cycles (Sourcery #312).
  const printAttemptedRef = useRef<boolean>(false)

  // Helper: open receipt modal with first receipt + reset cycle state.
  // Centralizes the reset+open pattern (Sourcery #314 P3) so both BUY/SELL submit
  // branches use a single source of truth.
  const openReceiptModal = useCallback((first: PrintReceiptData) => {
    printAttemptedRef.current = false
    setReceiptData(first)
    setShowReceiptModal(true)
  }, [])

  // Auth store for receipt data
  const worker = useAuthStore((s) => s.worker)
  // FK-KEZDÍJ (2026-06-02): a bejelentkezett dolgozó ügyvezető/főértéktáros-e — csak ekkor látszik
  // a SPECIAL (egyedi díj) + a "vezetői jóváhagyás" jogcím (a szerver amúgy is validál, ez UX-gate).
  const isDirectorUser = useAuthStore((s) => s.hasCanonicalRole)([
    'ugyvezeto',
    'foertektar',
    'admin',
  ])

  // Refs for keyboard navigation
  const currencyRefs = useRef<(HTMLInputElement | null)[]>([])
  const rateRefs = useRef<(HTMLInputElement | null)[]>([])
  const quantityRefs = useRef<(HTMLInputElement | null)[]>([])

  // Rate auth dialog state
  const [showRateAuth, setShowRateAuth] = useState(false)
  const [rateAuthRow, setRateAuthRow] = useState(0)
  const [rateAuthPendingRate, setRateAuthPendingRate] = useState(0)
  const rateAuthApprovedRef = useRef<Set<string>>(new Set())

  // Penztarosi sav (cashier custom rate) kvota
  const [cashierRateQuota, setCashierRateQuota] = useState<CashierCustomRateQuota | null>(null)
  const cashierCustomRateRowsRef = useRef<Set<string>>(new Set())

  // Calculated totals — a HUF végösszeg 5 Ft-ra kerekítve (magyar készpénz-kerekítés). A kedvezmény
  // Math.round-ja korábban 1 Ft-os értéket adhatott → az ügyfélnek mutatott + az AML-küszöbhöz használt
  // `total` nem volt 5 Ft többszöröse. (Per-soros összegek külön, már roundHuf-olva mennek a backendre.)
  const subtotal = rows.reduce((sum, r) => sum + r.hufValue, 0)
  const discountAmount = discount > 0 ? roundHuf((subtotal * discount) / 100) : 0
  // Codex PR #1103 P1: a fizetendő MÓD-FÜGGŐ — BUY-nál a díj LEVONÓDIK a kifizetésből és a
  // kedvezmény hozzáadódik, SELL-nél fordítva (a szerver calculateBuyGross/calculateSellGross
  // tükre = multiLinePayable). A korábbi sell-előjelű képlet BUY-nál díj/kedvezmény mellett
  // rossz összeget mutatott és rossz AML-küszöböt ellenőrzött.
  const total = multiLinePayable(
    subtotal,
    mode === 'buy' ? 'buy' : 'sell',
    discount > 0 ? discount : 0,
    handlingFee > 0 ? handlingFee : 0,
  )

  // Identification level based on HUF total
  const { identificationLevel, minimumLevel, setIdentificationLevel, requiresSourceVerification } =
    useIdentificationLevel(String(total))

  // FK-KEZDIJ B.1 (2026-06-12): a kezelési díj konfig betöltése (read-only — a backend
  // GET /handling-fee-config a pénztárosnak is engedélyezett). Régi backend (403) vagy
  // hálózati hiba → null konfig, a viselkedés a korábbi marad (a szerver sync-kor számol).
  useEffect(() => {
    let cancelled = false
    handlingFeeConfigApi
      .get()
      .then((cfg) => {
        if (!cancelled) setFeeConfig(cfg)
      })
      .catch(() => {
        if (!cancelled) setFeeConfig(null)
      })
    return () => {
      cancelled = true
    }
  }, [])

  // FK-KEZDIJ B.1 + DiscountThreshold contract: az AUTOMATIKUS díj a konfigból
  // (ezrelékes/sávos) indul, majd a backend /discount-threshold/apply szerződés
  // alkalmazza a BIGARFVALT/KISARFVALT automatikus küszöbkedvezményt/felárat.
  // Endpoint-hiba esetén fail-open: marad a baseFee, hogy a kassza ne akadjon meg;
  // a backend tranzakciórögzítés továbbra is autoritatívan újraszámol.
  useEffect(() => {
    if (!feeConfig || feeOverrideType) {
      setAutoFeeDiscountLabel(null)
      return
    }
    let cancelled = false
    const auto = computeHandlingFee(subtotal, feeConfig)
    if (auto === null) {
      setAutoFeeDiscountLabel(null)
      return
    }
    setHandlingFee(auto)
    setAutoFeeDiscountLabel(null)
    if (subtotal <= 0) return

    discountThresholdApi
      .apply(subtotal, auto)
      .then((result) => {
        if (cancelled) return
        const adjusted = roundHuf(result.adjustedFee ?? auto)
        setHandlingFee(adjusted)
        setAutoFeeDiscountLabel(
          result.discountCode
            ? `${result.discountName || result.discountCode}: ${formatNum(auto)} -> ${formatNum(adjusted)} HUF`
            : null,
        )
      })
      .catch((err) => {
        if (!cancelled) {
          setAutoFeeDiscountLabel(null)
          logger.warn(
            'CashierTransactionPage',
            'Discount threshold apply failed; base handling fee kept:',
            err,
          )
        }
      })
    return () => {
      cancelled = true
    }
  }, [subtotal, feeConfig, feeOverrideType])

  // Batch2-B (Fabulya-teszt 2026-06-12): betöltött díj-konfig mellett a kézi díj-mező
  // ZÁRT — a díjat a Kezelési költség beállítások szerint a program számolja; szabad
  // beírás kizárólag a vezetői SPECIAL felülbírálásban marad. Konfig nélkül (régi
  // backend 403 / hálózati hiba → feeConfig=null) a korábbi kézi viselkedés él.
  const feeInputLocked = feeConfig !== null && feeOverrideType !== 'SPECIAL'

  useEffect(() => {
    if (!showFeeDialog) return
    const discountPercent = Math.max(0, parseFloat(discountInput) || 0)
    if (discountPercent <= 0) {
      setDiscountApprovalInfo(null)
      setDiscountApprovalError(null)
      return
    }

    let cancelled = false
    const timerId = window.setTimeout(() => {
      setDiscountApprovalLoading(true)
      setDiscountApprovalError(null)
      api
        .get('/discount-approval/required-level', { params: { discountPercent } })
        .then((response) => {
          if (!cancelled) {
            setDiscountApprovalInfo(response.data as typeof discountApprovalInfo)
          }
        })
        .catch((err) => {
          if (!cancelled) {
            setDiscountApprovalInfo(null)
            setDiscountApprovalError('Kedvezmény-jóváhagyás ellenőrzése sikertelen.')
            logger.warn('CashierTransactionPage', 'Discount approval required-level failed:', err)
          }
        })
        .finally(() => {
          if (!cancelled) setDiscountApprovalLoading(false)
        })
    }, 250)

    return () => {
      cancelled = true
      window.clearTimeout(timerId)
    }
  }, [discountInput, showFeeDialog])

  const applyFeeDialog = async () => {
    const nextDiscount = Math.max(0, parseFloat(discountInput) || 0)
    if (nextDiscount > 0) {
      try {
        setDiscountApprovalError(null)
        await api.post('/discount-approval/validate', null, {
          params: { discountPercent: nextDiscount },
        })
      } catch (err) {
        setDiscountApprovalError(
          'A backend nem engedélyezte ezt a kedvezményt a jelenlegi dolgozói szinttel.',
        )
        logger.warn('CashierTransactionPage', 'Discount approval validate failed:', err)
        return
      }
    }
    if (!feeInputLocked) {
      setHandlingFee(Math.max(0, parseInt(feeInput, 10) || 0))
    }
    setDiscount(nextDiscount)
    setShowFeeDialog(false)
  }

  // Focus management
  useEffect(() => {
    if (activeField === 'currency') {
      currencyRefs.current[activeRow]?.focus()
    } else if (activeField === 'rate') {
      rateRefs.current[activeRow]?.focus()
    } else {
      quantityRefs.current[activeRow]?.focus()
    }
  }, [activeRow, activeField])

  useEffect(() => {
    const requestedMode = searchParams.get('mode')
    if (requestedMode === 'buy' || requestedMode === 'sell') {
      setMode(requestedMode)
    }
  }, [searchParams])

  // Daily session guard — check if session is open before allowing transactions
  useEffect(() => {
    let cancelled = false
    const checkSession = async () => {
      try {
        const isOpen = await dailySessionApi.isOpen()
        if (!cancelled) setSessionOpen(isOpen)
      } catch {
        // Fail-closed: ha nem tudjuk ellenőrizni, NEM engedjük a tranzakciót
        if (!cancelled) setSessionOpen(false)
      }
    }
    void checkSession()
    return () => {
      cancelled = true
    }
  }, [])

  // Load exchange rates with Electron cached-rates priority
  useEffect(() => {
    let cancelled = false

    const loadRates = async () => {
      if (electronQueueAvailable) {
        try {
          const cachedRates = await getElectronCachedRates()
          if (!cancelled && cachedRates.length > 0) {
            setExchangeRates(mapCachedRatesToExchangeRates(cachedRates))
            ratesLoadedAtRef.current = Date.now()
            return
          }
        } catch (err) {
          logger.error('CashierTransactionPage', 'Helyi arfolyam cache betöltés sikertelen:', err)
        }
      }

      try {
        const rates = await exchangeRateApi.list()
        if (!cancelled) {
          setExchangeRates(rates)
          ratesLoadedAtRef.current = Date.now()
        }
      } catch (err) {
        logger.error('CashierTransactionPage', 'Arfolyam betöltés sikertelen:', err)
        if (!cancelled && electronQueueAvailable) {
          toast.error(
            'Árfolyam nem elérhető',
            'Nincs használható helyi vagy szerver oldali árfolyam adat.',
          )
        }
      }
    }

    void loadRates()

    return () => {
      cancelled = true
    }
  }, [electronQueueAvailable])

  // Penztarosi sav kvota betoltes
  useEffect(() => {
    let cancelled = false
    const loadQuota = async () => {
      try {
        const quota = await transactionApi.getCashierRateQuota()
        if (!cancelled) setCashierRateQuota(quota)
      } catch {
        // Non-blocking: kvota lekerdezesi hiba nem akadalyozza a tranzakciot
      }
    }
    void loadQuota()
    return () => {
      cancelled = true
    }
  }, [])

  // Auto focus first row on mount
  useEffect(() => {
    const timerId = setTimeout(() => currencyRefs.current[0]?.focus(), 100)
    return () => clearTimeout(timerId)
  }, [])

  // ====== HOTKEYS ======
  // v2.3.40 B13: F1/F2 align Főmenü-höz. v2.3.43 P1: preventDefault().
  // v2.3.45 Sourcery #308: useFKeyHotkey helper-rel kiemelve a duplikacio.
  useFKeyHotkey('f1', () => setMode('buy'))
  useFKeyHotkey('f2', () => setMode('sell'))
  useFKeyHotkey('f5', () => navigate('/transactions?action=storno'))
  useFKeyHotkey('f8', () => navigate('/rates'))
  useFKeyHotkey('f9', () => {
    setFeeInput(String(handlingFee || ''))
    setDiscountInput(String(discount || ''))
    setShowFeeDialog(true)
  })
  useHotkeys(
    'escape',
    () => {
      void handleCancel()
    },
    { enableOnFormTags: true },
  )

  // ====== HANDLERS ======

  const handleCurrencySelect = useCallback(
    (rowIdx: number, code: string, rate: ExchangeRate | null) => {
      if (rate) {
        setRows((prev) => {
          const next = [...prev]
          const row = next[rowIdx]!
          const qtyNum = parseFloat(row.quantity) || 0
          const baseRate = mode === 'buy' ? rate.baseBuyRate : rate.baseSellRate
          const baseAmountHuf = baseRate * qtyNum
          const band = getBandForAmount(rate, mode, baseAmountHuf)
          next[rowIdx] = {
            ...row,
            currencyCode: code,
            exchangeRate: band.tierRate,
            currencyName: rate.currencyName || code,
          }
          return next
        })
      } else {
        setRows((prev) => {
          const next = [...prev]
          next[rowIdx] = { ...next[rowIdx]!, currencyCode: code }
          return next
        })
      }
    },
    [mode],
  )

  const handleCurrencyConfirm = useCallback((rowIdx: number) => {
    setActiveRow(rowIdx)
    setActiveField('rate')
  }, [])

  const handleRateInput = useCallback((rowIdx: number, value: string) => {
    const cleaned = value.replace(/[^0-9.,]/g, '').replace(',', '.')
    const newRate = parseFloat(cleaned) || 0
    setRows((prev) => {
      const next = [...prev]
      const row = next[rowIdx]!
      const qtyNum = parseFloat(row.quantity) || 0
      const hufValue = roundHuf(newRate * qtyNum)
      next[rowIdx] = { ...row, exchangeRate: newRate, hufValue }
      return next
    })
  }, [])

  const validateRateOnBlur = useCallback(
    (rowIdx: number) => {
      const row = rows[rowIdx]
      if (!row || !row.currencyCode || row.exchangeRate <= 0) return

      const rateObj = exchangeRates.find((r) => r.currencyCode === row.currencyCode)
      if (!rateObj) return

      const qtyNum = parseFloat(row.quantity) || 0
      const baseRate = mode === 'buy' ? rateObj.baseBuyRate : rateObj.baseSellRate
      const baseAmountHuf = qtyNum * baseRate

      if (!isWithinHardLimit(row.exchangeRate, rateObj.officialRate, mode)) {
        toast.error(
          'Árfolyam meghaladja a hard limitet',
          getHardLimitMessage(mode, rateObj.officialRate!),
        )
        const band = getBandForAmount(rateObj, mode, baseAmountHuf)
        setRows((prev) => {
          const next = [...prev]
          next[rowIdx] = {
            ...next[rowIdx]!,
            exchangeRate: band.tierRate,
            hufValue: roundHuf(band.tierRate * qtyNum),
          }
          return next
        })
        return
      }

      // Codex P1 #562 + #579 iter-3 + iter-4 fix:
      // A cashierCustomRateRowsRef Set lokálisan számon tartja az auto-approved
      // sorokat (rowKey = `${idx}-${currency}`). Pruning ELŐSZÖR fut, MINDEN
      // mező-változásra (rate edit / currency change). Két stale eset:
      //   (1) #579 iter-3: rowKey-currency már NEM egyezik a current row currency-jével
      //       (user EUR→USD switch ugyanazon a soron) → key benne ragadna
      //   (2) #579 iter-4: a rate VISSZA-szerkesztett in-band-be ugyanazon a row+currency-n
      //       (user 305 EUR off-band → 300 EUR in-band) → backend quota nem fogyasztott,
      //       de a key továbbra is foglalja a local effectiveRemaining slot-ot
      // A pruning mindkét scenarioban a megfelelő entry-t törli.
      for (const k of Array.from(cashierCustomRateRowsRef.current)) {
        const dashIdx = k.indexOf('-')
        if (dashIdx <= 0) continue
        const trackedIdx = Number.parseInt(k.slice(0, dashIdx), 10)
        const trackedCurrency = k.slice(dashIdx + 1)
        const trackedRow = rows[trackedIdx]
        // (1) Stale: row removed or currency changed
        if (!trackedRow || trackedRow.currencyCode !== trackedCurrency) {
          cashierCustomRateRowsRef.current.delete(k)
          rateAuthApprovedRef.current.delete(k)
          continue
        }
        // (2) Stale: rate now IN-band → no quota slot needed.
        // Codex P1 #579 iter-5 fix: isWithinBand BASE-rate-based HUF-fal hivando
        // (a tier selection a baseRate * qty alapjan tortenik MINDENHOL a fajlban,
        // lasd lines 303-305, 358-363, 450-452). Ha a custom rate * qty-val hivnank,
        // egy magas custom rate-tel atugorhatnank tier-t es false in-band classification
        // → silent freed slot. Ezert tracked baseRate * trackedQty hasznalando.
        const trackedRateObj = exchangeRates.find((r) => r.currencyCode === trackedCurrency)
        const trackedQty = Number.parseFloat(trackedRow.quantity.replace(/[\s,]/g, '.')) || 0
        if (trackedRateObj) {
          const trackedBaseRate =
            mode === 'buy' ? trackedRateObj.baseBuyRate : trackedRateObj.baseSellRate
          const trackedBaseHuf = trackedBaseRate * trackedQty
          if (isWithinBand(trackedRateObj, trackedRow.exchangeRate, mode, trackedBaseHuf)) {
            cashierCustomRateRowsRef.current.delete(k)
            rateAuthApprovedRef.current.delete(k)
          }
        }
      }

      const rowKey = `${rowIdx}-${row.currencyCode}`
      if (rateAuthApprovedRef.current.has(rowKey)) return

      if (!isWithinBand(rateObj, row.exchangeRate, mode, baseAmountHuf)) {
        const hufAmount = row.exchangeRate * qtyNum
        const minAmount = cashierRateQuota?.minAmountHuf ?? 400000
        const baseRemaining = cashierRateQuota?.remaining ?? 0
        const approvedLocally = cashierCustomRateRowsRef.current.size
        const effectiveRemaining = Math.max(0, baseRemaining - approvedLocally)

        if (hufAmount >= minAmount && effectiveRemaining > 0) {
          cashierCustomRateRowsRef.current.add(rowKey)
          rateAuthApprovedRef.current.add(rowKey)
          // Aktuális felhasználás after this approval = (limit - baseRemaining) + local_approved (most már +1).
          const totalUsedAfterThis =
            cashierRateQuota!.limit - baseRemaining + cashierCustomRateRowsRef.current.size
          toast.success(
            'Pénztárosi sáv',
            `Egyedi árfolyam engedélyezve (${totalUsedAfterThis}/${cashierRateQuota!.limit} ma)`,
          )
          return
        }

        if (hufAmount >= minAmount && effectiveRemaining <= 0) {
          toast.warning(
            'Pénztárosi sáv limit',
            `Napi ${cashierRateQuota?.limit ?? 5} egyedi árfolyam felhasználva!`,
          )
        }

        setRateAuthRow(rowIdx)
        setRateAuthPendingRate(row.exchangeRate)
        setShowRateAuth(true)
      }
    },
    [rows, exchangeRates, mode, cashierRateQuota],
  )

  const handleQuantityInput = useCallback(
    (rowIdx: number, value: string) => {
      const qty = value.replace(/[^0-9.]/g, '')
      setRows((prev) => {
        const next = [...prev]
        const row = next[rowIdx]!
        const qtyNum = parseFloat(qty) || 0

        const rateObj = exchangeRates.find((r) => r.currencyCode === row.currencyCode)
        let appliedRate = row.exchangeRate

        if (rateObj) {
          const baseRate = mode === 'buy' ? rateObj.baseBuyRate : rateObj.baseSellRate
          const baseAmountHuf = baseRate * qtyNum
          const band = getBandForAmount(rateObj, mode, baseAmountHuf)
          const rowKey = `${rowIdx}-${row.currencyCode}`
          if (!rateAuthApprovedRef.current.has(rowKey)) {
            appliedRate = band.tierRate
          }
        }

        const hufValue = roundHuf(appliedRate * qtyNum)
        next[rowIdx] = { ...row, quantity: qty, exchangeRate: appliedRate, hufValue }
        return next
      })
    },
    [exchangeRates, mode],
  )

  const sendIncomeProofEmail = useCallback(
    async (payload: IncomeProofEmailPayload) => {
      setIncomeProofPendingPayload(payload)
      setIncomeProofSendError(null)
      setShowIncomeProofSendModal(true)
      setIncomeProofSending(true)
      try {
        await incomeSourceDocApi.sendEmail(payload)
        incomeProofBase64Ref.current = null
        setIncomeProofPendingPayload(null)
        setShowIncomeProofSendModal(false)
        toast.success(t('incomeProof.kuldesSikeres'))
      } catch (err) {
        const message = getErrorMessage(err)
        logger.error('CashierTransactionPage', 'Income proof email send failed:', message)
        setIncomeProofSendError(message)
      } finally {
        setIncomeProofSending(false)
      }
    },
    [t],
  )

  const cancelIncomeProofEmail = useCallback(async () => {
    const transactionRef = incomeProofPendingPayload?.transactionRef
    try {
      await recordLocalAuditEvent({
        entityType: 'income_proof',
        eventType: 'INCOME_PROOF_EMAIL_UNFULFILLED',
        payload: {
          workerCode: useAuthStore.getState().worker?.workerCode ?? 'unknown',
          hufTotal: incomeProofPendingPayload?.hufAmount ?? total,
          transactionRef,
          reason: 'küldés sikertelen, pénztáros megszakította',
        },
        status: 'degraded',
      })
    } catch (err) {
      logger.warn(
        'CashierTransactionPage',
        'Income proof audit write failed:',
        getErrorMessage(err),
      )
    }
    incomeProofBase64Ref.current = null
    setIncomeProofPendingPayload(null)
    setIncomeProofSendError(null)
    setShowIncomeProofSendModal(false)
  }, [incomeProofPendingPayload, total])

  const handleSubmit = useCallback(async () => {
    // Codex P1 #586 iter-6: double-submit guard a REF-en olvas (NEM a state-en), igy az
    // useCallback memoizalt closure-ja is friss erteket lat. setIsSubmitting state-tukor
    // a button.disabled UI-hoz, isSubmittingRef.current az atomikus guard a logikahoz.
    if (isSubmittingRef.current) {
      logger.warn('CashierTransactionPage', 'Duplicate handleSubmit ignored (already submitting)')
      return
    }

    // Collect rows with any input (currency code typed)
    const touchedRows = rows.filter((r) => r.currencyCode.length > 0)
    if (touchedRows.length === 0) return

    // Session guard — block if session closed OR still loading (null)
    if (sessionOpen !== true) {
      toast.error(
        sessionOpen === null ? 'Session ellenorzes folyamatban' : 'Nincs nyitott nap',
        sessionOpen === null
          ? 'Varj, amig a napi session allapota ellenorzesre kerul!'
          : 'A tranzakcio rogzitesehez eloszor meg kell nyitni a napot!',
      )
      return
    }

    // Rate staleness warning (>5 min since load)
    if (ratesLoadedAtRef.current > 0 && Date.now() - ratesLoadedAtRef.current > RATE_STALE_MS) {
      toast.warning(
        'Arfolyam regi',
        'Az arfolyamok tobb mint 5 perce toltodtek be. Frissitsd az oldalt az aktualis arfolyamokhoz!',
      )
    }

    // Sell-mode stock check — verify branch has enough currency to sell
    // V235 (2026-05-19 HIBA #10): Buy-mode is ellenorzi a HUF keszletet — a vetel
    // soran a penztar HUF-ot fizet ki, ami CSOKKENTI a HUF keszletet. Ha nincs
    // eleg HUF a kasszaban, fail-closed (nem engedjuk az Electron offline queue-ba,
    // mert ott a hiba csak sync-kor derulne ki).
    if (mode === 'sell' || mode === 'buy') {
      try {
        const balances = await cashBalanceApi.list()
        const insufficientRows: string[] = []
        if (mode === 'sell') {
          for (const row of touchedRows) {
            if (row.currencyCode.length !== 3) continue
            const qty = parseFloat(row.quantity) || 0
            if (qty <= 0) continue
            const bal = balances.find((b) => b.currencyCode === row.currencyCode)
            const available = bal?.currentBalance ?? 0
            if (qty > available) {
              insufficientRows.push(`${row.currencyCode}: ${qty} kert, ${available} elerheto`)
            }
          }
        } else {
          // BUY: a tetelek hufValue-jat osszegezzuk, level kell vonni a kezelesi
          // dijat es a 5 Ft kerekitest, mert a backend a payable-bol vonja le a
          // fee-t mielott kifizet (TransactionService.processBuyTransaction). A
          // korabbi naiv summing-fee felulmero volt es indokolatlan blokkolast
          // okozhatott. Copilot P2 (PR #695) fix.
          const grossHuf = touchedRows.reduce((sum, row) => {
            if (row.currencyCode.length !== 3) return sum
            const qty = parseFloat(row.quantity) || 0
            if (qty <= 0) return sum
            return sum + Math.max(0, row.hufValue)
          }, 0)
          // Penztaros kifizetes ~= bruttó − handlingFee, 5 Ft-os rounding-toleranciaval
          const totalHufPayable = roundHuf(
            Math.max(0, grossHuf - (handlingFee > 0 ? handlingFee : 0)),
          )
          const hufBal = balances.find((b) => b.currencyCode === 'HUF')
          const hufAvailable = hufBal?.currentBalance ?? 0
          if (totalHufPayable > hufAvailable) {
            insufficientRows.push(
              `HUF: ${totalHufPayable.toLocaleString('hu-HU')} Ft kifizetes kerne, csak ${hufAvailable.toLocaleString('hu-HU')} Ft elerheto a kasszaban`,
            )
          }
        }
        if (insufficientRows.length > 0) {
          toast.error('Nincs eleg keszlet', insufficientRows.join(' | '))
          return
        }
      } catch (err) {
        logger.error('CashierTransactionPage', 'Keszletellenorzes sikertelen:', err)
        // Fail-closed: ha nem tudjuk ellenorizni, nem engedjuk tovabb
        toast.error(
          'Keszletellenorzes sikertelen',
          'A keszlet nem ellenorizheto. Probald ujra kesobb.',
        )
        return
      }
    }

    // Input validation — check ALL touched rows, collect errors
    const validationErrors: string[] = []
    for (const row of touchedRows) {
      if (row.currencyCode.length !== 3) {
        validationErrors.push(`"${row.currencyCode}" nem ervenyes 3 betus valutakod.`)
      }
      if (!row.exchangeRate || row.exchangeRate <= 0) {
        validationErrors.push(`${row.currencyCode || '?'}: nincs betoltve arfolyam.`)
      }
      const qty = parseFloat(row.quantity)
      if (!qty || qty <= 0) {
        validationErrors.push(`${row.currencyCode || '?'}: a mennyiseg 0-nal nagyobb kell legyen.`)
      }
    }
    if (validationErrors.length > 0) {
      toast.warning('Hibas sorok', validationErrors.join(' | '))
      return
    }

    // After validation, only send rows with actual values
    const filledRows = touchedRows.filter((r) => r.currencyCode.length === 3 && r.hufValue > 0)
    if (filledRows.length === 0) return

    // AML/identification check
    const cd = customerDataRef.current
    const aml = amlResultRef.current
    if (identificationLevel !== 'SIMPLE') {
      // A NÉV minden azonosított szinten kötelező. Az okmányszám viszont CSAK FULL (300k+)
      // szinten — a SIMPLIFIED (100k–300k) a CustomerPanel-ben szándékosan REJTI az okmányszám
      // mezőt (HIBA #12 / v2.27.22), így itt megkövetelni egy kitölthetetlen mezőt → blokkolná
      // az új, kézi ügyfél rögzítését 100k–300k között. (Az okmányszám-követelmény a FULL-ágba
      // került lentebb.)
      if (!cd?.name?.trim()) {
        toast.warning(
          'Ügyfél azonosítás kötelező',
          `${SIMPLIFIED_IDENTIFICATION_LIMIT.toLocaleString('hu-HU')} Ft feletti tranzakcióhoz ügyfél azonosítás KÖTELEZŐ!`,
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

    if (mode === 'buy' && !incomeProofBase64Ref.current) {
      try {
        const check = await incomeSourceDocApi.checkRequired(
          total,
          cd?.id ? String(cd.id) : undefined,
          filledRows[0]?.currencyCode,
        )
        if (check.required && !incomeProofBase64Ref.current) {
          setIncomeProofRequired(true)
          setShowIncomeProofModal(true)
          return
        }
      } catch (err) {
        logger.warn(
          'CashierTransactionPage',
          'Income proof required-check hiba:',
          getErrorMessage(err),
        )
        if (total >= 10_000_000) {
          toast.error(t('incomeProof.offlineBlokk'))
          return
        }
      }
    }

    // AML felsovezetoi jovahagyas pre-check (2026-06-04): ha a backend szerint a tranzakcio
    // felsovezetoi jovahagyast igenyel (FATF / eves gongyolesi limit >=3.6M / BIGCTRL 4+), elkerjuk
    // az engedelyezo workerId-t egy modallal, MIELOTT rogzitenenk (a local-first kliens kulonben
    // csak sync-kor tudna meg, hogy approval kellett volna). A pre-check authoritativ: a backend ket
    // AML-kapujat futtatja. Offline/hiba eseten NEM blokkol (a tranzakcio-POST/sync ugyis kivaltja a
    // szerver-oldali validaciot). Ha mar van approver (a modal utani re-invoke), atugorjuk.
    if (approverWorkerIdRef.current == null) {
      // In-flight guard (Copilot review): parhuzamos pre-check/modal elkerulese gyors dupla-submitnel.
      if (amlPrecheckInFlightRef.current) return
      amlPrecheckInFlightRef.current = true
      try {
        const checkRes = await api.post('/aml-approval/check-required', {
          amountHuf: total,
          customerId: cd?.id || undefined,
          customerName: cd?.name || undefined,
          documentNumber: cd?.documentNumber || undefined,
          currencyCode: filledRows[0]?.currencyCode,
          customerNationality: cd?.nationality || undefined,
        })
        if (checkRes.data?.requiresApproval) {
          // Uj jovahagyas-session a nyugtahoz (a grantot ehhez + a jovahagyott ugyfelhez koti a backend).
          approvalSessionIdRef.current = crypto.randomUUID()
          setAmlApprovalReason(
            typeof checkRes.data?.reason === 'string' ? checkRes.data.reason : '',
          )
          setShowAmlApprover(true)
          return // a modal onApproved-ja beallitja az approverWorkerId-t es ujrahivja a submitet
        }
      } catch (err) {
        logger.warn('CashierTransactionPage', 'AML approval pre-check hiba (nem blokkolo):', err)
      } finally {
        amlPrecheckInFlightRef.current = false
      }
    }

    // Local-first degradált AML mód (2026-05-14 user-direktíva): ha az AML ellenőrzés
    // hálózati/szerver hiba miatt nem futott le, a warnings tömb `[OFFLINE_DEGRADED]`
    // prefix-szel jelzi. Ilyenkor a pénztáros KÉNYTELEN megerősíteni hogy folytatja —
    // audit log rögzíti, központi szerver utólag újra-ellenőriz.
    const amlDegraded = aml?.warnings?.some((w) => w.startsWith('[OFFLINE_DEGRADED]')) ?? false
    if (amlDegraded && identificationLevel !== 'SIMPLE') {
      const confirmed = window.confirm(
        'FIGYELEM: Az AML ellenőrzés nem futott le (hálózati hiba).\n\n' +
          'A tranzakció FOLYTATHATÓ, de:\n' +
          '• Audit naplóba degradált módként kerül\n' +
          '• A központi szerver utólag újra-ellenőrzi\n' +
          '• Ha az utólagos ellenőrzés gyanút talál, a pénztárost értesítjük\n\n' +
          'Biztosan folytatja?',
      )
      if (!confirmed) {
        toast.info(
          'Tranzakció megszakítva',
          'Várj amíg helyreáll a hálózat, vagy próbáld újra később.',
        )
        return
      }
      // Codex P1 #586 iter-5 fix: setIsSubmitting(true) ELŐTT az audit write await, hogy a
      // ket-katintas / duplikalt-keyboard NE indithasson parhuzamos handleSubmit-et amig
      // az audit write fut. A handleSubmit elejen az isSubmitting guard mar visszater
      // ha mar fut egy submit. Itt explicit setIsSubmitting(true) az audit write elott.
      setIsSubmitting(true)
      try {
        const auditId = await recordLocalAuditEvent({
          entityType: 'aml_check',
          eventType: 'AML_DEGRADED_PROCEED',
          payload: {
            workerCode: useAuthStore.getState().worker?.workerCode ?? 'unknown',
            hufTotal: total,
            identificationLevel,
            customerId: cd?.id ?? null,
            customerDocNumber: cd?.documentNumber ?? null,
            confirmedAt: new Date().toISOString(),
            reason:
              'AML check failed (offline/server error), pénztáros explicit megerősítéssel folytatta',
          },
          status: 'degraded',
        })
        if (auditId == null) {
          // Electron API NEM elerheto (NEM Electron, vagy bridge nincs feltoltve).
          setIsSubmitting(false)
          toast.error(
            'Audit napló nem érhető el',
            'Degradált AML módban a tranzakció CSAK Electron klienssel folytathatható (audit naplóhoz). Kérjük indítsa el a pénztár klienst.',
          )
          return
        }
      } catch (auditErr) {
        setIsSubmitting(false)
        logger.error(
          'CashierTransactionPage',
          'AML degradalt audit log persist FAILED — tranzakcio blokkolva',
          auditErr,
        )
        toast.error(
          'Audit napló mentés sikertelen',
          'A degradált AML mód audit naplójának mentése nem sikerült. A tranzakció biztonsági okokból nem folytatható. Próbáld újra.',
        )
        return
      }
    } else {
      // Non-degraded path: setIsSubmitting itt (mint korabban).
      setIsSubmitting(true)
    }

    try {
      const customerData = cd
        ? {
            customerId: cd.id || undefined,
            customerName: cd.name || undefined,
            customerDocumentNumber: cd.documentNumber || undefined,
            customerDocumentType: cd.documentType || undefined,
            customerNationality: cd.nationality || undefined,
            customerBirthPlace: cd.birthPlace || undefined,
            customerBirthDate: cd.birthDate || undefined,
            customerMotherName: cd.motherName || undefined,
            customerAddress: cd.address || undefined,
            // V229 (2026-05-15 HIBA #8): 300k+ JOGCIM nyilatkozat
            customerIsPep: cd.isPep,
            sourceOfFunds: cd.sourceOfFunds,
            // AML 50M (Pmt./MNB 14/2025): strukturált forrás-dokumentum a szerver-oldali validációhoz
            sourceOfFundsDocType: cd.sourceOfFundsDocType,
            sourceOfFundsDocDate: cd.sourceOfFundsDocDate,
            customerOnOwnBehalf: cd.onOwnBehalf,
            customerActorName: cd.actorName,
            // V235 (2026-05-19 HIBA #15 + #17): PEP minoseg + actor teljes azonositasa
            customerPepKind: cd.pepKind ?? undefined,
            customerActorBirthPlace: cd.actorIdentity?.birthPlace,
            customerActorBirthDate: cd.actorIdentity?.birthDate,
            customerActorMotherName: cd.actorIdentity?.motherName,
            customerActorNationality: cd.actorIdentity?.nationality,
            customerActorDocumentType: cd.actorIdentity?.documentType,
            customerActorDocumentNumber: cd.actorIdentity?.documentNumber,
            customerActorAddress: cd.actorIdentity?.address,
            // V325 (Batch3-C): jogi szemely + tenyleges tulajdonosok a REST request-be
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
            // AML felsovezetoi jovahagyas: a jovahagyo workerId a REST buy/sell request-be (spread).
            approverWorkerId: approverWorkerIdRef.current ?? undefined,
            approvalSessionId: approvalSessionIdRef.current ?? undefined,
          }
        : {}

      // Penztar-batch C.1/C.2 (2026-06-12, user-kérés): a bizonylat Pmt.-mezői. Ezeket az
      // adatokat a backend felé eddig is elküldtük (customerData), de a BIZONYLAT-objektumból
      // hiányoztak — az előnézet '—' deviza-státuszt és statikus „saját nevemben" szöveget
      // mutatott, a nyomtatott bizonylatról pedig teljesen hiányoztak (printer.ts template).
      const receiptAmlFields = {
        customerNationality: cd?.nationality || undefined,
        customerMotherName: cd?.motherName || undefined,
        customerBirthPlace: cd?.birthPlace || undefined,
        customerBirthDate: cd?.birthDate || undefined,
        customerDocType: cd?.documentType || undefined,
        customerIsPep: cd?.isPep ?? undefined,
        customerPepKind: cd?.pepKind ?? undefined,
        sourceOfFunds: cd?.sourceOfFunds || undefined,
        customerOnOwnBehalf: cd?.onOwnBehalf ?? undefined,
        customerActorName: cd?.actorName || undefined,
        customerActorBirthPlace: cd?.actorIdentity?.birthPlace || undefined,
        customerActorBirthDate: cd?.actorIdentity?.birthDate || undefined,
        customerActorMotherName: cd?.actorIdentity?.motherName || undefined,
        customerActorNationality: cd?.actorIdentity?.nationality || undefined,
        customerActorDocumentType: cd?.actorIdentity?.documentType || undefined,
        customerActorDocumentNumber: cd?.actorIdentity?.documentNumber || undefined,
        customerActorAddress: cd?.actorIdentity?.address || undefined,
        // V325 (Batch3-C): jogi szemely blokk a bizonylaton (elonezet + nyomtatas)
        isLegalEntityCustomer: cd?.isLegalEntity ?? undefined,
        legalEntityName: cd?.legalEntityName || undefined,
        legalEntitySeat: cd?.legalEntitySeat || undefined,
        legalEntityTaxNumber: cd?.legalEntityTaxNumber || undefined,
        legalDeedNumber: cd?.legalDeedNumber || undefined,
        beneficialOwners: cd?.beneficialOwners?.length ? cd.beneficialOwners : undefined,
      }
      // C.2: a deviza-státusz MINDEN azonosítási szinten a bizonylatra kerül (a soronkénti
      // B/K toggle nem függ az azonosítástól). Többsoros nyugtán a fejléc csak akkor hordozza,
      // ha minden sor azonos — vegyesnél a soronkénti érték jelenik meg (transactionLines).
      const uniformForeignStatus = (rows: typeof filledRows): 'DOMESTIC' | 'FOREIGN' | undefined =>
        new Set(rows.map((r) => r.foreignStatus)).size === 1 ? rows[0]?.foreignStatus : undefined
      // Codex PR #1102 P1 + #1103 P1: a Pmt. 300k-s küszöb a FIZETENDŐ összegre vonatkozik
      // (AML-paritás), és a fizetendő MÓD-FÜGGŐ (BUY: +kedvezmény −díj; SELL: −kedvezmény +díj)
      // — a kanonikus multiLinePayable-lel számolunk (a szerver gross-számításának tükre).
      const singleRowPayable = (rowHuf: number): number =>
        multiLinePayable(
          rowHuf,
          mode === 'buy' ? 'buy' : 'sell',
          discount > 0 ? discount : 0,
          handlingFee > 0 ? handlingFee : 0,
        )

      if (electronQueueAvailable) {
        // V235 (2026-05-19 HIBA #14 + #15 + #17 + #18): a teljes Pmt. customer-
        // snapshot atadasa az Electron pending-queue fele. A korabbi payload csak
        // 4 alapmezot kuldott (name, docNumber, address, foreignStatus), igy a
        // bizonylaton hianyzott a szul.hely / szul.ido / anyja neve / allampolgar-
        // sag / okmany tipus / "mas neveben" flag es az actor teljes azonositasa.
        const actorIdentity = cd?.actorIdentity ?? null
        // Egy sor → PendingBuySellInput. A fejlec customer/AML mezok minden soron azonosak (egy
        // ugyfel / egy nyugta), a tetel-specifikus mezok (currency/foreign/huf/rate/foreignStatus)
        // a sorbol jonnek.
        const buildEntry = (row: TransactionRow): PendingBuySellInput => ({
          type: mode === 'buy' ? 'BUY' : 'SELL',
          currencyCode: row.currencyCode,
          foreignAmount: parseFloat(row.quantity) || 0,
          hufAmount: row.hufValue,
          roundedHufAmount: roundHuf(row.hufValue),
          rate: row.exchangeRate,
          handlingFee: handlingFee > 0 ? handlingFee : null,
          // FK-KEZDIJ offline (2026-06-12, B.1/b): a dij-override eddig CSENDBEN elveszett
          // az Electron uton — a REST-tel azonos mezok az offline queue-ba is.
          handlingFeeOverrideType: feeOverrideType || null,
          handlingFeeOverrideReason: feeOverrideReason || null,
          customerCardNumber: cardNumber.trim() || null,
          discountPercent: discount > 0 ? discount : null,
          customerIdentifier: cd?.documentNumber || null,
          customerName: cd?.name || null,
          customerDocumentNumber: cd?.documentNumber || null,
          customerAddress: cd?.address || null,
          denominations: null,
          foreignStatus: row.foreignStatus,
          // V229 100k+ alapmezok
          customerBirthPlace: cd?.birthPlace ?? null,
          customerBirthDate: cd?.birthDate ?? null,
          customerMotherName: cd?.motherName ?? null,
          customerNationality: cd?.nationality ?? null,
          customerDocumentType: cd?.documentType ?? null,
          // V229 300k+ JOGCIM nyilatkozat
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
          // AML felsovezetoi jovahagyas: a jovahagyo workerId (NULL ha nem kellett). A local-first
          // kliens lokalisan perzisztalja, majd a sync a backend-body-ba teszi.
          approverWorkerId: approverWorkerIdRef.current,
          approvalSessionId: approvalSessionIdRef.current,
          // V325 (Batch3-C): jogi szemely + tenyleges tulajdonosok az offline queue-ba is.
          isLegalEntityCustomer: cd?.isLegalEntity ?? null,
          legalEntityName: cd?.legalEntityName || null,
          legalEntitySeat: cd?.legalEntitySeat || null,
          legalEntityTaxNumber: cd?.legalEntityTaxNumber || null,
          legalDeedNumber: cd?.legalDeedNumber || null,
          beneficialOwnersJson: cd?.beneficialOwners?.length
            ? JSON.stringify(cd.beneficialOwners)
            : null,
        })

        // Multi-line aggregate (2026-06-04): tobb-soros nyugtanal EGY aggregalt pending tranzakciot
        // mentunk `lines[]` tombbel — a sync EGY POST /transactions/buy|sell-t kuld, a backend egyetlen
        // AML-kaput es egyetlen approval-grantot fogyaszt el. Egysoros nyugtanal a viselkedes
        // VALTOZATLAN (egy pending, `lines` nelkul).
        //
        // RATE-SEMANTIKA (penz-helyesseg): minden sor customExchangeRate-jet a sor TENYLEGES alkalmazott
        // arfolyamara (row.exchangeRate) allitjuk — pontosan ahogy az egysoros sync is teszi
        // (sync-engine: customExchangeRate = tx.rate). Igy az aggregalt nyugta penzugyileg azonos N
        // egysoros tranzakcio osszegevel (resolveBuyRate/resolveSellRate ugyanazt a customExchangeRate-et
        // honoralja mindket uton). A per-soros discountType=0 (a tenyleges szazalekos kedvezmenyt a
        // fejlec discountPercent hordozza, mint az egysoros agon).
        let entries: PendingBuySellInput[]
        if (filledRows.length > 1) {
          const header = buildEntry(filledRows[0]!)
          const lines = filledRows.map((row) => ({
            currencyCode: row.currencyCode,
            banknoteCount: parseFloat(row.quantity) || 0,
            customExchangeRate: row.exchangeRate,
            discountType: 0,
            foreignStatus: row.foreignStatus,
          }))
          entries = [{ ...header, lines: JSON.stringify(lines) }]
        } else {
          entries = filledRows.map(buildEntry)
        }
        const outcome = await saveAndSyncPendingBuySell(entries)

        if (outcome.allSavedSynced) {
          toast.success(
            'Bizonylat(ok) sikeresen rögzítve!',
            `${filledRows.length} tétel azonnal könyvelve.`,
          )
        } else if (outcome.syncErrors && outcome.syncErrors.length > 0) {
          // FKH-032 FR-4: a célzott azonnali kísérlet TÉNYLEGES hibaoka látszik,
          // nem csak egy általános "helyi queue-ba került" üzenet.
          toast.error(
            `Azonnali könyvelés sikertelen — ${outcome.pendingCount} tétel helyben mentve`,
            sanitizeSyncErrorMessage(outcome.syncErrors[0] ?? ''),
          )
        } else {
          toast.warning(
            'Offline mentés megtörtént',
            `${outcome.pendingCount} tétel helyi queue-ba került, ${outcome.syncedCount} tétel azonnal könyvelve.`,
          )
        }

        const now = new Date()
        const outcomeReceipts = outcome.localReferenceNumbers ?? []
        const primaryReceiptRef = outcomeReceipts[0] ?? `P-${now.getTime()}-0`

        // Build receipt(s) (Electron)
        if (isElectron()) {
          // 2026-06-04 (audit-fix): a TÉNYLEGES, rögzített szigorú helyi sorszámok (a mentett
          // pending-sorok local_reference_number-jei, savedIds-szel azonos sorrendben). A
          // korábbi kód egy NEM LÉTEZŐ `receiptNumbers` mezőre castolt → mindig fabrikált
          // `P-<timestamp>` került a bizonylatra, ami EGYETLEN rögzített tranzakcióval sem
          // egyezett (audit-probléma). Most a valós sorszámot bélyegezzük; ha hiányzik (régi
          // telepítő / null), fallback a fabrikált számra.
          const receiptHeader = {
            type: mode === 'buy' ? ('buy' as const) : ('sell' as const),
            companyType: ((worker?.companyCode ?? '').startsWith('EXP')
              ? 'EXPRESSZ'
              : 'BEST_CHANGE') as 'BEST_CHANGE' | 'EXPRESSZ',
            branchCode: worker?.branchCode ?? '',
            cashierName: worker?.fullName ?? '',
            date: now.toLocaleDateString('hu-HU'),
            time: now.toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit' }),
            customerName: cd?.name || undefined,
            customerDocNumber: cd?.documentNumber || undefined,
            customerAddress: cd?.address || undefined,
            vatExemptionText: 'Tárgyi adómentes az ÁFA tv. 86.§ (1) bek. k) pontja alapján.',
            // C.1/C.2: deviza-státusz + Pmt.-mezők a bizonylaton (minden azonosítási szinten).
            ...receiptAmlFields,
          }

          if (filledRows.length > 1) {
            // Multi-line aggregate (2026-06-04): a sync EGY aggregált tranzakciót küldött EGY
            // bizonylatszámmal (outcomeReceipts[0]), így EGY bizonylatot nyomtatunk, amely az
            // összes valuta-sort listázza. A backend (TransactionMultiLineService) a nyers
            // per-soros HUF-okat ÖSSZEGZI, majd a TELJES összeget kerekíti EGYSZER 5 Ft-ra —
            // ezt tükrözzük a fejléc hufAmount/roundedHufAmount/roundingDiff mezőiben.
            // FINDING 2 (Codex P2): a nyomtatott FIZETENDŐ végösszegnek a backend multi-line
            // payable-jét KELL tükröznie — nyers Σ hufValue helyett a kedvezmény+kezelési díjjal
            // korrigált, EGYSZER 5 Ft-ra kerekített összeget (multiLinePayable). Különben a
            // bizonylaton mutatott összeg eltér a szinkronizált tranzakció hufAmount-jától, ha
            // díj/kedvezmény van. A per-soros transactionLines TOVÁBBRA is a NYERS per-soros
            // HUF-bontást mutatja (részletezés), a fejléc viszont a fizetendő végösszeget.
            const totalRaw = filledRows.reduce((sum, row) => sum + row.hufValue, 0)
            const totalPayable = multiLinePayable(
              totalRaw,
              mode === 'buy' ? 'buy' : 'sell',
              discount > 0 ? discount : 0,
              handlingFee > 0 ? handlingFee : 0,
            )
            const receipt: PrintReceiptData = {
              ...receiptHeader,
              receiptNumber: primaryReceiptRef,
              hufAmount: totalPayable,
              roundedHufAmount: totalPayable,
              roundingDiff: 0,
              handlingFee: handlingFee > 0 ? handlingFee : undefined,
              payableHufAmount: totalPayable, // Codex #1102 P1: a díjjal együtt
              foreignStatus: uniformForeignStatus(filledRows), // C.2
              transactionLines: filledRows.map((row) => ({
                currencyCode: row.currencyCode,
                foreignAmount: parseFloat(row.quantity) || 0,
                rate: row.exchangeRate,
                hufAmount: row.hufValue,
                foreignStatus: row.foreignStatus, // C.2: vegyes B/K esetén soronként
              })),
            }
            receiptQueueRef.current = []
            openReceiptModal(receipt)
          } else {
            // Egysoros bizonylat: változatlan viselkedés (egy sor → egy bizonylat egy számmal).
            const receipts: PrintReceiptData[] = filledRows.map((row, idx) => ({
              ...receiptHeader,
              receiptNumber:
                idx === 0
                  ? primaryReceiptRef
                  : (outcomeReceipts[idx] ?? `P-${now.getTime()}-${idx}`),
              currencyCode: row.currencyCode,
              foreignAmount: parseFloat(row.quantity) || 0,
              rate: row.exchangeRate,
              hufAmount: row.hufValue,
              roundedHufAmount: roundHuf(row.hufValue),
              roundingDiff: roundHuf(row.hufValue) - row.hufValue,
              payableHufAmount: singleRowPayable(row.hufValue), // Codex #1102 P1
              foreignStatus: row.foreignStatus, // C.2
            }))
            receiptQueueRef.current = receipts.slice(1)
            if (receipts[0]) {
              openReceiptModal(receipts[0])
            }
          }
        }
        if (incomeProofBase64Ref.current) {
          void sendIncomeProofEmail({
            imageBase64: incomeProofBase64Ref.current,
            mimeType: 'image/jpeg',
            transactionRef: primaryReceiptRef,
            customerName: cd?.name,
            hufAmount: total,
          })
        }
      } else {
        const now = new Date()
        const receiptBase = {
          type: mode === 'buy' ? ('buy' as const) : ('sell' as const),
          companyType: ((worker?.companyCode ?? '').startsWith('EXP')
            ? 'EXPRESSZ'
            : 'BEST_CHANGE') as 'BEST_CHANGE' | 'EXPRESSZ',
          branchCode: worker?.branchCode ?? '',
          cashierName: worker?.fullName ?? '',
          date: now.toLocaleDateString('hu-HU'),
          time: now.toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit' }),
          customerName: cd?.name || undefined,
          customerDocNumber: cd?.documentNumber || undefined,
          customerAddress: cd?.address || undefined,
          vatExemptionText: 'Tárgyi adómentes az ÁFA tv. 86.§ (1) bek. k) pontja alapján.',
          // C.1/C.2: deviza-státusz + Pmt.-mezők a bizonylaton (minden azonosítási szinten).
          ...receiptAmlFields,
        }

        if (filledRows.length > 1) {
          // FINDING 1 (Codex P1, 2026-06-04): többsoros nyugtát EGY aggregált REST-kérésként
          // küldünk (`lines[]`), tükrözve az Electron utat. A grant immár STRICT single-use →
          // a korábbi per-soros transactionApi.buy/sell loop a 2. sornál "already used"-del
          // bukna (részleges nyugta). Az aggregált kérést a backend executeMultiLineBuy/Sell
          // ÁGRA futtatja: EGY tranzakció, EGY AML-grant fogyasztás, EGY bizonylatszám.
          //
          // Fejléc: customer/AML/handlingFee/discount mezők az első soron át (a backend a díjat
          // + kedvezményt az AGGREGÁTUMRA alkalmazza). currencyCode/currencyAmount/customExchangeRate
          // az ELSŐ sorból (a backend a fejléc-összeget figyelmen kívül hagyja, ha lines[] jelen van —
          // egyezően az Electron úttal). Soronkénti customExchangeRate = row.exchangeRate (a pénztáros
          // PONTOS árfolyama, ahogy az egysoros úton is). Per-soros discountType=0 (a százalékos
          // kedvezményt a fejléc discountPercent hordozza).
          const first = filledRows[0]!
          const lines: TransactionLineRequest[] = filledRows.map((row) => ({
            currencyCode: row.currencyCode,
            banknoteCount: parseFloat(row.quantity) || 0,
            customExchangeRate: row.exchangeRate,
            discountType: 0,
            foreignStatus: row.foreignStatus,
          }))
          const aggregateBase = {
            currencyCode: first.currencyCode,
            currencyAmount: parseFloat(first.quantity) || 0,
            customExchangeRate: first.exchangeRate,
            handlingFee: handlingFee > 0 ? handlingFee : undefined,
            // FK-KEZDÍJ (2026-06-02): kezelési díj override (a szerver validálja az engedély-mátrixot)
            handlingFeeOverrideType: feeOverrideType || undefined,
            handlingFeeOverrideReason: feeOverrideReason || undefined,
            customerCardNumber: cardNumber.trim() || undefined,
            discountPercent: discount > 0 ? discount : undefined,
            foreignStatus: first.foreignStatus,
            lines,
            ...customerData,
          }
          const result =
            mode === 'buy'
              ? await transactionApi.buy(aggregateBase as BuyRequest)
              : await transactionApi.sell(aggregateBase as SellRequest)

          toast.success(
            'Bizonylat(ok) sikeresen készítve!',
            `${filledRows.length} tétel, ${total.toLocaleString('hu-HU')} Ft | Bizonylat szám: ${result.receiptNumber}`,
          )

          // EGY bizonylat az összes valuta-sorral (mirror az Electron multi-line ágat). A fejléc
          // hufAmount-ot a backend által visszaadott aggregált összegre állítjuk (single-source-of-
          // truth: a tényleges payable, díj/kedvezmény + 5 Ft kerekítéssel). A per-soros bontás a
          // nyers per-soros HUF-ot mutatja.
          const totalRaw = filledRows.reduce((sum, row) => sum + row.hufValue, 0)
          const backendHuf = typeof result.hufAmount === 'number' ? result.hufAmount : null
          const totalPayable =
            backendHuf ??
            multiLinePayable(
              totalRaw,
              mode === 'buy' ? 'buy' : 'sell',
              discount > 0 ? discount : 0,
              handlingFee > 0 ? handlingFee : 0,
            )
          const receipt: PrintReceiptData = {
            ...receiptBase,
            receiptNumber: result.receiptNumber,
            hufAmount: totalPayable,
            roundedHufAmount: totalPayable,
            roundingDiff: 0,
            handlingFee: handlingFee > 0 ? handlingFee : undefined,
            payableHufAmount: totalPayable, // Codex #1102 P1: a díjjal együtt
            foreignStatus: uniformForeignStatus(filledRows), // C.2
            transactionLines: filledRows.map((row) => ({
              currencyCode: row.currencyCode,
              foreignAmount: parseFloat(row.quantity) || 0,
              rate: row.exchangeRate,
              hufAmount: row.hufValue,
              foreignStatus: row.foreignStatus, // C.2: vegyes B/K esetén soronként
            })),
          }
          receiptQueueRef.current = []
          openReceiptModal(receipt)
          if (incomeProofBase64Ref.current) {
            void sendIncomeProofEmail({
              imageBase64: incomeProofBase64Ref.current,
              mimeType: 'image/jpeg',
              transactionRef: result.receiptNumber,
              customerName: cd?.name,
              hufAmount: total,
            })
          }
        } else {
          // Egysoros REST út: VÁLTOZATLAN viselkedés (egy sor → egy kérés → egy bizonylat).
          const receiptNumbers: string[] = []
          for (let ri = 0; ri < filledRows.length; ri++) {
            const row = filledRows[ri]!
            const rowKey = `${ri}-${row.currencyCode}`
            const isCashierCustom = cashierCustomRateRowsRef.current.has(rowKey) || undefined
            if (mode === 'buy') {
              const request: BuyRequest = {
                currencyCode: row.currencyCode,
                currencyAmount: parseFloat(row.quantity) || 0,
                customExchangeRate: row.exchangeRate,
                handlingFee: handlingFee > 0 ? handlingFee : undefined,
                // FK-KEZDÍJ (2026-06-02): kezelési díj override (a szerver validálja az engedély-mátrixot)
                handlingFeeOverrideType: feeOverrideType || undefined,
                handlingFeeOverrideReason: feeOverrideReason || undefined,
                customerCardNumber: cardNumber.trim() || undefined,
                discountPercent: discount > 0 ? discount : undefined,
                cashierCustomRate: isCashierCustom,
                foreignStatus: row.foreignStatus,
                ...customerData,
              }
              const result = await transactionApi.buy(request)
              receiptNumbers.push(result.receiptNumber)
            } else {
              const request: SellRequest = {
                currencyCode: row.currencyCode,
                currencyAmount: parseFloat(row.quantity) || 0,
                customExchangeRate: row.exchangeRate,
                handlingFee: handlingFee > 0 ? handlingFee : undefined,
                // FK-KEZDÍJ (2026-06-02): kezelési díj override (a szerver validálja az engedély-mátrixot)
                handlingFeeOverrideType: feeOverrideType || undefined,
                handlingFeeOverrideReason: feeOverrideReason || undefined,
                customerCardNumber: cardNumber.trim() || undefined,
                discountPercent: discount > 0 ? discount : undefined,
                cashierCustomRate: isCashierCustom,
                foreignStatus: row.foreignStatus,
                ...customerData,
              }
              const result = await transactionApi.sell(request)
              receiptNumbers.push(result.receiptNumber)
            }
          }

          toast.success(
            'Bizonylat(ok) sikeresen készítve!',
            `${filledRows.length} tétel, ${total.toLocaleString('hu-HU')} Ft | Bizonylat számok: ${receiptNumbers.join(', ')}`,
          )
          const primaryReceiptRef = receiptNumbers[0]

          // Build receipt queue for all lines (API path)
          if (filledRows.length > 0 && receiptNumbers.length > 0) {
            const receipts: PrintReceiptData[] = filledRows.map((row, idx) => ({
              ...receiptBase,
              receiptNumber: receiptNumbers[idx] ?? `API-${now.getTime()}-${idx}`,
              currencyCode: row.currencyCode,
              foreignAmount: parseFloat(row.quantity) || 0,
              rate: row.exchangeRate,
              hufAmount: row.hufValue,
              roundedHufAmount: roundHuf(row.hufValue),
              roundingDiff: roundHuf(row.hufValue) - row.hufValue,
              payableHufAmount: singleRowPayable(row.hufValue), // Codex #1102 P1
              foreignStatus: row.foreignStatus, // C.2
            }))
            receiptQueueRef.current = receipts.slice(1)
            if (receipts[0]) {
              openReceiptModal(receipts[0])
            }
          }
          if (incomeProofBase64Ref.current && primaryReceiptRef) {
            void sendIncomeProofEmail({
              imageBase64: incomeProofBase64Ref.current,
              mimeType: 'image/jpeg',
              transactionRef: primaryReceiptRef,
              customerName: cd?.name,
              hufAmount: total,
            })
          }
        }
      }

      // Reset
      setRows(Array.from({ length: MAX_LINES }, emptyRow))
      setActiveRow(0)
      setActiveField('currency')
      customerDataRef.current = null
      setComplianceCustomerId(null)
      amlResultRef.current = null
      incomeProofBase64Ref.current = null
      setShowIncomeProofModal(false)
      setIncomeProofRequired(false)
      // AML jovahagyas: a kovetkezo tranzakcio friss jovahagyas-allapotrol induljon.
      approverWorkerIdRef.current = null
      approvalSessionIdRef.current = null
      // Codex P2 + Copilot P2 #579 follow-up: a tranzakció lezárult, a backend
      // most már perzisztens cashierCustomRate-flagű sorokat számol. Lokális
      // ref-eket tisztítjuk, hogy a következő tranzakció a friss backend-quota
      // baseline-ról induljon, és az abandoned-rowKey-k NE számítsanak a local
      // effectiveRemaining-be.
      cashierCustomRateRowsRef.current.clear()
      rateAuthApprovedRef.current.clear()
      // Codex P2 #579 iter-4 fix: NE blokkoljuk az isSubmitting felszabadulását a
      // post-save quota refresh-szel. Offline/Electron flow-ban a backend
      // unreachable → submit stuck az API timeout-ig. Helyette fire-and-forget
      // a quota refetch: setCashierRateQuota async, a felhasználó már új tranzakciót
      // kezdhet a régi-de-rendezett kvótával (mivel a ref-eket lokálisan tisztítottuk).
      transactionApi
        .getCashierRateQuota()
        .then((quota) => setCashierRateQuota(quota))
        .catch((e) =>
          logger.error('CashierTx', 'Quota refresh failed after submit (non-blocking)', e),
        )
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Ismeretlen hiba'
      const axiosError = error as { response?: { data?: { message?: string } } }
      const serverMessage = axiosError?.response?.data?.message
      toast.error('Hiba a tranzakció mentés során!', serverMessage || message)
      // Codex P2: hiba esetén ÉRVÉNYTELENÍTJÜK a jóváhagyást — különben a pénztáros szerkeszthetné a
      // sorokat/ügyfelet, és UGYANAZZAL a granttal/session-nel egy MÁSIK nyugtát küldhetne (receipt-
      // scoping szivárgás). Újraküldéskor friss pre-check + új PIN-jóváhagyás kell.
      approverWorkerIdRef.current = null
      approvalSessionIdRef.current = null
    } finally {
      setIsSubmitting(false)
    }
  }, [
    rows,
    mode,
    total,
    handlingFee,
    discount,
    identificationLevel,
    sessionOpen,
    electronQueueAvailable,
    worker?.branchCode,
    worker?.companyCode,
    worker?.fullName,
    openReceiptModal,
    sendIncomeProofEmail,
    t,
    // Lint-audit 2026-08-09 (react-hooks/exhaustive-deps): ez a harom ertek a
    // FELKULDOTT payload resze (handlingFeeOverrideType / -Reason /
    // customerCardNumber, lasd :1212, :1449, :1523, :1540), de hianyzott a
    // deps-listabol. Ha a penztaros UTOLJARA a dij-felulbiralast vagy a
    // kartyaszamot allitja be, a memoizalt closure a REGI erteket vinne fel —
    // dijelszamolasi es ugyfel-azonositasi (Pmt.) hiba. Az `isSubmitting`
    // szandekosan marad kint (:229 komment, ref-bol olvassuk); ezek viszont
    // ritkan valtozo user-input mezok, a re-create koltsege elhanyagolhato.
    cardNumber,
    feeOverrideReason,
    feeOverrideType,
    // `setIsSubmitting` stabil (`useCallback(..., [])` a :249 soron), a
    // felvetele nem okoz ujra-kreacios cascade-et.
    setIsSubmitting,
  ])

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent, rowIdx: number, field: 'currency' | 'rate' | 'quantity') => {
      if (e.key === 'Tab' && e.shiftKey) {
        e.preventDefault()
        if (field === 'quantity') {
          setActiveField('rate')
        } else if (field === 'rate') {
          setActiveField('currency')
        } else if (field === 'currency' && rowIdx > 0) {
          setActiveRow(rowIdx - 1)
          setActiveField('quantity')
        }
        return
      }
      if (e.key === 'Enter' || e.key === 'Tab') {
        e.preventDefault()
        if (field === 'currency') {
          setActiveField('rate')
        } else if (field === 'rate') {
          setActiveField('quantity')
        } else if (field === 'quantity') {
          if (rowIdx < MAX_LINES - 1) {
            setActiveRow(rowIdx + 1)
            setActiveField('currency')
          } else {
            handleSubmit()
          }
        }
      } else if (e.key === 'ArrowDown') {
        e.preventDefault()
        if (rowIdx < MAX_LINES - 1) {
          setActiveRow(rowIdx + 1)
        }
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        if (rowIdx > 0) {
          setActiveRow(rowIdx - 1)
        }
      } else if (e.key === 'Escape') {
        e.preventDefault()
        // Sor torlese — setRows callback form-ben olvassuk a current prev-et, NE
        // a closure-bol (kulonben rows-t kellene useCallback dep-nek megadni, ami
        // minden billentyunyomasra recreate-elne a handler-t).
        // Codex P2 + Copilot P2 #579 follow-up: ha a torolt sornak volt rowKey-je
        // a cashierCustomRate/rateAuth ref-ekben (auto-approved volt korabban),
        // toroljuk onnan is — kulonben abandoned-row fogyasztana a local quota-t.
        setRows((prev) => {
          const targetRow = prev[rowIdx]
          const oldRowKey = targetRow ? `${rowIdx}-${targetRow.currencyCode}` : null
          if (oldRowKey) {
            cashierCustomRateRowsRef.current.delete(oldRowKey)
            rateAuthApprovedRef.current.delete(oldRowKey)
          }
          const next = [...prev]
          next[rowIdx] = emptyRow()
          return next
        })
      }
    },
    [handleSubmit],
  )

  const handleCancel = useCallback(async () => {
    const hasDraftTransaction = rows.some(
      (r) => r.currencyCode || r.quantity || r.exchangeRate > 0 || r.hufValue > 0,
    )
    if (hasDraftTransaction) {
      if (!confirm('Biztosan elveti a tranzakciot?')) return
      try {
        const cd = customerDataRef.current
        const receipt = await receiptApi.createCancelledTransaction({
          mode: mode === 'buy' ? 'BUY' : 'SELL',
          reason: 'USER_CANCELLED',
          customerName: cd?.name || undefined,
          customerDocumentNumber: cd?.documentNumber || undefined,
          lines: rows
            .filter((r) => r.currencyCode || r.quantity || r.exchangeRate > 0 || r.hufValue > 0)
            .map((r) => ({
              currencyCode: r.currencyCode || undefined,
              foreignAmount: parseFloat(r.quantity) > 0 ? parseFloat(r.quantity) : undefined,
              rate: r.exchangeRate > 0 ? r.exchangeRate : undefined,
              hufAmount: r.hufValue > 0 ? r.hufValue : undefined,
            })),
        })
        toast.info('Megszakított bizonylat rögzítve', `Bizonylat: ${receipt.receiptNumber}`)
      } catch (error) {
        logger.warn(
          'CashierTransactionPage',
          'Cancelled transaction receipt could not be recorded',
          error,
        )
        toast.warning(
          'Megszakítás lokálisan elvetve',
          'A megszakított bizonylat szerveroldali rögzítése nem sikerült. Ellenőrizze a kapcsolatot.',
        )
      }
    }
    setRows(Array.from({ length: MAX_LINES }, emptyRow))
    setActiveRow(0)
    setActiveField('currency')
    setHandlingFee(0)
    setDiscount(0)
    setFeeOverrideType('')
    setFeeOverrideReason('')
    setCardNumber('')
    customerDataRef.current = null
    setComplianceCustomerId(null)
    amlResultRef.current = null
    incomeProofBase64Ref.current = null
    setShowIncomeProofModal(false)
    setIncomeProofRequired(false)
    // Codex P2 + Copilot P2 #579 follow-up: cancel-elt tranzakcio → ref-ek tisztítás
    // (abandoned rows NE számítsanak a local effectiveRemaining-be a kovetkezo
    // tranzakcio során).
    cashierCustomRateRowsRef.current.clear()
    rateAuthApprovedRef.current.clear()
  }, [mode, rows])

  // ====== FORMAT ======
  // FR-HL-15 (hibalista): a pénztári HUF-összegek KIJELZÉSE egész forintban, tizedes nélkül (HUF-nál
  // tizedes tiltott). Ez NEM az 5 Ft-os készpénz-kerekítés — azt a fizetendő végösszegre a HungarianRounding
  // végzi (lásd a `total` számítását fent); itt csak a megjelenítés kerekül egész Ft-ra (Math.round).
  // A formatNum minden használata HUF-érték (hufValue/subtotal/handlingFee/discountAmount/total).
  const formatNum = (n: number) =>
    Math.round(n).toLocaleString('hu-HU', { maximumFractionDigits: 0 })

  // ====== RENDER ======
  return (
    <div className="space-y-2 pb-20">
      {/* pb-20: a HotkeyBar position:fixed footer (~64px) miatt a tartalom utolsó eleme
          (Bizonylat készítése gomb) ne kerüljön a sticky footer alá. Codex P2 #345. */}
      {/* SESSION GUARD WARNING */}
      {sessionOpen === false && (
        <div className="bg-red-50 dark:bg-red-950/30 border-2 border-red-500 rounded-lg p-2 flex items-center gap-2">
          <AlertTriangle className="w-5 h-5 text-red-600 dark:text-red-400 shrink-0" />
          <div>
            <p className="font-bold text-sm text-red-800 dark:text-red-200">
              {t('transactions.nincsNyitottNapiSession')}
            </p>
            <p className="text-xs text-red-700 dark:text-red-300">
              {t('transactions.aTranzakciokRogzitesehezEloszorMegKellNyitniANapot')}
            </p>
          </div>
        </div>
      )}

      {/* FEE/DISCOUNT DIALOG */}
      {showFeeDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-2xl p-4 w-96 space-y-4">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">
              {t('transactions.kezelesiDijKedvezmeny')}
            </h3>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                {t('transactions.kezelesiDijHuf')}
              </label>
              {/* Batch2-B (Fabulya-teszt 2026-06-12): ha van betöltött díj-konfig, a díjat a
                  program számolja (Kezelési költség beállítások) — a kézi mező ZÁRT, kivéve a
                  vezetői SPECIAL felülbírálást. Konfig nélkül (régi backend / hálózati hiba)
                  marad a kézi bevitel, hogy a pénztár ne ragadjon be. */}
              <input
                type="number"
                value={feeInputLocked ? String(handlingFee || 0) : feeInput}
                disabled={feeInputLocked}
                onChange={(e) => setFeeInput(e.target.value)}
                className="w-full h-11 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white font-mono text-lg disabled:bg-gray-100 dark:disabled:bg-gray-700 disabled:text-gray-500 dark:disabled:text-gray-400"
                autoFocus={!feeInputLocked}
                min={0}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    void applyFeeDialog()
                  } else if (e.key === 'Escape') {
                    setFeeOverrideType('')
                    setFeeOverrideReason('')
                    setCardNumber('')
                    setShowFeeDialog(false)
                  }
                }}
              />
              {feeInputLocked && (
                <p className="text-xs text-gray-500 mt-1">
                  {t('transactions.kezelesiDijKonfigSzamolja', {
                    mode:
                      feeConfig?.feeType === 'BRACKET'
                        ? t('transactions.kezelesiDijModSavos')
                        : feeConfig?.feeType === 'PER_MILLE'
                          ? t('transactions.kezelesiDijModEzrelekes')
                          : t('transactions.kezelesiDijModNincs'),
                  })}
                </p>
              )}
              {autoFeeDiscountLabel && (
                <p
                  className="mt-1 text-xs font-medium text-green-700"
                  data-testid="auto-fee-discount"
                >
                  Automatikus küszöbkedvezmény: {autoFeeDiscountLabel}
                </p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                {t('transactions.kedvezmeny')}
              </label>
              <input
                type="number"
                value={discountInput}
                onChange={(e) => setDiscountInput(e.target.value)}
                className="w-full h-11 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white font-mono text-lg"
                min={0}
                autoFocus={feeInputLocked}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    void applyFeeDialog()
                  } else if (e.key === 'Escape') {
                    setFeeOverrideType('')
                    setFeeOverrideReason('')
                    setCardNumber('')
                    setShowFeeDialog(false)
                  }
                }}
              />
              {discountApprovalLoading && (
                <p className="mt-1 text-xs text-gray-500">
                  Kedvezmény jóváhagyási szint ellenőrzése...
                </p>
              )}
              {discountApprovalInfo && (
                <div
                  className={`mt-2 rounded border p-2 text-xs ${
                    discountApprovalInfo.canApprove
                      ? 'border-green-200 bg-green-50 text-green-800'
                      : 'border-amber-200 bg-amber-50 text-amber-900'
                  }`}
                  data-testid="discount-approval-info"
                >
                  Szükséges szint: {discountApprovalInfo.requiredLevel ?? '-'}; dolgozói szint:{' '}
                  {discountApprovalInfo.workerLevel ?? '-'}.
                  {discountApprovalInfo.exceedsMaxCap && (
                    <span> Maximum: {discountApprovalInfo.maxAllowedPercent ?? '-'}%.</span>
                  )}
                  {!discountApprovalInfo.canApprove && !discountApprovalInfo.exceedsMaxCap && (
                    <span> Magasabb jóváhagyási szint szükséges.</span>
                  )}
                </div>
              )}
              {discountApprovalError && (
                <div
                  className="mt-2 rounded border border-red-200 bg-red-50 p-2 text-xs text-red-800"
                  data-testid="discount-approval-error"
                >
                  {discountApprovalError}
                </div>
              )}
            </div>
            {/* FK-KEZDÍJ (2026-06-02): kezelési díj módosítás (override) — engedély-mátrix. */}
            <div className="border-t border-gray-200 dark:border-gray-700 pt-3 space-y-2">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Kezelési díj módosítása
              </label>
              <select
                value={feeOverrideType}
                onChange={(e) => {
                  const v = e.target.value as typeof feeOverrideType
                  setFeeOverrideType(v)
                  if (!v) {
                    setFeeOverrideReason('')
                    setCardNumber('')
                  }
                }}
                className="w-full h-10 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white"
              >
                <option value="">Nincs módosítás</option>
                <option value="HALF">Felezés</option>
                <option value="WAIVED">Elengedés</option>
                {isDirectorUser && (
                  <option value="SPECIAL">Speciális (egyedi összeg — vezetői)</option>
                )}
              </select>
              {feeOverrideType && (
                <select
                  value={feeOverrideReason}
                  onChange={(e) => {
                    const r = e.target.value as typeof feeOverrideReason
                    setFeeOverrideReason(r)
                    if (r !== 'CUSTOMER_CARD') setCardNumber('')
                  }}
                  className="w-full h-10 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white"
                >
                  <option value="">Jogcím választása...</option>
                  {isDirectorUser && (
                    <option value="DIRECTOR_APPROVAL">Ügyvezetői / főértéktárosi jóváhagyás</option>
                  )}
                  {feeOverrideType !== 'SPECIAL' && (
                    <option value="CUSTOMER_CARD">Ügyfélkártya</option>
                  )}
                  {feeOverrideType !== 'SPECIAL' && <option value="PROMOTION">Akció</option>}
                </select>
              )}
              {feeOverrideType && feeOverrideReason === 'CUSTOMER_CARD' && (
                <input
                  type="text"
                  value={cardNumber}
                  placeholder="Ügyfélkártya száma..."
                  maxLength={100}
                  onChange={(e) => setCardNumber(e.target.value)}
                  className="w-full h-10 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white font-mono"
                />
              )}
              {feeOverrideType && feeOverrideType !== 'SPECIAL' && (
                <p className="text-xs text-gray-500">
                  A díjat a szerver számolja (felezés = fele, elengedés = 0). A fenti díj-mező csak
                  speciális (egyedi) díjnál érvényes.
                </p>
              )}
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => void applyFeeDialog()}
                className="flex-1 py-2.5 rounded-lg text-white font-semibold"
                style={{ backgroundColor: 'var(--primary)' }}
              >
                {t('transactions.alkalmaz')}
              </button>
              <button
                onClick={() => {
                  // FK-KEZDÍJ (2026-06-02): Mégse → az override-draft NEM marad érvényben (biztonságos:
                  // a nem véglegesített díj-módosítás eldobódik).
                  setFeeOverrideType('')
                  setFeeOverrideReason('')
                  setCardNumber('')
                  setShowFeeDialog(false)
                }}
                className="flex-1 py-2.5 rounded-lg border border-gray-300 dark:border-gray-600 font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
              >
                {t('transactions.megse')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* MODE BADGE */}
      <div className="flex items-center gap-3">
        <span
          className="text-sm font-bold text-white px-3 py-1 rounded shadow"
          style={{ backgroundColor: mode === 'buy' ? '#2E7D32' : '#1565C0' }}
        >
          {mode === 'buy' ? 'VÉTEL' : 'ELADÁS'}
        </span>
        <span className="text-xs text-gray-500 dark:text-gray-400">
          {t('transactions.max')}
          {MAX_LINES} {t('transactions.valutasorTabEnter')}
        </span>
      </div>

      <main>
        <div className="grid grid-cols-[1fr,300px] gap-2">
          {/* BAL: 6-SOROS TABLA */}
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="bg-gray-100 dark:bg-gray-700 text-xs font-semibold text-gray-700 dark:text-gray-300">
                  <th className="px-2 py-1.5 text-left w-28">VALUTA</th>
                  <th className="px-2 py-1.5 text-right w-28">{t('transactions.arfolyam')}</th>
                  <th className="px-2 py-1.5 text-right w-32">{t('transactions.bankjegyDb')}</th>
                  <th
                    className="px-2 py-1.5 text-center w-16"
                    title="Devizastátusz: K=külföldi, B=belföldi (bizonylaton megjelenik)"
                  >
                    DSZ
                  </th>
                  <th className="px-2 py-1.5 text-right">{t('transactions.forintErtek')}</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row, idx) => (
                  <tr
                    key={row.id}
                    className={`border-b border-gray-100 dark:border-gray-700 transition-colors ${
                      idx === activeRow
                        ? 'bg-blue-50 dark:bg-blue-950/30 border-l-4 border-l-blue-500'
                        : ''
                    }`}
                  >
                    <td className="px-2 py-1">
                      <CurrencyAutocomplete
                        rates={exchangeRates}
                        value={row.currencyCode}
                        onChange={(code, rate) => handleCurrencySelect(idx, code, rate)}
                        onConfirm={() => handleCurrencyConfirm(idx)}
                        onKeyDown={(e) => handleKeyDown(e, idx, 'currency')}
                        onFocus={() => {
                          setActiveRow(idx)
                          setActiveField('currency')
                        }}
                        inputRef={(el) => {
                          currencyRefs.current[idx] = el
                        }}
                        placeholder="EUR, Euró..."
                        data-testid={`currency-input-${idx}`}
                      />
                    </td>
                    <td className="px-2 py-1 text-right">
                      <RateInput
                        ref={(el) => {
                          rateRefs.current[idx] = el
                        }}
                        rate={row.exchangeRate}
                        onChange={(val) => handleRateInput(idx, val)}
                        onKeyDown={(e) => handleKeyDown(e, idx, 'rate')}
                        onFocus={() => {
                          setActiveRow(idx)
                          setActiveField('rate')
                        }}
                        onRateBlur={() => validateRateOnBlur(idx)}
                        disabled={!row.currencyCode}
                      />
                    </td>
                    <td className="px-2 py-1 text-right">
                      <input
                        ref={(el) => {
                          quantityRefs.current[idx] = el
                        }}
                        value={row.quantity}
                        onChange={(e) => handleQuantityInput(idx, e.target.value)}
                        onKeyDown={(e) => handleKeyDown(e, idx, 'quantity')}
                        onFocus={() => {
                          setActiveRow(idx)
                          setActiveField('quantity')
                        }}
                        type="text"
                        inputMode="numeric"
                        className="w-24 h-8 text-right font-mono text-base font-semibold bg-transparent border-2 border-gray-300 dark:border-gray-600 rounded focus:ring-2 focus:border-transparent"
                        style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                        placeholder="0"
                        disabled={!row.currencyCode}
                      />
                    </td>
                    <td className="px-2 py-1 text-center">
                      <button
                        type="button"
                        onClick={() =>
                          setRows((prev) =>
                            prev.map((r, i) =>
                              i === idx
                                ? {
                                    ...r,
                                    foreignStatus:
                                      r.foreignStatus === 'FOREIGN' ? 'DOMESTIC' : 'FOREIGN',
                                  }
                                : r,
                            ),
                          )
                        }
                        disabled={!row.currencyCode}
                        className={`w-10 h-8 rounded font-mono font-bold text-sm border-2 transition-colors ${
                          row.foreignStatus === 'FOREIGN'
                            ? 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 border-blue-400 dark:border-blue-700'
                            : 'bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 border-green-400 dark:border-green-700'
                        } disabled:opacity-40 disabled:cursor-not-allowed`}
                        title={
                          row.foreignStatus === 'FOREIGN'
                            ? 'Külföldi (kattints: belföldire váltás)'
                            : 'Belföldi (kattints: külföldire váltás)'
                        }
                        data-testid={`foreign-status-toggle-${idx}`}
                      >
                        {row.foreignStatus === 'FOREIGN' ? 'K' : 'B'}
                      </button>
                    </td>
                    <td className="px-2 py-1 text-right">
                      <span className="text-lg font-mono font-bold text-gray-900 dark:text-white">
                        {row.hufValue ? formatNum(row.hufValue) : '-'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {/* SAVOS ARFOLYAM INFO */}
            {(() => {
              const activeRowData = rows[activeRow]
              if (!activeRowData?.currencyCode) return null
              const rateObj = exchangeRates.find(
                (r) => r.currencyCode === activeRowData.currencyCode,
              )
              if (!rateObj) return null
              const qtyNum = parseFloat(activeRowData.quantity) || 0
              const baseRate = mode === 'buy' ? rateObj.baseBuyRate : rateObj.baseSellRate
              const baseHuf = baseRate * qtyNum
              const band = getBandForAmount(rateObj, mode, baseHuf)
              const tiers: { name: string; rate: number; minHuf: number }[] = [
                {
                  name: 'Alap',
                  rate: mode === 'buy' ? rateObj.baseBuyRate : rateObj.baseSellRate,
                  minHuf: 0,
                },
              ]
              if (
                rateObj.limit1Amount != null &&
                (mode === 'buy' ? rateObj.limit1BuyRate : rateObj.limit1SellRate) != null
              ) {
                tiers.push({
                  name: 'Limit 1',
                  rate: (mode === 'buy' ? rateObj.limit1BuyRate : rateObj.limit1SellRate)!,
                  minHuf: rateObj.limit1Amount,
                })
              }
              if (
                rateObj.limit2Amount != null &&
                (mode === 'buy' ? rateObj.limit2BuyRate : rateObj.limit2SellRate) != null
              ) {
                tiers.push({
                  name: 'Limit 2',
                  rate: (mode === 'buy' ? rateObj.limit2BuyRate : rateObj.limit2SellRate)!,
                  minHuf: rateObj.limit2Amount,
                })
              }
              if (
                rateObj.limit3Amount != null &&
                (mode === 'buy' ? rateObj.limit3BuyRate : rateObj.limit3SellRate) != null
              ) {
                tiers.push({
                  name: 'Limit 3',
                  rate: (mode === 'buy' ? rateObj.limit3BuyRate : rateObj.limit3SellRate)!,
                  minHuf: rateObj.limit3Amount,
                })
              }
              return (
                <div className="bg-blue-50 dark:bg-blue-950/30 p-2 text-xs border-t border-blue-200 dark:border-blue-800">
                  <div className="flex items-center gap-4 flex-wrap">
                    <span className="font-semibold text-blue-700 dark:text-blue-300">
                      {activeRowData.currencyCode} sávok:
                    </span>
                    {/* FK-SAVOS B.2 (2026-06-12, user-kérés): a sáv-badge-ek KATTINTHATÓK — a
                        kiválasztott sáv árfolyama a sorra kerül. Csak az összeg-küszöböt elérő
                        sáv aktív (a küszöb alatti sáv kézi választása marzs-vesztés lenne —
                        ahhoz a sorban kézi árfolyam írható, a pénztárosi kvóta terhére). */}
                    {tiers.map((tier) => {
                      const isCurrent =
                        band.tierName === tier.name.toLowerCase().replace(' ', '') ||
                        (tier.name === 'Alap' && band.tierName === 'alap')
                      const reachable = baseHuf >= tier.minHuf
                      return (
                        // Copilot PR #1103: a title a NEM-disabled wrapper span-en — disabled
                        // gombon a böngészők többsége nem mutat tooltipet, pedig pont az
                        // inaktív sávnál kell a „miért nem választható" magyarázat.
                        <span
                          key={tier.name}
                          title={
                            reachable
                              ? `Sáv alkalmazása: ${tier.rate.toFixed(2)}`
                              : `A sávhoz legalább ${(tier.minHuf / 1000).toFixed(0)}k Ft összeg kell`
                          }
                        >
                          <button
                            type="button"
                            disabled={!reachable}
                            onClick={() => handleRateInput(activeRow, String(tier.rate))}
                            className={`px-1.5 py-0.5 rounded ${
                              isCurrent
                                ? 'bg-blue-600 text-white font-bold'
                                : 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200'
                            } ${reachable ? 'cursor-pointer hover:ring-1 hover:ring-blue-500' : 'opacity-50 cursor-not-allowed'}`}
                          >
                            {tier.name}: {tier.rate.toFixed(2)}{' '}
                            {tier.minHuf > 0 ? `(${(tier.minHuf / 1000).toFixed(0)}k+)` : ''}
                          </button>
                        </span>
                      )
                    })}
                    {/* Batch2-C (Fabulya-teszt 2026-06-12): ha csak az Alap sáv létezik, az nem
                        programhiba, hanem adat-állapot — a publikált rátában nincsenek kitöltve
                        a limit1-3 sávok. Explicit hint, hogy a pénztáros tudja, hol pótolható. */}
                    {tiers.length === 1 && (
                      <span className="text-gray-500 dark:text-gray-400 italic">
                        {t('transactions.nincsPublikaltLimitSav')}
                      </span>
                    )}
                    {cashierRateQuota && cashierRateQuota.remaining > 0 && (
                      <span className="px-1.5 py-0.5 rounded bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200">
                        Pénztárosi sáv: {cashierRateQuota.remaining}/{cashierRateQuota.limit} (
                        {(cashierRateQuota.minAmountHuf / 1000).toFixed(0)}k+ Ft)
                      </span>
                    )}
                    {cashierRateQuota && cashierRateQuota.remaining <= 0 && (
                      <span className="px-1.5 py-0.5 rounded bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200">
                        Pénztárosi sáv: elfogyott ({cashierRateQuota.used}/{cashierRateQuota.limit})
                      </span>
                    )}
                  </div>
                </div>
              )
            })()}

            {/* OSSZEGZO */}
            <div className="bg-gray-50 dark:bg-gray-800/80 p-2 space-y-1 border-t border-gray-200 dark:border-gray-700">
              <div className="flex justify-between text-sm">
                <span className="text-gray-600 dark:text-gray-400">
                  {t('transactions.osszesen')}
                </span>
                <span className="font-mono font-semibold">{formatNum(subtotal)} HUF</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-600 dark:text-gray-400">
                  {t('transactions.kezelesiDij')}
                </span>
                <span className="font-mono font-semibold">{formatNum(handlingFee)} HUF</span>
              </div>
              {autoFeeDiscountLabel && (
                <div className="flex justify-between gap-3 text-xs text-green-700">
                  <span>Automatikus díjkedvezmény</span>
                  <span className="text-right">{autoFeeDiscountLabel}</span>
                </div>
              )}
              {discount > 0 && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-400">
                    {t('transactions.kedvezmeny2')}
                    {discount}%):
                  </span>
                  <span className="font-mono font-semibold text-green-600">
                    -{formatNum(discountAmount)} HUF
                  </span>
                </div>
              )}
              <hr className="border-gray-300 dark:border-gray-600 my-1" />
              <div className="flex justify-between items-center">
                <span className="text-base font-bold">{t('transactions.fizetendo')}</span>
                <span
                  className="text-2xl font-mono font-black text-white px-3 py-1 rounded shadow"
                  style={{ backgroundColor: 'var(--primary)' }}
                >
                  {formatNum(total)} HUF
                </span>
              </div>
            </div>
          </div>

          {/* JOBB: UGYFEL PANEL */}
          <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-3 space-y-2">
            <CustomerPanel
              identificationLevel={identificationLevel}
              minimumLevel={minimumLevel}
              onLevelChange={setIdentificationLevel}
              requiresSourceVerification={requiresSourceVerification}
              hufTotal={total}
              onCustomerReady={(data) => {
                customerDataRef.current = data
                setComplianceCustomerId(data?.id ?? null)
              }}
              onAmlResult={(result) => {
                amlResultRef.current = result
              }}
            />

            {/* FS-10 S3: center-ben rögzített compliance-kérdések — nem blokkoló,
                a válasz az ügyfélhez kötve rögzül (transactionId nélkül). */}
            {complianceCustomerId != null && (
              <ComplianceQuestionsBlock
                key={complianceCustomerId}
                customerId={complianceCustomerId}
              />
            )}

            {/* Veglegestes gomb */}
            <button
              onClick={handleSubmit}
              disabled={
                isSubmitting ||
                !rows.some((r) => r.currencyCode.length > 0) ||
                (amlResultRef.current?.blocked ?? false)
              }
              className="w-full py-2 rounded-lg text-white font-bold text-base shadow transition-all disabled:opacity-50 disabled:cursor-not-allowed hover:opacity-90"
              data-action="save"
              style={{ backgroundColor: 'var(--primary)' }}
            >
              {isSubmitting ? 'MENTÉS...' : 'BIZONYLAT KÉSZÍTÉSE'}
            </button>
          </div>
        </div>
      </main>

      {/* RATE AUTH DIALOG */}
      <RateAuthDialog
        isOpen={showRateAuth}
        onSuccess={() => {
          const row = rows[rateAuthRow]
          if (row) {
            rateAuthApprovedRef.current.add(`${rateAuthRow}-${row.currencyCode}`)
          }
          setShowRateAuth(false)
        }}
        onCancel={() => {
          setShowRateAuth(false)
          const row = rows[rateAuthRow]
          if (row) {
            const rateObj = exchangeRates.find((r) => r.currencyCode === row.currencyCode)
            if (rateObj) {
              const qtyNum = parseFloat(row.quantity) || 0
              const baseRate = mode === 'buy' ? rateObj.baseBuyRate : rateObj.baseSellRate
              const baseAmountHuf = baseRate * qtyNum
              const band = getBandForAmount(rateObj, mode, baseAmountHuf)
              setRows((prev) => {
                const next = [...prev]
                next[rateAuthRow] = {
                  ...next[rateAuthRow]!,
                  exchangeRate: band.tierRate,
                  hufValue: roundHuf(band.tierRate * qtyNum),
                }
                return next
              })
            }
          }
        }}
        customRate={rateAuthPendingRate}
        currencyCode={rows[rateAuthRow]?.currencyCode || ''}
        mode={mode}
      />

      {showIncomeProofModal && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
          data-testid="income-proof-capture-modal"
        >
          <div className="w-full max-w-2xl rounded-xl bg-white p-4 shadow-2xl dark:bg-gray-800">
            <h3 className="mb-2 text-lg font-bold text-gray-900 dark:text-white">
              {t('incomeProof.cim')}
            </h3>
            {incomeProofRequired && (
              <p className="mb-3 text-sm text-red-700 dark:text-red-300">
                {t('incomeProof.kotelezo')}
              </p>
            )}
            <IncomeSourceDocCapture
              onCaptured={(base64) => {
                incomeProofBase64Ref.current = base64
                setShowIncomeProofModal(false)
                setIncomeProofRequired(false)
                void handleSubmit()
              }}
              onClear={() => {
                incomeProofBase64Ref.current = null
              }}
            />
            <div className="mt-3 flex justify-end">
              <button
                type="button"
                className="form-button"
                onClick={() => {
                  setShowIncomeProofModal(false)
                  setIncomeProofRequired(false)
                  incomeProofBase64Ref.current = null
                }}
              >
                {t('incomeProof.megsem')}
              </button>
            </div>
          </div>
        </div>
      )}

      {showIncomeProofSendModal && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
          data-testid="income-proof-send-modal"
        >
          <div className="w-full max-w-md rounded-xl bg-white p-4 shadow-2xl dark:bg-gray-800">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">
              {t('incomeProof.kuldes')}
            </h3>
            <p className="mt-2 text-sm text-gray-600 dark:text-gray-300">
              {t('incomeProof.nemTarolodik')}
            </p>
            {incomeProofSending && (
              <p className="mt-3 text-sm text-gray-700 dark:text-gray-200">
                {t('incomeProof.kuldes')}
              </p>
            )}
            {incomeProofSendError && (
              <div className="mt-3 space-y-3">
                <p className="rounded border border-red-200 bg-red-50 p-2 text-sm text-red-700">
                  {t('incomeProof.kuldesHiba')} {incomeProofSendError}
                </p>
                <div className="flex justify-end gap-2">
                  <button
                    type="button"
                    className="form-button"
                    onClick={() => {
                      void cancelIncomeProofEmail()
                    }}
                  >
                    {t('incomeProof.megsem')}
                  </button>
                  <button
                    type="button"
                    className="form-button-primary"
                    disabled={!incomeProofPendingPayload || incomeProofSending}
                    onClick={() => {
                      if (incomeProofPendingPayload)
                        void sendIncomeProofEmail(incomeProofPendingPayload)
                    }}
                  >
                    {t('incomeProof.ujra')}
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* RECEIPT PREVIEW MODAL */}
      <ReceiptPreviewModal
        isOpen={showReceiptModal}
        onClose={() => {
          // Show next receipt in queue if any
          const next = receiptQueueRef.current.shift()
          if (next) {
            setReceiptData(next)
          } else {
            setShowReceiptModal(false)
            setReceiptData(null)
            // v2.3.47 (Sourcery #311 fallback wire-up): Ha NEM nyomtatott a flow soran,
            // toast.info diszkret close-toast (B19 audit elegseges feedback). Ha
            // nyomtatott, a v2.3.35 print-toast adta a feedback-et — NINCS extra toast.
            if (!printAttemptedRef.current) {
              toast.info('Tranzakció befejezve', 'A bizonylatot megtekintette nyomtatás nélkül.')
            }
            // v2.3.49 (Sourcery #312 P3): defensive reset — a primary reset
            // a modal-OPEN-ben tortenik (linevel 429+490, set ON OPEN)
            printAttemptedRef.current = false
          }
        }}
        receiptData={receiptData}
        qrCodeDataUrl={null}
        allowPrint={isElectron()}
        onPrint={async () => {
          // v2.3.35 (B18 audit fix): Print silently fails -> explicit toast feedback
          // v2.3.47 (Sourcery #311): mark printAttempted -> close-toast NEM jon
          // Copilot PR #1100 (storno-minta): a hibás ágak THROW-val zárulnak — a
          // ReceiptPreviewModal csak SIKERES onPrint után zár be (2s auto-close),
          // hiba esetén nyitva marad és újrapróbálható.
          printAttemptedRef.current = true
          if (!receiptData) {
            toast.warning('Nyomtatás kihagyva', 'Nincs aktív bizonylat-adat.')
            throw new Error('Nincs aktív bizonylat-adat')
          }
          if (!window.electronAPI?.printReceipt) {
            // v2.3.37 (Sourcery #300 P2): a webes mod ES Electron preload-bug eseten
            // is ide kerul. Differencialjunk az isElectron() segedfuggvennyel.
            const inElectron = isElectron()
            toast.warning(
              'Nyomtatás nem elérhető',
              inElectron
                ? 'Electron preload/electronAPI wiring sikertelen — indítsa újra a klienst, ha tartós, frissítse a programot.'
                : 'Webes módban nincs nyomtatás. Telepítse az Electron klienst.',
            )
            throw new Error('printReceipt nem elérhető')
          }
          try {
            const success = await window.electronAPI.printReceipt(JSON.stringify(receiptData))
            if (!success) {
              toast.error(
                'Nyomtatás sikertelen',
                'A nyomtató offline / nincs konfigurálva / papír kifogyott. ' +
                  'Beállítások > Nyomtatás → ellenőrizze a soros port + nyomtató nevet.',
              )
              throw new Error('Nyomtatás sikertelen')
            }
            toast.success('Nyomtatás elindítva', `Bizonylat: ${receiptData.receiptNumber ?? '—'}`)
          } catch (err) {
            if (!(err instanceof Error && err.message === 'Nyomtatás sikertelen')) {
              const msg = err instanceof Error ? err.message : 'Ismeretlen hiba'
              toast.error('Nyomtatás váratlan hiba', msg)
            }
            throw err
          }
        }}
        printLabel={isElectron() ? undefined : 'Nyomtatás nem elérhető'}
      />

      {/* AML felsovezetoi jovahagyas modal — a pre-check trigger nyitja, ha approval kell */}
      <AmlApproverModal
        open={showAmlApprover}
        currentWorkerId={worker?.id ?? 0}
        reason={amlApprovalReason}
        sessionId={approvalSessionIdRef.current ?? ''}
        customerName={customerDataRef.current?.name ?? undefined}
        /* EXCMD b3 FR-AUTH-01..05: engedélykérő adatlap — pénztár + összeg + soros bontás + ügyfél */
        details={{
          branchCode: worker?.branchCode ?? undefined,
          branchName: worker?.branchName ?? undefined,
          totalHuf: total,
          lines: rows
            .filter((r) => r.currencyCode && r.hufValue > 0)
            .map((r) => ({
              currencyCode: r.currencyCode,
              // Copilot review (#1089): a quantity magyar formátumú string (szóköz, vessző)
              amount: parseFloat(r.quantity.replace(',', '.').replace(/\s/g, '')) || 0,
              rate: r.exchangeRate,
              hufValue: r.hufValue,
            })),
          customer: toApprovalCustomer(customerDataRef.current),
        }}
        onApproved={(workerId, name) => {
          approverWorkerIdRef.current = workerId
          setShowAmlApprover(false)
          toast.info('AML jóváhagyás megerősítve', `Engedélyező: ${name}`)
          // Ujrahivjuk a submitet — most az approverWorkerIdRef be van allitva, igy a pre-check
          // atugorja a modalt es a tranzakcio rogzul az approverWorkerId-val.
          void handleSubmit()
        }}
        onCancel={() => setShowAmlApprover(false)}
      />

      {/* EXCMD b9-korlevelek FR-03: gyanú-bejelentés (SAR) modal */}
      <SuspicionReportModal
        open={showSuspicionModal}
        customerName={customerDataRef.current?.name ?? undefined}
        hufAmount={total}
        onClose={() => setShowSuspicionModal(false)}
        onReported={() => {
          setShowSuspicionModal(false)
          toast.warning(
            'Gyanú-bejelentés rögzítve',
            'A vezetők értesítést kaptak. A tranzakciót NE rögzítse — egyeztessen telefonon a területi vezetővel.',
          )
        }}
      />

      {/* HOTKEY BAR */}
      <HotkeyBar
        left={[
          // v2.3.40 B13: F1/F2 align Főmenü-höz (F1=Vétel, F2=Eladás)
          { key: 'F1', label: 'Vétel', onClick: () => setMode('buy'), active: mode === 'buy' },
          { key: 'F2', label: 'Eladás', onClick: () => setMode('sell'), active: mode === 'sell' },
          {
            key: 'F5',
            label: 'Sztornó',
            onClick: () => navigate('/transactions?action=storno'),
            variant: 'danger',
          },
          { key: 'F8', label: 'Árfolyam', onClick: () => navigate('/rates') },
          {
            key: 'F9',
            label: 'Díj/Kedv.',
            onClick: () => {
              setFeeInput(String(handlingFee || ''))
              setDiscountInput(String(discount || ''))
              setShowFeeDialog(true)
            },
          },
          // EXCMD b9-korlevelek FR-03: gyanú-bejelentés (a folyamat felfüggesztése + SAR)
          {
            key: 'F10',
            label: 'Gyanú',
            onClick: () => setShowSuspicionModal(true),
            variant: 'danger',
          },
        ]}
        right={[
          {
            key: 'Esc',
            label: 'Mégse',
            onClick: () => {
              void handleCancel()
            },
            variant: 'secondary',
          },
        ]}
      />
    </div>
  )
}
