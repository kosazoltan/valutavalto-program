import type { ShiftState } from './useSuiteUpdate'
import { getElectronAPI } from '../utils/electron'
import { logger } from '../utils/logger'

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
 */
export async function reportLoginScreenIdleForUpdate(
  api: {
    suiteUpdate?: { setShiftState: (state: ShiftState) => Promise<unknown> }
  } | null = getElectronAPI(),
  hadAuth: boolean = hasAuthenticatedSession(),
): Promise<ShiftState | null> {
  if (!api?.suiteUpdate) return null
  const next: ShiftState = hadAuth ? 'SHIFT_OPEN' : 'IDLE_BEFORE_OPEN'
  try {
    await api.suiteUpdate.setShiftState(next)
    return next
  } catch (error) {
    logger.warn('SuiteUpdate', 'Login műszak-állapot jelentése sikertelen', error)
    return null
  }
}
