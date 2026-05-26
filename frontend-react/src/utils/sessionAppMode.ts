import { isAppMode } from '../types/appMode'
import type { AppMode } from '../types/appMode'

/**
 * HIBA 2026-05-26 (mód-választó): a belépés után választott program-mód (pénztár /
 * értéktár / …) session-szintű felülírása. A telepítéskor rögzített `app_mode` config
 * marad a default; ez az override CSAK a futó munkamenetre érvényes (kijelentkezéskor /
 * app-újraindításkor törlődik), és a {@link useAppMode} elsőbbséggel olvassa.
 */
const SESSION_APP_MODE_KEY = 'vv_session_app_mode'

export function getSessionAppMode(): AppMode | null {
  try {
    const v = sessionStorage.getItem(SESSION_APP_MODE_KEY)
    return isAppMode(v) ? v : null
  } catch {
    return null
  }
}

export function setSessionAppMode(mode: AppMode): void {
  try {
    sessionStorage.setItem(SESSION_APP_MODE_KEY, mode)
  } catch {
    // sessionStorage nem elérhető (pl. SSR/teszt) — csendben kihagyjuk
  }
}

export function clearSessionAppMode(): void {
  try {
    sessionStorage.removeItem(SESSION_APP_MODE_KEY)
  } catch {
    // no-op
  }
}
