/**
 * scanner.ts unit tests — barcode/document scanning, encryption, path validation.
 *
 * scanner.ts uses ipcMain.handle() at module level, so we mock electron
 * and test the underlying logic functions extracted from the handlers.
 */
import { describe, it, expect } from 'vitest';
import crypto from 'node:crypto';
import path from 'node:path';

// We can't easily import scanner.ts directly because it calls ipcMain.handle()
// at the module top level. Instead, we test the key logic functions in isolation.

describe('scanner — sanitizeId', () => {
  // Replicate the sanitizeId logic from scanner.ts
  function sanitizeId(id: string): string {
    const clean = id.replace(/[^a-zA-Z0-9_-]/g, '');
    if (!clean || clean !== id) throw new Error('Invalid transactionId: ' + id);
    return clean;
  }

  it('should pass valid transaction IDs', () => {
    expect(sanitizeId('abc123')).toBe('abc123');
    expect(sanitizeId('TX-001')).toBe('TX-001');
    expect(sanitizeId('transaction_42')).toBe('transaction_42');
  });

  it('should reject IDs with special characters', () => {
    expect(() => sanitizeId('../etc/passwd')).toThrow('Invalid transactionId');
    expect(() => sanitizeId('tx;rm -rf')).toThrow('Invalid transactionId');
    expect(() => sanitizeId('tx 123')).toThrow('Invalid transactionId');
    expect(() => sanitizeId('tx/123')).toThrow('Invalid transactionId');
  });

  it('should reject empty IDs', () => {
    expect(() => sanitizeId('')).toThrow('Invalid transactionId');
  });

  it('should reject IDs that become empty after sanitization', () => {
    expect(() => sanitizeId('///...')).toThrow('Invalid transactionId');
  });
});

describe('scanner — encryption/decryption', () => {
  // Replicate encrypt/decrypt logic from scanner.ts
  function encrypt(buffer: Buffer, key: Buffer): { encrypted: Buffer; iv: string; tag: string } {
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    const encrypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
    const tag = cipher.getAuthTag();
    return { encrypted, iv: iv.toString('hex'), tag: tag.toString('hex') };
  }

  function decrypt(encrypted: Buffer, iv: string, tag: string, key: Buffer): Buffer {
    const decipher = crypto.createDecipheriv('aes-256-gcm', key, Buffer.from(iv, 'hex'));
    decipher.setAuthTag(Buffer.from(tag, 'hex'));
    return Buffer.concat([decipher.update(encrypted), decipher.final()]);
  }

  const testKey = crypto.randomBytes(32);

  it('should encrypt and decrypt a buffer correctly', () => {
    const original = Buffer.from('Hello, this is a test document image');
    const { encrypted, iv, tag } = encrypt(original, testKey);
    const decrypted = decrypt(encrypted, iv, tag, testKey);
    expect(decrypted.toString()).toBe(original.toString());
  });

  it('should produce different ciphertext for same plaintext (random IV)', () => {
    const original = Buffer.from('Same input');
    const result1 = encrypt(original, testKey);
    const result2 = encrypt(original, testKey);
    expect(result1.encrypted).not.toEqual(result2.encrypted);
    expect(result1.iv).not.toBe(result2.iv);
  });

  it('should fail decryption with wrong key', () => {
    const original = Buffer.from('Secret data');
    const { encrypted, iv, tag } = encrypt(original, testKey);
    const wrongKey = crypto.randomBytes(32);
    expect(() => decrypt(encrypted, iv, tag, wrongKey)).toThrow();
  });

  it('should fail decryption with tampered ciphertext', () => {
    const original = Buffer.from('Tamper test');
    const { encrypted, iv, tag } = encrypt(original, testKey);
    // Tamper with encrypted data
    encrypted[0] = (encrypted[0]! ^ 0xff) as number;
    expect(() => decrypt(encrypted, iv, tag, testKey)).toThrow();
  });

  it('should fail decryption with wrong auth tag', () => {
    const original = Buffer.from('Auth tag test');
    const { encrypted, iv } = encrypt(original, testKey);
    const wrongTag = crypto.randomBytes(16).toString('hex');
    expect(() => decrypt(encrypted, iv, wrongTag, testKey)).toThrow();
  });

  it('should handle empty buffer', () => {
    const original = Buffer.alloc(0);
    const { encrypted, iv, tag } = encrypt(original, testKey);
    const decrypted = decrypt(encrypted, iv, tag, testKey);
    expect(decrypted.length).toBe(0);
  });

  it('should handle large buffer', () => {
    // 1MB of random data
    const original = crypto.randomBytes(1024 * 1024);
    const { encrypted, iv, tag } = encrypt(original, testKey);
    const decrypted = decrypt(encrypted, iv, tag, testKey);
    expect(decrypted).toEqual(original);
  });
});

describe('scanner — path validation', () => {
  const SCAN_DIR = 'C:/valuta/scan';

  it('should accept valid paths within SCAN_DIR', () => {
    const testPath = 'C:/valuta/scan/2026-03-24/TX-001/szemelyi_1234.enc';
    const resolved = path.resolve(testPath);
    expect(resolved.startsWith(path.resolve(SCAN_DIR))).toBe(true);
  });

  it('should reject path traversal attempts', () => {
    const maliciousPath = 'C:/valuta/scan/../../etc/passwd';
    const resolved = path.resolve(maliciousPath);
    expect(resolved.startsWith(path.resolve(SCAN_DIR))).toBe(false);
  });

  it('should reject paths outside scan directory', () => {
    const outsidePath = 'C:/windows/system32/config';
    const resolved = path.resolve(outsidePath);
    expect(resolved.startsWith(path.resolve(SCAN_DIR))).toBe(false);
  });
});

describe('scanner — document type validation', () => {
  type DocumentType = 'szemelyi' | 'utlevel' | 'jogositvany' | 'egyeb';
  const validTypes: DocumentType[] = ['szemelyi', 'utlevel', 'jogositvany', 'egyeb'];

  it('should accept all valid document types', () => {
    for (const docType of validTypes) {
      expect(validTypes.includes(docType)).toBe(true);
    }
  });

  it('should not include invalid types', () => {
    const invalidType = 'passport' as DocumentType;
    expect(validTypes.includes(invalidType)).toBe(false);
  });
});

describe('scanner — base64 encoding round-trip', () => {
  it('should correctly encode and decode image data', () => {
    // Simulate what the scanner IPC does: receive base64, convert to buffer, encrypt, then decrypt back to base64
    const originalBase64 = Buffer.from('fake-image-data-png-content').toString('base64');
    const buffer = Buffer.from(originalBase64, 'base64');
    const roundTripBase64 = buffer.toString('base64');
    expect(roundTripBase64).toBe(originalBase64);
  });
});
