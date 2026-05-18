import { useState, useCallback } from 'react'

/**
 * EBC Hangsegéd üzemmódok.
 *
 * - `idle`     — panel nyitva, de nincs aktív session
 * - `install`  — telepítés-kísérő (Setup Wizard mellett)
 * - `test`     — éles tesztelés-kísérő (medium reasoning effort)
 * - `support`  — hibajelentés-kísérő (riportál és exportál)
 *
 * Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §5.1.
 */
export type VoiceMode = 'idle' | 'install' | 'test' | 'support'

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
