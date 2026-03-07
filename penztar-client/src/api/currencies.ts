import apiClient from './client';

export interface CurrencyDto {
  id: number;
  code: string;
  name: string;
  symbol: string;
  decimals: number;
  displayOrder: number;
  active: boolean;
}

/**
 * Összes aktív valuta lekérdezése
 * GET /api/v1/currencies
 */
export async function getActiveCurrencies(): Promise<CurrencyDto[]> {
  const { data } = await apiClient.get<CurrencyDto[]>('/currencies');
  return data;
}

/**
 * Valuta keresése kód alapján
 * GET /api/v1/currencies/code/{code}
 */
export async function getCurrencyByCode(code: string): Promise<CurrencyDto> {
  const { data } = await apiClient.get<CurrencyDto>(`/currencies/code/${code}`);
  return data;
}

/**
 * Currency code → ID resolve helper
 */
export async function resolveCurrencyId(code: string): Promise<number> {
  const currency = await getCurrencyByCode(code);
  return currency.id;
}
