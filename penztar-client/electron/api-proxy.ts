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
import { isAllowedNetworkUrl } from './network-allowlist';

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
const ALLOWED_HOSTS = ['excvaluta.com'];
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

export interface ApiProxyOptions {
  configuredBaseUrl?: string | null;
}

export function fetchViaElectronNet(
  params: ApiProxyRequest,
  options: ApiProxyOptions = {},
): Promise<ApiProxyResponse> {
  const { method, url, body, headers, timeoutMs } = params;
  const timeout = timeoutMs ?? DEFAULT_TIMEOUT_MS;

  if (!isAllowedNetworkUrl(url, ALLOWED_HOSTS, options.configuredBaseUrl)) {
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
    if (safeHeaders.idempotencyKey) request.setHeader('Idempotency-Key', safeHeaders.idempotencyKey);
    if (safeHeaders.requestId) request.setHeader('X-Request-Id', safeHeaders.requestId);
    if (safeHeaders.acceptLanguage) request.setHeader('Accept-Language', safeHeaders.acceptLanguage);

    if (hasBody && upperMethod !== 'GET' && upperMethod !== 'HEAD'
        && !safeHeaders.contentType) {
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
      try { request.abort(); } catch { /* ignore */ }
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
          try { request.abort(); } catch { /* ignore */ }
          reject(new Error(`[api-proxy] Response too large (>${MAX_RESPONSE_BYTES} bytes) for ${method} ${url}`));
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
        const isBinary = !ct.includes('json') && !ct.includes('text') && !ct.includes('xml') && !ct.includes('html') && ct !== '';
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
