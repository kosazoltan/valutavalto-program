import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import MovementManager from './MovementManager'
import type { Transfer } from '../../services/api/index'
import { localIsoDate } from '../../utils/dateFormat'

const mocks = vi.hoisted(() => ({
  transferGetPending: vi.fn(),
  transferSearch: vi.fn(),
  currencyList: vi.fn(),
  branchListVaultCounterparties: vi.fn(),
  sealGetNext: vi.fn(),
}))

vi.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string) => key,
  }),
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: unknown) => unknown) =>
    selector({
      worker: {
        id: 1,
        workerCode: 'W0001',
        fullName: 'Teszt Admin',
        role: 'ADMIN',
        branchId: 'branch-1',
        branchCode: 'SZEGED',
        branchName: 'Szeged Értéktár',
        companyId: 'company-1',
        companyCode: 'EBC',
        companyName: 'EBC Valutaváltó',
      },
    }),
}))

vi.mock('../../utils/electronTransactions', () => ({
  isElectronQueueAvailable: () => false,
  recordLocalAuditEvent: vi.fn(),
  saveAndSyncPendingTransfer: vi.fn(),
}))

vi.mock('../../utils/localQueue', () => ({
  getLocalPendingTransfers: vi.fn().mockResolvedValue([]),
}))

vi.mock('../../services/api/index', () => ({
  transferApi: {
    getPending: mocks.transferGetPending,
    search: mocks.transferSearch,
  },
  currencyApi: {
    list: mocks.currencyList,
  },
  branchApi: {
    listVaultCounterparties: mocks.branchListVaultCounterparties,
  },
  sealNumberApi: {
    getNext: mocks.sealGetNext,
  },
}))

/** Teljes Transfer-sor factory a Mozgások előzmény-tábla tesztekhez (FKH-037). */
function transferRow(overrides: Partial<Transfer>): Transfer {
  return {
    id: 1,
    transferNumber: 'AT-0001',
    fromBranchId: 'branch-2',
    fromBranchCode: 'BR002',
    fromBranchName: 'Küldő iroda',
    toBranchId: 'branch-3',
    toBranchCode: 'BR003',
    toBranchName: 'Fogadó iroda',
    fromWorkerId: 10,
    fromWorkerName: 'Küldő Dolgozó',
    transferType: 'CURRENCY',
    transferTypeDisplay: 'Iroda szállítás',
    status: 'COMPLETED',
    statusDisplay: 'Teljesítve',
    transferDate: '2026-05-22',
    transferTime: '09:15:00',
    currencyId: 1,
    currencyCode: 'EUR',
    currencyName: 'Euró',
    amount: 5000,
    handoverPrinted: false,
    receiptPrinted: false,
    createdAt: '2026-05-22T09:15:00',
    hasDifference: false,
    isCompleted: true,
    isPending: false,
    ...overrides,
  }
}

describe('MovementManager', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.transferGetPending.mockResolvedValue([])
    mocks.transferSearch.mockResolvedValue({
      content: [],
      totalElements: 0,
      totalPages: 0,
      size: 50,
      number: 0,
    })
    mocks.currencyList.mockResolvedValue([{ id: 1, code: 'EUR', name: 'Euró', active: true }])
    mocks.branchListVaultCounterparties.mockResolvedValue({
      territorialCashiers: [],
      peerVaults: [],
      fixedCounterparties: [],
    })
    mocks.sealGetNext.mockResolvedValue({ sealNumber: 'SZEGED-20260618-001' })
  })

  it('backend plombaszám preview endpointból tölti ki az új mozgás plombaszámát', async () => {
    render(<MovementManager />)

    await screen.findByText('treasury.ujMozgas')
    fireEvent.click(screen.getByText('treasury.ujMozgas'))
    fireEvent.click(screen.getByText('Generálás'))

    await waitFor(() => {
      expect(mocks.sealGetNext).toHaveBeenCalledWith('SZEGED')
      expect(screen.getByDisplayValue('SZEGED-20260618-001')).toBeInTheDocument()
    })
  })

  // FKH-037 — dátumszűrés, irány-címke, teljes dátum
  it('FR-3: az első keresés a mai napot küldi startDate/endDate paraméterként', async () => {
    const today = localIsoDate()
    render(<MovementManager />)
    await waitFor(() =>
      expect(mocks.transferSearch).toHaveBeenCalledWith(
        expect.objectContaining({ startDate: today, endDate: today }),
      ),
    )
  })

  it('FR-4: a dátumszűrő módosítása új paraméterekkel hívja újra a keresést', async () => {
    render(<MovementManager />)
    await screen.findByText('treasury.mozgasTortenet')

    fireEvent.change(screen.getByTestId('movement-history-start-date'), {
      target: { value: '2026-05-20' },
    })
    fireEvent.change(screen.getByTestId('movement-history-end-date'), {
      target: { value: '2026-05-22' },
    })

    await waitFor(() =>
      expect(mocks.transferSearch).toHaveBeenCalledWith(
        expect.objectContaining({ startDate: '2026-05-20', endDate: '2026-05-22' }),
      ),
    )
  })

  it('FR-5: fromBranchId === worker.branchId → Átadás', async () => {
    mocks.transferSearch.mockResolvedValue({
      content: [
        transferRow({ id: 1, fromBranchId: 'branch-1', toBranchId: 'branch-9' }),
      ],
      totalElements: 1,
      totalPages: 1,
      size: 50,
      number: 0,
    })
    render(<MovementManager />)
    expect(await screen.findByText('Átadás')).toBeInTheDocument()
  })

  it('FR-5: toBranchId === worker.branchId → Átvétel', async () => {
    mocks.transferSearch.mockResolvedValue({
      content: [
        transferRow({ id: 2, fromBranchId: 'branch-9', toBranchId: 'branch-1' }),
      ],
      totalElements: 1,
      totalPages: 1,
      size: 50,
      number: 0,
    })
    render(<MovementManager />)
    expect(await screen.findByText('Átvétel')).toBeInTheDocument()
  })

  it('FR-5/FR-6: idegen sor megtartja a technikai címkét és a TIME cella teljes dátumot mutat', async () => {
    mocks.transferSearch.mockResolvedValue({
      content: [
        transferRow({
          id: 3,
          fromBranchId: 'branch-7',
          toBranchId: 'branch-8',
          transferType: 'CURRENCY',
          createdAt: '2026-05-22T09:15:00',
        }),
      ],
      totalElements: 1,
      totalPages: 1,
      size: 50,
      number: 0,
    })
    render(<MovementManager />)
    // Idegen sor: technikai típuscímke marad (TBD-2)
    expect(await screen.findByText('Iroda szállítás')).toBeInTheDocument()
    // TIME cella teljes dátumot mutat (nem csak órát): az év is szerepel a sor szövegében
    const rows = screen.getAllByRole('row')
    const dataRow = rows.find((row) => row.textContent?.includes('#AT-0001'))
    expect(dataRow).toBeDefined()
    expect(dataRow!.textContent).toContain('2026')
  })
})
