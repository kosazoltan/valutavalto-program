import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import AuditDiagnosticsPage from './AuditDiagnosticsPage'

const mocks = vi.hoisted(() => ({
  recent: vi.fn(),
  recentErrors: vi.fn(),
  byTrace: vi.fn(),
  entityChain: vi.fn(),
  errorCodes: vi.fn(),
  verifyHashChain: vi.fn(),
  staticAudit: vi.fn(),
  diagnosticsHealth: vi.fn(),
  vvLoggerError: vi.fn(),
  vvLoggerWarn: vi.fn(),
}))

vi.mock('../../services/api/diagnostics', () => ({
  diagnosticsApi: {
    health: mocks.diagnosticsHealth,
  },
  auditDiagnosticsApi: {
    recent: mocks.recent,
    recentErrors: mocks.recentErrors,
    byTrace: mocks.byTrace,
    entityChain: mocks.entityChain,
    errorCodes: mocks.errorCodes,
    verifyHashChain: mocks.verifyHashChain,
    staticAudit: mocks.staticAudit,
  },
}))

vi.mock('../../utils/vvLogger', () => ({
  vvLogger: {
    error: mocks.vvLoggerError,
    warn: mocks.vvLoggerWarn,
  },
}))

describe('AuditDiagnosticsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.recent.mockResolvedValue([
      {
        id: 'audit-1',
        ts: '2026-06-19T08:00:00',
        eventType: 'LOGIN',
        entityType: 'Worker',
        entityId: 'worker-1',
        userName: 'Admin Teszt',
        traceId: 'trace-1',
      },
    ])
    mocks.recentErrors.mockResolvedValue([
      {
        id: 'audit-error-1',
        ts: '2026-06-19T08:02:00',
        eventType: 'CLIENT_ERROR',
        action: 'ERROR',
        entityType: 'client_log',
        entityId: 'client-1',
        userName: 'Admin Teszt',
        traceId: 'trace-error-1',
      },
    ])
    mocks.errorCodes.mockResolvedValue({
      version: '1',
      totalCodes: 1,
      codes: [
        {
          code: 'VV-TECH-002',
          name: 'Technikai hiba',
          category: 'TECH',
          level: 'ERROR',
          userImpact: 'Admin vizsgalat szukseges',
        },
      ],
    })
    mocks.diagnosticsHealth.mockResolvedValue({
      ok: true,
      totalReportedErrors: 12,
    })
    mocks.verifyHashChain.mockResolvedValue({
      checkedCount: 10,
      intact: true,
      message: 'OK',
    })
    mocks.entityChain.mockResolvedValue([
      {
        id: 'entity-audit-1',
        ts: '2026-06-19T08:03:00',
        eventType: 'ENTITY_UPDATED',
        entityType: 'Worker',
        entityId: 'worker-1',
      },
    ])
    mocks.staticAudit.mockResolvedValue([
      { name: 'DB connection', pass: true, detail: 'OK' },
      { name: 'spring.mail.password', pass: false, detail: 'MISSING' },
    ])
  })

  it('betolti az audit diagnosztikat es static auditot futtat admin tokennel', async () => {
    const user = userEvent.setup()

    render(<AuditDiagnosticsPage />)

    expect(await screen.findByText('Audit Diagnosztika (V234)')).toBeInTheDocument()
    expect(mocks.recent).toHaveBeenCalledWith(100)
    expect(mocks.recentErrors).toHaveBeenCalledWith(100)
    expect(mocks.errorCodes).toHaveBeenCalled()
    expect(mocks.diagnosticsHealth).toHaveBeenCalled()
    const healthPanel = screen.getByTestId('diagnostics-health-panel')
    expect(within(healthPanel).getByText('Diagnostics ingest')).toBeInTheDocument()
    expect(within(healthPanel).getByText('DB-ben rögzített klienshibák')).toBeInTheDocument()
    expect(within(healthPanel).getByText('12')).toBeInTheDocument()
    expect(screen.getByText('Hibas audit-esemenyek')).toBeInTheDocument()
    expect(screen.getByText('CLIENT_ERROR')).toBeInTheDocument()

    await user.type(screen.getByPlaceholderText('Static audit admin token'), 'token-1')
    await user.click(screen.getByRole('button', { name: 'Static audit futtatasa' }))

    await waitFor(() => {
      expect(mocks.staticAudit).toHaveBeenCalledWith('token-1')
    })

    const results = await screen.findByTestId('static-audit-results')
    expect(within(results).getByText('DB connection')).toBeInTheDocument()
    expect(within(results).getByText('spring.mail.password')).toBeInTheDocument()
    expect(within(results).getByText('MISSING')).toBeInTheDocument()
    expect(within(results).getAllByText('OK').length).toBeGreaterThan(0)
  })

  it('hash-chain ellenorzest a meglovo backend wrapperre koti', async () => {
    const user = userEvent.setup()

    render(<AuditDiagnosticsPage />)

    await screen.findByText('Audit Diagnosztika (V234)')
    await user.click(screen.getByRole('button', { name: 'Ellenorzes (utolso 200)' }))

    await waitFor(() => {
      expect(mocks.verifyHashChain).toHaveBeenCalledWith(200)
      expect(screen.getByText('OK - chain ertintetlen')).toBeInTheDocument()
    })
  })

  it('entity audit-lanc keresest a backend wrapperre koti', async () => {
    const user = userEvent.setup()

    render(<AuditDiagnosticsPage />)

    await screen.findByText('Audit Diagnosztika (V234)')
    await user.type(screen.getByPlaceholderText('entityType'), 'Worker')
    await user.type(screen.getByPlaceholderText('entityId'), 'worker-1')
    await user.click(screen.getByRole('button', { name: 'Audit-lanc' }))

    await waitFor(() => {
      expect(mocks.entityChain).toHaveBeenCalledWith('Worker', 'worker-1')
      expect(screen.getByTestId('entity-chain-results')).toHaveTextContent('ENTITY_UPDATED')
    })
  })
})
