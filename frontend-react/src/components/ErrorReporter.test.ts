import { beforeEach, describe, expect, it, vi } from 'vitest'

const mocks = vi.hoisted(() => ({
  post: vi.fn(),
}))

vi.mock('../services/api/client', () => ({
  api: {
    post: mocks.post,
  },
}))

describe('ErrorReporter', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
  })

  it('elsodlegesen a diagnostics error-report backend szerzodest hivja', async () => {
    mocks.post.mockResolvedValueOnce({ data: { ok: true } })
    const { sendErrorReport } = await import('./ErrorReporter')

    await sendErrorReport({
      errorType: 'react_error_boundary',
      message: 'Teszt hiba',
      stack: 'Error: Teszt hiba',
      severity: 'CRITICAL',
      url: 'https://app.example.test/mobile',
    })

    expect(mocks.post).toHaveBeenCalledTimes(1)
    expect(mocks.post).toHaveBeenCalledWith('/diagnostics/error-report', {
      component: 'electron-renderer',
      version: 'test',
      osInfo: expect.any(String),
      errorMessage: 'Teszt hiba',
      stackTrace: 'Error: Teszt hiba',
      context: expect.objectContaining({
        errorType: 'react_error_boundary',
        message: 'Teszt hiba',
        severity: 'CRITICAL',
        url: 'https://app.example.test/mobile',
      }),
    })
  })

  it('diagnostics hiba eseten megtartja a legacy emailes error-report fallbacket', async () => {
    mocks.post
      .mockRejectedValueOnce(new Error('diagnostics down'))
      .mockResolvedValueOnce({ data: { ok: true } })
    const { sendErrorReport } = await import('./ErrorReporter')

    await sendErrorReport({ message: 'Fallback hiba' })

    expect(mocks.post).toHaveBeenCalledTimes(2)
    expect(mocks.post).toHaveBeenNthCalledWith(1, '/diagnostics/error-report', expect.any(Object))
    expect(mocks.post).toHaveBeenNthCalledWith(
      2,
      '/error-report',
      expect.objectContaining({
        message: 'Fallback hiba',
        errorType: 'frontend_error',
      }),
    )
  })
})
