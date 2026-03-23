/**
 * Pénztár Electron SQLite cache mintavétel (SyncEngine).
 * Futtatás: cd penztar-client && node ../scripts/smoke/tmp-read-electron-cache.js
 * (a sql.js a penztar-client node_modules-ból töltődik)
 */
const fs = require('fs');
const path = require('path');
const os = require('os');
const initSqlJs = require(path.join(process.cwd(), 'node_modules', 'sql.js'));

function execFirstRow(db, sql) {
  const r = db.exec(sql);
  return r[0]?.values?.[0] ?? null;
}

(async () => {
  const SQL = await initSqlJs({
    locateFile: (file) => path.join(process.cwd(), 'node_modules', 'sql.js', 'dist', file),
  });

  const dbPath = path.join(os.homedir(), '.valuta', 'local.db');
  if (!fs.existsSync(dbPath)) {
    console.log(JSON.stringify({ error: 'NO_DB', dbPath, hint: 'Indítsd a pénztárat és jelentkezz be.' }));
    process.exit(0);
  }

  const db = new SQL.Database(fs.readFileSync(dbPath));

  // Bármely sor (nem fix id=1 / KORUT — különböző seed / iroda)
  const worker = execFirstRow(
    db,
    'SELECT id, worker_code, full_name, cached_at FROM cached_workers ORDER BY id LIMIT 1;',
  );
  const cashDesk = execFirstRow(
    db,
    'SELECT id, code, name, cached_at FROM cached_cash_desks ORDER BY id LIMIT 1;',
  );
  const workerTs = execFirstRow(db, 'SELECT MAX(cached_at) FROM cached_workers;');
  const cashDeskTs = execFirstRow(db, 'SELECT MAX(cached_at) FROM cached_cash_desks;');

  const workerCount = execFirstRow(db, 'SELECT COUNT(*) FROM cached_workers;');
  const cashDeskCount = execFirstRow(db, 'SELECT COUNT(*) FROM cached_cash_desks;');

  console.log(
    JSON.stringify(
      {
        dbPath,
        worker,
        cashDesk,
        workerTs: workerTs?.[0] ?? null,
        cashDeskTs: cashDeskTs?.[0] ?? null,
        workerCount: workerCount?.[0] ?? 0,
        cashDeskCount: cashDeskCount?.[0] ?? 0,
      },
      null,
      0,
    ),
  );
})();
