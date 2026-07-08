/**
 * Main-process API proxy — electron.net.request alapú HTTP kliens.
 *
 * A renderer Chromium fetch / axios ESET MITM TLS proxy-val rendelkező gépeken
 * "Network Error"-t dob (Borsi laptop, Fabulya Zsuzsa, Kasza Helga — 2026-05-04/05/06 audit).
 * A v2.5.21 fix a login-t áttette main process-re, de a role selection, napnyitás és minden
 * más API hívás továbbra is renderer axios-on ment → Network Error.
 *
 * Ez a modul egy általános HTTP proxy-t biztosít: a renderer `window.electronAPI.apiRequest()`
 * IPC-n hívja, és a main process `electron.net.request`-tel továbbítja a backend felé.
 * Az `electron.net.request` a Windows certificate store + Chromium network stack-et használja
 * (--disable-http2, --disable-features=EncryptedClientHello switches alkalmazva a main.ts-ben),
 * ami ESET/Kaspersky/Bitdefender MITM proxy-val is működik.
 */

import { net as electronNet, IncomingMessage } from 'electron';
import log from 'electron-log/main';

export interface ApiProxyRequest {
  method: string;
  url: string;
  body?: string | null;
  headers?: Record<string, string>;
  timeoutMs?: number;
}

export interface ApiProxyResponse {
  ok: boolean;
  status: number;
  statusText: string;
  headers: Record<string, string>;
  body: string;
  isBase64?: boolean;
}

const DEFAULT_TIMEOUT_MS = 30_000;
const MAX_RESPONSE_BYTES = 50 * 1024 * 1024; // 50 MB safety cap
const ALLOWED_HOSTS = ['excvaluta.com', 'localhost'];
type SafeRequestHeaders = {
  accept?: string;
  authorization?: string;
  contentType?: string;
  idempotencyKey?: string;
  requestId?: string;
  acceptLanguage?: string;
};

function safeHeaderValue(value: unknown): string | null {
  if (typeof value !== 'string') return null;
  if (value.length > 8192) return null;
  if (/[\r\n]/.test(value)) return null;
  return value;
}

function normalizeSafeRequestHeaders(headers?: Record<string, string>): SafeRequestHeaders {
  const safe: SafeRequestHeaders = {};
  if (!headers) return safe;

  for (const [rawKey, rawValue] of Object.entries(headers)) {
    const value = safeHeaderValue(rawValue);
    if (value === null) continue;
    switch (rawKey.toLowerCase()) {
      case 'accept':
        safe.accept = value;
        break;
      case 'authorization':
        safe.authorization = value;
        break;
      case 'content-type':
        safe.contentType = value;
        break;
      case 'idempotency-key':
        safe.idempotencyKey = value;
        break;
      case 'x-request-id':
        safe.requestId = value;
        break;
      case 'accept-language':
        safe.acceptLanguage = value;
        break;
      default:
        break;
    }
  }
  return safe;
}

// F-005 (audit 2026-05-29) SSRF-hardening: a loopback + RFC1918 privát tartomány (10/x,
// 172.16-31/x, 192.168/x) ENGEDÉLYEZETT — ez a LAN-backend / offline helyi telepítés legitim
// use-case-e (lásd api-proxy.test.ts "LAN backend URL engedelyezett"). DE a LINK-LOCAL-t
// (169.254/x, benne a 169.254.169.254 cloud-metadata SSRF-célpont) MOSTANTÓL BLOKKOLJUK, és
// csak http(s) protokollt engedünk — így renderer-kompromittálódás nem érheti el a
// metadata / nem-HTTP endpointokat a main-process proxyn át.
function isPrivateOrLoopbackHost(hostname: string): boolean {
  const host = hostname.toLowerCase();
  if (host === '127.0.0.1' || host === '::1' || host === '[::1]') {
    return true;
  }
  const parts = host.split('.').map((part) => Number.parseInt(part, 10));
  if (parts.length !== 4 || parts.some((part) => Number.isNaN(part) || part < 0 || part > 255)) {
    return false;
  }
  const a = parts[0] ?? -1;
  const b = parts[1] ?? -1;
  // 169.254/16 (link-local + cloud-metadata 169.254.169.254) SZÁNDÉKOSAN KIMARAD (F-005).
  return a === 10 || (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168) || a === 127;
}

function isAllowedUrl(raw: string): boolean {
  try {
    const parsed = new URL(raw);
    // Csak http(s) — file:, data:, stb. tiltott (F-005).
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
      return false;
    }
    return (
      ALLOWED_HOSTS.some((h) => parsed.hostname === h || parsed.hostname.endsWith(`.${h}`)) ||
      isPrivateOrLoopbackHost(parsed.hostname)
    );
  } catch {
    return false;
  }
}

export function fetchViaElectronNet(params: ApiProxyRequest): Promise<ApiProxyResponse> {
  const { method, url, body, headers, timeoutMs } = params;
  const timeout = timeoutMs ?? DEFAULT_TIMEOUT_MS;

  if (!isAllowedUrl(url)) {
    return Promise.reject(new Error(`[api-proxy] Blocked: URL host not in allowlist: ${url}`));
  }

  const upperMethod = method.toUpperCase();
  const hasBody = body !== undefined && body !== null && body !== '';
  const safeHeaders = normalizeSafeRequestHeaders(headers);

  return new Promise((resolve, reject) => {
    const request = electronNet.request({ method: upperMethod, url });

    if (safeHeaders.accept) request.setHeader('Accept', safeHeaders.accept);
    if (safeHeaders.authorization) request.setHeader('Authorization', safeHeaders.authorization);
    if (safeHeaders.contentType) request.setHeader('Content-Type', safeHeaders.contentType);
    if (safeHeaders.idempotencyKey)
      request.setHeader('Idempotency-Key', safeHeaders.idempotencyKey);
    if (safeHeaders.requestId) request.setHeader('X-Request-Id', safeHeaders.requestId);
    if (safeHeaders.acceptLanguage)
      request.setHeader('Accept-Language', safeHeaders.acceptLanguage);

    if (hasBody && upperMethod !== 'GET' && upperMethod !== 'HEAD' && !safeHeaders.contentType) {
      request.setHeader('Content-Type', 'application/json');
    }
    if (!safeHeaders.accept) {
      request.setHeader('Accept', 'application/json');
    }

    const chunks: Buffer[] = [];
    let responseBytes = 0;
    let settled = false;
    const timeoutHandle = setTimeout(() => {
      if (settled) return;
      settled = true;
      try {
        request.abort();
      } catch {
        /* ignore */
      }
      reject(new Error(`[api-proxy] Timeout: ${timeout}ms exceeded for ${method} ${url}`));
    }, timeout);

    request.on('response', (response: IncomingMessage) => {
      const respHeaders = new Map<string, string>();
      for (const [key, value] of Object.entries(response.headers)) {
        if (key === '__proto__' || key === 'constructor' || key === 'prototype') continue;
        respHeaders.set(key, Array.isArray(value) ? value.join(', ') : String(value ?? ''));
      }

      response.on('data', (chunk: Buffer) => {
        if (settled) return;
        responseBytes += chunk.length;
        if (responseBytes > MAX_RESPONSE_BYTES) {
          settled = true;
          clearTimeout(timeoutHandle);
          try {
            request.abort();
          } catch {
            /* ignore */
          }
          reject(
            new Error(
              `[api-proxy] Response too large (>${MAX_RESPONSE_BYTES} bytes) for ${method} ${url}`,
            ),
          );
          return;
        }
        chunks.push(chunk);
      });

      response.on('end', () => {
        if (settled) return;
        settled = true;
        clearTimeout(timeoutHandle);
        const status = response.statusCode ?? 0;
        const fullBuffer = Buffer.concat(chunks);
        const responseHeaders = Object.fromEntries(respHeaders);
        const ct = (responseHeaders['content-type'] ?? '').toLowerCase();
        const isBinary =
          !ct.includes('json') &&
          !ct.includes('text') &&
          !ct.includes('xml') &&
          !ct.includes('html') &&
          ct !== '';
        resolve({
          ok: status >= 200 && status < 300,
          status,
          statusText: response.statusMessage ?? '',
          headers: responseHeaders,
          body: isBinary ? fullBuffer.toString('base64') : fullBuffer.toString('utf-8'),
          isBase64: isBinary,
        });
      });
    });

    request.on('error', (err: Error) => {
      if (settled) return;
      settled = true;
      clearTimeout(timeoutHandle);
      log.warn('[api-proxy] Network error for', method, url, ':', err.message);
      reject(new Error(`[api-proxy] Network error: ${err.message}`));
    });

    if (body) {
      request.write(body);
    }
    request.end();
  });
}

/**
 * Hálózati szintű (NEM HTTP-státusz) hiba felismerése retry-hoz.
 *
 * <p>Az ESET/Kaspersky/Bitdefender MITM TLS-proxy hidegindításkor reseteli az ÚJ domain
 * (excvaluta.com) első TLS-kapcsolatát — ilyenkor az `electron.net.request` Chromium-stackje
 * `net::ERR_CONNECTION_RESET` (vagy ERR_CONNECTION_CLOSED/ABORTED, ERR_SSL*, ERR_NETWORK_CHANGED,
 * ERR_TIMED_OUT, ERR_NAME_NOT_RESOLVED) hibát dob. Ezekre ÉRDEMES újrapróbálni, mert a vírusirtó
 * a következő (friss) kapcsolatra már jellemzően átengedi. A `[api-proxy] Network error` /
 * `[api-proxy] Timeout` prefixek a {@link fetchViaElectronNet}-ből jönnek. A `ECONNRESET`/`EAI_AGAIN`/
 * `ECONNREFUSED`/`ENOTFOUND` a Node-stílusú socket-hibák (LAN/offline backend).
 *
 * <p>HTTP 4xx/5xx NEM számít hálózati hibának (a {@link fetchViaElectronNet} ezekre `ok:false`
 * választ ad, NEM dob) → a hívót a retry érintetlenül hagyja.
 */
const RETRYABLE_NETWORK_ERROR_RE =
  /Network error|Timeout|ECONNRESET|EAI_AGAIN|ECONNREFUSED|ENOTFOUND|ERR_CONNECTION_RESET|ERR_CONNECTION_CLOSED|ERR_CONNECTION_ABORTED|ERR_NETWORK_CHANGED|ERR_TIMED_OUT|ERR_NAME_NOT_RESOLVED|ERR_SSL|ERR_EMPTY_RESPONSE|ERR_CONNECTION_REFUSED|socket hang up/i;

export function isRetryableNetworkError(message: string | null | undefined): boolean {
  if (!message) return false;
  return RETRYABLE_NETWORK_ERROR_RE.test(message);
}

export interface RetryOptions {
  /** Próbálkozások maximális száma (default 5). */
  maxRetries?: number;
  /** Várakozás (ms) az egyes próbák KÖZÖTT; az utolsó elem ismétlődik, ha kevesebb mint maxRetries-1. */
  retryDelaysMs?: number[];
  /** Injektálható sleep (teszthez: instant). */
  sleep?: (ms: number) => Promise<void>;
}

const DEFAULT_RETRY_DELAYS_MS = [1000, 2000, 3000, 5000, 8000];

/**
 * Általános retry-wrapper hálózati hibára. HTTP-státusz (`ok:false`) választ NEM próbál újra.
 * ESET-MITM hidegindítás-reset ellen (egyes kliensgépeken, 2026-06-01 értéktár-eset).
 */
export async function retryFetch(
  doFetch: () => Promise<ApiProxyResponse>,
  options: RetryOptions = {},
): Promise<ApiProxyResponse> {
  const maxRetries = Math.max(1, options.maxRetries ?? 5);
  const delays = options.retryDelaysMs ?? DEFAULT_RETRY_DELAYS_MS;
  const sleep = options.sleep ?? ((ms: number) => new Promise<void>((r) => setTimeout(r, ms)));

  let lastErr: Error | null = null;
  for (let attempt = 0; attempt < maxRetries; attempt += 1) {
    try {
      return await doFetch();
    } catch (err) {
      lastErr = err instanceof Error ? err : new Error(String(err));
      const isLast = attempt === maxRetries - 1;
      if (!isRetryableNetworkError(lastErr.message) || isLast) {
        throw lastErr;
      }
      const delay = delays[attempt] ?? delays[delays.length - 1] ?? 5000;
      await sleep(delay);
    }
  }
  throw lastErr ?? new Error('[api-proxy] retryFetch: ismeretlen hiba');
}

/**
 * Egy kérés retry-biztos-e (NEM duplikálhat szerver-oldali mellékhatást újrapróbálkozáskor).
 *
 * <p>Codex P1 (2026-06-01): a megosztott `api:fetch` MINDEN renderer-hívásra megy, beleértve a
 * MUTÁLÓ pénztáros-tranzakciókat (`POST /transactions/buy|sell|reversal`). Ha egy ilyen POST a
 * szerveren már commitált, de a válasz timeoutol/resetel, az újrapróbálkozás DUPLIKÁLNÁ a
 * tranzakciót (pénzügyi-integritás sérülés). Ezért:
 * <ul>
 *   <li>GET/HEAD/OPTIONS — HTTP-idempotens, mindig retry-biztos.</li>
 *   <li>POST/PUT/PATCH/DELETE — CSAK akkor, ha `Idempotency-Key` fejléc van: ekkor a backend
 *       deduplikál (`IdempotencyRecord` / `SyncInboxEvent`), így az újraküldés biztonságos.</li>
 * </ul>
 * Kulcs nélküli mutáló kérést NEM próbálunk újra (inkább egy hálózati hiba, mint dupla tranzakció).
 */
export function isRetrySafeRequest(params: ApiProxyRequest): boolean {
  const method = (params.method || 'GET').toUpperCase();
  if (method === 'GET' || method === 'HEAD' || method === 'OPTIONS') {
    return true;
  }
  const headers = params.headers ?? {};
  return Object.entries(headers).some(
    ([key, value]) =>
      key.toLowerCase() === 'idempotency-key' && typeof value === 'string' && value.length > 0,
  );
}

/**
 * {@link fetchViaElectronNet} + ESET-rezisztens retry egy lépésben.
 *
 * <p>Retry CSAK retry-biztos kérésre fut ({@link isRetrySafeRequest}) — mutáló, kulcs-nélküli
 * POST/PATCH-et egyetlen próbára korlátoz (nincs duplikáció-kockázat).
 */
export function fetchViaElectronNetWithRetry(
  params: ApiProxyRequest,
  options: RetryOptions = {},
): Promise<ApiProxyResponse> {
  const maxRetries = isRetrySafeRequest(params) ? (options.maxRetries ?? 5) : 1;
  return retryFetch(() => fetchViaElectronNet(params), { ...options, maxRetries });
}
