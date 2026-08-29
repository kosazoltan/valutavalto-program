import { useCallback, useEffect, useRef, useState } from 'react'
import { dailySessionApi } from '../services/api/index'
import { isElectron, getElectronAPI } from '../utils/electron'
import { logger } from '../utils/logger'
import { useAppMode } from './useAppMode'
import { CASHIER_APP_MODE } from '../types/appMode'
import { useAuthStore } from '../stores/authStore'
import { canonicalizeRoleForAppMode } from '../utils/appModeRoles'

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
 * FKH-041 FR-3, round 2 (D5/D6/D8): a telepíthető ablak CSAK bizonyított pénztáros
 * munkamenetben létezik — a döntés SZEREP-ELSŐ: `appMode === 'penztar'` ÉS az aktív
 * kanonikus szerep `penztar`. Minden más kombináció (nem-pénztár mód, értéktáros/
 * főértéktáros/értékszállító szerep — akár pénztár konfigurációjú gépen is —,
 * ismeretlen/hiányzó szerep) KONZERVATÍVAN `SHIFT_OPEN`-t jelent, és a napi-session
 * API-t sem hívja. Amíg az appMode nem oldódott fel (`isLoading`), a hook SEMMILYEN
 * állapotot nem jelent (a main process alapértelmezése úgyis `SHIFT_OPEN`). Indoklás:
 * a riportoló terminál SQLite `app_mode='penztar'` mellett futtat értéktárost, ezért
 * az appMode-egyből döntés hamis `IDLE_BEFORE_OPEN` ablakot hagyott nyitva
 * (`maybeOfferInstall` -> csendes telepítés -> `app.quit()` ~1 mp múlva, ami
 * megszakította a bejelentkezést). Ez a kompromisszum ELFOGADOTT: az értéktár
 * terminál és az értéktáros által kezelt pénztár gép sosem auto-telepít, a manuális
 * telepítő (Penztar-Setup) marad az út. NE „javítsd vissza" a main processben — a fő
 * folyamat telepítési kapuja a renderer jelentésétől függetlenül is fail-safe
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
  // D6 (round 2): a hook zéró-argumentumú marad (a boundary gate a `useSuiteUpdate()`
  // hívást rögzíti a MainLayout-ban); az appMode ÉS a kanonikus szerep belsőleg
  // olvasott, és mindkettő a reportState deps-ébe kerül, hogy a feloldott/átváltott
  // mód és a szerepváltás ÚJRA-jelentést váltson ki (R3/D6). A nem-selector
  // destrukturálás azonos a MainLayout.tsx konvenciójával.
  const { mode: appMode, isLoading: appModeLoading } = useAppMode()
  const { activeRole, user } = useAuthStore()
  const canonicalRole = canonicalizeRoleForAppMode(activeRole ?? user?.role ?? null)
  // D9: a never-install ág naplózása mountonként egyszer (a 60 mp-es intervallum
  // nem spamelhet). Csak log-guard — a SHIFT_OPEN-hozást NEM kapuzhatja.
  const neverInstallLoggedRef = useRef(false)

  const reportState = useCallback(async () => {
    const electronAPI = getElectronAPI()
    if (!electronAPI?.suiteUpdate) return

    // FKH-041 round 2 / D8: amíg az appMode nem oldódott fel, NEM jelentünk (a main
    // process alapértelmezése SHIFT_OPEN, tehát a hallgatás a biztonságos ág).
    if (appModeLoading) return

    let next: ShiftState
    if (appMode !== CASHIER_APP_MODE || canonicalRole !== 'penztar') {
      // FKH-041 round 2 / D5: telepítési ablak CSAK bizonyított pénztáros munkamenetben.
      // Az értéktáros (penztar konfigurációjú gépen is!) sosem nyit ablakot -> nincs
      // csendes telepítés a bejelentkezés alatt (suite-update.ts:624-648 -> app.quit()).
      if (!neverInstallLoggedRef.current) {
        neverInstallLoggedRef.current = true
        logger.warn(
          'SuiteUpdate',
          `Telepitesi ablak letiltva (FKH-041): appMode=${appMode}, kanonikus szerep=${canonicalRole || 'ismeretlen'} -> SHIFT_OPEN`,
        )
      }
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
  }, [appMode, appModeLoading, canonicalRole])

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
