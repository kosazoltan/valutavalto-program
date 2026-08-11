/**
 * FKH-D2/F5 — sync-gate-elt gyari reset tesztjei.
 *
 * A legfontosabb invariáns: a gyári reset kapuja MINDEN offline outbox-táblát
 * lásson. A `getPendingTransactionCount()` csak a `pending_transactions`-t nézi
 * (1/13) — ha valaki arra épít gate-et, vagy új `pending_*` táblát vezet be és
 * elfelejti felvenni az `OUTBOX_TABLES` listába, akkor a reset szinkronizálatlan
 * pénzügyi adatot törölne csendben. Ez a teszt azt a driftet fogja el.
 */
import { describe, it, expect, vi } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';

vi.mock('electron', () => ({
  app: {
    getPath: vi.fn(() => '/tmp/test-valuta-f5'),
    getAppPath: vi.fn(() => '/tmp/test-valuta-f5-app'),
    isPackaged: false,
  },
}));

import { getUnsyncedSummary, factoryResetLocalDatabase } from '../sqlite';

const SQLITE_SRC = fs.readFileSync(path.join(__dirname, '..', 'sqlite.ts'), 'utf8');

/** A sqlite.ts sémájából kiolvasja azokat a táblákat, amelyeknek van `synced` oszlopa. */
function tablesWithSyncedColumn(src: string): string[] {
  const found: string[] = [];
  const re = /CREATE TABLE IF NOT EXISTS (\w+)\s*\(([\s\S]*?)\n\s*\)/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(src)) !== null) {
    const [, name, body] = m;
    if (name && body && /\bsynced\b/.test(body)) found.push(name);
  }
  return found;
}

/** Az OUTBOX_TABLES lista a forrásból (nem exportált konstans, szándékosan). */
function declaredOutboxTables(src: string): string[] {
  const block = src.match(/const OUTBOX_TABLES = \[([\s\S]*?)\] as const;/);
  if (!block || !block[1]) return [];
  return [...block[1].matchAll(/'([^']+)'/g)].map((x) => x[1]!);
}

describe('FKH-D2/F5 — outbox-tábla teljesség (drift-őr)', () => {
  it('minden `synced` oszlopos üzleti tábla szerepel az OUTBOX_TABLES-ben', () => {
    const declared = declaredOutboxTables(SQLITE_SRC);
    expect(declared.length).toBeGreaterThan(0);

    // A `lf_tombstone` szinkron-metaadat, nem üzleti outbox — tudatos kivétel.
    const schemaTables = tablesWithSyncedColumn(SQLITE_SRC).filter((t) => t !== 'lf_tombstone');
    expect(schemaTables.length).toBeGreaterThan(1);

    const missing = schemaTables.filter((t) => !declared.includes(t));
    expect(
      missing,
      `Új outbox-tábla NEM szerepel az OUTBOX_TABLES-ben: ${missing.join(', ')} — ` +
        'a gyári reset kapuja így szinkronizálatlan pénzügyi adatot hagyna figyelmen kívül.',
    ).toEqual([]);
  });

  it('az OUTBOX_TABLES nem hivatkozik nem létező táblára', () => {
    const declared = declaredOutboxTables(SQLITE_SRC);
    const schemaTables = tablesWithSyncedColumn(SQLITE_SRC);
    const bogus = declared.filter((t) => !schemaTables.includes(t));
    expect(bogus, `Nem létező tábla az OUTBOX_TABLES-ben: ${bogus.join(', ')}`).toEqual([]);
  });

  it('a gate szélesebb, mint a getPendingTransactionCount (nem 1 táblás)', () => {
    // Ez az invariáns rögzíti a felfedezett hibát: a szűk count-ra épülő gate
    // hamis biztonságot adna.
    expect(declaredOutboxTables(SQLITE_SRC).length).toBeGreaterThan(1);
    expect(declaredOutboxTables(SQLITE_SRC)).toContain('pending_transactions');
  });
});

describe('FKH-D2/F5 — viselkedés inicializálatlan DB mellett', () => {
  it('getUnsyncedSummary üres összegzést ad, ha nincs betöltve DB', () => {
    const summary = getUnsyncedSummary();
    expect(summary.total).toBe(0);
    expect(summary.byTable).toEqual({});
  });

  it('factoryResetLocalDatabase nem bukik el, ha nincs adatbázis-fájl', () => {
    const result = factoryResetLocalDatabase();
    expect(result.ok).toBe(true);
    // Nem volt mit törölni -> nincs deletedPath.
    expect(result.deletedPath).toBeUndefined();
    expect(result.blockedBy).toBeUndefined();
  });
});
