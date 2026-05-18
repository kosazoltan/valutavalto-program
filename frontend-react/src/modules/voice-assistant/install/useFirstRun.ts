import { useState } from 'react'

/**
 * EBC Hangsegéd első-futtatás detektálás.
 *
 * Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §6.1
 *
 * localStorage flag — egy gépen csak az ELSO indításnál igaz. Az Electron
 * userData-flow miatt minden új telepítés (userData migráció után) első
 * indulásakor `null` és újra `true` lesz.
 *
 * Phase 9.5 Electron integráció: a `useFirstRun()` `true` esetén a
 * `<VoiceAssistantPanel>` autostarts `install` módban. Egyébként `idle`.
 *
 * (Copilot PR #666: a korabbi useless useEffect torolve. JSDoc-bol a
 * Javadoc-stilus <p> tagek eltavolitva, TSDoc-konvencio: blank * line.)
 */

const FLAG_KEY = 'ebc_voice_assistant_first_run_done'

export function useFirstRun(): { isFirstRun: boolean; markCompleted: () => void } {
  const [isFirstRun, setFirstRun] = useState<boolean>(() => {
    try {
      return localStorage.getItem(FLAG_KEY) === null
    } catch {
      return false
    }
  })

  const markCompleted = () => {
    try {
      localStorage.setItem(FLAG_KEY, new Date().toISOString())
    } catch {
      /* localStorage may be blocked in some sandboxed contexts */
    }
    setFirstRun(false)
  }

  return { isFirstRun, markCompleted }
}

/** Csak tesztekhez — ne hivd production-ben. */
export function __resetFirstRunForTesting(): void {
  try {
    localStorage.removeItem(FLAG_KEY)
  } catch {
    /* ignore */
  }
}
