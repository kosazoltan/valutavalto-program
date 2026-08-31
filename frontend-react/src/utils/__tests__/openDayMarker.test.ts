/**
 * openDayMarker — a HITELESÍTETT munkamenet által megfigyelt NYITOTT nap
 * helyi nap-kulcsú markere (C3 / AC-4).
 *
 * MIÉRT KELL: a belépőképernyő jelentése nem állíthatja, hogy „a nap még nem
 * indult el" (IDLE_BEFORE_OPEN), ha ezen a gépen ma már megfigyeltek nyitott
 * napot hitelesített munkamenetben — de éjfél után (helyi idő szerint) az
 * éjszakai telepítési ablakot sem szabad tovább blokkolni (AC-4). A helyi
 * nap-kulcs szemantikáját ezek az esetek rögzítik.
 */
import { describe, it, expect, beforeEach } from 'vitest'
import {
  OPEN_DAY_OBSERVED_KEY,
  localDayKey,
  rememberOpenDayObservation,
  clearOpenDayObservation,
  hasOpenDayObservedToday,
} from '../openDayMarker'

describe('openDayMarker — helyi nap-kulcsú marker', () => {
  beforeEach(() => {
    sessionStorage.clear()
    localStorage.clear()
  })

  it('M1: localDayKey helyi idő alapú (nem UTC/ISO)', () => {
    expect(localDayKey(new Date(2026, 7, 30, 15, 44))).toBe('2026-08-30')
  })

  it('M2: rememberOpenDayObservation a mai helyi nap kulcsát tárolja', () => {
    rememberOpenDayObservation(new Date(2026, 7, 30, 15, 44))
    expect(localStorage.getItem(OPEN_DAY_OBSERVED_KEY)).toBe('2026-08-30')
  })

  it('M3: hasOpenDayObservedToday -> true, ha ugyanazon a napon történt az írás', () => {
    const d = new Date(2026, 7, 30, 15, 44)
    rememberOpenDayObservation(d)
    expect(hasOpenDayObservedToday(d)).toBe(true)
  })

  it('M4: helyi éjféli átbillenés -> false (az éjszakai telepítési ablak megnyílik)', () => {
    rememberOpenDayObservation(new Date(2026, 7, 30, 23, 30))
    expect(hasOpenDayObservedToday(new Date(2026, 7, 31, 0, 5))).toBe(false)
  })

  it('M5: írás nélkül -> false', () => {
    expect(hasOpenDayObservedToday()).toBe(false)
  })

  it('M6: clearOpenDayObservation törli a kulcsot', () => {
    rememberOpenDayObservation()
    clearOpenDayObservation()
    expect(hasOpenDayObservedToday()).toBe(false)
    expect(localStorage.getItem(OPEN_DAY_OBSERVED_KEY)).toBeNull()
  })
})
