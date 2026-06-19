import { fireEvent, render, screen, waitFor } from '@testing-library/react'
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
    expect(screen.getAllByText(/Budapest 01/).length).toBeGreaterThan(0)
    expect(screen.getAllByText(/Szeged 01/).length).toBeGreaterThan(0)
  })

  it('új trade ajánlatot POST /trades/propose szerződésre küld', async () => {
    render(<TradePage />)

    await screen.findByText('Irodaközi trade')
    fireEvent.change(screen.getByLabelText('Cél iroda UUID'), { target: { value: '22222222-2222-2222-2222-222222222222' } })
    fireEvent.change(screen.getByLabelText('Valuta'), { target: { value: 'usd' } })
    fireEvent.change(screen.getByLabelText('Összeg'), { target: { value: '2500' } })
    fireEvent.change(screen.getByLabelText('Árfolyam'), { target: { value: '351.25' } })
    fireEvent.change(screen.getByLabelText('Megjegyzés'), { target: { value: 'Új ajánlat' } })
    fireEvent.click(screen.getByRole('button', { name: /Ajánlat létrehozása/i }))

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
    fireEvent.change(screen.getByPlaceholderText('Elutasítás oka'), { target: { value: 'Nincs készlet' } })
    fireEvent.click(screen.getAllByRole('button', { name: /Elutasítás/i })[0] as HTMLElement)
    await waitFor(() => {
      expect(mocks.reject).toHaveBeenCalledWith('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Nincs készlet')
    })
    fireEvent.click(screen.getAllByRole('button', { name: /Elfogadás/i })[0] as HTMLElement)
    await waitFor(() => {
      expect(mocks.accept).toHaveBeenCalledWith('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
    })
    fireEvent.click(screen.getAllByRole('button', { name: /Törlés/i })[0] as HTMLElement)
    await waitFor(() => {
      expect(mocks.cancel).toHaveBeenCalledWith('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')
    })
    fireEvent.click(screen.getAllByRole('button', { name: /Teljesítés/i })[0] as HTMLElement)
    await waitFor(() => {
      expect(mocks.complete).toHaveBeenCalledWith('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')
    })
  })
})
