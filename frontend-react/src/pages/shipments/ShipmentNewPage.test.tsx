import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import ShipmentNewPage from './ShipmentNewPage'
import { useAuthStore } from '../../stores/authStore'

const mocks = vi.hoisted(() => ({
  branchApi: { listActive: vi.fn() },
  currencyApi: { getActive: vi.fn() },
  shipmentRequestApi: { create: vi.fn(), submit: vi.fn() },
  persistToken: vi.fn(),
  clearPersistedToken: vi.fn(),
}))

vi.mock('../../services/api/index', () => mocks)

describe('ShipmentNewPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    useAuthStore.setState({
      worker: { id: 7, workerCode: 'KOSA', firstName: 'Zoltán', lastName: 'Kósa', fullName: 'Kósa Zoltán', role: 'CASHIER', branchId: 'BR-A', branchCode: 'EBC', branchName: 'Erzsébet körút', companyId: 'C-1', companyCode: 'EXC', companyName: 'Exc Valuta' },
      user: null,
      isAuthenticated: true,
    })
    mocks.branchApi.listActive.mockResolvedValue([
      { id: 'BR-A', code: 'EBC', name: 'Erzsébet körút', isActive: true },
      { id: 'BR-B', code: 'BEL', name: 'Belváros', isActive: true },
    ])
    mocks.currencyApi.getActive.mockResolvedValue([{ id: 4, code: 'EUR', name: 'Euró', decimals: 2, active: true }])
    mocks.shipmentRequestApi.create.mockResolvedValue({ id: 'shipment-1' })
    mocks.shipmentRequestApi.submit.mockResolvedValue({ id: 'shipment-1', requestStatus: 'SUBMITTED' })
  })

  it('creates and submits a shipment request from the real form', async () => {
    const user = userEvent.setup()
    render(<MemoryRouter><ShipmentNewPage /></MemoryRouter>)

    expect(screen.queryByText(/v2\.5\.0-ban érkezik/i)).not.toBeInTheDocument()
    await waitFor(() => expect(screen.getByLabelText(/Cél iroda/i)).not.toBeDisabled())
    await user.selectOptions(screen.getByLabelText(/Cél iroda/i), 'BR-B')
    await user.selectOptions(screen.getByLabelText(/Valuta/i), '4')
    await user.type(screen.getByLabelText(/Összeg/i), '1250')
    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    await waitFor(() => expect(mocks.shipmentRequestApi.create).toHaveBeenCalledWith({
      fromBranchId: 'BR-A',
      toBranchId: 'BR-B',
      deliveryDate: undefined,
      notes: '',
      items: [{ currencyId: '4', requestedAmount: 1250 }],
    }))
    await waitFor(() => expect(mocks.shipmentRequestApi.submit).toHaveBeenCalledWith('shipment-1'))
  })

  it('retries submit without creating a duplicate draft after submit failure', async () => {
    mocks.shipmentRequestApi.submit
      .mockRejectedValueOnce(new Error('submit failed'))
      .mockResolvedValueOnce({ id: 'shipment-1', requestStatus: 'SUBMITTED' })
    const user = userEvent.setup()
    render(<MemoryRouter><ShipmentNewPage /></MemoryRouter>)

    await waitFor(() => expect(screen.getByLabelText(/Cél iroda/i)).not.toBeDisabled())
    await user.selectOptions(screen.getByLabelText(/Cél iroda/i), 'BR-B')
    await user.selectOptions(screen.getByLabelText(/Valuta/i), '4')
    await user.type(screen.getByLabelText(/Összeg/i), '1250')
    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    await waitFor(() => expect(mocks.shipmentRequestApi.submit).toHaveBeenCalledTimes(1))
    await user.click(screen.getByRole('button', { name: /Igény beküldése/i }))

    await waitFor(() => expect(mocks.shipmentRequestApi.submit).toHaveBeenCalledTimes(2))
    expect(mocks.shipmentRequestApi.create).toHaveBeenCalledTimes(1)
  })
})
