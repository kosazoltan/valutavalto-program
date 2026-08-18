/**
 * Lokális dátum-formázás (YYYY-MM-DD) — időzóna-biztos.
 *
 * A `Date.prototype.toISOString().slice(0, 10)` UTC-re konvertál, ezért magyar
 * idő (CEST/CET) szerint éjfél körül az ELŐZŐ napot adhatja vissza — pl. 2026-05-20
 * 01:30 CEST → "2026-05-19". Riport default dátumtartományoknál ez hibás kezdő/záró
 * dátumot eredményez. Ez a helper a lokális naptári napot adja vissza.
 *
 * @param d a formázandó dátum (alapértelmezés: most)
 * @returns YYYY-MM-DD a futtató gép lokális időzónája szerint
 */
export function localIsoDate(d: Date = new Date()): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

/**
 * ISO naptári nap (YYYY-MM-DD) formai ellenőrzése — üres/rossz bemenet kiszűrésére.
 * Rögzített szélességű minták (a '2026-5-2' NEM ISO). Whitespace-t trimmel.
 */
export function isIsoDate(value: string | null | undefined): boolean {
  return typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value.trim())
}

/**
 * ISO dátum (YYYY-MM-DD) → magyar pontozott forma (YYYY.MM.DD.) — időzóna-biztos.
 *
 * Az érték mindig `<input type="date">`-ből / állapothoz kötött ISO stringből jön,
 * ezért NEM Date-objektum round-trippel, hanem egyszerű `-` mentén darabolással
 * alakítjuk (így nem csúszhat el időzóna szerint). Pl. "2026-05-22" → "2026.05.22.".
 *
 * A-6 (pótlás d5753273): üres/rossz bemenetnél `''` — sosem `undefined`-es szöveg.
 * „Ma"-fallback SZÁNDÉKOSAN nincs (az B-opció lenne).
 *
 * @param isoDate YYYY-MM-DD formátumú dátum
 * @returns YYYY.MM.DD. pontozott magyar dátum, rossz bemenetnél ''
 */
export function formatHuDate(isoDate: string): string {
  if (!isIsoDate(isoDate)) return ''
  const [y, m, d] = isoDate.trim().split('-')
  return `${y}.${m}.${d}.`
}
