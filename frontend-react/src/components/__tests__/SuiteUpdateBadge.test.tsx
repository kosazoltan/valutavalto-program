/**
 * SuiteUpdateBadge — explicit install (kanban #7) AND the visible failure
 * surface for a failed suite install (kanban #8).
 *
 * WHY: before kanban #8 a failed install was invisible (state silently reverted
 * to READY). The badge must show an error variant with the version and the
 * installer path so a non-admin colleague can report it — and the ready badge
 * must NOT be confused with a failure. The error variant ALSO renders the
 * install-now control so the cashier can retry the prompt (Design Decision 4:
 * canStartInstallOnDemand accepts INSTALL_FAILED "so the banner can retry").
 *
 * The three kanban #7 T-button cases are restored verbatim — they pin the
 * ready-path install-now behaviour and must never be dropped or weakened.
 */
import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import SuiteUpdateBadge from '../SuiteUpdateBadge'
import type { SuiteUpdateReady } from '../../hooks/useSuiteUpdate'

const startInstallMock = vi.fn(() => Promise.resolve({ started: true }))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, params?: Record<string, unknown>) =>
      params ? `${key}:${JSON.stringify(params)}` : key,
  }),
}))

vi.mock('../../utils/electron', () => ({
  getElectronAPI: () => ({
    suiteUpdate: {
      startInstall: () => startInstallMock(),
    },
  }),
}))

vi.mock('../../utils/logger', () => ({
  logger: { info: vi.fn(), warn: vi.fn(), error: vi.fn() },
}))

const ready: SuiteUpdateReady = {
  version: '2.28.96',
  mandatory: false,
  notes: null,
  installableNow: true,
}

beforeEach(() => {
  startInstallMock.mockClear()
  vi.stubGlobal('confirm', vi.fn())
})

describe('SuiteUpdateBadge — explicit install (kanban #7)', () => {
  // Faithful to the base fixture: installableNow=false proves the explicit
  // T-button install works even while the badge shows the "waiting" variant.
  const readyShiftOpen = {
    version: '2.28.96',
    mandatory: false,
    notes: null,
    installableNow: false,
  }

  it('T-button: confirm true -> startInstall once even when SHIFT_OPEN', () => {
    vi.mocked(window.confirm).mockReturnValue(true)
    render(<SuiteUpdateBadge readyUpdate={readyShiftOpen} />)
    fireEvent.click(screen.getByTestId('suite-update-install-now'))
    expect(startInstallMock).toHaveBeenCalledTimes(1)
  })

  it('T-button-cancel: confirm false -> startInstall not called', () => {
    vi.mocked(window.confirm).mockReturnValue(false)
    render(<SuiteUpdateBadge readyUpdate={readyShiftOpen} />)
    fireEvent.click(screen.getByTestId('suite-update-install-now'))
    expect(startInstallMock).not.toHaveBeenCalled()
  })

  it('T-button-absent: readyUpdate null -> no badge, no install-now', () => {
    const { container } = render(<SuiteUpdateBadge readyUpdate={null} />)
    expect(container.querySelector('[data-testid="suite-update-badge"]')).toBeNull()
    expect(container.querySelector('[data-testid="suite-update-install-now"]')).toBeNull()
  })
})

describe('SuiteUpdateBadge — failure surface (kanban #8)', () => {
  it('renders nothing without readyUpdate and without installFailure', () => {
    const { container } = render(<SuiteUpdateBadge readyUpdate={null} />)
    expect(container.firstChild).toBeNull()
  })

  it('renders the ready badge for a readyUpdate', () => {
    render(<SuiteUpdateBadge readyUpdate={ready} />)
    expect(screen.getByTestId('suite-update-badge')).toBeDefined()
  })

  it('renders the error variant with the version and installer path', () => {
    render(
      <SuiteUpdateBadge
        readyUpdate={ready}
        installFailure={{
          version: '2.28.96',
          reason: 'ELEVATION_REFUSED',
          installerPath: 'C:\\cache\\Penztar-Setup-2.28.96.exe',
        }}
      />,
    )
    const failed = screen.getByTestId('suite-update-failed')
    expect(failed.textContent).toContain('suiteUpdate.installFailedElevation')
    expect(failed.textContent).toContain('2.28.96')
    // The mock t() JSON-stringifies params, so backslashes render doubled.
    expect(failed.textContent).toContain('C:\\\\cache\\\\Penztar-Setup-2.28.96.exe')
    // The ready badge must not be shown alongside the failure.
    expect(screen.queryByTestId('suite-update-badge')).toBeNull()
  })

  it('uses the generic installFailed text for non-elevation failures', () => {
    render(
      <SuiteUpdateBadge
        readyUpdate={ready}
        installFailure={{
          version: '2.28.96',
          reason: 'LAUNCH_FAILED',
          installerPath: 'C:\\cache\\Penztar-Setup-2.28.96.exe',
        }}
      />,
    )
    expect(screen.getByTestId('suite-update-failed').textContent).toContain(
      'suiteUpdate.installFailed',
    )
  })
})

describe('SuiteUpdateBadge — error variant retry (kanban #8)', () => {
  const failure = {
    version: '2.28.96',
    reason: 'ELEVATION_REFUSED',
    installerPath: 'C:\\cache\\Penztar-Setup-2.28.96.exe',
  }

  it('error variant renders the install-now control', () => {
    render(<SuiteUpdateBadge readyUpdate={null} installFailure={failure} />)
    expect(screen.getByTestId('suite-update-failed')).toBeDefined()
    expect(screen.getByTestId('suite-update-install-now')).toBeDefined()
  })

  it('error variant: confirm true -> startInstall once', () => {
    vi.mocked(window.confirm).mockReturnValue(true)
    render(<SuiteUpdateBadge readyUpdate={null} installFailure={failure} />)
    fireEvent.click(screen.getByTestId('suite-update-install-now'))
    expect(startInstallMock).toHaveBeenCalledTimes(1)
  })

  it('error variant: confirm false -> startInstall not called', () => {
    vi.mocked(window.confirm).mockReturnValue(false)
    render(<SuiteUpdateBadge readyUpdate={null} installFailure={failure} />)
    fireEvent.click(screen.getByTestId('suite-update-install-now'))
    expect(startInstallMock).not.toHaveBeenCalled()
  })
})
