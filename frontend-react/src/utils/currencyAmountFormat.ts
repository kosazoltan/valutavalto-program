import { roundHuf } from './rounding'

/**
 * FKH-065 (FR-5 / NFR-3): per-currency amount formatting for closing / denomination
 * screens.
 *
 * Two repo invariants are joined here so callers cannot drift apart again:
 *  - HUF is displayed after the statutory 5 Ft rounding ({@link roundHuf}, the mirror
 *    of the backend `HungarianRounding.roundToFive`), with 0 decimals.
 *  - JPY has no minor unit, so it is shown with 0 decimals — but it is NOT 5-rounded,
 *    the 5 Ft rule is HUF-only.
 * Every other currency keeps 2 decimals, matching `DenominationEntryPage`.
 */
const ZERO_DECIMAL_CURRENCIES = new Set(['HUF', 'JPY'])

export function currencyDecimals(currencyCode: string | null | undefined): number {
  return ZERO_DECIMAL_CURRENCIES.has((currencyCode ?? '').toUpperCase()) ? 0 : 2
}

/**
 * The amount as it is DISPLAYED, before formatting: HUF carries the statutory 5 Ft
 * rounding, every other currency is returned unchanged. Comparisons that drive a
 * displayed state (e.g. "matches" colouring) must use this, otherwise a rounded "0"
 * could be painted as a mismatch.
 */
export function displayedAmount(amount: number, currencyCode: string | null | undefined): number {
  return (currencyCode ?? '').toUpperCase() === 'HUF' ? roundHuf(amount) : amount
}

/**
 * Formats an amount for display. Returns an em dash for a missing value so a panel
 * can render "not loaded" without a separate branch at every call site.
 */
export function formatCurrencyAmount(
  amount: number | null | undefined,
  currencyCode: string | null | undefined,
): string {
  if (amount === null || amount === undefined || !Number.isFinite(amount)) {
    return '—'
  }
  const code = (currencyCode ?? '').toUpperCase()
  const value = displayedAmount(amount, code)
  const decimals = currencyDecimals(code)
  return value.toLocaleString('hu-HU', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  })
}
