import type { AppMode } from '../types/appMode'

/**
 * Kliens-környezet detektálás egyetlen forrásból (Sourcery #860: a korábban
 * LoginPage / App / useAppMode között szétszórt `window.electronAPI` + `VITE_APP_FLAVOR`
 * vizsgálatokat itt egységesítjük, hogy a kliensek között ne csússzon szét a logika).
 *
 * - flavor `''` (üres)        → penztar-client (lokál terminál: penztar/ertektar/ertekszallito)
 * - flavor `central-workstation` → Kozponti munkaállomás (full mód)
 * - flavor `rate-maker`       → Árfolyamkészítő
 */

export type AppFlavor = '' | 'central-workstation' | 'rate-maker'

/** A build-időben rögzített kliens-flavor (trimmelt). Böngészőben üres. */
export function getAppFlavor(): AppFlavor {
  const raw = String(import.meta.env.VITE_APP_FLAVOR ?? '').trim()
  if (raw === 'central-workstation' || raw === 'rate-maker') return raw
  return ''
}

/** Igaz, ha Electron-kliensben futunk (a preload kitette a `window.electronAPI`-t). */
export function isElectronClient(): boolean {
  return typeof window !== 'undefined' && window.electronAPI != null
}

/**
 * Lokál terminál = penztar-client (Electron + nincs flavor). Csak itt ajánlunk
 * belépés utáni program-mód választót; a böngésző (full) és a kozponti/rate-maker
 * flavor-buildek mást csomagolnak.
 */
export function isLocalTerminalClient(): boolean {
  return isElectronClient() && getAppFlavor() === ''
}

export function isCentralWorkstationFlavor(): boolean {
  return getAppFlavor() === 'central-workstation'
}

export function isRateMakerFlavor(): boolean {
  return getAppFlavor() === 'rate-maker'
}

/** A flavor által diktált, role-független kezdő appMode (ha a flavor egyértelmű). */
export function flavorDefaultAppMode(): AppMode | null {
  const flavor = getAppFlavor()
  if (flavor === 'central-workstation') return 'full'
  if (flavor === 'rate-maker') return 'rate-maker'
  return null
}
