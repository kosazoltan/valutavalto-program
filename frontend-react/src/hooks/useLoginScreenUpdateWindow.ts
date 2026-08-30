import { useEffect, useRef } from 'react'
import type { AppMode } from '../types/appMode'
import {
  reportLoginScreenIdleForUpdate,
  type LoginScreenActivity,
} from './reportLoginScreenIdleForUpdate'
import type { ShiftState } from './useSuiteUpdate'

/**
 * Belépőképernyő telepítési-ablak hook (Interface Adapter: React/DOM).
 *
 * MIÉRT KELL (Google-OTP hurok, 2026-08-30): a korábbi LoginPage-mount azonnal
 * IDLE_BEFORE_OPEN-t jelentett, a main process 10 s múlva READY-re váltott és
 * telepített + `app.quit()` — miközben a pénztáros a 2-3 perces Google OTP-t
 * várta. Ez a hook fordítja meg a szemantikát:
 *
 * - mount és bármely folyamatban lévő belépési lépés (`interactionInFlight`)
 *   alatt CSAK `'ACTIVE'` jelentés megy (fail-closed: soha nem telepíthető);
 * - `'IDLE_TIMEOUT'` jelentés CSAK mért tétlenség után (`LOGIN_IDLE_TIMEOUT_MS`
 *   felhasználói input nélkül, futó belépési lépés nélkül);
 * - bármilyen input, interakció-átváltás vagy unmount (sikeres belépés) után
 *   azonnal újra `'ACTIVE'` — a main process átmenet-alapon működik
 *   (suite-update.ts:404-413), ezért az IDLE -> SHIFT_OPEN újrjelentés KELL
 *   a már megnyitott ablak bezárásához (nem „optimalizálható ki", lásd G9/G4).
 *
 * Web-böngészőben no-op: `reportLoginScreenIdleForUpdate` ott `null`-t ad
 * (`getElectronAPI() === null`), a hook csendben hallgat.
 */
export const LOGIN_IDLE_TIMEOUT_MS = 120_000

export function useLoginScreenUpdateWindow(params: {
  appMode: AppMode | null
  appModeLoading: boolean
  /** true, amíg BÁRMILYEN belépési lépés fut (Google OAuth, MFA, szerep-/mód-választó, ...). */
  interactionInFlight: boolean
  idleTimeoutMs?: number
}): void {
  const {
    appMode,
    appModeLoading,
    interactionInFlight,
    idleTimeoutMs = LOGIN_IDLE_TIMEOUT_MS,
  } = params
  // A main process átmenet-alapon jelent (suite-update.ts:404-413): az azonos
  // állapot újraküldése ott no-op. A ref az IDLE -> SHIFT_OPEN visszaváltást
  // vezérli (csak akkor jelentünk inputra, ha tényleg IDLE-t jelentettünk).
  const lastReportedRef = useRef<ShiftState | null>(null)

  useEffect(() => {
    // FKH-041 D8 guard: amíg az appMode nem oldódott fel, NEM jelentünk
    // (a main process alapértelmezése úgyis SHIFT_OPEN).
    if (appModeLoading) return undefined

    let timerId: number | undefined

    const report = (activity: LoginScreenActivity): void => {
      // A defaults (hadAuth, szerep-marker, nyitottnap-marker) itt a storage-ból
      // oldódnak fel — a hook csak a deklaratív állapotot adja át.
      void reportLoginScreenIdleForUpdate(undefined, undefined, appMode, undefined, activity).then(
        (state) => {
          if (state != null) lastReportedRef.current = state
        },
      )
    }

    const armTimer = (): void => {
      timerId = window.setTimeout(() => report('IDLE_TIMEOUT'), idleTimeoutMs)
    }

    const onUserInput = (): void => {
      // Input -> időzítő újraindítása (a tétlenség most kezdődik újra).
      if (timerId !== undefined) window.clearTimeout(timerId)
      armTimer()
      // Ha az utolsó jelentés IDLE_BEFORE_OPEN volt, azonnal be kell zárni az
      // ablakot (átmenet a main process felé) — különben a következő READY
      // átmenet telepítene.
      if (lastReportedRef.current === 'IDLE_BEFORE_OPEN') report('ACTIVE')
    }

    // Mount / (újra)futás: aktív képernyő jelentése azonnal.
    report('ACTIVE')

    if (!interactionInFlight) {
      armTimer()
      window.addEventListener('keydown', onUserInput, { passive: true })
      window.addEventListener('pointerdown', onUserInput, { passive: true })
      window.addEventListener('wheel', onUserInput, { passive: true })
      window.addEventListener('touchstart', onUserInput, { passive: true })
    }

    return () => {
      if (timerId !== undefined) window.clearTimeout(timerId)
      window.removeEventListener('keydown', onUserInput)
      window.removeEventListener('pointerdown', onUserInput)
      window.removeEventListener('wheel', onUserInput)
      window.removeEventListener('touchstart', onUserInput)
      // Unmount = a felhasználó bejutott (vagy a képernyőt lecserélték) ->
      // a telepítési ablak bezárása. Ezt a jelentést NEM szabad kihagyni.
      report('ACTIVE')
    }
  }, [appMode, appModeLoading, interactionInFlight, idleTimeoutMs])
}
