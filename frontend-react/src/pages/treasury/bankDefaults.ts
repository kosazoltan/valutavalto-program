// FK-005/C1 üzleti szabály: az értéktárak kizárólag a Raiffeisennel szerződnek, ezért a
// banki átadás célja minden esetben a Raiffeisen. Ez a helper a betöltött (területileg
// szűrt) Bank-törzsből kiválasztja a Raiffeisent alapértelmezettnek; ha nincs a listában,
// a kanonikus "Raiffeisen Bank" nevet adja vissza, hogy a mező sose maradjon üresen.

const RAIFFEISEN_CANONICAL = 'Raiffeisen Bank'

export function resolveDefaultBankName(
  banks: ReadonlyArray<{ name?: string | null }> | null | undefined,
): string {
  // Defenzív: az API alak-változása vagy hibás betöltés esetén se dobjon kivételt.
  const list = Array.isArray(banks) ? banks : []
  // Szigorú illesztés: a normalizált név a "raiffeisen"-nel KEZDŐDjön (nem véletlen
  // substring-egyezés), így a "...Raiffeisen..." nevű idegen bank nem aktiválódik.
  const match = list.find(
    b => typeof b?.name === 'string' && b.name.trim().toLowerCase().startsWith('raiffeisen'),
  )
  return match?.name?.trim() || RAIFFEISEN_CANONICAL
}
