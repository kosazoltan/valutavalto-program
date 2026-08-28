import type { ShiftState } from './useSuiteUpdate'
import { getElectronAPI } from '../utils/electron'
import { logger } from '../utils/logger'
import type { AppMode } from '../types/appMode'
import { CASHIER_APP_MODE } from '../types/appMode'

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
