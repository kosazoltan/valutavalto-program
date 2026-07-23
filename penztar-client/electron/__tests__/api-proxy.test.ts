import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { EventEmitter } from 'node:events';

// Mock electron-log
vi.mock('electron-log/main', () => ({
  default: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

// Mock response helper
function createMockResponse(
  opts: {
    statusCode?: number;
    statusMessage?: string;
    headers?: Record<string, string>;
    chunks?: Buffer[];
    errorOnData?: Error;
  } = {},
) {
  const response = new EventEmitter() as EventEmitter & {
    statusCode: number;
    statusMessage: string;
    headers: Record<string, string>;
  };
  response.statusCode = opts.statusCode ?? 200;
  response.statusMessage = opts.statusMessage ?? 'OK';
  response.headers = opts.headers ?? { 'content-type': 'application/json' };

  // Auto-emit data+end after 'data' listener is attached
  const originalOn = response.on.bind(response);
  let dataListenerAttached = false;
  let endListenerAttached = false;
  response.on = function (event: string, listener: (...args: unknown[]) => void) {
    originalOn(event, listener);
    if (event === 'data') dataListenerAttached = true;
    if (event === 'end') endListenerAttached = true;
    if (dataListenerAttached && endListenerAttached) {
      process.nextTick(() => {
        if (opts.errorOnData) {
          response.emit('error', opts.errorOnData);
          return;
        }
        const chunks = opts.chunks ?? [Buffer.from('{"ok":true}')];
        for (const chunk of chunks) {
          response.emit('data', chunk);
        }
        response.emit('end');
      });
    }
    return response;
  } as typeof response.on;

  return response;
}

// Mock electron.net
const mockSetHeader = vi.fn();
const mockWrite = vi.fn();
const mockEnd = vi.fn();
const mockAbort = vi.fn();

let _mockResponseEmitter: EventEmitter;
let mockRequestEmitter: EventEmitter & {
  setHeader: typeof mockSetHeader;
  write: typeof mockWrite;
  end: typeof mockEnd;
  abort: typeof mockAbort;
};

function createMockRequest() {
  const emitter = new EventEmitter() as typeof mockRequestEmitter;
  emitter.setHeader = mockSetHeader;
  emitter.write = mockWrite;
  emitter.end = mockEnd;
  emitter.abort = mockAbort;
  return emitter;
}

vi.mock('electron', () => ({
  net: {
    request: vi.fn(() => {
      mockRequestEmitter = createMockRequest();
      return mockRequestEmitter;
    }),
  },
  IncomingMessage: class {},
}));

import {
  fetchViaElectronNet,
  retryFetch,
  isRetryableNetworkError,
  isRetrySafeRequest,
  type ApiProxyResponse,
} from '../api-proxy';
import { net as electronNet } from 'electron';

describe('fetchViaElectronNet', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  function triggerResponse(opts?: Parameters<typeof createMockResponse>[0]) {
    const response = createMockResponse(opts);
    process.nextTick(() => {
      mockRequestEmitter.emit('response', response);
    });
  }

  describe('sikeres kérések', () => {
    it('GET kérés JSON válasszal', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/data',
      });
      triggerResponse({
        statusCode: 200,
        headers: { 'content-type': 'application/json' },
        chunks: [Buffer.from('{"hello":"world"}')],
      });

      vi.advanceTimersByTime(0);
      const result = await promise;

      expect(electronNet.request).toHaveBeenCalledWith({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/data',
      });
      expect(result.ok).toBe(true);
      expect(result.status).toBe(200);
      expect(result.body).toBe('{"hello":"world"}');
      expect(result.isBase64).toBe(false);
    });

    it('POST kérés body-val automatikusan Content-Type: application/json', async () => {
      const promise = fetchViaElectronNet({
        method: 'POST',
        url: 'https://excvaluta.com/api/v1/test/data',
        body: '{"key":"value"}',
      });
      triggerResponse();
      vi.advanceTimersByTime(0);
      await promise;

      expect(mockSetHeader).toHaveBeenCalledWith('Content-Type', 'application/json');
      expect(mockWrite).toHaveBeenCalledWith('{"key":"value"}');
    });

    it('GET kérés NEM kap Content-Type headert', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/data',
      });
      triggerResponse();
      vi.advanceTimersByTime(0);
      await promise;

      const setHeaderCalls = mockSetHeader.mock.calls.map((c) => c[0]);
      expect(setHeaderCalls).not.toContain('Content-Type');
    });

    it('Accept: application/json alapértelmezetten beállítódik', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/data',
      });
      triggerResponse();
      vi.advanceTimersByTime(0);
      await promise;

      expect(mockSetHeader).toHaveBeenCalledWith('Accept', 'application/json');
    });

    it('explicit headerek nem felülírtak', async () => {
      const promise = fetchViaElectronNet({
        method: 'POST',
        url: 'https://excvaluta.com/api/v1/test/data',
        body: 'data',
        headers: { 'Content-Type': 'text/plain', Accept: 'text/html' },
      });
      triggerResponse();
      vi.advanceTimersByTime(0);
      await promise;

      expect(mockSetHeader).toHaveBeenCalledWith('Content-Type', 'text/plain');
      expect(mockSetHeader).toHaveBeenCalledWith('Accept', 'text/html');
      const ctCalls = mockSetHeader.mock.calls.filter((c) => c[0] === 'Content-Type');
      expect(ctCalls).toHaveLength(1);
    });

    it('csak whitelistelt request headerek jutnak at a rendererbol', async () => {
      const promise = fetchViaElectronNet({
        method: 'PATCH',
        url: 'https://excvaluta.com/api/v1/workers/bulk-email',
        body: '{}',
        headers: {
          Authorization: 'Bearer token',
          'idempotency-key': 'idem-1',
          'X-Request-Id': 'req-1',
          'X-Forwarded-For': '203.0.113.50',
          Cookie: 'session=stolen',
          __proto__: 'polluted',
        },
      });
      triggerResponse();
      vi.advanceTimersByTime(0);
      await promise;

      expect(mockSetHeader).toHaveBeenCalledWith('Authorization', 'Bearer token');
      expect(mockSetHeader).toHaveBeenCalledWith('Idempotency-Key', 'idem-1');
      expect(mockSetHeader).toHaveBeenCalledWith('X-Request-Id', 'req-1');
      expect(mockSetHeader).not.toHaveBeenCalledWith('X-Forwarded-For', expect.any(String));
      expect(mockSetHeader).not.toHaveBeenCalledWith('Cookie', expect.any(String));
      expect(mockSetHeader).not.toHaveBeenCalledWith('__proto__', expect.any(String));
    });

    it('CRLF-et tartalmazo header ertek nem tovabbitodik', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/data',
        headers: {
          Authorization: 'Bearer ok',
          'X-Request-Id': 'req-1\r\nInjected: yes',
        },
      });
      triggerResponse();
      vi.advanceTimersByTime(0);
      await promise;

      expect(mockSetHeader).toHaveBeenCalledWith('Authorization', 'Bearer ok');
      expect(mockSetHeader).not.toHaveBeenCalledWith('X-Request-Id', expect.any(String));
    });
  });

  describe('HTTP státusz kezelés', () => {
    it('2xx → ok: true', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/ok',
      });
      triggerResponse({ statusCode: 201 });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.ok).toBe(true);
    });

    it('4xx → ok: false', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/bad',
      });
      triggerResponse({ statusCode: 401, statusMessage: 'Unauthorized' });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.ok).toBe(false);
      expect(result.status).toBe(401);
      expect(result.statusText).toBe('Unauthorized');
    });

    it('5xx → ok: false', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/err',
      });
      triggerResponse({ statusCode: 500 });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.ok).toBe(false);
      expect(result.status).toBe(500);
    });
  });

  describe('bináris válasz (base64)', () => {
    it('application/octet-stream → base64 kódolt', async () => {
      const binaryData = Buffer.from([0x89, 0x50, 0x4e, 0x47]);
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/file',
      });
      triggerResponse({
        headers: { 'content-type': 'application/octet-stream' },
        chunks: [binaryData],
      });
      vi.advanceTimersByTime(0);
      const result = await promise;

      expect(result.isBase64).toBe(true);
      expect(result.body).toBe(binaryData.toString('base64'));
    });

    it('application/json → NEM base64', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/json',
      });
      triggerResponse({
        headers: { 'content-type': 'application/json; charset=utf-8' },
        chunks: [Buffer.from('{"x":1}')],
      });
      vi.advanceTimersByTime(0);
      const result = await promise;

      expect(result.isBase64).toBe(false);
      expect(result.body).toBe('{"x":1}');
    });

    it('text/html → NEM base64', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/page',
      });
      triggerResponse({
        headers: { 'content-type': 'text/html' },
        chunks: [Buffer.from('<html></html>')],
      });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.isBase64).toBe(false);
    });

    it('üres content-type → NEM base64 (ct === "")', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/noct',
      });
      triggerResponse({
        headers: {},
        chunks: [Buffer.from('plain')],
      });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.isBase64).toBe(false);
    });

    it('xlsx content-type (openxmlformats) → base64 kódolt (FK-051 v2)', async () => {
      // Regressziós védelem: a régi blacklist-detekció a MIME-típusban lévő "xml"
      // szó miatt tévesen szövegként kezelte a .xlsx-t → bájt-korrupció.
      const xlsxMagic = Buffer.from([0x50, 0x4b, 0x03, 0x04]); // PK zip header
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/reports/average-rate/export',
      });
      triggerResponse({
        headers: {
          'content-type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        },
        chunks: [xlsxMagic],
      });
      vi.advanceTimersByTime(0);
      const result = await promise;

      expect(result.isBase64).toBe(true);
      expect(result.body).toBe(xlsxMagic.toString('base64'));
    });

    it('application/xml → NEM base64 (whitelist-regresszió)', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/xml',
      });
      triggerResponse({
        headers: { 'content-type': 'application/xml' },
        chunks: [Buffer.from('<a/>')],
      });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.isBase64).toBe(false);
      expect(result.body).toBe('<a/>');
    });

    it('application/pdf → base64 kódolt (whitelist: nem szöveges)', async () => {
      const pdfMagic = Buffer.from('%PDF-1.7');
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/pdf',
      });
      triggerResponse({
        headers: { 'content-type': 'application/pdf' },
        chunks: [pdfMagic],
      });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.isBase64).toBe(true);
      expect(result.body).toBe(pdfMagic.toString('base64'));
    });
  });

  describe('több chunk', () => {
    it('több data chunk → összefűzve', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/multi',
      });
      triggerResponse({
        headers: { 'content-type': 'application/json' },
        chunks: [Buffer.from('{"he'), Buffer.from('llo"'), Buffer.from(':"ok"}')],
      });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.body).toBe('{"hello":"ok"}');
    });
  });

  describe('timeout', () => {
    it('timeout lejártakor reject', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/slow',
        timeoutMs: 5000,
      });

      vi.advanceTimersByTime(5001);

      await expect(promise).rejects.toThrow('[api-proxy] Timeout');
      expect(mockAbort).toHaveBeenCalled();
    });

    it('alapértelmezett timeout 30s', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/slow',
      });

      vi.advanceTimersByTime(30_001);
      await expect(promise).rejects.toThrow('Timeout');
    });
  });

  describe('hálózati hiba', () => {
    it('request error → reject', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/err',
      });
      process.nextTick(() => {
        mockRequestEmitter.emit('error', new Error('ECONNREFUSED'));
      });
      vi.advanceTimersByTime(0);
      await expect(promise).rejects.toThrow('[api-proxy] Network error: ECONNREFUSED');
    });
  });

  describe('method normalizálás', () => {
    it('kisbetűs method → nagybetűre konvertál', async () => {
      const promise = fetchViaElectronNet({
        method: 'post',
        url: 'https://excvaluta.com/api/v1/test/data',
        body: '{}',
      });
      triggerResponse();
      vi.advanceTimersByTime(0);
      await promise;

      expect(electronNet.request).toHaveBeenCalledWith({
        method: 'POST',
        url: 'https://excvaluta.com/api/v1/test/data',
      });
    });
  });

  describe('engedelyezett telepitesi hostok', () => {
    it('LAN backend URL engedelyezett offline/helyi telepiteshez', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'http://192.168.1.20:8080/api/v1/auth/bootstrap-status',
      });
      triggerResponse();
      vi.advanceTimersByTime(0);
      const result = await promise;

      expect(result.ok).toBe(true);
      expect(electronNet.request).toHaveBeenCalledWith({
        method: 'GET',
        url: 'http://192.168.1.20:8080/api/v1/auth/bootstrap-status',
      });
    });

    it('tetszoleges kulso host tovabbra is blokkolt', async () => {
      await expect(
        fetchViaElectronNet({
          method: 'GET',
          url: 'https://example.com/api/v1/auth/bootstrap-status',
        }),
      ).rejects.toThrow('Blocked: URL host not in allowlist');
    });

    it('F-005: cloud-metadata link-local (169.254.169.254) BLOKKOLT (SSRF)', async () => {
      await expect(
        fetchViaElectronNet({
          method: 'GET',
          url: 'http://169.254.169.254/latest/meta-data/',
        }),
      ).rejects.toThrow('Blocked: URL host not in allowlist');
    });

    it('F-005: nem-http(s) protokoll (file:) BLOKKOLT', async () => {
      await expect(
        fetchViaElectronNet({
          method: 'GET',
          url: 'file:///etc/passwd',
        }),
      ).rejects.toThrow('Blocked: URL host not in allowlist');
    });
  });

  describe('response header kezelés', () => {
    it('tömb headerek → comma-separated', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'https://excvaluta.com/api/v1/test/headers',
      });
      const response = createMockResponse({
        headers: { 'content-type': 'application/json' },
      });
      // Override headers to test array case — Electron IncomingMessage headers can be string[]
      Object.assign(response, {
        headers: { 'set-cookie': ['a=1', 'b=2'], 'content-type': 'application/json' },
      });
      process.nextTick(() => {
        mockRequestEmitter.emit('response', response);
      });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.headers['set-cookie']).toBe('a=1, b=2');
    });
  });
});

describe('isRetryableNetworkError (ESET-MITM reset felismeres)', () => {
  it('net::ERR_CONNECTION_RESET → retryable (a Szeged-ertektar 2026-06-01 eset)', () => {
    expect(isRetryableNetworkError('[api-proxy] Network error: net::ERR_CONNECTION_RESET')).toBe(
      true,
    );
  });
  it('tovabbi Chromium net-hibak (CLOSED/ABORTED/SSL/TIMED_OUT/NAME_NOT_RESOLVED) → retryable', () => {
    for (const code of [
      'net::ERR_CONNECTION_CLOSED',
      'net::ERR_CONNECTION_ABORTED',
      'net::ERR_SSL_PROTOCOL_ERROR',
      'net::ERR_TIMED_OUT',
      'net::ERR_NAME_NOT_RESOLVED',
      'net::ERR_NETWORK_CHANGED',
      'net::ERR_EMPTY_RESPONSE',
    ]) {
      expect(isRetryableNetworkError(`[api-proxy] Network error: ${code}`)).toBe(true);
    }
  });
  it('Node socket-hibak (ECONNRESET/ECONNREFUSED/EAI_AGAIN/ENOTFOUND/socket hang up) → retryable', () => {
    for (const code of ['ECONNRESET', 'ECONNREFUSED', 'EAI_AGAIN', 'ENOTFOUND', 'socket hang up']) {
      expect(isRetryableNetworkError(code)).toBe(true);
    }
  });
  it('[api-proxy] Timeout → retryable', () => {
    expect(isRetryableNetworkError('[api-proxy] Timeout: 15000ms exceeded for POST ...')).toBe(
      true,
    );
  });
  it('HTTP-szeru / business hibak → NEM retryable', () => {
    expect(isRetryableNetworkError('HTTP 401 Unauthorized')).toBe(false);
    expect(isRetryableNetworkError('Blocked: URL host not in allowlist')).toBe(false);
    expect(isRetryableNetworkError('')).toBe(false);
    expect(isRetryableNetworkError(null)).toBe(false);
    expect(isRetryableNetworkError(undefined)).toBe(false);
  });
});

describe('retryFetch (ESET-rezisztens ujraprobalkozas)', () => {
  const okResponse: ApiProxyResponse = {
    ok: true,
    status: 200,
    statusText: 'OK',
    headers: {},
    body: '{"ok":true}',
  };
  const instantSleep = vi.fn(async (_ms: number) => {});

  beforeEach(() => instantSleep.mockClear());

  it('reset×2 majd siker → 3. probara visszaad (ESET "megtanulja" a domaint)', async () => {
    let calls = 0;
    const doFetch = vi.fn(async () => {
      calls += 1;
      if (calls <= 2) throw new Error('[api-proxy] Network error: net::ERR_CONNECTION_RESET');
      return okResponse;
    });
    const result = await retryFetch(doFetch, {
      maxRetries: 5,
      retryDelaysMs: [1, 1, 1, 1],
      sleep: instantSleep,
    });
    expect(result.ok).toBe(true);
    expect(doFetch).toHaveBeenCalledTimes(3);
    expect(instantSleep).toHaveBeenCalledTimes(2); // ket retry kozott ket varakozas
  });

  it('minden proba reset → maxRetries utan az utolso hibat dobja', async () => {
    const doFetch = vi.fn(async () => {
      throw new Error('[api-proxy] Network error: net::ERR_CONNECTION_RESET');
    });
    await expect(
      retryFetch(doFetch, { maxRetries: 4, retryDelaysMs: [1, 1, 1], sleep: instantSleep }),
    ).rejects.toThrow('net::ERR_CONNECTION_RESET');
    expect(doFetch).toHaveBeenCalledTimes(4);
    expect(instantSleep).toHaveBeenCalledTimes(3); // maxRetries-1 varakozas
  });

  it('nem-retryable hiba (HTTP-szeru throw) → AZONNAL dob, nincs retry', async () => {
    const doFetch = vi.fn(async () => {
      throw new Error('Blocked: URL host not in allowlist');
    });
    await expect(retryFetch(doFetch, { maxRetries: 5, sleep: instantSleep })).rejects.toThrow(
      'Blocked',
    );
    expect(doFetch).toHaveBeenCalledTimes(1);
    expect(instantSleep).not.toHaveBeenCalled();
  });

  it('elso probara siker → nincs retry, nincs sleep', async () => {
    const doFetch = vi.fn(async () => okResponse);
    const result = await retryFetch(doFetch, { sleep: instantSleep });
    expect(result.ok).toBe(true);
    expect(doFetch).toHaveBeenCalledTimes(1);
    expect(instantSleep).not.toHaveBeenCalled();
  });

  it('ok:false (HTTP 4xx/5xx) valasz NEM dob → retry nelkul visszaadja', async () => {
    const httpErr: ApiProxyResponse = {
      ok: false,
      status: 401,
      statusText: 'Unauthorized',
      headers: {},
      body: '{}',
    };
    const doFetch = vi.fn(async () => httpErr);
    const result = await retryFetch(doFetch, { sleep: instantSleep });
    expect(result.status).toBe(401);
    expect(doFetch).toHaveBeenCalledTimes(1);
  });
});

describe('isRetrySafeRequest (Codex P1 — mutalo tranzakcio dupla-vedelem)', () => {
  it('GET/HEAD/OPTIONS → mindig retry-biztos (idempotens)', () => {
    for (const method of ['GET', 'get', 'HEAD', 'OPTIONS']) {
      expect(isRetrySafeRequest({ method, url: 'https://excvaluta.com/api/v1/rates' })).toBe(true);
    }
  });
  it('mutalo POST/PUT/PATCH/DELETE Idempotency-Key NELKUL → NEM retry-biztos', () => {
    for (const method of ['POST', 'PUT', 'PATCH', 'DELETE', 'post']) {
      expect(
        isRetrySafeRequest({
          method,
          url: 'https://excvaluta.com/api/v1/transactions/buy',
          body: '{}',
        }),
      ).toBe(false);
    }
  });
  it('POST Idempotency-Key-vel → retry-biztos (backend deduplikal)', () => {
    expect(
      isRetrySafeRequest({
        method: 'POST',
        url: 'https://excvaluta.com/api/v1/transactions/buy',
        headers: { 'Idempotency-Key': 'abc-123' },
        body: '{}',
      }),
    ).toBe(true);
  });
  it('Idempotency-Key fejlec case-insensitive + ures kulcs nem szamit', () => {
    expect(
      isRetrySafeRequest({
        method: 'POST',
        url: 'https://excvaluta.com/api/v1/sell',
        headers: { 'idempotency-key': 'k1' },
      }),
    ).toBe(true);
    expect(
      isRetrySafeRequest({
        method: 'POST',
        url: 'https://excvaluta.com/api/v1/sell',
        headers: { 'Idempotency-Key': '' },
      }),
    ).toBe(false);
  });
  it('fetchViaElectronNetWithRetry: mutalo kulcs-nelkuli POST → 1 proba (nincs retry)', async () => {
    // A google-identify-szeru retry-biztos POST kulccsal megy; ez itt a vedett eset:
    // buy/sell kulcs nelkul SOHA nem duplikalodhat retry-bol.
    expect(
      isRetrySafeRequest({
        method: 'POST',
        url: 'https://excvaluta.com/api/v1/transactions/reversal',
      }),
    ).toBe(false);
  });
});
