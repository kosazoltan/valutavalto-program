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

import log from 'electron-log/main';

// --- Soros port típusok (dinamikus import, mert natív modul) ---
interface SerialPortInfo {
  path: string;
  manufacturer?: string;
  serialNumber?: string;
  pnpId?: string;
  locationId?: string;
  friendlyName?: string;
  vendorId?: string;
  productId?: string;
}

interface SerialPrinterConfig {
  port: string;           // pl. 'COM1'
  baudRate: number;       // alapért. 9600
  dataBits: 7 | 8;       // alapért. 8
  parity: 'none' | 'even' | 'odd'; // alapért. 'even' (SP500 gyári)
  stopBits: 1 | 2;       // alapért. 1
  encoding: string;       // alapért. 'cp852' (magyar ékezetek)
}

const DEFAULT_CONFIG: SerialPrinterConfig = {
  port: 'COM1',
  baudRate: 9600,
  dataBits: 8,
  parity: 'even',
  stopBits: 1,
  encoding: 'cp852',
};

// --- ESC/POS parancsok (byte-szintű, Star SP500 kompatibilis) ---
const ESC = 0x1B;
const GS = 0x1D;
const LF = 0x0A;

const COMMANDS = {
  /** Nyomtató inicializálás (reset) */
  INIT: Buffer.from([ESC, 0x40]),             // ESC @

  /** Szöveg igazítás */
  ALIGN_LEFT: Buffer.from([ESC, 0x61, 0x00]),   // ESC a 0
  ALIGN_CENTER: Buffer.from([ESC, 0x61, 0x01]), // ESC a 1
  ALIGN_RIGHT: Buffer.from([ESC, 0x61, 0x02]),  // ESC a 2

  /** Betű stílusok */
  BOLD_ON: Buffer.from([ESC, 0x45, 0x01]),    // ESC E 1
  BOLD_OFF: Buffer.from([ESC, 0x45, 0x00]),   // ESC E 0
  UNDERLINE_ON: Buffer.from([ESC, 0x2D, 0x01]),  // ESC - 1
  UNDERLINE_OFF: Buffer.from([ESC, 0x2D, 0x00]), // ESC - 0

  /** Karakter méret (GS !) */
  NORMAL_SIZE: Buffer.from([GS, 0x21, 0x00]),       // 1x1
  DOUBLE_WIDTH: Buffer.from([GS, 0x21, 0x10]),      // 2x széles
  DOUBLE_HEIGHT: Buffer.from([GS, 0x21, 0x01]),     // 2x magas
  DOUBLE_BOTH: Buffer.from([GS, 0x21, 0x11]),       // 2x2

  /** Papír vágás (ha van cutter — SP500-nál opcionális) */
  CUT_PARTIAL: Buffer.from([GS, 0x56, 0x01]),  // GS V 1
  CUT_FULL: Buffer.from([GS, 0x56, 0x00]),     // GS V 0

  /** Sorok előtolás */
  feedLines: (n: number): Buffer => Buffer.from([ESC, 0x64, n]),  // ESC d n

  /** Pénzfiók nyitás (DK port — pin 2) */
  OPEN_DRAWER: Buffer.from([ESC, 0x70, 0x00, 0x19, 0x78]), // ESC p 0 25 120

  /** Kódlap beállítás: CP852 (közép-európai / magyar) */
  SET_CODEPAGE_852: Buffer.from([ESC, 0x74, 0x12]),  // ESC t 18 (0x12 = CP852 index Star-nál)

  /** Soremelés */
  LF: Buffer.from([LF]),
} as const;

// --- CP852 karakter konverzió (magyar ékezetes betűk) ---
const CP852_MAP: Record<string, number> = {
  'á': 0xA0, 'Á': 0xB5,
  'é': 0x82, 'É': 0x90,
  'í': 0xA1, 'Í': 0xD6,
  'ó': 0xA2, 'Ó': 0xE0,
  'ö': 0x94, 'Ö': 0x99,
  'ő': 0x8B, 'Ő': 0x8A,
  'ú': 0xA3, 'Ú': 0xE9,
  'ü': 0x81, 'Ü': 0x9A,
  'ű': 0xFB, 'Ű': 0xEB,
};

/**
 * UTF-8 string → CP852 kódolású Buffer konverzió.
 * A nem konvertálható karakterek ASCII '?'-re cserélődnek.
 */
function toCP852(text: string): Buffer {
  const bytes: number[] = [];
  for (const ch of text) {
    const code = ch.charCodeAt(0);
    if (CP852_MAP[ch] !== undefined) {
      bytes.push(CP852_MAP[ch]!);
    } else if (code >= 0x20 && code <= 0x7E) {
      // Standard ASCII
      bytes.push(code);
    } else if (code === 0x0A) {
      // LF
      bytes.push(0x0A);
    } else {
      // Nem konvertálható → ?
      bytes.push(0x3F);
    }
  }
  return Buffer.from(bytes);
}

// --- 42 oszlopos formázás ---
const LINE_WIDTH = 42;

function line(ch = '─'): Buffer {
  return toCP852(ch.repeat(LINE_WIDTH));
}

function doubleLine(): Buffer {
  return toCP852('='.repeat(LINE_WIDTH));
}

function twoColumn(left: string, right: string): string {
  const gap = LINE_WIDTH - left.length - right.length;
  if (gap < 1) return (left + ' ' + right).slice(0, LINE_WIDTH);
  return left + ' '.repeat(gap) + right;
}

// ============================================================================
// Elérhető COM portok listázása
// ============================================================================

/**
 * Visszaadja az elérhető soros portok listáját (COM1, COM2, stb.)
 * IPC-ből hívható: a felhasználó kiválaszthatja a port-ot.
 */
export async function listSerialPorts(): Promise<SerialPortInfo[]> {
  try {
    const { SerialPort } = await import('serialport');
    const ports = await SerialPort.list();
    return ports;
  } catch (err) {
    log.error('[SERIAL-PRINTER] Soros portok listázása sikertelen:', err);
    return [];
  }
}

// ============================================================================
// Nyomtatás soros portra
// ============================================================================

/**
 * Adat küldése a soros blokknyomtatóra.
 *
 * @param data - A küldendő byte-ok (ESC/POS parancsok + szöveg)
 * @param config - Soros port konfiguráció
 * @returns true ha a küldés sikeres
 */
export async function printToSerial(
  data: Buffer,
  config: Partial<SerialPrinterConfig> = {},
): Promise<boolean> {
  const cfg: SerialPrinterConfig = { ...DEFAULT_CONFIG, ...config };

  try {
    const { SerialPort } = await import('serialport');

    const port = new SerialPort({
      path: cfg.port,
      baudRate: cfg.baudRate,
      dataBits: cfg.dataBits,
      parity: cfg.parity,
      stopBits: cfg.stopBits,
      autoOpen: false,
    });

    return new Promise<boolean>((resolve) => {
      port.open((openErr: Error | null | undefined) => {
        if (openErr) {
          log.error(`[SERIAL-PRINTER] Port nyitás sikertelen (${cfg.port}):`, openErr.message);
          resolve(false);
          return;
        }

        port.write(data, (writeErr: Error | null | undefined) => {
          if (writeErr) {
            log.error(`[SERIAL-PRINTER] Írás sikertelen (${cfg.port}):`, writeErr.message);
            port.close();
            resolve(false);
            return;
          }

          port.drain((drainErr: Error | null | undefined) => {
            if (drainErr) {
              log.warn(`[SERIAL-PRINTER] Drain figyelmeztetés (${cfg.port}):`, drainErr.message);
            }
            port.close((closeErr: Error | null | undefined) => {
              if (closeErr) {
                log.warn(`[SERIAL-PRINTER] Port zárás figyelmeztetés:`, closeErr.message);
              }
              log.info(`[SERIAL-PRINTER] Nyomtatás sikeres (${cfg.port})`);
              resolve(true);
            });
          });
        });
      });
    });
  } catch (err) {
    log.error('[SERIAL-PRINTER] Kritikus hiba:', err);
    return false;
  }
}

/**
 * Pénzfiók nyitása a soros porton keresztül.
 * A Star SP500 DK portján lévő fióknak küld impulzust.
 */
export async function openCashDrawer(
  config: Partial<SerialPrinterConfig> = {},
): Promise<boolean> {
  const data = Buffer.concat([
    COMMANDS.INIT,
    COMMANDS.OPEN_DRAWER,
  ]);
  return printToSerial(data, config);
}

// ============================================================================
// Bizonylat nyomtatás (Star SP500 ESC/POS)
// ============================================================================

// Import típus a printer.ts-ből
import type { PrintReceiptData } from './printer';

const JOB_TYPE_LABELS: Record<string, string> = {
  sell: 'ELADÁSI BIZONYLAT',
  buy: 'VÁSÁRLÁSI BIZONYLAT',
  transfer: 'ÁTADÁS-ÁTVÉTELI BIZONYLAT',
  storno: 'STORNÓ BIZONYLAT',
  conversion: 'KONVERZIÓS BIZONYLAT',
  closing: 'NAPI ZÁRÁS',
  handling_fee: 'KEZELÉSI DÍJ BIZONYLAT',
  cash_status: 'PÉNZTÁR ÁLLÁS',
  vault_closing: 'ÉRTÉKTÁRI ZÁRÁS',
  kktg_transfer: 'KKTG ÁTADÁS-ÁTVÉTEL',
};

const COMPANIES: Record<string, { name: string; fullName: string; taxNumber: string; address: string; phone: string }> = {
  BEST_CHANGE: {
    name: 'BEST CHANGE',
    fullName: 'EXCLUSIVE BEST CHANGE ZRT.',
    taxNumber: '32313332-2-02',
    address: 'Szeged, Kárász u. 5.',
    phone: '06703800161',
  },
  EXPRESSZ: {
    name: 'EXPRESSZ',
    fullName: 'EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT.',
    taxNumber: '14040535-2-02',
    address: 'Szeged, Klauzál tér 3.',
    phone: '',
  },
};

function fmtAmount(value: number | undefined): string {
  if (value === undefined) return '—';
  return value.toLocaleString('hu-HU', { maximumFractionDigits: 2 });
}

function fmtRate(value: number | undefined): string {
  if (value === undefined) return '—';
  return value.toLocaleString('hu-HU', { minimumFractionDigits: 2, maximumFractionDigits: 4 });
}

/**
 * Teljes bizonylat ESC/POS adat generálása a Star SP500-nak.
 * Buffer-t ad vissza, amit közvetlenül a soros portra kell küldeni.
 */
export function buildReceiptForSerial(data: PrintReceiptData): Buffer {
  const company = COMPANIES[data.companyType] ?? COMPANIES['BEST_CHANGE']!;
  const parts: Buffer[] = [];

  const push = (...bufs: Buffer[]) => { for (const b of bufs) parts.push(b); };
  const text = (s: string) => push(toCP852(s), COMMANDS.LF);
  const blank = () => push(COMMANDS.LF);

  // Init + kódlap
  push(COMMANDS.INIT, COMMANDS.SET_CODEPAGE_852);

  // --- Fejléc ---
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

  // --- Bizonylat típus ---
  push(COMMANDS.BOLD_ON, COMMANDS.DOUBLE_HEIGHT);
  text(JOB_TYPE_LABELS[data.type] ?? data.type);
  push(COMMANDS.NORMAL_SIZE, COMMANDS.BOLD_OFF);
  blank();

  // --- Meta ---
  push(COMMANDS.ALIGN_LEFT);
  text(`Bizonylat: ${data.receiptNumber}`);
  text(`Dátum:     ${data.date}  ${data.time}`);
  // Átadási bizonylaton a kérő iroda a törzsben „Kérő iroda" néven szerepel (nem „Pénztár"),
  // a felelős neve „Ügyintéző" — a bizonylat-előnézettel egyezően.
  if (data.type !== 'transfer') {
    text(`Pénztár:   ${data.branchCode}`);
  }
  text(`${data.type === 'transfer' ? 'Ügyintéző:' : 'Pénztáros:'} ${data.cashierName}`);
  blank();
  push(line(), COMMANDS.LF);

  // --- Típus-specifikus blokk ---
  if (data.type === 'sell' || data.type === 'buy') {
    const isSell = data.type === 'sell';
    blank();
    push(COMMANDS.BOLD_ON);
    text(isSell ? 'Deviza eladás (HUF -> valuta):' : 'Deviza vásárlás (valuta -> HUF):');
    push(COMMANDS.BOLD_OFF);
    blank();
    text(twoColumn('Valutanem:', data.currencyCode ?? '—'));
    text(twoColumn('Összeg:', `${fmtAmount(data.foreignAmount)} ${data.currencyCode ?? ''}`));
    text(twoColumn('Árfolyam:', fmtRate(data.rate)));
    blank();
    push(line(), COMMANDS.LF);
    push(COMMANDS.BOLD_ON);
    text(twoColumn('HUF összeg:', `${fmtAmount(data.hufAmount)} Ft`));
    if (data.roundedHufAmount !== undefined && data.roundingDiff !== undefined && data.roundingDiff !== 0) {
      text(twoColumn('Kerekítés:', `${fmtAmount(data.roundingDiff)} Ft`));
      push(COMMANDS.DOUBLE_HEIGHT);
      text(twoColumn('FIZETENDŐ:', `${fmtAmount(data.roundedHufAmount)} Ft`));
      push(COMMANDS.NORMAL_SIZE);
    } else {
      push(COMMANDS.DOUBLE_HEIGHT);
      text(twoColumn('FIZETENDŐ:', `${fmtAmount(data.roundedHufAmount ?? data.hufAmount)} Ft`));
      push(COMMANDS.NORMAL_SIZE);
    }
    push(COMMANDS.BOLD_OFF);
  } else if (data.type === 'conversion') {
    blank();
    push(COMMANDS.BOLD_ON); text('Konverzió:'); push(COMMANDS.BOLD_OFF);
    blank();
    text(twoColumn('Forrás:', `${fmtAmount(data.sourceAmount)} ${data.sourceCurrencyCode ?? '—'}`));
    text(twoColumn('Cél:', `${fmtAmount(data.targetAmount)} ${data.targetCurrencyCode ?? '—'}`));
    text(twoColumn('Köztes HUF:', `${fmtAmount(data.hufAmount)} Ft`));
    text(twoColumn('Árfolyam:', fmtRate(data.rate)));
    if (data.note) text(twoColumn('Megjegyzés:', data.note));
  } else if (data.type === 'transfer') {
    blank();
    push(COMMANDS.BOLD_ON); text('Átadás-átvétel:'); push(COMMANDS.BOLD_OFF);
    blank();
    // FR-2: kérő iroda + cél iroda (kötelező → mindig, „—" fallback) + valuta/összeg + forintosított érték.
    text(twoColumn('Kérő iroda:', data.branchCode || '—'));
    text(twoColumn('Cél iroda:', data.transferTarget ?? '—'));
    text(twoColumn('Valutanem:', data.currencyCode ?? '—'));
    text(twoColumn('Összeg:', `${fmtAmount(data.foreignAmount)} ${data.currencyCode ?? ''}`));
    // NFR-3: 5 Ft-ra kerekített forintosított érték.
    if (data.roundedHufAmount !== undefined || data.hufAmount !== undefined) {
      text(twoColumn('Forint érték:', `${fmtAmount(data.roundedHufAmount ?? data.hufAmount)} HUF`));
    }
    // FR-5: szállító + plombaszám a soros-nyomtató úton is.
    if (data.carrierName) text(twoColumn('Szállító:', data.carrierName));
    if (data.sealNumber) text(twoColumn('Plombaszám:', data.sealNumber));
    // FR-2: kért kézbesítési dátum.
    if (data.deliveryDate) text(twoColumn('Kézbesítési dátum:', data.deliveryDate));
    if (data.transferNote) text(twoColumn('Megjegyzés:', data.transferNote));
  } else if (data.type === 'storno') {
    blank();
    push(COMMANDS.BOLD_ON); text('STORNÓ:'); push(COMMANDS.BOLD_OFF);
    blank();
    text(twoColumn('Eredeti biz.:', data.originalReceiptNumber ?? '—'));
    text(twoColumn('Valutanem:', data.currencyCode ?? '—'));
    text(twoColumn('Összeg:', `${fmtAmount(data.foreignAmount)} ${data.currencyCode ?? ''}`));
    text(twoColumn('HUF összeg:', `${fmtAmount(data.hufAmount)} Ft`));
    if (data.stornoReason) { blank(); text(`Indok: ${data.stornoReason}`); }
  } else if (data.type === 'closing') {
    buildClosingBlock(data, parts);
  } else if (data.type === 'handling_fee') {
    blank();
    push(COMMANDS.BOLD_ON);
    text(twoColumn('Kezelési díj:', `${fmtAmount(data.hufAmount)} Ft`));
    push(COMMANDS.BOLD_OFF);
    if (data.sealNumber) text(twoColumn('Plombaszám:', data.sealNumber));
    if (data.originalReceiptNumber) text(twoColumn('Alapbizonylat:', data.originalReceiptNumber));
  } else if (data.type === 'cash_status') {
    blank();
    push(COMMANDS.BOLD_ON); text('PÉNZTÁR ÁLLÁS'); push(COMMANDS.BOLD_OFF);
    if (data.hufAmount !== undefined) text(twoColumn('HUF egyenleg:', `${fmtAmount(data.hufAmount)} Ft`));
    if (data.note) text(twoColumn('Megjegyzés:', data.note));
  } else if (data.type === 'vault_closing') {
    blank();
    push(COMMANDS.BOLD_ON); text('ÉRTÉKTÁRI ZÁRÁS'); push(COMMANDS.BOLD_OFF);
    if (data.hufAmount !== undefined) text(twoColumn('Összeg:', `${fmtAmount(data.hufAmount)} Ft`));
    if (data.sealNumber) text(twoColumn('Plombaszám:', data.sealNumber));
    if (data.note) text(twoColumn('Megjegyzés:', data.note));
  } else if (data.type === 'kktg_transfer') {
    blank();
    push(COMMANDS.BOLD_ON); text('KKTG ÁTADÁS-ÁTVÉTEL'); push(COMMANDS.BOLD_OFF);
    if (data.hufAmount !== undefined) text(twoColumn('Összeg:', `${fmtAmount(data.hufAmount)} Ft`));
    if (data.sealNumber) text(twoColumn('Plombaszám:', data.sealNumber));
    if (data.transferTarget) text(twoColumn('Cél iroda:', data.transferTarget));
    if (data.note) text(twoColumn('Megjegyzés:', data.note));
  }

  // --- Ügyfél adatok ---
  if (data.customerName) {
    blank();
    push(line(), COMMANDS.LF);
    push(COMMANDS.BOLD_ON); text('ÜGYFÉL ADATOK:'); push(COMMANDS.BOLD_OFF);
    text(twoColumn('Név:', data.customerName));
    if (data.customerBirthPlace) text(twoColumn('Szül.hely:', data.customerBirthPlace));
    if (data.customerBirthDate) text(twoColumn('Szül.idő:', data.customerBirthDate));
    if (data.customerMotherName) text(twoColumn('Anyja neve:', data.customerMotherName));
    if (data.customerAddress) text(twoColumn('Lakcím:', data.customerAddress));
    if (data.customerDocType) text(twoColumn('Okmány:', data.customerDocType));
    if (data.customerDocNumber) text(twoColumn('Okmányszám:', data.customerDocNumber));
    if (data.customerNationality) text(twoColumn('Államp.:', data.customerNationality));
  }

  // --- ÁFA-mentesség ---
  blank();
  push(line(), COMMANDS.LF);
  text('Szj 67.13.10.0');
  text('Az ÁFA alól mentes:');
  text('2007. évi CXVII tv. 85. § e)');
  push(line(), COMMANDS.LF);

  // --- Aláírás sorok ---
  blank();
  text('...............    ...............');
  text(data.type === 'transfer'
    ? '  Átadó                Átvevő'
    : '  Pénztáros            Ügyfél');

  // --- Lábléc ---
  blank();
  push(doubleLine(), COMMANDS.LF);
  push(COMMANDS.ALIGN_CENTER);
  text('Köszönjük, hogy minket választott!');
  blank();
  text('A bizonylat a pénzmosás elleni');
  text('törvény alapján nem helyettesíti');
  text('a számlát.');
  blank();

  // Papír előtolás + vágás (ha van cutter)
  push(COMMANDS.feedLines(4));
  push(COMMANDS.CUT_PARTIAL);

  return Buffer.concat(parts);
}

function buildClosingBlock(data: PrintReceiptData, parts: Buffer[]): void {
  const push = (...bufs: Buffer[]) => { for (const b of bufs) parts.push(b); };
  const text = (s: string) => push(toCP852(s), COMMANDS.LF);
  const blank = () => push(COMMANDS.LF);

  const summary = data.closingSummary;
  if (!summary) {
    blank();
    text('(Nincs zárási adat)');
    return;
  }

  blank();
  push(COMMANDS.BOLD_ON); text('FORGALMI ÖSSZESÍTŐ:'); push(COMMANDS.BOLD_OFF);
  blank();
  text(twoColumn('Összes tranzakció:', String(summary.totalTransactions)));
  text(twoColumn('  - Eladás:', String(summary.sellCount)));
  text(twoColumn('  - Vásárlás:', String(summary.buyCount)));
  blank();
  text(twoColumn('HUF forgalom:', `${fmtAmount(summary.totalHufTurnover)} Ft`));
  text(twoColumn('Díjbevétel:', `${fmtAmount(summary.totalFees)} Ft`));
  blank();
  push(line(), COMMANDS.LF);
  text(twoColumn('Nyitó egyenleg:', `${fmtAmount(summary.openingBalance)} Ft`));
  text(twoColumn('Záró egyenleg:', `${fmtAmount(summary.closingBalance)} Ft`));

  if (summary.discrepancies.length > 0) {
    blank();
    push(COMMANDS.BOLD_ON); text('ELTÉRÉSEK:'); push(COMMANDS.BOLD_OFF);
    for (const d of summary.discrepancies) {
      text(`  ${d.currencyCode}: várt ${fmtAmount(d.expected)} -> tény ${fmtAmount(d.actual)} (${fmtAmount(d.difference)})`);
    }
  }
}

/**
 * Teljes nyomtatási flow: bizonylat generálás + küldés a soros portra.
 *
 * @param data - Bizonylat adatai
 * @param config - Soros port konfiguráció (port, baud, stb.)
 * @returns true ha a nyomtatás sikeres
 */
export async function printReceiptToSerial(
  data: PrintReceiptData,
  config: Partial<SerialPrinterConfig> = {},
): Promise<boolean> {
  const buf = buildReceiptForSerial(data);
  log.info(`[SERIAL-PRINTER] Bizonylat küldés: ${data.type} ${data.receiptNumber} (${buf.length} byte → ${config.port ?? DEFAULT_CONFIG.port})`);
  return printToSerial(buf, config);
}
