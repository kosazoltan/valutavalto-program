import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import ValueBandSettingsPage from './ValueBandSettingsPage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  remove: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  valueBandApi: {
    list: mocks.list,
    create: mocks.create,
    update: mocks.update,
    remove: mocks.remove,
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
    vi.resetAllMocks()
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
    mocks.update.mockResolvedValue({ id: 'future-1' })
    mocks.remove.mockResolvedValue(undefined)
  })

  afterEach(() => {
    vi.restoreAllMocks()
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
    fireEvent.change(screen.getByLabelText('Érvényesség kezdete'), {
      target: { value: '2099-02-01' },
    })
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

  it('jövőbeli sáv törlése után újratölti a listát és eltűnik a sor', async () => {
    const user = userEvent.setup()
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    mocks.list
      .mockResolvedValueOnce([
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
      .mockResolvedValueOnce([
        {
          id: 'past-1',
          simplifiedIdentificationLimitHuf: 100000,
          identificationLimitHuf: 300000,
          incomeProofLimitHuf: 10000000,
          rollingWindowDays: 8,
          effectiveFrom: '2020-01-01',
          createdBy: 'seed',
        },
      ])

    render(<ValueBandSettingsPage />)

    const futureRow = await screen.findByTestId('value-band-row-future-1')
    await user.click(within(futureRow).getByRole('button', { name: /Törlés/i }))

    await waitFor(() => {
      expect(mocks.remove).toHaveBeenCalledWith('future-1')
    })
    expect(mocks.list).toHaveBeenCalledTimes(2)
    await waitFor(() => {
      expect(screen.queryByTestId('value-band-row-future-1')).not.toBeInTheDocument()
    })
  })

  it('jövőbeli sáv szerkesztése a sor értékeivel tölti az űrlapot és update-et hív', async () => {
    const user = userEvent.setup()
    render(<ValueBandSettingsPage />)

    const futureRow = await screen.findByTestId('value-band-row-future-1')
    await user.click(within(futureRow).getByRole('button', { name: /Szerkesztés/i }))

    expect(screen.getByLabelText('Egyszerűsített azonosítási küszöb')).toHaveValue(150000)
    expect(screen.getByLabelText('Teljes azonosítási küszöb')).toHaveValue(350000)
    expect(screen.getByLabelText('Jövedelemforrás / fokozott küszöb')).toHaveValue(11000000)
    expect(screen.getByLabelText('Göngyölési ablak napok')).toHaveValue(7)
    expect(screen.getByLabelText('Érvényesség kezdete')).toHaveValue('2099-01-01')

    await user.clear(screen.getByLabelText('Egyszerűsített azonosítási küszöb'))
    await user.type(screen.getByLabelText('Egyszerűsített azonosítási küszöb'), '160000')
    await user.click(screen.getByRole('button', { name: /Módosítás mentése/i }))

    await waitFor(() => {
      expect(mocks.update).toHaveBeenCalledWith('future-1', {
        simplifiedIdentificationLimitHuf: 160000,
        identificationLimitHuf: 350000,
        incomeProofLimitHuf: 11000000,
        rollingWindowDays: 7,
        effectiveFrom: '2099-01-01',
      })
    })
    expect(mocks.create).not.toHaveBeenCalled()
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /Új sáv mentése/i })).toBeInTheDocument()
    })
  })

  it('szerkesztési módban a Mégse visszaáll új sáv módba API hívás nélkül', async () => {
    const user = userEvent.setup()
    render(<ValueBandSettingsPage />)

    const futureRow = await screen.findByTestId('value-band-row-future-1')
    await user.click(within(futureRow).getByRole('button', { name: /Szerkesztés/i }))
    await user.click(screen.getByRole('button', { name: /Mégse/i }))

    expect(screen.getByRole('button', { name: /Új sáv mentése/i })).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Mégse/i })).not.toBeInTheDocument()
    expect(mocks.create).not.toHaveBeenCalled()
    expect(mocks.update).not.toHaveBeenCalled()
    expect(mocks.remove).not.toHaveBeenCalled()
  })
})
