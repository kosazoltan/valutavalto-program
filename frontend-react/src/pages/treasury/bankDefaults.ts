// FK-005/C1 üzleti szabály: az értéktárak kizárólag a Raiffeisennel szerződnek, ezért a
// banki átadás célja minden esetben a Raiffeisen. Ez a helper a betöltött (területileg
// szűrt) Bank-törzsből kiválasztja a Raiffeisent alapértelmezettnek; ha nincs a listában,
// a kanonikus "Raiffeisen Bank" nevet adja vissza, hogy a mező sose maradjon üresen.

const RAIFFEISEN_CANONICAL = 'Raiffeisen Bank'

export function resolveDefaultBankName(banks: ReadonlyArray<{ name: string }>): string {
  const match = banks.find(b => b.name.toLowerCase().includes('raiffeisen'))
  return match?.name ?? RAIFFEISEN_CANONICAL
}
