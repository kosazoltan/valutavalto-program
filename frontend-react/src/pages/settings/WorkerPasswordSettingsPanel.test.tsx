import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import WorkerPasswordSettingsPanel from './WorkerPasswordSettingsPanel'

const mocks = vi.hoisted(() => ({
  changeOwn: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({ worker: { id: 77, fullName: 'Teszt Dolgozó' } }),
}))

vi.mock('../../services/api/settings', () => ({
  workerPasswordApi: {
    changeOwn: mocks.changeOwn,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

describe('WorkerPasswordSettingsPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.changeOwn.mockResolvedValue(undefined)
  })

  it('a bejelentkezett worker id-val meghívja a WorkerController jelszóváltó szerződést', async () => {
    const user = userEvent.setup()
    render(<WorkerPasswordSettingsPanel />)

    await user.type(screen.getByLabelText('Jelenlegi jelszó'), 'old-password')
    await user.type(screen.getByLabelText('Új jelszó'), 'NewPass123')
    await user.type(screen.getByLabelText('Új jelszó ismét'), 'NewPass123')
    await user.click(screen.getByRole('button', { name: 'Jelszó módosítása' }))

    await waitFor(() => {
      expect(mocks.changeOwn).toHaveBeenCalledWith(77, 'old-password', 'NewPass123')
    })
    expect(await screen.findByText('Saját jelszó módosítva.')).toBeInTheDocument()
  })

  it('rövid új jelszó esetén nem hív backend műveletet', async () => {
    const user = userEvent.setup()
    render(<WorkerPasswordSettingsPanel />)

    await user.type(screen.getByLabelText('Jelenlegi jelszó'), 'old-password')
    await user.type(screen.getByLabelText('Új jelszó'), 'short')
    await user.type(screen.getByLabelText('Új jelszó ismét'), 'short')
    await user.click(screen.getByRole('button', { name: 'Jelszó módosítása' }))

    expect(mocks.changeOwn).not.toHaveBeenCalled()
    expect(screen.getByText('Az új jelszó 8-128 karakter legyen.')).toBeInTheDocument()
  })
})
