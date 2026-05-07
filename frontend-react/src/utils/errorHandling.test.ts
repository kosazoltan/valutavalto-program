import { describe, it, expect } from 'vitest'
import { AxiosError } from 'axios'
import {
  ApplicationError,
  handleApiError,
  getErrorMessage,
  isNetworkError,
  isUnauthorizedError,
  isForbiddenError,
  isNotFoundError,
} from './errorHandling'

// ─────────────────────────── Helpers ───────────────────────────

function makeAxiosError(
  status?: number,
  data?: Record<string, unknown>,
  code?: string,
  hasResponse = true,
): AxiosError {
  const err = new AxiosError('axios error', code)
  if (hasResponse && status !== undefined) {
    // @ts-expect-error mocking private property
    err.response = { status, data: data ?? {} }
  }
  return err
}

// ─────────────────────────── ApplicationError ───────────────────────────

describe('ApplicationError', () => {
  it('sets message and name', () => {
    const e = new ApplicationError('test msg')
    expect(e.message).toBe('test msg')
    expect(e.name).toBe('ApplicationError')
  })

  it('stores status, code, details', () => {
    const e = new ApplicationError('msg', 404, 'NOT_FOUND', { x: 1 })
    expect(e.status).toBe(404)
    expect(e.code).toBe('NOT_FOUND')
    expect(e.details).toEqual({ x: 1 })
  })

  it('instanceof ApplicationError works after setPrototypeOf', () => {
    const e = new ApplicationError('x')
    expect(e instanceof ApplicationError).toBe(true)
    expect(e instanceof Error).toBe(true)
  })
})

// ─────────────────────────── handleApiError ───────────────────────────

describe('handleApiError', () => {
  it('returns same ApplicationError if already ApplicationError', () => {
    const original = new ApplicationError('already wrapped', 500)
    const result = handleApiError(original)
    expect(result).toBe(original)
  })

  it('wraps AxiosError with status + message from response', () => {
    const axErr = makeAxiosError(400, { message: 'Bad request' })
    const result = handleApiError(axErr)
    expect(result).toBeInstanceOf(ApplicationError)
    expect(result.status).toBe(400)
    expect(result.message).toBe('Bad request')
  })

  it('uses response errorMessage when message is missing', () => {
    const axErr = makeAxiosError(503, { errorMessage: 'manifest write failed' })
    const result = handleApiError(axErr)
    expect(result.status).toBe(503)
    expect(result.message).toBe('manifest write failed')
  })

  it('uses axios message when response has no message', () => {
    const axErr = makeAxiosError(500, {})
    const result = handleApiError(axErr)
    expect(result.status).toBe(500)
    expect(result.message).toBeTruthy()
  })

  it('wraps plain Error', () => {
    const err = new Error('plain error')
    const result = handleApiError(err)
    expect(result).toBeInstanceOf(ApplicationError)
    expect(result.message).toBe('plain error')
  })

  it('wraps unknown value', () => {
    const result = handleApiError('some string')
    expect(result).toBeInstanceOf(ApplicationError)
    expect(result.message).toBe('Ismeretlen hiba történt')
  })

  it('wraps null', () => {
    const result = handleApiError(null)
    expect(result.message).toBe('Ismeretlen hiba történt')
  })

  it('wraps undefined', () => {
    const result = handleApiError(undefined)
    expect(result.message).toBe('Ismeretlen hiba történt')
  })

  it('extracts code from AxiosError response data', () => {
    const axErr = makeAxiosError(422, { message: 'Validation', code: 'VALIDATION_ERROR' })
    const result = handleApiError(axErr)
    expect(result.code).toBe('VALIDATION_ERROR')
  })
})

// ─────────────────────────── getErrorMessage ───────────────────────────

describe('getErrorMessage', () => {
  it('extracts message from ApplicationError', () => {
    const e = new ApplicationError('hello')
    expect(getErrorMessage(e)).toBe('hello')
  })

  it('returns default for unknown', () => {
    expect(getErrorMessage(42)).toBe('Ismeretlen hiba történt')
  })
})

// ─────────────────────────── isNetworkError ───────────────────────────

describe('isNetworkError', () => {
  it('returns true for AxiosError with ERR_NETWORK code and no response', () => {
    const err = makeAxiosError(undefined, undefined, 'ERR_NETWORK', false)
    expect(isNetworkError(err)).toBe(true)
  })

  it('returns false when response exists', () => {
    const err = makeAxiosError(500, {}, 'ERR_NETWORK')
    expect(isNetworkError(err)).toBe(false)
  })

  it('returns false for plain Error', () => {
    expect(isNetworkError(new Error('net'))).toBe(false)
  })

  it('returns false for ApplicationError', () => {
    expect(isNetworkError(new ApplicationError('net'))).toBe(false)
  })
})

// ─────────────────────────── isUnauthorizedError ───────────────────────────

describe('isUnauthorizedError', () => {
  it('returns true for AxiosError 401', () => {
    expect(isUnauthorizedError(makeAxiosError(401))).toBe(true)
  })

  it('returns true for ApplicationError 401', () => {
    expect(isUnauthorizedError(new ApplicationError('x', 401))).toBe(true)
  })

  it('returns false for 403', () => {
    expect(isUnauthorizedError(makeAxiosError(403))).toBe(false)
  })

  it('returns false for plain Error', () => {
    expect(isUnauthorizedError(new Error('x'))).toBe(false)
  })
})

// ─────────────────────────── isForbiddenError ───────────────────────────

describe('isForbiddenError', () => {
  it('returns true for AxiosError 403', () => {
    expect(isForbiddenError(makeAxiosError(403))).toBe(true)
  })

  it('returns true for ApplicationError 403', () => {
    expect(isForbiddenError(new ApplicationError('x', 403))).toBe(true)
  })

  it('returns false for 401', () => {
    expect(isForbiddenError(makeAxiosError(401))).toBe(false)
  })
})

// ─────────────────────────── isNotFoundError ───────────────────────────

describe('isNotFoundError', () => {
  it('returns true for AxiosError 404', () => {
    expect(isNotFoundError(makeAxiosError(404))).toBe(true)
  })

  it('returns true for ApplicationError 404', () => {
    expect(isNotFoundError(new ApplicationError('x', 404))).toBe(true)
  })

  it('returns false for 500', () => {
    expect(isNotFoundError(makeAxiosError(500))).toBe(false)
  })

  it('returns false for plain Error', () => {
    expect(isNotFoundError(new Error('x'))).toBe(false)
  })
})
