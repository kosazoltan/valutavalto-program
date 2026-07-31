import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import BankOrderPage from './BankOrderPage'

// B-csoport (RED) — FR-T1..FR-T4: a natív window.alert() kiváltása a közös toast-tal
// (components/ui/toaster). Az Electron rendererben az alert MŰKÖDIK ugyan (natív
// message-box), de angol OK-gombbal, app-témán kívül, a renderert blokkolva.
//
// A kör KIZÁRÓLAG az alert()-hívást cseréli. Az FKH-027-ben bekötött
// `requestReason()` (TextReasonModal) hívások, a null/üres-string ágak és a
// guard-sorrend VÁLTOZATLAN — a tesztek ezt is pinnelik.
//
// Szöveg-szerződés (Tomi jóváhagyása, 2026-07-31): a mai alert-szöveg
// `'<Cím>: ' + err.message` alakú, tehát VAN natural elválasztó → a repo bevett
// kétargumentumos mintája érvényes: `toast.error('<Cím>', '<részlet>')`
// (precedens: VaultClosingChecklistPanel.tsx:143, DecadeReportPage.tsx:86).
// Új szöveget NEM vezetünk be: a cím a kettőspont előtti mai szöveg, a részlet
// a mai `err instanceof Error ? err.message : ''` kifejezés — változatlanul.

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  get: vi.fn(),
  approve: vi.fn(),
  execute: vi.fn(),
  cancel: vi.fn(),
  create: vi.fn(),
  apiGet: vi.fn(),
  apiPost: vi.fn(),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
    info: vi.fn(),
    dismiss: vi.fn(),
  },
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

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

const baseOrder = {
  id: 'order-1',
  branchId: 'branch-1',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  currencyId: 2,
  currencyCode: 'EUR',
  amount: '2500',
  urgency: 'NORMAL',
  requestedByWorkerId: 77,
  requestedByWorkerName: 'Kérő dolgozó',
  requestedAt: '2026-06-19T08:00:00.000Z',
}

const pendingOrder = { ...baseOrder, status: 'PENDING' }
const approvedOrder = { ...baseOrder, status: 'APPROVED' }

function renderWithOrders(orders: unknown[]) {
  mocks.list.mockResolvedValue({
    content: orders,
    totalElements: orders.length,
    totalPages: 1,
    number: 0,
    size: 100,
  })
  render(
    <MemoryRouter initialEntries={['/bank-orders']}>
      <BankOrderPage />
    </MemoryRouter>,
  )
}

describe('BankOrderPage — FR-T1..T4: a natív alert() helyett toast', () => {
  beforeEach(() => {
    vi.clearAllMocks()
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
    vi.spyOn(window, 'alert').mockImplementation(() => {})
    vi.spyOn(window, 'prompt').mockReturnValue(null)
    // A megerősítő confirm() EBBEN A KÖRBEN NEM változik (A-csoport) — igennel válaszolunk.
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('FR-T1 (BankOrderPage.tsx:187) — jóváhagyási hiba toast.error-ral, natív alert nélkül', async () => {
    const user = userEvent.setup()
    mocks.approve.mockRejectedValue(new Error('Kapcsolat megszakadt'))
    renderWithOrders([pendingOrder])

    await user.click(await screen.findByRole('button', { name: 'Jóváhagy' }))

    await waitFor(() =>
      expect(mocks.toast.error).toHaveBeenCalledWith(
        'Hiba a jóváhagyásnál',
        'Kapcsolat megszakadt',
      ),
    )
    expect(mocks.toast.error).toHaveBeenCalledTimes(1)
    expect(window.alert).not.toHaveBeenCalled()
    // A guard-sorrend változatlan: a confirm ELŐBB fut, az API pontosan egyszer hívódik.
    expect(window.confirm).toHaveBeenCalledWith('Biztosan jóváhagyja ezt a banki rendelést?')
    expect(mocks.approve).toHaveBeenCalledTimes(1)
  })

  it('FR-T2 (BankOrderPage.tsx:203) — teljesítési hiba toast.error-ral; a requestReason-útvonal változatlan', async () => {
    const user = userEvent.setup()
    mocks.execute.mockRejectedValue(new Error('Időtúllépés'))
    renderWithOrders([approvedOrder])

    await user.click(await screen.findByRole('button', { name: 'Teljesít' }))
    const dialog = await screen.findByRole('alertdialog')
    // FKH-027 marad: a referencia a TextReasonModal-ból jön, nem natív prompt()-ból.
    expect(dialog).toHaveAccessibleName('Bank hivatkozási szám (opcionális):')
    expect(window.prompt).not.toHaveBeenCalled()
    await user.type(within(dialog).getByRole('textbox'), 'BANK-REF-2026-001')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))

    await waitFor(() =>
      expect(mocks.toast.error).toHaveBeenCalledWith('Hiba a teljesítésnél', 'Időtúllépés'),
    )
    expect(mocks.toast.error).toHaveBeenCalledTimes(1)
    expect(window.alert).not.toHaveBeenCalled()
    expect(mocks.execute).toHaveBeenCalledWith('order-1', 'BANK-REF-2026-001')
  })

  it('FR-T3 (BankOrderPage.tsx:217) — visszavonási hiba toast.error-ral; a requestReason-útvonal változatlan', async () => {
    const user = userEvent.setup()
    mocks.cancel.mockRejectedValue(new Error('Szerver hiba'))
    renderWithOrders([pendingOrder])

    await user.click(await screen.findByRole('button', { name: 'Visszavon' }))
    const dialog = await screen.findByRole('alertdialog')
    expect(dialog).toHaveAccessibleName('Visszavonás indoklása:')
    expect(window.prompt).not.toHaveBeenCalled()
    await user.type(within(dialog).getByRole('textbox'), 'Téves rögzítés')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))

    await waitFor(() =>
      expect(mocks.toast.error).toHaveBeenCalledWith('Hiba a visszavonásnál', 'Szerver hiba'),
    )
    expect(mocks.toast.error).toHaveBeenCalledTimes(1)
    expect(window.alert).not.toHaveBeenCalled()
    expect(mocks.cancel).toHaveBeenCalledWith('order-1', 'Téves rögzítés')
  })

  it('FR-T4 — nem-Error rejectnél a részlet ÜRES string marad (a mai ternary változatlan)', async () => {
    const user = userEvent.setup()
    // A mai kód: 'Hiba a jóváhagyásnál: ' + (err instanceof Error ? err.message : '')
    // → a bontás után a második argumentum a ternary eredménye, azaz üres string.
    // (Az üres message-t a Toaster nem rendereli — toaster.tsx:105.) A `getErrorMessage(err)`-re
    // cserélés NEM fér bele ebbe a körbe: az új, ma nem látható szöveget adna.
    mocks.approve.mockRejectedValue('sima string reject')
    renderWithOrders([pendingOrder])

    await user.click(await screen.findByRole('button', { name: 'Jóváhagy' }))

    await waitFor(() => expect(mocks.toast.error).toHaveBeenCalledWith('Hiba a jóváhagyásnál', ''))
    expect(window.alert).not.toHaveBeenCalled()
  })

  it('sikeres művelet: se toast.error, se natív alert nem fut', async () => {
    const user = userEvent.setup()
    mocks.approve.mockResolvedValue({ ...pendingOrder, status: 'APPROVED' })
    renderWithOrders([pendingOrder])

    await user.click(await screen.findByRole('button', { name: 'Jóváhagy' }))

    await waitFor(() => expect(mocks.approve).toHaveBeenCalledTimes(1))
    expect(mocks.toast.error).not.toHaveBeenCalled()
    expect(window.alert).not.toHaveBeenCalled()
  })
})
