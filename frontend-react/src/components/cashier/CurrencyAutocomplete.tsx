import { useState, useRef, useEffect, useCallback } from 'react'
import type { ExchangeRate } from '../../services/api/exchange-rates'
import { useTranslation } from 'react-i18next'

/**
 * Prediktív devizaválasztó — szabad szöveges bevitel autocomplete-tel.
 *
 * - Valutakód (EUR) VAGY név (Euró, Dollar, stb.) alapján keres
 * - Nyíl le/fel navigáció a listában
 * - Enter/Tab kiválasztás
 * - Esc bezárás
 * - 3 betűs pontos kód automatikusan kiválaszt (instant match)
 */

interface Props {
  rates: ExchangeRate[]
  value: string
  onChange: (code: string, rate: ExchangeRate | null) => void
  onConfirm: () => void
  onKeyDown?: (e: React.KeyboardEvent) => void
  inputRef?: React.Ref<HTMLInputElement>
  onFocus?: () => void
  placeholder?: string
  disabled?: boolean
  'data-testid'?: string
}

export function CurrencyAutocomplete({
  rates,
  value,
  onChange,
  onConfirm,
  onKeyDown: externalKeyDown,
  inputRef,
  onFocus,
  placeholder = 'EUR, Euró...',
  disabled = false,
  ...rest
}: Props) {
  const { t } = useTranslation()
  const [isOpen, setIsOpen] = useState(false)
  const [highlightIdx, setHighlightIdx] = useState(0)
  const [inputText, setInputText] = useState(value)
  const containerRef = useRef<HTMLDivElement>(null)
  const listRef = useRef<HTMLDivElement>(null)

  // Sync external value changes
  useEffect(() => {
    setInputText(value)
  }, [value])

  // Filter rates based on input text
  const filtered = useCallback(() => {
    const q = inputText.trim().toLowerCase()
    if (!q) return rates.filter(r => r.active)

    return rates
      .filter(r => r.active)
      .filter(r =>
        r.currencyCode.toLowerCase().includes(q) ||
        (r.currencyName?.toLowerCase().includes(q) ?? false)
      )
      .sort((a, b) => {
        // Exact code match first
        const aCodeStart = a.currencyCode.toLowerCase().startsWith(q) ? 0 : 1
        const bCodeStart = b.currencyCode.toLowerCase().startsWith(q) ? 0 : 1
        if (aCodeStart !== bCodeStart) return aCodeStart - bCodeStart
        // Then name match
        const aNameStart = (a.currencyName?.toLowerCase().startsWith(q) ?? false) ? 0 : 1
        const bNameStart = (b.currencyName?.toLowerCase().startsWith(q) ?? false) ? 0 : 1
        if (aNameStart !== bNameStart) return aNameStart - bNameStart
        return a.currencyCode.localeCompare(b.currencyCode)
      })
  }, [inputText, rates])

  const suggestions = filtered()

  // Reset highlight when suggestions change
  useEffect(() => {
    setHighlightIdx(0)
  }, [inputText])

  // Scroll highlighted item into view
  useEffect(() => {
    if (isOpen && listRef.current) {
      const item = listRef.current.children[highlightIdx] as HTMLElement | undefined
      item?.scrollIntoView({ block: 'nearest' })
    }
  }, [highlightIdx, isOpen])

  // Close dropdown on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handler)
    return () => document.removeEventListener('mousedown', handler)
  }, [])

  const selectRate = useCallback((rate: ExchangeRate) => {
    setInputText(rate.currencyCode)
    onChange(rate.currencyCode, rate)
    setIsOpen(false)
    onConfirm()
  }, [onChange, onConfirm])

  const handleInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value.toUpperCase()
    setInputText(raw)
    setIsOpen(true)

    // Instant match: if exact 3-letter code matches an active rate
    const exact = raw.length === 3
      ? rates.find(r => r.currencyCode === raw && r.active)
      : undefined
    if (exact) {
      onChange(raw, exact)
      setIsOpen(false)
      onConfirm()
      return
    }

    // Partial: notify parent with code only, no rate yet
    onChange(raw, null)
  }, [rates, onChange, onConfirm])

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (!isOpen && (e.key === 'ArrowDown' || e.key === 'ArrowUp')) {
      e.preventDefault()
      setIsOpen(true)
      return
    }

    if (isOpen) {
          if (e.key === 'ArrowDown') {
            e.preventDefault()
            setHighlightIdx(prev => Math.min(prev + 1, suggestions.length - 1))
            return
          }
          if (e.key === 'ArrowUp') {
            e.preventDefault()
            setHighlightIdx(prev => Math.max(prev - 1, 0))
            return
          }
          if (e.key === 'Enter' || e.key === 'Tab') {
            e.preventDefault()
            if (suggestions[highlightIdx]) {
              selectRate(suggestions[highlightIdx])
            }
            return
          }
          if (e.key === 'Escape') {
            e.preventDefault()
            setIsOpen(false)
            return
          }
        }
    else if (e.key === 'Enter' || e.key === 'Tab') {
            const exact = inputText.length === 3
              ? rates.find(r => r.currencyCode === inputText && r.active)
              : undefined
            if (exact) {
              e.preventDefault()
              selectRate(exact)
              return
            }
          }

    // Forward other keys to external handler (ArrowUp/Down for row nav when closed)
    externalKeyDown?.(e)
  }, [isOpen, suggestions, highlightIdx, inputText, rates, selectRate, externalKeyDown])

  return (
    <div ref={containerRef} className="relative">
      <input
        ref={inputRef}
        value={inputText}
        onChange={handleInputChange}
        onKeyDown={handleKeyDown}
        onFocus={() => {
          setIsOpen(true)
          onFocus?.()
        }}
        className="w-full h-12 px-3 text-center font-mono text-lg font-bold uppercase bg-transparent 
          border-2 border-gray-300 dark:border-gray-600 rounded-lg 
          focus:ring-2 focus:border-transparent"
        style={{ '--tw-ring-color': 'var(--primary)' } as React.CSSProperties}
        maxLength={10}
        placeholder={placeholder}
        autoComplete="off"
        disabled={disabled}
        data-testid={rest['data-testid']}
      />

      {/* Dropdown */}
      {isOpen && suggestions.length > 0 && inputText.length > 0 && (
        <div
          ref={listRef}
          className="absolute z-50 mt-1 w-72 max-h-60 overflow-y-auto 
            bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 
            rounded-lg shadow-xl"
        >
          {suggestions.map((rate, idx) => (
            <button
              key={rate.currencyCode}
              type="button"
              onMouseDown={(e) => {
                e.preventDefault() // Prevent input blur
                selectRate(rate)
              }}
              onMouseEnter={() => setHighlightIdx(idx)}
              className={`w-full text-left px-3 py-2 flex items-center gap-3 text-sm transition-colors
                ${idx === highlightIdx
                  ? 'bg-primary-50 dark:bg-primary-900/30 text-primary-700 dark:text-primary-300'
                  : 'hover:bg-gray-50 dark:hover:bg-gray-700/50'
                }`}
            >
              <span className="font-mono font-bold text-base w-10">{rate.currencyCode}</span>
              <span className="text-gray-600 dark:text-gray-400 flex-1 truncate">
                {rate.currencyName || rate.currencyCode}
              </span>
              <span className="font-mono text-xs text-gray-500">
                {rate.baseBuyRate?.toFixed(2) || '-'}
              </span>
            </button>
          ))}
        </div>
      )}

      {/* Empty state */}
      {isOpen && suggestions.length === 0 && inputText.length > 0 && (
        <div className="absolute z-50 mt-1 w-72 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-xl p-3 text-sm text-gray-500">
          {t('components.nincsTalalat')}{inputText}"
        </div>
      )}
    </div>
  )
}
