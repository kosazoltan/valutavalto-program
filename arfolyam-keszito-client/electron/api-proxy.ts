import { net as electronNet, type IncomingMessage } from 'electron'
import log from 'electron-log/main'

export interface ApiProxyRequest {
  method: string
  url: string
  body?: string | null
  headers?: Record<string, string>
  timeoutMs?: number
}

export interface ApiProxyResponse {
  ok: boolean
  status: number
  statusText: string
  headers: Record<string, string>
  body: string
  isBase64?: boolean
}

const DEFAULT_TIMEOUT_MS = 30_000
const MAX_RESPONSE_BYTES = 50 * 1024 * 1024
const ALLOWED_HOSTS = ['excvaluta.com', 'localhost']

function isPrivateOrLoopbackHost(hostname: string): boolean {
  const host = hostname.toLowerCase()
  if (host === '127.0.0.1' || host === '::1' || host === '[::1]') return true

  const parts = host.split('.').map((part) => Number.parseInt(part, 10))
  if (parts.length !== 4 || parts.some((part) => Number.isNaN(part) || part < 0 || part > 255)) {
    return false
  }

  const a = parts[0] ?? -1
  const b = parts[1] ?? -1
  return a === 10
    || (a === 172 && b >= 16 && b <= 31)
    || (a === 192 && b === 168)
    || (a === 169 && b === 254)
    || a === 127
}

function isAllowedUrl(raw: string): boolean {
  try {
    const parsed = new URL(raw)
    return ALLOWED_HOSTS.some((host) => parsed.hostname === host || parsed.hostname.endsWith(`.${host}`))
      || isPrivateOrLoopbackHost(parsed.hostname)
  } catch {
    return false
  }
}

function safeHeaderValue(value: unknown): string | null {
  if (typeof value !== 'string') return null
  if (value.length > 8192) return null
  if (/[\r\n]/.test(value)) return null
  return value
}

function copySafeRequestHeaders(
  request: Electron.ClientRequest,
  headers?: Record<string, string>,
): void {
  if (!headers) return

  for (const [rawKey, rawValue] of Object.entries(headers)) {
    const value = safeHeaderValue(rawValue)
    if (value === null) continue

    switch (rawKey.toLowerCase()) {
      case 'accept':
        request.setHeader('Accept', value)
        break
      case 'authorization':
        request.setHeader('Authorization', value)
        break
      case 'content-type':
        request.setHeader('Content-Type', value)
        break
      case 'idempotency-key':
        request.setHeader('Idempotency-Key', value)
        break
      case 'x-request-id':
        request.setHeader('X-Request-Id', value)
        break
      case 'accept-language':
        request.setHeader('Accept-Language', value)
        break
      default:
        break
    }
  }
}

export function fetchViaElectronNet(params: ApiProxyRequest): Promise<ApiProxyResponse> {
  const { method, url, body, headers, timeoutMs } = params
  const timeout = timeoutMs ?? DEFAULT_TIMEOUT_MS

  if (!isAllowedUrl(url)) {
    return Promise.reject(new Error(`[api-proxy] Tiltott API host: ${url}`))
  }

  const upperMethod = method.toUpperCase()
  const hasBody = body !== undefined && body !== null && body !== ''

  return new Promise((resolve, reject) => {
    const request = electronNet.request({ method: upperMethod, url })

    copySafeRequestHeaders(request, headers)
    if (hasBody && upperMethod !== 'GET' && upperMethod !== 'HEAD') {
      request.setHeader('Content-Type', String(headers?.['Content-Type'] ?? headers?.['content-type'] ?? 'application/json'))
    }
    if (!headers?.Accept && !headers?.accept) {
      request.setHeader('Accept', 'application/json')
    }

    const chunks: Buffer[] = []
    let responseBytes = 0
    let settled = false
    const timeoutHandle = setTimeout(() => {
      if (settled) return
      settled = true
      try { request.abort() } catch { /* ignore */ }
      reject(new Error(`[api-proxy] Időtúllépés: ${timeout}ms ${method} ${url}`))
    }, timeout)

    request.on('response', (response: IncomingMessage) => {
      const responseHeaders = new Map<string, string>()
      for (const [key, value] of Object.entries(response.headers)) {
        if (key === '__proto__' || key === 'constructor' || key === 'prototype') continue
        responseHeaders.set(key, Array.isArray(value) ? value.join(', ') : String(value ?? ''))
      }

      response.on('data', (chunk: Buffer) => {
        if (settled) return
        responseBytes += chunk.length
        if (responseBytes > MAX_RESPONSE_BYTES) {
          settled = true
          clearTimeout(timeoutHandle)
          try { request.abort() } catch { /* ignore */ }
          reject(new Error(`[api-proxy] Túl nagy szerverválasz (>${MAX_RESPONSE_BYTES} byte)`))
          return
        }
        chunks.push(chunk)
      })

      response.on('end', () => {
        if (settled) return
        settled = true
        clearTimeout(timeoutHandle)

        const status = response.statusCode ?? 0
        const fullBuffer = Buffer.concat(chunks)
        const headersObject = Object.fromEntries(responseHeaders)
        const contentType = (headersObject['content-type'] ?? '').toLowerCase()
        const isBinary = contentType !== ''
          && !contentType.includes('json')
          && !contentType.includes('text')
          && !contentType.includes('xml')
          && !contentType.includes('html')

        resolve({
          ok: status >= 200 && status < 300,
          status,
          statusText: response.statusMessage ?? '',
          headers: headersObject,
          body: isBinary ? fullBuffer.toString('base64') : fullBuffer.toString('utf-8'),
          isBase64: isBinary,
        })
      })
    })

    request.on('error', (err: Error) => {
      if (settled) return
      settled = true
      clearTimeout(timeoutHandle)
      log.warn('[api-proxy] Network error:', method, url, err.message)
      reject(new Error(`[api-proxy] Hálózati hiba: ${err.message}`))
    })

    if (body) request.write(body)
    request.end()
  })
}
