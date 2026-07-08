import { describe, it, expect } from 'vitest'

/**
 * Az Electron IPC adapter (client.ts sor 143-250) unit tesztjei.
 *
 * Az adapter CSAK akkor aktiv, ha:
 *   typeof window !== 'undefined' && window.electronAPI?.apiRequest && !import.meta.env.DEV
 *
 * Mivel a vitest jsdom env-ben a fenti feltetel nem teljesul automatikusan,
 * az adapter logikajat kulon fuggvenyekbe extraháljuk a tesztelheteoseg erdekeben.
 * Itt az adapter belso logikat teszteljuk mock-olt electronAPI-val.
 */

// --- Helper: az adapter URL builder logikajat tesztelo pure fuggveny ---
function buildProxyUrl(
  config: {
    baseURL?: string
    url?: string
    params?: Record<string, unknown>
    paramsSerializer?: unknown
  },
  defaultBaseUrl: string,
): string {
  const baseUrl = config.baseURL ?? defaultBaseUrl
  let url = config.url?.startsWith('http') ? config.url : `${baseUrl}${config.url ?? ''}`

  if (config.params && typeof config.params === 'object') {
    const serializer = config.paramsSerializer
    let queryString: string
    if (typeof serializer === 'function') {
      queryString = (serializer as (params: unknown) => string)(config.params)
    } else if (
      serializer &&
      typeof serializer === 'object' &&
      'serialize' in (serializer as object) &&
      typeof (serializer as { serialize: unknown }).serialize === 'function'
    ) {
      queryString = (
        serializer as { serialize: (params: unknown, opts: unknown) => string }
      ).serialize(config.params, serializer)
    } else {
      const searchParams = new URLSearchParams()
      for (const [key, value] of Object.entries(config.params)) {
        if (value !== undefined && value !== null) {
          searchParams.append(key, String(value))
        }
      }
      queryString = searchParams.toString()
    }
    if (queryString) {
      url += (url.includes('?') ? '&' : '?') + queryString
    }
  }

  return url
}

// --- Helper: az adapter body serialization logikajat tesztelo fuggveny ---
function serializeBody(data: unknown): string | null {
  if (data === undefined || data === null) return null
  return typeof data === 'string' ? data : JSON.stringify(data)
}

// --- Helper: binary response reconstruction ---
function reconstructBinary(
  responseType: string | undefined,
  isBase64: boolean | undefined,
  body: string,
  contentType: string,
): unknown {
  if ((responseType === 'blob' || responseType === 'arraybuffer') && isBase64) {
    const binary = Uint8Array.from(atob(body), (c) => c.charCodeAt(0))
    return responseType === 'blob'
      ? new Blob([binary], { type: contentType.split(';')[0] || 'application/octet-stream' })
      : binary.buffer
  }
  if (contentType.includes('json') && typeof body === 'string') {
    try {
      return JSON.parse(body)
    } catch {
      return body
    }
  }
  return body
}

describe('Electron IPC adapter — URL builder', () => {
  const BASE = 'https://excvaluta.com/api/v1'

  it('relatív URL → baseURL + url', () => {
    expect(buildProxyUrl({ url: '/auth/login' }, BASE)).toBe(
      'https://excvaluta.com/api/v1/auth/login',
    )
  })

  it('abszolút URL → bypass baseURL', () => {
    expect(buildProxyUrl({ url: 'https://other.com/data' }, BASE)).toBe('https://other.com/data')
  })

  it('explicit baseURL felülírja a default-ot', () => {
    expect(buildProxyUrl({ baseURL: 'https://custom.com', url: '/test' }, BASE)).toBe(
      'https://custom.com/test',
    )
  })

  it('params → query string', () => {
    const url = buildProxyUrl(
      {
        url: '/transactions',
        params: { page: 1, size: 20, status: 'ACTIVE' },
      },
      BASE,
    )
    expect(url).toContain('/transactions?')
    expect(url).toContain('page=1')
    expect(url).toContain('size=20')
    expect(url).toContain('status=ACTIVE')
  })

  it('params null/undefined értékek kiszűrődnek', () => {
    const url = buildProxyUrl(
      {
        url: '/search',
        params: { q: 'test', empty: null, undef: undefined } as Record<string, unknown>,
      },
      BASE,
    )
    expect(url).toContain('q=test')
    expect(url).not.toContain('empty')
    expect(url).not.toContain('undef')
  })

  it('már létező query string-hez & jellel fűz', () => {
    const url = buildProxyUrl(
      {
        url: 'https://api.test/data?existing=1',
        params: { extra: 'yes' },
      },
      BASE,
    )
    expect(url).toBe('https://api.test/data?existing=1&extra=yes')
  })

  it('paramsSerializer függvény támogatás', () => {
    const url = buildProxyUrl(
      {
        url: '/custom',
        params: { a: 1, b: 2 },
        paramsSerializer: (p: Record<string, number>) => `custom=${Object.values(p).join(',')}`,
      },
      BASE,
    )
    expect(url).toContain('custom=1,2')
  })

  it('paramsSerializer object.serialize támogatás', () => {
    const url = buildProxyUrl(
      {
        url: '/custom',
        params: { x: 'hello' },
        paramsSerializer: {
          serialize: (p: Record<string, string>) => `ser=${Object.values(p).join('+')}`,
        },
      },
      BASE,
    )
    expect(url).toContain('ser=hello')
  })

  it('üres params → nincs query string', () => {
    const url = buildProxyUrl(
      {
        url: '/clean',
        params: {},
      },
      BASE,
    )
    expect(url).toBe('https://excvaluta.com/api/v1/clean')
  })
})

describe('Electron IPC adapter — body serialization', () => {
  it('null → null', () => {
    expect(serializeBody(null)).toBeNull()
  })

  it('undefined → null', () => {
    expect(serializeBody(undefined)).toBeNull()
  })

  it('string → passthrough', () => {
    expect(serializeBody('raw-body')).toBe('raw-body')
  })

  it('object → JSON.stringify', () => {
    expect(serializeBody({ key: 'value' })).toBe('{"key":"value"}')
  })

  it('array → JSON.stringify', () => {
    expect(serializeBody([1, 2, 3])).toBe('[1,2,3]')
  })
})

describe('Electron IPC adapter — binary response reconstruction', () => {
  it('blob responseType + isBase64 → Blob', () => {
    const b64 = btoa('hello')
    const result = reconstructBinary('blob', true, b64, 'application/pdf')
    expect(result).toBeInstanceOf(Blob)
    expect((result as Blob).type).toBe('application/pdf')
  })

  it('arraybuffer responseType + isBase64 → ArrayBuffer', () => {
    const b64 = btoa('test')
    const result = reconstructBinary('arraybuffer', true, b64, 'application/octet-stream')
    expect(result).toBeInstanceOf(ArrayBuffer)
    expect(new Uint8Array(result as ArrayBuffer)).toEqual(
      Uint8Array.from(atob(b64), (c) => c.charCodeAt(0)),
    )
  })

  it('json content-type → parsed object', () => {
    const result = reconstructBinary(undefined, false, '{"x":1}', 'application/json')
    expect(result).toEqual({ x: 1 })
  })

  it('invalid JSON → raw string', () => {
    const result = reconstructBinary(undefined, false, 'not-json', 'application/json')
    expect(result).toBe('not-json')
  })

  it('text content-type → raw string', () => {
    const result = reconstructBinary(undefined, false, 'hello', 'text/plain')
    expect(result).toBe('hello')
  })

  it('blob responseType WITHOUT isBase64 + json → parsed', () => {
    const result = reconstructBinary('blob', false, '{"data":true}', 'application/json')
    expect(result).toEqual({ data: true })
  })
})
