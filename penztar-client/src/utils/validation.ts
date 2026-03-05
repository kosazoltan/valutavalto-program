/**
 * AML (Anti Money Laundering) limit validáció.
 *
 * Magyar jogszabály:
 *   300.000 HUF felett: ügyfél azonosítás KÖTELEZŐ
 *   1.000.000 HUF felett: bejelentés KÖTELEZŐ (NAV)
 */

/** Ügyfél azonosítási limit HUF-ban */
export const AML_IDENTIFICATION_LIMIT = 300_000;

/** Bejelentési limit HUF-ban */
export const AML_REPORTING_LIMIT = 1_000_000;

export interface AmlCheckResult {
  requiresIdentification: boolean;
  requiresReporting: boolean;
  hufAmount: number;
}

/**
 * AML limit ellenőrzés.
 * @param hufAmount - A tranzakció forint értéke (kerekítés előtt)
 */
export function checkAmlLimits(hufAmount: number): AmlCheckResult {
  const absAmount = Math.abs(hufAmount);
  return {
    requiresIdentification: absAmount >= AML_IDENTIFICATION_LIMIT,
    requiresReporting: absAmount >= AML_REPORTING_LIMIT,
    hufAmount: absAmount,
  };
}

/**
 * Ellenőrzi, hogy egy tranzakció végrehajtható-e ügyfél azonosítás nélkül.
 */
export function canProceedWithoutCustomer(hufAmount: number): boolean {
  return Math.abs(hufAmount) < AML_IDENTIFICATION_LIMIT;
}
