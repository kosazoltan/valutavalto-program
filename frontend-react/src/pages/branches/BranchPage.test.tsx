/**
 * FK-020 — Pénztár Törzs Adatbázis lista nézet tesztjei.
 * Lefedi: lista render (FR-2), keresés (FR-3), területi szűrő (FR-4),
 * inaktívak (FR-5), szolgáltatás-badge-ek (FR-6), darabszám (FR-9).
 */
import { render, screen, waitFor, fireEvent, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import BranchPage from './BranchPage'

const mockGet = vi.fn()
const mockBranchGetByCode = vi.fn()
const mockBranchListRoots = vi.fn()
const mockBranchListVaultOnly = vi.fn()
const mockBranchListVaultCounterparties = vi.fn()

vi.mock('../../services/api/index', () => ({
  api: {
    get: (...args: unknown[]) => mockGet(...args),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
    patch: vi.fn(),
  },
  branchApi: {
    getByCode: (...args: unknown[]) => mockBranchGetByCode(...args),
    listRoots: (...args: unknown[]) => mockBranchListRoots(...args),
    listVaultOnly: (...args: unknown[]) => mockBranchListVaultOnly(...args),
    listVaultCounterparties: (...args: unknown[]) => mockBranchListVaultCounterparties(...args),
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn() },
}))

const BRANCHES = [
  { id: '1', code: 'BR027', name: 'Szeged Tesco', region: 'SZEGED', address: 'Rókusi krt. 42', city: 'Szeged', email: 'szeged@ebc.hu', phone: '+3611', isActive: true, isVault: false, hasAfa: true, hasWu: true, hasMg: false, hasPos: false },
  { id: '2', code: 'BR013', name: 'Pécs Tesco', region: 'PECS', address: 'Makay u. 5', city: 'Pécs', email: 'pecs@ebc.hu', phone: '+3622', isActive: true, isVault: false, hasAfa: false, hasWu: false, hasMg: true, hasPos: false },
  { id: '3', code: 'BR074', name: 'Békéscsaba Tesco', region: 'BEKESCSABA', address: 'Szarvasi út 68', city: 'Békéscsaba', email: 'bcs@ebc.hu', phone: '+3633', isActive: true, isVault: false, hasAfa: false, hasWu: false, hasMg: false, hasPos: true },
  { id: '4', code: 'BR999', name: 'Régi bezárt iroda', region: 'SZEGED', address: 'Régi u. 1', city: 'Szeged', email: null, phone: null, isActive: false, isVault: false, hasAfa: false, hasWu: false, hasMg: false, hasPos: false },
]

function mockApi() {
  mockGet.mockImplementation((url: string) => {
    if (typeof url === 'string' && url === '/branches') return Promise.resolve({ data: BRANCHES })
    if (typeof url === 'string' && url === '/admin/branches') {
      return Promise.resolve({
        data: [
          { id: '1', workerCount: 5, dailyTurnoverHuf: 0, lastSyncAt: '2026-06-18T08:00:00', syncStatus: 'SYNCED' },
          { id: '2', workerCount: 3, dailyTurnoverHuf: 0, lastSyncAt: null, syncStatus: 'NEVER' },
        ],
      })
    }
    // dictionary dropdownok a form-hoz
    return Promise.resolve({ data: [] })
  })
}

function renderPage() {
  return render(<MemoryRouter><BranchPage /></MemoryRouter>)
}

describe('BranchPage — FK-020 Pénztár Törzs Adatbázis lista', () => {
  beforeEach(() => {
    mockGet.mockReset()
    mockBranchGetByCode.mockReset()
    mockBranchListRoots.mockReset()
    mockBranchListVaultOnly.mockReset()
    mockBranchListVaultCounterparties.mockReset()
    mockBranchGetByCode.mockResolvedValue({
      id: '1',
      code: 'BR027',
      name: 'Backend kód találat',
      region: 'SZEGED',
      isActive: true,
    })
    mockBranchListRoots.mockResolvedValue([{ id: 'root-1', code: 'ROOT', name: 'Gyökér iroda', isActive: true }])
    mockBranchListVaultOnly.mockResolvedValue([{ id: 'vault-1', code: 'VAULT', name: 'Értéktár', isActive: true, isVault: true }])
    mockBranchListVaultCounterparties.mockResolvedValue({
      territorialCashiers: [{ id: 'cashier-1', code: 'BR027', name: 'Szeged Tesco', isActive: true }],
      peerVaults: [{ id: 'vault-2', code: 'VAULT2', name: 'Másik értéktár', isActive: true, isVault: true }],
      fixedCounterparties: [{ id: 'mnb-1', code: 'MNB', name: 'MNB', isActive: true }],
    })
    mockApi()
  })

  it('FR-2/FR-9: alapból csak az aktív irodákat listázza + darabszám', async () => {
    renderPage()
    await waitFor(() => expect(screen.getAllByText('Szeged Tesco').length).toBeGreaterThan(0))
    expect(screen.getAllByText('Pécs Tesco').length).toBeGreaterThan(0)
    expect(screen.getAllByText('Békéscsaba Tesco').length).toBeGreaterThan(0)
    // inaktív alapból NEM látszik
    expect(screen.queryByText('Régi bezárt iroda')).not.toBeInTheDocument()
    // darabszám = 3
    expect(screen.getByTestId('branch-count')).toHaveTextContent('3 pénztár')
  })

  it('FR-2: clientType=CENTRAL paraméterrel kéri a listát (virtuálisok kizárása)', async () => {
    renderPage()
    await waitFor(() => expect(screen.getAllByText('Szeged Tesco').length).toBeGreaterThan(0))
    expect(mockGet).toHaveBeenCalledWith('/branches', { params: { clientType: 'CENTRAL' } })
  })

  it('az admin statisztikás branch szerződést is lekéri és megjeleníti', async () => {
    renderPage()
    await waitFor(() => expect(screen.getAllByText('Szeged Tesco').length).toBeGreaterThan(0))

    expect(mockGet).toHaveBeenCalledWith('/admin/branches')
    expect(screen.getAllByText('5 fő').length).toBeGreaterThan(0)
    expect(screen.getAllByText(/Sync:/).length).toBeGreaterThan(0)
  })

  it('a backend branch összefoglaló listákat lekéri és számlálóként megjeleníti', async () => {
    renderPage()
    await waitFor(() => expect(screen.getAllByText('Szeged Tesco').length).toBeGreaterThan(0))

    expect(mockBranchListRoots).toHaveBeenCalledWith()
    expect(mockBranchListVaultOnly).toHaveBeenCalledWith()
    expect(mockBranchListVaultCounterparties).toHaveBeenCalledWith()
    expect(screen.getByTestId('branch-backend-summary')).toHaveTextContent('Gyökér irodák')
    expect(screen.getByTestId('branch-backend-summary')).toHaveTextContent('Értéktárak')
    expect(screen.getByTestId('branch-backend-summary')).toHaveTextContent('Értéktári célpartnerek')
    expect(screen.getByTestId('branch-roots-count')).toHaveTextContent('1')
    expect(screen.getByTestId('branch-vaults-count')).toHaveTextContent('1')
    expect(screen.getByTestId('branch-counterparties-count')).toHaveTextContent('3')
  })

  it('FR-3: szabad szöveges keresés névre/címre szűr', async () => {
    renderPage()
    await waitFor(() => expect(screen.getAllByText('Szeged Tesco').length).toBeGreaterThan(0))
    fireEvent.change(screen.getByLabelText('Keresés'), { target: { value: 'Pécs' } })
    expect(screen.getAllByText('Pécs Tesco').length).toBeGreaterThan(0)
    expect(screen.queryByText('Szeged Tesco')).not.toBeInTheDocument()
    expect(screen.getByTestId('branch-count')).toHaveTextContent('1 pénztár')
  })

  it('FR-4: területi szűrő region szerint szűr', async () => {
    renderPage()
    await waitFor(() => expect(screen.getAllByText('Szeged Tesco').length).toBeGreaterThan(0))
    fireEvent.change(screen.getByLabelText('Területi szűrő'), { target: { value: 'SZEGED' } })
    expect(screen.getAllByText('Szeged Tesco').length).toBeGreaterThan(0)
    expect(screen.queryByText('Pécs Tesco')).not.toBeInTheDocument()
    expect(screen.queryByText('Békéscsaba Tesco')).not.toBeInTheDocument()
  })

  it('FR-5: "Inaktívak is" checkbox megjeleníti az inaktív irodát', async () => {
    renderPage()
    await waitFor(() => expect(screen.getAllByText('Szeged Tesco').length).toBeGreaterThan(0))
    fireEvent.click(screen.getByLabelText('Inaktívak is'))
    expect(screen.getAllByText('Régi bezárt iroda').length).toBeGreaterThan(0)
    expect(screen.getByTestId('branch-count')).toHaveTextContent('4 pénztár')
  })

  it('FR-6: szolgáltatás-badge-ek megjelennek (ÁFA/WU/MG/POS)', async () => {
    renderPage()
    await waitFor(() => expect(screen.getAllByText('Szeged Tesco').length).toBeGreaterThan(0))
    const row = screen.getAllByText('Szeged Tesco').map((node) => node.closest('tr')).find(Boolean) as HTMLElement
    // a Szeged sorban: ÁFA aktív (kék), WU aktív, MG/POS szürke — mind jelen van label-ként
    expect(within(row).getByText('ÁFA')).toBeInTheDocument()
    expect(within(row).getByText('WU')).toBeInTheDocument()
    expect(within(row).getByText('MG')).toBeInTheDocument()
    expect(within(row).getByText('POS')).toBeInTheDocument()
    expect(within(row).getByText('ÁFA').className).toMatch(/text-blue-700/)
    expect(within(row).getByText('MG').className).toMatch(/text-gray-400/)
  })

  it('pontos pénztárkód kereséskor a backend code lookup wrappert hívja', async () => {
    renderPage()
    await waitFor(() => expect(screen.getAllByText('Szeged Tesco').length).toBeGreaterThan(0))

    fireEvent.change(screen.getByLabelText('Pontos pénztárkód'), { target: { value: 'BR027' } })
    fireEvent.click(screen.getByRole('button', { name: 'Kód keresés' }))

    await waitFor(() => {
      expect(mockBranchGetByCode).toHaveBeenCalledWith('BR027')
    })
    expect(screen.getByTestId('branch-code-result')).toHaveTextContent('Backend kód találat')
  })
})
