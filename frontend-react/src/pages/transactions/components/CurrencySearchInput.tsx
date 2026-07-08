import { useState, useRef, useEffect, useCallback, useMemo } from 'react'
import { Search } from 'lucide-react'
import type { CurrencyRate } from '../hooks/useTransactionRates'
import { useTranslation } from 'react-i18next'

/**
 * Prediktív devizakereső mező — a Tranzakció adatok panelen.
 * Gépelésre kód vagy név alapján szűr, dropdown listából választható.
 */

interface Props {
  currencyRates: CurrencyRate[]
  onSelect: (currency: CurrencyRate) => void
}

export default function CurrencySearchInput({ currencyRates, onSelect }: Props) {
  const { t } = useTranslation()
  const [searchText, setSearchText] = useState('')
  const [isOpen, setIsOpen] = useState(false)
  const [highlightIdx, setHighlightIdx] = useState(0)
  const containerRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const listRef = useRef<HTMLDivElement>(null)

  const filtered = useMemo(
    () =>
      searchText.trim()
        ? currencyRates
            .filter((c) => {
              const q = searchText.trim().toLowerCase()
              return (
                c.code.toLowerCase().includes(q) || (c.name?.toLowerCase().includes(q) ?? false)
              )
            })
            .sort((a, b) => {
              const q = searchText.trim().toLowerCase()
              const aStart = a.code.toLowerCase().startsWith(q) ? 0 : 1
              const bStart = b.code.toLowerCase().startsWith(q) ? 0 : 1
              if (aStart !== bStart) return aStart - bStart
              return a.code.localeCompare(b.code)
            })
        : [],
    [searchText, currencyRates],
  )

  // Reset highlight on filter change
  useEffect(() => {
    setHighlightIdx(0)
  }, [searchText])

  // Scroll highlighted into view
  useEffect(() => {
    if (isOpen && listRef.current) {
      const item = listRef.current.children[highlightIdx] as HTMLElement | undefined
      item?.scrollIntoView({ block: 'nearest' })
    }
  }, [highlightIdx, isOpen])

  // Close on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const selectItem = useCallback(
    (currency: CurrencyRate) => {
      onSelect(currency)
      setSearchText('')
      setIsOpen(false)
    },
    [onSelect],
  )

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (!isOpen && filtered.length > 0 && (e.key === 'ArrowDown' || e.key === 'Enter')) {
        e.preventDefault()
        setIsOpen(true)
        return
      }

      if (isOpen) {
        if (e.key === 'ArrowDown') {
          e.preventDefault()
          setHighlightIdx((prev) => Math.min(prev + 1, filtered.length - 1))
        } else if (e.key === 'ArrowUp') {
          e.preventDefault()
          setHighlightIdx((prev) => Math.max(prev - 1, 0))
        } else if (e.key === 'Enter') {
          e.preventDefault()
          if (filtered[highlightIdx]) {
            selectItem(filtered[highlightIdx])
          }
        } else if (e.key === 'Escape') {
          e.preventDefault()
          setIsOpen(false)
          setSearchText('')
        }
      }
    },
    [isOpen, filtered, highlightIdx, selectItem],
  )

  return (
    <div ref={containerRef} className="relative mb-3">
      <div className="form-group-box pt-4">
        <span className="form-group-box-title">{t('transactions.gyorsDevizakereses')}</span>
        <div className="relative">
          <Search
            size={16}
            className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none"
          />
          <input
            ref={inputRef}
            type="text"
            value={searchText}
            onChange={(e) => {
              setSearchText(e.target.value)
              if (e.target.value.trim()) setIsOpen(true)
            }}
            onFocus={() => {
              if (searchText.trim()) setIsOpen(true)
            }}
            onKeyDown={handleKeyDown}
            placeholder="Valuta kód vagy név (pl. EUR, Euró...)"
            className="form-input w-full pl-9 pr-3 h-11 text-sm"
            autoComplete="off"
            data-testid="currency-quick-search"
          />
        </div>
      </div>

      {/* Dropdown results */}
      {isOpen && filtered.length > 0 && (
        <div
          ref={listRef}
          className="absolute z-50 left-0 right-0 mt-1 max-h-52 overflow-y-auto
            bg-white border border-gray-200 rounded-lg shadow-xl"
        >
          {filtered.map((currency, idx) => (
            <button
              key={currency.id}
              type="button"
              onMouseDown={(e) => {
                e.preventDefault()
                selectItem(currency)
              }}
              onMouseEnter={() => setHighlightIdx(idx)}
              className={`w-full text-left px-3 py-2.5 flex items-center justify-between text-sm transition-colors
                ${idx === highlightIdx ? 'bg-blue-50 text-blue-800' : 'hover:bg-gray-50'}`}
            >
              <div className="flex items-center gap-2">
                <span className="font-mono font-bold text-base w-10">{currency.code}</span>
                <span className="text-gray-600">{currency.name || currency.code}</span>
              </div>
              <div className="text-right font-mono text-xs text-gray-500">
                <div>
                  {t('transactions.v')}
                  {currency.buyRate?.toFixed(2)}
                </div>
                <div>
                  {t('transactions.e')}
                  {currency.sellRate?.toFixed(2)}
                </div>
              </div>
            </button>
          ))}
        </div>
      )}

      {/* No results */}
      {isOpen && filtered.length === 0 && searchText.trim().length > 0 && (
        <div className="absolute z-50 left-0 right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-xl p-3 text-sm text-gray-500">
          {t('components.nincsTalalat')}
          {searchText}"
        </div>
      )}
    </div>
  )
}
