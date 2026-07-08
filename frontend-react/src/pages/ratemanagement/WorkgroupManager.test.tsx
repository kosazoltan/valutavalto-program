import { render, screen, waitFor, fireEvent, within } from '@testing-library/react'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import WorkgroupManager from './WorkgroupManager'

// FK-02: a csempés kezelő felület. A backend végpontokat (rate-management/workgroups,
// rate-creation/branches, /currencies) mockoljuk.
const mocks = vi.hoisted(() => ({
  list: vi.fn(),
  create: vi.fn(),
  update: vi.fn(),
  remove: vi.fn(),
  getBranches: vi.fn(),
  updateWorkgroupBranches: vi.fn(),
  currencyList: vi.fn(),
  logger: { error: vi.fn(), info: vi.fn(), warn: vi.fn(), debug: vi.fn() },
}))

vi.mock('../../services/api/index', () => ({
  rateWorkgroupApi: {
    list: mocks.list,
    create: mocks.create,
    update: mocks.update,
    remove: mocks.remove,
  },
  rateCreationApi: {
    getBranches: mocks.getBranches,
    updateWorkgroupBranches: mocks.updateWorkgroupBranches,
  },
  currencyApi: { list: mocks.currencyList },
}))
vi.mock('../../utils/logger', () => ({ logger: mocks.logger }))

const WORKGROUPS = [
  {
    id: 'wg1',
    code: 'WG01',
    name: 'Budapest központ',
    legacyGroupNumber: 1,
    active: true,
    tileColor: 'sky',
  },
  { id: 'wg2', code: 'WG02', name: 'Pécs', legacyGroupNumber: 2, active: true, tileColor: 'amber' },
  // Inaktív (soft-deleted) — NEM jelenhet meg a csempék között.
  { id: 'wg3', code: 'WG09', name: 'Régi', legacyGroupNumber: 9, active: false, tileColor: 'red' },
]

const BRANCHES = [
  { id: 'b1', code: 'BP1', name: 'Deák tér', city: 'Budapest', assignedToCurrentWorkgroup: true },
  { id: 'b2', code: 'BP2', name: 'Nyugati', city: 'Budapest', assignedToCurrentWorkgroup: false },
]

const CURRENCIES = [
  { id: 1, code: 'EUR', name: 'Euró', decimals: 2, displayOrder: 0, active: true },
  { id: 2, code: 'USD', name: 'Dollár', decimals: 2, displayOrder: 1, active: true },
]

describe('WorkgroupManager (FK-02)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.list.mockResolvedValue(WORKGROUPS)
    mocks.getBranches.mockResolvedValue(BRANCHES)
    mocks.currencyList.mockResolvedValue(CURRENCIES)
    mocks.create.mockResolvedValue(WORKGROUPS[0])
    mocks.update.mockResolvedValue(WORKGROUPS[0])
    mocks.remove.mockResolvedValue(undefined)
    mocks.updateWorkgroupBranches.mockResolvedValue(undefined)
  })

  it('csak az AKTÍV munkacsoportokat jeleníti meg csempeként, sorszámmal', async () => {
    render(<WorkgroupManager />)
    await waitFor(() => expect(screen.getByText('Budapest központ')).toBeInTheDocument())
    expect(screen.getByText('Pécs')).toBeInTheDocument()
    // Az inaktív 'Régi' NEM jelenik meg.
    expect(screen.queryByText('Régi')).not.toBeInTheDocument()
  })

  it('csempére kattintva megerősítés nélkül megnyílik a munkacsoport (vissza-gombbal)', async () => {
    render(<WorkgroupManager />)
    await waitFor(() => expect(screen.getByText('Budapest központ')).toBeInTheDocument())
    fireEvent.click(screen.getByText('Budapest központ'))
    // Detail nézet: vissza-gomb + pénztár-szekció + árfolyamlap-struktúra.
    await waitFor(() => expect(screen.getByText('Vissza')).toBeInTheDocument())
    expect(screen.getByText(/Pénztárak/)).toBeInTheDocument()
    await waitFor(() => expect(screen.getByText(/Árfolyamlap-struktúra/)).toBeInTheDocument())
    // A J–S struktúra fejlécei és a valuta-sorok (K oszlop ISO kód).
    expect(screen.getByText('EUR')).toBeInTheDocument()
    expect(screen.getByText('USD')).toBeInTheDocument()
  })

  it('"Új munkacsoport" megnyitja a szerkesztőt, mentés hívja a create API-t', async () => {
    render(<WorkgroupManager />)
    await waitFor(() => expect(screen.getByText('Budapest központ')).toBeInTheDocument())
    fireEvent.click(screen.getByText('Új munkacsoport'))
    // FK02-E (FR-1): a modal csak a nevet kéri; a Kód mező megszűnt (szerver generálja a sorszámból).
    const dialog = screen
      .getByText('Új munkacsoport', { selector: 'h3' })
      .closest('div') as HTMLElement
    const scope = within(dialog)
    expect(scope.queryByPlaceholderText('pl. WG01')).toBeNull()
    fireEvent.change(scope.getByPlaceholderText('pl. Budapest központ'), {
      target: { value: 'Szeged' },
    })
    fireEvent.click(scope.getByText('Mentés'))
    await waitFor(() => expect(mocks.create).toHaveBeenCalledTimes(1))
    // FK02-E (FR-2): a sorszám üresen marad → a szerver osztja ki (a teljes cég-scope alapján,
    // az inaktív csoportok foglalt sorszámát is figyelembe véve), a payload legacyGroupNumber-e undefined.
    expect(mocks.create).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'Szeged', legacyGroupNumber: undefined }),
    )
  })

  it('törlés megerősítő dialógus után hívja a remove (soft-delete) API-t', async () => {
    render(<WorkgroupManager />)
    await waitFor(() => expect(screen.getByText('Budapest központ')).toBeInTheDocument())
    fireEvent.click(screen.getByText('Budapest központ'))
    await waitFor(() => expect(screen.getByText('Törlés')).toBeInTheDocument())
    fireEvent.click(screen.getByText('Törlés'))
    // Megerősítő dialógus → "Törlés" gomb a modalban.
    const dialog = screen.getByText('Munkacsoport törlése').closest('div') as HTMLElement
    fireEvent.click(within(dialog).getByText('Törlés'))
    await waitFor(() => expect(mocks.remove).toHaveBeenCalledWith('wg1'))
  })
})
