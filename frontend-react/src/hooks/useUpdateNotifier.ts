import { useEffect, useRef, useState } from 'react'
import { isElectron } from '../utils/electron'
import { api } from '../services/api/index'
import { logger } from '../utils/logger'

const CHECK_INTERVAL_MS = 2 * 60 * 1000 // 2 perc
const HARD_WARNING_DELAY_MS = 5 * 60 * 1000 // 5 perc

type VersionResponse = {
  buildTime?: string
  version?: string
}

/**
 * Frissítés-figyelő hook — csak Electron-ban aktív.
 * 2 percenként lekérdezi a /version endpointot, és ha a buildTime változott,
 * jelzi, hogy frissítés érhető el. 5 perc után kötelező újraindítást kér.
 */
export function useUpdateNotifier(): { updateAvailable: boolean; hardRequired: boolean } {
  const [updateAvailable, setUpdateAvailable] = useState(false)
  const [hardRequired, setHardRequired] = useState(false)

  const initialBuildTimeRef = useRef<string | null>(null)
  const detectedAtRef = useRef<number | null>(null)
  const updateAvailableRef = useRef(false)

  useEffect(() => {
    // Csak Electron-ban fut
    if (!isElectron()) return

    let isMounted = true

    const checkVersion = async () => {
      try {
        const response = await api.get<VersionResponse>('/version')
        const buildTime = response.data?.buildTime
        if (!buildTime) return

        if (!initialBuildTimeRef.current) {
          initialBuildTimeRef.current = buildTime
          return
        }

        if (buildTime !== initialBuildTimeRef.current && !updateAvailableRef.current) {
          updateAvailableRef.current = true
          if (isMounted) {
            detectedAtRef.current = Date.now()
            setUpdateAvailable(true)
          }
        }
      } catch (error) {
        logger.warn('UpdateNotifier', 'Verzió-ellenőrzés sikertelen:', error)
      }
    }

    void checkVersion()
    const intervalId = window.setInterval(checkVersion, CHECK_INTERVAL_MS)

    return () => {
      isMounted = false
      window.clearInterval(intervalId)
    }
  }, [])

  useEffect(() => {
    if (!updateAvailable || hardRequired) return undefined

    const detectedAt = detectedAtRef.current ?? Date.now()
    detectedAtRef.current = detectedAt
    const elapsed = Date.now() - detectedAt
    const remaining = Math.max(0, HARD_WARNING_DELAY_MS - elapsed)

    const timeoutId = window.setTimeout(() => {
      setHardRequired(true)
    }, remaining)

    return () => window.clearTimeout(timeoutId)
  }, [updateAvailable, hardRequired])

  return { updateAvailable, hardRequired }
}
