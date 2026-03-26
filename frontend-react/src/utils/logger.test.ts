import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { logger } from './logger'

describe('logger', () => {
  let debugSpy: ReturnType<typeof vi.spyOn>
  let infoSpy: ReturnType<typeof vi.spyOn>
  let warnSpy: ReturnType<typeof vi.spyOn>
  let errorSpy: ReturnType<typeof vi.spyOn>

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

  it('error() passes extra args', () => {
    const errObj = new Error('oops')
    logger.error('Tag', 'something failed', errObj)
    expect(errorSpy).toHaveBeenCalledWith('[Tag]', 'something failed', errObj)
  })
})
