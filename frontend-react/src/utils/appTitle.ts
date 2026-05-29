/**
 * v2.5.54 #6/#20 — ablak-cím a kliens build-time flavor-ja szerint.
 *
 * Eddig mind a 3 Electron-kliens (pénztár / központi / árfolyamkészítő) ugyanazt a
 * `frontend-react` buildet tölti, és az Electron-ablak címe a betöltött HTML
 * `document.title`-jét követi → mindenhol „Valuta Pénztári Rendszer - Best Change"
 * jelent meg (megkülönböztethetetlen ablakok). A `VITE_APP_FLAVOR` build-time változó
 * alapján flavoronként eltérő címet adunk, így a tálcán/ablakváltón elkülönülnek.
 */

const SUFFIX = 'Best Change'

/** A flavor-hoz tartozó ablak-cím. Ismeretlen/üres flavor → pénztár (alapértelmezett). */
export function appTitleForFlavor(flavor: string | undefined | null): string {
  switch (flavor) {
    case 'rate-maker':
      return `Árfolyam Készítő — ${SUFFIX}`
    case 'central-workstation':
      return `Központi Munkaállomás — ${SUFFIX}`
    default:
      return `Valuta Pénztár — ${SUFFIX}`
  }
}
