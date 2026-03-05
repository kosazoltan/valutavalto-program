import type { CurrencyInfo, CurrencyCode, ExchangeRate } from '@/types';

interface CurrencySelectorProps {
  currencies: CurrencyInfo[];
  selected: CurrencyCode | null;
  onSelect: (code: CurrencyCode) => void;
  rates: ExchangeRate[];
  rateType: 'buy' | 'sell';
}

export default function CurrencySelector({
  currencies,
  selected,
  onSelect,
  rates,
  rateType,
}: CurrencySelectorProps) {
  const getRate = (code: CurrencyCode): string => {
    const rate = rates.find((r) => r.currencyCode === code);
    if (!rate) return '—';
    const value = rateType === 'buy' ? rate.buyRate : rate.sellRate;
    return value.toFixed(2);
  };

  return (
    <div className="space-y-1">
      {currencies.map((currency) => (
        <button
          key={currency.code}
          onClick={() => onSelect(currency.code)}
          className={`currency-card w-full ${
            selected === currency.code ? 'currency-card-selected' : ''
          }`}
        >
          <span className="text-2xl">{currency.flag}</span>
          <div className="flex-1 text-left">
            <p className="text-sm font-bold">{currency.code}</p>
            <p className="text-xs text-gray-500">{currency.name}</p>
          </div>
          <div className="text-right">
            <p className="text-sm font-mono font-semibold text-blue-600">
              {getRate(currency.code)}
            </p>
            {currency.unit > 1 && (
              <p className="text-xs text-gray-400">/{currency.unit}</p>
            )}
          </div>
        </button>
      ))}
    </div>
  );
}
