import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import ValueBandSettingsPage from './ValueBandSettingsPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  create: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  valueBandApi: {
    list: mocks.list,
    create: mocks.create,
    update: vi.fn(),
    remove: vi.fn(),
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    error: mocks.toastError,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

describe('ValueBandSettingsPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue([
      {
        id: 'past-1',
        simplifiedIdentificationLimitHuf: 100000,
        identificationLimitHuf: 300000,
        incomeProofLimitHuf: 10000000,
        rollingWindowDays: 8,
        effectiveFrom: '2020-01-01',
        createdBy: 'seed',
      },
      {
        id: 'future-1',
        simplifiedIdentificationLimitHuf: 150000,
        identificationLimitHuf: 350000,
        incomeProofLimitHuf: 11000000,
        rollingWindowDays: 7,
        effectiveFrom: '2099-01-01',
      },
    ])
    mocks.create.mockResolvedValue({ id: 'new-1' })
  })

  it('betölti és megjeleníti az értéksávokat státusz badge-dzsel', async () => {
    render(<ValueBandSettingsPage />)

    expect(await screen.findByText('AML értéksávok')).toBeInTheDocument()
    expect(screen.getByText('HATÁLYOS')).toBeInTheDocument()
    expect(screen.getByText('JÖVŐBELI')).toBeInTheDocument()
    expect(screen.getByText('300 000 Ft')).toBeInTheDocument()
  })

  it('új jövőbeli sávot kliens-validáció után létrehoz', async () => {
    const user = userEvent.setup()
    render(<ValueBandSettingsPage />)

    await screen.findByText('AML értéksávok')
    await user.clear(screen.getByLabelText('Egyszerűsített azonosítási küszöb'))
    await user.type(screen.getByLabelText('Egyszerűsített azonosítási küszöb'), '120000')
    await user.clear(screen.getByLabelText('Teljes azonosítási küszöb'))
    await user.type(screen.getByLabelText('Teljes azonosítási küszöb'), '320000')
    await user.clear(screen.getByLabelText('Jövedelemforrás / fokozott küszöb'))
    await user.type(screen.getByLabelText('Jövedelemforrás / fokozott küszöb'), '10000000')
    await user.clear(screen.getByLabelText('Göngyölési ablak napok'))
    await user.type(screen.getByLabelText('Göngyölési ablak napok'), '8')
    fireEvent.change(screen.getByLabelText('Érvényesség kezdete'), { target: { value: '2099-02-01' } })
    await user.click(screen.getByRole('button', { name: /Új sáv mentése/i }))

    await waitFor(() => {
      expect(mocks.create).toHaveBeenCalledWith({
        simplifiedIdentificationLimitHuf: 120000,
        identificationLimitHuf: 320000,
        incomeProofLimitHuf: 10000000,
        rollingWindowDays: 8,
        effectiveFrom: '2099-02-01',
      })
    })
  })

  it('hatályos/múltbeli soron nincs szerkesztés vagy törlés gomb', async () => {
    render(<ValueBandSettingsPage />)

    await screen.findByText('HATÁLYOS')
    const pastRow = screen.getByTestId('value-band-row-past-1')
    expect(pastRow).not.toHaveTextContent('Szerkesztés')
    expect(pastRow).not.toHaveTextContent('Törlés')
  })
})
