import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { fireEvent } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import BanknoteBreakdown from './BanknoteBreakdown'

/**
 * FK-072_v2 FR-6: a tranzakciós Bankjegy-bontás komponens szabad számmezős
 * fallback-ágán (COMMON_DENOMINATIONS-on kívüli valuta, pl. JPY) az 1 alatti
 * névérték elutasítása. Ma a handleAdd csak <= 0-t szűr, a 0,5 átmegy a create-be.
 */

const mocks = vi.hoisted(() => ({
  getByTransaction: vi.fn(),
  create: vi.fn(),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
  },
}))

vi.mock('../../services/api/transactions', () => ({
  transactionBanknoteApi: {
    getByTransaction: (...args: unknown[]) => mocks.getByTransaction(...args),
    create: (...args: unknown[]) => mocks.create(...args),
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: mocks.toast,
}))

function renderJpyFallback() {
  return render(
    <BanknoteBreakdown transactionId={10} currencyCode="JPY" direction="IN" />,
  )
}

describe('BanknoteBreakdown — FK-072_v2 tört címletek (FR-6, FR-7)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getByTransaction.mockResolvedValue([])
    mocks.create.mockResolvedValue({
      id: 99,
      transactionId: 10,
      currencyCode: 'JPY',
      faceValue: 500,
      quantity: 2,
      direction: 'IN',
      totalValue: 1000,
    })
  })

  it('FR-6: fallback számmezőben 1 alatti névérték (0,5) → warning, a create API NEM hívódik', async () => {
    renderJpyFallback()
    await waitFor(() => screen.getByText('Hozzáad'))

    // JPY nincs a COMMON_DENOMINATIONS-ban → szabad számmező a névértékre.
    const [faceValueInput] = screen.getAllByRole('spinbutton')
    fireEvent.change(faceValueInput!, { target: { value: '0.5' } })

    await userEvent.click(screen.getByText('Hozzáad'))

    await waitFor(() => {
      expect(mocks.toast.warning).toHaveBeenCalled()
    })
    // NFR-1: az elutasítás magyar hibaüzenettel történik — a warning cím+üzenet
    // szövege együtt tartalmazza legalább az "1"-et és a "címlet" szót (nem szó
    // szerinti egyezés, a többi helyszín "1-nél kisebb" regex-védelmi szintje).
    const warningText = mocks.toast.warning.mock.calls.at(-1)!.join(' ')
    expect(warningText).toMatch(/1/)
    expect(warningText).toMatch(/címlet/i)
    expect(mocks.create).not.toHaveBeenCalled()
  })

  it('FR-7 regresszió: egész névérték (500 × 2) változatlanul rögzíthető a fallback mezőben', async () => {
    renderJpyFallback()
    await waitFor(() => screen.getByText('Hozzáad'))

    const [faceValueInput, quantityInput] = screen.getAllByRole('spinbutton')
    fireEvent.change(faceValueInput!, { target: { value: '500' } })
    fireEvent.change(quantityInput!, { target: { value: '2' } })

    await userEvent.click(screen.getByText('Hozzáad'))

    await waitFor(() => {
      expect(mocks.create).toHaveBeenCalledWith(
        10,
        expect.objectContaining({ currencyCode: 'JPY', faceValue: 500, quantity: 2 }),
      )
    })
    expect(mocks.toast.warning).not.toHaveBeenCalled()
  })
})
