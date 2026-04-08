const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');
const DB_PATH = path.join(__dirname, 'memory.sqlite');

async function main() {
const SQL = await initSqlJs();
let db;
if (fs.existsSync(DB_PATH)) { db = new SQL.Database(fs.readFileSync(DB_PATH)); }
else { db = new SQL.Database(); }

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
`);

function insertEntry(cat, title, content, imp, tags) {
  db.run('INSERT INTO entries (category, title, content, importance, tags) VALUES (?, ?, ?, ?, ?)', [cat, title, content, imp, tags]);
}
function insertMeta(key, value) {
  db.run('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)', [key, value]);
}

// ============ META ============
const meta = {
  'project.name': 'Valutavalto Penztar',
  'project.version': '1.9.0',
  'project.type': 'Multi-branch currency exchange ERP',
  'tech.backend': 'Spring Boot 3.2, Java 21, PostgreSQL 16',
  'tech.frontend': 'React 18, TypeScript, Vite, Tailwind CSS, shadcn/ui',
  'tech.electron': 'Electron 41.1.1, sql.js (SQLite WASM), offline-first sync',
  'tech.server': 'Hetzner VPS (95.216.191.162), Ubuntu 24.04, nginx, Let\'s Encrypt',
  'tech.db.encryption': 'LUKS disk encryption (AES-256)',
  'tech.db.backup': 'Neon PostgreSQL replication (feature flag OFF)',
  'infra.domain': 'excvaluta.com',
  'infra.branches': '2 (Korut, Tisza Sarok) — dynamikus, legacy 1-180',
  'infra.workers': '4 (BORSI/CASHIER, BALI/CASHIER, KASZA/CASHIER, KOSA/MANAGER)',
  'pipeline': 'Junior kod → Eszter review → Tamas teszt → Bence security → deploy',
  'installer': 'NSIS Electron, per-user install, 101 MB',
};
for (const [k, v] of Object.entries(meta)) insertMeta(k, v);

// ============ ARCHITECTURE ============
const arch = [
  ['Ertektari modszer', 'A valutavaltas kizarolag helyi Electron app-ban tortenik. excvaluta.com weben NINCS React SPA — CSAK API backend + landing page. Az Electron sync-engine 30s-enkent szinkronizal a szerverrel.', 10, 'electron,sync,architecture'],
  ['192 Backend Service', 'A backend 192 Spring Boot service-bol all: TransactionService, DailyClosingService, EveningClosingService, TrbExportService, MnbReportService, AmlService, stb. Minden endpoint @PreAuthorize-al vedett, SecurityUtils.getCurrentCompanyId() multi-tenant szures.', 9, 'backend,security'],
  ['Offline-first Electron', 'Az Electron kliens SQLite-ban tarol pending tranzakciokat (pending_transactions, pending_conversions, stb). A sync-engine POST-olja a szerverre, idempotency_key-vel. Ha offline: lokalis queue. 180 napos retencio a synced=1 rekordokon.', 9, 'electron,sync,offline'],
  ['Legacy 95% lefedettseg', 'A legacy Delphi rendszer (30 DLL/unit, Firebird DB, receptor pattern) 95%-ban portolva. Gap: POS Borgun/Worldline driver (G1-G2), Darius transport (G3). A receptor pattern szandekosan kihagyva — centralizalt DB helyettesiti.', 8, 'legacy,gap'],
  ['Esti zaras 9+16 lepes', 'DailyClosingService: 9 technikai lepes (MTCN, cimletezesek, NAV kontroll, dekad, havi gyujto). ClosingWizardSteps: 16 lepes a felhasznaloi varazsloban. EveningClosingService: napi adatcsomag (JSON REST, nem FTP).', 8, 'closing,legacy'],
];
for (const [title, content, imp, tags] of arch) insertEntry('architecture', title, content, imp, tags);

// ============ DECISIONS ============
const decisions = [
  ['Valutavaltas CSAK Electron', 'Zoltan dontese 2026-04-01: valutavaltas kizarolag helyi Electron alkalmazasban. excvaluta.com weben NINCS valutavaltas, NINCS ertektar. A szerver szerepe: API backend + jovobeli riportok.', 10, 'architecture,zoltan'],
  ['Hetzner VPS a production', 'Zoltan dontese: Hetzner VPS (95.216.191.162) a production szerver, NEM Render. Deploy SSH-val, shared/hetzner-vps-ops-runbook.md szerint.', 10, 'infra,deploy'],
  ['VPN szandekosan mellozve', 'Zoltan dontese: WireGuard VPN NEM szukseges — Cloudflare + TLS + JWT + UFW elegseges.', 9, 'security'],
  ['LUKS disk titkositas', 'Customer @Convert (mezo-szintu AES) VISSZAVONVA — adatvesztes kockazat. Helyette LUKS disk titkositas a Hetzner szerveren. 0% adatvesztes, teljes kompatibilitas.', 9, 'security,gdpr'],
  ['180 napos helyi retencio', 'Zoltan dontese 2026-04-08: synced pending rekordok 180 napig megmaradnak helyben. Igy szerver adatvesztes eseten a helyi gepekbol rekonstrualhato.', 8, 'sync,retention'],
  ['INS-143 Pipeline tilalom', 'Installer EXE NEM keszitheto es NEM kuldheto amig Eszter+Tamas+Bence PASS. Teszteletlen kodbol installer TILOS.', 10, 'pipeline,governance'],
  ['Cron modell diverzitas', '4 modell 4 perspektiva: Qwen3-30B (lokal $0), GLM-4.7-Flash (lokal $0), Haiku ($0.25/M), GPT-4.1-mini ($0.40/M). Opus cron-ban TILOS.', 7, 'cron,cost'],
];
for (const [title, content, imp, tags] of decisions) insertEntry('decision', title, content, imp, tags);

// ============ LEARNINGS ============
const learnings = [
  ['foreignAmount nem letezik', 'Transaction entity-ben currencyAmount a helyes mezonev, NEM foreignAmount. Hibernate PathElementException ha rosszul hivatkozunk.', 9, 'bug,entity'],
  ['Penztar szam DB-bol', 'Soha nem feltetelezni a penztar/iroda darabszamot dokumentaciobol — MINDIG SELECT COUNT(*) FROM branch. Production: 2 branch (Korut, Tisza Sarok), 4 worker.', 9, 'data,governance'],
  ['PowerShell BOM hiba', 'ConvertTo-Json BOM-ot ir → package.json parse error. Megoldas: .NET WriteAllText(UTF8NoBOM) vagy node-dal irni.', 7, 'bug,powershell'],
  ['DenominationType.COIN', 'Denomination entity-ben denominationType enum (BANKNOTE/COIN), NEM isCoin() boolean getter. Build error ha rosszul hivatkozunk.', 8, 'bug,entity'],
  ['Sandbox felteteles', 'Windows 11 Insider 26200+ Chromium sandbox FAIL. Megoldas: osBuild >= 26200 eseten no-sandbox, egyebkent sandbox ON. Electron 41.1.1.', 8, 'electron,bug'],
  ['gpt41mini alias nem mukodik', 'Cron job-ban a model alias (gpt41mini) NEM mukodik — teljes provider/model nev kell (openai/gpt-4.1-mini).', 7, 'cron,bug'],
  ['Sztorno 3-as limit MAR VAN', 'StornoService.DAILY_STORNO_LIMIT_BRANCH=3, DAILY_STORNO_LIMIT_CASHIER=2. Supervisor jovahagyas limit felett. Nem kell ujraimplementalni.', 8, 'feature,storno'],
  ['Customer @Convert kockazatos', 'JPA @Convert(EncryptedStringConverter) az erzekeny Customer mezokon adatvesztest okozhat ha a key elveszik. Ezert LUKS disk titkositas helyette.', 9, 'security,decision'],
];
for (const [title, content, imp, tags] of learnings) insertEntry('learning', title, content, imp, tags);

// ============ CONTEXT ============
const contexts = [
  ['TRB Export implementalva', 'TrbExportService: legacy unit5.pas WImport modern megvalositasa. Preview JSON + TXT + Excel. 3 JELENTES szekció: PENZTARALLOMANY, UGYFELFORGALOM, BANKIFORGALOM. Bankkartyás megkulonboztetes implementalva (sumCardSalesByCurrencyAndBranchAndDate).', 7, 'feature,trb'],
  ['Ketiranyu sync', 'Penztar→Szerver: sync-engine.ts syncAll() 30s-enkent. Szerver→Penztar: SyncRestoreController GET /api/v1/sync/restore/transactions. 180 napos retencio: cleanupSyncedPendingRecords.', 8, 'sync,feature'],
  ['7 cimletezesi strategia', 'DenominationOptimizationService: GREEDY, MIN_BANKNOTES, MIN_TOTAL, DYNAMIC, MIN_COINS, CUSTOM, BRANCH_SPECIFIC. MIN_COINS: bankjegy eloszor, erme maradek.', 6, 'feature,denomination'],
  ['Arfolyam-elteres sztornokor', 'StornoCheckResultDto: +originalRate, +currentRate, +rateDifference, +rateChanged. A checkStorno az aktualis branch-hoz tartozo ExchangeRate-bol amount-aware arfolyamot valaszt (getBuyRateForAmount / getSellRateForAmount a hufAmount alapjan).', 7, 'feature,storno'],
  ['Felmeres tudasbazis', 'docs/valuta-knowledge.sqlite: 414 Felmeres dok (DOCX, XLSX, CSV, TXT, PDF, kep, hang). 6 Whisper transzkripció. FTS5 kereso: docs/valuta-kb-search.py.', 6, 'knowledge,felmeres'],
];
for (const [title, content, imp, tags] of contexts) insertEntry('context', title, content, imp, tags);

fs.writeFileSync(DB_PATH, Buffer.from(db.export()));
console.log(`Seeded: ${arch.length} architecture, ${decisions.length} decisions, ${learnings.length} learnings, ${contexts.length} context, ${Object.keys(meta).length} meta`);
db.close();
}
main();
