import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import BanknoteBreakdown from './BanknoteBreakdown'

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

const mockBanknotesIN = [
  {
    id: 1,
    transactionId: 10,
    currencyCode: 'EUR',
    faceValue: 50,
    quantity: 3,
    direction: 'IN' as const,
    totalValue: 150,
  },
  {
    id: 2,
    transactionId: 10,
    currencyCode: 'EUR',
    faceValue: 20,
    quantity: 2,
    direction: 'IN' as const,
    totalValue: 40,
  },
]

const mockBanknotesOUT = [
  {
    id: 3,
    transactionId: 10,
    currencyCode: 'HUF',
    faceValue: 5000,
    quantity: 10,
    direction: 'OUT' as const,
    totalValue: 50000,
  },
]

function renderComponent(
  props?: Partial<{
    transactionId: number
    currencyCode: string
    direction: 'IN' | 'OUT'
    readOnly: boolean
  }>,
) {
  return render(
    <BanknoteBreakdown
      transactionId={props?.transactionId ?? 10}
      currencyCode={props?.currencyCode ?? 'EUR'}
      direction={props?.direction ?? 'IN'}
      readOnly={props?.readOnly}
    />,
  )
}

describe('BanknoteBreakdown', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getByTransaction.mockResolvedValue([])
  })

  it('betöltés közben spinner látható', () => {
    mocks.getByTransaction.mockReturnValue(new Promise(() => {}))
    renderComponent()
    expect(screen.getByText('Betöltés...')).toBeDefined()
  })

  it('IN irány esetén "Beérkező" felirat jelenik meg', async () => {
    mocks.getByTransaction.mockResolvedValue([])
    renderComponent({ direction: 'IN' })
    await waitFor(() => {
      expect(screen.getByText(/Beérkező/)).toBeDefined()
    })
  })

  it('OUT irány esetén "Kiadandó" felirat jelenik meg', async () => {
    mocks.getByTransaction.mockResolvedValue([])
    renderComponent({ direction: 'OUT' })
    await waitFor(() => {
      expect(screen.getByText(/Kiadandó/)).toBeDefined()
    })
  })

  it('üres lista esetén nincs táblázat', async () => {
    mocks.getByTransaction.mockResolvedValue([])
    renderComponent()
    await waitFor(() => {
      expect(screen.queryByText('Névérték')).toBeNull()
    })
  })

  it('IN irányú banknotes helyesen jelennek meg', async () => {
    mocks.getByTransaction.mockResolvedValue(mockBanknotesIN)
    renderComponent({ direction: 'IN', currencyCode: 'EUR' })
    await waitFor(() => {
      // Névérték cellák: "50 EUR", "20 EUR"
      const cells = screen.getAllByText(/EUR/)
      expect(cells.length).toBeGreaterThan(0)
      expect(screen.getByText('3 db')).toBeDefined()
    })
  })

  it('OUT irányú banknotes-okat szűri, IN nem jelenik meg', async () => {
    mocks.getByTransaction.mockResolvedValue([...mockBanknotesIN, ...mockBanknotesOUT])
    renderComponent({ direction: 'OUT', currencyCode: 'HUF' })
    await waitFor(() => {
      expect(screen.getByText(/5\s*000\s*HUF/)).toBeDefined()
      // IN irányú EUR nem jelenhet meg
      expect(screen.queryByText(/50\s*EUR/)).toBeNull()
    })
  })

  it('összesítő sor helyes értékekkel jelenik meg', async () => {
    mocks.getByTransaction.mockResolvedValue(mockBanknotesIN)
    renderComponent({ direction: 'IN', currencyCode: 'EUR' })
    await waitFor(() => {
      // 3+2 = 5 db
      expect(screen.getByText('5 db')).toBeDefined()
      // Összesen sor
      expect(screen.getByText('Összesen')).toBeDefined()
    })
  })

  it('API hiba esetén hibaüzenet jelenik meg', async () => {
    mocks.getByTransaction.mockRejectedValue(new Error('Hálózati hiba'))
    renderComponent()
    await waitFor(() => {
      expect(screen.getByText('Hálózati hiba')).toBeDefined()
    })
  })

  it('Hozzáad gomb látható ha nem readOnly', async () => {
    mocks.getByTransaction.mockResolvedValue([])
    renderComponent({ readOnly: false })
    await waitFor(() => {
      expect(screen.getByText('Hozzáad')).toBeDefined()
    })
  })

  it('Hozzáad gomb nem látható ha readOnly=true', async () => {
    mocks.getByTransaction.mockResolvedValue([])
    renderComponent({ readOnly: true })
    await waitFor(() => {
      expect(screen.queryByText('Hozzáad')).toBeNull()
    })
  })

  it('érvénytelen faceValue (0) esetén warning toast jelenik meg', async () => {
    mocks.getByTransaction.mockResolvedValue([])
    renderComponent({ currencyCode: 'USD', direction: 'IN' })
    await waitFor(() => screen.getByText('Hozzáad'))

    // USD-nél input mező jelenik meg (nincs COMMON_DENOMINATIONS-ban a 0)
    // az alapértelmezett faceValue=0, ezért warning-ot kell dobni
    await userEvent.click(screen.getByText('Hozzáad'))

    await waitFor(() => {
      expect(mocks.toast.warning).toHaveBeenCalledWith(
        'Érvénytelen adat',
        'Névérték és darabszám pozitív kell legyen',
      )
    })
  })

  it('EUR denominations select megjelenik EUR pénznem esetén', async () => {
    mocks.getByTransaction.mockResolvedValue([])
    renderComponent({ currencyCode: 'EUR', direction: 'IN' })
    await waitFor(() => {
      expect(screen.getByText('Válassz...')).toBeDefined()
    })
  })

  it('ismeretlen pénznem esetén szabad beviteli mező jelenik meg', async () => {
    mocks.getByTransaction.mockResolvedValue([])
    renderComponent({ currencyCode: 'JPY', direction: 'IN' })
    await waitFor(() => {
      const inputs = screen.getAllByRole('spinbutton')
      expect(inputs.length).toBeGreaterThan(0)
    })
  })

  it('sikeres hozzáadás meghívja az API-t és frissíti a listát', async () => {
    mocks.getByTransaction.mockResolvedValue([])
    const newBanknote = {
      id: 99,
      transactionId: 10,
      currencyCode: 'EUR',
      faceValue: 50,
      quantity: 2,
      direction: 'IN' as const,
      totalValue: 100,
    }
    mocks.create.mockResolvedValue(newBanknote)

    renderComponent({ currencyCode: 'EUR', direction: 'IN' })
    await waitFor(() => screen.getByText('Válassz...'))

    // EUR denomination kiválasztása (50-es)
    const select = screen.getByRole('combobox')
    await userEvent.selectOptions(select, '50')

    await userEvent.click(screen.getByText('Hozzáad'))

    await waitFor(() => {
      expect(mocks.create).toHaveBeenCalledWith(
        10,
        expect.objectContaining({ currencyCode: 'EUR', faceValue: 50, direction: 'IN' }),
      )
      expect(mocks.toast.success).toHaveBeenCalledWith('Címlet hozzáadva')
    })
  })

  it('create API hiba esetén error toast jelenik meg', async () => {
    mocks.getByTransaction.mockResolvedValue([])
    mocks.create.mockRejectedValue(new Error('Szerver hiba'))

    renderComponent({ currencyCode: 'EUR', direction: 'IN' })
    await waitFor(() => screen.getByText('Válassz...'))

    const select = screen.getByRole('combobox')
    await userEvent.selectOptions(select, '50')

    await userEvent.click(screen.getByText('Hozzáad'))

    await waitFor(() => {
      expect(mocks.toast.error).toHaveBeenCalledWith('Hiba', 'Szerver hiba')
    })
  })
})
