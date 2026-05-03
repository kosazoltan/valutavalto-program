/**
 * Audit P0.9 (2026-05-03) — kozponti path/enum hardening helper.
 *
 * Magyarazat: a korabbi `resolved.startsWith(path.resolve(BASE))` minta
 * Windows-on sebezheto sibling-prefix attack-ra (`C:\valuta\scan_evil\file`
 * `startsWith('C:\\valuta\\scan')` mert csak prefix matchol). A `+ path.sep`
 * lezaras kell, plusz az exact-equals base-eset is engedelyezett.
 *
 * Ez a modul kozpontilag definialja a path/enum guard-okat, hogy a
 * scanner.ts, camera.ts es minden tovabbi IPC handler ugyanazt a
 * konzisztens validaciot hasznalja.
 */
import path from 'node:path';

/**
 * Biztositja, hogy `value` a `base` konyvtar alatt (vagy egyenlo vele) van.
 * Sibling-prefix tamadasok ellen vedett: `C:\valuta\scan_evil` NEM mehet at,
 * mert `C:\valuta\scan_evil` !== `C:\valuta\scan` ÉS nem startsWith `C:\valuta\scan` + sep.
 *
 * <p>Sourcery PR #355 follow-up: a fuggveny IS resolveolja a value-t, igy a
 * hivok NEM csinaljak duplan (`path.resolve(x)` -> assertInsideBase(resolved, ...)`
 * helyett `assertInsideBase(x, ...)`). A normalizalt path-et VISSZAADJA, igy
 * a hivok ezt hasznaljak `fs.readFileSync`-be vagy szuksege szerint.</p>
 *
 * @returns a normalizalt (resolved) path
 * @throws Error ha a path a base-en kivul esik
 */
export function assertInsideBase(value: string, base: string, label = 'path'): string {
  const baseResolved = path.resolve(base);
  const resolvedNormalized = path.resolve(value);
  if (
    resolvedNormalized !== baseResolved &&
    !resolvedNormalized.startsWith(baseResolved + path.sep)
  ) {
    throw new Error(`Invalid ${label}: outside allowed directory`);
  }
  return resolvedNormalized;
}

/** Scanner dokumentum-tipus runtime allowlist. */
export const ALLOWED_DOCUMENT_TYPES = ['szemelyi', 'utlevel', 'jogositvany', 'egyeb'] as const;
export type DocumentType = (typeof ALLOWED_DOCUMENT_TYPES)[number];

/**
 * @throws Error ha a `value` nem allowlist-ed dokumentum-tipus
 */
export function validateDocumentType(value: string): DocumentType {
  if ((ALLOWED_DOCUMENT_TYPES as readonly string[]).includes(value)) {
    return value as DocumentType;
  }
  throw new Error(`Invalid documentType: ${value}`);
}

/** Felvetel kiterjesztes runtime allowlist. */
export const ALLOWED_RECORDING_EXTENSIONS = ['mp4', 'webm'] as const;
export type RecordingExtension = (typeof ALLOWED_RECORDING_EXTENSIONS)[number];

/**
 * @throws Error ha a `value` nem allowlist-ed kiterjesztes,
 *   vagy ha tartalmaz path-traversal karaktert (slash, backslash, `..`).
 */
export function validateRecordingExtension(value: string): RecordingExtension {
  // Defenzív: a fajlnevbe kerul, igy slash/dot/backslash teljesen tiltott.
  if (/[/\\.]/.test(value) || value.includes('..')) {
    throw new Error(`Invalid extension: ${value}`);
  }
  if ((ALLOWED_RECORDING_EXTENSIONS as readonly string[]).includes(value)) {
    return value as RecordingExtension;
  }
  throw new Error(`Invalid extension: ${value}`);
}
