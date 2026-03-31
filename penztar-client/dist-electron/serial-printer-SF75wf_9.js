const require_chunk = require("./chunk-DyKKrNZQ.js");
let electron_log_main = require("electron-log/main");
electron_log_main = require_chunk.__toESM(electron_log_main);
//#region electron/serial-printer.ts
/**
* Star Micronics SP500 — Soros port (COM) blokknyomtató driver.
*
* Támogatott modellek:
*   - Star SP500 (SP512MC, SP512) — mátrix/impact, ESC/POS emulációs módban
*   - Egyéb ESC/POS kompatibilis soros blokknyomtatók
*
* Protokoll: ESC/POS soros porton (RS-232C)
* Alapértelmezett: 9600 baud, 8N1, DTR handshake
*
* FONTOS: A Star SP500 DIP switch-csel kell ESC/POS módra állítani!
* (Alapból Star Line Mode-ban van.)
*
* Karakterszélesség: 42 karakter (normál) / 21 (dupla széles)
*/
var DEFAULT_CONFIG = {
	port: "COM1",
	baudRate: 9600,
	dataBits: 8,
	parity: "even",
	stopBits: 1,
	encoding: "cp852"
};
var ESC = 27;
var GS = 29;
var COMMANDS = {
	INIT: Buffer.from([ESC, 64]),
	ALIGN_LEFT: Buffer.from([
		ESC,
		97,
		0
	]),
	ALIGN_CENTER: Buffer.from([
		ESC,
		97,
		1
	]),
	ALIGN_RIGHT: Buffer.from([
		ESC,
		97,
		2
	]),
	BOLD_ON: Buffer.from([
		ESC,
		69,
		1
	]),
	BOLD_OFF: Buffer.from([
		ESC,
		69,
		0
	]),
	UNDERLINE_ON: Buffer.from([
		ESC,
		45,
		1
	]),
	UNDERLINE_OFF: Buffer.from([
		ESC,
		45,
		0
	]),
	NORMAL_SIZE: Buffer.from([
		GS,
		33,
		0
	]),
	DOUBLE_WIDTH: Buffer.from([
		GS,
		33,
		16
	]),
	DOUBLE_HEIGHT: Buffer.from([
		GS,
		33,
		1
	]),
	DOUBLE_BOTH: Buffer.from([
		GS,
		33,
		17
	]),
	CUT_PARTIAL: Buffer.from([
		GS,
		86,
		1
	]),
	CUT_FULL: Buffer.from([
		GS,
		86,
		0
	]),
	feedLines: (n) => Buffer.from([
		ESC,
		100,
		n
	]),
	OPEN_DRAWER: Buffer.from([
		ESC,
		112,
		0,
		25,
		120
	]),
	SET_CODEPAGE_852: Buffer.from([
		ESC,
		116,
		18
	]),
	LF: Buffer.from([10])
};
var CP852_MAP = {
	"á": 160,
	"Á": 181,
	"é": 130,
	"É": 144,
	"í": 161,
	"Í": 214,
	"ó": 162,
	"Ó": 224,
	"ö": 148,
	"Ö": 153,
	"ő": 139,
	"Ő": 138,
	"ú": 163,
	"Ú": 233,
	"ü": 129,
	"Ü": 154,
	"ű": 251,
	"Ű": 235
};
/**
* UTF-8 string → CP852 kódolású Buffer konverzió.
* A nem konvertálható karakterek ASCII '?'-re cserélődnek.
*/
function toCP852(text) {
	const bytes = [];
	for (const ch of text) {
		const code = ch.charCodeAt(0);
		if (CP852_MAP[ch] !== void 0) bytes.push(CP852_MAP[ch]);
		else if (code >= 32 && code <= 126) bytes.push(code);
		else if (code === 10) bytes.push(10);
		else bytes.push(63);
	}
	return Buffer.from(bytes);
}
var LINE_WIDTH = 42;
function line(ch = "─") {
	return toCP852(ch.repeat(LINE_WIDTH));
}
function doubleLine() {
	return toCP852("=".repeat(LINE_WIDTH));
}
function twoColumn(left, right) {
	const gap = LINE_WIDTH - left.length - right.length;
	if (gap < 1) return (left + " " + right).slice(0, LINE_WIDTH);
	return left + " ".repeat(gap) + right;
}
/**
* Visszaadja az elérhető soros portok listáját (COM1, COM2, stb.)
* IPC-ből hívható: a felhasználó kiválaszthatja a port-ot.
*/
async function listSerialPorts() {
	try {
		const { SerialPort } = await Promise.resolve().then(() => /* @__PURE__ */ require_chunk.__toESM(require("./dist-gKGTpKa7.js").default));
		return await SerialPort.list();
	} catch (err) {
		electron_log_main.default.error("[SERIAL-PRINTER] Soros portok listázása sikertelen:", err);
		return [];
	}
}
/**
* Adat küldése a soros blokknyomtatóra.
*
* @param data - A küldendő byte-ok (ESC/POS parancsok + szöveg)
* @param config - Soros port konfiguráció
* @returns true ha a küldés sikeres
*/
async function printToSerial(data, config = {}) {
	const cfg = {
		...DEFAULT_CONFIG,
		...config
	};
	try {
		const { SerialPort } = await Promise.resolve().then(() => /* @__PURE__ */ require_chunk.__toESM(require("./dist-gKGTpKa7.js").default));
		const port = new SerialPort({
			path: cfg.port,
			baudRate: cfg.baudRate,
			dataBits: cfg.dataBits,
			parity: cfg.parity,
			stopBits: cfg.stopBits,
			autoOpen: false
		});
		return new Promise((resolve) => {
			port.open((openErr) => {
				if (openErr) {
					electron_log_main.default.error(`[SERIAL-PRINTER] Port nyitás sikertelen (${cfg.port}):`, openErr.message);
					resolve(false);
					return;
				}
				port.write(data, (writeErr) => {
					if (writeErr) {
						electron_log_main.default.error(`[SERIAL-PRINTER] Írás sikertelen (${cfg.port}):`, writeErr.message);
						port.close();
						resolve(false);
						return;
					}
					port.drain((drainErr) => {
						if (drainErr) electron_log_main.default.warn(`[SERIAL-PRINTER] Drain figyelmeztetés (${cfg.port}):`, drainErr.message);
						port.close((closeErr) => {
							if (closeErr) electron_log_main.default.warn(`[SERIAL-PRINTER] Port zárás figyelmeztetés:`, closeErr.message);
							electron_log_main.default.info(`[SERIAL-PRINTER] Nyomtatás sikeres (${cfg.port})`);
							resolve(true);
						});
					});
				});
			});
		});
	} catch (err) {
		electron_log_main.default.error("[SERIAL-PRINTER] Kritikus hiba:", err);
		return false;
	}
}
/**
* Pénzfiók nyitása a soros porton keresztül.
* A Star SP500 DK portján lévő fióknak küld impulzust.
*/
async function openCashDrawer(config = {}) {
	return printToSerial(Buffer.concat([COMMANDS.INIT, COMMANDS.OPEN_DRAWER]), config);
}
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
function fmtAmount(value) {
	if (value === void 0) return "—";
	return value.toLocaleString("hu-HU", { maximumFractionDigits: 2 });
}
function fmtRate(value) {
	if (value === void 0) return "—";
	return value.toLocaleString("hu-HU", {
		minimumFractionDigits: 2,
		maximumFractionDigits: 4
	});
}
/**
* Teljes bizonylat ESC/POS adat generálása a Star SP500-nak.
* Buffer-t ad vissza, amit közvetlenül a soros portra kell küldeni.
*/
function buildReceiptForSerial(data) {
	const company = COMPANIES[data.companyType] ?? COMPANIES["BEST_CHANGE"];
	const parts = [];
	const push = (...bufs) => {
		for (const b of bufs) parts.push(b);
	};
	const text = (s) => push(toCP852(s), COMMANDS.LF);
	const blank = () => push(COMMANDS.LF);
	push(COMMANDS.INIT, COMMANDS.SET_CODEPAGE_852);
	push(COMMANDS.ALIGN_CENTER, COMMANDS.BOLD_ON, COMMANDS.DOUBLE_BOTH);
	text(company.name);
	push(COMMANDS.NORMAL_SIZE);
	text(company.fullName);
	push(COMMANDS.BOLD_OFF);
	text(company.address);
	const phone = data.companyPhone || company.phone;
	if (phone) text(`Tel: ${phone}`);
	text(`Adószám: ${data.companyTaxNumber || company.taxNumber}`);
	blank();
	push(doubleLine(), COMMANDS.LF);
	blank();
	push(COMMANDS.BOLD_ON, COMMANDS.DOUBLE_HEIGHT);
	text(JOB_TYPE_LABELS[data.type] ?? data.type);
	push(COMMANDS.NORMAL_SIZE, COMMANDS.BOLD_OFF);
	blank();
	push(COMMANDS.ALIGN_LEFT);
	text(`Bizonylat: ${data.receiptNumber}`);
	text(`Dátum:     ${data.date}  ${data.time}`);
	text(`Pénztár:   ${data.branchCode}`);
	text(`Pénztáros: ${data.cashierName}`);
	blank();
	push(line(), COMMANDS.LF);
	if (data.type === "sell" || data.type === "buy") {
		const isSell = data.type === "sell";
		blank();
		push(COMMANDS.BOLD_ON);
		text(isSell ? "Deviza eladás (HUF -> valuta):" : "Deviza vásárlás (valuta -> HUF):");
		push(COMMANDS.BOLD_OFF);
		blank();
		text(twoColumn("Valutanem:", data.currencyCode ?? "—"));
		text(twoColumn("Összeg:", `${fmtAmount(data.foreignAmount)} ${data.currencyCode ?? ""}`));
		text(twoColumn("Árfolyam:", fmtRate(data.rate)));
		blank();
		push(line(), COMMANDS.LF);
		push(COMMANDS.BOLD_ON);
		text(twoColumn("HUF összeg:", `${fmtAmount(data.hufAmount)} Ft`));
		if (data.roundedHufAmount !== void 0 && data.roundingDiff !== void 0 && data.roundingDiff !== 0) {
			text(twoColumn("Kerekítés:", `${fmtAmount(data.roundingDiff)} Ft`));
			push(COMMANDS.DOUBLE_HEIGHT);
			text(twoColumn("FIZETENDŐ:", `${fmtAmount(data.roundedHufAmount)} Ft`));
			push(COMMANDS.NORMAL_SIZE);
		} else {
			push(COMMANDS.DOUBLE_HEIGHT);
			text(twoColumn("FIZETENDŐ:", `${fmtAmount(data.roundedHufAmount ?? data.hufAmount)} Ft`));
			push(COMMANDS.NORMAL_SIZE);
		}
		push(COMMANDS.BOLD_OFF);
	} else if (data.type === "conversion") {
		blank();
		push(COMMANDS.BOLD_ON);
		text("Konverzió:");
		push(COMMANDS.BOLD_OFF);
		blank();
		text(twoColumn("Forrás:", `${fmtAmount(data.sourceAmount)} ${data.sourceCurrencyCode ?? "—"}`));
		text(twoColumn("Cél:", `${fmtAmount(data.targetAmount)} ${data.targetCurrencyCode ?? "—"}`));
		text(twoColumn("Köztes HUF:", `${fmtAmount(data.hufAmount)} Ft`));
		text(twoColumn("Árfolyam:", fmtRate(data.rate)));
		if (data.note) text(twoColumn("Megjegyzés:", data.note));
	} else if (data.type === "transfer") {
		blank();
		push(COMMANDS.BOLD_ON);
		text("Átadás-átvétel:");
		push(COMMANDS.BOLD_OFF);
		blank();
		text(twoColumn("Cél pénztár:", data.transferTarget ?? "—"));
		text(twoColumn("Valutanem:", data.currencyCode ?? "—"));
		text(twoColumn("Összeg:", `${fmtAmount(data.foreignAmount)} ${data.currencyCode ?? ""}`));
		if (data.transferNote) text(twoColumn("Megjegyzés:", data.transferNote));
	} else if (data.type === "storno") {
		blank();
		push(COMMANDS.BOLD_ON);
		text("STORNÓ:");
		push(COMMANDS.BOLD_OFF);
		blank();
		text(twoColumn("Eredeti biz.:", data.originalReceiptNumber ?? "—"));
		text(twoColumn("Valutanem:", data.currencyCode ?? "—"));
		text(twoColumn("Összeg:", `${fmtAmount(data.foreignAmount)} ${data.currencyCode ?? ""}`));
		text(twoColumn("HUF összeg:", `${fmtAmount(data.hufAmount)} Ft`));
		if (data.stornoReason) {
			blank();
			text(`Indok: ${data.stornoReason}`);
		}
	} else if (data.type === "closing") buildClosingBlock(data, parts);
	else if (data.type === "handling_fee") {
		blank();
		push(COMMANDS.BOLD_ON);
		text(twoColumn("Kezelési díj:", `${fmtAmount(data.hufAmount)} Ft`));
		push(COMMANDS.BOLD_OFF);
		if (data.sealNumber) text(twoColumn("Plombaszám:", data.sealNumber));
		if (data.originalReceiptNumber) text(twoColumn("Alapbizonylat:", data.originalReceiptNumber));
	} else if (data.type === "cash_status") {
		blank();
		push(COMMANDS.BOLD_ON);
		text("PÉNZTÁR ÁLLÁS");
		push(COMMANDS.BOLD_OFF);
		if (data.hufAmount !== void 0) text(twoColumn("HUF egyenleg:", `${fmtAmount(data.hufAmount)} Ft`));
		if (data.note) text(twoColumn("Megjegyzés:", data.note));
	} else if (data.type === "vault_closing") {
		blank();
		push(COMMANDS.BOLD_ON);
		text("ÉRTÉKTÁRI ZÁRÁS");
		push(COMMANDS.BOLD_OFF);
		if (data.hufAmount !== void 0) text(twoColumn("Összeg:", `${fmtAmount(data.hufAmount)} Ft`));
		if (data.sealNumber) text(twoColumn("Plombaszám:", data.sealNumber));
		if (data.note) text(twoColumn("Megjegyzés:", data.note));
	} else if (data.type === "kktg_transfer") {
		blank();
		push(COMMANDS.BOLD_ON);
		text("KKTG ÁTADÁS-ÁTVÉTEL");
		push(COMMANDS.BOLD_OFF);
		if (data.hufAmount !== void 0) text(twoColumn("Összeg:", `${fmtAmount(data.hufAmount)} Ft`));
		if (data.sealNumber) text(twoColumn("Plombaszám:", data.sealNumber));
		if (data.transferTarget) text(twoColumn("Cél iroda:", data.transferTarget));
		if (data.note) text(twoColumn("Megjegyzés:", data.note));
	}
	if (data.customerName) {
		blank();
		push(line(), COMMANDS.LF);
		push(COMMANDS.BOLD_ON);
		text("ÜGYFÉL ADATOK:");
		push(COMMANDS.BOLD_OFF);
		text(twoColumn("Név:", data.customerName));
		if (data.customerBirthPlace) text(twoColumn("Szül.hely:", data.customerBirthPlace));
		if (data.customerBirthDate) text(twoColumn("Szül.idő:", data.customerBirthDate));
		if (data.customerMotherName) text(twoColumn("Anyja neve:", data.customerMotherName));
		if (data.customerAddress) text(twoColumn("Lakcím:", data.customerAddress));
		if (data.customerDocType) text(twoColumn("Okmány:", data.customerDocType));
		if (data.customerDocNumber) text(twoColumn("Okmányszám:", data.customerDocNumber));
		if (data.customerNationality) text(twoColumn("Államp.:", data.customerNationality));
	}
	blank();
	push(line(), COMMANDS.LF);
	text("Szj 67.13.10.0");
	text("Az ÁFA alól mentes:");
	text("2007. évi CXVII tv. 85. § e)");
	push(line(), COMMANDS.LF);
	blank();
	text("...............    ...............");
	text("  Pénztáros            Ügyfél");
	blank();
	push(doubleLine(), COMMANDS.LF);
	push(COMMANDS.ALIGN_CENTER);
	text("Köszönjük, hogy minket választott!");
	blank();
	text("A bizonylat a pénzmosás elleni");
	text("törvény alapján nem helyettesíti");
	text("a számlát.");
	blank();
	push(COMMANDS.feedLines(4));
	push(COMMANDS.CUT_PARTIAL);
	return Buffer.concat(parts);
}
function buildClosingBlock(data, parts) {
	const push = (...bufs) => {
		for (const b of bufs) parts.push(b);
	};
	const text = (s) => push(toCP852(s), COMMANDS.LF);
	const blank = () => push(COMMANDS.LF);
	const summary = data.closingSummary;
	if (!summary) {
		blank();
		text("(Nincs zárási adat)");
		return;
	}
	blank();
	push(COMMANDS.BOLD_ON);
	text("FORGALMI ÖSSZESÍTŐ:");
	push(COMMANDS.BOLD_OFF);
	blank();
	text(twoColumn("Összes tranzakció:", String(summary.totalTransactions)));
	text(twoColumn("  - Eladás:", String(summary.sellCount)));
	text(twoColumn("  - Vásárlás:", String(summary.buyCount)));
	blank();
	text(twoColumn("HUF forgalom:", `${fmtAmount(summary.totalHufTurnover)} Ft`));
	text(twoColumn("Díjbevétel:", `${fmtAmount(summary.totalFees)} Ft`));
	blank();
	push(line(), COMMANDS.LF);
	text(twoColumn("Nyitó egyenleg:", `${fmtAmount(summary.openingBalance)} Ft`));
	text(twoColumn("Záró egyenleg:", `${fmtAmount(summary.closingBalance)} Ft`));
	if (summary.discrepancies.length > 0) {
		blank();
		push(COMMANDS.BOLD_ON);
		text("ELTÉRÉSEK:");
		push(COMMANDS.BOLD_OFF);
		for (const d of summary.discrepancies) text(`  ${d.currencyCode}: várt ${fmtAmount(d.expected)} -> tény ${fmtAmount(d.actual)} (${fmtAmount(d.difference)})`);
	}
}
/**
* Teljes nyomtatási flow: bizonylat generálás + küldés a soros portra.
*
* @param data - Bizonylat adatai
* @param config - Soros port konfiguráció (port, baud, stb.)
* @returns true ha a nyomtatás sikeres
*/
async function printReceiptToSerial(data, config = {}) {
	const buf = buildReceiptForSerial(data);
	electron_log_main.default.info(`[SERIAL-PRINTER] Bizonylat küldés: ${data.type} ${data.receiptNumber} (${buf.length} byte → ${config.port ?? DEFAULT_CONFIG.port})`);
	return printToSerial(buf, config);
}
//#endregion
exports.listSerialPorts = listSerialPorts;
exports.openCashDrawer = openCashDrawer;
exports.printReceiptToSerial = printReceiptToSerial;
