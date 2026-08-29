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
 * Hideg indítás (még nem volt belépés): IDLE_BEFORE_OPEN — a telepítés
 * belépés nélkül is elindulhat.
 * Logout után (már volt belépés): SHIFT_OPEN — ne telepítsen nyitott nap közben.
 *
 * FKH-041 FR-3 / C6 (D7): ha a hívó appMode-ot ad, nem-pénztár módban SOHA nem
 * IDLE_BEFORE_OPEN (értéktár képernyőjén nincs pénztári nap-határ, a hamis ablak
 * csendes telepítést és app.quit()-et váltana ki a bejelentkezés közben).
 * `appMode = null` (default) a FKH-041 előtti szemantikát tartja — a boundary gate
 * pontosan a lenti `hadAuth ? ...` ternary szöveget rögzíti.
 */
export async function reportLoginScreenIdleForUpdate(
  api: {
    suiteUpdate?: { setShiftState: (state: ShiftState) => Promise<unknown> }
  } | null = getElectronAPI(),
  hadAuth: boolean = hasAuthenticatedSession(),
  appMode: AppMode | null = null,
): Promise<ShiftState | null> {
  if (!api?.suiteUpdate) return null
  let next: ShiftState
  if (appMode != null && appMode !== CASHIER_APP_MODE) {
    // FKH-041 FR-3: nem-pénztár módban SOHA nem IDLE — nincs pénztári nap-határ.
    next = 'SHIFT_OPEN'
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
