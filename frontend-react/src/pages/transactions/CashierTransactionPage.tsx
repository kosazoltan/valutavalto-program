import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { useHotkeys } from 'react-hotkeys-hook'
import {
  AlertTriangle,
  User,
  Scan,
} from 'lucide-react'
import { CashierHeader } from '../../components/cashier/CashierHeader'
import { HotkeyBar } from '../../components/cashier/HotkeyBar'
import { useCompanyTheme } from '../../contexts/CompanyThemeContext'
import { transactionApi, exchangeRateApi } from '../../services/api/index'
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

/**
 * Penztaros Eladas/Vetel kepernyoje — 6 soros valuta tabla.
 *
 * Legacy: ELADAS.DLL + VASARLAS.DLL
 * - Max 6 valutasor/bizonylat
 * - Arfolyam/100 * bankjegy = forint (JPY /1000)
 * - Tab/Enter navigacio sorok kozott
 * - F2=Vetel, F3=Eladas, F5=Storno, F8=Arfolyam, F9=Kedvezmeny, Esc=Megse
 */

const MAX_LINES = 6
const IDENTIFICATION_LIMIT = 300_000

interface TransactionRow {
  currencyCode: string
  currencyName: string
  exchangeRate: number
  quantity: string
  hufValue: number
}

const emptyRow = (): TransactionRow => ({
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

  // Transaction state
  const [mode, setMode] = useState<'buy' | 'sell'>('buy')
  const [rows, setRows] = useState<TransactionRow[]>(
    Array.from({ length: MAX_LINES }, emptyRow)
  )
  const [activeRow, setActiveRow] = useState(0)
  const [activeField, setActiveField] = useState<'currency' | 'quantity'>('currency')

  // Customer state
  const [customerName, setCustomerName] = useState('')
  const [customerDocNumber, setCustomerDocNumber] = useState('')
  const [customerAddress, setCustomerAddress] = useState('')

  // Fees
  const [handlingFee, _setHandlingFee] = useState(0)
  const [discount, _setDiscount] = useState(0)

  // Exchange rates from API
  const [exchangeRates, setExchangeRates] = useState<ExchangeRate[]>([])

  // Submission state
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Receipt print state — queue for multi-line transactions
  const [showReceiptModal, setShowReceiptModal] = useState(false)
  const [receiptData, setReceiptData] = useState<PrintReceiptData | null>(null)
  const receiptQueueRef = useRef<PrintReceiptData[]>([])

  // Auth store for receipt data
  const worker = useAuthStore(s => s.worker)

  // Refs for keyboard navigation
  const currencyRefs = useRef<(HTMLInputElement | null)[]>([])
  const quantityRefs = useRef<(HTMLInputElement | null)[]>([])

  // Calculated totals
  const subtotal = rows.reduce((sum, r) => sum + r.hufValue, 0)
  const total = subtotal + handlingFee - discount

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

  // Load exchange rates with Electron cached-rates priority
  useEffect(() => {
    let cancelled = false

    const loadRates = async () => {
      if (electronQueueAvailable) {
        try {
          const cachedRates = await getElectronCachedRates()
          if (!cancelled && cachedRates.length > 0) {
            setExchangeRates(mapCachedRatesToExchangeRates(cachedRates))
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
  useHotkeys('f2', () => setMode('buy'), { enableOnFormTags: true })
  useHotkeys('f3', () => setMode('sell'), { enableOnFormTags: true })
  useHotkeys('f5', () => navigate('/stornos'), { enableOnFormTags: true })
  useHotkeys('f8', () => navigate('/rates'), { enableOnFormTags: true })
  useHotkeys('escape', () => handleCancel(), { enableOnFormTags: true })

  // ====== HANDLERS ======

  const handleCurrencyInput = useCallback(
    async (rowIdx: number, value: string) => {
      const code = value.toUpperCase().slice(0, 3)
      setRows((prev) => {
        const next = [...prev]
        next[rowIdx] = { ...next[rowIdx]!, currencyCode: code }
        return next
      })

      // Ha 3 betus kod, arfolyam lekérés az API-bol betoltott rateekbol
      if (code.length === 3) {
        const rateEntry = exchangeRates.find((r) => r.currencyCode === code && r.active)
        if (rateEntry) {
          const appliedRate = mode === 'buy' ? rateEntry.baseBuyRate : rateEntry.baseSellRate
          setRows((prev) => {
            const next = [...prev]
            next[rowIdx] = {
              ...next[rowIdx]!,
              currencyCode: code,
              exchangeRate: appliedRate,
              currencyName: rateEntry.currencyName || code,
            }
            return next
          })
          setActiveField('quantity')
        }
      }
    },
    [mode, exchangeRates]
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
    const filledRows = rows.filter((r) => r.currencyCode && r.hufValue > 0)
    if (filledRows.length === 0) return

    // AML ellenorzes
    if (total >= IDENTIFICATION_LIMIT) {
      if (!customerName.trim() || !customerDocNumber.trim()) {
        toast.warning('Ügyfél azonosítás kötelező', `${IDENTIFICATION_LIMIT.toLocaleString('hu-HU')} Ft feletti tranzakciohoz ugyfel azonositas KOTELEZO!`)
        return
      }
    }

    setIsSubmitting(true)

    try {
      const customerData = total >= IDENTIFICATION_LIMIT ? {
        customerName: customerName.trim() || undefined,
        customerDocumentNumber: customerDocNumber.trim() || undefined,
        customerAddress: customerAddress.trim() || undefined,
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
            customerIdentifier: customerDocNumber.trim() || null,
            customerName: customerName.trim() || null,
            customerDocumentNumber: customerDocNumber.trim() || null,
            customerAddress: customerAddress.trim() || null,
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
            customerName: customerName.trim() || undefined,
            customerDocNumber: customerDocNumber.trim() || undefined,
            customerAddress: customerAddress.trim() || undefined,
            vatExemptionText: 'Tárgyi adómentes az ÁFA tv. 86.§ (1) bek. k) pontja alapján.',
          }))
          receiptQueueRef.current = receipts.slice(1)
          if (receipts[0]) {
            setReceiptData(receipts[0])
            setShowReceiptModal(true)
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
            customerName: customerName.trim() || undefined,
            customerDocNumber: customerDocNumber.trim() || undefined,
            customerAddress: customerAddress.trim() || undefined,
            vatExemptionText: 'Tárgyi adómentes az ÁFA tv. 86.§ (1) bek. k) pontja alapján.',
          }))
          receiptQueueRef.current = receipts.slice(1)
          if (receipts[0]) {
            setReceiptData(receipts[0])
            setShowReceiptModal(true)
          }
        }
      }

      // Reset
      setRows(Array.from({ length: MAX_LINES }, emptyRow))
      setActiveRow(0)
      setActiveField('currency')
      setCustomerName('')
      setCustomerDocNumber('')
      setCustomerAddress('')
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : 'Ismeretlen hiba'
      const axiosError = error as { response?: { data?: { message?: string } } }
      const serverMessage = axiosError?.response?.data?.message
      toast.error('Hiba a tranzakció mentés során!', serverMessage || message)
    } finally {
      setIsSubmitting(false)
    }
  }, [rows, mode, total, handlingFee, discount, customerName, customerDocNumber, customerAddress, electronQueueAvailable, worker?.branchCode, worker?.companyCode, worker?.fullName])

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent, rowIdx: number, field: 'currency' | 'quantity') => {
      if (e.key === 'Enter' || e.key === 'Tab') {
        e.preventDefault()
        if (field === 'currency' && rows[rowIdx]?.currencyCode.length === 3) {
          // Ugras quantity-re
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
    [rows, handleSubmit]
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
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 pb-20">
      <CashierHeader />

      {/* MODE BADGE */}
      <div className="px-6 pt-4 pb-2 flex items-center gap-4">
        <span
          className="text-lg font-bold text-white px-5 py-2 rounded-lg shadow"
          style={{ backgroundColor: mode === 'buy' ? '#2E7D32' : '#1565C0' }}
        >
          {mode === 'buy' ? 'VÉTEL' : 'ELADÁS'}
        </span>
        <span className="text-sm text-gray-500 dark:text-gray-400">
          Max {MAX_LINES} valutasor | Tab/Enter = következő | Esc = sor törlés
        </span>
      </div>

      <main className="px-6">
        <div className="grid grid-cols-[1fr,340px] gap-6">
          {/* BAL: 6-SOROS TABLA */}
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="bg-gray-100 dark:bg-gray-700 text-sm font-semibold text-gray-700 dark:text-gray-300">
                  <th className="px-4 py-3 text-left w-28">VALUTA</th>
                  <th className="px-4 py-3 text-right w-32">ÁRFOLYAM</th>
                  <th className="px-4 py-3 text-right w-36">BANKJEGY DB</th>
                  <th className="px-4 py-3 text-right">FORINT ERTEK</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row, idx) => (
                  <tr
                    key={idx}
                    className={`border-b border-gray-100 dark:border-gray-700 transition-colors ${
                      idx === activeRow
                        ? 'bg-blue-50 dark:bg-blue-950/30 border-l-4 border-l-blue-500'
                        : ''
                    }`}
                  >
                    <td className="px-4 py-2">
                      <input
                        ref={(el) => { currencyRefs.current[idx] = el }}
                        value={row.currencyCode}
                        onChange={(e) => handleCurrencyInput(idx, e.target.value)}
                        onKeyDown={(e) => handleKeyDown(e, idx, 'currency')}
                        onFocus={() => { setActiveRow(idx); setActiveField('currency') }}
                        className="w-20 h-12 text-center font-mono text-lg font-bold uppercase bg-transparent border-2 border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:border-transparent"
                        style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                        maxLength={3}
                        placeholder="EUR"
                        autoComplete="off"
                      />
                    </td>
                    <td className="px-4 py-2 text-right">
                      <span className="text-lg font-mono font-semibold text-gray-900 dark:text-white">
                        {row.exchangeRate ? row.exchangeRate.toFixed(2) : '-'}
                      </span>
                    </td>
                    <td className="px-4 py-2 text-right">
                      <input
                        ref={(el) => { quantityRefs.current[idx] = el }}
                        value={row.quantity}
                        onChange={(e) => handleQuantityInput(idx, e.target.value)}
                        onKeyDown={(e) => handleKeyDown(e, idx, 'quantity')}
                        onFocus={() => { setActiveRow(idx); setActiveField('quantity') }}
                        type="text"
                        inputMode="numeric"
                        className="w-28 h-12 text-right font-mono text-lg font-semibold bg-transparent border-2 border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:border-transparent"
                        style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
                        placeholder="0"
                        disabled={!row.currencyCode}
                      />
                    </td>
                    <td className="px-4 py-2 text-right">
                      <span className="text-xl font-mono font-bold text-gray-900 dark:text-white">
                        {row.hufValue ? formatNum(row.hufValue) : '-'}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {/* OSSZEGZO */}
            <div className="bg-gray-50 dark:bg-gray-800/80 p-6 space-y-3 border-t border-gray-200 dark:border-gray-700">
              <div className="flex justify-between text-base">
                <span className="text-gray-600 dark:text-gray-400">OSSZESEN:</span>
                <span className="font-mono font-semibold">{formatNum(subtotal)} HUF</span>
              </div>
              <div className="flex justify-between text-base">
                <span className="text-gray-600 dark:text-gray-400">KEZELESI DIJ:</span>
                <span className="font-mono font-semibold">{formatNum(handlingFee)} HUF</span>
              </div>
              {discount > 0 && (
                <div className="flex justify-between text-base">
                  <span className="text-gray-600 dark:text-gray-400">KEDVEZMENY:</span>
                  <span className="font-mono font-semibold text-green-600">-{formatNum(discount)} HUF</span>
                </div>
              )}
              <hr className="border-gray-300 dark:border-gray-600" />
              <div className="flex justify-between items-center pt-1">
                <span className="text-2xl font-bold">FIZETENDO:</span>
                <span
                  className="text-4xl font-mono font-black text-white px-6 py-3 rounded-lg shadow-lg"
                  style={{ backgroundColor: 'var(--primary)' }}
                >
                  {formatNum(total)} HUF
                </span>
              </div>
            </div>
          </div>

          {/* JOBB: UGYFEL PANEL */}
          <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-5 space-y-4">
            <h3 className="text-lg font-bold flex items-center gap-2 text-gray-900 dark:text-white">
              <User className="w-5 h-5" />
              UGYFEL ADATOK
            </h3>

            {total >= IDENTIFICATION_LIMIT && (
              <div className="bg-amber-50 dark:bg-amber-950/30 border-2 border-amber-400 dark:border-amber-600 rounded-lg p-3 flex items-start gap-2">
                <AlertTriangle className="w-5 h-5 text-amber-600 dark:text-amber-400 mt-0.5 shrink-0" />
                <p className="text-sm font-semibold text-amber-900 dark:text-amber-200">
                  Azonositas KOTELEZO {IDENTIFICATION_LIMIT.toLocaleString('hu-HU')} Ft felett!
                </p>
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Nev</label>
              <input
                value={customerName}
                onChange={(e) => setCustomerName(e.target.value)}
                placeholder="Kovacs Janos"
                className="w-full h-11 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Igazolvany szam</label>
              <input
                value={customerDocNumber}
                onChange={(e) => setCustomerDocNumber(e.target.value)}
                placeholder="123456AB"
                className="w-full h-11 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent font-mono text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Lakcim</label>
              <input
                value={customerAddress}
                onChange={(e) => setCustomerAddress(e.target.value)}
                placeholder="1111 Budapest, Fo utca 1."
                className="w-full h-11 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
              />
            </div>

            {total >= IDENTIFICATION_LIMIT && (
              <button className="w-full py-2.5 border border-gray-300 dark:border-gray-600 rounded-lg flex items-center justify-center gap-2 text-sm font-medium hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                <Scan className="w-4 h-4" />
                Igazolvany beolvasas
              </button>
            )}

            {/* Veglegestes gomb */}
            <button
              onClick={handleSubmit}
              disabled={isSubmitting || !rows.some((r) => r.hufValue > 0)}
              className="w-full py-3 rounded-lg text-white font-bold text-lg shadow-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed hover:opacity-90"
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
          }
        }}
        receiptData={receiptData}
        qrCodeDataUrl={null}
        allowPrint={isElectron()}
        onPrint={async () => {
          if (receiptData && window.electronAPI?.printReceipt) {
            await window.electronAPI.printReceipt(JSON.stringify(receiptData))
          }
        }}
        printLabel={!isElectron() ? 'Nyomtatás nem elérhető' : undefined}
      />

      {/* HOTKEY BAR */}
      <HotkeyBar
        left={[
          { key: 'F2', label: 'Vetel', onClick: () => setMode('buy'), active: mode === 'buy' },
          { key: 'F3', label: 'Eladas', onClick: () => setMode('sell'), active: mode === 'sell' },
          { key: 'F5', label: 'Storno', onClick: () => navigate('/stornos'), variant: 'danger' },
          { key: 'F8', label: 'Árfolyam', onClick: () => navigate('/rates') },
        ]}
        right={[
          { key: 'Esc', label: 'Mégse', onClick: handleCancel, variant: 'secondary' },
        ]}
      />
    </div>
  )
}
