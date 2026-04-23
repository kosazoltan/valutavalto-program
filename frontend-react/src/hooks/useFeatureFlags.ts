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

/**
 * Backend feature flag-ek (runtime).
 * A menuGroups szur szerinte: pl. camera=false -> Kamera csoport rejtve.
 *
 * Sourcery PR #146 P2 fix: catch blokk NEM swallow-ol, logger.warn monitorozhato.
 * Codex PR #146 P1 fix: authenticated endpoint - 401 eseten default fallback.
 */
export function useFeatureFlags(): FeatureFlags {
  const [flags, setFlags] = useState<FeatureFlags>(DEFAULT_FEATURES)

  useEffect(() => {
    let cancelled = false
    api.get<FeatureFlags>('/features')
      .then(r => {
        if (!cancelled) setFlags({ ...DEFAULT_FEATURES, ...r.data })
      })
      .catch(err => {
        // 401 (pre-login) eseten a default flag-ekkel megyunk tovabb.
        // Minden mas hibat logger-rel monitorozzuk (Sentry stb.)
        logger.warn('useFeatureFlags', 'Feature flag fetch failed, using defaults', err)
      })
    return () => { cancelled = true }
  }, [])

  return flags
}