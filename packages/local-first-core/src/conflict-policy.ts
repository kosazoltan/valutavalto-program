/**
 * ConflictPolicy: explicit conflict resolution strategies per entity type.
 *
 * Every synced entity MUST have a registered conflict policy.
 * Attempting to sync an entity without a policy throws an error.
 */

import type { Database } from 'sql.js'

export type ConflictResolution = 'local_wins' | 'server_wins' | 'merged' | 'manual_pending'

export interface ConflictPolicy {
  entityType: string
  strategy: 'server_authority' | 'field_merge' | 'append_only' | 'last_write_wins' | 'manual'
  description: string
  resolve: (local: unknown, server: unknown) => { resolution: ConflictResolution; merged?: unknown }
}

const registry = new Map<string, ConflictPolicy>()

export function registerPolicy(policy: ConflictPolicy): void {
  registry.set(policy.entityType, policy)
}

export function getPolicy(entityType: string): ConflictPolicy {
  const policy = registry.get(entityType)
  if (!policy) {
    throw new Error(
      `No conflict policy registered for entity type '${entityType}'. ` +
        `Every synced entity MUST have an explicit conflict policy.`,
    )
  }
  return policy
}

export function hasPolicy(entityType: string): boolean {
  return registry.has(entityType)
}

export function resolveConflict(
  db: Database,
  entityType: string,
  entityId: string,
  localData: unknown,
  serverData: unknown,
): { resolution: ConflictResolution; merged?: unknown } {
  const policy = getPolicy(entityType)
  const result = policy.resolve(localData, serverData)

  db.run(
    `INSERT INTO lf_conflict_log (entity_type, entity_id, local_version, server_version, resolution, details)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [
      entityType,
      entityId,
      JSON.stringify(localData),
      JSON.stringify(serverData),
      result.resolution,
      JSON.stringify({ strategy: policy.strategy, merged: result.merged }),
    ],
  )

  return result
}

export const SERVER_AUTHORITY: ConflictPolicy['resolve'] = (_local, server) => ({
  resolution: 'server_wins' as const,
  merged: server,
})

export const LAST_WRITE_WINS: ConflictPolicy['resolve'] = (local, _server) => ({
  resolution: 'local_wins' as const,
  merged: local,
})

export function fieldMerge(
  priorityFields: Record<string, 'local' | 'server'>,
): ConflictPolicy['resolve'] {
  return (local, server) => {
    const localObj = local as Record<string, unknown>
    const serverObj = server as Record<string, unknown>
    const merged = { ...serverObj }

    for (const [field, priority] of Object.entries(priorityFields)) {
      if (priority === 'local' && field in localObj) {
        merged[field] = localObj[field]
      }
    }

    return { resolution: 'merged' as const, merged }
  }
}
