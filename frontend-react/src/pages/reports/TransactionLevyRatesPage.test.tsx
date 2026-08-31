import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { AxiosError, type AxiosResponse } from 'axios'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import TransactionLevyRatesPage from './TransactionLevyRatesPage'

/**
 * FK-099 R1–R4 — illeték-ráta beállítások oldal (WU7 RED → WU9 GREEN;
 * round-3: R-sorozatra átnevezve — az F8–F11 nevek a riport-oldalé;
 * D6: a batchelt validációs hiba valódi AxiosError-ként érkezik, a szöveg VERBATIM).
 * R1: history lista effectiveFrom DESC, nincs szerkesztés/törlés vezérlő (FR-1).
 * R2/R3: a mentési űrlap CSAK foertektar/ugyvezeto/admin szerepben (FR-18 UI).
 * R4: a batchelt validációs hiba szó szerint jelenik meg.
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
  'reports.transactionLevyRates.singleSideInfo':
    'A konverzió egyszeri adóztatása (TRUE alapértelmezés) könyvelői/adótanácsadói megerősítésre vár — nem végleges jogi állásfoglalás.',
  'reports.transactionLevyRates.history': 'Ráta-history',
  'reports.transactionLevyRates.threshold': 'Küszöb',
  'reports.transactionLevyRates.createdBy': 'Rögzítette',
  'reports.transactionLevyRates.confirmTitle': 'Eltérő illeték-ráta rögzítése',
  'reports.transactionLevyRates.confirmText':
    'Az új ráta értékei eltérnek a jelenleg hatályos rátától.',
  'reports.transactionLevyRates.confirmIrreversible':
    'Ez a döntés a jövőben visszamenőlegesen nem módosítható.',
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

/**
 * FK-100 FR-4: RELATÍV dátumú fixture (pitfall 6) — baseline ≈ ma−30 nap
 * (0.3% / 15 000 cap), opcionális jövőbeli sor ≈ ma+30 nap. A fix dátumok
 * elavulnának; a relatív ablak a „ma hatályos" baseline-t stabilan adja.
 */
function isoDaysFromToday(days: number): string {
  const d = new Date()
  d.setDate(d.getDate() + days)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(
    d.getDate(),
  ).padStart(2, '0')}`
}

const fmt = new Intl.NumberFormat('hu-HU')
const fmtText = (n: number) => fmt.format(n).replace(/\s+/g, ' ')

function relativeRatesDesc() {
  return [
    {
      id: 'rf',
      effectiveFrom: isoDaysFromToday(30),
      baseRatePercent: 0.2,
      baseRateCapHuf: 10000,
      supplementRatePercent: 0.2,
      supplementRateCapHuf: 10000,
      conversionSingleSideFlag: true,
      createdBy: 'WK002',
      createdAt: '2026-08-14T10:00:00Z',
      thresholdHuf: 5000000,
    },
    {
      id: 'rb',
      effectiveFrom: isoDaysFromToday(-30),
      baseRatePercent: 0.3,
      baseRateCapHuf: 15000,
      supplementRatePercent: 0.3,
      supplementRateCapHuf: 15000,
      conversionSingleSideFlag: true,
      createdBy: 'WK001',
      createdAt: '2026-08-01T00:00:00Z',
      thresholdHuf: 5000000,
    },
  ]
}

/** R5/R6/R7/R10 közös bemenete: az űrlap kitöltése a baseline-tól eltérő értékekkel. */
function fillDifferingForm() {
  fireEvent.change(screen.getByLabelText('Hatálybalépés dátuma'), {
    target: { value: isoDaysFromToday(40) },
  })
  fireEvent.change(screen.getByLabelText('Alap ráta (%)'), { target: { value: '0.5' } })
  fireEvent.change(screen.getByLabelText('Alap plafon (Ft)'), { target: { value: '25000' } })
  fireEvent.change(screen.getByLabelText('Kiegészítő ráta (%)'), { target: { value: '0.5' } })
  fireEvent.change(screen.getByLabelText('Kiegészítő plafon (Ft)'), {
    target: { value: '25000' },
  })
}

describe('TransactionLevyRatesPage — FK-099', () => {
  beforeEach(() => {
    mocks.listRates.mockReset()
    mocks.createRate.mockReset()
    mocks.listRates.mockResolvedValue(RATES_DESC)
  })

  it('R1/FR-1 UI: a lista effectiveFrom DESC-rendezett és nincs szerkesztés/törlés vezérlő', async () => {
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

  it('R2/FR-18 UI: belso_ellenor (írás-jogosultság nélkül) NEM látja az új ráta űrlapot', async () => {
    mocks.roles.value = ['belso_ellenor']

    render(<TransactionLevyRatesPage />)

    await waitFor(() => expect(screen.getByText('2013-01-01')).toBeInTheDocument())
    expect(screen.queryByText('Új ráta rögzítése')).toBeNull()
    expect(screen.queryByRole('button', { name: 'Mentés' })).toBeNull()
  })

  it('R3/FR-18 UI: foertektar látja az űrlapot, a mentés a típusozott body-val hívja a createRate-et', async () => {
    mocks.roles.value = ['foertektar']
    mocks.createRate.mockResolvedValue(RATES_DESC[0])

    render(<TransactionLevyRatesPage />)

    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    // FK-100 FR-4: a baseline-tól (r2: 0.3/15000) eltérő űrlap megerősítő modált
    // nyitna — ezért a payload-alak pinje a baseline-azonos értékekkel fut
    // (a típusozott body-kontraktum ugyanúgy bizonyított; R5–R7 viseli a modált).
    fireEvent.change(screen.getByLabelText('Hatálybalépés dátuma'), {
      target: { value: '2026-09-15' },
    })
    fireEvent.change(screen.getByLabelText('Alap ráta (%)'), { target: { value: '0.3' } })
    fireEvent.change(screen.getByLabelText('Alap plafon (Ft)'), { target: { value: '15000' } })
    fireEvent.change(screen.getByLabelText('Kiegészítő ráta (%)'), { target: { value: '0.3' } })
    fireEvent.change(screen.getByLabelText('Kiegészítő plafon (Ft)'), {
      target: { value: '15000' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() =>
      expect(mocks.createRate).toHaveBeenCalledWith({
        effectiveFrom: '2026-09-15',
        baseRatePercent: 0.3,
        baseRateCapHuf: 15000,
        supplementRatePercent: 0.3,
        supplementRateCapHuf: 15000,
        conversionSingleSideFlag: true,
      }),
    )
  })

  it('R4: createRate batchelt validációs hibája szó szerint megjelenik', async () => {
    mocks.roles.value = ['foertektar']
    mocks.listRates.mockResolvedValue(RATES_DESC)
    // D6: valódi AxiosError (nem plain objektum) — a batchelt validációs üzenet
    // (`response.data.message`, FR-1 UI/D8) VERBATIM jelenik meg a getErrorMessage-en át.
    mocks.createRate.mockRejectedValue(
      new AxiosError(
        'Request failed with status code 400',
        'ERR_BAD_REQUEST',
        undefined,
        undefined,
        {
          data: {
            message:
              'A hatálybalépés dátuma csak jövőbeli lehet. A hatálybalépés dátuma nem lehet korábbi vagy azonos a legutolsó rögzített sorénál: 2026-08-15',
          },
          status: 400,
          statusText: 'Bad Request',
          headers: {},
          config: {},
        } as AxiosResponse,
      ),
    )

    render(<TransactionLevyRatesPage />)

    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    // FK-100 FR-4: baseline-azonos számértékek (0.3/15000), hogy a verbatim
    // hibaüzenet-pin ne a megerősítő modálon bukjon el (effectiveFrom nem
    // összehasonlított mező — C9).
    fireEvent.change(screen.getByLabelText('Hatálybalépés dátuma'), {
      target: { value: '2026-08-10' },
    })
    fireEvent.change(screen.getByLabelText('Alap ráta (%)'), { target: { value: '0.3' } })
    fireEvent.change(screen.getByLabelText('Alap plafon (Ft)'), { target: { value: '15000' } })
    fireEvent.change(screen.getByLabelText('Kiegészítő ráta (%)'), { target: { value: '0.3' } })
    fireEvent.change(screen.getByLabelText('Kiegészítő plafon (Ft)'), {
      target: { value: '15000' },
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

  // ============================ R5–R11: FK-100 FR-4 megerősítő modal + FR-1 info ============================

  it('R5/FR-4 (FK-100): baseline-tól eltérő értékek → alertdialog jelenlegi vs új értékekkel, createRate NÉLKÜL', async () => {
    mocks.roles.value = ['foertektar']
    mocks.listRates.mockResolvedValue(relativeRatesDesc())

    render(<TransactionLevyRatesPage />)
    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    fillDifferingForm()

    fireEvent.click(screen.getByRole('button', { name: 'Mentés' }))

    const dialog = await screen.findByRole('alertdialog')
    // Jelenlegi (baseline, ma hatályos: 0.3% / 15 000) vs új (0.5% / 25 000).
    expect(dialog).toHaveTextContent('0.3')
    expect(dialog).toHaveTextContent(fmtText(15000))
    expect(dialog).toHaveTextContent('0.5')
    expect(dialog).toHaveTextContent(fmtText(25000))
    // A kötelező visszavonhatatlanság-mondat (i18n).
    expect(dialog).toHaveTextContent('Ez a döntés a jövőben visszamenőlegesen nem módosítható.')
    expect(mocks.createRate).not.toHaveBeenCalled()
  })

  it('R6/FR-4 (FK-100): Mégse → dialog eltűnik, createRate NEM hívódik, az űrlap értékei megmaradnak', async () => {
    mocks.roles.value = ['foertektar']
    mocks.listRates.mockResolvedValue(relativeRatesDesc())

    render(<TransactionLevyRatesPage />)
    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    const dateValue = isoDaysFromToday(40)
    fillDifferingForm()
    fireEvent.click(screen.getByRole('button', { name: 'Mentés' }))

    await screen.findByRole('alertdialog')
    fireEvent.click(screen.getByRole('button', { name: 'Mégse' }))

    await waitFor(() => expect(screen.queryByRole('alertdialog')).toBeNull())
    expect(mocks.createRate).not.toHaveBeenCalled()
    // Az űrlap DOM-ja mounton maradt — a kitöltött értékek megőrződnek (uncontrolled).
    expect((screen.getByLabelText('Hatálybalépés dátuma') as HTMLInputElement).value).toBe(
      dateValue,
    )
    expect((screen.getByLabelText('Alap ráta (%)') as HTMLInputElement).value).toBe('0.5')
    expect((screen.getByLabelText('Alap plafon (Ft)') as HTMLInputElement).value).toBe('25000')
  })

  it('R7/FR-4 (FK-100): megerősítés → createRate PONTOSAN EGYSZER a parse-olt payload-dal', async () => {
    mocks.roles.value = ['foertektar']
    mocks.listRates.mockResolvedValue(relativeRatesDesc())
    mocks.createRate.mockResolvedValue(relativeRatesDesc()[0])

    render(<TransactionLevyRatesPage />)
    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    const dateValue = isoDaysFromToday(40)
    fillDifferingForm()
    fireEvent.click(screen.getByRole('button', { name: 'Mentés' }))

    await screen.findByRole('alertdialog')
    fireEvent.click(screen.getByRole('button', { name: 'Küldés megerősítése' }))

    await waitFor(() => expect(mocks.createRate).toHaveBeenCalledTimes(1))
    expect(mocks.createRate).toHaveBeenCalledWith({
      effectiveFrom: dateValue,
      baseRatePercent: 0.5,
      baseRateCapHuf: 25000,
      supplementRatePercent: 0.5,
      supplementRateCapHuf: 25000,
      conversionSingleSideFlag: true,
    })
  })

  it('R8/FR-4 (FK-100): baseline-nal azonos értékek → nincs dialog, közvetlen mentés', async () => {
    mocks.roles.value = ['foertektar']
    mocks.listRates.mockResolvedValue(relativeRatesDesc())
    mocks.createRate.mockResolvedValue(relativeRatesDesc()[1])

    render(<TransactionLevyRatesPage />)
    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    fireEvent.change(screen.getByLabelText('Hatálybalépés dátuma'), {
      target: { value: isoDaysFromToday(40) },
    })
    fireEvent.change(screen.getByLabelText('Alap ráta (%)'), { target: { value: '0.3' } })
    fireEvent.change(screen.getByLabelText('Alap plafon (Ft)'), { target: { value: '15000' } })
    fireEvent.change(screen.getByLabelText('Kiegészítő ráta (%)'), { target: { value: '0.3' } })
    fireEvent.change(screen.getByLabelText('Kiegészítő plafon (Ft)'), {
      target: { value: '15000' },
    })
    fireEvent.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() => expect(mocks.createRate).toHaveBeenCalledTimes(1))
    expect(screen.queryByRole('alertdialog')).toBeNull()
  })

  it('R9/FR-4 (FK-100): csak jövőbeli history-sorok → nincs baseline, nincs dialog, közvetlen mentés', async () => {
    mocks.roles.value = ['foertektar']
    mocks.listRates.mockResolvedValue([relativeRatesDesc()[0]]) // csak a ma+30 napos sor
    mocks.createRate.mockResolvedValue(relativeRatesDesc()[0])

    render(<TransactionLevyRatesPage />)
    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    fillDifferingForm()
    fireEvent.click(screen.getByRole('button', { name: 'Mentés' }))

    await waitFor(() => expect(mocks.createRate).toHaveBeenCalledTimes(1))
    expect(screen.queryByRole('alertdialog')).toBeNull()
  })

  it('R10/FR-4 (FK-100): Escape → dialog eltűnik, createRate NEM hívódik', async () => {
    mocks.roles.value = ['foertektar']
    mocks.listRates.mockResolvedValue(relativeRatesDesc())

    render(<TransactionLevyRatesPage />)
    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    fillDifferingForm()
    fireEvent.click(screen.getByRole('button', { name: 'Mentés' }))

    const dialog = await screen.findByRole('alertdialog')
    fireEvent.keyDown(dialog, { key: 'Escape' })

    await waitFor(() => expect(screen.queryByRole('alertdialog')).toBeNull())
    expect(mocks.createRate).not.toHaveBeenCalled()
  })

  it('R11/FR-1 UI (FK-100): a singleSideInfo tájékoztató szöveg megjelenik a checkbox mellett', async () => {
    mocks.roles.value = ['foertektar']

    render(<TransactionLevyRatesPage />)

    await waitFor(() => expect(screen.getByText('Új ráta rögzítése')).toBeInTheDocument())
    expect(
      screen.getByText(
        'A konverzió egyszeri adóztatása (TRUE alapértelmezés) könyvelői/adótanácsadói megerősítésre vár — nem végleges jogi állásfoglalás.',
      ),
    ).toBeInTheDocument()
  })
})
