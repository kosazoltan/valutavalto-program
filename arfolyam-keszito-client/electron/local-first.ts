/**
 * Local-first integration for the Rate Maker (Árfolyamkészítő) client.
 *
 * Provides: SQLite init, sync engine, outbox IPC handlers, conflict policies.
 *
 * LocalFirstPlan:
 *   local_store: SQLite via sql.js (Electron Main process)
 *   write_path: UI -> IPC -> Main process SQLite INSERT/UPDATE -> outbox
 *   sync_path: 30s polling push/pull with excvaluta.com backend
 *   conflict_policy:
 *     - rate_drafts: field_level_merge (editable, non-critical)
 *     - published_rates: server_authority (immutable once published)
 *     - settings: last_write_wins (non-critical)
 *     - currency_pairs: server_authority (master data)
 *   invariants:
 *     - buy_rate < sell_rate
 *     - spread >= 0
 *     - rate_valid_until not expired
 *     - currency_pair unique per draft set
 *   auth_scope: companyId + branchId filtered server-side
 *   migration: PRAGMA user_version + versioned migrations
 *   tests: offline CRUD, reconnect sync, concurrent edit
 */

import { app, ipcMain, safeStorage } from 'electron'
import { resolveWasmPath, loadToken } from '../../packages/electron-platform/src'
import path from 'node:path'
import fs from 'node:fs'
import { randomUUID } from 'node:crypto'
import log from 'electron-log'
import type { Database } from 'sql.js'
import {
  initLocalDatabase,
  getDb,
  saveDatabase,
  closeDatabase,
  outbox,
  syncState,
  cachedEntities,
  conflictPolicy,
  SyncEngineBase,
  SERVER_AUTHORITY,
  LAST_WRITE_WINS,
  fieldMerge,
} from '../../packages/local-first-core/src'
import type { OutboxEntry } from '../../packages/local-first-core/src'

// `resolveWasmPath` a kozos platform-retegben: packages/electron-platform/src/local-first-paths.ts

// --- Conflict policies ---

conflictPolicy.registerPolicy({
  entityType: 'rate_draft',
  strategy: 'field_merge',
  description: 'Rate drafts: field-level merge, editable by rate makers',
  resolve: fieldMerge({
    buy_rate: 'local',
    sell_rate: 'local',
    spread: 'local',
    notes: 'local',
    valid_from: 'server',
    valid_until: 'server',
  }),
})

conflictPolicy.registerPolicy({
  entityType: 'published_rate',
  strategy: 'server_authority',
  description: 'Published rates: immutable, server is source of truth',
  resolve: SERVER_AUTHORITY,
})

conflictPolicy.registerPolicy({
  entityType: 'currency_pair',
  strategy: 'server_authority',
  description: 'Currency pairs: master data from server',
  resolve: SERVER_AUTHORITY,
})

conflictPolicy.registerPolicy({
  entityType: 'settings',
  strategy: 'last_write_wins',
  description: 'Settings: LWW acceptable, no critical data loss',
  resolve: LAST_WRITE_WINS,
})

// --- Rate Maker Sync Engine ---

class RateMakerSyncEngine extends SyncEngineBase {
  private apiUrl: string
  private getToken: () => string | null

  constructor(db: Database, apiUrl: string, getToken: () => string | null) {
    super(db, 30_000)
    this.apiUrl = apiUrl
    this.getToken = getToken
  }

  async getAuthToken(): Promise<string | null> {
    return this.getToken()
  }

  async pullChanges(
    token: string,
    checkpoint: string | null,
  ): Promise<{ checkpoint: string; count: number }> {
    const url = `${this.apiUrl}/rate-maker/sync/pull${checkpoint ? `?since=${encodeURIComponent(checkpoint)}` : ''}`
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
      signal: AbortSignal.timeout(15_000),
    })

    if (!response.ok) {
      throw new Error(`Pull failed: HTTP ${response.status}`)
    }

    const data = (await response.json()) as {
      checkpoint: string
      rates?: Array<{ id: string; [key: string]: unknown }>
      currencyPairs?: Array<{ id: string; [key: string]: unknown }>
      deletedIds?: Array<{ entityType: string; entityId: string }>
    }

    let count = 0

    if (data.rates) {
      for (const rate of data.rates) {
        cachedEntities.upsertCached(
          this.db,
          'published_rate',
          rate.id,
          rate,
          1,
          String(rate.updatedAt ?? ''),
        )
        count++
      }
    }

    if (data.currencyPairs) {
      for (const pair of data.currencyPairs) {
        cachedEntities.upsertCached(this.db, 'currency_pair', pair.id, pair, 1)
        count++
      }
    }

    if (data.deletedIds) {
      for (const del of data.deletedIds) {
        cachedEntities.softDeleteCached(this.db, del.entityType, del.entityId)
        count++
      }
    }

    saveDatabase()
    return { checkpoint: data.checkpoint ?? new Date().toISOString(), count }
  }

  async pushEntry(token: string, entry: OutboxEntry): Promise<void> {
    const url = `${this.apiUrl}/rate-maker/sync/push`
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Idempotency-Key': entry.mutation_id,
      },
      body: JSON.stringify({
        mutationId: entry.mutation_id,
        entityType: entry.entity_type,
        entityId: entry.entity_id,
        action: entry.action,
        payload: JSON.parse(entry.payload),
      }),
      signal: AbortSignal.timeout(15_000),
    })

    if (!response.ok) {
      throw new Error(`Push failed: HTTP ${response.status}`)
    }
  }
}

// --- Module state ---

let syncEngine: RateMakerSyncEngine | null = null
let cachedToken: string | null = null

// A perzisztalt token betoltese a kozos platform-primitivvel tortenik
// (`loadToken`), amely ugyanazt az auth-token.bin fajlt olvassa.

// --- Public API ---

// Az árfolyamkészítő vékony publikáló kliens: közvetlen REST-en publikál
// (/api/v1/local-rate-maker/packages/publish, ill. exchange-rate-master), NEM
// pull/push szinkronnal. A RateMakerSyncEngine a /rate-maker/sync/pull|push
// végpontokat hívná, amelyek a backenden NEM léteznek (csak /api/v1/sync/* és
// /api/v1/local-rate-maker/packages/publish) → folyamatos 404-loop a háttérben,
// miközben a renderer egyetlen lf:* draft-IPC-t sem használ (dead path).
// A kozponti rate-maker módjával összhangban (PR #842) a sync-motort NEM
// indítjuk; ezért az `apiUrl` itt nincs használva (a call-site kompatibilitás
// miatt megtartjuk a paramétert), és a DB-init visszatérési értékét sem kell
// elkapni — a `getDb()` modul-szintű accessoron át érjük el a lokál cache-t.
export async function initLocalFirst(_apiUrl: string): Promise<void> {
  const dbDir = path.join(app.getPath('home'), '.valuta-rate-maker')
  await initLocalDatabase({
    dbDir,
    dbName: 'rate-maker.db',
    wasmPath: resolveWasmPath(),
  })

  cachedToken = loadToken()

  log.info(
    '[LocalFirst] Rate Maker local-first initialized (sync-motor KIHAGYVA — közvetlen REST publikálás)',
  )
}

export function shutdownLocalFirst(): void {
  syncEngine?.stop()
  closeDatabase()
  log.info('[LocalFirst] Rate Maker local-first shutdown')
}

export function setAuthToken(token: string | null): void {
  cachedToken = token
}

// --- IPC Handlers ---

export function registerLocalFirstIpcHandlers(): void {
  ipcMain.handle('lf:sync-status', () => {
    try {
      return syncState.getSyncState(getDb())
    } catch {
      return {
        status: 'idle',
        lastPullAt: null,
        lastPushAt: null,
        lastPullCheckpoint: null,
        errorMessage: null,
        consecutiveFailures: 0,
      }
    }
  })

  ipcMain.handle('lf:outbox-stats', () => {
    try {
      return outbox.getStats(getDb())
    } catch {
      return {}
    }
  })

  ipcMain.handle('lf:trigger-sync', async () => {
    if (!syncEngine) return { error: 'Sync engine not initialized' }
    return syncEngine.runCycle()
  })

  ipcMain.handle('lf:save-rate-draft', (_event, draft: Record<string, unknown>) => {
    const db = getDb()
    const entityId = String(draft.id ?? randomUUID())
    const mutationId = outbox.enqueue(
      db,
      'rate_draft',
      'CREATE',
      { ...draft, id: entityId },
      entityId,
    )
    cachedEntities.upsertCached(db, 'rate_draft', entityId, { ...draft, id: entityId }, 1)
    saveDatabase()
    return { ok: true, mutationId }
  })

  ipcMain.handle('lf:update-rate-draft', (_event, draft: Record<string, unknown>) => {
    const db = getDb()
    const entityId = String(draft.id ?? '')
    outbox.enqueue(db, 'rate_draft', 'UPDATE', draft, entityId)
    cachedEntities.upsertCached(db, 'rate_draft', entityId, draft, 1)
    saveDatabase()
    return { ok: true }
  })

  ipcMain.handle('lf:delete-rate-draft', (_event, entityId: string) => {
    const db = getDb()
    outbox.enqueue(db, 'rate_draft', 'DELETE', { id: entityId }, entityId)
    cachedEntities.softDeleteCached(db, 'rate_draft', entityId)
    saveDatabase()
    return { ok: true }
  })

  ipcMain.handle('lf:get-rate-drafts', () => {
    return cachedEntities.listCached(getDb(), 'rate_draft')
  })

  ipcMain.handle('lf:get-published-rates', () => {
    return cachedEntities.listCached(getDb(), 'published_rate')
  })

  ipcMain.handle('lf:get-currency-pairs', () => {
    return cachedEntities.listCached(getDb(), 'currency_pair')
  })

  // FK02-B (csoport-árfolyamlap FR-11/FR-12): a beírt csoport-ráta ÉRTÉKEK TARTÓS offline
  // perzisztálása az onBlur-ra, hogy lapváltás/offline után se vesszenek el. A local-first
  // `lf_cached_entities` táblát használjuk (nincs külön nyers tábla) — entityType='group_rate_values',
  // entityId=groupId, data = a teljes `${currencyId}.${field}` → string érték-map (a localStorage
  // szemantikájával 1:1, így a sávok K_1/K_2/E_1/E_2 is megőrződnek, nem csak a vétel/eladás).
  // Csak lokál (a vékony publikáló kliens nem futtat sync-motort).
  ipcMain.handle(
    'lf:save-group-rate-values',
    (
      _event,
      payload: {
        groupId: string
        values: Record<string, string>
      },
    ) => {
      try {
        const db = getDb()
        const { groupId, values } = payload ?? { groupId: '', values: {} }
        // Szigorú payload-validáció (Copilot review): groupId string ÉS values sima objektum (nem tömb/null).
        if (
          typeof groupId !== 'string' ||
          !groupId ||
          typeof values !== 'object' ||
          values === null ||
          Array.isArray(values)
        ) {
          return { ok: false, error: 'invalid payload' }
        }
        // Üres map → tombstone (a publikálás-utáni overlay-törléssel összhangban; betöltéskor {}).
        if (Object.keys(values).length === 0) {
          cachedEntities.softDeleteCached(db, 'group_rate_values', groupId)
        } else {
          cachedEntities.upsertCached(db, 'group_rate_values', groupId, values, 1)
        }
        saveDatabase()
        return { ok: true }
      } catch (error) {
        log.error('[LocalFirst] Hiba a csoport-árfolyam értékek SQLite mentésekor:', error)
        return { ok: false, error: error instanceof Error ? error.message : String(error) }
      }
    },
  )

  ipcMain.handle('lf:get-group-rate-values', (_event, groupId: string) => {
    try {
      if (typeof groupId !== 'string' || !groupId) return {}
      const entity = cachedEntities.getCached<Record<string, string>>(
        getDb(),
        'group_rate_values',
        groupId,
      )
      return entity && entity.data && typeof entity.data === 'object' && !Array.isArray(entity.data)
        ? entity.data
        : {}
    } catch (error) {
      log.error('[LocalFirst] Hiba a csoport-árfolyam értékek SQLite lekérésekor:', error)
      return {}
    }
  })
}
