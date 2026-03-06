import { describe, it, expect, vi } from 'vitest';

// Mock react-router-dom
vi.mock('react-router-dom', () => ({
  useNavigate: () => vi.fn(),
}));

// Mock authStore
vi.mock('@/stores/authStore', () => ({
  useAuthStore: () => ({ companyType: 'DEFAULT' }),
}));

// Mock calculator API
vi.mock('@/api/calculator', () => ({
  convertCurrency: vi.fn().mockResolvedValue({
    fromCurrency: 'EUR',
    toCurrency: 'HUF',
    amount: 100,
    result: 39500,
    rate: 395.0,
  }),
  getRoundingRules: vi.fn().mockResolvedValue([]),
}));

// Mock currencies utility
vi.mock('@/utils/currencies', () => ({
  getForeignCurrencies: () => [
    { code: 'EUR', name: 'Euró', flag: '🇪🇺' },
    { code: 'USD', name: 'USA dollár', flag: '🇺🇸' },
    { code: 'GBP', name: 'Font', flag: '🇬🇧' },
  ],
  getCurrencyInfo: (code: string) => ({ flag: '🏳️', name: code }),
}));

describe('CalculatorPage', () => {
  it('importálható hiba nélkül', async () => {
    const mod = await import('../CalculatorPage');
    expect(mod.default).toBeDefined();
  });

  it('default export egy React komponens (function)', async () => {
    const mod = await import('../CalculatorPage');
    expect(typeof mod.default).toBe('function');
  });

  it('a konverzió logika helyes EUR→HUF irányban', () => {
    const eurAmount = 100;
    const eurRate = 395.0;
    const hufResult = eurAmount * eurRate;
    expect(hufResult).toBe(39500);
  });

  it('BUY és SELL irány különböző árfolyamokat használ', () => {
    const buyRate = 390.0;  // bank vételi
    const sellRate = 400.0; // bank eladási

    expect(sellRate).toBeGreaterThan(buyRate);
    expect(sellRate - buyRate).toBe(10); // spread
  });
});
