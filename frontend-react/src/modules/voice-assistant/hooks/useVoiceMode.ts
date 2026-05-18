import { useState, useCallback } from 'react'

/**
 * EBC Hangsegéd üzemmódok.
 *
 * - `idle`     — panel nyitva, de nincs aktív session
 * - `install`  — telepítés-kísérő (Setup Wizard mellett) — legacy
 * - `test`     — éles tesztelés-kísérő (medium reasoning effort) — legacy
 * - `support`  — hibajelentés-kísérő (riportál és exportál) — legacy
 * - `unified`  — Kósa Zoltán direktíva 2026-05-18: egyetlen mód, ami
 *                minden korábbi mód kérdéseit kezeli. medium reasoning.
 *
 * Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §5.1.
 */
export type VoiceMode = 'idle' | 'install' | 'test' | 'support' | 'unified'

export interface UseVoiceModeResult {
  mode: VoiceMode
  isActive: boolean
  setMode: (mode: VoiceMode) => void
  reset: () => void
}

export function useVoiceMode(initial: VoiceMode = 'idle'): UseVoiceModeResult {
  const [mode, setModeState] = useState<VoiceMode>(initial)

  const setMode = useCallback((next: VoiceMode) => {
    setModeState(next)
  }, [])

  const reset = useCallback(() => {
    setModeState('idle')
  }, [])

  return {
    mode,
    isActive: mode !== 'idle',
    setMode,
    reset,
  }
}
