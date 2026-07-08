import { useState, useEffect } from 'react'
import { api } from '../services/api/client'
import { logger } from '../utils/logger'

export interface FeatureFlags {
  camera: boolean
  yearOpeningScheduler: boolean
  navIntegration: boolean
}

const DEFAULT_FEATURES: FeatureFlags = {
  camera: false,
  yearOpeningScheduler: true,
  navIntegration: true,
}

interface AxiosLikeError {
  response?: { status?: number }
}

function isExpected401(err: unknown): boolean {
  const ax = err as AxiosLikeError | undefined
  return ax?.response?.status === 401
}

/**
 * Backend feature flag-ek (runtime).
 * A menuGroups szur szerinte: pl. camera=false -> Kamera csoport rejtve.
 *
 * Sourcery PR #146 P2 fix: catch blokk NEM swallow-ol, logger.warn monitorozhato.
 * Codex PR #146 P1 fix: authenticated endpoint - 401 eseten default fallback.
 * Sourcery PR #147 fix: pre-login 401 NEM warn (zaj-csokkentes) - csak 500+/netwerk.
 */
export function useFeatureFlags(): FeatureFlags {
  const [flags, setFlags] = useState<FeatureFlags>(DEFAULT_FEATURES)

  useEffect(() => {
    let cancelled = false
    api
      .get<FeatureFlags>('/features')
      .then((r) => {
        if (!cancelled) setFlags({ ...DEFAULT_FEATURES, ...r.data })
      })
      .catch((err) => {
        // 401 (pre-login) varhato eset, NEM logoljuk (zaj elkerulese).
        // Mas hibat (500, network error, stb.) monitorozzuk.
        if (!isExpected401(err)) {
          logger.warn('useFeatureFlags', 'Feature flag fetch failed, using defaults', err)
        }
      })
    return () => {
      cancelled = true
    }
  }, [])

  return flags
}
