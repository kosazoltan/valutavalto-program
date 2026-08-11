/**
 * Platform api-url modul — jellemzo-tesztek.
 *
 * MIERT ITT: a `packages/electron-platform`-nak nincs sajat teszt-runnere; a
 * `penztar-client` vitest configja (`electron/__tests__/**`) node-kornyezetben
 * fut, es a modul SZANDEKOSAN pure (nincs `electron` import), ezert kozvetlenul
 * behivhato. A kiemeles utan ez a teszt bizonyitja, hogy a harom kliens
 * korabbi viselkedese megmaradt.
 */

import { describe, it, expect } from 'vitest';
import {
  normalizeApiUrl,
  decideApiUrl,
  parseErrorMessage,
} from '../../../packages/electron-platform/src/api-url';

describe('normalizeApiUrl', () => {
  it('valtozatlanul hagyja a mar /api/v1-re vegzodo URL-t', () => {
    expect(normalizeApiUrl('https://excvaluta.com/api/v1')).toBe('https://excvaluta.com/api/v1');
  });

  it('hozzafuzi az /api/v1 utotagot', () => {
    expect(normalizeApiUrl('https://excvaluta.com')).toBe('https://excvaluta.com/api/v1');
  });

  it('levagja a zaro perjeleket a suffix elott', () => {
    expect(normalizeApiUrl('https://excvaluta.com///')).toBe('https://excvaluta.com/api/v1');
  });

  it('trimmeli a korulvevo whitespace-t', () => {
    expect(normalizeApiUrl('  http://localhost:8080  ')).toBe('http://localhost:8080/api/v1');
  });
});

describe('decideApiUrl', () => {
  it('ures/hianyzo ertekre fallback "empty" okkal', () => {
    for (const value of ['', '   ', null, undefined]) {
      const decision = decideApiUrl(value);
      expect(decision.kind).toBe('fallback');
      if (decision.kind === 'fallback') expect(decision.reason).toBe('empty');
    }
  });

  it('ervenyes https URL-t normalizalva fogad el', () => {
    const decision = decideApiUrl('https://excvaluta.com');
    expect(decision).toEqual({ kind: 'configured', url: 'https://excvaluta.com/api/v1' });
  });

  it('ervenyes http URL-t is elfogad (lokalis fejlesztes)', () => {
    const decision = decideApiUrl('http://localhost:8080/api/v1');
    expect(decision).toEqual({ kind: 'configured', url: 'http://localhost:8080/api/v1' });
  });

  it('BIZTONSAG: nem-http(s) semat elutasit', () => {
    for (const value of ['file:///etc/passwd', 'ftp://example.com', 'javascript:alert(1)']) {
      const decision = decideApiUrl(value);
      expect(decision.kind).toBe('fallback');
      if (decision.kind === 'fallback') {
        expect(decision.reason).toBe('invalid-protocol');
        expect(decision.detail).toBe(value);
      }
    }
  });

  it('szintaktikailag ervenytelen ertekre parse-error', () => {
    const decision = decideApiUrl('nem-egy-url');
    expect(decision.kind).toBe('fallback');
    if (decision.kind === 'fallback') expect(decision.reason).toBe('parse-error');
  });
});

describe('parseErrorMessage', () => {
  it('a JSON `message` mezot adja vissza', () => {
    expect(parseErrorMessage('{"message":"Hibas jelszo"}', 'fallback')).toBe('Hibas jelszo');
  });

  it('`message` hianyaban az `error` mezot hasznalja', () => {
    expect(parseErrorMessage('{"error":"unauthorized"}', 'fallback')).toBe('unauthorized');
  });

  it('nem-JSON torzsre a fallbacket adja', () => {
    expect(parseErrorMessage('<html>502</html>', 'Bejelentkezési hiba')).toBe(
      'Bejelentkezési hiba',
    );
  });

  it('ures JSON objektumra a fallbacket adja', () => {
    expect(parseErrorMessage('{}', 'fallback')).toBe('fallback');
  });
});
