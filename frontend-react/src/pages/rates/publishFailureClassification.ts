import { isAxiosError } from 'axios'
import type { PublishAllResult } from './publishAllWorkgroups'

/**
 * FK09: a szétküldési hiba jellege a szerver-szinkron állapot döntéséhez.
 * Az indikátor csak bizonyított transport-hibánál válthat offline állapotba.
 */
export type PublishFailureKind = 'business' | 'transport'

export function classifyPublishFailure(error: unknown): PublishFailureKind {
  if (isAxiosError(error)) {
    const status = error.response?.status
    if (status == null) return 'transport'
    return status >= 500 ? 'transport' : 'business'
  }
  return 'business'
}

/**
 * Részleges siker bizonyítja a szerver elérhetőségét. Nulla siker esetén csak
 * transport-jellegű (vagy legacy, osztályozatlan) csoporthiba állít offline-t.
 */
export function resolveDispatchSyncDecision(result: PublishAllResult): 'online' | 'offline' {
  if (result.published > 0 || result.total === 0) return 'online'

  const failed = result.outcomes.filter((outcome) => outcome.status === 'failed')
  if (failed.length === 0) return 'online'

  return failed.some((outcome) => outcome.failureKind !== 'business') ? 'offline' : 'online'
}
