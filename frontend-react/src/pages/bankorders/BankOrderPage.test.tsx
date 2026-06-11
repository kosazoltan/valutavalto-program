/**
 * E-B8 (#279) — BankOrderPage sürgősségi deep-link tesztek.
 * A Készlet pillanatkép „Sürgősségi banki kivét" gombja ?create=1&urgency=EMERGENCY
 * paraméterekkel nyitja elő az új-rendelés formot.
 */
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import BankOrderPage from './BankOrderPage'

const mockList = vi.fn()
const mockGet = vi.fn()

vi.mock('../../services/api/bankOrders', async (importOriginal) => {
  const original = await importOriginal<typeof import('../../services/api/bankOrders')>()
  return {
    ...original,
    bankOrdersApi: {
      ...original.bankOrdersApi,
      list: (...args: unknown[]) => mockList(...args),
    },
  }
})

vi.mock('../../services/api', () => ({
  api: {
    get: (...args: unknown[]) => mockGet(...args),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
    patch: vi.fn(),
  },
}))

function mockApi() {
  mockList.mockResolvedValue({ content: [], totalElements: 0, totalPages: 0, number: 0, size: 50 })
  mockGet.mockImplementation((url: string) => {
    if (url === '/western-union/daily-limit') {
      return Promise.resolve({
        data: { businessDate: '2026-06-11', currencyCode: 'USD', dailyLimit: 10000, usedAmount: 0, remainingAmount: 10000, usagePercent: 0 },
      })
    }
    if (url === '/branches') {
      return Promise.resolve({ data: [{ id: 'b1', code: 'BR105', name: 'Békéscsaba', isActive: true }] })
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
    mockGet.mockReset()
    mockApi()
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
})
