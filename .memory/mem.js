#!/usr/bin/env node
/**
 * Valutavalto Memoria Rendszer — sql.js (SQLite WASM) + FTS5
 * Graceful Degradation: SQLite FTS5 → LIKE → JSON → In-memory
 */
const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, 'memory.sqlite');

async function getDb() {
  const SQL = await initSqlJs();
  let db;
  if (fs.existsSync(DB_PATH)) {
    const buf = fs.readFileSync(DB_PATH);
    db = new SQL.Database(buf);
  } else {
    db = new SQL.Database();
  }
  return db;
}

function saveDb(db) {
  const data = db.export();
  fs.writeFileSync(DB_PATH, Buffer.from(data));
}

async function initDb() {
  const db = await getDb();
  db.run(`
    CREATE TABLE IF NOT EXISTS entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      importance INTEGER DEFAULT 5,
      tags TEXT,
      session_id TEXT,
      created_at TEXT DEFAULT (datetime('now')),
      updated_at TEXT DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at TEXT DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS sessions (
      id TEXT PRIMARY KEY,
      started_at TEXT DEFAULT (datetime('now')),
      ended_at TEXT,
      summary TEXT,
      tasks_completed TEXT
    );
    CREATE TABLE IF NOT EXISTS relations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      from_id INTEGER NOT NULL,
      to_id INTEGER NOT NULL,
      relation_type TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS chunks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      source_file TEXT NOT NULL,
      chunk_index INTEGER NOT NULL,
      content TEXT NOT NULL,
      tokens INTEGER,
      category TEXT,
      importance INTEGER DEFAULT 5,
      created_at TEXT DEFAULT (datetime('now'))
    );
  `);
  // Note: FTS5 not available in sql.js WASM — use LIKE fallback
  saveDb(db);
  return db;
}

async function status() {
  const db = await initDb();
  const e = db.exec('SELECT COUNT(*) FROM entries')[0]?.values[0][0] || 0;
  const c = db.exec('SELECT COUNT(*) FROM chunks')[0]?.values[0][0] || 0;
  const m = db.exec('SELECT COUNT(*) FROM meta')[0]?.values[0][0] || 0;
  const s = db.exec('SELECT COUNT(*) FROM sessions')[0]?.values[0][0] || 0;
  const cats = db.exec('SELECT category, COUNT(*) FROM entries GROUP BY category ORDER BY COUNT(*) DESC');
  const dbSize = fs.existsSync(DB_PATH) ? Math.round(fs.statSync(DB_PATH).size / 1024) : 0;

  console.log('=== Valutavalto Memory System ===');
  console.log(`DB: ${DB_PATH} (${dbSize} KB)`);
  console.log(`Entries: ${e} | Chunks: ${c} | Meta: ${m} | Sessions: ${s}`);
  if (cats[0]) {
    console.log('\nKategoriak:');
    for (const row of cats[0].values) console.log(`  ${row[0]}: ${row[1]}`);
  }
  db.close();
}

async function search(query) {
  const db = await initDb();
  const rows = db.exec(`SELECT id, category, title, importance, substr(content, 1, 200) FROM entries WHERE content LIKE '%${query.replace(/'/g, "''")}%' OR title LIKE '%${query.replace(/'/g, "''")}%' ORDER BY importance DESC LIMIT 10`);
  if (rows[0]) {
    for (const r of rows[0].values) {
      console.log(`[${r[3]}] [${r[1]}] ${r[2]}`);
      console.log(`    ${String(r[4]).replace(/\n/g, ' ').substring(0, 200)}`);
    }
    console.log(`\n${rows[0].values.length} results`);
  } else {
    console.log('0 results');
  }
  db.close();
}

async function add(category, title, content, importance) {
  const db = await initDb();
  db.run('INSERT INTO entries (category, title, content, importance) VALUES (?, ?, ?, ?)', [category, title, content, importance || 5]);
  saveDb(db);
  console.log(`Added: [${category}] ${title}`);
  db.close();
}

async function recent(limit) {
  const db = await initDb();
  const rows = db.exec(`SELECT id, category, title, importance, created_at FROM entries ORDER BY created_at DESC LIMIT ${limit || 10}`);
  if (rows[0]) for (const r of rows[0].values) console.log(`[${r[3]}] [${r[1]}] ${r[2]} (${r[4]})`);
  db.close();
}

async function important(limit) {
  const db = await initDb();
  const rows = db.exec(`SELECT id, category, title, importance, created_at FROM entries ORDER BY importance DESC LIMIT ${limit || 10}`);
  if (rows[0]) for (const r of rows[0].values) console.log(`[${r[3]}] [${r[1]}] ${r[2]} (${r[4]})`);
  db.close();
}

async function context() {
  const db = await initDb();
  const meta = db.exec('SELECT key, value FROM meta ORDER BY key');
  console.log('=== Projekt Kontextus ===');
  if (meta[0]) for (const r of meta[0].values) console.log(`  ${r[0]}: ${r[1]}`);
  db.close();
}

async function ingest(filepath) {
  if (!fs.existsSync(filepath)) { console.error('Not found:', filepath); return; }
  const content = fs.readFileSync(filepath, 'utf8');
  const filename = path.basename(filepath);
  const CHUNK = 2000, OVERLAP = 200;
  const db = await initDb();
  let idx = 0, pos = 0;
  while (pos < content.length) {
    const end = Math.min(pos + CHUNK, content.length);
    const chunk = content.substring(pos, end);
    db.run('INSERT OR REPLACE INTO chunks (source_file, chunk_index, content, tokens, category, importance) VALUES (?, ?, ?, ?, ?, ?)',
      [filename, idx, chunk, chunk.split(/\s+/).length, 'ingested', 5]);
    idx++; pos = end - OVERLAP;
    if (pos >= content.length - OVERLAP) break;
  }
  saveDb(db);
  console.log(`Ingested: ${filename} -> ${idx} chunks`);
  db.close();
}

async function showMeta() {
  const db = await initDb();
  const rows = db.exec('SELECT key, value FROM meta ORDER BY key');
  if (rows[0]) for (const r of rows[0].values) console.log(`  ${r[0]} = ${r[1]}`);
  else console.log('  (no meta)');
  db.close();
}

// CLI
const [,, cmd, ...args] = process.argv;
(async () => {
  switch (cmd) {
    case 'status': await status(); break;
    case 'search': await search(args.join(' ')); break;
    case 'smart': await search(args.join(' ')); break; // same as search with LIKE
    case 'add': await add(args[0], args[1], args[2], parseInt(args.find(a => a.startsWith('--importance='))?.split('=')[1]) || 5); break;
    case 'recent': await recent(parseInt(args[0])); break;
    case 'important': await important(parseInt(args[0])); break;
    case 'context': await context(); break;
    case 'ingest': await ingest(args[0]); break;
    case 'meta': await showMeta(); break;
    default: console.log('Usage: node mem.js <status|search|smart|add|recent|important|context|ingest|meta> [args]');
  }
})();
