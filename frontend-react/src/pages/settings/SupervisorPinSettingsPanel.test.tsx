import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import SupervisorPinSettingsPanel from './SupervisorPinSettingsPanel'

const mocks = vi.hoisted(() => ({
  setPin: vi.fn(),
  clearPin: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  supervisorPinApi: {
    set: mocks.setPin,
    clear: mocks.clearPin,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

describe('SupervisorPinSettingsPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.setPin.mockResolvedValue({ ok: true, message: 'PIN beállítva' })
    mocks.clearPin.mockResolvedValue({ ok: true, message: 'PIN törölve' })
  })

  it('jelenlegi jelszóval és PIN-nel meghívja a supervisor-pin set backend szerződést', async () => {
    const user = userEvent.setup()
    render(<SupervisorPinSettingsPanel />)

    await user.type(screen.getByLabelText('Jelenlegi jelszó'), 'current-password')
    await user.type(screen.getByLabelText('Új PIN'), '1234')
    await user.type(screen.getByLabelText('PIN ismét'), '1234')
    await user.click(screen.getByRole('button', { name: 'PIN beállítása' }))

    await waitFor(() => {
      expect(mocks.setPin).toHaveBeenCalledWith('current-password', '1234')
    })
    expect(await screen.findByText('PIN beállítva')).toBeInTheDocument()
  })

  it('jelenlegi jelszóval meghívja a supervisor-pin clear backend szerződést', async () => {
    const user = userEvent.setup()
    render(<SupervisorPinSettingsPanel />)

    await user.type(screen.getByLabelText('Jelenlegi jelszó'), 'current-password')
    await user.click(screen.getByRole('button', { name: 'PIN törlése' }))

    await waitFor(() => {
      expect(mocks.clearPin).toHaveBeenCalledWith('current-password')
    })
    expect(await screen.findByText('PIN törölve')).toBeInTheDocument()
  })

  it('érvénytelen PIN esetén nem hív backend műveletet', async () => {
    const user = userEvent.setup()
    render(<SupervisorPinSettingsPanel />)

    await user.type(screen.getByLabelText('Jelenlegi jelszó'), 'current-password')
    await user.type(screen.getByLabelText('Új PIN'), '12ab')
    await user.type(screen.getByLabelText('PIN ismét'), '12ab')
    await user.click(screen.getByRole('button', { name: 'PIN beállítása' }))

    expect(mocks.setPin).not.toHaveBeenCalled()
    expect(screen.getByText('A supervisor PIN 4-6 számjegy legyen.')).toBeInTheDocument()
  })

  it('PIN-set hiba: a logolt argumentumok nem tartalmazzák a PIN-t/jelszót', async () => {
    const user = userEvent.setup()
    mocks.setPin.mockRejectedValue(
      Object.assign(new Error('Request failed with status code 401'), {
        isAxiosError: true,
        config: {
          url: '/supervisor-pin/set',
          data: JSON.stringify({ currentPassword: 'Titok-1', pin: '445566' }),
        },
        response: { status: 401 },
      }),
    )
    render(<SupervisorPinSettingsPanel />)

    await user.type(screen.getByLabelText('Jelenlegi jelszó'), 'Titok-1')
    await user.type(screen.getByLabelText('Új PIN'), '445566')
    await user.type(screen.getByLabelText('PIN ismét'), '445566')
    await user.click(screen.getByRole('button', { name: 'PIN beállítása' }))

    await waitFor(() => expect(mocks.loggerError).toHaveBeenCalled())
    const logged = JSON.stringify(mocks.loggerError.mock.calls)
    expect(logged).not.toContain('445566')
    expect(logged).not.toContain('Titok-1')
  })
})
