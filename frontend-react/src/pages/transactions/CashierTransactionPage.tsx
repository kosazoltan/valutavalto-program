import { useState, useEffect, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { useHotkeys } from 'react-hotkeys-hook'
import {
  AlertTriangle,
  User,
  Scan,
} from 'lucide-react'
import { CashierHeader } from '../../components/cashier/CashierHeader'
import { HotkeyBar } from '../../components/cashier/HotkeyBar'
import { useCompanyTheme } from '../../contexts/CompanyThemeContext'
// import { exchangeRateApi } from '../../services/api'  // TODO: bekotni production API-hoz

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
  const { theme: _theme } = useCompanyTheme()

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

  // Auto focus first row on mount
  useEffect(() => {
    setTimeout(() => currencyRefs.current[0]?.focus(), 100)
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

      // Ha 3 betus kod, arfolyam lekeres
      if (code.length === 3) {
        // Mock arfolyamok (production-ben API hivas)
        const mockRates: Record<string, number> = {
          EUR: mode === 'buy' ? 391.5 : 398.5,
          USD: mode === 'buy' ? 358.2 : 365.8,
          GBP: mode === 'buy' ? 455 : 468,
          CHF: mode === 'buy' ? 402.5 : 412.5,
          CZK: mode === 'buy' ? 15.2 : 16.4,
          PLN: mode === 'buy' ? 91.5 : 96.5,
          RON: mode === 'buy' ? 78.5 : 82.5,
          HRK: mode === 'buy' ? 52 : 55,
          JPY: mode === 'buy' ? 260 : 275,
          SEK: mode === 'buy' ? 34.5 : 37.2,
          NOK: mode === 'buy' ? 33.8 : 36.5,
          DKK: mode === 'buy' ? 52.8 : 55.4,
          CAD: mode === 'buy' ? 265 : 275,
          AUD: mode === 'buy' ? 238 : 248,
          TRY: mode === 'buy' ? 10.5 : 12.8,
          RSD: mode === 'buy' ? 3.38 : 3.68,
          BAM: mode === 'buy' ? 200 : 210,
          BGN: mode === 'buy' ? 202 : 212,
          UAH: mode === 'buy' ? 9.2 : 10.5,
          RUB: mode === 'buy' ? 3.85 : 4.35,
        }
        const mockRate = mockRates[code]
        if (mockRate) {
          setRows((prev) => {
            const next = [...prev]
            next[rowIdx] = {
              ...next[rowIdx]!,
              currencyCode: code,
              exchangeRate: mockRate,
              currencyName: code,
            }
            return next
          })
          setActiveField('quantity')
        }
      }
    },
    [mode]
  )

  const handleQuantityInput = useCallback(
    (rowIdx: number, value: string) => {
      const qty = value.replace(/[^0-9.]/g, '')
      setRows((prev) => {
        const next = [...prev]
        const row = next[rowIdx]!
        const qtyNum = parseFloat(qty) || 0

        // Legacy arfolyam szamitas: rate / 100 * bankjegy (JPY /1000)
        const divisor = row.currencyCode === 'JPY' ? 1000 : 100
        const hufValue = Math.round((row.exchangeRate / divisor) * qtyNum)

        next[rowIdx] = { ...row, quantity: qty, hufValue }
        return next
      })
    },
    []
  )

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
    [rows]
  )

  const handleSubmit = useCallback(async () => {
    const filledRows = rows.filter((r) => r.currencyCode && r.hufValue > 0)
    if (filledRows.length === 0) return

    // AML ellenorzes
    if (total >= IDENTIFICATION_LIMIT) {
      if (!customerName.trim() || !customerDocNumber.trim()) {
        alert(`${IDENTIFICATION_LIMIT.toLocaleString('hu-HU')} Ft feletti tranzakciohoz ugyfel azonositas KOTELEZO!`)
        return
      }
    }

    // TODO: API hivas
    console.log('Tranzakcio:', {
      type: mode,
      lines: filledRows,
      total,
      handlingFee,
      discount,
      customer: { name: customerName, doc: customerDocNumber, address: customerAddress },
    })

    alert(`Bizonylat keszitve: ${filledRows.length} tetel, ${total.toLocaleString('hu-HU')} Ft`)

    // Reset
    setRows(Array.from({ length: MAX_LINES }, emptyRow))
    setActiveRow(0)
    setActiveField('currency')
    setCustomerName('')
    setCustomerDocNumber('')
    setCustomerAddress('')
  }, [rows, mode, total, handlingFee, discount, customerName, customerDocNumber, customerAddress])

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
          {mode === 'buy' ? 'VETEL' : 'ELADAS'}
        </span>
        <span className="text-sm text-gray-500 dark:text-gray-400">
          Max {MAX_LINES} valutasor | Tab/Enter = kovetkezo | Esc = sor torles
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
                  <th className="px-4 py-3 text-right w-32">ARFOLYAM</th>
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
                        style={{ '--tw-ring-color': 'var(--primary)' } as any}
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
                        style={{ '--tw-ring-color': 'var(--primary)' } as any}
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
                style={{ '--tw-ring-color': 'var(--primary)' } as any}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Igazolvany szam</label>
              <input
                value={customerDocNumber}
                onChange={(e) => setCustomerDocNumber(e.target.value)}
                placeholder="123456AB"
                className="w-full h-11 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent font-mono text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                style={{ '--tw-ring-color': 'var(--primary)' } as any}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Lakcim</label>
              <input
                value={customerAddress}
                onChange={(e) => setCustomerAddress(e.target.value)}
                placeholder="1111 Budapest, Fo utca 1."
                className="w-full h-11 px-3 rounded-lg border border-gray-300 dark:border-gray-600 bg-transparent text-gray-900 dark:text-white focus:ring-2 focus:border-transparent"
                style={{ '--tw-ring-color': 'var(--primary)' } as any}
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
              disabled={!rows.some((r) => r.hufValue > 0)}
              className="w-full py-3 rounded-lg text-white font-bold text-lg shadow-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed hover:opacity-90"
              style={{ backgroundColor: 'var(--primary)' }}
            >
              BIZONYLAT KESZITESE
            </button>
          </div>
        </div>
      </main>

      {/* HOTKEY BAR */}
      <HotkeyBar
        left={[
          { key: 'F2', label: 'Vetel', onClick: () => setMode('buy'), active: mode === 'buy' },
          { key: 'F3', label: 'Eladas', onClick: () => setMode('sell'), active: mode === 'sell' },
          { key: 'F5', label: 'Storno', onClick: () => navigate('/stornos'), variant: 'danger' },
          { key: 'F8', label: 'Arfolyam', onClick: () => navigate('/rates') },
        ]}
        right={[
          { key: 'Esc', label: 'Megse', onClick: handleCancel, variant: 'secondary' },
        ]}
      />
    </div>
  )
}
