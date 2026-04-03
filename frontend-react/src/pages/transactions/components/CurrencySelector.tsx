import { useRef, useEffect } from 'react'
import { formatDecimal } from '../../../utils/numberFormat'
import type { CurrencyRate } from '../hooks/useTransactionRates'

interface CurrencySelectorProps {
  currencyRates: CurrencyRate[]
  selectedCurrency: CurrencyRate | null
  onSelect: (currency: CurrencyRate) => void
}

export default function CurrencySelector({
  currencyRates,
  selectedCurrency,
  onSelect,
}: CurrencySelectorProps) {
  const currencyListRef = useRef<HTMLDivElement>(null)
  const selectedIndexRef = useRef(0)

  useEffect(() => {
    if (!selectedCurrency) return
    const index = currencyRates.findIndex(c => c.id === selectedCurrency.id)
    if (index !== -1) {
      selectedIndexRef.current = index
    }
  }, [selectedCurrency, currencyRates])

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowUp') {
      e.preventDefault()
      selectedIndexRef.current = Math.max(0, selectedIndexRef.current - 1)
      const next = currencyRates[selectedIndexRef.current]
      if (next) onSelect(next)
      ;(currencyListRef.current?.children[selectedIndexRef.current] as HTMLElement)
        ?.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
    } else if (e.key === 'ArrowDown') {
      e.preventDefault()
      selectedIndexRef.current = Math.min(currencyRates.length - 1, selectedIndexRef.current + 1)
      const next = currencyRates[selectedIndexRef.current]
      if (next) onSelect(next)
      ;(currencyListRef.current?.children[selectedIndexRef.current] as HTMLElement)
        ?.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
    }
  }

  return (
    <div className="form-panel">
      <h2 className="font-semibold mb-2 pb-1 border-b">Deviza választás</h2>
      <div
        ref={currencyListRef}
        className="space-y-1 max-h-[400px] overflow-auto focus:outline-none focus:ring-2 focus:ring-primary rounded"
        tabIndex={0}
        role="listbox"
        aria-label="Deviza választás"
        data-testid="currency-selector"
        onKeyDown={handleKeyDown}
      >
        {currencyRates.map((currency, index) => (
          <button
            key={currency.id}
            onClick={() => onSelect(currency)}
            data-testid={`currency-${currency.code}`}
            className={`w-full text-left p-2 border rounded transition-colors focus:outline-none ${
              selectedCurrency?.id === currency.id
                ? 'bg-primary text-white border-primary ring-2 ring-primary ring-offset-2'
                : 'bg-white hover:bg-gray-50 border-form-border'
            }`}
            title={`Választás: ${index + 1} billentyű`}
          >
            <div className="flex justify-between items-center">
              <div>
                <span className="font-bold text-lg">
                  {currency.code}
                  <span className="ml-2 text-xs opacity-75">({index + 1})</span>
                </span>
                <span className={`ml-2 text-sm ${
                  selectedCurrency?.id === currency.id ? 'text-primary-100' : 'text-gray-500'
                }`}>
                  {currency.name}
                </span>
              </div>
              <div className="text-right text-sm font-mono">
                <div>V: {formatDecimal(currency.buyRate, 2, 2)}</div>
                <div>E: {formatDecimal(currency.sellRate, 2, 2)}</div>
              </div>
            </div>
          </button>
        ))}
      </div>
      <div className="mt-2 text-xs text-gray-500">
        <div>Navigáció: Nyilak ↑↓</div>
        <div>Választás: Enter</div>
      </div>
    </div>
  )
}
