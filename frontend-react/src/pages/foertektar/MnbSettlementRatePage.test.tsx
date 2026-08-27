import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MnbSettlementRatePage from './MnbSettlementRatePage'

const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  update: vi.fn(),
  publish: vi.fn(),
  mnbQuery: vi.fn(),
  toastSuccess: vi.fn(),
  toastError: vi.fn(),
  canEdit: true,
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: {
    success: mocks.toastSuccess,
    error: mocks.toastError,
    warning: vi.fn(),
    info: vi.fn(),
  },
}))

vi.mock('../../services/api/index', () => ({
  mnbSettlementRateApi: {
    list: mocks.list,
    update: mocks.update,
    publish: mocks.publish,
    mnbQuery: mocks.mnbQuery,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (
    selector: (state: { hasCanonicalRole: (roles: string | string[]) => boolean }) => unknown,
  ) =>
    selector({
      hasCanonicalRole: (roles: string | string[]) => {
        const requested = Array.isArray(roles) ? roles : [roles]
        return mocks.canEdit && requested.includes('foertektar')
      },
    }),
}))

const baseRows = [
  {
    currencyCode: 'HUF',
    currencyName: 'Magyar forint',
    officialRate: 1,
    availableToOfficesAt: null,
  },
  {
    currencyCode: 'EUR',
    currencyName: 'Euró',
    officialRate: 400,
    availableToOfficesAt: null,
  },
  {
    currencyCode: 'USD',
    currencyName: 'USA dollár',
    officialRate: 300,
    availableToOfficesAt: '2026-07-01T10:00:00Z',
  },
  {
    currencyCode: 'GBP',
    currencyName: 'Angol font',
    officialRate: 0,
    availableToOfficesAt: null,
  },
]

async function renderLoaded() {
  render(<MnbSettlementRatePage />)
  await screen.findByTestId('mnb-settlement-grid')
}

describe('FK-028 — MNB árfolyamok rögzítése oldal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.canEdit = true
    mocks.list.mockResolvedValue(baseRows)
    mocks.update.mockResolvedValue(baseRows)
    mocks.publish.mockResolvedValue(baseRows)
    mocks.mnbQuery.mockResolvedValue([])
  })

  it('lista-render: data-grid táblázat, HUF fix 1,0000 és nem szerkeszthető', async () => {
    await renderLoaded()

    const grid = await screen.findByTestId('mnb-settlement-grid')
    expect(grid.className).toContain('data-grid')
    expect(screen.getByText('Kód')).toBeInTheDocument()
    expect(screen.getByText('Euró')).toBeInTheDocument()
    expect(screen.getByTestId('huf-rate')).toHaveTextContent('1,0000')
    expect(screen.queryByLabelText('HUF árfolyam')).not.toBeInTheDocument()
  })

  it('input-szerkesztés után a Rögzítés csak a módosult nem-HUF sort küldi', async () => {
    await renderLoaded()

    fireEvent.change(await screen.findByLabelText('EUR árfolyam'), {
      target: { value: '401.2500' },
    })
    fireEvent.click(screen.getByRole('button', { name: /^Rögzítés$/ }))

    await waitFor(() => {
      expect(mocks.update).toHaveBeenCalledWith([{ currencyCode: 'EUR', officialRate: 401.25 }])
    })
    expect(mocks.update).not.toHaveBeenCalledWith(
      expect.arrayContaining([expect.objectContaining({ currencyCode: 'HUF' })]),
    )
    expect(mocks.toastSuccess).toHaveBeenCalledWith('MNB árfolyamok rögzítve')
  })

  it('MNB letöltés siker: előtölti a nem-HUF inputokat, HUF változatlan', async () => {
    mocks.mnbQuery.mockResolvedValue([
      { currencyCode: 'EUR', officialRate: 410.125 },
      { currencyCode: 'USD', officialRate: 309.5 },
      { currencyCode: 'HUF', officialRate: 2 },
    ])
    await renderLoaded()

    fireEvent.click(screen.getByRole('button', { name: 'MNB letöltés' }))

    await waitFor(() => expect(screen.getByLabelText('EUR árfolyam')).toHaveValue('410.1250'))
    expect(screen.getByLabelText('USD árfolyam')).toHaveValue('309.5000')
    expect(screen.getByTestId('huf-rate')).toHaveTextContent('1,0000')
    expect(mocks.toastSuccess).toHaveBeenCalledWith('MNB árfolyamok letöltve')
  })

  it('MNB letöltés hiba: toast error és a mezők változatlanok maradnak', async () => {
    mocks.mnbQuery.mockRejectedValue(new Error('MNB nem elérhető'))
    await renderLoaded()

    fireEvent.click(screen.getByRole('button', { name: 'MNB letöltés' }))

    await waitFor(() =>
      expect(mocks.toastError).toHaveBeenCalledWith('MNB letöltés sikertelen', 'MNB nem elérhető'),
    )
    expect(screen.getByLabelText('EUR árfolyam')).toHaveValue('400.0000')
    expect(screen.getByLabelText('USD árfolyam')).toHaveValue('300.0000')
  })

  it('±10% figyelmeztetés: >10% igen, pontosan 10% és prev=0 nem', async () => {
    await renderLoaded()

    fireEvent.change(await screen.findByLabelText('EUR árfolyam'), {
      target: { value: '440.1000' },
    })
    fireEvent.blur(screen.getByLabelText('EUR árfolyam'))
    expect(await screen.findByTestId('rate-warning-EUR')).toBeInTheDocument()

    fireEvent.change(screen.getByLabelText('EUR árfolyam'), { target: { value: '440.0000' } })
    await waitFor(() => expect(screen.queryByTestId('rate-warning-EUR')).not.toBeInTheDocument())

    fireEvent.change(screen.getByLabelText('GBP árfolyam'), { target: { value: '100.0000' } })
    expect(screen.queryByTestId('rate-warning-GBP')).not.toBeInTheDocument()
  })

  it('MNB-preview után is megjelenik a >10% figyelmeztetés', async () => {
    mocks.mnbQuery.mockResolvedValue([{ currencyCode: 'EUR', officialRate: 441 }])
    await renderLoaded()

    fireEvent.click(screen.getByRole('button', { name: 'MNB letöltés' }))

    expect(await screen.findByTestId('rate-warning-EUR')).toBeInTheDocument()
  })

  it('Rögzítés + Küldés irodáknak üres payloaddal is hívható', async () => {
    await renderLoaded()

    fireEvent.click(screen.getByRole('button', { name: 'Rögzítés + Küldés irodáknak' }))

    await waitFor(() => expect(mocks.publish).toHaveBeenCalledWith([]))
    expect(mocks.toastSuccess).toHaveBeenCalledWith(
      'MNB árfolyamok rögzítve és kiküldve az irodáknak',
    )
  })

  it('read-only mód belső ellenőrnek: inputok és gombok tiltottak', async () => {
    mocks.canEdit = false
    await renderLoaded()

    expect(screen.getByLabelText('EUR árfolyam')).toBeDisabled()
    expect(screen.getByLabelText('USD árfolyam')).toBeDisabled()
    expect(screen.getByRole('button', { name: 'MNB letöltés' })).toBeDisabled()
    expect(screen.getByRole('button', { name: /^Rögzítés$/ })).toBeDisabled()
    expect(screen.getByRole('button', { name: 'Rögzítés + Küldés irodáknak' })).toBeDisabled()
    expect(screen.getByText(/Olvasási mód/)).toBeInTheDocument()
  })
})
