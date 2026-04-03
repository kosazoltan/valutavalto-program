/**
 * CameraEncryption — AES-256-GCM titkosítás az Electron kamera rétegben.
 *
 * A backend CameraEncryptionService tükörképe: ugyanaz a fájlformátum,
 * kompatibilis a szerveroldali visszafejtéssel.
 *
 * Fájlformátum: [12 byte nonce][titkosított adat + GCM auth tag]
 */

import crypto from 'node:crypto';
import fs from 'node:fs';


const ALGORITHM = 'aes-256-gcm';
const NONCE_LENGTH = 12;
const AUTH_TAG_LENGTH = 16; // 128 bit

export interface EncryptionConfig {
  enabled: boolean;
  masterKeyBase64: string;
}

/**
 * Érvényesíti és visszaadja a master kulcsot Buffer formában.
 */
function getKeyBuffer(config: EncryptionConfig): Buffer {
  if (!config.masterKeyBase64) {
    throw new Error('Camera encryption master key nincs konfigurálva!');
  }
  const keyBuf = Buffer.from(config.masterKeyBase64, 'base64');
  if (keyBuf.length !== 32) {
    throw new Error(`Camera encryption key mérete nem 256 bit (32 byte)! Jelenlegi: ${keyBuf.length} byte`);
  }
  return keyBuf;
}

/**
 * Fájl titkosítása AES-256-GCM-mel.
 * @returns A nonce Base64 kódolva (audit loghoz)
 */
export async function encryptFile(
  plainPath: string,
  encryptedPath: string,
  config: EncryptionConfig,
): Promise<string> {
  if (!config.enabled) {
    fs.copyFileSync(plainPath, encryptedPath);
    return 'UNENCRYPTED';
  }

  const key = getKeyBuffer(config);
  const nonce = crypto.randomBytes(NONCE_LENGTH);

  const plainData = fs.readFileSync(plainPath);
  const cipher = crypto.createCipheriv(ALGORITHM, key, nonce, { authTagLength: AUTH_TAG_LENGTH });
  const encrypted = Buffer.concat([cipher.update(plainData), cipher.final()]);
  const authTag = cipher.getAuthTag();

  // Fájlformátum: [nonce][encrypted + authTag]
  const fd = fs.openSync(encryptedPath, 'w');
  try {
    fs.writeSync(fd, nonce);
    fs.writeSync(fd, encrypted);
    fs.writeSync(fd, authTag);
  } finally {
    fs.closeSync(fd);
  }

  return nonce.toString('base64');
}

/**
 * Titkosított fájl visszafejtése.
 */
export async function decryptFile(
  encryptedPath: string,
  plainPath: string,
  config: EncryptionConfig,
): Promise<void> {
  if (!config.enabled) {
    fs.copyFileSync(encryptedPath, plainPath);
    return;
  }

  const key = getKeyBuffer(config);
  const fileData = fs.readFileSync(encryptedPath);

  if (fileData.length < NONCE_LENGTH + AUTH_TAG_LENGTH) {
    throw new Error(`Titkosított fájl túl rövid: ${encryptedPath}`);
  }

  const nonce = fileData.subarray(0, NONCE_LENGTH);
  const authTag = fileData.subarray(fileData.length - AUTH_TAG_LENGTH);
  const encrypted = fileData.subarray(NONCE_LENGTH, fileData.length - AUTH_TAG_LENGTH);

  const decipher = crypto.createDecipheriv(ALGORITHM, key, nonce, { authTagLength: AUTH_TAG_LENGTH });
  decipher.setAuthTag(authTag);
  const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);
  fs.writeFileSync(plainPath, decrypted);
}

/**
 * Byte tömb titkosítása (metaadat, kisebb adatok).
 * @returns [nonce + encrypted + authTag]
 */
export function encryptBytes(data: Buffer, config: EncryptionConfig): Buffer {
  if (!config.enabled) return data;

  const key = getKeyBuffer(config);
  const nonce = crypto.randomBytes(NONCE_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, nonce, { authTagLength: AUTH_TAG_LENGTH });
  const encrypted = Buffer.concat([cipher.update(data), cipher.final()]);
  const authTag = cipher.getAuthTag();

  return Buffer.concat([nonce, encrypted, authTag]);
}

/**
 * Fájl SHA-256 hash számítása (integritás ellenőrzéshez).
 */
export function computeFileHash(filePath: string): string {
  const hash = crypto.createHash('sha256');
  const data = fs.readFileSync(filePath);
  hash.update(data);
  return hash.digest('hex');
}

/**
 * Streaming SHA-256 hash nagy fájlokhoz.
 */
export async function computeFileHashStreaming(filePath: string): Promise<string> {
  const hash = crypto.createHash('sha256');
  const stream = fs.createReadStream(filePath);
  for await (const chunk of stream) {
    hash.update(chunk);
  }
  return hash.digest('hex');
}

/**
 * Új AES-256 kulcs generálása.
 */
export function generateNewKey(): string {
  const key = crypto.randomBytes(32);
  return key.toString('base64');
}
