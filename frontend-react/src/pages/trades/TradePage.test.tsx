import { act, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TradePage from './TradePage'

const mocks = vi.hoisted(() => ({
  pending: vi.fn(),
  history: vi.fn(),
  propose: vi.fn(),
  accept: vi.fn(),
  reject: vi.fn(),
  complete: vi.fn(),
  cancel: vi.fn(),
  listVaultCounterparties: vi.fn(),
}))

vi.mock('../../services/api', () => ({
  branchApi: {
    listVaultCounterparties: mocks.listVaultCounterparties,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) => selector({
    worker: {
      id: 77,
      workerCode: 'ADMIN',
      fullName: 'Admin Teszt',
      role: 'ADMIN',
      branchId: '11111111-1111-1111-1111-111111111111',
      branchCode: 'BUD01',
      branchName: 'Budapest 01',
      companyId: 'company-1',
      companyCode: 'EBC',
      companyName: 'EBC',
    },
  }),
}))

vi.mock('../../services/api/trades', () => ({
  tradeApi: {
    pending: mocks.pending,
    history: mocks.history,
    propose: mocks.propose,
    accept: mocks.accept,
    reject: mocks.reject,
    complete: mocks.complete,
    cancel: mocks.cancel,
  },
}))

const proposedTrade = {
  id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  fromBranchId: '11111111-1111-1111-1111-111111111111',
  fromBranchName: 'Budapest 01',
  toBranchId: '22222222-2222-2222-2222-222222222222',
  toBranchName: 'Szeged 01',
  currencyCode: 'EUR',
  amount: 1000,
  rate: 394.5,
  status: 'PROPOSED',
  proposedBy: 77,
  proposedAt: '2026-06-19T08:00:00',
  notes: 'Teszt trade',
}

const acceptedTrade = {
  ...proposedTrade,
  id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  status: 'ACCEPTED',
}

async function clickEnabledButton(name: string | RegExp, index = 0): Promise<void> {
  const buttons = await screen.findAllByRole('button', { name })
  const button = buttons[index]
  if (!button) throw new Error(`Button not found: ${String(name)} at index ${index}`)
  await waitFor(() => expect(button).toBeEnabled())
  await act(async () => {
    fireEvent.click(button)
  })
}

describe('TradePage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.pending.mockResolvedValue([proposedTrade, acceptedTrade])
    mocks.history.mockResolvedValue({
      content: [{ ...proposedTrade, status: 'COMPLETED' }],
      totalElements: 1,
      totalPages: 1,
      size: 20,
      number: 0,
    })
    mocks.propose.mockResolvedValue(proposedTrade)
    mocks.accept.mockResolvedValue({ ...proposedTrade, status: 'ACCEPTED' })
    mocks.reject.mockResolvedValue({ ...proposedTrade, status: 'REJECTED' })
    mocks.complete.mockResolvedValue({ ...acceptedTrade, status: 'COMPLETED' })
    mocks.cancel.mockResolvedValue({ ...proposedTrade, status: 'CANCELLED' })
    mocks.listVaultCounterparties.mockResolvedValue({
      territorialCashiers: [{ id: '22222222-2222-2222-2222-222222222222', code: 'SZG01', name: 'Szeged 01' }],
      peerVaults: [],
      fixedCounterparties: [],
    })
  })

  it('pending és history trade-eket a backend szerződésből tölt', async () => {
    render(<TradePage />)

    await waitFor(() => {
      expect(mocks.pending).toHaveBeenCalledWith('11111111-1111-1111-1111-111111111111')
      expect(mocks.history).toHaveBeenCalledWith(expect.objectContaining({
        branchId: '11111111-1111-1111-1111-111111111111',
        size: 20,
      }))
    })
    expect((await screen.findAllByText(/Budapest 01/)).length).toBeGreaterThan(0)
    expect((await screen.findAllByText(/Szeged 01/)).length).toBeGreaterThan(0)
  })

  it('új trade ajánlatot POST /trades/propose szerződésre küld', async () => {
    render(<TradePage />)

    await screen.findByText('Irodaközi trade')
    await waitFor(() => expect(mocks.listVaultCounterparties).toHaveBeenCalled())
    expect(await screen.findByDisplayValue('Budapest 01')).toBeInTheDocument()
    const celIroda = await screen.findByLabelText('Cél iroda')
    fireEvent.change(celIroda, { target: { value: '22222222-2222-2222-2222-222222222222' } })
    const valuta = screen.getByLabelText('Valuta')
    fireEvent.change(valuta, { target: { value: 'usd' } })
    const osszeg = screen.getByLabelText('Összeg')
    fireEvent.change(osszeg, { target: { value: '2500' } })
    const arfolyam = screen.getByLabelText('Árfolyam')
    fireEvent.change(arfolyam, { target: { value: '351.25' } })
    const megjegyzes = screen.getByLabelText('Megjegyzés')
    fireEvent.change(megjegyzes, { target: { value: 'Új ajánlat' } })
    const submitBtn = screen.getByRole('button', { name: /Ajánlat létrehozása/i })
    fireEvent.click(submitBtn)

    await waitFor(() => {
      expect(mocks.propose).toHaveBeenCalledWith({
        fromBranchId: '11111111-1111-1111-1111-111111111111',
        toBranchId: '22222222-2222-2222-2222-222222222222',
        currencyCode: 'USD',
        amount: 2500,
        rate: 351.25,
        notes: 'Új ajánlat',
      })
    })
  })

  it('trade státusz akciókat a megfelelő backend endpointokra küldi', async () => {
    render(<TradePage />)

    expect((await screen.findAllByText('Teszt trade')).length).toBeGreaterThan(0)
    const rejectReason = await screen.findByPlaceholderText('Elutasítás oka')
    fireEvent.change(rejectReason, { target: { value: 'Nincs készlet' } })
    await clickEnabledButton(/Elutasítás/i)
    await waitFor(() => {
      expect(mocks.reject).toHaveBeenCalledWith('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Nincs készlet')
    })
    await clickEnabledButton(/Elfogadás/i)
    await waitFor(() => {
      expect(mocks.accept).toHaveBeenCalledWith('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
    })
    await clickEnabledButton(/Törlés/i)
    await waitFor(() => {
      expect(mocks.cancel).toHaveBeenCalledWith('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
    })
    await clickEnabledButton(/Teljesítés/i)
    await waitFor(() => {
      expect(mocks.complete).toHaveBeenCalledWith('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')
    })
  })
})
