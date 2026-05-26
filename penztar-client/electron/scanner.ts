import { ipcMain } from 'electron';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { assertInsideBase, validateDocumentType, type DocumentType } from './path-guard';

const SCAN_DIR = 'C:/valuta/scan';
const ENCRYPTION_KEY_FILE = 'C:/valuta/.scan_key';

function sanitizeId(id: string): string {
  const clean = id.replace(/[^a-zA-Z0-9_-]/g, '');
  if (!clean || clean !== id) throw new Error('Invalid transactionId: ' + id);
  return clean;
}

type EncryptionPayload = {
  encrypted: Buffer;
  iv: string;
  tag: string;
};

function getOrCreateKey(): Buffer {
  // Audit-iter3 P0 (CodeQL js/file-system-race fix, 2026-04-27):
  // a korabbi `existsSync` -> `readFileSync` / `writeFileSync` minta TOCTOU race
  // volt. Kritikus, mert ha kozben mas process letrehozta a kulcsot, akkor
  // a writeFileSync felulirta volna - kriptografiai katasztrofa!
  // Fix: `wx` flag (O_CREAT | O_EXCL) atomic create-if-not-exists. EEXIST
  // eseten read-eljuk a meglevo kulcsot - race-mentes.
  const newKey = crypto.randomBytes(32);
  try {
    fs.writeFileSync(ENCRYPTION_KEY_FILE, newKey.toString('base64'), { mode: 0o600, flag: 'wx' });
    return newKey;
  } catch (e: unknown) {
    // Audit P2.1 (2026-05-03) + Sourcery PR #356 follow-up: catch (e: any) -> catch (e: unknown)
    // + Node.js-spec type guard (`Error` + `code` property), nem manual `'code' in e` cast.
    // EEXIST -> mas process mar letrehozta a kulcsot ugyanabban a tick-ben (race-mentes
    // O_CREAT|O_EXCL `wx` flag-gel detektalva). Olvassuk vissza a meglevot.
    if (isErrnoException(e) && e.code === 'EEXIST') {
      const stored = fs.readFileSync(ENCRYPTION_KEY_FILE, 'utf8').trim();
      return Buffer.from(stored, 'base64');
    }
    throw e;
  }
}

/** User-defined type guard a Node.js `NodeJS.ErrnoException` szuro szerepere. */
function isErrnoException(e: unknown): e is NodeJS.ErrnoException {
  return e instanceof Error && typeof (e as NodeJS.ErrnoException).code === 'string';
}

function encrypt(buffer: Buffer): EncryptionPayload {
  const key = getOrCreateKey();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv, { authTagLength: 16 });
  const encrypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
  const tag = cipher.getAuthTag();
  return { encrypted, iv: iv.toString('hex'), tag: tag.toString('hex') };
}

function decrypt(encrypted: Buffer, iv: string, tag: string): Buffer {
  const key = getOrCreateKey();
  // Semgrep gcm-no-tag-length: explicit 16 bájtos auth-tag hossz → csonkolt tag elutasítva.
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, Buffer.from(iv, 'hex'), {
    authTagLength: 16,
  });
  decipher.setAuthTag(Buffer.from(tag, 'hex'));
  return Buffer.concat([decipher.update(encrypted), decipher.final()]);
}

export function registerScannerHandlers(): void {
  ipcMain.handle('scan-save-document', async (
    _event,
    transactionId: string,
    documentType: string,
    imageBase64: string,
  ): Promise<{ path: string; encrypted: boolean }> => {
    // Audit P0.9: runtime allowlist a documentType-ra (TS-tipus a runtime-on
    // semmit nem garantal, az IPC bemenet untrusted).
    const safeDocumentType: DocumentType = validateDocumentType(documentType);
    const buffer = Buffer.from(imageBase64, 'base64');
    const { encrypted, iv, tag } = encrypt(buffer);
    const date = new Date().toISOString().slice(0, 10);
    const safeId = sanitizeId(transactionId);
    const dir = path.join(SCAN_DIR, date, safeId);
    fs.mkdirSync(dir, { recursive: true });
    const filename = `${safeDocumentType}_${Date.now()}.enc`;
    const filepath = path.join(dir, filename);
    fs.writeFileSync(filepath, encrypted);
    fs.writeFileSync(
      `${filepath}.meta`,
      JSON.stringify({ iv, tag, documentType: safeDocumentType, timestamp: new Date().toISOString() }),
    );
    return { path: filepath, encrypted: true };
  });

  ipcMain.handle('scan-get-document', async (
    _event,
    filepath: string,
  ): Promise<string> => {
    // Audit P0.9 + Sourcery PR #355 follow-up: az `assertInsideBase` resolveol es
    // visszaadja a normalizalt path-et — DRY, NEM duplikalunk path.resolve-ot.
    const resolved = assertInsideBase(filepath, SCAN_DIR, 'scan filepath');
    const encrypted = fs.readFileSync(resolved);
    const metaRaw = fs.readFileSync(`${resolved}.meta`, 'utf8');
    const meta = JSON.parse(metaRaw) as { iv: string; tag: string };
    const decrypted = decrypt(encrypted, meta.iv, meta.tag);
    return decrypted.toString('base64');
  });

  ipcMain.handle('scan-list-documents', async (
    _event,
    transactionId: string,
  ): Promise<string[]> => {
    if (!fs.existsSync(SCAN_DIR)) return [];
    const results: string[] = [];
    const safeId = sanitizeId(transactionId);
    const dateDirs = fs.readdirSync(SCAN_DIR);
    for (const dateDir of dateDirs) {
      const candidate = path.join(SCAN_DIR, dateDir, safeId);
      if (!fs.existsSync(candidate) || !fs.statSync(candidate).isDirectory()) continue;
      const files = fs.readdirSync(candidate);
      for (const file of files) {
        if (file.endsWith('.enc')) {
          results.push(path.join(candidate, file));
        }
      }
    }
    return results;
  });
}
