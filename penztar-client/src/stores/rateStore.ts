import { create } from 'zustand';
import type { ExchangeRate, CurrencyCode } from '@/types';
import { getCurrentRates } from '@/api/rates';

interface RateState {
  rates: ExchangeRate[];
  lastUpdate: string | null;
  isLoading: boolean;
  error: string | null;

  fetchRates: () => Promise<void>;
  getRate: (currencyCode: CurrencyCode) => ExchangeRate | undefined;
  getBuyRate: (currencyCode: CurrencyCode) => number;
  getSellRate: (currencyCode: CurrencyCode) => number;
}

export const useRateStore = create<RateState>((set, get) => ({
  rates: [],
  lastUpdate: null,
  isLoading: false,
  error: null,

  fetchRates: async () => {
    set({ isLoading: true, error: null });
    try {
      const rates = await getCurrentRates();
      set({
        rates,
        lastUpdate: new Date().toISOString(),
        isLoading: false,
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Árfolyam lekérési hiba';
      set({ error: message, isLoading: false });
    }
  },

  getRate: (currencyCode) => {
    return get().rates.find((r) => r.currencyCode === currencyCode);
  },

  getBuyRate: (currencyCode) => {
    const rate = get().getRate(currencyCode);
    return rate?.buyRate ?? 0;
  },

  getSellRate: (currencyCode) => {
    const rate = get().getRate(currencyCode);
    return rate?.sellRate ?? 0;
  },
}));
