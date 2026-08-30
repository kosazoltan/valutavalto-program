/**
 * Nyitottnap-marker — a HITELESÍTETT munkamenet által megfigyelt NYITOTT nap
 * helyi dátuma (Frameworks/Drivers adapter: browser localStorage).
 *
 * MIÉRT KELL (Google-OTP hurok, 2026-08-30): a belépőképernyő jelentése nem
 * állíthatja, hogy „a nap még nem indult el" (IDLE_BEFORE_OPEN), ha ezen a
 * gépen ma már megfigyeltek nyitott napot hitelesített munkamenetben
 * (`dailySessionApi.isOpen() === true`). A marker éjfélkor (HELYI idő szerint)
 * magától elévül — pontosan akkor nyílik meg az éjszakai telepítési ablak (AC-4).
 *
 * Írási jogosultság: CSAK a hitelesített `useSuiteUpdate` út írhatja/törölheti;
 * hálózati hiba esetén egyáltalán nem nyúlunk hozzá (fail-safe: hiba nem
 * gyárthat telepítési ablakot).
 *
 * MIÉRT localStorage és nem sessionStorage: az `app.quit()` (csendes telepítés)
 * a sessionStorage-ot törli, a localStorage-t nem — a markernek ugyanúgy túl
 * kell élnie a folyamat-újraindítást, ahogy a szerep-marker is túléli.
 */

/** LocalStorage: a HITELESÍTETT munkamenet által megfigyelt NYITOTT nap helyi dátuma. */
export const OPEN_DAY_OBSERVED_KEY = 'valuta-suite-update-open-day'

/**
 * Helyi (nem UTC) nap-kulcs: 'YYYY-MM-DD'.
 *
 * SZÁNDÉKOSAN NEM `toISOString().slice(0, 10)`: az UTC-alapú kulcs CEST-ben
 * éjfél körül átbillenne (pl. 2026-08-31 01:00 helyi = 2026-08-30 UTC), ami a
 * blokkot éjfél után is életben tartaná — és megölné az éjszakai ablakot (AC-4).
 */
export function localDayKey(now: Date = new Date()): string {
  const y = now.getFullYear()
  const m = String(now.getMonth() + 1).padStart(2, '0')
  const d = String(now.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

/** isOpen()===true után hívandó; a mai helyi nap-kulcsot tárolja. */
export function rememberOpenDayObservation(now?: Date): void {
  try {
    localStorage.setItem(OPEN_DAY_OBSERVED_KEY, localDayKey(now))
  } catch {
    // localStorage nem elérhető (teszt / privát mód) — a marker nélkül a
    // döntés fail-closed marad (az IDLE ágnak más bizonyíték kell).
  }
}

/** isOpen()===false után hívandó; a markert törli. Hibánál NEM hívandó. */
export function clearOpenDayObservation(): void {
  try {
    localStorage.removeItem(OPEN_DAY_OBSERVED_KEY)
  } catch {
    // no-op
  }
}

/** true, ha a tárolt kulcs a MAI helyi nap. Olvashatatlan storage -> false. */
export function hasOpenDayObservedToday(now?: Date): boolean {
  try {
    return localStorage.getItem(OPEN_DAY_OBSERVED_KEY) === localDayKey(now)
  } catch {
    return false
  }
}
