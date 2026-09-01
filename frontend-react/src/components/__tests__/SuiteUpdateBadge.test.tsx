import { fireEvent, render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import SuiteUpdateBadge from '../SuiteUpdateBadge'

const startInstallMock = vi.fn(() => Promise.resolve({ started: true }))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, opts?: { version?: string }) =>
      opts?.version ? `${key}:${opts.version}` : key,
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

const ready = {
  version: '2.28.96',
  mandatory: false,
  notes: null,
  installableNow: false,
}

describe('SuiteUpdateBadge — explicit install (kanban #7)', () => {
  beforeEach(() => {
    startInstallMock.mockClear()
    vi.stubGlobal('confirm', vi.fn())
  })

  it('T-button: confirm true -> startInstall once even when SHIFT_OPEN', () => {
    vi.mocked(window.confirm).mockReturnValue(true)
    render(<SuiteUpdateBadge readyUpdate={ready} />)
    fireEvent.click(screen.getByTestId('suite-update-install-now'))
    expect(startInstallMock).toHaveBeenCalledTimes(1)
  })

  it('T-button-cancel: confirm false -> startInstall not called', () => {
    vi.mocked(window.confirm).mockReturnValue(false)
    render(<SuiteUpdateBadge readyUpdate={ready} />)
    fireEvent.click(screen.getByTestId('suite-update-install-now'))
    expect(startInstallMock).not.toHaveBeenCalled()
  })

  it('T-button-absent: readyUpdate null -> no badge, no install-now', () => {
    const { container } = render(<SuiteUpdateBadge readyUpdate={null} />)
    expect(container.querySelector('[data-testid="suite-update-badge"]')).toBeNull()
    expect(container.querySelector('[data-testid="suite-update-install-now"]')).toBeNull()
  })
})
