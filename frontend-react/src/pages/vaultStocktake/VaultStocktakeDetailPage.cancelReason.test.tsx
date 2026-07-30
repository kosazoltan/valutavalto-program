import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import VaultStocktakeDetailPage from './VaultStocktakeDetailPage'

// FKH-027 PR A (RED) — FR-8: a handleCancel a natív prompt() helyett a közös
// TextReasonModal-lal kéri be a megszakítás okát, "Megszakítás oka" title-lel.
// A 102. sori natív confirm() (lezárás) ebben a körben szándékosan NEM változik,
// ezért erre ez a teszt nem is állít semmit.

const mocks = vi.hoisted(() => ({
  create: vi.fn(),
  list: vi.fn(),
  get: vi.fn(),
  countItem: vi.fn(),
  review: vi.fn(),
  close: vi.fn(),
  cancel: vi.fn(),
  summary: vi.fn(),
}))

vi.mock('../../services/api/vaultStocktake', () => ({
  vaultStocktakeApi: {
    create: mocks.create,
    list: mocks.list,
    get: mocks.get,
    countItem: mocks.countItem,
    review: mocks.review,
    close: mocks.close,
    cancel: mocks.cancel,
    summary: mocks.summary,
  },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

const session = {
  id: 'session-1',
  companyId: 'company-1',
  branchId: 'branch-1',
  territoryId: null,
  sessionName: 'Havi értéktár-leltár',
  status: 'OPEN',
  startedAt: '2026-07-29T09:00:00',
  completedAt: null,
  startedBy: 'Kiss Anna',
  reviewedBy: null,
  approvedBy: null,
  note: null,
  discrepancyTotalHuf: 0,
  items: [],
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/vault-stocktake/session-1']}>
      <Routes>
        <Route path="/vault-stocktake/:id" element={<VaultStocktakeDetailPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('VaultStocktakeDetailPage — FR-8: megszakítási ok a TextReasonModal-lal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.get.mockResolvedValue(session)
    mocks.summary.mockResolvedValue(null)
    mocks.cancel.mockResolvedValue({ ...session, status: 'CANCELLED' })
    // A natív promptot lecseréljük, hogy assertálható legyen: az új folyamat NEM hívja
    vi.spyOn(window, 'prompt').mockReturnValue(null)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  async function openCancelModal(user: ReturnType<typeof userEvent.setup>) {
    renderPage()
    await user.click(await screen.findByRole('button', { name: 'Megszakitas' }))
    const dialog = await screen.findByRole('alertdialog')
    expect(dialog).toHaveAccessibleName('Megszakítás oka')
    expect(window.prompt).not.toHaveBeenCalled()
    return dialog
  }

  it('string-ág: a megadott okkal pontosan egyszer hívódik a vaultStocktakeApi.cancel', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.type(within(dialog).getByRole('textbox'), 'Rossz nyitó címletlista')
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() =>
      expect(mocks.cancel).toHaveBeenCalledWith('session-1', 'Rossz nyitó címletlista'),
    )
    expect(mocks.cancel).toHaveBeenCalledTimes(1)
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
  })

  it('null-ág: Mégse után nem hívódik a vaultStocktakeApi.cancel', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'Mégse' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.cancel).not.toHaveBeenCalled()
  })

  it('üres string: a hívó-oldali validáció megmarad — üres okkal nincs API-hívás', async () => {
    const user = userEvent.setup()
    const dialog = await openCancelModal(user)
    await user.click(within(dialog).getByRole('button', { name: 'OK' }))
    await waitFor(() => expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument())
    expect(mocks.cancel).not.toHaveBeenCalled()
  })
})
