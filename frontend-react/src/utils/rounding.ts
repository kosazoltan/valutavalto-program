/**
 * Magyar HUF kerekítés — 5 Ft-ra kerekítés az MNB szabályozás szerint.
 *
 * Szabály (utolsó számjegy alapján):
 *   0, 5       → marad
 *   1, 2       → lefelé 0-ra  (pl. 1001, 1002 → 1000)
 *   3, 4       → felfelé 5-re (pl. 1003, 1004 → 1005)
 *   6, 7       → lefelé 5-re  (pl. 1006, 1007 → 1005)
 *   8, 9       → felfelé 10-re (pl. 1008, 1009 → 1010)
 *
 * Negatív számok: az abszolút értékre alkalmazzuk, majd visszaadjuk az előjelet.
 * Ez a backend HungarianRounding.roundToFive(long) logikájával ekvivalens.
 *
 * Példák:  1233 → 1235,  -1233 → -1235,  1001 → 1000,  -1008 → -1010
 */
export function roundHuf(amount: number): number {
  const abs = Math.abs(Math.round(amount))
  const lastDigit = abs % 10
  const base = abs - lastDigit

  let rounded: number

  if (lastDigit <= 2) {
    rounded = base
  } else if (lastDigit <= 7) {
    rounded = base + 5
  } else {
    rounded = base + 10
  }

  return amount < 0 ? -rounded : rounded
}
