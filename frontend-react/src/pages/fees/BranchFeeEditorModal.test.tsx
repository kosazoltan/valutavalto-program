import { render, screen, waitFor, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import BranchFeeEditorModal from './BranchFeeEditorModal'
import type { BranchFeeConfigRow } from '../../services/api/settings'

const mocks = vi.hoisted(() => ({
  saveDraft: vi.fn(),
  publish: vi.fn(),
  loggerError: vi.fn(),
}))

vi.mock('../../services/api/settings', () => ({
  branchFeeConfigApi: { saveDraft: mocks.saveDraft, publish: mocks.publish },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: mocks.loggerError },
}))

const ROW: BranchFeeConfigRow = {
  branchId: 'b1',
  branchCode: 'B01',
  branchName: 'Budapest 1',
  region: 'BUDAPEST',
  liveFeeMode: 'PER_MILLE',
  livePerMilleRate: 3.5,
  livePerMilleCap: 2003,
  hasDraft: false,
  draftFeeMode: null,
  draftPerMilleRate: null,
  draftPerMilleCap: null,
  version: 0,
}

function renderModal(row: BranchFeeConfigRow = ROW) {
  return render(
    <BranchFeeEditorModal row={row} onClose={() => undefined} onChanged={() => undefined} />,
  )
}

describe('BranchFeeEditorModal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('a LIVE mód NONE esetén megjelenik az örökölt-érték banner és a Küldés tiltott', () => {
    renderModal({
      ...ROW,
      liveFeeMode: 'NONE',
      livePerMilleRate: null,
      livePerMilleCap: null,
    })

    expect(
      screen.getByText(
        'Jelenleg nincs kezelési díj beállítva (örökölt érték) — válassz módot a küldéshez.',
      ),
    ).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Küldés' })).toBeDisabled()
  })

  it('a Mentés (piszkozat) NEM változtatja a LIVE oszlopot — csak saveDraft hívódik (FR-8)', async () => {
    const user = userEvent.setup()
    // ITEM 5 (R2-WU-9): a mock a VALÓS controller JSON-t adja (sor-alakú DTO):
    // a LIVE oszlopok érintetlenek, a DRAFT oszlopok az új értékek, verzió növelve.
    mocks.saveDraft.mockResolvedValue({
      ...ROW,
      hasDraft: true,
      draftFeeMode: 'PER_MILLE',
      draftPerMilleRate: 5,
      draftPerMilleCap: 2003,
      version: 1,
    })
    renderModal()

    await user.click(screen.getByRole('radio', { name: /Ezrelékes/ }))
    const rateInput = screen.getByLabelText('Ezrelék mértéke')
    await user.clear(rateInput)
    await user.type(rateInput, '5')
    await user.click(screen.getByRole('button', { name: 'Mentés (piszkozat)' }))

    await waitFor(() => {
      expect(mocks.saveDraft).toHaveBeenCalledTimes(1)
    })
    expect(mocks.saveDraft).toHaveBeenCalledWith('b1', {
      feeMode: 'PER_MILLE',
      perMilleRate: 5,
      perMilleCap: 2003,
    })
    expect(mocks.publish).not.toHaveBeenCalled()
  })

  it('a Küldés megerősítő párbeszédet nyit (role=alertdialog), Esc megszakít', async () => {
    const user = userEvent.setup()
    renderModal()

    await user.click(screen.getByRole('radio', { name: /Ezrelékes/ }))
    await user.click(screen.getByRole('button', { name: 'Küldés' }))

    const dialog = await screen.findByRole('alertdialog')
    expect(
      within(dialog).getByText('Biztosan elküldöd? Az iroda mostantól ezzel az értékkel számol.'),
    ).toBeInTheDocument()

    await user.keyboard('{Escape}')
    expect(screen.queryByRole('alertdialog')).not.toBeInTheDocument()
    expect(mocks.publish).not.toHaveBeenCalled()
  })

  it('megerősítéskor publish(branchId, version) hívódik — version=0 legitim (B2)', async () => {
    const user = userEvent.setup()
    // ITEM 5 (R2-WU-9): a VALÓS publish-válasz sor-alakú — a LIVE oszlopok a
    // publikált értéket hordozzák, a DRAFT oszlopok kiürülnek, verzió növelve.
    mocks.publish.mockResolvedValue({
      ...ROW,
      livePerMilleRate: 5,
      hasDraft: false,
      draftFeeMode: null,
      draftPerMilleRate: null,
      draftPerMilleCap: null,
      version: 1,
    })
    renderModal()

    await user.click(screen.getByRole('radio', { name: /Ezrelékes/ }))
    await user.click(screen.getByRole('button', { name: 'Küldés' }))
    const dialog = await screen.findByRole('alertdialog')
    await user.click(within(dialog).getByRole('button', { name: 'Küldés megerősítése' }))

    await waitFor(() => {
      expect(mocks.publish).toHaveBeenCalledTimes(1)
    })
    expect(mocks.publish).toHaveBeenCalledWith('b1', 0)
  })
  it('FR-5: az élő konfiguráció audit-blokkja megjelenik (KOSA / EDIT / 2026-08-26 19:04 / 2026-08-26)', () => {
    renderModal({
      ...ROW,
      createdBy: 'KOSA',
      publishedBy: 'EDIT',
      publishedAt: '2026-08-26T19:04:11',
      validFrom: '2026-08-26',
    })

    // FK-098 review-fix: a dátumok helyes címkéhez párosítva — publishedAt a
    // "Publikálva" (időbélyeg), validFrom az "Érvényes" (nap) mellé kerül; a régi
    // félrevezető "Élő konfiguráció eredete" címke-dátum páros megszűnt.
    expect(screen.getByText('KOSA')).toBeInTheDocument()
    expect(screen.getByText('EDIT')).toBeInTheDocument()
    expect(screen.getByText('2026-08-26 19:04')).toBeInTheDocument()
    expect(screen.getByText('2026-08-26')).toBeInTheDocument()
  })

  it('FR-5: hiányzó audit-adatoknál a címkék kötőjellel jelennek meg (nincs crash, nincs Invalid Date)', () => {
    renderModal()

    // determinista: a Létrehozta/Élesítette címkék i18n-alapúak — a '—' dash-count marad a fő assert
    expect(screen.getAllByText('—').length).toBeGreaterThanOrEqual(4)
    expect(screen.queryByText(/Invalid Date/)).not.toBeInTheDocument()
  })

  it('FR-5: LIVE mód nélkül (null) az audit-blokk rejtve marad', () => {
    renderModal({ ...ROW, liveFeeMode: null })
    expect(screen.queryByText('KOSA')).not.toBeInTheDocument()
    expect(screen.queryByText('Élesítette')).not.toBeInTheDocument()
  })
})
