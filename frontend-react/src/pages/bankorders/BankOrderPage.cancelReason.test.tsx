import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import BankOrderPage from './BankOrderPage'

// FKH-027 PR B (RED) — FR-B8..FR-B9: a handleCancel a natív prompt() helyett a közös
// TextReasonModal-lal kéri be a visszavonás indoklását.
// A jelenlegi őrfeltétel (BankOrderPage.tsx:205-209) `if (!reason) return`, tehát a
// null ÉS az üres string egyaránt a "nincs API-hívás" ágba tartozik — itt a
// pilot-kör mintája érvényes (eltérően a handleExecute-tól).

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  get: vi.fn(),
  approve: vi.fn(),
  execute: vi.fn(),
  cancel: vi.fn(),
  create: vi.fn(),
  apiGet: vi.fn(),
  apiPost: vi.fn(),
}))

vi.mock('../../services/api/bankOrders', async (importOriginal) => {
  const original = await importOriginal<typeof import('../../services/api/bankOrders')>()
  return {
    ...original,
    bankOrdersApi: {
      ...original.bankOrdersApi,
      list: mocks.list,
      get: mocks.get,
      approve: mocks.approve,
      execute: mocks.execute,
      cancel: mocks.cancel,
      create: mocks.create,
    },
  }
})

vi.mock('../../services/api', () => ({
  api: {
    get: mocks.apiGet,
    post: mocks.apiPost,
    put: vi.fn(),
    delete: vi.fn(),
    patch: vi.fn(),
  },
}))

const pendingOrder = {
  id: 'order-1',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  currencyId: 2,
  currencyCode: 'EUR',
  amount: '2500',
  status: 'PENDING',
  urgency: 'NORMAL',
  requestedByWorkerId: 77,
  requestedByWorkerName: 'Kérő dolgozó',
  requestedAt: '2026-06-19T08:00:00.000Z',
}

describe('BankOrderPage — FR-B8..B9: visszavonás indoklása a TextReasonModal-lal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue({
      content: [pendingOrder],
      totalElements: 1,
      totalPages: 1,
      number: 0,
      size: 100,
    })
    mocks.cancel.mockResolvedValue({ ...pendingOrder, status: 'CANCELLED' })
    mocks.apiGet.mockImplementation((url: string) => {
      if (url === '/western-union/daily-limit') {
        return Promise.resolve({
          data: {
            businessDate: '2026-07-31',
            currencyCode: 'USD',
            dailyLimit: 10000,
            usedAmount: 0,
            remainingAmount: 10000,
            usagePercent: 0,
          },
        })
      }
      return Promise.resolve({ data: [] })
    })
    vi.spyOn(window, 'prompt').mockReturnValue(null)
    vi.spyOn(window, 'alert').mockImplementation(() => {})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  async function openCancelModal(user: ReturnType<typeof userEvent.setup>) {
    render(
      <MemoryRouter initialEntries={['/bank-orders']}>
        <BankOrderPage />
      </MemoryRouter>,
    )
    await user.click(await screen.findByRole('button', { name: 'Visszavon' }))
    const dialog = await screen.findByRole('alertdialog')
    // FR-B8: a title szó szerint az eddigi prompt-szöveg
    expect(dialog).toHaveAccessibleName('Visszavonás indoklása:')
    expect(window.prompt).not.toHaveBeenCalled()
    return dialog
  }

  it('FR-B9 string-ág: a megadott indoklással pontosan egyszer hívódik a bankOrdersApi.cancel', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.type(within(dialog).getByRole('textbox'), 'Téves rögzítés')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(mocks.cancel).toHaveBeenCalledWith('order-1', 'Téves rögzítés'))
    expect(mocks.cancel).toHaveBeenCalledTimes(1)
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-B9 null-ág: Mégse után nem hívódik a bankOrdersApi.cancel', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.cancel).not.toHaveBeenCalled()
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('üres string: a hívó-oldali validáció megmarad — üres indoklással nincs API-hívás', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.cancel).not.toHaveBeenCalled()
  })
})
