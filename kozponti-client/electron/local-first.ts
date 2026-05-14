/**
 * Local-first integration for the Central Workstation (Központi Irányítóközpont).
 *
 * Provides: SQLite init, sync engine, outbox IPC handlers, conflict policies.
 *
 * The Central Workstation (appMode='full') oversees:
 *   - Treasury operations (bank buy/sell, currency intake/distribution)
 *   - Branch balance overview (per-branch, per-currency stock positions)
 *   - Distribution tracking (treasury → branch currency sends)
 *   - Transfer management (paired events: transfer_out ↔ transfer_in)
 *   - Daily closing aggregation across branches
 *
 * LocalFirstPlan:
 *   local_store: SQLite via sql.js (Electron Main process)
 *   write_path: UI -> IPC -> Main process SQLite INSERT/UPDATE -> outbox
 *   sync_path: 30s polling push/pull with excvaluta.com backend
 *   conflict_policy:
 *     - treasury_operation: field_level_merge (draft editable, finalized=server_authority)
 *     - distribution: server_authority (once confirmed, immutable)
 *     - transfer: server_authority (paired events, server matches)
 *     - daily_closing: server_authority (finalized, immutable)
 *     - branch_status: server_authority (master data)
 *     - branch_balance: server_authority (server-calculated aggregate)
 *     - settings: last_write_wins (non-critical user prefs)
 *   invariants:
 *     - treasury stock >= 0 per currency after operation
 *     - distribution amount > 0 and <= treasury stock
 *     - transfer_out + transfer_in must pair (server-side matching)
 *     - daily_closing immutable once finalized
 *   auth_scope: companyId filtered server-side, treasury-level access
 *   migration: PRAGMA user_version + versioned migrations
 */

import { app, ipcMain, safeStorage } from 'electron';
import path from 'node:path';
import fs from 'node:fs';
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
  entityType: 'treasury_operation',
  strategy: 'field_merge',
  description: 'Treasury operations: field-level merge while draft, server authority once finalized',
  resolve: fieldMerge({
    amount: 'local',
    currency_code: 'local',
    rate: 'local',
    notes: 'local',
    operation_type: 'local',
    status: 'server',
    finalized_at: 'server',
    finalized_by: 'server',
  }),
});

conflictPolicy.registerPolicy({
  entityType: 'distribution',
  strategy: 'server_authority',
  description: 'Distributions: immutable once confirmed, server matches paired transfers',
  resolve: SERVER_AUTHORITY,
});

conflictPolicy.registerPolicy({
  entityType: 'transfer',
  strategy: 'server_authority',
  description: 'Transfers: paired events (out↔in), server is source of truth for matching',
  resolve: SERVER_AUTHORITY,
});

conflictPolicy.registerPolicy({
  entityType: 'daily_closing',
  strategy: 'server_authority',
  description: 'Daily closings: immutable once finalized',
  resolve: SERVER_AUTHORITY,
});

conflictPolicy.registerPolicy({
  entityType: 'branch_status',
  strategy: 'server_authority',
  description: 'Branch status: master data from server',
  resolve: SERVER_AUTHORITY,
});

conflictPolicy.registerPolicy({
  entityType: 'branch_balance',
  strategy: 'server_authority',
  description: 'Branch balances: server-calculated aggregate, read-only locally',
  resolve: SERVER_AUTHORITY,
});

conflictPolicy.registerPolicy({
  entityType: 'settings',
  strategy: 'last_write_wins',
  description: 'Settings: LWW acceptable, user preferences only',
  resolve: LAST_WRITE_WINS,
});

// --- Central Workstation Sync Engine ---

class CentralWorkstationSyncEngine extends SyncEngineBase {
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
    const url = `${this.apiUrl}/central/sync/pull${checkpoint ? `?since=${encodeURIComponent(checkpoint)}` : ''}`;
    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
      signal: AbortSignal.timeout(15_000),
    });

    if (!response.ok) {
      throw new Error(`Pull failed: HTTP ${response.status}`);
    }

    const data = await response.json() as {
      checkpoint: string;
      treasuryOperations?: Array<{ id: string; [key: string]: unknown }>;
      distributions?: Array<{ id: string; [key: string]: unknown }>;
      transfers?: Array<{ id: string; [key: string]: unknown }>;
      dailyClosings?: Array<{ id: string; [key: string]: unknown }>;
      branchStatuses?: Array<{ id: string; [key: string]: unknown }>;
      branchBalances?: Array<{ id: string; [key: string]: unknown }>;
      deletedIds?: Array<{ entityType: string; entityId: string }>;
    };

    let count = 0;

    if (data.treasuryOperations) {
      for (const op of data.treasuryOperations) {
        cachedEntities.upsertCached(this.db, 'treasury_operation', op.id, op, 1, String(op.updatedAt ?? ''));
        count++;
      }
    }

    if (data.distributions) {
      for (const dist of data.distributions) {
        cachedEntities.upsertCached(this.db, 'distribution', dist.id, dist, 1, String(dist.updatedAt ?? ''));
        count++;
      }
    }

    if (data.transfers) {
      for (const xfer of data.transfers) {
        cachedEntities.upsertCached(this.db, 'transfer', xfer.id, xfer, 1, String(xfer.updatedAt ?? ''));
        count++;
      }
    }

    if (data.dailyClosings) {
      for (const dc of data.dailyClosings) {
        cachedEntities.upsertCached(this.db, 'daily_closing', dc.id, dc, 1, String(dc.updatedAt ?? ''));
        count++;
      }
    }

    if (data.branchStatuses) {
      for (const bs of data.branchStatuses) {
        cachedEntities.upsertCached(this.db, 'branch_status', bs.id, bs, 1);
        count++;
      }
    }

    if (data.branchBalances) {
      for (const bb of data.branchBalances) {
        cachedEntities.upsertCached(this.db, 'branch_balance', bb.id, bb, 1);
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
    const url = `${this.apiUrl}/central/sync/push`;
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

let syncEngine: CentralWorkstationSyncEngine | null = null;
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
  const dbDir = path.join(app.getPath('home'), '.valuta-central');
  const db = await initLocalDatabase({
    dbDir,
    dbName: 'central-workstation.db',
    wasmPath: resolveWasmPath(),
  });

  cachedToken = loadPersistedToken();

  syncEngine = new CentralWorkstationSyncEngine(db, apiUrl, () => cachedToken);
  syncEngine.start();

  log.info('[LocalFirst] Central Workstation local-first initialized');
}

export function shutdownLocalFirst(): void {
  syncEngine?.stop();
  closeDatabase();
  log.info('[LocalFirst] Central Workstation local-first shutdown');
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

  // --- Treasury operations ---
  ipcMain.handle('lf:save-treasury-operation', (_event, op: Record<string, unknown>) => {
    const db = getDb();
    const entityId = String(op.id ?? crypto.randomUUID());
    const mutationId = outbox.enqueue(db, 'treasury_operation', 'CREATE', { ...op, id: entityId }, entityId);
    cachedEntities.upsertCached(db, 'treasury_operation', entityId, { ...op, id: entityId }, 1);
    saveDatabase();
    return { ok: true, mutationId, entityId };
  });

  ipcMain.handle('lf:update-treasury-operation', (_event, op: Record<string, unknown>) => {
    const db = getDb();
    const entityId = String(op.id ?? '');
    outbox.enqueue(db, 'treasury_operation', 'UPDATE', op, entityId);
    cachedEntities.upsertCached(db, 'treasury_operation', entityId, op, 1);
    saveDatabase();
    return { ok: true };
  });

  ipcMain.handle('lf:get-treasury-operations', () => {
    return cachedEntities.listCached(getDb(), 'treasury_operation');
  });

  // --- Distributions ---
  ipcMain.handle('lf:save-distribution', (_event, dist: Record<string, unknown>) => {
    const db = getDb();
    const entityId = String(dist.id ?? crypto.randomUUID());
    const mutationId = outbox.enqueue(db, 'distribution', 'CREATE', { ...dist, id: entityId }, entityId);
    cachedEntities.upsertCached(db, 'distribution', entityId, { ...dist, id: entityId }, 1);
    saveDatabase();
    return { ok: true, mutationId, entityId };
  });

  ipcMain.handle('lf:get-distributions', () => {
    return cachedEntities.listCached(getDb(), 'distribution');
  });

  // --- Transfers ---
  ipcMain.handle('lf:save-transfer', (_event, xfer: Record<string, unknown>) => {
    const db = getDb();
    const entityId = String(xfer.id ?? crypto.randomUUID());
    const mutationId = outbox.enqueue(db, 'transfer', 'CREATE', { ...xfer, id: entityId }, entityId);
    cachedEntities.upsertCached(db, 'transfer', entityId, { ...xfer, id: entityId }, 1);
    saveDatabase();
    return { ok: true, mutationId, entityId };
  });

  ipcMain.handle('lf:get-transfers', () => {
    return cachedEntities.listCached(getDb(), 'transfer');
  });

  // --- Daily closings (read-only from server, not locally created) ---
  ipcMain.handle('lf:get-daily-closings', () => {
    return cachedEntities.listCached(getDb(), 'daily_closing');
  });

  // --- Branch status (read-only from server) ---
  ipcMain.handle('lf:get-branch-statuses', () => {
    return cachedEntities.listCached(getDb(), 'branch_status');
  });

  // --- Branch balances (read-only from server, aggregated) ---
  ipcMain.handle('lf:get-branch-balances', () => {
    return cachedEntities.listCached(getDb(), 'branch_balance');
  });
}
