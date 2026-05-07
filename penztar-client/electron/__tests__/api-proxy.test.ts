import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { EventEmitter } from 'node:events';

// Mock electron-log
vi.mock('electron-log/main', () => ({
  default: { warn: vi.fn(), info: vi.fn(), error: vi.fn() },
}));

// Mock response helper
function createMockResponse(opts: {
  statusCode?: number;
  statusMessage?: string;
  headers?: Record<string, string>;
  chunks?: Buffer[];
  errorOnData?: Error;
} = {}) {
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

import { fetchViaElectronNet } from '../api-proxy';
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
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/data' });
      triggerResponse({
        statusCode: 200,
        headers: { 'content-type': 'application/json' },
        chunks: [Buffer.from('{"hello":"world"}')],
      });

      vi.advanceTimersByTime(0);
      const result = await promise;

      expect(electronNet.request).toHaveBeenCalledWith({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/data' });
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

      const setHeaderCalls = mockSetHeader.mock.calls.map(c => c[0]);
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
        headers: { 'Content-Type': 'text/plain', 'Accept': 'text/html' },
      });
      triggerResponse();
      vi.advanceTimersByTime(0);
      await promise;

      expect(mockSetHeader).toHaveBeenCalledWith('Content-Type', 'text/plain');
      expect(mockSetHeader).toHaveBeenCalledWith('Accept', 'text/html');
      const ctCalls = mockSetHeader.mock.calls.filter(c => c[0] === 'Content-Type');
      expect(ctCalls).toHaveLength(1);
    });

    it('csak whitelistelt request headerek jutnak at a rendererbol', async () => {
      const headers = {
        Authorization: 'Bearer token',
        'idempotency-key': 'idem-1',
        'X-Request-Id': 'req-1',
        'X-Forwarded-For': '203.0.113.50',
        Cookie: 'session=stolen',
      } as Record<string, string>;
      Object.defineProperty(headers, '__proto__', {
        value: 'polluted',
        enumerable: true,
        configurable: true,
      });

      const promise = fetchViaElectronNet({
        method: 'PATCH',
        url: 'https://excvaluta.com/api/v1/workers/bulk-email',
        body: '{}',
        headers,
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
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/ok' });
      triggerResponse({ statusCode: 201 });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.ok).toBe(true);
    });

    it('4xx → ok: false', async () => {
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/bad' });
      triggerResponse({ statusCode: 401, statusMessage: 'Unauthorized' });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.ok).toBe(false);
      expect(result.status).toBe(401);
      expect(result.statusText).toBe('Unauthorized');
    });

    it('5xx → ok: false', async () => {
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/err' });
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
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/file' });
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
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/json' });
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
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/page' });
      triggerResponse({
        headers: { 'content-type': 'text/html' },
        chunks: [Buffer.from('<html></html>')],
      });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.isBase64).toBe(false);
    });

    it('üres content-type → NEM base64 (ct === "")', async () => {
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/noct' });
      triggerResponse({
        headers: {},
        chunks: [Buffer.from('plain')],
      });
      vi.advanceTimersByTime(0);
      const result = await promise;
      expect(result.isBase64).toBe(false);
    });
  });

  describe('több chunk', () => {
    it('több data chunk → összefűzve', async () => {
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/multi' });
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
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/err' });
      process.nextTick(() => {
        mockRequestEmitter.emit('error', new Error('ECONNREFUSED'));
      });
      vi.advanceTimersByTime(0);
      await expect(promise).rejects.toThrow('[api-proxy] Network error: ECONNREFUSED');
    });
  });

  describe('method normalizálás', () => {
    it('kisbetűs method → nagybetűre konvertál', async () => {
      const promise = fetchViaElectronNet({ method: 'post', url: 'https://excvaluta.com/api/v1/test/data', body: '{}' });
      triggerResponse();
      vi.advanceTimersByTime(0);
      await promise;

      expect(electronNet.request).toHaveBeenCalledWith({ method: 'POST', url: 'https://excvaluta.com/api/v1/test/data' });
    });
  });

  describe('engedelyezett telepitesi hostok', () => {
    it('konfiguralt LAN backend URL engedelyezett offline/helyi telepiteshez', async () => {
      const promise = fetchViaElectronNet({
        method: 'GET',
        url: 'http://192.168.1.20:8080/api/v1/auth/bootstrap-status',
      }, {
        configuredBaseUrl: 'http://192.168.1.20:8080/api/v1',
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

    it('nem konfiguralt LAN backend URL blokkolt', async () => {
      await expect(fetchViaElectronNet({
        method: 'GET',
        url: 'http://192.168.1.20:8080/api/v1/auth/bootstrap-status',
      }, {
        configuredBaseUrl: 'https://excvaluta.com/api/v1',
      })).rejects.toThrow('Blocked: URL host not in allowlist');
    });

    it('link-local metadata host akkor sem engedelyezett, ha privat IPv4-nek tunik', async () => {
      await expect(fetchViaElectronNet({
        method: 'GET',
        url: 'http://169.254.169.254/latest/meta-data',
      }, {
        configuredBaseUrl: 'http://192.168.1.20:8080/api/v1',
      })).rejects.toThrow('Blocked: URL host not in allowlist');
    });

    it('tetszoleges kulso host tovabbra is blokkolt', async () => {
      await expect(fetchViaElectronNet({
        method: 'GET',
        url: 'https://example.com/api/v1/auth/bootstrap-status',
      })).rejects.toThrow('Blocked: URL host not in allowlist');
    });
  });

  describe('response header kezelés', () => {
    it('tömb headerek → comma-separated', async () => {
      const promise = fetchViaElectronNet({ method: 'GET', url: 'https://excvaluta.com/api/v1/test/headers' });
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
