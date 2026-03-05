import type { CurrencyInfo, CurrencyCode } from '@/types';

export const CURRENCIES: CurrencyInfo[] = [
  { code: 'EUR', name: 'Euró', flag: '🇪🇺', unit: 1 },
  { code: 'USD', name: 'Amerikai dollár', flag: '🇺🇸', unit: 1 },
  { code: 'GBP', name: 'Brit font', flag: '🇬🇧', unit: 1 },
  { code: 'CHF', name: 'Svájci frank', flag: '🇨🇭', unit: 1 },
  { code: 'CZK', name: 'Cseh korona', flag: '🇨🇿', unit: 100 },
  { code: 'PLN', name: 'Lengyel zloty', flag: '🇵🇱', unit: 1 },
  { code: 'RON', name: 'Román lej', flag: '🇷🇴', unit: 1 },
  { code: 'HRK', name: 'Horvát kuna', flag: '🇭🇷', unit: 1 },
  { code: 'RSD', name: 'Szerb dinár', flag: '🇷🇸', unit: 100 },
  { code: 'BAM', name: 'Bosnyák márka', flag: '🇧🇦', unit: 1 },
  { code: 'BGN', name: 'Bolgár leva', flag: '🇧🇬', unit: 1 },
  { code: 'DKK', name: 'Dán korona', flag: '🇩🇰', unit: 1 },
  { code: 'NOK', name: 'Norvég korona', flag: '🇳🇴', unit: 1 },
  { code: 'SEK', name: 'Svéd korona', flag: '🇸🇪', unit: 1 },
  { code: 'CAD', name: 'Kanadai dollár', flag: '🇨🇦', unit: 1 },
  { code: 'AUD', name: 'Ausztrál dollár', flag: '🇦🇺', unit: 1 },
  { code: 'NZD', name: 'Új-zélandi dollár', flag: '🇳🇿', unit: 1 },
  { code: 'JPY', name: 'Japán jen', flag: '🇯🇵', unit: 100 },
  { code: 'CNY', name: 'Kínai jüan', flag: '🇨🇳', unit: 1 },
  { code: 'TRY', name: 'Török líra', flag: '🇹🇷', unit: 1 },
  { code: 'RUB', name: 'Orosz rubel', flag: '🇷🇺', unit: 100 },
  { code: 'UAH', name: 'Ukrán hrivnya', flag: '🇺🇦', unit: 1 },
  { code: 'ILS', name: 'Izraeli sékel', flag: '🇮🇱', unit: 1 },
  { code: 'THB', name: 'Thai baht', flag: '🇹🇭', unit: 1 },
  { code: 'BRL', name: 'Brazil real', flag: '🇧🇷', unit: 1 },
  { code: 'MXN', name: 'Mexikói peso', flag: '🇲🇽', unit: 1 },
  { code: 'HUF', name: 'Magyar forint', flag: '🇭🇺', unit: 1 },
];

export function getCurrencyInfo(code: CurrencyCode): CurrencyInfo | undefined {
  return CURRENCIES.find((c) => c.code === code);
}

export function getForeignCurrencies(): CurrencyInfo[] {
  return CURRENCIES.filter((c) => c.code !== 'HUF');
}
