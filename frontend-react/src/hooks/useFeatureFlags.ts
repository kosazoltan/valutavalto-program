import { useState, useEffect } from 'react'
import { api } from '../services/api/client'

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
 */
export function useFeatureFlags(): FeatureFlags {
  const [flags, setFlags] = useState<FeatureFlags>(DEFAULT_FEATURES)

  useEffect(() => {
    let cancelled = false
    api.get<FeatureFlags>('/features')
      .then(r => {
        if (!cancelled) setFlags({ ...DEFAULT_FEATURES, ...r.data })
      })
      .catch(() => {
        // Backend nem elerheto vagy 401: default flag-ek maradnak
      })
    return () => { cancelled = true }
  }, [])

  return flags
}