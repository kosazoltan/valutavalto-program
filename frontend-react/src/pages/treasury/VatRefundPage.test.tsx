import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import VatRefundPage from './VatRefundPage'

const mocks = vi.hoisted(() => ({
  getVatRefunds: vi.fn(),
  getVatRefund: vi.fn(),
  getDailyVatRefunds: vi.fn(),
  createVatRefund: vi.fn(),
  stornoVatRefund: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({
    t: (_key: string, defaultValue?: string) => defaultValue ?? _key,
  }),
}))

vi.mock('react-hotkeys-hook', () => ({
  useHotkeys: vi.fn(),
}))

vi.mock('../../services/api/index', () => ({
  ertektarApi: {
    getVatRefunds: mocks.getVatRefunds,
    getVatRefund: mocks.getVatRefund,
    getDailyVatRefunds: mocks.getDailyVatRefunds,
    createVatRefund: mocks.createVatRefund,
    stornoVatRefund: mocks.stornoVatRefund,
  },
}))

const baseRecord = {
  id: 1,
  companyId: 'company-1',
  voucherType: 'AK',
  serialNumber: 'VAT-001',
  transactionDate: '2026-06-19',
  transactionTime: '09:00:00',
  grossAmount: 12700,
  vatAmount: 2700,
  vatPercentage: 27,
  customerName: 'Lista Ügyfél',
  isReversed: false,
  createdAt: '2026-06-19T09:00:00',
}

describe('VatRefundPage backend contract', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getVatRefunds.mockResolvedValue([baseRecord])
    mocks.getDailyVatRefunds.mockResolvedValue([
      { ...baseRecord, id: 2, serialNumber: 'VAT-DAILY' },
    ])
    mocks.getVatRefund.mockResolvedValue({ ...baseRecord, customerName: 'Részlet Ügyfél' })
  })

  it('a napi ÁFA-visszatérítést a GET /vat-refund/daily szerződésből tölti', async () => {
    render(<VatRefundPage />)

    await screen.findAllByText('VAT-001')
    fireEvent.click(screen.getByRole('button', { name: 'Mai nap' }))

    await waitFor(() => {
      expect(mocks.getDailyVatRefunds).toHaveBeenCalledWith(
        expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/),
      )
    })
    expect((await screen.findAllByText('VAT-DAILY')).length).toBeGreaterThan(0)
  })

  it('a részlet modal megnyitásakor GET /vat-refund/{id} szerződésből frissít', async () => {
    render(<VatRefundPage />)

    await screen.findAllByText('VAT-001')
    const detailButtons = screen.getAllByLabelText('Részletek VAT-001')
    expect(detailButtons.length).toBeGreaterThan(0)
    fireEvent.click(detailButtons[0] as HTMLElement)

    await waitFor(() => {
      expect(mocks.getVatRefund).toHaveBeenCalledWith(1)
    })
    expect(await screen.findByText('Részlet Ügyfél')).toBeInTheDocument()
  })
})
