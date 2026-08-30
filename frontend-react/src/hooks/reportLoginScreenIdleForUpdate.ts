import type { ShiftState } from './useSuiteUpdate'
import { getElectronAPI } from '../utils/electron'
import { logger } from '../utils/logger'
import type { AppMode } from '../types/appMode'
import { CASHIER_APP_MODE } from '../types/appMode'
import { canonicalizeRoleForAppMode } from '../utils/appModeRoles'
import { hasOpenDayObservedToday } from '../utils/openDayMarker'

/** SessionStorage: volt-e sikeres belépés ebben a renderer-folyamatban. */
export const HAD_AUTH_SESSION_KEY = 'valuta-suite-update-had-auth'

export function markAuthenticatedSession(): void {
  try {
    sessionStorage.setItem(HAD_AUTH_SESSION_KEY, '1')
  } catch {
    // sessionStorage nem elérhető (teszt / privát mód) — a hideg indítás ACTIVE marad.
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
 * A belépőképernyő aktivitási állapota a suite-updater szempontjából.
 *
 * `'ACTIVE'`: BELÉPÉS FOLYAMATBAN / aktív képernyő (mount, bármely belépési
 * lépés — Google OAuth/OTP, MFA, szerep-/mód-választó —, friss felhasználói
 * bevitel). `'IDLE_TIMEOUT'`: MÉRT tétlenség (nincs folyamatban lévő lépés,
 * nincs input a küszöb óta) — EZ AZ EGYETLEN ág, amely IDLE_BEFORE_OPEN-hez
 * vezethet, és azt is csak a többi szabály engedélyével.
 */
export type LoginScreenActivity = 'ACTIVE' | 'IDLE_TIMEOUT'

/**
 * Belépőképernyő műszak-döntése a suite-updaternek — tiszta függvény (Application
 * policy, nincs I/O), ezért DOM/IPC nélkül unit-tesztelhető.
 *
 * Szabálysorrend (első egyezés nyer; az első négy szabály mind `SHIFT_OPEN`,
 * így a sorrend kimenetet nem változtat, de a FKH-041 diagnosztikai log megmarad):
 *
 * 1. Nem-pénztár appMode -> SHIFT_OPEN (FKH-041 FR-3).
 * 2. Pénztár appMode, de a gép utolsó bizonyított szerepe nem `penztar`
 *    -> SHIFT_OPEN + warn (FKH-041 round 2, fail-closed).
 * 3. ACTIVE (belépés folyamatban / aktív képernyő) -> SHIFT_OPEN. Ez öli meg a
 *    Google-OTP hurkot: a 2-3 perces out-of-process OAuth alatt a gép sosem IDLE.
 * 4. Ma megfigyelt nyitott nap -> SHIFT_OPEN. Nem hazudjuk, hogy „a nap még nem
 *    indult el", ha a hitelesített munkamenet ma már látott `Nap nyitva`-t (C3) —
 *    és ehhez NEM kell autentikálatlan `/daily-sessions/is-open` hívás (AC-5).
 * 5. A fail-safe ternár (boundary gate rögzíti szövegesen): logout -> SHIFT_OPEN,
 *    egyébként IDLE_BEFORE_OPEN.
 */
export function decideLoginScreenShiftState(input: {
  hadAuth: boolean
  appMode: AppMode | null
  lastInstallWindowRole: string
  activity: LoginScreenActivity
  openDayObservedToday: boolean
}): ShiftState {
  const { hadAuth, appMode, lastInstallWindowRole, activity, openDayObservedToday } = input
  if (appMode != null && appMode !== CASHIER_APP_MODE) {
    // FKH-041 FR-3: nem-pénztár módban SOHA nem IDLE — nincs pénztári nap-határ.
    return 'SHIFT_OPEN'
  }
  const lastCanonical = canonicalizeRoleForAppMode(lastInstallWindowRole)
  if (appMode != null && lastCanonical !== 'penztar') {
    // FKH-041 round 2 (ITEM 1b): FAIL-CLOSED — penztar konfiguraciojú gépen sem nyitunk
    // telepítési ablakot, amíg nincs BIZONYÍTOTT pénztáros munkamenet ezen a gépen.
    logger.warn(
      'SuiteUpdate',
      `Belepes elotti telepitesi ablak letiltva (FKH-041): appMode=${appMode}, utolso kanonikus szerep=${lastCanonical || 'ismeretlen'}`,
    )
    return 'SHIFT_OPEN'
  }
  if (activity === 'ACTIVE') {
    logger.info('SuiteUpdate', 'Belepes folyamatban / aktiv belepokepernyo -> SHIFT_OPEN')
    return 'SHIFT_OPEN'
  }
  if (openDayObservedToday) {
    logger.warn(
      'SuiteUpdate',
      'Telepitesi ablak letiltva: a mai nap mar nyitott volt (hitelesitett munkamenetben megfigyelt nyitott nap) -> SHIFT_OPEN',
    )
    return 'SHIFT_OPEN'
  }
  // appMode = null: a FKH-041 előtti szemantika változatlan (boundary gate rögzíti).
  return hadAuth ? 'SHIFT_OPEN' : 'IDLE_BEFORE_OPEN'
}

/**
 * Belépőképernyő műszak-jelentése a suite-updaternek.
 *
 * ÚJ SZERZŐDÉS (Google-OTP hurok, 2026-08-30): a belépőképernyő MOUNTJA SOHA nem
 * telepíthető — mountkor és bármely folyamatban lévő belépési lépés alatt
 * (Google OAuth/OTP 2-3 perce, MFA, szerep-/mód-választó) `SHIFT_OPEN` megy.
 * `IDLE_BEFORE_OPEN` CSAK mért idle-timeout után (`'IDLE_TIMEOUT'` aktivitás,
 * lásd `useLoginScreenUpdateWindow`) ÉS csak akkor, ha a mai napra nincs
 * megfigyelt nyitott nap (nyitottnap-marker) és nem volt még belépés sem.
 *
 * Az `activity` paraméter defaultja FAIL-CLOSED `'ACTIVE'`: bármely legacy /
 * 2-arg hívás ezért `SHIFT_OPEN`-t jelent — az egyetlen hívó, amely tétlenséget
 * állíthat, az, aki TÉNYLEGESEN mérte is.
 *
 * Nem-pénztár módban SOHA nem IDLE (FKH-041 FR-3). `appMode = null` (default)
 * esetén a marker-szabály nem él (back-compat a legacy hívásokra), de az
 * activity-szabály ott is elsőbbséget élvez; a boundary gate pontosan a lenti
 * `hadAuth ? ...` ternary szöveget rögzíti.
 */
export async function reportLoginScreenIdleForUpdate(
  api: {
    suiteUpdate?: { setShiftState: (state: ShiftState) => Promise<unknown> }
  } | null = getElectronAPI(),
  hadAuth: boolean = hasAuthenticatedSession(),
  appMode: AppMode | null = null,
  lastInstallWindowRole: string = readInstallWindowRole(),
  activity: LoginScreenActivity = 'ACTIVE',
  openDayObservedToday: boolean = hasOpenDayObservedToday(),
): Promise<ShiftState | null> {
  if (!api?.suiteUpdate) return null
  const next = decideLoginScreenShiftState({
    hadAuth,
    appMode,
    lastInstallWindowRole,
    activity,
    openDayObservedToday,
  })
  try {
    await api.suiteUpdate.setShiftState(next)
    return next
  } catch (error) {
    logger.warn('SuiteUpdate', 'Login műszak-állapot jelentése sikertelen', error)
    return null
  }
}
