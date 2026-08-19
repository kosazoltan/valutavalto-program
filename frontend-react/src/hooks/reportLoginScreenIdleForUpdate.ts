import type { ShiftState } from './useSuiteUpdate'
import { getElectronAPI } from '../utils/electron'
import { logger } from '../utils/logger'

/**
 * A belépőképernyőn még nincs műszak — a suite-updater alapból SHIFT_OPEN-t
 * feltételez, amíg a MainLayout (bejelentkezés UTÁN) nem jelent. Ha a kolléga
 * nem tud belépni, a telepítés soha nem indul. A login ezért IDLE_BEFORE_OPEN-t
 * jelent: a kész frissítés belépés nélkül is települhet.
 */
export async function reportLoginScreenIdleForUpdate(
  api: {
    suiteUpdate?: { setShiftState: (state: ShiftState) => Promise<unknown> }
  } | null = getElectronAPI(),
): Promise<boolean> {
  if (!api?.suiteUpdate) return false
  try {
    await api.suiteUpdate.setShiftState('IDLE_BEFORE_OPEN')
    return true
  } catch (error) {
    logger.warn('SuiteUpdate', 'Login IDLE_BEFORE_OPEN jelentése sikertelen', error)
    return false
  }
}
