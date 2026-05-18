import React, { createContext, useContext, useMemo, useRef, useState, useCallback } from 'react'
import { logger } from '../../../utils/logger'
import { useVoiceMode, VoiceMode } from '../hooks/useVoiceMode'
import { openRealtimeSession, RealtimeSession } from '../realtime/realtimeClient'

/**
 * EBC Hangsegéd Context — egyetlen aktív session a teljes React-fában.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §5.2
 */

export interface VoiceAssistantContextValue {
  mode: VoiceMode
  isActive: boolean
  isConnecting: boolean
  error: string | null
  start: (mode: Exclude<VoiceMode, 'idle'>) => Promise<void>
  stop: () => void
}

const VoiceAssistantContext = createContext<VoiceAssistantContextValue | null>(null)

export function VoiceAssistantProvider({ children }: { children: React.ReactNode }) {
  const { mode, isActive, setMode, reset } = useVoiceMode('idle')
  const [isConnecting, setConnecting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const sessionRef = useRef<RealtimeSession | null>(null)

  const stop = useCallback(() => {
    if (sessionRef.current) {
      sessionRef.current.close()
      sessionRef.current = null
    }
    reset()
    setError(null)
  }, [reset])

  const start = useCallback(
    async (next: Exclude<VoiceMode, 'idle'>) => {
      if (sessionRef.current) {
        stop()
      }
      setConnecting(true)
      setError(null)
      setMode(next)
      try {
        const session = await openRealtimeSession(next, (event) => {
          logger.debug('VoiceAssistant', 'event: ' + JSON.stringify(event).slice(0, 200))
        })
        sessionRef.current = session
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err)
        logger.error('VoiceAssistant', 'start failed — ' + message)
        setError(message)
        reset()
      } finally {
        setConnecting(false)
      }
    },
    [reset, setMode, stop]
  )

  const value = useMemo<VoiceAssistantContextValue>(
    () => ({ mode, isActive, isConnecting, error, start, stop }),
    [mode, isActive, isConnecting, error, start, stop]
  )

  return (
    <VoiceAssistantContext.Provider value={value}>
      {children}
    </VoiceAssistantContext.Provider>
  )
}

export function useVoiceAssistant(): VoiceAssistantContextValue {
  const ctx = useContext(VoiceAssistantContext)
  if (!ctx) {
    throw new Error('useVoiceAssistant: VoiceAssistantProvider hiányzik a React fában.')
  }
  return ctx
}
