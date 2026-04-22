// Quick-fix: beirja a branch_code-ot a user SQLite config tablajaba, ha hianyzik.
// Hasznalat: node scripts/fix-branch-code.mjs [branch_code] [company_code]
//
// Miert kell: a v2.1.3 elott a SetupWizard NEM irta be az SQLite config tablaba
// a branch_code erteket (csak a .env-be). A v2.1.4+ ezt mar megteszi,
// de a regebbi telepiteseken a savePendingTransaction elszall ezzel a
// hibaval: "SetupWizard nem futott le: branch_code SQLite config hianyzik".
//
// Ez a script idempotens: ha mar be van irva, nem csinal semmit.
// Forras: process.env.VITE_BRANCH_CODE (ha van) vagy parancssor-argumentum.

import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const initSqlJs = require('sql.js');

const DB_PATH = path.join(os.homedir(), '.valuta', 'local.db');
// AI REVIEW FIX (PR #97 Codex P2 + Sourcery): kerunk EXPLICIT argumentumot vagy env valtozot -
// nincs csendes 'EBC' fallback, mert az masik ceg gepen hibas configot ir.
const FALLBACK_BRANCH = process.argv[2] || process.env.VITE_BRANCH_CODE || '';
const FALLBACK_COMPANY = process.argv[3] || process.env.VITE_COMPANY_CODE || process.env.PENZTAR_BOOTSTRAP_COMPANY_CODE || '';
if (!FALLBACK_BRANCH || !FALLBACK_COMPANY) {
  console.error('[fix-branch-code] HIBA: branch_code es/vagy company_code hianyzik!');
  console.error('  Hasznalat:  node scripts/fix-branch-code.mjs <branch_code> <company_code>');
  console.error('  vagy env:   VITE_BRANCH_CODE=EBC VITE_COMPANY_CODE=EBC node scripts/fix-branch-code.mjs');
  process.exit(2);
}

async function main() {
  if (!fs.existsSync(DB_PATH)) {
    console.error('[fix-branch-code] SQLite fajl nem letezik: ' + DB_PATH);
    console.error('  Indits el eloszor a penztar-klienst (npm run dev) hogy letrejojjon.');
    process.exit(1);
  }

  // AI REVIEW FIX (PR #97 Sourcery P2): cwd-independent wasm resolve.
  // A process.cwd() brittle ha a script mashonnan hivjak, pl. global install.
  // Helyette import.meta.url alapjan a script-relativ node_modules-t kutatjuk.
  const scriptDir = path.dirname(new URL(import.meta.url).pathname.replace(/^\//, ''));
  const wasmCandidates = [
    path.resolve(scriptDir, '../node_modules/sql.js/dist/sql-wasm.wasm'),
    path.resolve(scriptDir, '../../node_modules/sql.js/dist/sql-wasm.wasm'),
    path.resolve(process.cwd(), 'node_modules/sql.js/dist/sql-wasm.wasm'),
  ];
  const wasmPath = wasmCandidates.find((p) => fs.existsSync(p));
  if (!wasmPath) {
    // Sourcery P2 fix: wasmPath undefined, helyette a kerestett path-ok listaja informativ
    console.error('[fix-branch-code] sql-wasm.wasm egyik keresett path-on sem talalhato:');
    for (const p of wasmCandidates) {
      console.error('  - ' + p);
    }
    console.error('  Futtasd: npm install (penztar-client modulon belul)');
    process.exit(1);
  }

  const wasmBinary = fs.readFileSync(wasmPath);
  const SQL = await initSqlJs({ wasmBinary });
  const buffer = fs.readFileSync(DB_PATH);
  const db = new SQL.Database(buffer);

  const tableCheck = db.exec("SELECT name FROM sqlite_master WHERE type='table' AND name='config'");
  if (tableCheck.length === 0) {
    console.error('[fix-branch-code] A config tabla nem letezik az SQLite-ban. Inditsd el eloszor a penztar-klienst.');
    db.close();
    process.exit(1);
  }

  const currentBranch = db.exec("SELECT value FROM config WHERE key='branch_code'");
  const currentCompany = db.exec("SELECT value FROM config WHERE key='bootstrap_company_code'");

  const branchValue = currentBranch[0]?.values?.[0]?.[0] ?? null;
  const companyValue = currentCompany[0]?.values?.[0]?.[0] ?? null;

  console.log('[fix-branch-code] Jelenlegi SQLite config:');
  console.log('  branch_code            = ' + (branchValue ?? '(hianyzik)'));
  console.log('  bootstrap_company_code = ' + (companyValue ?? '(hianyzik)'));

  let changed = false;

  if (!branchValue) {
    const stmt = db.prepare("INSERT OR REPLACE INTO config (key, value, updated_at) VALUES (?, ?, datetime('now'))");
    stmt.run(['branch_code', FALLBACK_BRANCH]);
    stmt.free();
    console.log('[fix-branch-code] branch_code = "' + FALLBACK_BRANCH + '" beirva.');
    changed = true;
  }

  if (!companyValue) {
    const stmt = db.prepare("INSERT OR REPLACE INTO config (key, value, updated_at) VALUES (?, ?, datetime('now'))");
    stmt.run(['bootstrap_company_code', FALLBACK_COMPANY]);
    stmt.free();
    console.log('[fix-branch-code] bootstrap_company_code = "' + FALLBACK_COMPANY + '" beirva.');
    changed = true;
  }

  if (changed) {
    const data = db.export();
    fs.writeFileSync(DB_PATH, Buffer.from(data));
    console.log('[fix-branch-code] SQLite mentve: ' + DB_PATH);
  } else {
    console.log('[fix-branch-code] Nincs teendo - minden ertek be van allitva.');
  }

  db.close();
}

main().catch((err) => {
  console.error('[fix-branch-code] Hiba:', err);
  process.exit(1);
});
