/**
 * __holdout__ teszt — transfers címke↔route szemantikai paritás.
 *
 * HOLDOUT PROTOKOLL: ezt a fájlt a coder NEM látta és nem implementált ellene.
 * Az orchestrator adta hozzá a dev-loop pipeline ZÖLD lezárása UTÁN, független
 * elfogadási bizonyítékként (terv: .hermes/plans/2026-07-14-transfers-relabel-split-holdout.md).
 * A teszt-integritási szabály erre is vonatkozik: RED esetén a KÓD javul, nem a teszt.
 *
 * (A) menü-szemantika: a címke pontosan azt ígéri, amit a route csinál (mock nélkül).
 * (B) felület-szemantika: a /transfers nem hordoz önálló create-űrlapot; a
 *     /transfers/new hordozza a teljes create-űrlapot (render-szintű bizonyítás).
 */
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { menuGroups } from '../../layouts/menuGroups'
import { effectiveCanonicalRolesForPath } from '../../layouts/menuVisibility'
import TransferPage from './TransferPage'
import TransferCreatePage from './TransferCreatePage'

// ── (A) Menü címke↔route paritás — pure, mock nélkül ────────────────────────
const allItems = menuGroups.flatMap((g) => g.items.map((i) => ({ ...i, group: g.label })))

describe('__holdout__ transfers címke↔route szemantikai paritás', () => {
  it('nincs olyan bejegyzés, amely "aláírás" címkével a létrehozó felületre visz', () => {
    const misleading = allItems.filter(
      (i) => /aláír/i.test(i.label) && i.path === '/transfers/new',
    )
    expect(misleading).toEqual([])
  })

  it('a régi egybemosott "Átadás-átvétel aláírás" címke sehol nem létezik', () => {
    expect(allItems.filter((i) => i.label === 'Átadás-átvétel aláírás')).toEqual([])
  })

  it('minden /transfers bejegyzés a visszaigazolást ígéri, és NEM ígér létrehozást', () => {
    const entries = allItems.filter((i) => i.path === '/transfers')
    expect(entries.length).toBeGreaterThanOrEqual(2) // penztar + ertektar csoport
    for (const e of entries) {
      expect(e.label).toMatch(/visszaigazolás/i)
      expect(e.label).not.toMatch(/^Új/i) // a címke ne KEZDŐDJÖN "Új"-jal
      expect(e.label).not.toMatch(/rögzítés|létrehoz/i) // se "rögzítés"/"létrehoz" bárhol
    }
  })

  it('minden /transfers/new bejegyzés a létrehozást ígéri, és NEM a puszta aláírást', () => {
    const entries = allItems.filter((i) => i.path === '/transfers/new')
    expect(entries.length).toBeGreaterThanOrEqual(2)
    for (const e of entries) {
      expect(e.label).toMatch(/Új|rögzítés/i)
      expect(e.label).not.toMatch(/aláír/i)
    }
  })

  it('mindkét route menü-gate-elhető (penztar+ertektar+ertekszallito unió)', () => {
    for (const path of ['/transfers', '/transfers/new']) {
      const roles = effectiveCanonicalRolesForPath(menuGroups, path)
      expect(roles, `${path} szerepkör-uniója`).toBeDefined()
      expect([...(roles ?? [])].sort()).toEqual(['ertekszallito', 'ertektar', 'penztar'])
    }
  })
})

// ── (B) Felület-szemantika — render-szintű, egyesített mock-állványzat ───────
const mocks = vi.hoisted(() => ({
  // TransferPage (visszaigazolás) lista-hívások
  getOutgoing: vi.fn(),
  getIncoming: vi.fn(),
  getPending: vi.fn(),
  countPending: vi.fn(),
  // TransferCreatePage create-hívások
  create: vi.fn(),
  getActive: vi.fn(),
  listActive: vi.fn(),
  cashBalanceList: vi.fn(),
  rateList: vi.fn(),
  denominationList: vi.fn(),
  isElectronQueueAvailable: vi.fn(),
  saveAndSyncPendingTransfer: vi.fn(),
  getElectronCachedRates: vi.fn(),
  getLocalPendingTransfers: vi.fn(),
  toast: { success: vi.fn(), warning: vi.fn(), error: vi.fn(), info: vi.fn() },
}))

vi.mock('../../services/api/index', () => ({
  transferApi: {
    getOutgoing: mocks.getOutgoing,
    getIncoming: mocks.getIncoming,
    getPending: mocks.getPending,
    countPending: mocks.countPending,
    getById: vi.fn(),
    getByTransferNumber: vi.fn(),
    receive: vi.fn(),
    reject: vi.fn(),
    cancel: vi.fn(),
    storno: vi.fn(),
    getStornoPreview: vi.fn(),
    create: mocks.create,
  },
  currencyApi: { getActive: mocks.getActive },
  branchApi: { listActive: mocks.listActive },
  cashBalanceApi: { list: mocks.cashBalanceList },
  denominationApi: { getByCurrencyId: mocks.denominationList },
  exchangeRateApi: { list: mocks.rateList },
}))

vi.mock('../../stores/authStore', () => {
  const state = {
    worker: {
      id: 9,
      fullName: 'Fabulya Zsuzsanna',
      branchId: 'b-own',
      branchCode: 'BR076',
      branchName: 'Pécsi értéktár',
      companyCode: 'EBC',
    },
  }
  return {
    useAuthStore: (selector?: (s: typeof state) => unknown) =>
      selector ? selector(state) : state,
  }
})

vi.mock('../../utils/electronTransactions', () => ({
  isElectronQueueAvailable: mocks.isElectronQueueAvailable,
  recordLocalAuditEvent: vi.fn(),
  saveAndSyncPendingTransfer: mocks.saveAndSyncPendingTransfer,
  getElectronCachedRates: mocks.getElectronCachedRates,
}))

vi.mock('../../utils/localQueue', () => ({
  getLocalPendingTransfers: mocks.getLocalPendingTransfers,
  getCompanyType: () => 'BEST_CHANGE',
  queueOfflineTransferStorno: vi.fn(),
}))

vi.mock('../../components/auth/SupervisorPinModal', () => ({ default: () => null }))

vi.mock('../../components/NumberInput', () => ({
  NumberInput: ({
    value,
    onChange,
    id,
    placeholder,
  }: {
    value: string
    onChange: (v: string) => void
    id?: string
    placeholder?: string
  }) => (
    <input
      id={id}
      placeholder={placeholder}
      value={value}
      onChange={(event) => onChange(event.target.value)}
    />
  ),
}))

vi.mock('../../utils/electron', () => ({ isElectron: () => true }))
vi.mock('../../components/ui/toaster', () => ({ toast: mocks.toast }))

const pendingTransfer = {
  id: 7,
  transferNumber: 'AT-LIST-007',
  fromBranchCode: 'BR001',
  fromBranchName: 'Budapesti értéktár',
  toBranchCode: 'BR076',
  toBranchName: 'Pécsi értéktár',
  fromWorkerName: 'Lista Béla',
  transferDate: '2026-06-19',
  transferTime: '10:00:00',
  currencyCode: 'EUR',
  amount: 100,
  hufValue: 39000,
  status: 'PENDING',
  statusDisplay: 'Átvételre vár',
  isPending: true,
  isCompleted: false,
  direction: 'U',
  transferType: 'CURRENCY',
  transferTypeDisplay: 'Deviza',
}

describe('__holdout__ a felületek funkció-hordozója szétvált', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.isElectronQueueAvailable.mockReturnValue(false)
    mocks.getLocalPendingTransfers.mockResolvedValue([])
    mocks.getOutgoing.mockResolvedValue([])
    mocks.getIncoming.mockResolvedValue([])
    mocks.getPending.mockResolvedValue([pendingTransfer])
    mocks.countPending.mockResolvedValue(1)
    mocks.getActive.mockResolvedValue([
      { id: 1, code: 'EUR', name: 'Euró' },
      { id: 2, code: 'HUF', name: 'Forint' },
    ])
    mocks.listActive.mockResolvedValue([
      { id: 'b-own', code: 'BR076', name: 'Pécsi értéktár', isVault: true, branchTypeCode: 'VAULT' },
      { id: 'b-target', code: 'BR001', name: 'Budapesti értéktár', isVault: true, branchTypeCode: 'VAULT' },
    ])
    mocks.cashBalanceList.mockResolvedValue([{ currencyCode: 'EUR', currentBalance: 100000 }])
    mocks.rateList.mockResolvedValue([])
    mocks.getElectronCachedRates.mockResolvedValue([])
    mocks.denominationList.mockResolvedValue([])
  })

  it('a /transfers (visszaigazolás) NEM hordoz create-űrlapot — csak navigációt', async () => {
    render(
      <MemoryRouter>
        <TransferPage />
      </MemoryRouter>,
    )
    await screen.findByText('AT-LIST-007') // a lista betöltődött (a 19 prod-sor útvonala él)
    // create-funkció-hordozók HIÁNYA:
    expect(screen.queryByText('Átadás létrehozása')).not.toBeInTheDocument()
    expect(document.querySelector('#transfer-type')).toBeNull()
    expect(document.querySelector('#to-branch')).toBeNull()
    // a létrehozás felé KIZÁRÓLAG navigáció létezik:
    expect(screen.getByRole('link', { name: /Új átadás/ })).toHaveAttribute('href', '/transfers/new')
  })

  it('a /transfers/new (létrehozás) hordozza a teljes create-űrlapot, lista-tabok nélkül', async () => {
    render(
      <MemoryRouter initialEntries={['/transfers/new']}>
        <TransferCreatePage />
      </MemoryRouter>,
    )
    await waitFor(() => expect(document.querySelector('#transfer-type')).not.toBeNull())
    // create-funkció-hordozók MEGLÉTE:
    expect(document.querySelector('#to-branch')).not.toBeNull()
    expect(screen.getByText('Átadás létrehozása')).toBeInTheDocument()
    // és fordítva: itt NINCS visszaigazolás-lista/tab:
    expect(screen.queryByRole('button', { name: 'Kimenő átadások' })).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Bejövő átadások' })).not.toBeInTheDocument()
  })
})
