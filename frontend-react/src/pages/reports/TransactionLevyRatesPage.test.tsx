import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TransactionLevyRatesPage from './TransactionLevyRatesPage'

/**
 * FK-099 F8–F11 — illeték-ráta beállítások oldal (WU7 RED → WU9 GREEN).
 * F8: history lista effectiveFrom DESC, nincs szerkesztés/törlés vezérlő (FR-1).
 * F9/F10: a mentési űrlap CSAK foertektar/ugyvezeto/admin szerepben (FR-18 UI).
 * F11: a batchelt validációs hiba szó szerint jelenik meg.
 */

const translations: Record<string, string> = vi.hoisted(() => ({
  'reports.transactionLevyRates.title': 'Illeték-ráta beállítások',
  'reports.transactionLevyRates.newRow': 'Új ráta rögzítése',
  'reports.transactionLevyRates.save': 'Mentés',
  'reports.transactionLevyRates.effectiveFrom': 'Hatálybalépés dátuma',
  'reports.transactionLevyRates.baseRate': 'Alap ráta (%)',
  'reports.transactionLevyRates.baseCap': 'Alap plafon (Ft)',
  'reports.transactionLevyRates.supplementRate': 'Kiegészítő ráta (%)',
  'reports.transactionLevyRates.supplementCap': 'Kiegészítő plafon (Ft)',
  'reports.transactionLevyRates.singleSide': 'Konverzió egy illeték-pár',
  'reports.transactionLevyRates.history': 'Ráta-history',
  'reports.transactionLevyRates.threshold': 'Küszöb',
  'reports.transactionLevyRates.createdBy': 'Rögzítette',
}))

vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({
    t: (key: string) => translations[key] ?? key,
  }),
}))

const mocks = vi.hoisted(() => ({
  listRates: vi.fn(),
  createRate: vi.fn(),
  roles: { value: ['belso_ellenor'] as string[] },
}))

vi.mock('../../services/api/index', () => ({
  transactionLevyApi: {
    getReport: vi.fn(),
    listRates: (...args: unknown[]) => mocks.listRates(...args),
    createRate: (...args: unknown[]) => mocks.createRate(...args),
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({
      hasCanonicalRole: (roles: string[]) => roles.some((r) => mocks.roles.value.includes(r)),
    }),
}))

const RATES_DESC = [
  {
    id: 'r2',
    effectiveFrom: '2026-08-15',
    baseRatePercent: 0.3,
    baseRateCapHuf: 15000,
    supplementRatePercent: 0.3,
    supplementRateCapHuf: 15000,
    conversionSingleSideFlag: true,
    createdBy: 'WK001',
    createdAt: '2026-08-14T10:00:00Z',
    thresholdHuf: 5000000,
  },
  {
    id: 'r1',
    effectiveFrom: '2013-01-01',
    baseRatePercent: 0.45,
    baseRateCapHuf: 20000,
    supplementRatePercent: 0.45,
    supplementRateCapHuf: 20000,
    conversionSingleSideFlag: true,
    createdBy: 'V384',
    createdAt: '2026-08-01T00:00:00Z',
    thresholdHuf: 4444445,
  },
]

describe('TransactionLevyRatesPage — FK-099', () => {
  beforeEach(() => {
    mocks.listRates.mockReset()
    mocks.createRate.mockReset()
    mocks.listRates.mockResolvedValue(RATES_DESC)
  })

  it('F8/FR-1 UI: a lista effectiveFrom DESC-rendezett és nincs szerkesztés/törlés vezérlő', async () => {
    mocks.roles.value = ['belso_ellenor']

    render(<TransactionLevyRatesPage />)

    await waitFor(() => expect(screen.getByText('2026-08-15')).toBeInTheDocument())
    expect(screen.getByText('2013-01-01')).toBeInTheDocument()
    // A DESC sorrend: az újabb ráta sora előbb szerepel a dokumentumban.
    const rows = screen.getAllByRole('row')
    const newerIndex = rows.findIndex((r) => r.textContent?.includes('2026-08-15'))
    const olderIndex = rows.findIndex((r) => r.textContent?.includes('2013-01-01'))
    expect(newerIndex).toBeLessThan(olderIndex)
    // FR-1: append-only UI — nincs szerkesztés vagy törlés vezérlő.
    expect(screen.queryByRole('button', { name: /szerkeszt/i })).toBeNull()
    expect(screen.queryByRole('button', { name: /törl/i })).toBeNull()
    expect(screen.queryByRole('button', { name: /edit/i })).toBeNull()
    expect(screen.queryByRole('button', { name: /delete/i })).toBeNull()
  })

  it('F9/FR-18 UI: belso_ellenor (írás-jogosultság nélkül) NEM látja az új ráta űrlapot', async () => {
    mocks.roles.value = ['belso_ellenor']

    render(<TransactionLevyRatesPage />)

    await waitFor(() => expect(screen.getByText('2013-01-01')).toBeInTheDocument())
    expect(screen.queryByText('Új ráta rögzítése')).toBeNull()
    expect(screen.queryByRole('button', { name: 'Mentés' })).toBeNull()
  })

  it('F10/FR-18 UI: foertektar látja az űrlapot, a mentés a típusozott body-val hívja a createRate-et', async () => {
    mocks.roles.value = ['foertektar']
    mocks.createRate.mockResolvedValue(RATES_DESC[0])

    render(<TransactionLevyRatesPage />)

    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    fireEvent.change(screen.getByLabelText('Hatálybalépés dátuma'), {
      target: { value: '2026-09-15' },
    })
    fireEvent.change(screen.getByLabelText('Alap ráta (%)'), { target: { value: '0.5' } })
    fireEvent.change(screen.getByLabelText('Alap plafon (Ft)'), { target: { value: '25000' } })
    fireEvent.change(screen.getByLabelText('Kiegészítő ráta (%)'), { target: { value: '0.5' } })
    fireEvent.change(screen.getByLabelText('Kiegészítő plafon (Ft)'), {
      target: { value: '25000' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() =>
      expect(mocks.createRate).toHaveBeenCalledWith({
        effectiveFrom: '2026-09-15',
        baseRatePercent: 0.5,
        baseRateCapHuf: 25000,
        supplementRatePercent: 0.5,
        supplementRateCapHuf: 25000,
        conversionSingleSideFlag: true,
      }),
    )
  })

  it('F11: createRate batchelt validációs hibája szó szerint megjelenik', async () => {
    mocks.roles.value = ['foertektar']
    mocks.listRates.mockResolvedValue(RATES_DESC)
    mocks.createRate.mockRejectedValue({
      response: {
        data: {
          message:
            'A hatálybalépés dátuma csak jövőbeli lehet. A hatálybalépés dátuma nem lehet korábbi vagy azonos a legutolsó rögzített sorénál: 2026-08-15',
        },
      },
    })

    render(<TransactionLevyRatesPage />)

    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    fireEvent.change(screen.getByLabelText('Hatálybalépés dátuma'), {
      target: { value: '2026-08-10' },
    })
    fireEvent.change(screen.getByLabelText('Alap ráta (%)'), { target: { value: '0.5' } })
    fireEvent.change(screen.getByLabelText('Alap plafon (Ft)'), { target: { value: '25000' } })
    fireEvent.change(screen.getByLabelText('Kiegészítő ráta (%)'), { target: { value: '0.5' } })
    fireEvent.change(screen.getByLabelText('Kiegészítő plafon (Ft)'), {
      target: { value: '25000' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() =>
      expect(
        screen.getByText(
          'A hatálybalépés dátuma csak jövőbeli lehet. A hatálybalépés dátuma nem lehet korábbi vagy azonos a legutolsó rögzített sorénál: 2026-08-15',
        ),
      ).toBeInTheDocument(),
    )
  })
})
