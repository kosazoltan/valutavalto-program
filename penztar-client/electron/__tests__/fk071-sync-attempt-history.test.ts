/**
 * FK-071 FR-5 — RED-fázis specifikációs teszt (implementáció nélkül, buknia kell).
 *
 * Given: egy pending tranzakció többször is elutasításra kerül (automatikus vagy
 *        kézi újraküldésnél), majd végül sikeresen felmegy.
 * When:  minden egyes kísérlet lezajlik (markTransactionSyncError / markTransactionSynced).
 * Then:  időbélyeg + eredmény (siker / hiba+üzenet) hozzáfűzésre kerül egy
 *        kísérlet-történethez a tételen, BELSŐ (nem-UI-exponált) formában.
 *
 * Szerződés, amit ez a teszt rögzít (review tárgya, GREEN-fázis előtt):
 *  - Új exportált olvasó a sqlite modulban: getTransactionSyncAttemptHistory(id)
 *    → Array<{ attemptedAt: string; outcome: 'SUCCESS' | 'ERROR'; message?: string | null }>
 *  - A meglévő markTransactionSyncError(id, error, attemptIso) hívás hibás
 *    kísérletként (outcome: 'ERROR', message: error, attemptedAt: attemptIso) fűz hozzá.
 *  - A meglévő markTransactionSynced(id) sikeres kísérletként (outcome: 'SUCCESS')
 *    fűz hozzá, időbélyeggel.
 *  - A történet csak belső diagnosztika: a UI-nonexponálást a
 *    TransactionListPage.fk071.test.tsx külön guard-tesztje rögzíti.
 *
 * Jelenlegi (bukó) viselkedés: nincs kísérlet-történet — csak sync_error (utolsó
 * hiba), sync_attempts (számláló) és last_attempt_at (utolsó időpont) létezik,
 * a getTransactionSyncAttemptHistory export nem létezik.
 */
import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const mockState = vi.hoisted(() => ({
  tempHome: '',
}));

vi.mock('electron', () => ({
  app: {
    getPath: vi.fn(() => mockState.tempHome),
    getAppPath: vi.fn(() => mockState.tempHome),
    isPackaged: false,
  },
}));

import * as sqlite from '../sqlite';
import { getDb, initDatabase, markTransactionSynced, markTransactionSyncError } from '../sqlite';

/** Minimális pending tranzakció beszúrása közvetlen SQL-lel; a beszúrt sor id-jét adja vissza. */
function insertPendingTx(): number {
  const db = getDb();
  if (!db) throw new Error('Database not initialized');
  db.run(
    `INSERT INTO pending_transactions
       (type, currency_code, foreign_amount, huf_amount, rounded_huf_amount, rate, synced)
     VALUES ('BUY', 'EUR', 100, 40000, 40000, 400, 0)`,
  );
  const stmt = db.prepare('SELECT last_insert_rowid() AS id');
  stmt.step();
  const row = stmt.getAsObject() as { id?: number };
  stmt.free();
  if (!row.id) throw new Error('Insert failed');
  return row.id;
}

type SyncAttemptEntry = {
  attemptedAt: string;
  outcome: 'SUCCESS' | 'ERROR';
  message?: string | null;
};

/**
 * A még nem létező exportot futásidőben oldjuk fel, hogy a typecheck zöld
 * maradjon, a teszt viszont PIROSAN bukjon, amíg az implementáció hiányzik.
 */
function resolveHistoryReader(): ((id: number) => SyncAttemptEntry[]) | undefined {
  const candidate = (sqlite as unknown as Record<string, unknown>)[
    'getTransactionSyncAttemptHistory'
  ];
  return typeof candidate === 'function'
    ? (candidate as (id: number) => SyncAttemptEntry[])
    : undefined;
}

describe('FK-071 FR-5 — sync-kísérlet-történet (belső napló)', () => {
  beforeAll(async () => {
    mockState.tempHome = fs.mkdtempSync(path.join(os.tmpdir(), 'fk071-attempt-history-'));
    await initDatabase();
  });

  beforeEach(() => {
    const db = getDb();
    if (!db) throw new Error('Database not initialized');
    db.run('DELETE FROM pending_transactions');
  });

  afterAll(() => {
    fs.rmSync(mockState.tempHome, { recursive: true, force: true });
  });

  it('FR-5: minden kísérlet (2 hiba + 1 siker) időbélyeggel és eredménnyel kerül a kísérlet-történetbe', () => {
    const id = insertPendingTx();

    markTransactionSyncError(
      id,
      'HTTP 400 — Árfolyam-eltérés a kihirdetett árfolyamhoz képest',
      '2026-07-29T10:00:00.000Z',
    );
    markTransactionSyncError(
      id,
      'HTTP 422 — Fedezethiány: nincs elegendő EUR készlet',
      '2026-07-29T10:05:00.000Z',
    );
    markTransactionSynced(id);

    const getTransactionSyncAttemptHistory = resolveHistoryReader();
    expect(
      getTransactionSyncAttemptHistory,
      'Hiányzó export: getTransactionSyncAttemptHistory(id) a sqlite modulban (FK-071 FR-5 szerződés)',
    ).toBeTypeOf('function');

    const history = getTransactionSyncAttemptHistory!(id);

    expect(Array.isArray(history)).toBe(true);
    expect(history).toHaveLength(3);

    // 1. kísérlet: hiba, a megadott időbélyeggel és üzenettel
    expect(history[0]!.outcome).toBe('ERROR');
    expect(history[0]!.attemptedAt).toBe('2026-07-29T10:00:00.000Z');
    expect(history[0]!.message).toContain('Árfolyam-eltérés');

    // 2. kísérlet: hiba, az ÚJ üzenettel (a történet nem íródik felül, hanem bővül)
    expect(history[1]!.outcome).toBe('ERROR');
    expect(history[1]!.attemptedAt).toBe('2026-07-29T10:05:00.000Z');
    expect(history[1]!.message).toContain('Fedezethiány');

    // 3. kísérlet: siker, időbélyeggel
    expect(history[2]!.outcome).toBe('SUCCESS');
    expect(history[2]!.attemptedAt).toBeTruthy();
  });

  it('FR-5: a kísérlet-történet tételenként elkülönül (másik tétel története üres marad)', () => {
    const idA = insertPendingTx();
    const idB = insertPendingTx();

    markTransactionSyncError(idA, 'HTTP 400 — Validációs hiba', '2026-07-29T11:00:00.000Z');

    const getTransactionSyncAttemptHistory = resolveHistoryReader();
    expect(
      getTransactionSyncAttemptHistory,
      'Hiányzó export: getTransactionSyncAttemptHistory(id) a sqlite modulban (FK-071 FR-5 szerződés)',
    ).toBeTypeOf('function');

    expect(getTransactionSyncAttemptHistory!(idA)).toHaveLength(1);
    expect(getTransactionSyncAttemptHistory!(idB)).toHaveLength(0);
  });
});
