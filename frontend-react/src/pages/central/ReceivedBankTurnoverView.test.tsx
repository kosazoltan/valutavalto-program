import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import ReceivedBankTurnoverView from './ReceivedBankTurnoverView'
import hu from '../../i18n/hu.json'

const mockLoad = vi.fn()

vi.mock('../../services/api/received-bank-turnover', () => ({
  receivedBankTurnoverApi: {
    load: (...args: unknown[]) => mockLoad(...args),
  },
}))

const VAULT_A = '20000000-0000-0000-0000-00000000000a'

const payload = {
  fromDate: '2026-09-10',
  toDate: '2026-09-12',
  branchId: null,
  vaultTerritoryId: null,
  branches: [
    {
      id: VAULT_A,
      code: 'ET1',
      name: 'Szeged Értéktár',
      isVault: true,
      vaultTerritoryId: 2,
      region: 'Szeged',
    },
    {
      id: '20000000-0000-0000-0000-00000000000c',
      code: 'BR001',
      name: 'Dombóvár',
      isVault: false,
      vaultTerritoryId: 2,
      region: 'Szeged',
    },
  ],
  territories: [{ id: 2, name: 'Szeged' }],
  rows: [{ currencyCode: 'EUR', bankIn: 1000, bankOut: 250 }],
  missingClosingDays: [
    { branchId: VAULT_A, branchCode: 'ET1', branchName: 'Szeged Értéktár', date: '2026-09-11' },
  ],
}

describe('ReceivedBankTurnoverView — FK-114', () => {
  beforeEach(() => {
    mockLoad.mockReset()
  })

  it('nem kérdez le automatikusan betöltéskor', () => {
    render(<ReceivedBankTurnoverView />)
    expect(mockLoad).not.toHaveBeenCalled()
    expect(screen.getByText(hu.centralReceivedData.bankTurnoverPrompt)).toBeInTheDocument()
  })

  it('Lekérdezés gombra valutánként mutatja a Felvett-KP / Befizetett-KP értékeket', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedBankTurnoverView />)
    await userEvent.click(screen.getByTestId('bank-turnover-load-button'))

    expect(await screen.findByTestId('bank-turnover-row-EUR')).toBeInTheDocument()
    expect(screen.getByText(hu.centralReceivedData.bankTurnoverBankIn)).toBeInTheDocument()
    expect(screen.getByText(hu.centralReceivedData.bankTurnoverBankOut)).toBeInTheDocument()
    const eurRow = screen.getByTestId('bank-turnover-row-EUR')
    expect(eurRow).toHaveTextContent('1000')
    expect(eurRow).toHaveTextContent('250')
    expect(screen.getByTestId('bank-turnover-missing-days')).toBeInTheDocument()
    await waitFor(() => {
      expect(mockLoad).toHaveBeenCalledTimes(1)
    })
  })

  it('terület-szűrő a vault_territory_id-t küldi, nem a region_code-ot', async () => {
    mockLoad.mockResolvedValue(payload)
    render(<ReceivedBankTurnoverView />)
    await userEvent.click(screen.getByTestId('bank-turnover-load-button'))
    await screen.findByTestId('bank-turnover-row-EUR')

    await userEvent.selectOptions(screen.getByTestId('bank-turnover-unit-select'), 'territory:2')
    await userEvent.click(screen.getByTestId('bank-turnover-load-button'))

    expect(mockLoad).toHaveBeenLastCalledWith(
      expect.any(String),
      expect.any(String),
      expect.objectContaining({ vaultTerritoryId: 2, branchId: null }),
    )
  })
})
