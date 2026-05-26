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

import { app, ipcMain, safeStorage } from 'electron';
import path from 'node:path';
import fs from 'node:fs';
import { randomUUID } from 'node:crypto';
import log from 'electron-log';
import type { Database } from 'sql.js';
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
} from '../../packages/local-first-core/src';
import type { OutboxEntry } from '../../packages/local-first-core/src';

function resolveWasmPath(): string {
  if (app.isPackaged) {
    return path.join(process.resourcesPath, 'sql-wasm.wasm');
  }
  const candidates = [
    path.join(__dirname, '../node_modules/sql.js/dist/sql-wasm.wasm'),
    path.join(process.cwd(), 'node_modules/sql.js/dist/sql-wasm.wasm'),
  ];
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  throw new Error(`sql-wasm.wasm not found. Tried: ${candidates.join(', ')}`);
}

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
});

conflictPolicy.registerPolicy({
  entityType: 'published_rate',
  strategy: 'server_authority',
  description: 'Published rates: immutable, server is source of truth',
  resolve: SERVER_AUTHORITY,
});

conflictPolicy.registerPolicy({
  entityType: 'currency_pair',
  strategy: 'server_authority',
  description: 'Currency pairs: master data from server',
  resolve: SERVER_AUTHORITY,
});

conflictPolicy.registerPolicy({
  entityType: 'settings',
  strategy: 'last_write_wins',
  description: 'Settings: LWW acceptable, no critical data loss',
  resolve: LAST_WRITE_WINS,
});

// --- Rate Maker Sync Engine ---

class RateMakerSyncEngine extends SyncEngineBase {
  private apiUrl: string;
  private getToken: () => string | null;

  constructor(db: Database, apiUrl: string, getToken: () => string | null) {
    super(db, 30_000);
    this.apiUrl = apiUrl;
    this.getToken = getToken;
  }

  async getAuthToken(): Promise<string | null> {
    return this.getToken();
  }

  async pullChanges(token: string, checkpoint: string | null): Promise<{ checkpoint: string; count: number }> {
    const url = `${this.apiUrl}/rate-maker/sync/pull${checkpoint ? `?since=${encodeURIComponent(checkpoint)}` : ''}`;
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
      signal: AbortSignal.timeout(15_000),
    });

    if (!response.ok) {
      throw new Error(`Pull failed: HTTP ${response.status}`);
    }

    const data = await response.json() as {
      checkpoint: string;
      rates?: Array<{ id: string; [key: string]: unknown }>;
      currencyPairs?: Array<{ id: string; [key: string]: unknown }>;
      deletedIds?: Array<{ entityType: string; entityId: string }>;
    };

    let count = 0;

    if (data.rates) {
      for (const rate of data.rates) {
        cachedEntities.upsertCached(this.db, 'published_rate', rate.id, rate, 1, String(rate.updatedAt ?? ''));
        count++;
      }
    }

    if (data.currencyPairs) {
      for (const pair of data.currencyPairs) {
        cachedEntities.upsertCached(this.db, 'currency_pair', pair.id, pair, 1);
        count++;
      }
    }

    if (data.deletedIds) {
      for (const del of data.deletedIds) {
        cachedEntities.softDeleteCached(this.db, del.entityType, del.entityId);
        count++;
      }
    }

    saveDatabase();
    return { checkpoint: data.checkpoint ?? new Date().toISOString(), count };
  }

  async pushEntry(token: string, entry: OutboxEntry): Promise<void> {
    const url = `${this.apiUrl}/rate-maker/sync/push`;
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
    });

    if (!response.ok) {
      throw new Error(`Push failed: HTTP ${response.status}`);
    }
  }
}

// --- Module state ---

let syncEngine: RateMakerSyncEngine | null = null;
let cachedToken: string | null = null;

function loadPersistedToken(): string | null {
  try {
    const tokenFilePath = path.join(app.getPath('userData'), 'auth-token.bin');
    if (!safeStorage.isEncryptionAvailable() || !fs.existsSync(tokenFilePath)) return null;
    return safeStorage.decryptString(fs.readFileSync(tokenFilePath));
  } catch {
    return null;
  }
}

// --- Public API ---

export async function initLocalFirst(apiUrl: string): Promise<void> {
  const dbDir = path.join(app.getPath('home'), '.valuta-rate-maker');
  const db = await initLocalDatabase({
    dbDir,
    dbName: 'rate-maker.db',
    wasmPath: resolveWasmPath(),
  });

  cachedToken = loadPersistedToken();

  // Az árfolyamkészítő vékony publikáló kliens: közvetlen REST-en publikál
  // (/api/v1/local-rate-maker/packages/publish, ill. exchange-rate-master), NEM
  // pull/push szinkronnal. A RateMakerSyncEngine a /rate-maker/sync/pull|push
  // végpontokat hívná, amelyek a backenden NEM léteznek (csak /api/v1/sync/* és
  // /api/v1/local-rate-maker/packages/publish) → folyamatos 404-loop a háttérben,
  // miközben a renderer egyetlen lf:* draft-IPC-t sem használ (dead path).
  // A kozponti rate-maker módjával összhangban (PR #842) a sync-motort NEM
  // indítjuk; a DB-init megmarad a lokál cache-hez.
  void apiUrl;
  log.info('[LocalFirst] Rate Maker local-first initialized (sync-motor KIHAGYVA — közvetlen REST publikálás)');
}

export function shutdownLocalFirst(): void {
  syncEngine?.stop();
  closeDatabase();
  log.info('[LocalFirst] Rate Maker local-first shutdown');
}

export function setAuthToken(token: string | null): void {
  cachedToken = token;
}

// --- IPC Handlers ---

export function registerLocalFirstIpcHandlers(): void {
  ipcMain.handle('lf:sync-status', () => {
    try {
      return syncState.getSyncState(getDb());
    } catch {
      return { status: 'idle', lastPullAt: null, lastPushAt: null, lastPullCheckpoint: null, errorMessage: null, consecutiveFailures: 0 };
    }
  });

  ipcMain.handle('lf:outbox-stats', () => {
    try {
      return outbox.getStats(getDb());
    } catch {
      return {};
    }
  });

  ipcMain.handle('lf:trigger-sync', async () => {
    if (!syncEngine) return { error: 'Sync engine not initialized' };
    return syncEngine.runCycle();
  });

  ipcMain.handle('lf:save-rate-draft', (_event, draft: Record<string, unknown>) => {
    const db = getDb();
    const entityId = String(draft.id ?? randomUUID());
    const mutationId = outbox.enqueue(db, 'rate_draft', 'CREATE', { ...draft, id: entityId }, entityId);
    cachedEntities.upsertCached(db, 'rate_draft', entityId, { ...draft, id: entityId }, 1);
    saveDatabase();
    return { ok: true, mutationId };
  });

  ipcMain.handle('lf:update-rate-draft', (_event, draft: Record<string, unknown>) => {
    const db = getDb();
    const entityId = String(draft.id ?? '');
    outbox.enqueue(db, 'rate_draft', 'UPDATE', draft, entityId);
    cachedEntities.upsertCached(db, 'rate_draft', entityId, draft, 1);
    saveDatabase();
    return { ok: true };
  });

  ipcMain.handle('lf:delete-rate-draft', (_event, entityId: string) => {
    const db = getDb();
    outbox.enqueue(db, 'rate_draft', 'DELETE', { id: entityId }, entityId);
    cachedEntities.softDeleteCached(db, 'rate_draft', entityId);
    saveDatabase();
    return { ok: true };
  });

  ipcMain.handle('lf:get-rate-drafts', () => {
    return cachedEntities.listCached(getDb(), 'rate_draft');
  });

  ipcMain.handle('lf:get-published-rates', () => {
    return cachedEntities.listCached(getDb(), 'published_rate');
  });

  ipcMain.handle('lf:get-currency-pairs', () => {
    return cachedEntities.listCached(getDb(), 'currency_pair');
  });
}
