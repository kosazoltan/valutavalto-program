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
