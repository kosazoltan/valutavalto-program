import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { ReactNode } from 'react'
import EveningClosingPage from './EveningClosingPage'

/**
 * FKH-036 — Értéktári „Napi zárás" egyesített blokkoló zárás.
 *
 * WU-0 RED tesztek: ezek a tesztek a CÉLVISELKEDÉST pinelik, és a (termelési)
 * kód nélkül PIROSNAK kell lenniük:
 *  1. FR-1: az új DailyDataPackage-összefoglaló mezőkkel nem omlik össze az oldal.
 *  2. FR-1 védőháló: legacy (mezők nélküli) válasz sem dob hibát.
 *  3. FR-2: mountkor automatikusan betölt (előnézet + closing-status).
 *  4. FR-2: dátumváltásra újratölt.
 *  5. FR-3/FR-8: a becímletező CTA a checklist ELŐTT van a DOM-ban.
 *  6. FR-3: a CTA-link returnTo paraméterrel mutat a becímletezőre.
 */

const mocks = vi.hoisted(() => ({
  preview: vi.fn(),
  send: vi.fn(),
  report: vi.fn(),
  getStatus: vi.fn(),
  navigate: vi.fn(),
  toastWarning: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
  loggerError: vi.fn(),
}))

const authState = vi.hoisted(() => ({
  worker: {
    id: 77,
    workerCode: 'ERTEKTAR',
    firstName: 'Értéktár',
    lastName: 'Teszt',
    fullName: 'Teszt Értéktár',
    role: 'ERTEKTAR',
    branchId: 'branch-1',
    branchCode: 'VT01',
    branchName: 'Értéktár 01',
    companyId: 'company-1',
    companyCode: 'EBC',
    companyName: 'Exclusive Best Change',
  },
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (key: string) => key }),
}))

vi.mock('../../utils/dateFormat', () => ({
  localIsoDate: () => '2026-06-18',
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) => selector(authState),
}))

vi.mock('react-router-dom', () => ({
  Link: ({ to, children }: { to: string; children: ReactNode }) => <a href={to}>{children}</a>,
  useNavigate: () => mocks.navigate,
}))

vi.mock('../../services/api/index', () => ({
  eveningClosingApi: { preview: mocks.preview, send: mocks.send, report: mocks.report },
  closingWizardApi: { getStatus: mocks.getStatus },
}))

vi.mock('../../components/closing/VaultClosingChecklistPanel', () => ({
  default: () => <div data-testid="vault-closing-checklist" />,
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    warning: mocks.toastWarning,
    success: mocks.toastSuccess,
    error: mocks.toastError,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: {
    error: mocks.loggerError,
  },
}))

/** FKH-036 WU-1 után ezt az alakot adja a backend (JsonInclude.NON_NULL). */
const FULL_SHAPE_PREVIEW = {
  branchId: 1,
  branchName: 'Értéktár 01',
  date: '2026-06-18',
  status: 'PREVIEW',
  transactionCount: 2,
  totalBuyHuf: 150000,
  totalSellHuf: 90000,
  pendingSyncs: 0,
  openReservations: 0,
  warnings: [],
  balances: [{ currency: 'HUF', amount: 1200000 }],
  packages: [
    {
      packageId: 'FF-20260618-0001',
      currency: 'EUR',
      amount: 5000,
      sealNumber: 'PL-001',
      destination: 'Budapest 02',
    },
  ],
  transactions: [],
  denominations: [],
  rates: [],
  customers: [],
  reservations: [],
  handlingFees: null,
  checksum: 'abc123',
}

/** A WU-1 előtti backend-válasz alakja — összefoglaló mezők nélkül. */
const LEGACY_SHAPE_PREVIEW = {
  branchId: 1,
  date: '2026-06-18',
  transactions: [],
  denominations: [],
  rates: [],
  customers: [],
  reservations: [],
  handlingFees: null,
  checksum: 'x',
}

const VAULT_STATUS = {
  branchId: 'branch-1',
  closingDate: '2026-06-18',
  vaultContext: true,
  denominationRecorded: true,
  exactMatch: true,
  message: 'A zárási címletezés pontosan egyezik a nyilvántartással.',
  differences: [],
  activeWizardId: null,
  activeWizardStatus: null,
  requiredCurrencies: ['HUF', 'EUR'],
  handlingFeeRequired: false,
}

beforeEach(() => {
  vi.clearAllMocks()
  mocks.preview.mockResolvedValue(FULL_SHAPE_PREVIEW)
  mocks.getStatus.mockResolvedValue(VAULT_STATUS)
})

describe('EveningClosingPage — FKH-036', () => {
  it('FR-1: valós DailyDataPackage-alakú válaszon nem omlik össze', async () => {
    render(<EveningClosingPage />)

    // FR-2 auto-load: a mountkor induló előnézet-hívás oldja meg a preview-t.
    await waitFor(() => expect(mocks.preview).toHaveBeenCalledTimes(1))

    // Az összefoglaló mezők renderelődnek (2 tranzakció; 150 000 Ft hu-HU formátumban).
    expect(await screen.findByText('2')).toBeInTheDocument()
    expect(await screen.findByText(/150[  ]000/)).toBeInTheDocument()
    // A nyers lista-mezők ellenére nincs összeomlás.
    expect(screen.queryByText(/Váratlan hiba/)).toBeNull()
  })

  it('FR-1 védőháló: legacy (mezők nélküli) válaszon sem omlik össze', async () => {
    mocks.preview.mockResolvedValue(LEGACY_SHAPE_PREVIEW)

    render(<EveningClosingPage />)

    await waitFor(() => expect(mocks.preview).toHaveBeenCalledTimes(1))

    // A preview-ág renderelődik (a status-jelvény megjelenik), de egyetlen undefined-olvasás
    // sem dobhat — a warnings/balances/packages/numeric mezők mind opcionálisak.
    await waitFor(() => expect(screen.getByText('closing.nemIndult')).toBeInTheDocument())
    expect(screen.queryByText(/Cannot read properties of undefined/)).toBeNull()
  })

  it('FR-2: mountkor automatikusan betölt (előnézet + zárás-státusz)', async () => {
    render(<EveningClosingPage />)

    await waitFor(() => {
      expect(mocks.preview).toHaveBeenCalledTimes(1)
      expect(mocks.preview).toHaveBeenCalledWith('branch-1', '2026-06-18')
      expect(mocks.getStatus).toHaveBeenCalledWith('2026-06-18')
    })
  })

  it('FR-2: dátumváltásra újratölt az új dátummal', async () => {
    render(<EveningClosingPage />)

    await waitFor(() => expect(mocks.preview).toHaveBeenCalledTimes(1))
    expect(mocks.preview).toHaveBeenLastCalledWith('branch-1', '2026-06-18')

    const dateInput = document.querySelector('input[type="date"]')!
    fireEvent.change(dateInput, { target: { value: '2026-06-19' } })

    await waitFor(() => {
      expect(mocks.preview).toHaveBeenLastCalledWith('branch-1', '2026-06-19')
    })
    expect(mocks.preview).toHaveBeenCalledTimes(2)
  })

  it('FR-3/FR-8: a becímletező CTA-szekció a checklist ELŐTT van a DOM-ban', async () => {
    render(<EveningClosingPage />)

    const cta = await screen.findByTestId('fkh036-denomination-cta')
    const checklist = screen.getByTestId('vault-closing-checklist')

    // A checklist a CTA-t követő pozícióban van a dokumentumban.
    expect(cta.compareDocumentPosition(checklist) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('FR-3: az EVENING CTA returnTo paraméterrel mutat a becímletezőre', async () => {
    render(<EveningClosingPage />)

    const cta = await screen.findByTestId('fkh036-denomination-cta')
    const eveningLink = within(cta).getByText('Esti zárás címletezése')
    expect(eveningLink.getAttribute('href')).toBe(
      '/closing/denomination-entry/EVENING?returnTo=%2Fevening-closing',
    )
  })

  // ——— FKH-036 kieg. #2 FR-14: valuta-CTA → checklist → kezelési díj CTA sorrend ———

  it('FKH-036 kieg. #2 FR-14: handlingFeeRequired esetén a kezelési díj CTA a checklist UTÁN van', async () => {
    mocks.getStatus.mockResolvedValue({ ...VAULT_STATUS, handlingFeeRequired: true })
    render(<EveningClosingPage />)

    const cta = await screen.findByTestId('fkh036-denomination-cta')
    const checklist = screen.getByTestId('vault-closing-checklist')
    const fee = await screen.findByTestId('fkh036-handling-fee-cta')

    // DOM-sorrend: valuta-CTA < checklist < kezelési díj CTA.
    expect(cta.compareDocumentPosition(checklist) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
    expect(checklist.compareDocumentPosition(fee) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()

    const feeLink = within(fee).getByText('Kezelési díj címletezése')
    expect(feeLink.getAttribute('href')).toBe(
      '/closing/denomination-entry/HANDLING_FEE?returnTo=%2Fevening-closing',
    )
    // A kezelési díj CTA már NEM lehet a valuta-CTA panelen belül.
    expect(within(cta).queryByText('Kezelési díj címletezése')).toBeNull()
  })

  it('FKH-036 kieg. #2 FR-14: handlingFeeRequired nélkül nincs kezelési díj CTA, a sorrend valuta-CTA → checklist', async () => {
    // Default VAULT_STATUS (handlingFeeRequired: false).
    render(<EveningClosingPage />)

    const cta = await screen.findByTestId('fkh036-denomination-cta')
    const checklist = screen.getByTestId('vault-closing-checklist')

    expect(screen.queryByTestId('fkh036-handling-fee-cta')).toBeNull()
    expect(cta.compareDocumentPosition(checklist) & Node.DOCUMENT_POSITION_FOLLOWING).toBeTruthy()
  })

  it('Round-2 rework: több tételes shipmentnél nincs React duplicate-key diagnózis és minden sor renderelődik', async () => {
    // A backend ShipmentRequestItem-enként vetít ki csomag-sort — egy több tételes FF
    // shipment több AZONOS packageId-jú sort ad. A kulcsnak soronként egyedinek kell
    // lennie, különben React "Encountered two children with the same key" figyelmeztetést
    // ad, és a sorok renderelése nem determinisztikus.
    const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {})
    mocks.preview.mockResolvedValue({
      ...FULL_SHAPE_PREVIEW,
      packages: [
        {
          packageId: 'FF-20260618-0001',
          currency: 'EUR',
          amount: 5000,
          sealNumber: 'PL-001',
          destination: 'Budapest 02',
        },
        {
          packageId: 'FF-20260618-0001',
          currency: 'USD',
          amount: 3000,
          sealNumber: 'PL-001',
          destination: 'Budapest 02',
        },
      ],
    })

    render(<EveningClosingPage />)

    await waitFor(() => expect(mocks.preview).toHaveBeenCalledTimes(1))

    // Mindkét tétel-sor renderelődik (a két valuta-cellával és a közös csomagid kétszer).
    expect(await screen.findByText('EUR')).toBeInTheDocument()
    expect(await screen.findByText('USD')).toBeInTheDocument()
    expect(screen.getAllByText('FF-20260618-0001')).toHaveLength(2)

    // Nem érkezett React duplicate-key diagnózis a konzolra.
    const duplicateKeyCalls = consoleErrorSpy.mock.calls.filter((args) =>
      args.some((arg) => typeof arg === 'string' && arg.includes('children with the same key')),
    )
    expect(duplicateKeyCalls).toHaveLength(0)

    consoleErrorSpy.mockRestore()
  })
})
