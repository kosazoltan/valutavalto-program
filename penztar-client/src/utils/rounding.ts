/**
 * Magyar HUF kerekítés — a Delphi ATADVET modul logikája szerint.
 *
 * Szabály:
 *   utolsó számjegy 0-2  → lefelé kerekít (pl. 1001, 1002 → 1000)
 *   utolsó számjegy 3-7  → 5-re kerekít (pl. 1003-1007 → 1005)
 *   utolsó számjegy 8-9  → felfelé 10-re kerekít (pl. 1008, 1009 → 1010)
 */
export function roundHuf(amount: number): number {
  const lastDigit = Math.abs(Math.round(amount)) % 10;
  const base = Math.floor(Math.abs(Math.round(amount)) / 10) * 10;
  const sign = amount < 0 ? -1 : 1;

  let rounded: number;

  if (lastDigit <= 2) {
    // 0-2 → lefelé (base)
    rounded = base;
  } else if (lastDigit <= 7) {
    // 3-7 → 5-re
    rounded = base + 5;
  } else {
    // 8-9 → felfelé 10-re
    rounded = base + 10;
  }

  return rounded * sign;
}

/**
 * Kerekítési különbség kiszámítása
 */
export function roundingDiff(amount: number): number {
  return roundHuf(amount) - amount;
}
