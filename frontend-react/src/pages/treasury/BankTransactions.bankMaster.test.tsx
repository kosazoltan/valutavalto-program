import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import BankTransactions from './BankTransactions'

const mocks = vi.hoisted(() => ({
  ertektarApi: {
    getBankTransactions: vi.fn(),
    createBankTransaction: vi.fn(),
    confirmBankTransactionReceived: vi.fn(),
    confirmBankTransactionPaid: vi.fn(),
  },
  currencyApi: {
    list: vi.fn(),
  },
  bankApi: {
    list: vi.fn(),
    create: vi.fn(),
    deactivate: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  ertektarApi: mocks.ertektarApi,
  currencyApi: mocks.currencyApi,
  bankApi: mocks.bankApi,
}))

vi.mock('../../utils/electronTransactions', () => ({
  isElectronQueueAvailable: () => false,
  saveAndSyncPendingBankTransaction: vi.fn(),
}))

vi.mock('../../utils/localQueue', () => ({
  getLocalPendingBankTransactions: vi.fn().mockResolvedValue([]),
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

describe('BankTransactions bank-törzs backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.ertektarApi.getBankTransactions.mockResolvedValue([])
    mocks.currencyApi.list.mockResolvedValue([])
    mocks.bankApi.list.mockResolvedValue([
      { id: 'bank-1', name: 'Raiffeisen Bank', regionCode: '20' },
    ])
    mocks.bankApi.create.mockResolvedValue({ id: 'bank-2', name: 'Teszt Bank', regionCode: '30' })
    mocks.bankApi.deactivate.mockResolvedValue(undefined)
    vi.spyOn(window, 'confirm').mockReturnValue(true)
  })

  it('új bank felvételekor a POST /banks wrapperét hívja', async () => {
    const user = userEvent.setup()
    render(<BankTransactions />)

    await screen.findByText('Bank-törzs')
    await user.type(screen.getByLabelText(/Bank neve/i), 'Teszt Bank')
    await user.type(screen.getByLabelText(/Területkód/i), '30')
    await user.click(screen.getByRole('button', { name: /Felvétel/i }))

    await waitFor(() => {
      expect(mocks.bankApi.create).toHaveBeenCalledWith({ name: 'Teszt Bank', regionCode: '30' })
    })
  })

  it('bank deaktiválásakor a DELETE /banks/{id} wrapperét hívja', async () => {
    const user = userEvent.setup()
    render(<BankTransactions />)

    await screen.findByText('Raiffeisen Bank')
    await user.click(screen.getByTitle('Deaktiválás'))

    await waitFor(() => {
      expect(mocks.bankApi.deactivate).toHaveBeenCalledWith('bank-1')
    })
  })
})
