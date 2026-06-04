import { useState, useEffect, useRef, useCallback, forwardRef } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useHotkeys } from 'react-hotkeys-hook'
import { useFKeyHotkey } from '../../hooks/useFKeyHotkey'
import { AlertTriangle } from 'lucide-react'
import { HotkeyBar } from '../../components/cashier/HotkeyBar'
import { useCompanyTheme } from '../../contexts/CompanyThemeContext'
import { transactionApi, exchangeRateApi, dailySessionApi, cashBalanceApi } from '../../services/api/index'
import { api } from '../../services/api/client'
import AmlApproverModal from '../../components/auth/AmlApproverModal'
import type { BuyRequest, SellRequest, ExchangeRate, CashierCustomRateQuota } from '../../services/api/index'
import { roundHuf } from '../../utils/rounding'
import { toast } from '../../components/ui/toaster'
import {
  getElectronCachedRates,
  isElectronQueueAvailable,
  mapCachedRatesToExchangeRates,
  recordLocalAuditEvent,
  saveAndSyncPendingBuySell,
} from '../../utils/electronTransactions'
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
import { getBandForAmount, isWithinBand, isWithinHardLimit, getHardLimitMessage } from '../../utils/rateBands'
import RateAuthDialog from './components/RateAuthDialog'

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

const emptyRow = (): TransactionRow => ({
  id: `row-${++_rowIdSeq}`,
  currencyCode: '',
  currencyName: '',
  exchangeRate: 0,
  quantity: '',
  hufValue: 0,
  foreignStatus: 'FOREIGN',  // Default: kulfoldi (penzvalto-bran a leggyakoribb)
})

const RateInput = forwardRef<HTMLInputElement, {
  rate: number
  onChange: (val: string) => void
  onKeyDown: (e: React.KeyboardEvent) => void
  onFocus: () => void
  onRateBlur?: () => void
  disabled: boolean
}>(({ rate, onChange, onKeyDown, onFocus, onRateBlur, disabled }, ref) => {
  const [editing, setEditing] = useState(false)
  const [text, setText] = useState('')

  const display = rate ? rate.toFixed(2) : ''

  return (
    <input
      ref={ref}
      value={editing ? text : display}
      onChange={(e) => { setText(e.target.value); onChange(e.target.value) }}
      onKeyDown={onKeyDown}
      onFocus={(e) => {
        setEditing(true)
        setText(display)
        onFocus()
        e.target.select()
      }}
      onBlur={() => { setEditing(false); onRateBlur?.() }}
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
  const [rows, setRows] = useState<TransactionRow[]>(
    Array.from({ length: MAX_LINES }, emptyRow)
  )
  const [activeRow, setActiveRow] = useState(0)
  const [activeField, setActiveField] = useState<'currency' | 'rate' | 'quantity'>('currency')

  // Customer state (managed by CustomerPanel)
  const customerDataRef = useRef<CustomerPanelData | null>(null)
  const amlResultRef = useRef<AmlCheckResultDto | null>(null)

  // Fees
  const [handlingFee, setHandlingFee] = useState(0)
  const [discount, setDiscount] = useState(0)
  const [showFeeDialog, setShowFeeDialog] = useState(false)
  const [feeInput, setFeeInput] = useState('')
  const [discountInput, setDiscountInput] = useState('')
  // FK-KEZDÍJ (2026-06-02): kezelési díj módosítás (override). A szerver validálja az engedély-
  // mátrixot; itt csak a kliens-választás (típus/jogcím/kártyaszám) — HALF/WAIVED-nél a szerver
  // számolja a végösszeget, SPECIAL-nál a feeInput az egyedi díj.
  const [feeOverrideType, setFeeOverrideType] = useState<'' | 'HALF' | 'WAIVED' | 'SPECIAL'>('')
  const [feeOverrideReason, setFeeOverrideReason] = useState<'' | 'DIRECTOR_APPROVAL' | 'CUSTOMER_CARD' | 'PROMOTION'>('')
  const [cardNumber, setCardNumber] = useState('')

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
  // Codex P1: a jovahagyando nyugta TENYLEGES sorszama → ennyi felhasznalasu grantot ker a modal a
  // verify-approver-tol. A penztar-client a multi-line nyugtat N fuggetlen tranzakciokent synkronizalja
  // ugyanazzal a session-nel, mind megutheti az AML-kaput → N grant-felhasznalas kell (kulonben az elso
  // sor elhasznalja az egyetlen grantot, a tobbi "kimerult"-tel elhasal). A pre-check trigger allitja be.
  const amlGrantUsesRef = useRef(1)
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
  const worker = useAuthStore(s => s.worker)
  // FK-KEZDÍJ (2026-06-02): a bejelentkezett dolgozó ügyvezető/főértéktáros-e — csak ekkor látszik
  // a SPECIAL (egyedi díj) + a "vezetői jóváhagyás" jogcím (a szerver amúgy is validál, ez UX-gate).
  const isDirectorUser = useAuthStore(s => s.hasCanonicalRole)(['ugyvezeto', 'foertektar', 'admin'])

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
  const discountAmount = discount > 0 ? roundHuf(subtotal * discount / 100) : 0
  const total = roundHuf(subtotal + handlingFee - discountAmount)

  // Identification level based on HUF total
  const { identificationLevel, minimumLevel, setIdentificationLevel, requiresSourceVerification } = useIdentificationLevel(String(total))

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
    return () => { cancelled = true }
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
          toast.error('Árfolyam nem elérhető', 'Nincs használható helyi vagy szerver oldali árfolyam adat.')
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
    return () => { cancelled = true }
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
  useHotkeys('escape', () => handleCancel(), { enableOnFormTags: true })

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
    [mode]
  )

  const handleCurrencyConfirm = useCallback(
    (rowIdx: number) => {
      setActiveRow(rowIdx)
      setActiveField('rate')
    },
    []
  )

  const handleRateInput = useCallback(
    (rowIdx: number, value: string) => {
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
    },
    []
  )

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
        toast.error('Árfolyam meghaladja a hard limitet', getHardLimitMessage(mode, rateObj.officialRate!))
        const band = getBandForAmount(rateObj, mode, baseAmountHuf)
        setRows((prev) => {
          const next = [...prev]
          next[rowIdx] = { ...next[rowIdx]!, exchangeRate: band.tierRate, hufValue: roundHuf(band.tierRate * qtyNum) }
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
        const trackedRateObj = exchangeRates.find(r => r.currencyCode === trackedCurrency)
        const trackedQty = Number.parseFloat(trackedRow.quantity.replace(/[\s,]/g, '.')) || 0
        if (trackedRateObj) {
          const trackedBaseRate = mode === 'buy' ? trackedRateObj.baseBuyRate : trackedRateObj.baseSellRate
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
          const totalUsedAfterThis = cashierRateQuota!.limit - baseRemaining + cashierCustomRateRowsRef.current.size
          toast.success(
            'Pénztárosi sáv',
            `Egyedi árfolyam engedélyezve (${totalUsedAfterThis}/${cashierRateQuota!.limit} ma)`,
          )
          return
        }

        if (hufAmount >= minAmount && effectiveRemaining <= 0) {
          toast.warning('Pénztárosi sáv limit', `Napi ${cashierRateQuota?.limit ?? 5} egyedi árfolyam felhasználva!`)
        }

        setRateAuthRow(rowIdx)
        setRateAuthPendingRate(row.exchangeRate)
        setShowRateAuth(true)
      }
    },
    [rows, exchangeRates, mode, cashierRateQuota]
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
    [exchangeRates, mode]
  )

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
      toast.warning('Arfolyam regi', 'Az arfolyamok tobb mint 5 perce toltodtek be. Frissitsd az oldalt az aktualis arfolyamokhoz!')
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
            const bal = balances.find(b => b.currencyCode === row.currencyCode)
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
          const totalHufPayable = roundHuf(Math.max(0, grossHuf - (handlingFee > 0 ? handlingFee : 0)))
          const hufBal = balances.find(b => b.currencyCode === 'HUF')
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
        toast.error('Keszletellenorzes sikertelen', 'A keszlet nem ellenorizheto. Probald ujra kesobb.')
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
        toast.warning('Ügyfél azonosítás kötelező', `${SIMPLIFIED_IDENTIFICATION_LIMIT.toLocaleString('hu-HU')} Ft feletti tranzakcióhoz ügyfél azonosítás KÖTELEZŐ!`)
        return
      }
      if (identificationLevel === 'SIMPLIFIED' && (!cd?.birthPlace || !cd?.birthDate)) {
        toast.warning('Egyszerűsített azonosítás hiányos', '100.000 Ft felett születési hely és születési idő is KÖTELEZŐ!')
        return
      }
      if (identificationLevel === 'FULL' && (!cd?.documentNumber?.trim() || !cd?.birthPlace || !cd?.birthDate || !cd?.motherName || !cd?.address)) {
        toast.warning('Teljes azonosítás kötelező', '300.000 Ft felett teljes ügyféladatsor szükséges (okmányszám, születési hely/idő, anyja neve, lakcím)!')
        return
      }
    }
    if (aml?.blocked) {
      toast.error('Tranzakcio blokkolt', 'AML szabalysertes — a tranzakcio nem rogzitheto!')
      return
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
          // Uj jovahagyas-session a nyugtahoz (a grantot ehhez koti a backend).
          approvalSessionIdRef.current = crypto.randomUUID()
          // A grant felhasznalasai = a nyugta tenyleges sorszama (minden sor onallo backend-tranzakcio,
          // mind UGYANEZT a session-t viszi); single-line → 1. Server-side [1, MAX_LINES]-re klampelt.
          amlGrantUsesRef.current = filledRows.length
          setAmlApprovalReason(typeof checkRes.data?.reason === 'string' ? checkRes.data.reason : '')
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
        toast.info('Tranzakció megszakítva', 'Várj amíg helyreáll a hálózat, vagy próbáld újra később.')
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
            reason: 'AML check failed (offline/server error), pénztáros explicit megerősítéssel folytatta',
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
        logger.error('CashierTransactionPage', 'AML degradalt audit log persist FAILED — tranzakcio blokkolva', auditErr)
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
      const customerData = cd ? {
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
        // AML felsovezetoi jovahagyas: a jovahagyo workerId a REST buy/sell request-be (spread).
        approverWorkerId: approverWorkerIdRef.current ?? undefined,
        approvalSessionId: approvalSessionIdRef.current ?? undefined,
      } : {}

      if (electronQueueAvailable) {
        // V235 (2026-05-19 HIBA #14 + #15 + #17 + #18): a teljes Pmt. customer-
        // snapshot atadasa az Electron pending-queue fele. A korabbi payload csak
        // 4 alapmezot kuldott (name, docNumber, address, foreignStatus), igy a
        // bizonylaton hianyzott a szul.hely / szul.ido / anyja neve / allampolgar-
        // sag / okmany tipus / "mas neveben" flag es az actor teljes azonositasa.
        const actorIdentity = cd?.actorIdentity ?? null
        const outcome = await saveAndSyncPendingBuySell(
          filledRows.map((row) => ({
            type: mode === 'buy' ? 'BUY' : 'SELL',
            currencyCode: row.currencyCode,
            foreignAmount: parseFloat(row.quantity) || 0,
            hufAmount: row.hufValue,
            roundedHufAmount: roundHuf(row.hufValue),
            rate: row.exchangeRate,
            handlingFee: handlingFee > 0 ? handlingFee : null,
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
            // AML 50M (Pmt./MNB 14/2025): strukturált forrás-dokumentum
            sourceOfFundsDocType: cd?.sourceOfFundsDocType ?? null,
            sourceOfFundsDocDate: cd?.sourceOfFundsDocDate ?? null,
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
          })),
        )

        if (outcome.allSavedSynced) {
          toast.success('Bizonylat(ok) sikeresen rögzítve!', `${filledRows.length} tétel azonnal szinkronizálva.`)
        } else {
          toast.warning(
            'Offline mentés megtörtént',
            `${outcome.pendingCount} tétel helyi queue-ba került, ${outcome.syncedCount} tétel azonnal feltöltve.`,
          )
        }

        // Build receipt queue for all lines (Electron)
        if (isElectron()) {
          const now = new Date()
          const outcomeReceipts = (outcome as { receiptNumbers?: string[] }).receiptNumbers ?? []
          const receipts: PrintReceiptData[] = filledRows.map((row, idx) => ({
            type: mode === 'buy' ? 'buy' as const : 'sell' as const,
            companyType: ((worker?.companyCode ?? '').startsWith('EXP') ? 'EXPRESSZ' : 'BEST_CHANGE') as 'BEST_CHANGE' | 'EXPRESSZ',
            receiptNumber: outcomeReceipts[idx] ?? `P-${now.getTime()}-${idx}`,
            branchCode: worker?.branchCode ?? '',
            cashierName: worker?.fullName ?? '',
            date: now.toLocaleDateString('hu-HU'),
            time: now.toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit' }),
            currencyCode: row.currencyCode,
            foreignAmount: parseFloat(row.quantity) || 0,
            rate: row.exchangeRate,
            hufAmount: row.hufValue,
            roundedHufAmount: roundHuf(row.hufValue),
            roundingDiff: roundHuf(row.hufValue) - row.hufValue,
            customerName: cd?.name || undefined,
            customerDocNumber: cd?.documentNumber || undefined,
            customerAddress: cd?.address || undefined,
            vatExemptionText: 'Tárgyi adómentes az ÁFA tv. 86.§ (1) bek. k) pontja alapján.',
          }))
          receiptQueueRef.current = receipts.slice(1)
          if (receipts[0]) {
            openReceiptModal(receipts[0])
          }
        }
      } else {
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

        toast.success('Bizonylat(ok) sikeresen készítve!', `${filledRows.length} tétel, ${total.toLocaleString('hu-HU')} Ft | Bizonylat számok: ${receiptNumbers.join(', ')}`)

        // Build receipt queue for all lines (API path)
        if (filledRows.length > 0 && receiptNumbers.length > 0) {
          const now = new Date()
          const receipts: PrintReceiptData[] = filledRows.map((row, idx) => ({
            type: mode === 'buy' ? 'buy' as const : 'sell' as const,
            companyType: ((worker?.companyCode ?? '').startsWith('EXP') ? 'EXPRESSZ' : 'BEST_CHANGE') as 'BEST_CHANGE' | 'EXPRESSZ',
            receiptNumber: receiptNumbers[idx] ?? `API-${now.getTime()}-${idx}`,
            branchCode: worker?.branchCode ?? '',
            cashierName: worker?.fullName ?? '',
            date: now.toLocaleDateString('hu-HU'),
            time: now.toLocaleTimeString('hu-HU', { hour: '2-digit', minute: '2-digit' }),
            currencyCode: row.currencyCode,
            foreignAmount: parseFloat(row.quantity) || 0,
            rate: row.exchangeRate,
            hufAmount: row.hufValue,
            roundedHufAmount: roundHuf(row.hufValue),
            roundingDiff: roundHuf(row.hufValue) - row.hufValue,
            customerName: cd?.name || undefined,
            customerDocNumber: cd?.documentNumber || undefined,
            customerAddress: cd?.address || undefined,
            vatExemptionText: 'Tárgyi adómentes az ÁFA tv. 86.§ (1) bek. k) pontja alapján.',
          }))
          receiptQueueRef.current = receipts.slice(1)
          if (receipts[0]) {
            openReceiptModal(receipts[0])
          }
        }
      }

      // Reset
      setRows(Array.from({ length: MAX_LINES }, emptyRow))
      setActiveRow(0)
      setActiveField('currency')
      customerDataRef.current = null
      amlResultRef.current = null
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
      transactionApi.getCashierRateQuota()
        .then(quota => setCashierRateQuota(quota))
        .catch(e => logger.error('CashierTx', 'Quota refresh failed after submit (non-blocking)', e))
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
  }, [rows, mode, total, handlingFee, discount, identificationLevel, sessionOpen, electronQueueAvailable, worker?.branchCode, worker?.companyCode, worker?.fullName, openReceiptModal])

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
    [handleSubmit]
  )

  const handleCancel = useCallback(() => {
    if (rows.some((r) => r.currencyCode)) {
      if (!confirm('Biztosan elveti a tranzakciot?')) return
    }
    setRows(Array.from({ length: MAX_LINES }, emptyRow))
    setActiveRow(0)
    setActiveField('currency')
    // Codex P2 + Copilot P2 #579 follow-up: cancel-elt tranzakcio → ref-ek tisztítás
    // (abandoned rows NE számítsanak a local effectiveRemaining-be a kovetkezo
    // tranzakcio során).
    cashierCustomRateRowsRef.current.clear()
    rateAuthApprovedRef.current.clear()
  }, [rows])

  // ====== FORMAT ======
  // FR-HL-15 (hibalista): a pénztári HUF-összegek KIJELZÉSE egész forintban, tizedes nélkül (HUF-nál
  // tizedes tiltott). Ez NEM az 5 Ft-os készpénz-kerekítés — azt a fizetendő végösszegre a HungarianRounding
  // végzi (lásd a `total` számítását fent); itt csak a megjelenítés kerekül egész Ft-ra (Math.round).
  // A formatNum minden használata HUF-érték (hufValue/subtotal/handlingFee/discountAmount/total).
  const formatNum = (n: number) => Math.round(n).toLocaleString('hu-HU', { maximumFractionDigits: 0 })

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
            <p className="font-bold text-sm text-red-800 dark:text-red-200">{t('transactions.nincsNyitottNapiSession')}</p>
            <p className="text-xs text-red-700 dark:text-red-300">{t('transactions.aTranzakciokRogzitesehezEloszorMegKellNyitniANapot')}</p>
          </div>
        </div>
      )}

      {/* FEE/DISCOUNT DIALOG */}
      {showFeeDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-2xl p-4 w-96 space-y-4">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">{t('transactions.kezelesiDijKedvezmeny')}</h3>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('transactions.kezelesiDijHuf')}</label>
              <input
                type="number"
                value={feeInput}
                onChange={(e) => setFeeInput(e.target.value)}
                className="w-full h-11 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white font-mono text-lg"
                autoFocus
                min={0}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    setHandlingFee(Math.max(0, parseInt(feeInput) || 0))
                    setDiscount(Math.min(15, Math.max(0, parseFloat(discountInput) || 0)))
                    setShowFeeDialog(false)
                  } else if (e.key === 'Escape') {
                    setFeeOverrideType(''); setFeeOverrideReason(''); setCardNumber('')
                    setShowFeeDialog(false)
                  }
                }}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">{t('transactions.kedvezmeny')}</label>
              <input
                type="number"
                value={discountInput}
                onChange={(e) => setDiscountInput(e.target.value)}
                className="w-full h-11 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white font-mono text-lg"
                min={0}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    setHandlingFee(Math.max(0, parseInt(feeInput) || 0))
                    setDiscount(Math.min(15, Math.max(0, parseFloat(discountInput) || 0)))
                    setShowFeeDialog(false)
                  } else if (e.key === 'Escape') {
                    setFeeOverrideType(''); setFeeOverrideReason(''); setCardNumber('')
                    setShowFeeDialog(false)
                  }
                }}
              />
            </div>
            {/* FK-KEZDÍJ (2026-06-02): kezelési díj módosítás (override) — engedély-mátrix. */}
            <div className="border-t border-gray-200 dark:border-gray-700 pt-3 space-y-2">
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">Kezelési díj módosítása</label>
              <select
                value={feeOverrideType}
                onChange={(e) => {
                  const v = e.target.value as typeof feeOverrideType
                  setFeeOverrideType(v)
                  if (!v) { setFeeOverrideReason(''); setCardNumber('') }
                }}
                className="w-full h-10 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white"
              >
                <option value="">Nincs módosítás</option>
                <option value="HALF">Felezés</option>
                <option value="WAIVED">Elengedés</option>
                {isDirectorUser && <option value="SPECIAL">Speciális (egyedi összeg — vezetői)</option>}
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
                  {isDirectorUser && <option value="DIRECTOR_APPROVAL">Ügyvezetői / főértéktárosi jóváhagyás</option>}
                  {feeOverrideType !== 'SPECIAL' && <option value="CUSTOMER_CARD">Ügyfélkártya</option>}
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
                <p className="text-xs text-gray-500">A díjat a szerver számolja (felezés = fele, elengedés = 0). A fenti díj-mező csak speciális (egyedi) díjnál érvényes.</p>
              )}
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => {
                  setHandlingFee(Math.max(0, parseInt(feeInput) || 0))
                  setDiscount(Math.min(15, Math.max(0, parseFloat(discountInput) || 0)))
                  setShowFeeDialog(false)
                }}
                className="flex-1 py-2.5 rounded-lg text-white font-semibold"
                style={{ backgroundColor: 'var(--primary)' }}
              >
                {t('transactions.alkalmaz')}
              </button>
              <button
                onClick={() => {
                  // FK-KEZDÍJ (2026-06-02): Mégse → az override-draft NEM marad érvényben (biztonságos:
                  // a nem véglegesített díj-módosítás eldobódik).
                  setFeeOverrideType(''); setFeeOverrideReason(''); setCardNumber('')
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
          {t('transactions.max')}{MAX_LINES} {t('transactions.valutasorTabEnter')}
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
                  <th className="px-2 py-1.5 text-center w-16" title="Devizastátusz: K=külföldi, B=belföldi (bizonylaton megjelenik)">DSZ</th>
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
                        onFocus={() => { setActiveRow(idx); setActiveField('currency') }}
                        inputRef={(el) => { currencyRefs.current[idx] = el }}
                        placeholder="EUR, Euró..."
                        data-testid={`currency-input-${idx}`}
                      />
                    </td>
                    <td className="px-2 py-1 text-right">
                      <RateInput
                        ref={(el) => { rateRefs.current[idx] = el }}
                        rate={row.exchangeRate}
                        onChange={(val) => handleRateInput(idx, val)}
                        onKeyDown={(e) => handleKeyDown(e, idx, 'rate')}
                        onFocus={() => { setActiveRow(idx); setActiveField('rate') }}
                        onRateBlur={() => validateRateOnBlur(idx)}
                        disabled={!row.currencyCode}
                      />
                    </td>
                    <td className="px-2 py-1 text-right">
                      <input
                        ref={(el) => { quantityRefs.current[idx] = el }}
                        value={row.quantity}
                        onChange={(e) => handleQuantityInput(idx, e.target.value)}
                        onKeyDown={(e) => handleKeyDown(e, idx, 'quantity')}
                        onFocus={() => { setActiveRow(idx); setActiveField('quantity') }}
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
                        onClick={() => setRows(prev => prev.map((r, i) => i === idx ? { ...r, foreignStatus: r.foreignStatus === 'FOREIGN' ? 'DOMESTIC' : 'FOREIGN' } : r))}
                        disabled={!row.currencyCode}
                        className={`w-10 h-8 rounded font-mono font-bold text-sm border-2 transition-colors ${
                          row.foreignStatus === 'FOREIGN'
                            ? 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 border-blue-400 dark:border-blue-700'
                            : 'bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200 border-green-400 dark:border-green-700'
                        } disabled:opacity-40 disabled:cursor-not-allowed`}
                        title={row.foreignStatus === 'FOREIGN' ? 'Külföldi (kattints: belföldire váltás)' : 'Belföldi (kattints: külföldire váltás)'}
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
              const rateObj = exchangeRates.find((r) => r.currencyCode === activeRowData.currencyCode)
              if (!rateObj) return null
              const qtyNum = parseFloat(activeRowData.quantity) || 0
              const baseRate = mode === 'buy' ? rateObj.baseBuyRate : rateObj.baseSellRate
              const baseHuf = baseRate * qtyNum
              const band = getBandForAmount(rateObj, mode, baseHuf)
              const tiers: { name: string; rate: number; minHuf: number }[] = [
                { name: 'Alap', rate: mode === 'buy' ? rateObj.baseBuyRate : rateObj.baseSellRate, minHuf: 0 },
              ]
              if (rateObj.limit1Amount != null && (mode === 'buy' ? rateObj.limit1BuyRate : rateObj.limit1SellRate) != null) {
                tiers.push({ name: 'Limit 1', rate: (mode === 'buy' ? rateObj.limit1BuyRate : rateObj.limit1SellRate)!, minHuf: rateObj.limit1Amount })
              }
              if (rateObj.limit2Amount != null && (mode === 'buy' ? rateObj.limit2BuyRate : rateObj.limit2SellRate) != null) {
                tiers.push({ name: 'Limit 2', rate: (mode === 'buy' ? rateObj.limit2BuyRate : rateObj.limit2SellRate)!, minHuf: rateObj.limit2Amount })
              }
              if (rateObj.limit3Amount != null && (mode === 'buy' ? rateObj.limit3BuyRate : rateObj.limit3SellRate) != null) {
                tiers.push({ name: 'Limit 3', rate: (mode === 'buy' ? rateObj.limit3BuyRate : rateObj.limit3SellRate)!, minHuf: rateObj.limit3Amount })
              }
              return (
                <div className="bg-blue-50 dark:bg-blue-950/30 p-2 text-xs border-t border-blue-200 dark:border-blue-800">
                  <div className="flex items-center gap-4 flex-wrap">
                    <span className="font-semibold text-blue-700 dark:text-blue-300">{activeRowData.currencyCode} sávok:</span>
                    {tiers.map((tier) => (
                      <span key={tier.name} className={`px-1.5 py-0.5 rounded ${band.tierName === tier.name.toLowerCase().replace(' ', '') || (tier.name === 'Alap' && band.tierName === 'alap') ? 'bg-blue-600 text-white font-bold' : 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200'}`}>
                        {tier.name}: {tier.rate.toFixed(2)} {tier.minHuf > 0 ? `(${(tier.minHuf / 1000).toFixed(0)}k+)` : ''}
                      </span>
                    ))}
                    {cashierRateQuota && cashierRateQuota.remaining > 0 && (
                      <span className="px-1.5 py-0.5 rounded bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200">
                        Pénztárosi sáv: {cashierRateQuota.remaining}/{cashierRateQuota.limit} ({(cashierRateQuota.minAmountHuf / 1000).toFixed(0)}k+ Ft)
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
                <span className="text-gray-600 dark:text-gray-400">{t('transactions.osszesen')}</span>
                <span className="font-mono font-semibold">{formatNum(subtotal)} HUF</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-600 dark:text-gray-400">{t('transactions.kezelesiDij')}</span>
                <span className="font-mono font-semibold">{formatNum(handlingFee)} HUF</span>
              </div>
              {discount > 0 && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-400">{t('transactions.kedvezmeny2')}{discount}%):</span>
                  <span className="font-mono font-semibold text-green-600">-{formatNum(discountAmount)} HUF</span>
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
              onCustomerReady={(data) => { customerDataRef.current = data }}
              onAmlResult={(result) => { amlResultRef.current = result }}
            />

            {/* Veglegestes gomb */}
            <button
              onClick={handleSubmit}
              disabled={isSubmitting || !rows.some((r) => r.currencyCode.length > 0) || (amlResultRef.current?.blocked ?? false)}
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
                next[rateAuthRow] = { ...next[rateAuthRow]!, exchangeRate: band.tierRate, hufValue: roundHuf(band.tierRate * qtyNum) }
                return next
              })
            }
          }
        }}
        customRate={rateAuthPendingRate}
        currencyCode={rows[rateAuthRow]?.currencyCode || ''}
        mode={mode}
      />

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
          printAttemptedRef.current = true
          if (!receiptData) {
            toast.warning('Nyomtatás kihagyva', 'Nincs aktív bizonylat-adat.')
            return
          }
          if (!window.electronAPI?.printReceipt) {
            // v2.3.37 (Sourcery #300 P2): a webes mod ES Electron preload-bug eseten
            // is ide kerul. Differencialjunk az isElectron() segedfuggvennyel.
            const inElectron = isElectron()
            toast.warning(
              'Nyomtatás nem elérhető',
              inElectron
                ? 'Electron preload/electronAPI wiring sikertelen — indítsa újra a klienst, ha tartós, frissítse a programot.'
                : 'Webes módban nincs nyomtatás. Telepítse az Electron klienst.'
            )
            return
          }
          try {
            const success = await window.electronAPI.printReceipt(JSON.stringify(receiptData))
            if (success) {
              toast.success('Nyomtatás elindítva', `Bizonylat: ${receiptData.receiptNumber ?? '—'}`)
            } else {
              toast.error('Nyomtatás sikertelen',
                'A nyomtató offline / nincs konfigurálva / papír kifogyott. ' +
                'Beállítások > Nyomtatás → ellenőrizze a soros port + nyomtató nevet.')
            }
          } catch (err) {
            const msg = err instanceof Error ? err.message : 'Ismeretlen hiba'
            toast.error('Nyomtatás váratlan hiba', msg)
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
        grantUses={amlGrantUsesRef.current}
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

      {/* HOTKEY BAR */}
      <HotkeyBar
        left={[
          // v2.3.40 B13: F1/F2 align Főmenü-höz (F1=Vétel, F2=Eladás)
          { key: 'F1', label: 'Vétel', onClick: () => setMode('buy'), active: mode === 'buy' },
          { key: 'F2', label: 'Eladás', onClick: () => setMode('sell'), active: mode === 'sell' },
          { key: 'F5', label: 'Sztornó', onClick: () => navigate('/transactions?action=storno'), variant: 'danger' },
          { key: 'F8', label: 'Árfolyam', onClick: () => navigate('/rates') },
          { key: 'F9', label: 'Díj/Kedv.', onClick: () => { setFeeInput(String(handlingFee || '')); setDiscountInput(String(discount || '')); setShowFeeDialog(true) } },
        ]}
        right={[
          { key: 'Esc', label: 'Mégse', onClick: handleCancel, variant: 'secondary' },
        ]}
      />
    </div>
  )
}
