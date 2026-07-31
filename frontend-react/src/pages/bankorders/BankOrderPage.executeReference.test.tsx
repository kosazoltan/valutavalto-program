import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import BankOrderPage from './BankOrderPage'

// FKH-027 PR B (RED) — FR-B6..FR-B7: a handleExecute a natív prompt() helyett a közös
// TextReasonModal-lal kéri be a banki hivatkozási számot.
//
// FIGYELEM — ez a helyszín SZÁNDÉKOSAN eltér a pilot-kör (CameraExportPage /
// VaultStocktakeDetailPage) mintájától: a jelenlegi kód a null-t és az üres stringet
// megkülönbözteti (BankOrderPage.tsx:191-196):
//   if (ref === null) return
//   await bankOrdersApi.execute(id, ref || undefined)
// -> Mégse (null): NINCS execute-hívás.
// -> OK üresen (''): VAN execute-hívás, és a `ref || undefined` miatt a második
//    argumentum `undefined` (NEM üres string). A teszt a forrás tényleges
//    viselkedését pinneli.

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

const approvedOrder = {
  id: 'order-1',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  currencyId: 2,
  currencyCode: 'EUR',
  amount: '2500',
  status: 'APPROVED',
  urgency: 'NORMAL',
  requestedByWorkerId: 77,
  requestedByWorkerName: 'Kérő dolgozó',
  requestedAt: '2026-06-19T08:00:00.000Z',
  approvedByWorkerName: 'Jóváhagyó vezető',
}

describe('BankOrderPage — FR-B6..B7: banki hivatkozási szám a TextReasonModal-lal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue({
      content: [approvedOrder],
      totalElements: 1,
      totalPages: 1,
      number: 0,
      size: 100,
    })
    mocks.execute.mockResolvedValue({ ...approvedOrder, status: 'EXECUTED' })
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

  async function openExecuteModal(user: ReturnType<typeof userEvent.setup>) {
    render(
      <MemoryRouter initialEntries={['/bank-orders']}>
        <BankOrderPage />
      </MemoryRouter>,
    )
    await user.click(await screen.findByRole('button', { name: 'Teljesít' }))
    const dialog = await screen.findByRole('alertdialog')
    // FR-B6: a title szó szerint az eddigi prompt-szöveg
    expect(dialog).toHaveAccessibleName('Bank hivatkozási szám (opcionális):')
    expect(window.prompt).not.toHaveBeenCalled()
    return dialog
  }

  it('FR-B6 string-ág: a megadott referenciával pontosan egyszer hívódik a bankOrdersApi.execute', async () => {
    const user = userEvent.setup()
    const dialog = await openExecuteModal(user)
    await user.type(within(dialog).getByRole('textbox'), 'BANK-REF-2026-001')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(mocks.execute).toHaveBeenCalledWith('order-1', 'BANK-REF-2026-001'))
    expect(mocks.execute).toHaveBeenCalledTimes(1)
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-B7 null-ág (Mégse): NEM hívódik a bankOrdersApi.execute', async () => {
    const user = userEvent.setup()
    const dialog = await openExecuteModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.execute).not.toHaveBeenCalled()
    expect(window.prompt).not.toHaveBeenCalled()
  })

  it('FR-B7 üres string-ág (OK üresen): a bankOrdersApi.execute IGENIS hívódik, undefined referenciával', async () => {
    const user = userEvent.setup()
    const dialog = await openExecuteModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(mocks.execute).toHaveBeenCalledWith('order-1', undefined))
    expect(mocks.execute).toHaveBeenCalledTimes(1)
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(window.prompt).not.toHaveBeenCalled()
  })
})
