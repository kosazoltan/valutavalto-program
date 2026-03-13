import { ipcMain } from 'electron';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const SCAN_DIR = 'C:/valuta/scan';
const ENCRYPTION_KEY_FILE = 'C:/valuta/.scan_key';

function sanitizeId(id: string): string {
  const clean = id.replace(/[^a-zA-Z0-9_-]/g, '');
  if (!clean || clean !== id) throw new Error('Invalid transactionId: ' + id);
  return clean;
}

type DocumentType = 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb';

type EncryptionPayload = {
  encrypted: Buffer;
  iv: string;
  tag: string;
};

function getOrCreateKey(): Buffer {
  if (fs.existsSync(ENCRYPTION_KEY_FILE)) {
    const stored = fs.readFileSync(ENCRYPTION_KEY_FILE, 'utf8').trim();
    return Buffer.from(stored, 'base64');
  }

  const key = crypto.randomBytes(32);
  fs.writeFileSync(ENCRYPTION_KEY_FILE, key.toString('base64'), { mode: 0o600 });
  return key;
}

function encrypt(buffer: Buffer): EncryptionPayload {
  const key = getOrCreateKey();
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const encrypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
  const tag = cipher.getAuthTag();
  return { encrypted, iv: iv.toString('hex'), tag: tag.toString('hex') };
}

function decrypt(encrypted: Buffer, iv: string, tag: string): Buffer {
  const key = getOrCreateKey();
  const decipher = crypto.createDecipheriv('aes-256-gcm', key, Buffer.from(iv, 'hex'));
  decipher.setAuthTag(Buffer.from(tag, 'hex'));
  return Buffer.concat([decipher.update(encrypted), decipher.final()]);
}

ipcMain.handle('scan-save-document', async (
  _event,
  transactionId: string,
  documentType: DocumentType,
  imageBase64: string,
): Promise<{ path: string; encrypted: boolean }> => {
  const buffer = Buffer.from(imageBase64, 'base64');
  const { encrypted, iv, tag } = encrypt(buffer);
  const date = new Date().toISOString().slice(0, 10);
  const safeId = sanitizeId(transactionId);
  const dir = path.join(SCAN_DIR, date, safeId);
  fs.mkdirSync(dir, { recursive: true });
  const filename = `${documentType}_${Date.now()}.enc`;
  const filepath = path.join(dir, filename);
  fs.writeFileSync(filepath, encrypted);
  fs.writeFileSync(
    `${filepath}.meta`,
    JSON.stringify({ iv, tag, documentType, timestamp: new Date().toISOString() }),
  );
  return { path: filepath, encrypted: true };
});

ipcMain.handle('scan-get-document', async (
  _event,
  filepath: string,
): Promise<string> => {
  const resolved = path.resolve(filepath);
  if (!resolved.startsWith(path.resolve(SCAN_DIR))) {
    throw new Error('Érvénytelen fájlútvonal');
  }
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
