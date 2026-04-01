const require_chunk = require("./chunk-DyKKrNZQ.js");
let electron = require("electron");
let electron_log_main = require("electron-log/main");
electron_log_main = require_chunk.__toESM(electron_log_main);
let node_path = require("node:path");
node_path = require_chunk.__toESM(node_path);
let node_url = require("node:url");
let sql_js = require("sql.js");
sql_js = require_chunk.__toESM(sql_js);
let node_fs = require("node:fs");
node_fs = require_chunk.__toESM(node_fs);
let node_crypto = require("node:crypto");
node_crypto = require_chunk.__toESM(node_crypto);
//#region electron/sqlite.ts
var db = null;
var dbPath = "";
function getDbPath() {
	const userDir = electron.app.getPath("home");
	const valutaDir = node_path.default.join(userDir, ".valuta");
	if (!node_fs.default.existsSync(valutaDir)) try {
		node_fs.default.mkdirSync(valutaDir, { recursive: true });
	} catch (err) {
		const message = err instanceof Error ? err.message : String(err);
		throw new Error(`Nem sikerült létrehozni a valuta mappát: ${valutaDir}. ${message}`, { cause: err });
	}
	return node_path.default.join(valutaDir, "local.db");
}
function resolveWasmPath() {
	const candidates = [];
	if (electron.app.isPackaged) {
		candidates.push(node_path.default.join(process.resourcesPath, "sql-wasm.wasm"));
		candidates.push(node_path.default.join(electron.app.getAppPath(), "resources", "sql-wasm.wasm"));
		candidates.push(node_path.default.join(electron.app.getAppPath(), "sql-wasm.wasm"));
		candidates.push(node_path.default.join(__dirname, "sql-wasm.wasm"));
	} else {
		candidates.push(node_path.default.join(__dirname, "../node_modules/sql.js/dist/sql-wasm.wasm"));
		candidates.push(node_path.default.join(process.cwd(), "node_modules/sql.js/dist/sql-wasm.wasm"));
	}
	for (const candidate of candidates) if (node_fs.default.existsSync(candidate)) return candidate;
	throw new Error(`sql-wasm.wasm nem található. Próbált útvonalak: ${candidates.join(" | ")}`);
}
async function initDatabase() {
	try {
		dbPath = getDbPath();
		const wasmPath = resolveWasmPath();
		const SQL = await (0, sql_js.default)({ wasmBinary: node_fs.default.readFileSync(wasmPath) });
		if (node_fs.default.existsSync(dbPath)) {
			const buffer = node_fs.default.readFileSync(dbPath);
			db = new SQL.Database(buffer);
		} else db = new SQL.Database();
		db.run("PRAGMA foreign_keys = ON;");
		db.run(`
      CREATE TABLE IF NOT EXISTS config (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT DEFAULT (datetime('now'))
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS cached_rates (
        currency_code TEXT PRIMARY KEY,
        buy_rate REAL NOT NULL,
        sell_rate REAL NOT NULL,
        unit INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL,
        official_rate REAL,
        limit1_amount REAL,
        limit1_buy_rate REAL,
        limit1_sell_rate REAL,
        limit2_amount REAL,
        limit2_buy_rate REAL,
        limit2_sell_rate REAL,
        limit3_amount REAL,
        limit3_buy_rate REAL,
        limit3_sell_rate REAL
      );
    `);
		for (const col of [
			"official_rate",
			"limit1_amount",
			"limit1_buy_rate",
			"limit1_sell_rate",
			"limit2_amount",
			"limit2_buy_rate",
			"limit2_sell_rate",
			"limit3_amount",
			"limit3_buy_rate",
			"limit3_sell_rate"
		]) try {
			db.run(`ALTER TABLE cached_rates ADD COLUMN ${col} REAL`);
		} catch {}
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('SELL', 'BUY')),
        currency_code TEXT NOT NULL,
        foreign_amount REAL NOT NULL,
        huf_amount REAL NOT NULL,
        rounded_huf_amount REAL NOT NULL,
        rate REAL NOT NULL,
        handling_fee REAL,
        discount_percent REAL,
        customer_id INTEGER,
        customer_identifier TEXT,
        customer_name TEXT,
        customer_document_number TEXT,
        customer_address TEXT,
        denominations TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_conversions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_currency_id INTEGER,
        from_currency_code TEXT NOT NULL,
        to_currency_id INTEGER,
        to_currency_code TEXT NOT NULL,
        from_amount REAL NOT NULL,
        calculated_huf_amount REAL NOT NULL,
        calculated_to_amount REAL NOT NULL,
        conversion_rate REAL NOT NULL,
        handling_fee REAL,
        customer_id TEXT,
        customer_name TEXT,
        customer_document_number TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_bank_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_type TEXT NOT NULL CHECK(transaction_type IN ('BUY', 'SELL')),
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        exchange_rate REAL NOT NULL,
        huf_amount REAL NOT NULL,
        vault_territory_id INTEGER,
        bank_name TEXT,
        bank_reference TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_stornos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        original_receipt_number TEXT NOT NULL,
        original_transaction_type TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        foreign_amount REAL,
        huf_amount REAL NOT NULL,
        exchange_rate REAL,
        reason TEXT NOT NULL,
        approval_id TEXT,
        custom_exchange_rate REAL,
        payment_method TEXT,
        customer_name TEXT,
        customer_document_number TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_handover_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL CHECK(operation_type IN ('GENERATE', 'PRINT', 'COMPLETE')),
        sheet_id TEXT,
        from_cash_desk_id TEXT,
        to_cash_desk_id TEXT,
        transfer_date TEXT,
        amounts_json TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS local_audit_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        event_type TEXT NOT NULL,
        reference_number TEXT,
        entity_id TEXT,
        payload_json TEXT NOT NULL,
        customer_snapshot_json TEXT,
        identification_snapshot_json TEXT,
        rate_snapshot_json TEXT,
        status TEXT NOT NULL DEFAULT 'LOCAL_RECORDED',
        retention_until TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now'))
      );
    `);
		try {
			db.run("ALTER TABLE pending_transactions ADD COLUMN idempotency_key TEXT");
		} catch {}
		for (const colDef of [
			"handling_fee REAL",
			"discount_percent REAL",
			"customer_identifier TEXT",
			"customer_name TEXT",
			"customer_document_number TEXT",
			"customer_address TEXT",
			"local_reference_number TEXT"
		]) try {
			db.run(`ALTER TABLE pending_transactions ADD COLUMN ${colDef}`);
		} catch {}
		db.run(`
      CREATE TABLE IF NOT EXISTS cached_customers (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        document_type TEXT NOT NULL,
        document_number TEXT NOT NULL,
        nationality TEXT,
        birth_date TEXT,
        cached_at TEXT DEFAULT (datetime('now'))
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_branch_id TEXT,
        target_branch_code TEXT NOT NULL,
        currency_id INTEGER,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        huf_value REAL,
        transfer_type TEXT,
        denominations TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_distributions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_branch_code TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        denominations TEXT,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS cached_branch_status (
        branch_code TEXT PRIMARY KEY,
        branch_name TEXT NOT NULL,
        company_id INTEGER,
        last_sync_at TEXT,
        online_status TEXT DEFAULT 'offline',
        total_huf_value REAL DEFAULT 0,
        daily_turnover REAL DEFAULT 0,
        cash_balances TEXT,
        cached_at TEXT DEFAULT (datetime('now'))
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS cached_cash_desks (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        company_id TEXT,
        city TEXT,
        is_active INTEGER DEFAULT 1,
        cached_at TEXT DEFAULT (datetime('now'))
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS cached_workers (
        id INTEGER PRIMARY KEY,
        worker_code TEXT,
        full_name TEXT NOT NULL,
        role TEXT,
        branch_id TEXT,
        branch_code TEXT,
        branch_name TEXT,
        company_id TEXT,
        company_code TEXT,
        active INTEGER DEFAULT 1,
        cached_at TEXT DEFAULT (datetime('now'))
      );
    `);
		db.run(`
      CREATE TABLE IF NOT EXISTS pending_collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_branch_code TEXT NOT NULL,
        currency_code TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        local_reference_number TEXT,
        idempotency_key TEXT,
        created_at TEXT DEFAULT (datetime('now')),
        synced INTEGER DEFAULT 0
      );
    `);
		for (const colDef of [
			"target_branch_id TEXT",
			"currency_id INTEGER",
			"huf_value REAL",
			"transfer_type TEXT",
			"local_reference_number TEXT",
			"idempotency_key TEXT"
		]) try {
			db.run(`ALTER TABLE pending_transfers ADD COLUMN ${colDef}`);
		} catch {}
		for (const colDef of ["local_reference_number TEXT", "idempotency_key TEXT"]) try {
			db.run(`ALTER TABLE pending_distributions ADD COLUMN ${colDef}`);
		} catch {}
		for (const colDef of ["local_reference_number TEXT", "idempotency_key TEXT"]) try {
			db.run(`ALTER TABLE pending_collections ADD COLUMN ${colDef}`);
		} catch {}
		for (const colDef of [
			"approval_id TEXT",
			"custom_exchange_rate REAL",
			"payment_method TEXT",
			"customer_name TEXT",
			"customer_document_number TEXT",
			"local_reference_number TEXT",
			"idempotency_key TEXT"
		]) try {
			db.run(`ALTER TABLE pending_stornos ADD COLUMN ${colDef}`);
		} catch {}
		for (const colDef of [
			"sheet_id TEXT",
			"from_cash_desk_id TEXT",
			"to_cash_desk_id TEXT",
			"transfer_date TEXT",
			"amounts_json TEXT",
			"note TEXT",
			"local_reference_number TEXT",
			"idempotency_key TEXT"
		]) try {
			db.run(`ALTER TABLE pending_handover_operations ADD COLUMN ${colDef}`);
		} catch {}
		cleanupLocalAuditEvents();
		saveDatabase();
	} catch (err) {
		const error = err;
		const errorCode = "code" in error && error.code ? String(error.code) : "unknown";
		const errorMessage = error instanceof Error ? error.message : String(error);
		const wasmPath = (() => {
			try {
				return resolveWasmPath();
			} catch (resolveErr) {
				return `resolve error: ${resolveErr instanceof Error ? resolveErr.message : String(resolveErr)}`;
			}
		})();
		const details = [
			`dbPath=${dbPath || "n/a"}`,
			`wasmPath=${wasmPath}`,
			`resourcesPath=${process.resourcesPath}`,
			`appPath=${electron.app.getAppPath()}`,
			`isPackaged=${electron.app.isPackaged}`,
			`errorCode=${errorCode}`,
			`errorMessage=${errorMessage}`
		].join("\n");
		throw new Error(`Database init failed:\n${details}`, { cause: err });
	}
}
/**
* Atomi adatbázis mentés — temp fájl + rename pattern.
*
* Ez véd az áramszünet/crash közbeni korrupció ellen:
* 1. Írás temp fájlba (dbPath + '.tmp')
* 2. Rename temp → végleges (atomi művelet a legtöbb fájlrendszeren)
* Ha a rename sikertelen, a temp fájl marad, az eredeti DB érintetlen.
*/
function saveDatabase() {
	if (!db) return;
	const data = db.export();
	const buffer = Buffer.from(data);
	const tmpPath = dbPath + ".tmp";
	try {
		node_fs.default.writeFileSync(tmpPath, buffer);
		node_fs.default.renameSync(tmpPath, dbPath);
	} catch (err) {
		try {
			node_fs.default.unlinkSync(tmpPath);
		} catch {}
		node_fs.default.writeFileSync(dbPath, buffer);
	}
}
function computeRetentionUntil(days = 31) {
	const retentionDate = /* @__PURE__ */ new Date();
	retentionDate.setDate(retentionDate.getDate() + days);
	return retentionDate.toISOString();
}
function generateLocalReference(prefix) {
	return `${prefix}-${(/* @__PURE__ */ new Date()).toISOString().replace(/\D/g, "").slice(0, 14)}-${node_crypto.default.randomBytes(2).toString("hex").toUpperCase()}`;
}
function toJsonOrNull(value) {
	if (value === null || value === void 0) return null;
	return JSON.stringify(value);
}
function saveLocalAuditEvent(params) {
	if (!db) throw new Error("Database not initialized");
	db.run(`INSERT INTO local_audit_events (
      entity_type,
      event_type,
      reference_number,
      entity_id,
      payload_json,
      customer_snapshot_json,
      identification_snapshot_json,
      rate_snapshot_json,
      status,
      retention_until
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		params.entityType,
		params.eventType,
		params.referenceNumber ?? null,
		params.entityId ?? null,
		JSON.stringify(params.payload),
		toJsonOrNull(params.customerSnapshot),
		toJsonOrNull(params.identificationSnapshot),
		toJsonOrNull(params.rateSnapshot),
		params.status ?? "LOCAL_RECORDED",
		computeRetentionUntil(params.retentionDays ?? 31)
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	return row["id"] ?? 0;
}
function getLocalAuditEvents(limit = 200) {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM local_audit_events ORDER BY created_at DESC LIMIT ?");
	stmt.bind([limit]);
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function cleanupLocalAuditEvents(retentionDays = 31) {
	if (!db) return;
	db.run(`DELETE FROM local_audit_events
     WHERE datetime(created_at) < datetime('now', ?)`, [`-${retentionDays} days`]);
}
function getConfig(key) {
	if (!db) return null;
	const stmt = db.prepare("SELECT value FROM config WHERE key = ?");
	stmt.bind([key]);
	if (stmt.step()) {
		const row = stmt.getAsObject();
		stmt.free();
		return row["value"] ?? null;
	}
	stmt.free();
	return null;
}
function setConfig(key, value) {
	if (!db) return;
	if (key.length > 100) throw new Error(`Config key too long: ${key.length} chars (max 100)`);
	if (value.length > 1e4) throw new Error(`Config value too long: ${value.length} chars (max 10000)`);
	db.run(`INSERT INTO config (key, value, updated_at) VALUES (?, ?, datetime('now'))
     ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at`, [key, value]);
	saveDatabase();
}
function deleteConfig(key) {
	if (!db) return;
	db.run("DELETE FROM config WHERE key = ?", [key]);
	saveDatabase();
}
function savePendingTransaction(type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, handlingFee, discountPercent, customerIdentifier, customerName, customerDocumentNumber, customerAddress, denominations) {
	if (!db) throw new Error("Database not initialized");
	const idempotencyKey = node_crypto.default.randomUUID();
	const localReferenceNumber = generateLocalReference(type === "BUY" ? "LB" : "LS");
	const normalizedCustomerIdentifier = customerIdentifier?.trim() || null;
	const normalizedCustomerName = customerName?.trim() || null;
	const normalizedCustomerDocumentNumber = customerDocumentNumber?.trim() || null;
	const normalizedCustomerAddress = customerAddress?.trim() || null;
	db.run(`INSERT INTO pending_transactions (
      type,
      currency_code,
      foreign_amount,
      huf_amount,
      rounded_huf_amount,
      rate,
      handling_fee,
      discount_percent,
      customer_id,
      customer_identifier,
      customer_name,
      customer_document_number,
      customer_address,
      denominations,
      local_reference_number,
      idempotency_key
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		type,
		currencyCode,
		foreignAmount,
		hufAmount,
		roundedHufAmount,
		rate,
		handlingFee,
		discountPercent,
		null,
		normalizedCustomerIdentifier,
		normalizedCustomerName,
		normalizedCustomerDocumentNumber,
		normalizedCustomerAddress,
		denominations,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "TRANSACTION",
		eventType: type,
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			type,
			currencyCode,
			foreignAmount,
			hufAmount,
			roundedHufAmount,
			rate,
			handlingFee,
			discountPercent,
			denominations,
			idempotencyKey
		},
		customerSnapshot: {
			customerIdentifier: normalizedCustomerIdentifier,
			customerName: normalizedCustomerName,
			customerDocumentNumber: normalizedCustomerDocumentNumber,
			customerAddress: normalizedCustomerAddress
		},
		identificationSnapshot: {
			customerIdentifier: normalizedCustomerIdentifier,
			customerDocumentNumber: normalizedCustomerDocumentNumber
		},
		rateSnapshot: {
			currencyCode,
			rate,
			roundedHufAmount
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingTransactions() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_transactions WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) {
		const row = stmt.getAsObject();
		results.push(row);
	}
	stmt.free();
	return results;
}
function savePendingConversion(fromCurrencyId, fromCurrencyCode, toCurrencyId, toCurrencyCode, fromAmount, calculatedHufAmount, calculatedToAmount, conversionRate, handlingFee, customerId, customerName, customerDocumentNumber, note) {
	if (!db) throw new Error("Database not initialized");
	const idempotencyKey = node_crypto.default.randomUUID();
	const localReferenceNumber = generateLocalReference("LC");
	db.run(`INSERT INTO pending_conversions (
      from_currency_id,
      from_currency_code,
      to_currency_id,
      to_currency_code,
      from_amount,
      calculated_huf_amount,
      calculated_to_amount,
      conversion_rate,
      handling_fee,
      customer_id,
      customer_name,
      customer_document_number,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		fromCurrencyId,
		fromCurrencyCode,
		toCurrencyId,
		toCurrencyCode,
		fromAmount,
		calculatedHufAmount,
		calculatedToAmount,
		conversionRate,
		handlingFee,
		customerId?.trim() || null,
		customerName?.trim() || null,
		customerDocumentNumber?.trim() || null,
		note?.trim() || null,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "CONVERSION",
		eventType: "CREATE",
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			fromCurrencyId,
			fromCurrencyCode,
			toCurrencyId,
			toCurrencyCode,
			fromAmount,
			calculatedHufAmount,
			calculatedToAmount,
			conversionRate,
			handlingFee,
			note: note?.trim() || null,
			idempotencyKey
		},
		customerSnapshot: {
			customerId: customerId?.trim() || null,
			customerName: customerName?.trim() || null,
			customerDocumentNumber: customerDocumentNumber?.trim() || null
		},
		identificationSnapshot: {
			customerId: customerId?.trim() || null,
			customerDocumentNumber: customerDocumentNumber?.trim() || null
		},
		rateSnapshot: {
			fromCurrencyCode,
			toCurrencyCode,
			conversionRate,
			calculatedHufAmount,
			calculatedToAmount
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingConversions() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_conversions WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) {
		const row = stmt.getAsObject();
		results.push(row);
	}
	stmt.free();
	return results;
}
function markConversionSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_conversions SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function markTransactionSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_transactions SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function getPendingTransactionCount() {
	if (!db) return 0;
	const stmt = db.prepare("SELECT COUNT(*) as cnt FROM pending_transactions WHERE synced = 0");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	return row["cnt"] ?? 0;
}
function getDb() {
	return db;
}
function savePendingDistribution(targetBranchCode, currencyCode, amount, denominations, note) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference("LD");
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_distributions (
      target_branch_code,
      currency_code,
      amount,
      denominations,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?)`, [
		targetBranchCode,
		currencyCode,
		amount,
		denominations,
		note,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "TREASURY_DISTRIBUTION",
		eventType: "CREATE",
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			targetBranchCode,
			currencyCode,
			amount,
			denominations,
			note,
			idempotencyKey
		},
		rateSnapshot: { currencyCode },
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingDistributions() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_distributions WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markDistributionSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_distributions SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function savePendingTransfer(targetBranchId, targetBranchCode, currencyId, currencyCode, amount, hufValue, transferType, denominations, note) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference("LT");
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_transfers (
      target_branch_id,
      target_branch_code,
      currency_id,
      currency_code,
      amount,
      huf_value,
      transfer_type,
      denominations,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		targetBranchId,
		targetBranchCode,
		currencyId,
		currencyCode,
		amount,
		hufValue,
		transferType,
		denominations,
		note,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "TRANSFER",
		eventType: transferType ?? "CREATE",
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			targetBranchId,
			targetBranchCode,
			currencyId,
			currencyCode,
			amount,
			hufValue,
			transferType,
			denominations,
			note,
			idempotencyKey
		},
		rateSnapshot: {
			currencyCode,
			hufValue
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingTransfers() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_transfers WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markTransferSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_transfers SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function savePendingCollection(sourceBranchCode, currencyCode, amount, note) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference("LCOL");
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_collections (
      source_branch_code,
      currency_code,
      amount,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?)`, [
		sourceBranchCode,
		currencyCode,
		amount,
		note,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "TREASURY_COLLECTION",
		eventType: "CREATE",
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			sourceBranchCode,
			currencyCode,
			amount,
			note,
			idempotencyKey
		},
		rateSnapshot: { currencyCode },
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function savePendingBankTransaction(transactionType, currencyCode, amount, exchangeRate, hufAmount, vaultTerritoryId, bankName, bankReference, note) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference("LBANK");
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_bank_transactions (
      transaction_type,
      currency_code,
      amount,
      exchange_rate,
      huf_amount,
      vault_territory_id,
      bank_name,
      bank_reference,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		transactionType,
		currencyCode,
		amount,
		exchangeRate,
		hufAmount,
		vaultTerritoryId,
		bankName?.trim() || null,
		bankReference?.trim() || null,
		note?.trim() || null,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "BANK_TRANSACTION",
		eventType: transactionType,
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			transactionType,
			currencyCode,
			amount,
			exchangeRate,
			hufAmount,
			vaultTerritoryId,
			bankName: bankName?.trim() || null,
			bankReference: bankReference?.trim() || null,
			note: note?.trim() || null,
			idempotencyKey
		},
		rateSnapshot: {
			currencyCode,
			exchangeRate,
			hufAmount
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingBankTransactions() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_bank_transactions WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markBankTransactionSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_bank_transactions SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function savePendingStorno(params) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference("LST");
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_stornos (
      transaction_id,
      original_receipt_number,
      original_transaction_type,
      currency_code,
      foreign_amount,
      huf_amount,
      exchange_rate,
      reason,
      approval_id,
      custom_exchange_rate,
      payment_method,
      customer_name,
      customer_document_number,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		params.transactionId,
		params.originalReceiptNumber,
		params.originalTransactionType,
		params.currencyCode,
		params.foreignAmount,
		params.hufAmount,
		params.exchangeRate,
		params.reason.trim(),
		params.approvalId ?? null,
		params.customExchangeRate ?? null,
		params.paymentMethod ?? null,
		params.customerName?.trim() || null,
		params.customerDocumentNumber?.trim() || null,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "STORNO",
		eventType: "EXECUTE",
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			transactionId: params.transactionId,
			originalReceiptNumber: params.originalReceiptNumber,
			originalTransactionType: params.originalTransactionType,
			currencyCode: params.currencyCode,
			foreignAmount: params.foreignAmount,
			hufAmount: params.hufAmount,
			exchangeRate: params.exchangeRate,
			reason: params.reason.trim(),
			approvalId: params.approvalId ?? null,
			customExchangeRate: params.customExchangeRate ?? null,
			paymentMethod: params.paymentMethod ?? null,
			idempotencyKey
		},
		customerSnapshot: {
			customerName: params.customerName?.trim() || null,
			customerDocumentNumber: params.customerDocumentNumber?.trim() || null
		},
		identificationSnapshot: { customerDocumentNumber: params.customerDocumentNumber?.trim() || null },
		rateSnapshot: {
			currencyCode: params.currencyCode,
			exchangeRate: params.customExchangeRate ?? params.exchangeRate,
			hufAmount: params.hufAmount
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingStornos() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_stornos WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markStornoSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_stornos SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function savePendingHandoverOperation(params) {
	if (!db) throw new Error("Database not initialized");
	const localReferenceNumber = generateLocalReference(params.operationType === "GENERATE" ? "LHS" : `LHS-${params.operationType}`);
	const idempotencyKey = node_crypto.default.randomUUID();
	db.run(`INSERT INTO pending_handover_operations (
      operation_type,
      sheet_id,
      from_cash_desk_id,
      to_cash_desk_id,
      transfer_date,
      amounts_json,
      note,
      local_reference_number,
      idempotency_key
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`, [
		params.operationType,
		params.sheetId ?? null,
		params.fromCashDeskId ?? null,
		params.toCashDeskId ?? null,
		params.transferDate ?? null,
		toJsonOrNull(params.amounts),
		params.note?.trim() || null,
		localReferenceNumber,
		idempotencyKey
	]);
	saveDatabase();
	const stmt = db.prepare("SELECT last_insert_rowid() as id");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	const insertedId = row["id"] ?? 0;
	saveLocalAuditEvent({
		entityType: "HANDOVER_SHEET",
		eventType: params.operationType,
		referenceNumber: localReferenceNumber,
		entityId: String(insertedId),
		payload: {
			sheetId: params.sheetId ?? null,
			fromCashDeskId: params.fromCashDeskId ?? null,
			toCashDeskId: params.toCashDeskId ?? null,
			transferDate: params.transferDate ?? null,
			amounts: params.amounts ?? null,
			note: params.note?.trim() || null,
			idempotencyKey
		},
		status: "PENDING_UPLOAD"
	});
	return insertedId;
}
function getPendingHandoverOperations() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_handover_operations WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markHandoverOperationSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_handover_operations SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function getPendingCollections() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM pending_collections WHERE synced = 0 ORDER BY created_at ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function markCollectionSynced(id) {
	if (!db) return;
	db.run("UPDATE pending_collections SET synced = 1 WHERE id = ?", [id]);
	saveDatabase();
}
function saveCachedBranchStatus(branchCode, branchName, companyId, lastSyncAt, onlineStatus, totalHufValue, dailyTurnover, cashBalances) {
	if (!db) return;
	db.run(`INSERT INTO cached_branch_status (branch_code, branch_name, company_id, last_sync_at, online_status, total_huf_value, daily_turnover, cash_balances, cached_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(branch_code) DO UPDATE SET
       branch_name = excluded.branch_name,
       company_id = excluded.company_id,
       last_sync_at = excluded.last_sync_at,
       online_status = excluded.online_status,
       total_huf_value = excluded.total_huf_value,
       daily_turnover = excluded.daily_turnover,
       cash_balances = excluded.cash_balances,
       cached_at = excluded.cached_at`, [
		branchCode,
		branchName,
		companyId,
		lastSyncAt,
		onlineStatus,
		totalHufValue,
		dailyTurnover,
		cashBalances
	]);
	saveDatabase();
}
function getCachedBranchStatuses() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM cached_branch_status ORDER BY branch_code ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function getCachedBranchStatusTimestamp() {
	if (!db) return null;
	const stmt = db.prepare("SELECT MAX(cached_at) as last_cached FROM cached_branch_status");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	return row["last_cached"] ?? null;
}
function saveCachedCashDesk(id, code, name, companyId, city, isActive) {
	if (!db) return;
	db.run(`INSERT INTO cached_cash_desks (id, code, name, company_id, city, is_active, cached_at)
     VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(id) DO UPDATE SET
       code = excluded.code,
       name = excluded.name,
       company_id = excluded.company_id,
       city = excluded.city,
       is_active = excluded.is_active,
       cached_at = excluded.cached_at`, [
		id,
		code,
		name,
		companyId,
		city,
		isActive ? 1 : 0
	]);
	saveDatabase();
}
function getCachedCashDesks() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM cached_cash_desks ORDER BY code ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function getCachedCashDeskTimestamp() {
	if (!db) return null;
	const stmt = db.prepare("SELECT MAX(cached_at) as last_cached FROM cached_cash_desks");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	return row["last_cached"] ?? null;
}
function saveCachedWorker(id, workerCode, fullName, role, branchId, branchCode, branchName, companyId, companyCode, active) {
	if (!db) return;
	db.run(`INSERT INTO cached_workers (id, worker_code, full_name, role, branch_id, branch_code, branch_name, company_id, company_code, active, cached_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(id) DO UPDATE SET
       worker_code = excluded.worker_code,
       full_name = excluded.full_name,
       role = excluded.role,
       branch_id = excluded.branch_id,
       branch_code = excluded.branch_code,
       branch_name = excluded.branch_name,
       company_id = excluded.company_id,
       company_code = excluded.company_code,
       active = excluded.active,
       cached_at = excluded.cached_at`, [
		id,
		workerCode,
		fullName,
		role,
		branchId,
		branchCode,
		branchName,
		companyId,
		companyCode,
		active ? 1 : 0
	]);
	saveDatabase();
}
function getCachedWorkers() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM cached_workers ORDER BY full_name ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
function getCachedWorkerTimestamp() {
	if (!db) return null;
	const stmt = db.prepare("SELECT MAX(cached_at) as last_cached FROM cached_workers");
	stmt.step();
	const row = stmt.getAsObject();
	stmt.free();
	return row["last_cached"] ?? null;
}
function getCachedRates() {
	if (!db) return [];
	const results = [];
	const stmt = db.prepare("SELECT * FROM cached_rates ORDER BY currency_code ASC");
	while (stmt.step()) results.push(stmt.getAsObject());
	stmt.free();
	return results;
}
//#endregion
//#region electron/printer.ts
/**
* Thermal Receipt Printer — Electron main process.
*
* 80mm-es hőnyomtatóra generál bizonylat szöveget ESC/POS parancsokkal,
* illetve HTML formátumban az Electron beépített nyomtató API-ján keresztül.
*
* Nyomtatási architektúra:
*   1. printReceipt() — fő belépési pont, IPC-ből hívva
*   2. Megpróbálja printToThermalUsb()-t (ESC/POS közvetlen USB — jövőbeli)
*   3. Ha nincs USB nyomtató, fallback: printViaElectron() — rejtett ablakban
*      HTML-t renderel és a rendszer nyomtató-driverén keresztül nyomtat
*
* Két cég:
*   - Best Change: Exclusive Best Change Zrt. (adószám: 32313332-2-02)
*   - Expressz: Expressz Ékszerház és Minibank Kft. (adószám: 14040535-2-02)
*/
var ESC = "\x1B";
var GS = "";
`${ESC}`, `${ESC}`, `${ESC}`, `${ESC}`, `${ESC}`, `${GS}`, `${GS}`, `${GS}`, `${GS}`, `${ESC}`, `${ESC}`, `${GS}`, `${GS}`, "─".repeat(42), "═".repeat(42);
var COMPANIES = {
	BEST_CHANGE: {
		name: "BEST CHANGE",
		fullName: "EXCLUSIVE BEST CHANGE ZRT.",
		taxNumber: "32313332-2-02",
		address: "Szeged, Kárász u. 5.",
		phone: "06703800161"
	},
	EXPRESSZ: {
		name: "EXPRESSZ",
		fullName: "EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT.",
		taxNumber: "14040535-2-02",
		address: "Szeged, Klauzál tér 3.",
		phone: ""
	}
};
var JOB_TYPE_LABELS = {
	sell: "ELADÁSI BIZONYLAT",
	buy: "VÁSÁRLÁSI BIZONYLAT",
	transfer: "ÁTADÁS-ÁTVÉTELI BIZONYLAT",
	storno: "STORNÓ BIZONYLAT",
	conversion: "KONVERZIÓS BIZONYLAT",
	closing: "NAPI ZÁRÁS",
	handling_fee: "KEZELÉSI DÍJ BIZONYLAT",
	cash_status: "PÉNZTÁR ÁLLÁS",
	vault_closing: "ÉRTÉKTÁRI ZÁRÁS",
	kktg_transfer: "KKTG ÁTADÁS-ÁTVÉTEL"
};
function formatAmount(value) {
	if (value === void 0) return "—";
	return value.toLocaleString("hu-HU", { maximumFractionDigits: 2 });
}
function formatRate(value) {
	if (value === void 0) return "—";
	return value.toLocaleString("hu-HU", {
		minimumFractionDigits: 2,
		maximumFractionDigits: 4
	});
}
/**
* Bizonylat HTML generálása — 80mm szélességre optimalizált.
* Ezt rendereli a rejtett BrowserWindow a rendszer nyomtató felé.
*/
async function generateReceiptHtml(data) {
	const company = COMPANIES[data.companyType] ?? COMPANIES["BEST_CHANGE"];
	const label = JOB_TYPE_LABELS[data.type];
	let bodyContent = "";
	bodyContent += `
    <div class="center">
      <div class="company-name">${escHtml(company.name)}</div>
      <div class="company-full">${escHtml(company.fullName)}</div>
      <div>${escHtml(company.address)}</div>
      ${data.companyPhone || company.phone ? `<div>Tel: ${escHtml(data.companyPhone || company.phone)}</div>` : ""}
      <div>Adószám: ${escHtml(data.companyTaxNumber || company.taxNumber)}</div>
    </div>
    <div class="double-line"></div>
    <div class="center receipt-type">${escHtml(label)}</div>
    <div class="meta">
      <div>Bizonylat: ${escHtml(data.receiptNumber)}</div>
      <div>Dátum: ${escHtml(data.date)} &nbsp; ${escHtml(data.time)}</div>
      <div>Pénztár: ${escHtml(data.branchCode)}</div>
      <div>Pénztáros: ${escHtml(data.cashierName)}</div>
    </div>
    <div class="line"></div>
  `;
	if (data.type === "sell" || data.type === "buy") bodyContent += generateTransactionHtml(data);
	else if (data.type === "transfer") bodyContent += generateTransferHtml(data);
	else if (data.type === "storno") bodyContent += generateStornoHtml(data);
	else if (data.type === "conversion") bodyContent += generateConversionHtml(data);
	else if (data.type === "closing") bodyContent += generateClosingHtml(data);
	else if (data.type === "handling_fee") bodyContent += generateHandlingFeeHtml(data);
	else if (data.type === "cash_status") bodyContent += generateCashStatusHtml(data);
	else if (data.type === "vault_closing") bodyContent += generateVaultClosingHtml(data);
	else if (data.type === "kktg_transfer") bodyContent += generateKktgTransferHtml(data);
	if (data.customerName) bodyContent += `
      <div class="line"></div>
      <div class="bold">ÜGYFÉL ADATOK:</div>
      <div class="amount-row"><span>Név:</span><span>${escHtml(data.customerName)}</span></div>
      ${data.customerBirthPlace ? `<div class="amount-row"><span>Szül. hely:</span><span>${escHtml(data.customerBirthPlace)}</span></div>` : ""}
      ${data.customerBirthDate ? `<div class="amount-row"><span>Szül. idő:</span><span>${escHtml(data.customerBirthDate)}</span></div>` : ""}
      ${data.customerMotherName ? `<div class="amount-row"><span>Anyja neve:</span><span>${escHtml(data.customerMotherName)}</span></div>` : ""}
      ${data.customerAddress ? `<div class="amount-row"><span>Lakcím:</span><span>${escHtml(data.customerAddress)}</span></div>` : ""}
      ${data.customerDocType ? `<div class="amount-row"><span>Okmány:</span><span>${escHtml(data.customerDocType)}</span></div>` : ""}
      ${data.customerDocNumber ? `<div class="amount-row"><span>Okmányszám:</span><span>${escHtml(data.customerDocNumber)}</span></div>` : ""}
      ${data.customerNationality ? `<div class="amount-row"><span>Állampolgárság:</span><span>${escHtml(data.customerNationality)}</span></div>` : ""}
    `;
	bodyContent += `
    <div class="line"></div>
    <div style="font-size: 9px; margin: 4px 0;">
      ${data.vatExemptionText ? `<div>${escHtml(data.vatExemptionText)}</div>` : `<div>Szj 67.13.10.0</div><div>Az ÁFA alól mentes: 2007. évi CXVII tv. 85. § e)</div>`}
    </div>
    <div class="line"></div>
  `;
	bodyContent += `
    <div style="display: flex; justify-content: space-around; margin: 12px 0;">
      <div style="text-align: center;">
        <div style="border-top: 1px solid #000; width: 90px; display: inline-block;"></div>
        <div style="font-size: 9px;">Pénztáros</div>
      </div>
      <div style="text-align: center;">
        <div style="border-top: 1px solid #000; width: 90px; display: inline-block;"></div>
        <div style="font-size: 9px;">Ügyfél</div>
      </div>
    </div>
  `;
	const taxNum = data.companyTaxNumber || company.taxNumber;
	const qrText = [
		data.receiptNumber,
		data.date,
		(data.roundedHufAmount ?? data.hufAmount ?? 0).toString(),
		data.currencyCode ?? "HUF",
		taxNum,
		data.branchCode ?? ""
	].join("|");
	try {
		const qrDataUrl = await (await Promise.resolve().then(() => /* @__PURE__ */ require_chunk.__toESM(require("./lib-C2WqpPNS.js").default))).toDataURL(qrText, {
			width: 120,
			margin: 1,
			errorCorrectionLevel: "M"
		});
		bodyContent += `
      <div class="center" style="margin: 8px 0;">
        <img src="${qrDataUrl}" style="width: 100px; height: 100px;" alt="QR" />
      </div>
    `;
	} catch {
		bodyContent += `
      <div class="center" style="margin: 8px 0; font-size: 8px; color: #999;">QR: ${escHtml(qrText)}</div>
    `;
	}
	bodyContent += `
    <div class="double-line"></div>
    <div class="center footer">Köszönjük, hogy minket választott!</div>
    <div class="center" style="font-size: 8px; color: #666; margin-top: 4px;">
      A bizonylat a pénzmosás elleni törvény alapján nem helyettesíti a számlát.
    </div>
  `;
	return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    @page {
      size: 80mm auto;
      margin: 2mm;
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: 'Courier New', monospace;
      font-size: 11px;
      line-height: 1.4;
      width: 76mm;
      color: #000;
    }
    .center { text-align: center; }
    .bold { font-weight: bold; }
    .company-name {
      font-size: 18px;
      font-weight: bold;
    }
    .company-full {
      font-size: 11px;
      font-weight: bold;
    }
    .receipt-type {
      font-size: 14px;
      font-weight: bold;
      margin: 4px 0;
    }
    .meta { margin: 4px 0; }
    .line {
      border-top: 1px dashed #000;
      margin: 6px 0;
    }
    .double-line {
      border-top: 2px solid #000;
      margin: 6px 0;
    }
    .amount-row {
      display: flex;
      justify-content: space-between;
    }
    .total {
      font-size: 14px;
      font-weight: bold;
      margin-top: 4px;
    }
    .section { margin: 6px 0; }
    .footer { margin-top: 8px; font-size: 10px; }
    .discrepancy { color: #c00; font-weight: bold; }
  </style>
</head>
<body>${bodyContent}</body>
</html>`;
}
function generateTransactionHtml(data) {
	let html = `
    <div class="section">
      <div class="bold">${escHtml(data.type === "sell" ? "Deviza eladás (HUF → valuta):" : "Deviza vásárlás (valuta → HUF):")}</div>
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? "—")}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? "")}</span></div>
      <div class="amount-row"><span>Árfolyam:</span><span>${formatRate(data.rate)}</span></div>
    </div>
    <div class="line"></div>
    <div class="amount-row bold"><span>HUF összeg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>
  `;
	if (data.roundedHufAmount !== void 0 && data.roundingDiff !== void 0 && data.roundingDiff !== 0) html += `
      <div class="amount-row"><span>Kerekítés:</span><span>${formatAmount(data.roundingDiff)} Ft</span></div>
      <div class="amount-row total"><span>FIZETENDŐ:</span><span>${formatAmount(data.roundedHufAmount)} Ft</span></div>
    `;
	else html += `
      <div class="amount-row total"><span>FIZETENDŐ:</span><span>${formatAmount(data.roundedHufAmount ?? data.hufAmount)} Ft</span></div>
    `;
	return html;
}
function generateTransferHtml(data) {
	return `
    <div class="section">
      <div class="bold">Átadás-átvétel:</div>
      <div class="amount-row"><span>Cél pénztár:</span><span>${escHtml(data.transferTarget ?? "—")}</span></div>
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? "—")}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? "")}</span></div>
      ${data.transferNote ? `<div>Megjegyzés: ${escHtml(data.transferNote)}</div>` : ""}
    </div>
  `;
}
function generateStornoHtml(data) {
	return `
    <div class="section">
      <div class="bold">STORNÓ:</div>
      <div class="amount-row"><span>Eredeti biz.:</span><span>${escHtml(data.originalReceiptNumber ?? "—")}</span></div>
      <div class="amount-row"><span>Valutanem:</span><span>${escHtml(data.currencyCode ?? "—")}</span></div>
      <div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.foreignAmount)} ${escHtml(data.currencyCode ?? "")}</span></div>
      <div class="amount-row"><span>HUF összeg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>
      ${data.stornoReason ? `<div>Indok: ${escHtml(data.stornoReason)}</div>` : ""}
    </div>
  `;
}
function generateClosingHtml(data) {
	const summary = data.closingSummary;
	if (!summary) return "<div class=\"section\">(Nincs zárási adat)</div>";
	let discrepancyHtml = "";
	if (summary.discrepancies.length > 0) discrepancyHtml = `
      <div class="bold discrepancy">ELTÉRÉSEK:</div>
      ${summary.discrepancies.map((d) => `<div class="discrepancy">&nbsp;&nbsp;${escHtml(d.currencyCode)}: várt ${formatAmount(d.expected)} → tény ${formatAmount(d.actual)} (${formatAmount(d.difference)})</div>`).join("")}
    `;
	return `
    <div class="section">
      <div class="bold">FORGALMI ÖSSZESÍTŐ:</div>
      <div class="amount-row"><span>Összes tranzakció:</span><span>${summary.totalTransactions}</span></div>
      <div class="amount-row"><span>&nbsp;&nbsp;- Eladás:</span><span>${summary.sellCount}</span></div>
      <div class="amount-row"><span>&nbsp;&nbsp;- Vásárlás:</span><span>${summary.buyCount}</span></div>
      <br/>
      <div class="amount-row"><span>HUF forgalom:</span><span>${formatAmount(summary.totalHufTurnover)} Ft</span></div>
      <div class="amount-row"><span>Díjbevétel:</span><span>${formatAmount(summary.totalFees)} Ft</span></div>
    </div>
    <div class="line"></div>
    <div class="amount-row"><span>Nyitó egyenleg:</span><span>${formatAmount(summary.openingBalance)} Ft</span></div>
    <div class="amount-row"><span>Záró egyenleg:</span><span>${formatAmount(summary.closingBalance)} Ft</span></div>
    ${discrepancyHtml}
  `;
}
function generateConversionHtml(data) {
	return `
    <div class="section">
      <div class="amount-row"><span>Forrás:</span><span>${formatAmount(data.sourceAmount)} ${escHtml(data.sourceCurrencyCode ?? "—")}</span></div>
      <div class="amount-row"><span>Cél:</span><span>${formatAmount(data.targetAmount)} ${escHtml(data.targetCurrencyCode ?? "—")}</span></div>
      <div class="amount-row"><span>Köztes HUF:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>
      <div class="amount-row"><span>Árfolyam:</span><span>${formatRate(data.rate)}</span></div>
      ${data.note ? `<div class="amount-row"><span>Megjegyzés:</span><span>${escHtml(data.note)}</span></div>` : ""}
    </div>
  `;
}
function generateHandlingFeeHtml(data) {
	return `
    <div class="section">
      <div class="bold total">Kezelési díj: ${formatAmount(data.hufAmount ?? 0)} Ft</div>
      ${data.sealNumber ? `<div class="amount-row"><span>Plombaszám:</span><span>${escHtml(data.sealNumber)}</span></div>` : ""}
      ${data.originalReceiptNumber ? `<div class="amount-row"><span>Alapbizonylat:</span><span>${escHtml(data.originalReceiptNumber)}</span></div>` : ""}
    </div>
  `;
}
function generateCashStatusHtml(data) {
	return `
    <div class="section">
      <div class="bold">PÉNZTÁR ÁLLÁS</div>
      ${data.hufAmount !== void 0 ? `<div class="amount-row"><span>HUF egyenleg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>` : ""}
      ${data.note ? `<div class="amount-row"><span>Megjegyzés:</span><span>${escHtml(data.note)}</span></div>` : ""}
    </div>
  `;
}
function generateVaultClosingHtml(data) {
	return `
    <div class="section">
      <div class="bold">ÉRTÉKTÁRI ZÁRÁS</div>
      ${data.hufAmount !== void 0 ? `<div class="amount-row"><span>Összeg:</span><span>${formatAmount(data.hufAmount)} Ft</span></div>` : ""}
      ${data.sealNumber ? `<div class="amount-row"><span>Plombaszám:</span><span>${escHtml(data.sealNumber)}</span></div>` : ""}
      ${data.note ? `<div class="amount-row"><span>Megjegyzés:</span><span>${escHtml(data.note)}</span></div>` : ""}
    </div>
  `;
}
function generateKktgTransferHtml(data) {
	return `
    <div class="section">
      <div class="bold total">Összeg: ${formatAmount(data.hufAmount ?? 0)} Ft</div>
      ${data.sealNumber ? `<div class="amount-row"><span>Plombaszám:</span><span>${escHtml(data.sealNumber)}</span></div>` : ""}
      ${data.transferTarget ? `<div class="amount-row"><span>Cél iroda:</span><span>${escHtml(data.transferTarget)}</span></div>` : ""}
      ${data.note ? `<div class="amount-row"><span>Megjegyzés:</span><span>${escHtml(data.note)}</span></div>` : ""}
    </div>
  `;
}
/** Egyszerű HTML escape az XSS elkerülésére. */
function escHtml(str) {
	return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
/** Soros (COM) port konfig kulcs — ha be van állítva, a blokknyomtató soros porton nyomtat. */
var SERIAL_PORT_CONFIG_KEY = "printer.serialPort";
/**
* Soros blokknyomtató küldés (Star SP500 vagy kompatibilis).
* Ha van konfigurált COM port, közvetlenül soros portra küldi az ESC/POS adatot.
*
* @returns true ha sikerült nyomtatni, false ha nincs soros nyomtató konfigurálva
*/
async function printToSerialPrinter(data, serialPort) {
	if (!serialPort) return false;
	try {
		const { printReceiptToSerial } = await Promise.resolve().then(() => require("./serial-printer-SF75wf_9.js"));
		return await printReceiptToSerial(data, { port: serialPort });
	} catch (err) {
		electron_log_main.default.warn("[PRINTER] Soros nyomtató hiba, fallback Electron print-re:", err);
		return false;
	}
}
/**
* Nyomtatás Electron beépített webContents.print() API-n keresztül.
* Rejtett BrowserWindow-ban rendereli a bizonylat HTML-t, majd a rendszer
* nyomtató-driverén keresztül kinyomtatja.
*
* @param html - A bizonylat HTML tartalma
* @param printerName - Opcionális nyomtató név; ha nincs megadva, az alapértelmezett nyomtatót használja
* @returns true ha a nyomtatás sikerült
*/
async function printViaElectron(html, printerName) {
	let printWindow = null;
	try {
		printWindow = new electron.BrowserWindow({
			show: false,
			width: 302,
			height: 800,
			webPreferences: {
				contextIsolation: true,
				nodeIntegration: false
			}
		});
		await printWindow.loadURL(`data:text/html;charset=utf-8,${encodeURIComponent(html)}`);
		const printOptions = {
			silent: true,
			printBackground: true,
			margins: { marginType: "none" },
			pageSize: {
				width: 8e4,
				height: 297e3
			}
		};
		if (printerName) printOptions.deviceName = printerName;
		return await new Promise((resolve) => {
			printWindow.webContents.print(printOptions, (success, failureReason) => {
				if (!success) electron_log_main.default.warn(`[PRINTER] Nyomtatás sikertelen: ${failureReason}`);
				resolve(success);
			});
		});
	} catch (err) {
		electron_log_main.default.error("[PRINTER] printViaElectron hiba:", err);
		return false;
	} finally {
		if (printWindow && !printWindow.isDestroyed()) printWindow.close();
	}
}
/**
* Bizonylat nyomtatás — fő belépési pont.
*
* Nyomtatási sorrend:
*   1. Ha USB hőnyomtató konfigurálva van → ESC/POS közvetlen nyomtatás
*   2. Egyébként → Electron webContents.print() rendszer nyomtatón keresztül
*
* Hibajelzések:
*   - Nyomtató offline / nem elérhető → false visszatérés, log üzenet
*   - Papír kifogyott → a rendszer driver kezeli, false visszatérés
*
* @param data - A bizonylat adatai
* @param printerName - Opcionális nyomtató név felülírás
* @returns true ha a nyomtatás sikeresen elindult
*/
async function printReceipt(data, printerName, serialPort) {
	try {
		electron_log_main.default.info(`[PRINTER] Nyomtatás indítása: ${data.type} ${data.receiptNumber}`);
		if (serialPort) {
			if (await printToSerialPrinter(data, serialPort)) {
				electron_log_main.default.info(`[PRINTER] Soros blokknyomtató (${serialPort}): OK — ${data.receiptNumber}`);
				return true;
			}
			electron_log_main.default.warn(`[PRINTER] Soros port ${serialPort} sikertelen, Electron fallback...`);
		}
		electron_log_main.default.info("[PRINTER] Electron print fallback...");
		const electronSuccess = await printViaElectron(await generateReceiptHtml(data), printerName);
		if (electronSuccess) electron_log_main.default.info(`[PRINTER] Electron print: OK — ${data.receiptNumber}`);
		else electron_log_main.default.error(`[PRINTER] Nyomtatás sikertelen — ${data.receiptNumber}. Ellenőrizd a nyomtató állapotát (offline / papír kifogyott).`);
		return electronSuccess;
	} catch (err) {
		electron_log_main.default.error("[PRINTER] Váratlan nyomtatási hiba:", err);
		return false;
	}
}
//#endregion
//#region electron/sync-engine.ts
/**
* SyncEngine — Offline → Online szinkronizáció.
*
* Feladatai:
* 1. Pending tranzakciók szinkronizálása (30s intervallum)
* 2. Árfolyamok letöltése és SQLite cache frissítése
* 3. Körlevelek letöltése
*
* Életciklus:
* - app.whenReady() → syncEngine.start()
* - app.on('will-quit') → syncEngine.stop()
*/
var HttpStatusError = class extends Error {
	status;
	constructor(status, statusText) {
		super(`HTTP ${status}: ${statusText}`);
		this.status = status;
	}
};
function isAuthStatusError(err) {
	return err instanceof HttpStatusError && (err.status === 401 || err.status === 403);
}
async function httpGet(url, token) {
	const headers = { "Content-Type": "application/json" };
	if (token) headers["Authorization"] = `Bearer ${token}`;
	const response = await fetch(url, {
		method: "GET",
		headers,
		signal: AbortSignal.timeout(1e4)
	});
	if (!response.ok) throw new HttpStatusError(response.status, response.statusText);
	return response.json();
}
async function httpPost(url, body, token, idempotencyKey) {
	const headers = {
		"Content-Type": "application/json",
		"Idempotency-Key": idempotencyKey ?? crypto.randomUUID()
	};
	if (token) headers["Authorization"] = `Bearer ${token}`;
	const response = await fetch(url, {
		method: "POST",
		headers,
		body: JSON.stringify(body),
		signal: AbortSignal.timeout(15e3)
	});
	if (!response.ok) throw new HttpStatusError(response.status, response.statusText);
	return response.json();
}
var SyncEngine = class {
	intervalId = null;
	lastTokenValidationAt = 0;
	tokenValidationTtlMs = 12e4;
	status = {
		lastSyncAt: null,
		lastSyncResult: null,
		isRunning: false
	};
	getServerUrl() {
		return getConfig("server_url") ?? "http://localhost:8080/api/v1";
	}
	getBootstrapCredentials() {
		const companyCode = process.env.PENZTAR_BOOTSTRAP_COMPANY_CODE?.trim() || getConfig("bootstrap_company_code")?.trim() || "";
		const workerCode = process.env.PENZTAR_BOOTSTRAP_WORKER_CODE?.trim() || getConfig("bootstrap_worker_code")?.trim() || "";
		const password = process.env.PENZTAR_BOOTSTRAP_PASSWORD?.trim() || getConfig("bootstrap_password")?.trim() || "";
		const roleCode = process.env.PENZTAR_BOOTSTRAP_ROLE_CODE?.trim() || getConfig("bootstrap_role_code")?.trim() || null;
		if (!companyCode || !workerCode || !password) return null;
		return {
			companyCode,
			workerCode,
			password,
			roleCode
		};
	}
	persistAuthToken(token) {
		try {
			if (electron.safeStorage.isEncryptionAvailable()) {
				setConfig("auth_token_encrypted", electron.safeStorage.encryptString(token).toString("base64"));
				deleteConfig("auth_token");
				return;
			}
		} catch (err) {
			console.warn("[SyncEngine] Token titkosított mentése nem sikerült, plaintext fallback:", err);
		}
		setConfig("auth_token", token);
	}
	clearStoredAuthToken() {
		deleteConfig("auth_token_encrypted");
		deleteConfig("auth_token");
		this.lastTokenValidationAt = 0;
	}
	async validateToken(serverUrl, token) {
		const now = Date.now();
		if (now - this.lastTokenValidationAt < this.tokenValidationTtlMs) return true;
		try {
			await httpGet(`${serverUrl}/workers/me`, token);
			this.lastTokenValidationAt = now;
			return true;
		} catch (err) {
			if (isAuthStatusError(err)) return false;
			throw err;
		}
	}
	async bootstrapAuthSession(serverUrl) {
		const credentials = this.getBootstrapCredentials();
		if (!credentials) return null;
		try {
			const login = await httpPost(`${serverUrl}/auth/login`, {
				companyCode: credentials.companyCode,
				workerCode: credentials.workerCode,
				password: credentials.password
			}, null);
			let token = login.token;
			if (login.roleSelectionRequired && credentials.roleCode) token = (await httpPost(`${serverUrl}/auth/login/select-role`, {
				token,
				roleCode: credentials.roleCode
			}, null)).token;
			this.persistAuthToken(token);
			this.lastTokenValidationAt = Date.now();
			console.log("[SyncEngine] Lokális auth/session bootstrap sikeres");
			return token;
		} catch (err) {
			if (isAuthStatusError(err)) console.warn("[SyncEngine] Lokális auth bootstrap sikertelen (401/403). Ellenőrizd a bootstrap credentialöket.");
			else console.warn("[SyncEngine] Lokális auth bootstrap hiba:", err instanceof Error ? err.message : err);
			return null;
		}
	}
	getAuthToken() {
		const encryptedToken = getConfig("auth_token_encrypted");
		if (encryptedToken && electron.safeStorage.isEncryptionAvailable()) try {
			return electron.safeStorage.decryptString(Buffer.from(encryptedToken, "base64"));
		} catch (err) {
			console.warn("[SyncEngine] Nem sikerült visszafejteni a tárolt auth tokent:", err);
			deleteConfig("auth_token_encrypted");
		}
		return getConfig("auth_token");
	}
	/**
	* Szinkronizáció indítása — periodikus (alapértelmezetten 30s).
	*/
	start(intervalMs = 3e4) {
		if (this.intervalId) {
			console.log("[SyncEngine] Már fut, újraindítás...");
			this.stop();
		}
		console.log(`[SyncEngine] Indítás — ${intervalMs}ms intervallum`);
		setTimeout(() => {
			this.runSync();
		}, 5e3);
		this.intervalId = setInterval(() => {
			this.runSync();
		}, intervalMs);
	}
	/**
	* Szinkronizáció leállítása.
	*/
	stop() {
		if (this.intervalId) {
			clearInterval(this.intervalId);
			this.intervalId = null;
			console.log("[SyncEngine] Leállítva");
		}
	}
	/**
	* Teljes szinkronizálási ciklus futtatása.
	*/
	async runSync() {
		if (this.status.isRunning) {
			console.log("[SyncEngine] Előző sync még fut, kihagyás");
			return;
		}
		this.status.isRunning = true;
		try {
			const serverUrl = this.getServerUrl();
			let token = this.getAuthToken();
			if (token) {
				if (!await this.validateToken(serverUrl, token)) {
					this.clearStoredAuthToken();
					token = await this.bootstrapAuthSession(serverUrl);
				}
			} else token = await this.bootstrapAuthSession(serverUrl);
			const result = await this.syncAll(token);
			this.status.lastSyncResult = result;
			if (result.synced > 0) console.log(`[SyncEngine] ${result.synced} tranzakció szinkronizálva`);
			if (result.failed > 0) console.warn(`[SyncEngine] ${result.failed} tranzakció SIKERTELEN:`, result.errors);
			if (token) {
				await this.syncRates();
				await this.syncCirculars();
				await this.syncDistributions();
				await this.syncTransfers();
				await this.syncCollections();
				await this.cacheBranchStatus();
				await this.syncCashDeskMasterData();
				await this.syncWorkerMasterData();
			}
			this.status.lastSyncAt = (/* @__PURE__ */ new Date()).toISOString();
		} catch (err) {
			console.error("[SyncEngine] Sync hiba:", err);
		} finally {
			this.status.isRunning = false;
		}
	}
	/**
	* Pending tranzakciók szinkronizálása a szerverrel.
	*/
	async syncAll(tokenOverride) {
		const result = {
			synced: 0,
			failed: 0,
			errors: []
		};
		const pendingTransactions = getPendingTransactions();
		const pendingConversions = getPendingConversions();
		const pendingBankTransactions = getPendingBankTransactions();
		const pendingDistributions = getPendingDistributions();
		const pendingTransfers = getPendingTransfers();
		const pendingCollections = getPendingCollections();
		const pendingStornos = getPendingStornos();
		const pendingHandoverOperations = getPendingHandoverOperations();
		const totalPending = pendingTransactions.length + pendingConversions.length + pendingBankTransactions.length + pendingDistributions.length + pendingTransfers.length + pendingCollections.length + pendingStornos.length + pendingHandoverOperations.length;
		if (totalPending === 0) return result;
		const serverUrl = this.getServerUrl();
		const token = tokenOverride ?? this.getAuthToken();
		if (!token) {
			result.errors.push("Nincs auth token — bejelentkezés szükséges");
			result.failed = totalPending;
			return result;
		}
		for (const tx of pendingTransactions) try {
			await this.syncTransaction(serverUrl, token, tx);
			markTransactionSynced(tx.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`TX #${tx.id} (${tx.type} ${tx.currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const conversion of pendingConversions) try {
			await this.syncConversion(serverUrl, token, conversion);
			markConversionSynced(conversion.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`CONV #${conversion.id} (${conversion.from_currency_code}->${conversion.to_currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const bankTransaction of pendingBankTransactions) try {
			await this.syncBankTransaction(serverUrl, token, bankTransaction);
			markBankTransactionSynced(bankTransaction.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`BANK #${bankTransaction.id} (${bankTransaction.transaction_type} ${bankTransaction.currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const distribution of pendingDistributions) try {
			await this.syncDistribution(serverUrl, token, distribution);
			markDistributionSynced(distribution.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`DIST #${distribution.id} (${distribution.currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const transfer of pendingTransfers) try {
			await this.syncTransfer(serverUrl, token, transfer);
			markTransferSynced(transfer.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`TRANSFER #${transfer.id} (${transfer.currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const collection of pendingCollections) try {
			await this.syncCollection(serverUrl, token, collection);
			markCollectionSynced(collection.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`COLLECTION #${collection.id} (${collection.currency_code}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const storno of pendingStornos) try {
			await this.syncStorno(serverUrl, token, storno);
			markStornoSynced(storno.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`STORNO #${storno.id} (${storno.original_receipt_number}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		if (result.errors.some((error) => error.includes("Hálózati hiba"))) return result;
		for (const operation of pendingHandoverOperations) try {
			await this.syncHandoverOperation(serverUrl, token, operation);
			markHandoverOperationSynced(operation.id);
			result.synced++;
		} catch (err) {
			const errorMsg = err instanceof Error ? err.message : String(err);
			result.failed++;
			result.errors.push(`HANDOVER #${operation.id} (${operation.operation_type}): ${errorMsg}`);
			if (isAuthStatusError(err) || errorMsg.includes("HTTP 401") || errorMsg.includes("HTTP 403")) {
				result.errors.push("Auth/session hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
			if (errorMsg.includes("fetch") || errorMsg.includes("network") || errorMsg.includes("timeout")) {
				result.errors.push("Hálózati hiba — további próbálkozások leállítva");
				result.failed += totalPending - result.synced - result.failed;
				break;
			}
		}
		return result;
	}
	/**
	* Egyedi tranzakció szinkronizálása.
	*/
	async syncTransaction(serverUrl, token, tx) {
		const endpoint = tx.type === "SELL" ? `${serverUrl}/transactions/sell` : `${serverUrl}/transactions/buy`;
		const body = {
			currencyCode: tx.currency_code,
			currencyAmount: tx.foreign_amount,
			customExchangeRate: tx.rate
		};
		if (tx.handling_fee !== null && tx.handling_fee !== void 0) body["handlingFee"] = tx.handling_fee;
		if (tx.discount_percent !== null && tx.discount_percent !== void 0) body["discountPercent"] = tx.discount_percent;
		const customerIdentifier = tx.customer_identifier ?? (typeof tx.customer_id === "string" ? tx.customer_id : null);
		if (customerIdentifier && customerIdentifier.trim().length > 0) body["customerId"] = customerIdentifier;
		if (tx.customer_name && tx.customer_name.trim().length > 0) body["customerName"] = tx.customer_name;
		if (tx.customer_document_number && tx.customer_document_number.trim().length > 0) body["customerDocumentNumber"] = tx.customer_document_number;
		if (tx.customer_address && tx.customer_address.trim().length > 0) body["customerAddress"] = tx.customer_address;
		if (tx.denominations !== null) try {
			body["denominations"] = JSON.parse(tx.denominations);
		} catch {
			body["denominations"] = tx.denominations;
		}
		await httpPost(endpoint, body, token, tx.idempotency_key ?? void 0);
	}
	async syncConversion(serverUrl, token, conversion) {
		const body = { fromAmount: conversion.from_amount };
		if (conversion.from_currency_id && conversion.from_currency_id > 0) body["fromCurrencyId"] = conversion.from_currency_id;
		else body["fromCurrencyCode"] = conversion.from_currency_code;
		if (conversion.to_currency_id && conversion.to_currency_id > 0) body["toCurrencyId"] = conversion.to_currency_id;
		else body["toCurrencyCode"] = conversion.to_currency_code;
		if (conversion.handling_fee !== null && conversion.handling_fee !== void 0) body["handlingFee"] = conversion.handling_fee;
		if (conversion.customer_id && conversion.customer_id.trim().length > 0) body["customerId"] = conversion.customer_id;
		if (conversion.customer_name && conversion.customer_name.trim().length > 0) body["customerName"] = conversion.customer_name;
		if (conversion.customer_document_number && conversion.customer_document_number.trim().length > 0) body["customerDocumentNumber"] = conversion.customer_document_number;
		await httpPost(`${serverUrl}/transactions/conversion`, body, token, conversion.idempotency_key ?? void 0);
	}
	async syncBankTransaction(serverUrl, token, bankTransaction) {
		const body = {
			transactionType: bankTransaction.transaction_type,
			currencyCode: bankTransaction.currency_code,
			amount: bankTransaction.amount,
			exchangeRate: bankTransaction.exchange_rate
		};
		if (bankTransaction.vault_territory_id !== null && bankTransaction.vault_territory_id !== void 0) body["vaultTerritoryId"] = bankTransaction.vault_territory_id;
		if (bankTransaction.bank_name && bankTransaction.bank_name.trim().length > 0) body["bankName"] = bankTransaction.bank_name;
		if (bankTransaction.bank_reference && bankTransaction.bank_reference.trim().length > 0) body["bankReference"] = bankTransaction.bank_reference;
		if (bankTransaction.note && bankTransaction.note.trim().length > 0) body["note"] = bankTransaction.note;
		await httpPost(`${serverUrl}/ertektar/bank-transactions`, body, token, bankTransaction.idempotency_key ?? void 0);
	}
	async syncStorno(serverUrl, token, storno) {
		const body = {
			transactionId: storno.transaction_id,
			reason: storno.reason
		};
		if (storno.approval_id) body["approvalId"] = storno.approval_id;
		if (storno.custom_exchange_rate !== null && storno.custom_exchange_rate !== void 0) body["customExchangeRate"] = storno.custom_exchange_rate;
		if (storno.payment_method) body["paymentMethodDid"] = storno.payment_method;
		await httpPost(`${serverUrl}/stornos/execute`, body, token, storno.idempotency_key ?? void 0);
	}
	async syncDistribution(serverUrl, token, dist) {
		const body = {
			targetBranchCode: dist.target_branch_code,
			currencyCode: dist.currency_code,
			amount: dist.amount
		};
		if (dist.denominations) try {
			body["denominations"] = JSON.parse(dist.denominations);
		} catch {}
		if (dist.note) body["note"] = dist.note;
		await httpPost(`${serverUrl}/ertektar/distribution`, body, token, dist.idempotency_key ?? void 0);
	}
	async syncTransfer(serverUrl, token, tx) {
		const body = {
			amount: tx.amount,
			targetBranchCode: tx.target_branch_code,
			currencyCode: tx.currency_code
		};
		if (tx.target_branch_id) body["toBranchId"] = tx.target_branch_id;
		if (tx.currency_id !== null && tx.currency_id !== void 0) body["currencyId"] = tx.currency_id;
		if (tx.transfer_type) body["transferType"] = tx.transfer_type;
		if (tx.huf_value !== null && tx.huf_value !== void 0) body["hufValue"] = tx.huf_value;
		if (tx.denominations) try {
			body["denominations"] = JSON.parse(tx.denominations);
		} catch {}
		if (tx.note) body["notes"] = tx.note;
		await httpPost(`${serverUrl}/transfers`, body, token, tx.idempotency_key ?? void 0);
	}
	async syncCollection(serverUrl, token, col) {
		const body = {
			sourceBranchCode: col.source_branch_code,
			currencyCode: col.currency_code,
			amount: col.amount
		};
		if (col.note) body["note"] = col.note;
		await httpPost(`${serverUrl}/ertektar/collections`, body, token, col.idempotency_key ?? void 0);
	}
	async syncHandoverOperation(serverUrl, token, operation) {
		if (operation.operation_type === "GENERATE") {
			await httpPost(`${serverUrl}/handover-sheets/generate`, {
				fromCashDeskId: operation.from_cash_desk_id,
				toCashDeskId: operation.to_cash_desk_id,
				transferDate: operation.transfer_date,
				amounts: operation.amounts_json ? JSON.parse(operation.amounts_json) : {}
			}, token, operation.idempotency_key ?? void 0);
			return;
		}
		if (!operation.sheet_id) throw new Error("Hiányzó handover sheet id");
		await httpPost(operation.operation_type === "PRINT" ? `${serverUrl}/handover-sheets/${operation.sheet_id}/print` : `${serverUrl}/handover-sheets/${operation.sheet_id}/complete`, {}, token, operation.idempotency_key ?? void 0);
	}
	/**
	* Árfolyamok letöltése és SQLite cache frissítése.
	*
	* Legacy: ArfolyamBeolvasas — FTP szerveren lévő NR*.DAT fájl letöltése
	* és a helyi ARFOLYAM tábla frissítése.
	* Új rendszer: REST API-n keresztül kéri le az aktuális árfolyamokat.
	*/
	async syncRates() {
		try {
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			const rates = await httpGet(`${serverUrl}/exchange-rates/pos-current`, token);
			const db = getDb();
			if (!db || !Array.isArray(rates)) return;
			for (const rate of rates) db.run(`INSERT INTO cached_rates (currency_code, buy_rate, sell_rate, unit, updated_at,
             official_rate, limit1_amount, limit1_buy_rate, limit1_sell_rate,
             limit2_amount, limit2_buy_rate, limit2_sell_rate,
             limit3_amount, limit3_buy_rate, limit3_sell_rate)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
           ON CONFLICT(currency_code) DO UPDATE SET
             buy_rate = excluded.buy_rate,
             sell_rate = excluded.sell_rate,
             unit = excluded.unit,
             updated_at = excluded.updated_at,
             official_rate = excluded.official_rate,
             limit1_amount = excluded.limit1_amount,
             limit1_buy_rate = excluded.limit1_buy_rate,
             limit1_sell_rate = excluded.limit1_sell_rate,
             limit2_amount = excluded.limit2_amount,
             limit2_buy_rate = excluded.limit2_buy_rate,
             limit2_sell_rate = excluded.limit2_sell_rate,
             limit3_amount = excluded.limit3_amount,
             limit3_buy_rate = excluded.limit3_buy_rate,
             limit3_sell_rate = excluded.limit3_sell_rate`, [
				rate.currencyCode,
				rate.buyRate,
				rate.sellRate,
				rate.unit,
				rate.updatedAt,
				rate.officialRate ?? null,
				rate.limit1Amount ?? null,
				rate.limit1BuyRate ?? null,
				rate.limit1SellRate ?? null,
				rate.limit2Amount ?? null,
				rate.limit2BuyRate ?? null,
				rate.limit2SellRate ?? null,
				rate.limit3Amount ?? null,
				rate.limit3BuyRate ?? null,
				rate.limit3SellRate ?? null
			]);
			saveDatabase();
			console.log(`[SyncEngine] ${rates.length} árfolyam frissítve`);
		} catch (err) {
			if (isAuthStatusError(err)) {
				this.clearStoredAuthToken();
				console.warn("[SyncEngine] Árfolyam sync auth hiba (401/403), session újra-bootstrap szükséges.");
				return;
			}
			console.warn("[SyncEngine] Árfolyam sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Körlevelek letöltése és SQLite-ba mentése.
	*/
	async syncCirculars() {
		try {
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			const circulars = await httpGet(`${serverUrl}/circulars`, token);
			const db = getDb();
			if (!db || !Array.isArray(circulars)) return;
			db.run(`
        CREATE TABLE IF NOT EXISTS cached_circulars (
          id INTEGER PRIMARY KEY,
          subject TEXT NOT NULL,
          body TEXT NOT NULL,
          sender TEXT NOT NULL,
          sent_at TEXT NOT NULL,
          acknowledged INTEGER DEFAULT 0,
          cached_at TEXT DEFAULT (datetime('now'))
        )
      `);
			for (const circular of circulars) db.run(`INSERT INTO cached_circulars (id, subject, body, sender, sent_at)
           VALUES (?, ?, ?, ?, ?)
           ON CONFLICT(id) DO UPDATE SET
             subject = excluded.subject,
             body = excluded.body,
             sender = excluded.sender,
             sent_at = excluded.sent_at`, [
				circular.id,
				circular.subject,
				circular.body,
				circular.sender,
				circular.sentAt
			]);
			if (circulars.length > 0) {
				saveDatabase();
				console.log(`[SyncEngine] ${circulars.length} körlevél szinkronizálva`);
			}
		} catch (err) {
			if (isAuthStatusError(err)) {
				this.clearStoredAuthToken();
				console.warn("[SyncEngine] Körlevél sync auth hiba (401/403), session újra-bootstrap szükséges.");
				return;
			}
			console.warn("[SyncEngine] Körlevél sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Értéktár: Pending distributions szinkronizálása.
	*/
	async syncDistributions() {
		try {
			const pending = getPendingDistributions();
			if (pending.length === 0) return;
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			if (!token) return;
			for (const dist of pending) try {
				const body = {
					targetBranchCode: dist.target_branch_code,
					currencyCode: dist.currency_code,
					amount: dist.amount
				};
				if (dist.denominations) try {
					body["denominations"] = JSON.parse(dist.denominations);
				} catch {}
				if (dist.note) body["note"] = dist.note;
				await httpPost(`${serverUrl}/ertektar/distribution`, body, token, dist.idempotency_key ?? void 0);
				markDistributionSynced(dist.id);
			} catch (err) {
				if (isAuthStatusError(err)) {
					this.clearStoredAuthToken();
					console.warn("[SyncEngine] Distribution auth hiba (401/403), ciklus leállítva.");
					break;
				}
				console.warn(`[SyncEngine] Distribution #${dist.id} sync hiba:`, err instanceof Error ? err.message : err);
				break;
			}
		} catch (err) {
			console.warn("[SyncEngine] Distribution sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Értéktár: Pending transfers szinkronizálása.
	*/
	async syncTransfers() {
		try {
			const pending = getPendingTransfers();
			if (pending.length === 0) return;
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			if (!token) return;
			for (const tx of pending) try {
				const body = { amount: tx.amount };
				if (tx.target_branch_id) body["toBranchId"] = tx.target_branch_id;
				body["targetBranchCode"] = tx.target_branch_code;
				if (tx.currency_id !== null && tx.currency_id !== void 0) body["currencyId"] = tx.currency_id;
				body["currencyCode"] = tx.currency_code;
				if (tx.transfer_type) body["transferType"] = tx.transfer_type;
				if (tx.huf_value !== null && tx.huf_value !== void 0) body["hufValue"] = tx.huf_value;
				if (tx.denominations) try {
					body["denominations"] = JSON.parse(tx.denominations);
				} catch {}
				if (tx.note) body["notes"] = tx.note;
				await httpPost(`${serverUrl}/transfers`, body, token, tx.idempotency_key ?? void 0);
				markTransferSynced(tx.id);
			} catch (err) {
				if (isAuthStatusError(err)) {
					this.clearStoredAuthToken();
					console.warn("[SyncEngine] Transfer auth hiba (401/403), ciklus leállítva.");
					break;
				}
				console.warn(`[SyncEngine] Transfer #${tx.id} sync hiba:`, err instanceof Error ? err.message : err);
				break;
			}
		} catch (err) {
			console.warn("[SyncEngine] Transfer sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Értéktár: Pending collections szinkronizálása.
	*/
	async syncCollections() {
		try {
			const pending = getPendingCollections();
			if (pending.length === 0) return;
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			if (!token) return;
			for (const col of pending) try {
				const body = {
					sourceBranchCode: col.source_branch_code,
					currencyCode: col.currency_code,
					amount: col.amount
				};
				if (col.note) body["note"] = col.note;
				await httpPost(`${serverUrl}/ertektar/collections`, body, token, col.idempotency_key ?? void 0);
				markCollectionSynced(col.id);
			} catch (err) {
				if (isAuthStatusError(err)) {
					this.clearStoredAuthToken();
					console.warn("[SyncEngine] Collection auth hiba (401/403), ciklus leállítva.");
					break;
				}
				console.warn(`[SyncEngine] Collection #${col.id} sync hiba:`, err instanceof Error ? err.message : err);
				break;
			}
		} catch (err) {
			console.warn("[SyncEngine] Collection sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Értéktár: Pénztár státuszok cache-elése.
	*/
	async cacheBranchStatus() {
		try {
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			const branches = await httpGet(`${serverUrl}/ertektar/branches/status`, token);
			if (!Array.isArray(branches)) return;
			for (const branch of branches) saveCachedBranchStatus(branch.code, branch.name, branch.companyId, branch.lastSyncAt, branch.onlineStatus, branch.totalHufValue, branch.dailyTurnover, branch.cashBalances ? JSON.stringify(branch.cashBalances) : null);
			if (branches.length > 0) console.log(`[SyncEngine] ${branches.length} pénztár státusz cache-elve`);
		} catch (err) {
			if (isAuthStatusError(err)) {
				this.clearStoredAuthToken();
				console.warn("[SyncEngine] Branch status auth hiba (401/403), session újra-bootstrap szükséges.");
				return;
			}
			console.warn("[SyncEngine] Branch status cache hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Pénztár törzs (branch master) cache-elése.
	*/
	async syncCashDeskMasterData() {
		try {
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			const cashDesks = await httpGet(`${serverUrl}/branches?activeOnly=true`, token);
			if (!Array.isArray(cashDesks)) return;
			for (const cashDesk of cashDesks) saveCachedCashDesk(cashDesk.id, cashDesk.code, cashDesk.name, cashDesk.companyId ?? null, cashDesk.city ?? null, cashDesk.isActive ?? true);
			if (cashDesks.length > 0) console.log(`[SyncEngine] ${cashDesks.length} pénztár törzs rekord cache-elve`);
		} catch (err) {
			if (isAuthStatusError(err)) {
				this.clearStoredAuthToken();
				console.warn("[SyncEngine] Pénztár törzs sync auth hiba (401/403), session újra-bootstrap szükséges.");
				return;
			}
			console.warn("[SyncEngine] Pénztár törzs sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Dolgozó törzs cache-elése.
	*/
	async syncWorkerMasterData() {
		try {
			const serverUrl = this.getServerUrl();
			const token = this.getAuthToken();
			const workers = await httpGet(`${serverUrl}/workers/active`, token);
			if (!Array.isArray(workers)) return;
			for (const worker of workers) saveCachedWorker(worker.id, worker.workerCode ?? null, worker.fullName, worker.role ?? null, worker.branchId ?? null, worker.branchCode ?? null, worker.branchName ?? null, worker.companyId ?? null, worker.companyCode ?? null, worker.active ?? true);
			if (workers.length > 0) console.log(`[SyncEngine] ${workers.length} dolgozó törzs rekord cache-elve`);
		} catch (err) {
			if (isAuthStatusError(err)) {
				this.clearStoredAuthToken();
				console.warn("[SyncEngine] Dolgozó törzs sync auth hiba (401/403), session újra-bootstrap szükséges.");
				return;
			}
			console.warn("[SyncEngine] Dolgozó törzs sync hiba:", err instanceof Error ? err.message : err);
		}
	}
	/**
	* Aktuális szinkronizáció státusz lekérdezése.
	*/
	getStatus() {
		return { ...this.status };
	}
};
/**
* Globális SyncEngine példány — az electron main process-ben használjuk.
*/
var syncEngine = new SyncEngine();
//#endregion
//#region electron/camera.ts
var CAMERA_DIR = "C:/valuta/camera";
function sanitizeId$1(id) {
	const clean = id.replace(/[^a-zA-Z0-9_-]/g, "");
	if (!clean || clean !== id) throw new Error("Invalid transactionId: " + id);
	return clean;
}
function listDirectories(root) {
	if (!node_fs.default.existsSync(root)) return [];
	return node_fs.default.readdirSync(root).filter((entry) => {
		const fullPath = node_path.default.join(root, entry);
		return node_fs.default.existsSync(fullPath) && node_fs.default.statSync(fullPath).isDirectory();
	});
}
function collectFiles(root) {
	if (!node_fs.default.existsSync(root)) return [];
	const result = [];
	const entries = node_fs.default.readdirSync(root, { withFileTypes: true });
	for (const entry of entries) {
		const fullPath = node_path.default.join(root, entry.name);
		if (entry.isDirectory()) result.push(...collectFiles(fullPath));
		else if (entry.isFile()) result.push(fullPath);
	}
	return result;
}
function copyDirectoryWithCount(sourceDir, targetDir) {
	if (!node_fs.default.existsSync(sourceDir)) return 0;
	node_fs.default.mkdirSync(targetDir, { recursive: true });
	let count = 0;
	const entries = node_fs.default.readdirSync(sourceDir, { withFileTypes: true });
	for (const entry of entries) {
		const src = node_path.default.join(sourceDir, entry.name);
		const dest = node_path.default.join(targetDir, entry.name);
		if (entry.isDirectory()) count += copyDirectoryWithCount(src, dest);
		else if (entry.isFile()) {
			node_fs.default.mkdirSync(node_path.default.dirname(dest), { recursive: true });
			node_fs.default.copyFileSync(src, dest);
			count += 1;
		}
	}
	return count;
}
function getDirSize(dirPath) {
	if (!node_fs.default.existsSync(dirPath)) return 0;
	let size = 0;
	const entries = node_fs.default.readdirSync(dirPath, { withFileTypes: true });
	for (const entry of entries) {
		const fullPath = node_path.default.join(dirPath, entry.name);
		if (entry.isDirectory()) size += getDirSize(fullPath);
		else if (entry.isFile()) try {
			size += node_fs.default.statSync(fullPath).size;
		} catch {}
	}
	return size;
}
function registerCameraHandlers() {
	electron.ipcMain.handle("camera-save-recording", async (_event, transactionId, videoBuffer, extension) => {
		const date = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
		const safeId = sanitizeId$1(transactionId);
		const dir = node_path.default.join(CAMERA_DIR, date, safeId);
		node_fs.default.mkdirSync(dir, { recursive: true });
		const filename = `recording_${Date.now()}.${extension}`;
		const filepath = node_path.default.join(dir, filename);
		node_fs.default.writeFileSync(filepath, Buffer.from(videoBuffer));
		return filepath;
	});
	electron.ipcMain.handle("camera-export-to-usb", async (_event, dateFrom, dateTo) => {
		const result = await electron.dialog.showOpenDialog({
			title: "Válaszd ki az USB meghajtót",
			properties: ["openDirectory"],
			buttonLabel: "Exportálás ide"
		});
		if (result.canceled || !result.filePaths[0]) return {
			success: false,
			exported: 0,
			error: "Megszakítva"
		};
		const from = new Date(dateFrom);
		const to = new Date(dateTo);
		if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) return {
			success: false,
			exported: 0,
			error: "Érvénytelen dátum"
		};
		if (from > to) return {
			success: false,
			exported: 0,
			error: "A dátumtartomány hibás"
		};
		try {
			const targetDir = node_path.default.join(result.filePaths[0], "valuta_kamera_export");
			node_fs.default.mkdirSync(targetDir, { recursive: true });
			let exported = 0;
			const dateDirs = listDirectories(CAMERA_DIR);
			for (const dateDir of dateDirs) {
				const dateValue = new Date(dateDir);
				if (Number.isNaN(dateValue.getTime())) continue;
				if (dateValue < from || dateValue > to) continue;
				const sourceDir = node_path.default.join(CAMERA_DIR, dateDir);
				const destinationDir = node_path.default.join(targetDir, dateDir);
				exported += copyDirectoryWithCount(sourceDir, destinationDir);
			}
			return {
				success: true,
				exported
			};
		} catch (err) {
			return {
				success: false,
				exported: 0,
				error: `Írási hiba: ${err.message}`
			};
		}
	});
	electron.ipcMain.handle("camera-list-recordings", async (_event, transactionId) => {
		if (!node_fs.default.existsSync(CAMERA_DIR)) return [];
		if (transactionId) {
			const recordings = [];
			const safeId = sanitizeId$1(transactionId);
			const dateDirs = listDirectories(CAMERA_DIR);
			for (const dateDir of dateDirs) {
				const candidateDir = node_path.default.join(CAMERA_DIR, dateDir, safeId);
				recordings.push(...collectFiles(candidateDir));
			}
			return recordings;
		}
		return collectFiles(CAMERA_DIR);
	});
	electron.ipcMain.handle("camera-local-storage-stats", async () => {
		if (!node_fs.default.existsSync(CAMERA_DIR)) return {
			totalUsageBytes: 0,
			availableSpaceBytes: 0,
			totalRecordings: 0,
			oldestDate: null,
			newestDate: null
		};
		const totalUsageBytes = getDirSize(CAMERA_DIR);
		const allFiles = collectFiles(CAMERA_DIR);
		const dateDirs = listDirectories(CAMERA_DIR).sort();
		let availableSpaceBytes = 0;
		try {
			const stats = node_fs.default.statfsSync(CAMERA_DIR);
			availableSpaceBytes = Number(stats.bavail) * Number(stats.bsize);
		} catch {}
		return {
			totalUsageBytes,
			availableSpaceBytes,
			totalRecordings: allFiles.length,
			oldestDate: dateDirs.length > 0 ? dateDirs[0] : null,
			newestDate: dateDirs.length > 0 ? dateDirs[dateDirs.length - 1] : null
		};
	});
	electron.ipcMain.handle("camera-local-recordings-by-date", async (_event, dateFrom, dateTo) => {
		if (!node_fs.default.existsSync(CAMERA_DIR)) return [];
		const from = new Date(dateFrom);
		const to = new Date(dateTo);
		if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) return [];
		const results = [];
		const dateDirs = listDirectories(CAMERA_DIR);
		for (const dateDir of dateDirs) {
			const dirDate = new Date(dateDir);
			if (Number.isNaN(dirDate.getTime())) continue;
			if (dirDate < from || dirDate > to) continue;
			const txDirs = listDirectories(node_path.default.join(CAMERA_DIR, dateDir));
			for (const txDir of txDirs) {
				const files = collectFiles(node_path.default.join(CAMERA_DIR, dateDir, txDir));
				for (const filePath of files) try {
					const stat = node_fs.default.statSync(filePath);
					results.push({
						date: dateDir,
						transactionId: txDir,
						filePath,
						fileSizeBytes: stat.size,
						createdAt: stat.birthtime.toISOString()
					});
				} catch {}
			}
		}
		return results;
	});
	electron.ipcMain.handle("camera-local-read-file", async (_event, filePath) => {
		const resolved = node_path.default.resolve(filePath);
		if (!resolved.startsWith(node_path.default.resolve(CAMERA_DIR))) return null;
		if (!node_fs.default.existsSync(resolved)) return null;
		return node_fs.default.readFileSync(resolved).toString("base64");
	});
	electron.ipcMain.handle("camera-local-cleanup", async (_event, retentionDays) => {
		if (!node_fs.default.existsSync(CAMERA_DIR)) return { deletedCount: 0 };
		const cutoff = /* @__PURE__ */ new Date();
		cutoff.setDate(cutoff.getDate() - retentionDays);
		let deletedCount = 0;
		for (const dateDir of listDirectories(CAMERA_DIR)) {
			const dirDate = new Date(dateDir);
			if (Number.isNaN(dirDate.getTime()) || dirDate >= cutoff) continue;
			const dirPath = node_path.default.join(CAMERA_DIR, dateDir);
			const fileCount = collectFiles(dirPath).length;
			try {
				node_fs.default.rmSync(dirPath, {
					recursive: true,
					force: true
				});
				deletedCount += fileCount;
			} catch {}
		}
		return { deletedCount };
	});
}
//#endregion
//#region electron/scanner.ts
var SCAN_DIR = "C:/valuta/scan";
var ENCRYPTION_KEY_FILE = "C:/valuta/.scan_key";
function sanitizeId(id) {
	const clean = id.replace(/[^a-zA-Z0-9_-]/g, "");
	if (!clean || clean !== id) throw new Error("Invalid transactionId: " + id);
	return clean;
}
function getOrCreateKey() {
	if (node_fs.default.existsSync(ENCRYPTION_KEY_FILE)) {
		const stored = node_fs.default.readFileSync(ENCRYPTION_KEY_FILE, "utf8").trim();
		return Buffer.from(stored, "base64");
	}
	const key = node_crypto.default.randomBytes(32);
	node_fs.default.writeFileSync(ENCRYPTION_KEY_FILE, key.toString("base64"), { mode: 384 });
	return key;
}
function encrypt(buffer) {
	const key = getOrCreateKey();
	const iv = node_crypto.default.randomBytes(16);
	const cipher = node_crypto.default.createCipheriv("aes-256-gcm", key, iv);
	const encrypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
	const tag = cipher.getAuthTag();
	return {
		encrypted,
		iv: iv.toString("hex"),
		tag: tag.toString("hex")
	};
}
function decrypt(encrypted, iv, tag) {
	const key = getOrCreateKey();
	const decipher = node_crypto.default.createDecipheriv("aes-256-gcm", key, Buffer.from(iv, "hex"));
	decipher.setAuthTag(Buffer.from(tag, "hex"));
	return Buffer.concat([decipher.update(encrypted), decipher.final()]);
}
function registerScannerHandlers() {
	electron.ipcMain.handle("scan-save-document", async (_event, transactionId, documentType, imageBase64) => {
		const { encrypted, iv, tag } = encrypt(Buffer.from(imageBase64, "base64"));
		const date = (/* @__PURE__ */ new Date()).toISOString().slice(0, 10);
		const safeId = sanitizeId(transactionId);
		const dir = node_path.default.join(SCAN_DIR, date, safeId);
		node_fs.default.mkdirSync(dir, { recursive: true });
		const filename = `${documentType}_${Date.now()}.enc`;
		const filepath = node_path.default.join(dir, filename);
		node_fs.default.writeFileSync(filepath, encrypted);
		node_fs.default.writeFileSync(`${filepath}.meta`, JSON.stringify({
			iv,
			tag,
			documentType,
			timestamp: (/* @__PURE__ */ new Date()).toISOString()
		}));
		return {
			path: filepath,
			encrypted: true
		};
	});
	electron.ipcMain.handle("scan-get-document", async (_event, filepath) => {
		const resolved = node_path.default.resolve(filepath);
		if (!resolved.startsWith(node_path.default.resolve(SCAN_DIR))) throw new Error("Érvénytelen fájlútvonal");
		const encrypted = node_fs.default.readFileSync(resolved);
		const metaRaw = node_fs.default.readFileSync(`${resolved}.meta`, "utf8");
		const meta = JSON.parse(metaRaw);
		return decrypt(encrypted, meta.iv, meta.tag).toString("base64");
	});
	electron.ipcMain.handle("scan-list-documents", async (_event, transactionId) => {
		if (!node_fs.default.existsSync(SCAN_DIR)) return [];
		const results = [];
		const safeId = sanitizeId(transactionId);
		const dateDirs = node_fs.default.readdirSync(SCAN_DIR);
		for (const dateDir of dateDirs) {
			const candidate = node_path.default.join(SCAN_DIR, dateDir, safeId);
			if (!node_fs.default.existsSync(candidate) || !node_fs.default.statSync(candidate).isDirectory()) continue;
			const files = node_fs.default.readdirSync(candidate);
			for (const file of files) if (file.endsWith(".enc")) results.push(node_path.default.join(candidate, file));
		}
		return results;
	});
}
//#endregion
//#region electron/updater.ts
function registerUpdaterHandlers() {
	electron.ipcMain.handle("restart-app", () => {
		try {
			electron.app.relaunch();
			electron.app.exit(0);
			return true;
		} catch (err) {
			electron_log_main.default.error("[Updater] restart-app failed", err);
			return false;
		}
	});
}
//#endregion
//#region electron/main.ts
import("dotenv/config").catch(() => {});
electron.app.commandLine.appendSwitch("no-sandbox");
electron.app.commandLine.appendSwitch("disable-gpu-sandbox");
var isDev = !electron.app.isPackaged;
var devServerUrl = process.env.ELECTRON_RENDERER_URL ?? "http://127.0.0.1:3000";
var devUserDataDir = process.env.ELECTRON_DEV_USER_DATA;
var shouldAutoOpenDevTools = isDev && [
	"1",
	"true",
	"yes",
	"on"
].includes((process.env.ELECTRON_OPEN_DEVTOOLS ?? "").toLowerCase());
if (isDev && devUserDataDir) {
	electron.app.commandLine.appendSwitch("user-data-dir", devUserDataDir);
	electron.app.setPath("userData", devUserDataDir);
	electron.app.setPath("sessionData", node_path.default.join(devUserDataDir, "session"));
	electron.app.commandLine.appendSwitch("disk-cache-dir", node_path.default.join(devUserDataDir, "cache"));
	electron.app.commandLine.appendSwitch("disable-gpu-shader-disk-cache");
}
electron.protocol.registerSchemesAsPrivileged([{
	scheme: "app",
	privileges: {
		standard: true,
		secure: true,
		supportFetchAPI: true,
		corsEnabled: true,
		stream: true
	}
}]);
electron_log_main.default.initialize();
electron_log_main.default.transports.file.level = "info";
electron_log_main.default.transports.console.level = isDev ? "debug" : "warn";
process.on("uncaughtException", (err) => {
	electron_log_main.default.error("[Process] uncaughtException", err);
});
process.on("unhandledRejection", (reason) => {
	electron_log_main.default.error("[Process] unhandledRejection", reason);
});
var mainWindow = null;
function createWindow() {
	mainWindow = new electron.BrowserWindow({
		width: 1280,
		height: 1024,
		resizable: isDev,
		fullscreen: false,
		autoHideMenuBar: true,
		title: "Valuta Pénztár",
		webPreferences: {
			preload: node_path.default.join(__dirname, "preload.js"),
			contextIsolation: true,
			nodeIntegration: false,
			sandbox: true,
			webSecurity: true,
			allowRunningInsecureContent: false,
			experimentalFeatures: false
		}
	});
	if (isDev) {
		electron_log_main.default.info(`[App] Dev renderer URL: ${devServerUrl}`);
		const loadDevUrlWithRetry = async () => {
			const retries = 20;
			for (let i = 0; i < retries; i += 1) try {
				await mainWindow?.loadURL(devServerUrl);
				return;
			} catch (err) {
				const message = err instanceof Error ? err.message : String(err);
				electron_log_main.default.warn(`[DevLoad] attempt ${i + 1}/${retries} failed: ${message}`);
				await new Promise((resolve) => setTimeout(resolve, 500));
			}
			electron.dialog.showErrorBox("Fejlesztői indítási hiba", `A renderer nem tudott csatlakozni a dev szerverhez: ${devServerUrl}\n\nEllenőrizze, hogy a Vite szerver fut-e, majd indítsa újra az alkalmazást.`);
		};
		loadDevUrlWithRetry();
		if (shouldAutoOpenDevTools) mainWindow.webContents.openDevTools({ mode: "detach" });
	} else mainWindow.loadURL("app://localhost/index.html");
	mainWindow.webContents.on("console-message", (_event, level, message, line, sourceId) => {
		if (level >= 2) electron_log_main.default.warn(`[Renderer] L${level} ${sourceId}:${line} — ${message}`);
	});
	mainWindow.webContents.on("did-fail-load", (_event, errorCode, errorDescription, validatedURL) => {
		electron_log_main.default.error(`[Renderer] did-fail-load ${errorCode} ${errorDescription} @ ${validatedURL}`);
	});
	mainWindow.webContents.on("render-process-gone", (_event, details) => {
		electron_log_main.default.error("[Renderer] Process gone:", details.reason);
		electron.dialog.showErrorBox("Megjelenítési hiba", `A program megjelenítő folyamata leállt.\nOk: ${details.reason}\n\nKérjük, indítsa újra az alkalmazást.`);
	});
	mainWindow.webContents.on("before-input-event", (_event, input) => {
		if (input.key === "F12" && input.type === "keyDown") mainWindow?.webContents.toggleDevTools();
	});
	mainWindow.webContents.on("will-navigate", (event, url) => {
		if (!["app://localhost", devServerUrl].some((origin) => url.startsWith(origin))) {
			electron_log_main.default.warn(`[Security] Blocked navigation to: ${url}`);
			event.preventDefault();
		}
	});
	mainWindow.webContents.setWindowOpenHandler(({ url }) => {
		electron_log_main.default.warn(`[Security] Blocked popup window: ${url}`);
		return { action: "deny" };
	});
	mainWindow.on("closed", () => {
		mainWindow = null;
	});
}
electron.ipcMain.handle("print-receipt", async (_event, dataJson) => {
	try {
		return await printReceipt(JSON.parse(dataJson), getConfig("printer.deviceName") ?? void 0, getConfig("printer.serialPort") ?? void 0);
	} catch (err) {
		console.error("[IPC] print-receipt hiba:", err);
		return false;
	}
});
electron.ipcMain.handle("list-serial-ports", async () => {
	try {
		const { listSerialPorts } = await Promise.resolve().then(() => require("./serial-printer-SF75wf_9.js"));
		return await listSerialPorts();
	} catch (err) {
		console.error("[IPC] list-serial-ports hiba:", err);
		return [];
	}
});
electron.ipcMain.handle("open-cash-drawer", async () => {
	try {
		const serialPort = getConfig(SERIAL_PORT_CONFIG_KEY);
		if (!serialPort) return false;
		const { openCashDrawer } = await Promise.resolve().then(() => require("./serial-printer-SF75wf_9.js"));
		return await openCashDrawer({ port: serialPort });
	} catch (err) {
		console.error("[IPC] open-cash-drawer hiba:", err);
		return false;
	}
});
electron.ipcMain.handle("get-config", async (_event, key) => {
	return getConfig(key);
});
electron.ipcMain.handle("set-config", async (_event, key, value) => {
	setConfig(key, value);
});
electron.ipcMain.handle("delete-config", async (_event, key) => {
	deleteConfig(key);
});
electron.ipcMain.handle("save-pending-transaction", async (_event, type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, handlingFee, discountPercent, customerIdentifier, customerName, customerDocumentNumber, customerAddress, denominations) => {
	return savePendingTransaction(type, currencyCode, foreignAmount, hufAmount, roundedHufAmount, rate, handlingFee, discountPercent, customerIdentifier, customerName, customerDocumentNumber, customerAddress, denominations);
});
electron.ipcMain.handle("get-pending-transactions", async () => {
	return getPendingTransactions();
});
electron.ipcMain.handle("save-pending-conversion", async (_event, fromCurrencyId, fromCurrencyCode, toCurrencyId, toCurrencyCode, fromAmount, calculatedHufAmount, calculatedToAmount, conversionRate, handlingFee, customerId, customerName, customerDocumentNumber, note) => {
	return savePendingConversion(fromCurrencyId, fromCurrencyCode, toCurrencyId, toCurrencyCode, fromAmount, calculatedHufAmount, calculatedToAmount, conversionRate, handlingFee, customerId, customerName, customerDocumentNumber, note);
});
electron.ipcMain.handle("get-pending-conversions", async () => {
	return getPendingConversions();
});
electron.ipcMain.handle("save-pending-bank-transaction", async (_event, transactionType, currencyCode, amount, exchangeRate, hufAmount, vaultTerritoryId, bankName, bankReference, note) => {
	return savePendingBankTransaction(transactionType, currencyCode, amount, exchangeRate, hufAmount, vaultTerritoryId, bankName, bankReference, note);
});
electron.ipcMain.handle("get-pending-bank-transactions", async () => {
	return getPendingBankTransactions();
});
electron.ipcMain.handle("save-pending-storno", async (_event, payload) => {
	return savePendingStorno(payload);
});
electron.ipcMain.handle("get-pending-stornos", async () => {
	return getPendingStornos();
});
electron.ipcMain.handle("get-pending-transaction-count", async () => {
	return getPendingTransactionCount();
});
electron.ipcMain.handle("mark-transaction-synced", async (_event, id) => {
	markTransactionSynced(id);
});
electron.ipcMain.handle("mark-conversion-synced", async (_event, id) => {
	markConversionSynced(id);
});
electron.ipcMain.handle("mark-bank-transaction-synced", async (_event, id) => {
	markBankTransactionSynced(id);
});
electron.ipcMain.handle("mark-storno-synced", async (_event, id) => {
	markStornoSynced(id);
});
electron.ipcMain.handle("sync-offline", async () => {
	return (await syncEngine.syncAll()).synced;
});
electron.ipcMain.handle("get-sync-status", async () => {
	return JSON.stringify(syncEngine.getStatus());
});
electron.ipcMain.handle("get-app-version", async () => {
	return electron.app.getVersion();
});
electron.ipcMain.handle("get-printers", async () => {
	if (!mainWindow) return [];
	return mainWindow.webContents.getPrintersAsync();
});
electron.ipcMain.handle("save-pending-distribution", async (_event, targetBranchCode, currencyCode, amount, denominations, note) => {
	return savePendingDistribution(targetBranchCode, currencyCode, amount, denominations, note);
});
electron.ipcMain.handle("save-pending-transfer", async (_event, targetBranchId, targetBranchCode, currencyId, currencyCode, amount, hufValue, transferType, denominations, note) => {
	return savePendingTransfer(targetBranchId, targetBranchCode, currencyId, currencyCode, amount, hufValue, transferType, denominations, note);
});
electron.ipcMain.handle("get-pending-transfers", async () => {
	return getPendingTransfers();
});
electron.ipcMain.handle("save-pending-collection", async (_event, sourceBranchCode, currencyCode, amount, note) => {
	return savePendingCollection(sourceBranchCode, currencyCode, amount, note);
});
electron.ipcMain.handle("save-pending-handover-operation", async (_event, payload) => {
	return savePendingHandoverOperation(payload);
});
electron.ipcMain.handle("get-pending-handover-operations", async () => {
	return getPendingHandoverOperations();
});
electron.ipcMain.handle("get-cached-branch-statuses", async () => {
	return getCachedBranchStatuses();
});
electron.ipcMain.handle("get-cached-branch-status-timestamp", async () => {
	return getCachedBranchStatusTimestamp();
});
electron.ipcMain.handle("get-cached-rates", async () => {
	return getCachedRates();
});
electron.ipcMain.handle("get-cached-cash-desks", async () => {
	return getCachedCashDesks();
});
electron.ipcMain.handle("get-cached-cash-desk-timestamp", async () => {
	return getCachedCashDeskTimestamp();
});
electron.ipcMain.handle("get-cached-workers", async () => {
	return getCachedWorkers();
});
electron.ipcMain.handle("get-cached-worker-timestamp", async () => {
	return getCachedWorkerTimestamp();
});
electron.ipcMain.handle("save-local-audit-event", async (_event, payload) => {
	return saveLocalAuditEvent(payload);
});
electron.ipcMain.handle("get-local-audit-events", async (_event, limit) => {
	return getLocalAuditEvents(limit ?? 200);
});
electron.ipcMain.handle("secure-store-token", async (_event, token) => {
	try {
		if (!electron.safeStorage.isEncryptionAvailable()) {
			electron_log_main.default.warn("[SafeStorage] Encryption not available, falling back to config store");
			setConfig("auth_token", token);
			return true;
		}
		setConfig("auth_token_encrypted", electron.safeStorage.encryptString(token).toString("base64"));
		deleteConfig("auth_token");
		return true;
	} catch (err) {
		electron_log_main.default.error("[SafeStorage] store-token error:", err);
		return false;
	}
});
electron.ipcMain.handle("secure-load-token", async () => {
	try {
		const encrypted = getConfig("auth_token_encrypted");
		if (encrypted && electron.safeStorage.isEncryptionAvailable()) try {
			const buffer = Buffer.from(encrypted, "base64");
			return electron.safeStorage.decryptString(buffer);
		} catch (err) {
			electron_log_main.default.warn("[SafeStorage] Corrupted encrypted token removed");
			deleteConfig("auth_token_encrypted");
		}
		const plaintext = getConfig("auth_token");
		if (plaintext) {
			electron_log_main.default.info("[SafeStorage] Migrating plaintext token to encrypted storage");
			if (electron.safeStorage.isEncryptionAvailable()) {
				setConfig("auth_token_encrypted", electron.safeStorage.encryptString(plaintext).toString("base64"));
				deleteConfig("auth_token");
			}
			return plaintext;
		}
		return null;
	} catch (err) {
		electron_log_main.default.error("[SafeStorage] load-token error:", err);
		return null;
	}
});
electron.ipcMain.handle("secure-clear-token", async () => {
	deleteConfig("auth_token_encrypted");
	deleteConfig("auth_token");
});
electron.app.whenReady().then(async () => {
	if (isDev) {
		const devCsp = [
			"default-src 'self' app: data: blob: http: https:",
			"script-src 'self' 'unsafe-inline' http: https:",
			"style-src 'self' 'unsafe-inline' http: https:",
			"img-src 'self' data: blob: http: https:",
			"font-src 'self' data: http: https:",
			"connect-src 'self' data: blob: http: https: ws: wss:",
			"worker-src 'self' blob:",
			"object-src 'none'",
			"base-uri 'self'",
			"frame-ancestors 'none'"
		].join("; ");
		electron.session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
			callback({ responseHeaders: {
				...details.responseHeaders ?? {},
				"Content-Security-Policy": [devCsp]
			} });
		});
	}
	registerCameraHandlers();
	registerScannerHandlers();
	registerUpdaterHandlers();
	const distPath = node_path.default.join(__dirname, "../dist");
	electron.protocol.handle("app", (req) => {
		const url = new URL(req.url);
		let filePath = node_path.default.join(distPath, decodeURIComponent(url.pathname));
		if (url.pathname === "/" || url.pathname === "") filePath = node_path.default.join(distPath, "index.html");
		if (!(node_path.default.extname(filePath) !== "")) filePath = node_path.default.join(distPath, "index.html");
		const resolved = node_path.default.resolve(filePath);
		const resolvedDist = node_path.default.resolve(distPath);
		if (!resolved.startsWith(resolvedDist + node_path.default.sep) && resolved !== resolvedDist) {
			electron_log_main.default.warn(`[Protocol] Path traversal blokkolva: ${req.url} → ${resolved}`);
			filePath = node_path.default.join(distPath, "index.html");
		}
		electron_log_main.default.info(`[Protocol] ${req.url} → ${filePath}`);
		return electron.net.fetch((0, node_url.pathToFileURL)(filePath).toString());
	});
	electron_log_main.default.info("[App] Custom \"app\" protocol regisztrálva, distPath:", distPath);
	try {
		await initDatabase();
	} catch (err) {
		electron_log_main.default.error("[App] initDatabase failed", err);
		const details = err instanceof Error ? err.message : String(err);
		electron.dialog.showErrorBox("Adatbázis hiba", `A helyi adatbázist nem sikerült inicializálni.\n\nRészletek:\n${details}`);
		electron.app.quit();
		return;
	}
	if (isDev) {
		const currentServerUrl = getConfig("server_url");
		if (!currentServerUrl || currentServerUrl.includes("localhost:8080")) {
			setConfig("server_url", "https://excvaluta.com/api/v1");
			electron_log_main.default.info("[App] Dev default server_url set to https://excvaluta.com/api/v1");
		}
	}
	createWindow();
	syncEngine.start(3e4);
	electron_log_main.default.info("[App] SyncEngine elindítva");
});
electron.app.on("will-quit", () => {
	syncEngine.stop();
	electron_log_main.default.info("[App] SyncEngine leállítva");
});
electron.app.on("window-all-closed", () => {
	electron.app.quit();
});
electron.app.on("activate", () => {
	if (mainWindow === null) createWindow();
});
//#endregion
