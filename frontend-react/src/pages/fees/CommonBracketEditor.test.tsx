import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { AxiosError } from 'axios'
import CommonBracketEditor from './CommonBracketEditor'

const mocks = vi.hoisted(() => ({
  get: vi.fn(),
  saveDraft: vi.fn(),
  publish: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  handlingFeeBracketApi: { get: mocks.get, saveDraft: mocks.saveDraft, publish: mocks.publish },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: mocks.loggerError },
}))

const LIVE = [{ bracketOrder: 1, upperLimit: 100000, feeAmount: 200, active: true }]
const DRAFT = [{ bracketOrder: 1, upperLimit: 100000, feeAmount: 999, active: true }]

describe('CommonBracketEditor', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.get.mockResolvedValue({ live: LIVE, draft: [] })
  })

  it('megjeleníti a LIVE és (ha van) a DRAFT sáv-táblát', async () => {
    mocks.get.mockResolvedValue({ live: LIVE, draft: DRAFT })
    render(<CommonBracketEditor />)

    expect(await screen.findByText('Éles (LIVE) sávok')).toBeInTheDocument()
    expect(screen.getByText('Piszkozat (DRAFT) sávok')).toBeInTheDocument()
  })

  it('a Mentés (piszkozat) saveDraft-ot hív, és NEM publish-t', async () => {
    const user = userEvent.setup()
    mocks.saveDraft.mockResolvedValue({ live: LIVE, draft: LIVE })
    render(<CommonBracketEditor />)
    await screen.findByText('Éles (LIVE) sávok')

    await user.click(screen.getByRole('button', { name: 'Mentés (piszkozat)' }))

    await waitFor(() => {
      expect(mocks.saveDraft).toHaveBeenCalledTimes(1)
    })
    expect(mocks.publish).not.toHaveBeenCalled()
  })

  it('a Küldés megerősítéssel hív publish-t; megerősítés nélkül nem', async () => {
    const user = userEvent.setup()
    mocks.publish.mockResolvedValue({ live: LIVE, draft: [] })
    render(<CommonBracketEditor />)
    await screen.findByText('Éles (LIVE) sávok')

    await user.click(screen.getByRole('button', { name: 'Küldés' }))
    expect(mocks.publish).not.toHaveBeenCalled()

    const dialog = await screen.findByRole('alertdialog')
    expect(
      within(dialog).getByText('Biztosan elküldöd? Minden sávos irodára azonnal érvényes lesz.'),
    ).toBeInTheDocument()
    await user.click(within(dialog).getByRole('button', { name: 'Küldés megerősítése' }))

    await waitFor(() => {
      expect(mocks.publish).toHaveBeenCalledTimes(1)
    })
  })
  it('FR-4: a Tól (Ft) oszlop számított értékei (0, 100 001, 500 001) — LIVE és szerkesztő tábla', async () => {
    const live = [
      { bracketOrder: 1, upperLimit: 100000, feeAmount: 200, active: true },
      { bracketOrder: 2, upperLimit: 500000, feeAmount: 400, active: true },
      { bracketOrder: 3, upperLimit: 1000000, feeAmount: 900, active: true },
    ]
    mocks.get.mockResolvedValue({ live, draft: [] })
    render(<CommonBracketEditor />)
    await screen.findByText('Éles (LIVE) sávok')

    // A hu-HU ezres-elválasztója NBSP (U+00A0), a testing-library alap normalizere
    // viszont az NBSP-t sima szóközzé összevonja — ezért saját normalizerrel
    // bájt-pontos összehasonlítást végzünk (locale-elválasztó-független).
    const exact = (_text: string) => ({ normalizer: (t: string) => t })
    expect(screen.getAllByText(`${(0).toLocaleString('hu-HU')} Ft`, exact('0'))).toHaveLength(2)
    expect(
      screen.getAllByText(`${(100001).toLocaleString('hu-HU')} Ft`, exact('100001')),
    ).toHaveLength(2)
    expect(
      screen.getAllByText(`${(500001).toLocaleString('hu-HU')} Ft`, exact('500001')),
    ).toHaveLength(2)
  })

  it('FR-4: a szerkesztő táblában van Tól (Ft) fejléc, de nincs hozzá beviteli mező', async () => {
    const live = [
      { bracketOrder: 1, upperLimit: 100000, feeAmount: 200, active: true },
      { bracketOrder: 2, upperLimit: 500000, feeAmount: 400, active: true },
    ]
    mocks.get.mockResolvedValue({ live, draft: [] })
    render(<CommonBracketEditor />)
    await screen.findByText('Éles (LIVE) sávok')

    expect(screen.getAllByRole('columnheader', { name: 'Tól (Ft)' }).length).toBeGreaterThanOrEqual(
      2,
    )
    expect(screen.getAllByRole('spinbutton')).toHaveLength(4)
  })

  it('FR-7: részlegesen kitöltött új sor blokkolja a mentést — hibaüzenet, nincs API-hívás, a sor megmarad', async () => {
    const user = userEvent.setup()
    render(<CommonBracketEditor />)
    await screen.findByText('Éles (LIVE) sávok')

    await user.click(screen.getByRole('button', { name: '+ Új sáv' }))
    await user.click(screen.getByRole('button', { name: 'Mentés (piszkozat)' }))

    expect(
      await screen.findByText(/töltsd ki a felső határt és a díjat, vagy töröld a sort\./),
    ).toBeInTheDocument()
    expect(mocks.saveDraft).not.toHaveBeenCalled()
    expect(screen.getAllByRole('spinbutton')).toHaveLength(4)
  })

  it('FR-7: új sor törlése után a mentés az eredeti teljes sorokat küldi', async () => {
    const user = userEvent.setup()
    mocks.saveDraft.mockResolvedValue({ live: LIVE, draft: LIVE })
    render(<CommonBracketEditor />)
    await screen.findByText('Éles (LIVE) sávok')

    await user.click(screen.getByRole('button', { name: '+ Új sáv' }))
    await user.click(screen.getByRole('button', { name: '2. Sor törlése' }))
    await user.click(screen.getByRole('button', { name: 'Mentés (piszkozat)' }))

    await waitFor(() => {
      expect(mocks.saveDraft).toHaveBeenCalledTimes(1)
    })
    expect(mocks.saveDraft).toHaveBeenCalledWith(LIVE)
  })

  it('FR-6: a backend monotonitás-hibája változatlan szöveggel jelenik meg (getErrorMessage wiring)', async () => {
    const user = userEvent.setup()
    const backendMessage =
      '2. sáv: a felső határnak nagyobbnak kell lennie az előző sáv felső határánál (100000).'
    mocks.saveDraft.mockRejectedValue(
      new AxiosError(
        'Request failed with status code 400',
        'ERR_BAD_REQUEST',
        undefined as never,
        undefined as never,
        { data: { message: backendMessage } } as never,
      ),
    )
    render(<CommonBracketEditor />)
    await screen.findByText('Éles (LIVE) sávok')

    await user.click(screen.getByRole('button', { name: 'Mentés (piszkozat)' }))

    expect(await screen.findByText(backendMessage)).toBeInTheDocument()
  })

  it('FR-6 review-fix: publish 400 hibája is a backend üzenetét mutatja, nem a generikusat', async () => {
    const user = userEvent.setup()
    const backendMessage =
      'Érvénytelen sáv-készlet — 2. sáv: a felső határnak nagyobbnak kell lennie.'
    mocks.publish.mockRejectedValue(
      new AxiosError(
        'Request failed with status code 400',
        'ERR_BAD_REQUEST',
        undefined as never,
        undefined as never,
        { data: { message: backendMessage } } as never,
      ),
    )
    render(<CommonBracketEditor />)
    await screen.findByText('Éles (LIVE) sávok')

    await user.click(screen.getByRole('button', { name: 'Küldés' }))
    await user.click(await screen.findByRole('button', { name: 'Küldés megerősítése' }))

    expect(await screen.findByText(backendMessage)).toBeInTheDocument()
    expect(screen.queryByText('A sávok publikálása nem sikerült.')).not.toBeInTheDocument()
  })
})
