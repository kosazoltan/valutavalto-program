/**
 * E-B8 (#279) — BankOrderPage sürgősségi deep-link tesztek.
 * A Készlet pillanatkép „Sürgősségi banki kivét" gombja ?create=1&urgency=EMERGENCY
 * paraméterekkel nyitja elő az új-rendelés formot.
 */
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import BankOrderPage from './BankOrderPage'

const mockList = vi.fn()
const mockBankOrderGet = vi.fn()
const mockGet = vi.fn()
const mockPost = vi.fn()

vi.mock('../../services/api/bankOrders', async (importOriginal) => {
  const original = await importOriginal<typeof import('../../services/api/bankOrders')>()
  return {
    ...original,
    bankOrdersApi: {
      ...original.bankOrdersApi,
      list: (...args: unknown[]) => mockList(...args),
      get: (...args: unknown[]) => mockBankOrderGet(...args),
    },
  }
})

vi.mock('../../services/api', () => ({
  api: {
    get: (...args: unknown[]) => mockGet(...args),
    post: (...args: unknown[]) => mockPost(...args),
    put: vi.fn(),
    delete: vi.fn(),
    patch: vi.fn(),
  },
}))

function mockApi() {
  mockList.mockResolvedValue({ content: [], totalElements: 0, totalPages: 0, number: 0, size: 50 })
  mockBankOrderGet.mockResolvedValue({
    id: 'order-1',
    branchId: 'branch-1',
    branchCode: 'BUD01',
    branchName: 'Budapest 01',
    currencyId: 2,
    currencyCode: 'EUR',
    amount: '2500',
    status: 'APPROVED',
    urgency: 'URGENT',
    requestedByWorkerId: 77,
    requestedByWorkerName: 'Kérő dolgozó',
    requestedAt: '2026-06-19T08:00:00.000Z',
    approvedByWorkerName: 'Jóváhagyó vezető',
    executedByWorkerName: 'Értéktár kezelő',
    bankReference: 'BANK-DETAIL-001',
    notes: 'Backend részletes banki rendelés megjegyzés',
  })
  mockGet.mockImplementation((url: string) => {
    if (url === '/western-union/daily-limit') {
      return Promise.resolve({
        data: {
          businessDate: '2026-06-11',
          currencyCode: 'USD',
          dailyLimit: 10000,
          usedAmount: 0,
          remainingAmount: 10000,
          usagePercent: 0,
        },
      })
    }
    if (url === '/branches') {
      return Promise.resolve({
        data: [{ id: 'b1', code: 'BR105', name: 'Békéscsaba', isActive: true }],
      })
    }
    if (url === '/currencies') {
      return Promise.resolve({ data: [{ id: 1, code: 'EUR', name: 'Euró', isActive: true }] })
    }
    return Promise.resolve({ data: [] })
  })
}

function renderPage(initialEntry: string) {
  return render(
    <MemoryRouter initialEntries={[initialEntry]}>
      <BankOrderPage />
    </MemoryRouter>,
  )
}

describe('BankOrderPage — E-B8 sürgősségi deep-link', () => {
  beforeEach(() => {
    mockList.mockReset()
    mockBankOrderGet.mockReset()
    mockGet.mockReset()
    mockPost.mockReset()
    mockApi()
    mockPost.mockResolvedValue({
      data: {
        businessDate: '2026-06-11',
        currencyCode: 'USD',
        dailyLimit: 10000,
        usedAmount: 250,
        remainingAmount: 9750,
        usagePercent: 2.5,
      },
    })
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  it('?create=1&urgency=EMERGENCY: form nyitva, sürgősség = Azonnali, referencia-adat betöltve', async () => {
    renderPage('/bank-orders?create=1&urgency=EMERGENCY')
    await waitFor(() => expect(screen.getByText('Új banki rendelés')).toBeInTheDocument())
    expect(screen.getByLabelText('Sürgősség')).toHaveValue('EMERGENCY')
    // a deep-link is betölti az iroda/valuta listát (openCreate-tel ekvivalens)
    await waitFor(() => expect(mockGet).toHaveBeenCalledWith('/branches'))
    expect(mockGet).toHaveBeenCalledWith('/currencies')
  })

  it('érvénytelen urgency paraméter: NORMAL-ra esik vissza', async () => {
    renderPage('/bank-orders?create=1&urgency=HACK')
    await waitFor(() => expect(screen.getByText('Új banki rendelés')).toBeInTheDocument())
    expect(screen.getByLabelText('Sürgősség')).toHaveValue('NORMAL')
  })

  it('paraméter nélkül a form zárva marad', async () => {
    renderPage('/bank-orders')
    await waitFor(() => expect(mockList).toHaveBeenCalled())
    expect(screen.queryByText('Új banki rendelés')).not.toBeInTheDocument()
  })

  it('WU napi keret kézi fallback felhasználását backend POST szerződésre köti', async () => {
    const user = userEvent.setup()
    renderPage('/bank-orders')

    await screen.findByText('Western Union napi keret')
    await user.type(screen.getByLabelText(/Kézi fallback felhasználás/i), '250')
    await user.click(screen.getByRole('button', { name: /Keret felhasználás/i }))

    await waitFor(() => {
      expect(mockPost).toHaveBeenCalledWith('/western-union/daily-limit/use', {
        amountUsd: 250,
        businessDate: '2026-06-11',
      })
    })
  })

  it('részletek megnyitásakor a banki rendelés detail endpointot használja', async () => {
    const user = userEvent.setup()
    mockList.mockResolvedValue({
      content: [
        {
          id: 'order-1',
          branchId: 'branch-1',
          branchCode: 'BUD01',
          branchName: 'Budapest 01',
          currencyId: 2,
          currencyCode: 'EUR',
          amount: '1000',
          status: 'APPROVED',
          urgency: 'NORMAL',
          requestedByWorkerId: 77,
          requestedByWorkerName: 'Lista kérő',
          requestedAt: '2026-06-19T08:00:00.000Z',
        },
      ],
      totalElements: 1,
      totalPages: 1,
      number: 0,
      size: 50,
    })

    renderPage('/bank-orders')

    await screen.findByText('BUD01')
    await user.click(screen.getByRole('button', { name: /Részletek/i }))

    await waitFor(() => expect(mockBankOrderGet).toHaveBeenCalledWith('order-1'))
    expect(
      await screen.findByText('Backend részletes banki rendelés megjegyzés'),
    ).toBeInTheDocument()
    expect(screen.getByText('BANK-DETAIL-001')).toBeInTheDocument()
  })
})
