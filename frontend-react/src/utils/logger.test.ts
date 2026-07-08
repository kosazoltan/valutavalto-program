import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { logger } from './logger'

describe('logger', () => {
  let debugSpy: ReturnType<typeof vi.spyOn>
  let infoSpy: ReturnType<typeof vi.spyOn>
  let warnSpy: ReturnType<typeof vi.spyOn>
  let errorSpy: ReturnType<typeof vi.spyOn>

  function makeAxiosLikeError(): Error {
    const err = new Error('Request failed with status code 401') as Error & Record<string, unknown>
    err.name = 'AxiosError'
    err.isAxiosError = true
    err.code = 'ERR_BAD_REQUEST'
    err.config = {
      method: 'post',
      url: '/api/v1/aml-approval/verify-approver?trace=abc',
      headers: { Authorization: 'Bearer szupertitkos-token-123' },
      data: '{"pin":"9876","approverWorkerId":5}',
    }
    err.response = { status: 401, data: { error: 'Hibás PIN' } }
    return err
  }

  beforeEach(() => {
    debugSpy = vi.spyOn(console, 'debug').mockImplementation(() => {})
    infoSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
    warnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
    errorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  // In test/dev mode import.meta.env.DEV is true so all levels emit

  it('debug() calls console.debug with tag and message', () => {
    logger.debug('TestTag', 'debug message')
    expect(debugSpy).toHaveBeenCalledWith('[TestTag]', 'debug message')
  })

  it('info() calls console.log with tag and message', () => {
    logger.info('TestTag', 'info message')
    expect(infoSpy).toHaveBeenCalledWith('[TestTag]', 'info message')
  })

  it('warn() calls console.warn with tag and message', () => {
    logger.warn('TestTag', 'warn message')
    expect(warnSpy).toHaveBeenCalledWith('[TestTag]', 'warn message')
  })

  it('error() calls console.error with tag and message', () => {
    logger.error('TestTag', 'error message')
    expect(errorSpy).toHaveBeenCalledWith('[TestTag]', 'error message')
  })

  it('formats tag in square brackets', () => {
    logger.info('MyTag', 'msg')
    expect(infoSpy).toHaveBeenCalledWith('[MyTag]', 'msg')
  })

  it('passes extra args through', () => {
    logger.info('Tag', 'msg', { extra: true }, 42)
    expect(infoSpy).toHaveBeenCalledWith('[Tag]', 'msg', { extra: true }, 42)
  })

  it('error() converts Error arg to sanitized string (security contract, TD1)', () => {
    logger.error('Tag', 'something failed', new Error('oops'))
    const args = errorSpy.mock.calls[0]
    expect(args[0]).toBe('[Tag]')
    expect(args[1]).toBe('something failed')
    expect(typeof args[2]).toBe('string')
    expect(args[2]).toContain('Error: oops')
  })

  it('warn() with AxiosError never leaks Authorization header, token or PIN', () => {
    logger.warn('Api', 'request failed', makeAxiosLikeError())
    const flat = JSON.stringify(warnSpy.mock.calls[0])
    expect(flat).not.toContain('Bearer')
    expect(flat).not.toContain('szupertitkos-token-123')
    expect(flat).not.toContain('9876')
    expect(flat).toContain('status=401')
    expect(flat).toContain('ERR_BAD_REQUEST')
  })

  it('strips query string from the logged axios URL', () => {
    logger.warn('Api', 'request failed', makeAxiosLikeError())
    const flat = JSON.stringify(warnSpy.mock.calls[0])
    expect(flat).toContain('/api/v1/aml-approval/verify-approver')
    expect(flat).not.toContain('trace=abc')
  })

  it('redacts sensitive keys in plain object args (deep)', () => {
    logger.info('Tag', 'msg', { token: 'abc', nested: { pin: '1234' }, ok: 1 })
    expect(infoSpy).toHaveBeenCalledWith('[Tag]', 'msg', {
      token: '[REDACTED]',
      nested: { pin: '[REDACTED]' },
      ok: 1,
    })
  })

  it('passes primitives through unchanged', () => {
    logger.info('Tag', 'msg', 'plain', 42, true, null)
    expect(infoSpy).toHaveBeenCalledWith('[Tag]', 'msg', 'plain', 42, true, null)
  })

  it('handles circular references without throwing', () => {
    const o: Record<string, unknown> = { a: 1 }
    o.self = o
    expect(() => logger.info('Tag', 'msg', o)).not.toThrow()
    expect(infoSpy).toHaveBeenCalledWith('[Tag]', 'msg', { a: 1, self: '[Circular]' })
  })

  it('heartbeat() sanitizes error args too', () => {
    logger.heartbeat('Hb', 'tick', makeAxiosLikeError())
    const call = warnSpy.mock.calls[0]
    expect(call[0]).toBe('[HEARTBEAT] [Hb]')
    expect(JSON.stringify(call)).not.toContain('Bearer')
  })
})
