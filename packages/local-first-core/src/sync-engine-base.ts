/**
 * SyncEngineBase: abstract sync engine with pull/push cycle, backoff, and lifecycle.
 *
 * Concrete implementations override:
 *   - pullChanges(): download server changes
 *   - pushChanges(): upload outbox entries
 *   - getAuthToken(): provide current auth token
 *
 * The engine manages the polling loop, exponential backoff,
 * online/offline detection, and sync state updates.
 */

import type { Database } from 'sql.js'
import log from 'electron-log'
import * as outbox from './outbox'
import * as syncState from './sync-state'
import * as tombstone from './tombstone'
import { saveDatabase } from './database'

export interface SyncResult {
  pushed: number
  pulled: number
  failed: number
  errors: string[]
}

export abstract class SyncEngineBase {
  protected db: Database
  private intervalMs: number
  private timer: ReturnType<typeof setInterval> | null = null
  private running = false
  private backoffMs = 0
  private readonly maxBackoffMs = 300_000 // 5 min

  constructor(db: Database, intervalMs = 30_000) {
    this.db = db
    this.intervalMs = intervalMs
  }

  abstract pullChanges(
    token: string,
    checkpoint: string | null,
  ): Promise<{ checkpoint: string; count: number }>
  abstract pushEntry(token: string, entry: outbox.OutboxEntry): Promise<void>
  abstract getAuthToken(): Promise<string | null>

  start(): void {
    if (this.timer) return
    log.info(`[SyncEngine] Starting with ${this.intervalMs}ms interval`)
    this.timer = setInterval(() => void this.runCycle(), this.intervalMs)
    void this.runCycle()
  }

  stop(): void {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
    log.info('[SyncEngine] Stopped')
  }

  pause(): void {
    this.stop()
    log.info('[SyncEngine] Paused')
  }

  resume(): void {
    this.start()
  }

  async runCycle(): Promise<SyncResult> {
    if (this.running) return { pushed: 0, pulled: 0, failed: 0, errors: ['Already running'] }
    this.running = true

    const result: SyncResult = { pushed: 0, pulled: 0, failed: 0, errors: [] }

    try {
      const token = await this.getAuthToken()
      if (!token) {
        syncState.updateSyncStatus(this.db, 'error', 'No auth token')
        return result
      }

      if (this.backoffMs > 0) {
        await new Promise((r) => setTimeout(r, this.backoffMs))
      }

      // --- PUSH phase ---
      syncState.updateSyncStatus(this.db, 'pushing')
      const pending = outbox.getPending(this.db)

      for (const entry of pending) {
        try {
          outbox.markSyncing(this.db, entry.mutation_id)
          await this.pushEntry(token, entry)
          outbox.markSynced(this.db, entry.mutation_id)
          result.pushed++
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err)
          outbox.markFailed(this.db, entry.mutation_id, msg)
          result.failed++
          result.errors.push(`${entry.entity_type}/${entry.mutation_id}: ${msg}`)
        }
      }

      // --- Push tombstones ---
      const pendingTombstones = tombstone.getUnsyncedTombstones(this.db)
      for (const ts of pendingTombstones) {
        try {
          await this.pushEntry(token, {
            id: 0,
            mutation_id: `tombstone-${ts.entity_type}-${ts.entity_id}`,
            entity_type: ts.entity_type,
            entity_id: ts.entity_id,
            action: 'DELETE',
            payload: JSON.stringify({ entity_type: ts.entity_type, entity_id: ts.entity_id }),
            status: 'pending',
            retry_count: 0,
            max_retries: 10,
            error_message: null,
            created_at: ts.deleted_at,
            synced_at: null,
            next_retry_at: null,
          })
          tombstone.markTombstoneSynced(this.db, ts.entity_type, ts.entity_id)
        } catch {
          // Tombstone push failures are non-critical; will retry next cycle
        }
      }

      syncState.updatePushTimestamp(this.db)

      // --- PULL phase ---
      syncState.updateSyncStatus(this.db, 'pulling')
      const state = syncState.getSyncState(this.db)
      const pullResult = await this.pullChanges(token, state.lastPullCheckpoint)
      result.pulled = pullResult.count
      syncState.updatePullCheckpoint(this.db, pullResult.checkpoint)

      // --- Cleanup ---
      outbox.cleanupSynced(this.db, 30)
      tombstone.cleanupExpired(this.db)

      // --- Success ---
      syncState.updateSyncStatus(this.db, 'synced')
      this.backoffMs = 0

      saveDatabase()
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err)
      log.error('[SyncEngine] Cycle failed:', msg)
      syncState.updateSyncStatus(this.db, 'error', msg)
      this.backoffMs = Math.min((this.backoffMs || 1000) * 1.5, this.maxBackoffMs)
      result.errors.push(msg)
    } finally {
      this.running = false
    }

    return result
  }

  getStatus(): syncState.SyncStateInfo {
    return syncState.getSyncState(this.db)
  }

  getOutboxStats(): Record<string, number> {
    return outbox.getStats(this.db)
  }
}
