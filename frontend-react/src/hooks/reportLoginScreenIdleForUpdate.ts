import type { ShiftState } from './useSuiteUpdate'
import { getElectronAPI } from '../utils/electron'
import { logger } from '../utils/logger'
import type { AppMode } from '../types/appMode'
import { CASHIER_APP_MODE } from '../types/appMode'
import { canonicalizeRoleForAppMode } from '../utils/appModeRoles'

/** SessionStorage: volt-e sikeres belépés ebben a renderer-folyamatban. */
export const HAD_AUTH_SESSION_KEY = 'valuta-suite-update-had-auth'

export function markAuthenticatedSession(): void {
  try {
    sessionStorage.setItem(HAD_AUTH_SESSION_KEY, '1')
  } catch {
    // sessionStorage nem elérhető (teszt / privát mód) — a hideg indítás IDLE marad.
  }
}

export function hasAuthenticatedSession(): boolean {
  try {
    return sessionStorage.getItem(HAD_AUTH_SESSION_KEY) === '1'
  } catch {
    return false
  }
}

/**
 * LocalStorage: az UTOLSÓ sikeres belépés kanonikus szerepe ezen a gépen.
 *
 * FKH-041 round 2 (D7/D8b): belépés ELŐTT nincs activeRole, ezért a telepítési
 * ablak bizonyítéka az, hogy ezen a gépen utoljára BIZONYÍTOTTAN pénztáros lépett
 * be. A marker localStorage-ban él (túléli a csendes telepítés okozta
 * folyamat-újraindítást is). Írási szemantika: kanonikus szerep tárolódik;
 * üres/ismeretlen szerep TÖRLI a kulcsot (elavult `penztar` marker nem maradhat
 * egy ismeretlen szerepű belépés után — az pontosan a javított lyukat nyitná újra).
 */
export const LAST_INSTALL_WINDOW_ROLE_KEY = 'valuta-suite-update-last-role'

export function rememberInstallWindowRole(roleCode: string | null | undefined): void {
  try {
    const canonical = canonicalizeRoleForAppMode(roleCode)
    if (!canonical) {
      localStorage.removeItem(LAST_INSTALL_WINDOW_ROLE_KEY)
      return
    }
    localStorage.setItem(LAST_INSTALL_WINDOW_ROLE_KEY, canonical)
  } catch {
    // localStorage nem elérhető (teszt / privát mód) — a fail-closed alapérték marad.
  }
}

/** Az utolsó sikeres belépés kanonikus szerepe; '' ha nincs marker / nem olvasható. */
export function readInstallWindowRole(): string {
  try {
    return localStorage.getItem(LAST_INSTALL_WINDOW_ROLE_KEY) ?? ''
  } catch {
    return ''
  }
}

/**
 * Belépőképernyő műszak-jelentése a suite-updaternek.
 *
 * Hideg indítás (még nem volt belépés): a telepítés belépés nélkül is
 * elindulhat — DE FKH-041 round 2 (D7) óta CSAK akkor, ha a gép utolsó sikeres
 * belépése BIZONYÍTOTTAN pénztáros volt (localStorage marker). Amíg ez nem
 * bizonyított, a döntés FAIL-CLOSED: `SHIFT_OPEN` (nincs IDLE_BEFORE_OPEN, nincs
 * csendes telepítés a bejelentkezés alatt — a riportáló terminál
 * `app_mode='penztar'` mellett futtat értéktárost, ott a round-1 appMode-only
 * szabály nem tüzelt). Logout után (már volt belépés): SHIFT_OPEN — ne telepítsen
 * nyitott nap közben (`hadAuth` továbbra is nyer a markerrel szemben, D14).
 *
 * Nem-pénztár módban SOHA nem IDLE (értéktár képernyőjén nincs pénztári nap-határ,
 * a hamis ablak csendes telepítést és app.quit()-et váltana ki a bejelentkezés
 * közben). `appMode = null` (default) a FKH-041 előtti szemantikát tartja — a
 * marker csak adott mód mellett él (back-compat a legacy 2-arg hívásokra), és a
 * boundary gate pontosan a lenti `hadAuth ? ...` ternary szöveget rögzíti.
 */
export async function reportLoginScreenIdleForUpdate(
  api: {
    suiteUpdate?: { setShiftState: (state: ShiftState) => Promise<unknown> }
  } | null = getElectronAPI(),
  hadAuth: boolean = hasAuthenticatedSession(),
  appMode: AppMode | null = null,
  lastInstallWindowRole: string = readInstallWindowRole(),
): Promise<ShiftState | null> {
  if (!api?.suiteUpdate) return null
  let next: ShiftState
  const lastCanonical = canonicalizeRoleForAppMode(lastInstallWindowRole)
  if (appMode != null && appMode !== CASHIER_APP_MODE) {
    // FKH-041 FR-3: nem-pénztár módban SOHA nem IDLE — nincs pénztári nap-határ.
    next = 'SHIFT_OPEN'
  } else if (appMode != null && lastCanonical !== 'penztar') {
    // FKH-041 round 2 (ITEM 1b): FAIL-CLOSED — penztar konfiguraciojú gépen sem nyitunk
    // telepítési ablakot, amíg nincs BIZONYÍTOTT pénztáros munkamenet ezen a gépen.
    next = 'SHIFT_OPEN'
    logger.warn(
      'SuiteUpdate',
      `Belepes elotti telepitesi ablak letiltva (FKH-041): appMode=${appMode}, utolso kanonikus szerep=${lastCanonical || 'ismeretlen'}`,
    )
  } else {
    // appMode = null: a FKH-041 előtti szemantika változatlan (boundary gate rögzíti).
    next = hadAuth ? 'SHIFT_OPEN' : 'IDLE_BEFORE_OPEN'
  }
  try {
    await api.suiteUpdate.setShiftState(next)
    return next
  } catch (error) {
    logger.warn('SuiteUpdate', 'Login műszak-állapot jelentése sikertelen', error)
    return null
  }
}
