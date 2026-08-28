import { useCallback, useEffect, useRef, useState } from 'react'
import { dailySessionApi } from '../services/api/index'
import { isElectron, getElectronAPI } from '../utils/electron'
import { logger } from '../utils/logger'
import { useAppMode } from './useAppMode'
import { CASHIER_APP_MODE } from '../types/appMode'

/**
 * A pénztárgép munkafolyamat-állapota a suite-frissítés szempontjából.
 *
 * A main process (`penztar-client/electron/suite-update.ts`) ezt az értéket használja
 * annak eldöntésére, hogy a már letöltött és ellenőrzött frissítés TELEPÍTHETŐ-e:
 * telepítés kizárólag `IDLE_BEFORE_OPEN` vagy `CLOSED_AFTER_DAY_END` állapotban indul.
 *
 * Szerződés: `docs/auto-update-terv-es-vegrehajtas.md` 3.6 szakasz.
 */
export type ShiftState = 'IDLE_BEFORE_OPEN' | 'SHIFT_OPEN' | 'CLOSED_AFTER_DAY_END'

/** A main processből kapott "frissítés készen áll" jelzés. */
export type SuiteUpdateReady = {
  version: string
  mandatory: boolean
  notes: string | null
  installableNow: boolean
}

/** Milyen gyakran jelentjük újra az állapotot (a napzárás közben is friss legyen). */
const REPORT_INTERVAL_MS = 60 * 1000

/**
 * A napi munkamenet állapotát ShiftState-re képezi.
 *
 * FONTOS — a leképezés KONZERVATÍV: ha az állapot bármilyen okból nem
 * megállapítható (backend nem elérhető, hibás válasz), `SHIFT_OPEN`-t adunk vissza,
 * mert az a "nem telepíthető" ág. Így egy hálózati hiba SOSEM okozhat munka közbeni
 * telepítést. Ugyanez a fail-safe a main processben is megvan (kettős védelem).
 */
export function mapSessionToShiftState(
  session: {
    status?: 'OPEN' | 'CLOSED'
    closedAt?: string
  } | null,
): ShiftState {
  if (!session) {
    // Nincs mai munkamenet -> a nap még nem indult el, biztonságos telepíteni.
    return 'IDLE_BEFORE_OPEN'
  }
  if (session.status === 'CLOSED') {
    // A napzárás lezárult -> telepíthető.
    return 'CLOSED_AFTER_DAY_END'
  }
  // OPEN vagy ismeretlen status -> nyitott műszakként kezeljük (nem telepítünk).
  return 'SHIFT_OPEN'
}

/**
 * Jelenti a műszak-állapotot a main processnek, és fogadja a "frissítés készen áll"
 * jelzést.
 *
 * MIÉRT A RENDERER JELENTI: csak itt (illetve a backendben) tudható, hogy van-e
 * nyitott napi munkamenet — a main process ezt nem látja. A jelentés
 * állapotváltáskor és percenként is megtörténik, mert a telepítés kiváltója az
 * ÁLLAPOTÁTMENET (napzárás lezárása vagy napnyitás előtti állapot), nem egy időzítő.
 *
 * FKH-041 FR-3 (D5/D6): nem-pénztár módban a renderer KONZERVATÍVAN `SHIFT_OPEN`-t
 * jelent. Indoklás: az értéktár munkafolyamatnak nincs pénztári nap-határa, ezért
 * nincs detektálhatóan biztonságos telepítési ablak — az `IDLE_BEFORE_OPEN` hamis
 * ablakot nyitna (a main process `maybeOfferInstall` -> csendes telepítés ->
 * `app.quit()` ~1 mp múlva, ami megszakította a bejelentkezést). Ez a kompromisszum
 * ELFOGADOTT: az értéktár terminál sosem auto-telepít, a manuális telepítő
 * (Penztar-Setup) marad az út. NE „javítsd vissza" a main processben — a fő folyamat
 * telepítési kapuja a renderer jelentésétől függetlenül is fail-safe
 * (alapértelmezés és ismeretlen érték egyaránt `SHIFT_OPEN`).
 *
 * Web-böngészőben (nem Electron) no-op: nincs mit frissíteni.
 */
export function useSuiteUpdate(): {
  shiftState: ShiftState | null
  readyUpdate: SuiteUpdateReady | null
} {
  const [shiftState, setShiftState] = useState<ShiftState | null>(null)
  const [readyUpdate, setReadyUpdate] = useState<SuiteUpdateReady | null>(null)
  const lastReportedRef = useRef<ShiftState | null>(null)
  // D6: a hook zéró-argumentumú marad (a boundary gate a `useSuiteUpdate()` hívást
  // rögzíti a MainLayout-ban); az appMode-ot belsőleg olvassuk, és a reportState
  // deps-ébe kerül, hogy a feloldott/átváltott mód ÚJRA-jelentést váltson ki (R3/D6).
  const { mode: appMode } = useAppMode()

  const reportState = useCallback(async () => {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.suiteUpdate) return

    let next: ShiftState
    if (appMode !== CASHIER_APP_MODE) {
      // FKH-041 FR-3: nem pénztár módban NINCS pénztári napi munkamenet, ezért az
      // `IDLE_BEFORE_OPEN` hamis „telepíthető" ablakot nyitna (suite-update.ts:609-649
      // -> csendes telepítés -> app.quit()). Konzervatívan SHIFT_OPEN —
      // és a napi-session API-t sem hívjuk (felesleges backend-kör nélkül).
      next = 'SHIFT_OPEN'
    } else {
      try {
        const isOpen = await dailySessionApi.isOpen()
        if (isOpen) {
          next = 'SHIFT_OPEN'
        } else {
          // Nincs nyitott munkamenet: a mai nap már lezárult, vagy még el sem indult.
          // A kettő telepítés szempontjából egyenértékű (mindkettő ablak), de a
          // dialógus szövege eltér, ezért megkülönböztetjük.
          try {
            const current = await dailySessionApi.getCurrent()
            next = mapSessionToShiftState(current)
          } catch {
            // Nincs mai munkamenet-rekord -> a nap még nem indult el.
            next = 'IDLE_BEFORE_OPEN'
          }
        }
      } catch (error) {
        // Fail-safe: nem megállapítható állapot -> nyitott műszakként kezeljük.
        logger.warn(
          'SuiteUpdate',
          'Műszak-állapot nem megállapítható, SHIFT_OPEN-t jelentünk',
          error,
        )
        next = 'SHIFT_OPEN'
      }
    }

    setShiftState(next)
    if (lastReportedRef.current === next) return
    lastReportedRef.current = next
    try {
      await electronAPI.suiteUpdate.setShiftState(next)
      logger.info('SuiteUpdate', `Műszak-állapot jelentve: ${next}`)
    } catch (error) {
      logger.warn('SuiteUpdate', 'A műszak-állapot jelentése sikertelen', error)
    }
  }, [appMode])

  useEffect(() => {
    if (!isElectron()) return undefined
    const electronAPI = getElectronAPI()
    if (!electronAPI?.suiteUpdate) return undefined

    void reportState()
    const intervalId = window.setInterval(() => void reportState(), REPORT_INTERVAL_MS)

    // A már készen álló frissítést induláskor is megkérdezzük (az event lehet, hogy
    // a hook felcsatolása ELŐTT tüzelt).
    void electronAPI.suiteUpdate
      .status()
      .then((status) => {
        if (status?.readyVersion) {
          setReadyUpdate({
            version: status.readyVersion,
            mandatory: status.mandatory === true,
            notes: null,
            installableNow: status.shiftState !== 'SHIFT_OPEN',
          })
        }
      })
      .catch((error) =>
        logger.warn('SuiteUpdate', 'A frissítés-állapot lekérése sikertelen', error),
      )

    const unsubscribe = electronAPI.suiteUpdate.onReady((payload) => {
      logger.info('SuiteUpdate', `Frissítés készen áll: v${payload.version}`)
      setReadyUpdate(payload)
    })

    return () => {
      window.clearInterval(intervalId)
      unsubscribe()
    }
  }, [reportState])

  return { shiftState, readyUpdate }
}
