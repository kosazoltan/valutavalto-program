import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useHotkeys } from 'react-hotkeys-hook'
import { useFKeyHotkey } from '../../hooks/useFKeyHotkey'
import { AlertTriangle } from 'lucide-react'
import { HotkeyBar } from '../../components/cashier/HotkeyBar'
import { useCompanyTheme } from '../../contexts/CompanyThemeContext'
import { transactionApi, exchangeRateApi, dailySessionApi, cashBalanceApi } from '../../services/api/index'
import type { BuyRequest, SellRequest, ExchangeRate } from '../../services/api/index'
import { roundHuf } from '../../utils/rounding'
import { toast } from '../../components/ui/toaster'
import {
  getElectronCachedRates,
  isElectronQueueAvailable,
  mapCachedRatesToExchangeRates,
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
const IDENTIFICATION_LIMIT = 300_000
const RATE_STALE_MS = 5 * 60 * 1000 // 5 perc

let _rowIdSeq = 0

interface TransactionRow {
  id: string
  currencyCode: string
  currencyName: string
  exchangeRate: number
  quantity: string
  hufValue: number
}

const emptyRow = (): TransactionRow => ({
  id: `row-${++_rowIdSeq}`,
  currencyCode: '',
  currencyName: '',
  exchangeRate: 0,
  quantity: '',
  hufValue: 0,
})

export default function CashierTransactionPage() {
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
  const [activeField, setActiveField] = useState<'currency' | 'quantity'>('currency')

  // Customer state (managed by CustomerPanel)
  const customerDataRef = useRef<CustomerPanelData | null>(null)
  const amlResultRef = useRef<AmlCheckResultDto | null>(null)

  // Fees
  const [handlingFee, setHandlingFee] = useState(0)
  const [discount, setDiscount] = useState(0)
  const [showFeeDialog, setShowFeeDialog] = useState(false)
  const [feeInput, setFeeInput] = useState('')
  const [discountInput, setDiscountInput] = useState('')

  // Exchange rates from API
  const [exchangeRates, setExchangeRates] = useState<ExchangeRate[]>([])
  const ratesLoadedAtRef = useRef<number>(0)

  // Submission state
  const [isSubmitting, setIsSubmitting] = useState(false)

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

  // Refs for keyboard navigation
  const currencyRefs = useRef<(HTMLInputElement | null)[]>([])
  const quantityRefs = useRef<(HTMLInputElement | null)[]>([])

  // Calculated totals
  const subtotal = rows.reduce((sum, r) => sum + r.hufValue, 0)
  const discountAmount = discount > 0 ? Math.round(subtotal * discount / 100) : 0
  const total = subtotal + handlingFee - discountAmount

  // Identification level based on HUF total
  const { identificationLevel, requiresSourceVerification } = useIdentificationLevel(String(total))

  // Focus management
  useEffect(() => {
    if (activeField === 'currency') {
      currencyRefs.current[activeRow]?.focus()
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
        const appliedRate = mode === 'buy' ? rate.baseBuyRate : rate.baseSellRate
        setRows((prev) => {
          const next = [...prev]
          next[rowIdx] = {
            ...next[rowIdx]!,
            currencyCode: code,
            exchangeRate: appliedRate,
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
      setActiveField('quantity')
    },
    []
  )

  const handleQuantityInput = useCallback(
    (rowIdx: number, value: string) => {
      const qty = value.replace(/[^0-9.]/g, '')
      setRows((prev) => {
        const next = [...prev]
        const row = next[rowIdx]!
        const qtyNum = parseFloat(qty) || 0

        // Arfolyam szamitas: rate * mennyiseg = HUF ertek (magyar 5 Ft kerekites)
        const hufValue = roundHuf(row.exchangeRate * qtyNum)

        next[rowIdx] = { ...row, quantity: qty, hufValue }
        return next
      })
    },
    []
  )

  const handleSubmit = useCallback(async () => {
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
    if (mode === 'sell') {
      try {
        const balances = await cashBalanceApi.list()
        const insufficientRows: string[] = []
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
      if (!cd?.name?.trim() || !cd?.documentNumber?.trim()) {
        toast.warning('Ügyfél azonosítás kötelező', `${IDENTIFICATION_LIMIT.toLocaleString('hu-HU')} Ft feletti tranzakcióhoz ügyfél azonosítás KÖTELEZŐ!`)
        return
      }
      if (identificationLevel === 'FULL' && (!cd?.birthPlace || !cd?.birthDate || !cd?.motherName || !cd?.address)) {
        toast.warning('Teljes azonosítás kötelező', '300.000 Ft felett teljes ügyféladatsor szükséges (születési hely/idő, anyja neve, lakcím)!')
        return
      }
    }
    if (aml?.blocked) {
      toast.error('Tranzakcio blokkolt', 'AML szabalysertes — a tranzakcio nem rogzitheto!')
      return
    }

    setIsSubmitting(true)

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
      } : {}

      if (electronQueueAvailable) {
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

        for (const row of filledRows) {
          if (mode === 'buy') {
            const request: BuyRequest = {
              currencyCode: row.currencyCode,
              currencyAmount: parseFloat(row.quantity) || 0,
              customExchangeRate: row.exchangeRate,
              handlingFee: handlingFee > 0 ? handlingFee : undefined,
              discountPercent: discount > 0 ? discount : undefined,
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
              discountPercent: discount > 0 ? discount : undefined,
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
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Ismeretlen hiba'
      const axiosError = error as { response?: { data?: { message?: string } } }
      const serverMessage = axiosError?.response?.data?.message
      toast.error('Hiba a tranzakció mentés során!', serverMessage || message)
    } finally {
      setIsSubmitting(false)
    }
  }, [rows, mode, total, handlingFee, discount, identificationLevel, sessionOpen, electronQueueAvailable, worker?.branchCode, worker?.companyCode, worker?.fullName])

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent, rowIdx: number, field: 'currency' | 'quantity') => {
      if (e.key === 'Enter' || e.key === 'Tab') {
        e.preventDefault()
        if (field === 'currency') {
          // Currency autocomplete kezeli az Enter/Tab-ot — itt csak fallback
          setActiveField('quantity')
        } else if (field === 'quantity') {
          // Kovetkezo sor
          if (rowIdx < MAX_LINES - 1) {
            setActiveRow(rowIdx + 1)
            setActiveField('currency')
          } else {
            // Utolso sor utan: veglegestes
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
        // Sor torlese
        setRows((prev) => {
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
  }, [rows])

  // ====== FORMAT ======
  const formatNum = (n: number) => n.toLocaleString('hu-HU')

  // ====== RENDER ======
  return (
    <div className="space-y-2">
      {/* SESSION GUARD WARNING */}
      {sessionOpen === false && (
        <div className="bg-red-50 dark:bg-red-950/30 border-2 border-red-500 rounded-lg p-2 flex items-center gap-2">
          <AlertTriangle className="w-5 h-5 text-red-600 dark:text-red-400 shrink-0" />
          <div>
            <p className="font-bold text-sm text-red-800 dark:text-red-200">Nincs nyitott napi session!</p>
            <p className="text-xs text-red-700 dark:text-red-300">A tranzakciok rogzitesehez eloszor meg kell nyitni a napot.</p>
          </div>
        </div>
      )}

      {/* FEE/DISCOUNT DIALOG */}
      {showFeeDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-2xl p-4 w-96 space-y-4">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">Kezelési díj / Kedvezmény</h3>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kezelési díj (HUF)</label>
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
                    setShowFeeDialog(false)
                  }
                }}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Kedvezmeny (%)</label>
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
                    setShowFeeDialog(false)
                  }
                }}
              />
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
                Alkalmaz
              </button>
              <button
                onClick={() => setShowFeeDialog(false)}
                className="flex-1 py-2.5 rounded-lg border border-gray-300 dark:border-gray-600 font-semibold text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
              >
                Megse
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
          Max {MAX_LINES} valutasor | Tab/Enter = következő | Esc = sor törlés
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
                  <th className="px-2 py-1.5 text-right w-28">ÁRFOLYAM</th>
                  <th className="px-2 py-1.5 text-right w-32">BANKJEGY DB</th>
                  <th className="px-2 py-1.5 text-right">FORINT ÉRTÉK</th>
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
                      <span className="text-base font-mono font-semibold text-gray-900 dark:text-white">
                        {row.exchangeRate ? row.exchangeRate.toFixed(2) : '-'}
                      </span>
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
                    <td className="px-2 py-1 text-right">
                      <span className="text-lg font-mono font-bold text-gray-900 dark:text-white">
                        {row.hufValue ? formatNum(row.hufValue) : '-'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {/* OSSZEGZO */}
            <div className="bg-gray-50 dark:bg-gray-800/80 p-2 space-y-1 border-t border-gray-200 dark:border-gray-700">
              <div className="flex justify-between text-sm">
                <span className="text-gray-600 dark:text-gray-400">OSSZESEN:</span>
                <span className="font-mono font-semibold">{formatNum(subtotal)} HUF</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-600 dark:text-gray-400">KEZELESI DIJ:</span>
                <span className="font-mono font-semibold">{formatNum(handlingFee)} HUF</span>
              </div>
              {discount > 0 && (
                <div className="flex justify-between text-sm">
                  <span className="text-gray-600 dark:text-gray-400">KEDVEZMENY ({discount}%):</span>
                  <span className="font-mono font-semibold text-green-600">-{formatNum(discountAmount)} HUF</span>
                </div>
              )}
              <hr className="border-gray-300 dark:border-gray-600 my-1" />
              <div className="flex justify-between items-center">
                <span className="text-base font-bold">FIZETENDO:</span>
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
