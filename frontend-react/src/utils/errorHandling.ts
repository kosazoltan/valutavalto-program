import { AxiosError } from 'axios'

export interface ApiError {
  message: string
  status?: number
  code?: string
  details?: unknown
}

export class ApplicationError extends Error {
  public readonly status?: number
  public readonly code?: string
  public readonly details?: unknown

  constructor(message: string, status?: number, code?: string, details?: unknown) {
    super(message)
    this.name = 'ApplicationError'
    this.status = status
    this.code = code
    this.details = details
    Object.setPrototypeOf(this, ApplicationError.prototype)
  }
}

function humanizeRawMessage(msg: string): string {
  if (msg === 'Network Error' || msg === 'Failed to fetch' || msg === 'Load failed') {
    return 'A szerver nem érhető el. Ellenőrizze a hálózati kapcsolatot.'
  }
  if (msg.includes('ECONNREFUSED') || msg.includes('ERR_CONNECTION_REFUSED')) {
    return 'A szerver nem fogadja a kapcsolatot.'
  }
  if (msg.includes('ENOTFOUND') || msg.includes('ERR_NAME_NOT_RESOLVED')) {
    return 'A szerver címe nem található.'
  }
  if (msg.includes('ETIMEDOUT') || msg.includes('timeout')) {
    return 'A szerver nem válaszolt időben.'
  }
  if (msg.includes('ERR_CERT') || msg.includes('SSL') || msg.includes('certificate')) {
    return 'Tanúsítvány hiba a szerver felé. Ellenőrizze a HTTPS beállításokat.'
  }
  if (msg.includes('CORS') || msg.includes('cross-origin')) {
    return 'A szerver nem engedélyezi a hozzáférést (CORS). Forduljon a rendszergazdához.'
  }
  return msg
}

export function humanizeError(err: unknown): string {
  if (err instanceof Error) return humanizeRawMessage(err.message)
  return String(err)
}

export function humanizeIpcError(code: string, message: string): string {
  if (code.startsWith('HTTP_4')) return message

  const humanized = humanizeRawMessage(message)
  if (humanized !== message) return humanized

  if (code === 'NETWORK') return 'A szerver nem érhető el. Ellenőrizze a hálózati kapcsolatot.'
  if (code === 'TIMEOUT') return 'A szerver nem válaszolt időben. Próbálja újra.'
  if (code === 'PARSE_ERROR') return 'A szerver válasza nem értelmezhető.'
  if (code === 'UNEXPECTED') return 'Váratlan hiba történt a bejelentkezés során.'
  if (code === 'MISCONFIGURED') return message
  if (code === 'BAD_REQUEST') return 'Hiányzó bejelentkezési adatok.'

  return message
}

export function handleApiError(error: unknown): ApplicationError {
  if (error instanceof ApplicationError) {
    return error
  }

  if (error instanceof AxiosError) {
    const status = error.response?.status
    const serverMessage = error.response?.data?.message
    const message = serverMessage || humanizeRawMessage(error.message || 'Ismeretlen hiba történt')
    const code = error.response?.data?.code || error.code
    const details = error.response?.data

    return new ApplicationError(message, status, code, details)
  }

  if (error instanceof Error) {
    return new ApplicationError(humanizeRawMessage(error.message))
  }

  return new ApplicationError('Ismeretlen hiba történt')
}

export function getErrorMessage(error: unknown): string {
  const appError = handleApiError(error)
  return appError.message
}

/**
 * Hibaüzenet kinyerése blob-válaszú (`responseType: 'blob'`) kérésből.
 *
 * Ilyenkor a NEM-2xx hibatest is `Blob`, ezért a sima {@link getErrorMessage}
 * nem látja a szerver (magyar) üzenetét. Itt kiolvassuk a blob szövegét, és ha
 * JSON, a `message` mezőt adjuk vissza; különben a nyers szöveget; ha nincs, a
 * standard handlerre esünk vissza.
 */
export async function getBlobErrorMessage(error: unknown): Promise<string> {
  const data = (error as { response?: { data?: unknown } })?.response?.data
  if (data instanceof Blob) {
    try {
      const text = await data.text()
      try {
        const json = JSON.parse(text) as { message?: unknown }
        if (typeof json?.message === 'string') return json.message
      } catch {
        // nem JSON — a nyers szöveggel térünk vissza, ha van
      }
      if (text) return text
    } catch {
      // blob-olvasás sikertelen — esünk a general handlerre
    }
  }
  return getErrorMessage(error)
}

export function isNetworkError(error: unknown): boolean {
  if (error instanceof AxiosError) {
    return !error.response && error.code === 'ERR_NETWORK'
  }
  return false
}

export function isUnauthorizedError(error: unknown): boolean {
  if (error instanceof AxiosError) {
    return error.response?.status === 401
  }
  if (error instanceof ApplicationError) {
    return error.status === 401
  }
  return false
}

export function isForbiddenError(error: unknown): boolean {
  if (error instanceof AxiosError) {
    return error.response?.status === 403
  }
  if (error instanceof ApplicationError) {
    return error.status === 403
  }
  return false
}

export function isNotFoundError(error: unknown): boolean {
  if (error instanceof AxiosError) {
    return error.response?.status === 404
  }
  if (error instanceof ApplicationError) {
    return error.status === 404
  }
  return false
}
