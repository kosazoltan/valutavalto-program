/**
 * SuiteUpdateBadge — the visible failure surface for a failed suite install.
 *
 * WHY: before kanban #8 a failed install was invisible (state silently reverted
 * to READY). The badge must show an error variant with the version and the
 * installer path so a non-admin colleague can report it — and the ready badge
 * must NOT be confused with a failure.
 */
import { describe, it, expect, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import SuiteUpdateBadge from '../SuiteUpdateBadge'
import type { SuiteUpdateReady } from '../../hooks/useSuiteUpdate'

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, params?: Record<string, unknown>) =>
      params ? `${key}:${JSON.stringify(params)}` : key,
  }),
}))

vi.mock('../../utils/electron', () => ({
  getElectronAPI: () => undefined,
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
