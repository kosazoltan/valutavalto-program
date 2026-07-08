import React, {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  useCallback,
} from 'react'
import { logger } from '../../../utils/logger'
import { useVoiceMode, VoiceMode } from '../hooks/useVoiceMode'
import { openRealtimeSession, RealtimeSession } from '../realtime/realtimeClient'

/**
 * EBC Hangsegéd Context — egyetlen aktív session a teljes React-fában.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §5.2
 *
 * <p>Copilot finding #660-ra reagálva:
 * <ul>
 *   <li>in-flight guard (`isStartingRef`) — concurrent start hívások blokkolva</li>
 *   <li>AbortController — stop() közben futó start cancel-eli</li>
 *   <li>unmount cleanup — useEffect cleanup zárja a session-t</li>
 *   <li>generation counter — race-elt setState-ek kiszűrve</li>
 * </ul>
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
  const isStartingRef = useRef(false)
  const startAbortRef = useRef<AbortController | null>(null)
  /** Generation counter — minden start uj generaciot kap, ki nem aktiv generaciok setState-jei ignorral. */
  const generationRef = useRef(0)

  const closeSessionAndReset = useCallback(() => {
    if (sessionRef.current) {
      try {
        sessionRef.current.close()
      } catch (err) {
        logger.warn('VoiceAssistant', 'session.close hiba: ' + String(err))
      }
      sessionRef.current = null
    }
    if (startAbortRef.current) {
      startAbortRef.current.abort()
      startAbortRef.current = null
    }
  }, [])

  const stop = useCallback(() => {
    closeSessionAndReset()
    isStartingRef.current = false
    generationRef.current += 1
    reset()
    setError(null)
    setConnecting(false)
  }, [closeSessionAndReset, reset])

  const start = useCallback(
    async (next: Exclude<VoiceMode, 'idle'>) => {
      // In-flight guard (Copilot #660): elutasit, ha mar zajlik egy start
      if (isStartingRef.current) {
        logger.warn('VoiceAssistant', 'start mar zajlik, uj start kiserlet elutasitva')
        return
      }
      if (sessionRef.current) {
        stop()
      }
      isStartingRef.current = true
      const myGen = ++generationRef.current
      const myAbort = new AbortController()
      startAbortRef.current = myAbort

      setConnecting(true)
      setError(null)
      setMode(next)

      try {
        const session = await openRealtimeSession(
          next,
          (event) => {
            logger.debug('VoiceAssistant', 'event: ' + JSON.stringify(event).slice(0, 200))
          },
          { signal: myAbort.signal },
        )
        // Generation check (Copilot #660): kozben jott egy stop / uj start
        if (myGen !== generationRef.current) {
          try {
            session.close()
          } catch {
            /* ignore */
          }
          return
        }
        sessionRef.current = session
      } catch (err) {
        if ((err as Error)?.name === 'AbortError') {
          logger.info('VoiceAssistant', 'start abort signal-lal megszakitva')
          return
        }
        if (myGen !== generationRef.current) return
        const message = err instanceof Error ? err.message : String(err)
        logger.error('VoiceAssistant', 'start failed — ' + message)
        setError(message)
        reset()
      } finally {
        if (myGen === generationRef.current) {
          setConnecting(false)
          isStartingRef.current = false
          startAbortRef.current = null
        }
      }
    },
    [reset, setMode, stop],
  )

  // Unmount cleanup (Copilot #660): provider unmount-kor zarjuk a session-t
  useEffect(() => {
    return () => {
      closeSessionAndReset()
    }
  }, [closeSessionAndReset])

  const value = useMemo<VoiceAssistantContextValue>(
    () => ({ mode, isActive, isConnecting, error, start, stop }),
    [mode, isActive, isConnecting, error, start, stop],
  )

  return <VoiceAssistantContext.Provider value={value}>{children}</VoiceAssistantContext.Provider>
}

export function useVoiceAssistant(): VoiceAssistantContextValue {
  const ctx = useContext(VoiceAssistantContext)
  if (!ctx) {
    throw new Error('useVoiceAssistant: VoiceAssistantProvider hiányzik a React fában.')
  }
  return ctx
}
