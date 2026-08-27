import { render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import FeePackagePage from './FeePackagePage'

const mocks = vi.hoisted(() => ({
  getTypes: vi.fn(),
  getRates: vi.fn(),
  getDiscounts: vi.fn(),
  createType: vi.fn(),
  updateType: vi.fn(),
  createRate: vi.fn(),
  updateRate: vi.fn(),
  createDiscount: vi.fn(),
  updateDiscount: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../services/api/index', () => ({
  feeApi: {
    getTypes: mocks.getTypes,
    getRates: mocks.getRates,
    getDiscounts: mocks.getDiscounts,
    createType: mocks.createType,
    updateType: mocks.updateType,
    createRate: mocks.createRate,
    updateRate: mocks.updateRate,
    createDiscount: mocks.createDiscount,
    updateDiscount: mocks.updateDiscount,
  },
}))

vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))

describe('FeePackagePage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.getTypes.mockResolvedValue([
      {
        id: 'fee-type-1',
        code: 'WU',
        name: 'Western Union',
        calculationMethod: 'FIXED',
        isActive: true,
      },
    ])
    mocks.getRates.mockResolvedValue([])
    mocks.getDiscounts.mockResolvedValue([])
  })

  it('a régi /fee-packages route-ot a valós /fees díjkezelő backend szerződésre köti', async () => {
    render(<FeePackagePage />)

    await waitFor(() => expect(screen.getByText('Western Union')).toBeInTheDocument())
    expect(screen.getByText('fees.dijkezeles')).toBeInTheDocument()
    expect(screen.queryByText(/nincs azonos szerződésű backend/i)).not.toBeInTheDocument()
    expect(mocks.getTypes).toHaveBeenCalledTimes(1)
  })
})
