/**
 * Audit P0.9 (2026-05-03) regressziovedelem.
 *
 * Bizonyitja, hogy a path/enum guard-ok kivedik:
 *   - sibling-prefix tamadast (pl. `C:\valuta\scan_evil\file.enc`)
 *   - path-traversal payload-okat (`../`, `..\\`, `a/b`, `a\\b`)
 *   - invalid documentType / extension enum bemenetet
 */
import { describe, it, expect } from 'vitest';
import path from 'node:path';
import {
  assertInsideBase,
  sanitizeId,
  validateDocumentType,
  validateRecordingExtension,
  ALLOWED_DOCUMENT_TYPES,
  ALLOWED_RECORDING_EXTENSIONS,
} from '../path-guard';

describe('path-guard — sanitizeId', () => {
  it('returns an allowlisted camera identifier unchanged', () => {
    expect(sanitizeId('cam-01_A')).toBe('cam-01_A');
  });

  it.each(['../../evil', 'a/b', 'a\\b', '', 'a b', '..'])(
    'rejects the unsafe identifier `%s`',
    (id) => {
      expect(() => sanitizeId(id)).toThrow(/Invalid transactionId/);
    },
  );

  it('includes the supplied label in the error message', () => {
    expect(() => sanitizeId('../evil', 'cameraId')).toThrow(/Invalid cameraId/);
  });
});

describe('path-guard — assertInsideBase', () => {
  const SCAN_BASE = process.platform === 'win32' ? 'C:\\valuta\\scan' : '/var/valuta/scan';

  it('atengedi a base-en BELULI fajlt es visszaadja a normalizalt path-et', () => {
    const inside = path.join(SCAN_BASE, '2026-05-03', 'tx-123', 'doc.enc');
    const result = assertInsideBase(inside, SCAN_BASE);
    expect(result).toBe(path.resolve(inside));
  });

  it('atengedi exact base-eseten es visszaadja a base-t', () => {
    const result = assertInsideBase(SCAN_BASE, SCAN_BASE);
    expect(result).toBe(path.resolve(SCAN_BASE));
  });

  it('elutasitja a sibling-prefix tamadast (scan_evil prefix-ben matchelne scan-re)', () => {
    // Ez a kritikus regression: a regi `startsWith(SCAN_BASE)` (kotojel-zaras nelkul)
    // matchelne erre, mert "C:\valuta\scan_evil\..." stringkent kezdodik "C:\valuta\scan"-nal.
    const sibling =
      process.platform === 'win32'
        ? 'C:\\valuta\\scan_evil\\stolen.enc'
        : '/var/valuta/scan_evil/stolen.enc';
    expect(() => assertInsideBase(sibling, SCAN_BASE)).toThrow(/Invalid path/);
  });

  it('elutasitja a teljesen kulso fajlt', () => {
    const outside = process.platform === 'win32' ? 'C:\\Windows\\System32\\config' : '/etc/passwd';
    expect(() => assertInsideBase(outside, SCAN_BASE)).toThrow(/Invalid path/);
  });

  it('elutasitja a path-traversal payload-ot (../)', () => {
    const traversed =
      process.platform === 'win32'
        ? 'C:\\valuta\\scan\\..\\..\\Windows\\System32'
        : '/var/valuta/scan/../../etc/passwd';
    // path.resolve normalizalja a `..` szegmenseket, igy a kapott resolved kivul lesz.
    const resolved = path.resolve(traversed);
    expect(() => assertInsideBase(resolved, SCAN_BASE)).toThrow(/Invalid path/);
  });

  it('label parameter belekerul a hibauzenetbe', () => {
    expect(() => assertInsideBase('/tmp/foo', SCAN_BASE, 'scan filepath')).toThrow(
      /Invalid scan filepath/,
    );
  });
});

describe('path-guard — validateDocumentType', () => {
  it.each(ALLOWED_DOCUMENT_TYPES)('atengedi az allowlist-ed `%s` erteket', (value) => {
    expect(validateDocumentType(value)).toBe(value);
  });

  it('elutasitja az ismeretlen erteket', () => {
    expect(() => validateDocumentType('admin')).toThrow(/Invalid documentType/);
    expect(() => validateDocumentType('SZEMELYI')).toThrow(/Invalid documentType/); // case-sensitive
    expect(() => validateDocumentType('')).toThrow(/Invalid documentType/);
  });

  it('elutasitja a path-traversal payload-ot mint documentType-ot', () => {
    expect(() => validateDocumentType('../etc/passwd')).toThrow(/Invalid documentType/);
    expect(() => validateDocumentType('a/b')).toThrow(/Invalid documentType/);
  });
});

describe('path-guard — validateRecordingExtension', () => {
  it.each(ALLOWED_RECORDING_EXTENSIONS)('atengedi az allowlist-ed `%s` kiterjesztest', (value) => {
    expect(validateRecordingExtension(value)).toBe(value);
  });

  it('elutasitja az ismeretlen kiterjesztest', () => {
    expect(() => validateRecordingExtension('exe')).toThrow(/Invalid extension/);
    expect(() => validateRecordingExtension('mkv')).toThrow(/Invalid extension/);
    expect(() => validateRecordingExtension('')).toThrow(/Invalid extension/);
  });

  it('elutasitja a slash/backslash/pont karaktert', () => {
    expect(() => validateRecordingExtension('mp4/foo')).toThrow(/Invalid extension/);
    expect(() => validateRecordingExtension('mp4\\foo')).toThrow(/Invalid extension/);
    expect(() => validateRecordingExtension('mp4.exe')).toThrow(/Invalid extension/);
    expect(() => validateRecordingExtension('..')).toThrow(/Invalid extension/);
    expect(() => validateRecordingExtension('../mp4')).toThrow(/Invalid extension/);
  });
});
