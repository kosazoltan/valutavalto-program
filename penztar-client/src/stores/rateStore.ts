import { create } from 'zustand';
import type { ExchangeRate, CurrencyCode } from '@/types';
import { getCurrentRates } from '@/api/rates';

interface RateState {
  rates: ExchangeRate[];
  lastUpdate: string | null;
  isLoading: boolean;
  error: string | null;
  autoRefreshIntervalId: ReturnType<typeof setInterval> | null;

  fetchRates: () => Promise<void>;
  applyPublishedRates: (updates: Array<{ currencyCode?: string; buyRate: number | string; sellRate: number | string }>) => void;
  getRate: (currencyCode: CurrencyCode) => ExchangeRate | undefined;
  getBuyRate: (currencyCode: CurrencyCode) => number;
  getSellRate: (currencyCode: CurrencyCode) => number;
  updateRatesFromSync: (rates: ExchangeRate[]) => void;
  startAutoRefresh: (intervalMs?: number) => void;
  stopAutoRefresh: () => void;
}

/**
 * Árfolyam store — a pénztár kliens árfolyam kezelése.
 *
 * Legacy: a régi rendszerben az értéktár FTP-n küldte ki az árfolyamokat
 * (NR*.DAT fájlok) és a pénztár letöltötte + a helyi ARFOLYAM táblába
 * mentette. Az új rendszerben REST API-n keresztül kéri le és
 * WebSocket-en kapja az azonnali frissítéseket.
 */
export const useRateStore = create<RateState>((set, get) => ({
  rates: [],
  lastUpdate: null,
  isLoading: false,
  error: null,
  autoRefreshIntervalId: null,

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

  applyPublishedRates: (updates) => {
    if (!updates.length) {
      return;
    }

    const now = new Date().toISOString();
    const currentRates = get().rates;
    const nextByCode = new Map(currentRates.map((rate) => [rate.currencyCode, rate]));

    for (const update of updates) {
      const code = update.currencyCode as CurrencyCode | undefined;
      if (!code) {
        continue;
      }

      const current = nextByCode.get(code);
      const parsedBuy = Number(update.buyRate);
      const parsedSell = Number(update.sellRate);

      const buyRate = Number.isFinite(parsedBuy) ? parsedBuy : current?.buyRate ?? 0;
      const sellRate = Number.isFinite(parsedSell) ? parsedSell : current?.sellRate ?? 0;

      nextByCode.set(code, {
        currencyCode: code,
        buyRate,
        sellRate,
        unit: current?.unit ?? 1,
        updatedAt: now,
      });
    }

    const nextRates: ExchangeRate[] = [];
    for (const rate of currentRates) {
      const updated = nextByCode.get(rate.currencyCode);
      if (updated) {
        nextRates.push(updated);
        nextByCode.delete(rate.currencyCode);
      }
    }

    for (const extra of nextByCode.values()) {
      nextRates.push(extra);
    }

    set({ rates: nextRates, lastUpdate: now, error: null });
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

  /**
   * Árfolyamok frissítése szinkronizációból (SyncEngine által hívva).
   * Nem szükséges API hívás, közvetlenül frissíti a store-t.
   */
  updateRatesFromSync: (rates) => {
    set({
      rates,
      lastUpdate: new Date().toISOString(),
      error: null,
    });
  },

  /**
   * Automatikus árfolyam frissítés indítása.
   * Az SyncEngine 30 másodpercenként szinkronizálja az árfolyamokat,
   * de a UI-ban is biztosítjuk a frissítést.
   */
  startAutoRefresh: (intervalMs = 60_000) => {
    const existing = get().autoRefreshIntervalId;
    if (existing) clearInterval(existing);

    // Első lekérés azonnal
    get().fetchRates();

    const id = setInterval(() => {
      get().fetchRates();
    }, intervalMs);

    set({ autoRefreshIntervalId: id });
  },

  stopAutoRefresh: () => {
    const id = get().autoRefreshIntervalId;
    if (id) {
      clearInterval(id);
      set({ autoRefreshIntervalId: null });
    }
  },
}));
