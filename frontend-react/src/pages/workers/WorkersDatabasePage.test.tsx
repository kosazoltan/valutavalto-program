/**
 * FK-026 — Dolgozói Törzs Adatbázis lista nézet tesztjei.
 * Lefedi: 3 csoport render (FR-5), munkakör magyar név (FR-7),
 * multi-role különböző csoportban (FR-8), multi-role azonos csoportban (FR-9),
 * üres roleCodes → Egyéb/Háttér "–" (FR-10), területi szűrő (FR-11),
 * státusz Aktív/Inaktív (FR-12).
 */
import { render, screen, waitFor, fireEvent, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import WorkersDatabasePage from './WorkersDatabasePage'

const mockGet = vi.fn()

vi.mock('../../services/api/index', () => ({
  api: {
    get: (...args: unknown[]) => mockGet(...args),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
    patch: vi.fn(),
  },
}))

const WORKERS = [
  // multi-role, KÜLÖNBÖZŐ csoportban: Vezetői (Területi vezető) + Operatív (Értéktáros)
  {
    id: 1,
    workerCode: 'BR020-01',
    fullName: 'Kiss Anna',
    region: 'SZEGED',
    active: true,
    roleCodes: ['teruleti_vezeto', 'ertektar'],
  },
  // multi-role, AZONOS csoportban: Operatív (Pénztáros, Értéktáros)
  {
    id: 2,
    workerCode: 'BR020-02',
    fullName: 'Nagy Béla',
    region: 'SZEGED',
    active: true,
    roleCodes: ['penztar', 'ertektar'],
  },
  // üres roleCodes → Egyéb/Háttér, "–"
  {
    id: 3,
    workerCode: 'BR013-01',
    fullName: 'Tóth Cecília',
    region: 'PECS',
    active: true,
    roleCodes: [],
  },
  // region null + inaktív → Vezetői (Ügyvezető), "Nincs megadva", Inaktív
  {
    id: 4,
    workerCode: 'KP-01',
    fullName: 'Szabó Dénes',
    region: null,
    active: false,
    roleCodes: ['ugyvezeto'],
  },
]

function mockApi() {
  mockGet.mockImplementation((url: string) => {
    if (typeof url === 'string' && url === '/workers/directory')
      return Promise.resolve({ data: WORKERS })
    return Promise.resolve({ data: [] })
  })
}

function renderPage() {
  return render(
    <MemoryRouter>
      <WorkersDatabasePage />
    </MemoryRouter>,
  )
}

describe('WorkersDatabasePage — FK-026 Dolgozói Törzs Adatbázis lista', () => {
  beforeEach(() => {
    mockGet.mockReset()
    mockApi()
  })

  it('FR-5: a 3 funkcionális csoport mind megjelenik', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByTestId('group-operativ')).toBeInTheDocument())
    expect(screen.getByTestId('group-vezetoi')).toBeInTheDocument()
    expect(screen.getByTestId('group-egyeb')).toBeInTheDocument()
  })

  it('FR-8: multi-role különböző csoportban → két szekcióban, csoportonkénti munkakör-névvel', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByTestId('group-vezetoi')).toBeInTheDocument())
    // Vezetői/Felügyeleti szekcióban "Területi vezető" névvel
    const vezetoi = screen.getByTestId('group-vezetoi')
    expect(within(vezetoi).getByText('Kiss Anna')).toBeInTheDocument()
    expect(within(vezetoi).getByText('Területi vezető')).toBeInTheDocument()
    // Operatív szekcióban "Értéktáros" névvel
    const operativ = screen.getByTestId('group-operativ')
    expect(within(operativ).getByText('Kiss Anna')).toBeInTheDocument()
    expect(within(operativ).getByText('Értéktáros')).toBeInTheDocument()
  })

  it('FR-9: multi-role azonos csoportban → egy sor, vesszővel elválasztott munkakörök', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByTestId('group-operativ')).toBeInTheDocument())
    const operativ = screen.getByTestId('group-operativ')
    expect(within(operativ).getByText('Nagy Béla')).toBeInTheDocument()
    expect(within(operativ).getByText('Pénztáros, Értéktáros')).toBeInTheDocument()
  })

  it('FR-10: üres roleCodes → Egyéb/Háttér szekció, Munkakör "–"', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByTestId('group-egyeb')).toBeInTheDocument())
    const egyeb = screen.getByTestId('group-egyeb')
    const row = within(egyeb).getByText('Tóth Cecília').closest('tr') as HTMLElement
    expect(within(row).getByText('–')).toBeInTheDocument()
  })

  it('FR-12: inaktív dolgozó "Inaktív" státusszal jelenik meg, region null → "Nincs megadva"', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByTestId('group-vezetoi')).toBeInTheDocument())
    const vezetoi = screen.getByTestId('group-vezetoi')
    const row = within(vezetoi).getByText('Szabó Dénes').closest('tr') as HTMLElement
    expect(within(row).getByText('Inaktív')).toBeInTheDocument()
    expect(within(row).getByText('Nincs megadva')).toBeInTheDocument()
  })

  it('FR-11: területi szűrő region szerint mindhárom szekcióban szűr', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByText('Tóth Cecília')).toBeInTheDocument())
    fireEvent.change(screen.getByLabelText('Területi szűrő'), { target: { value: 'SZEGED' } })
    // SZEGED-es dolgozók maradnak (Kiss Anna két szekcióban is — FR-8 — ezért getAllByText)
    expect(screen.getAllByText('Kiss Anna').length).toBeGreaterThan(0)
    expect(screen.getByText('Nagy Béla')).toBeInTheDocument()
    // PECS-es dolgozó eltűnik
    expect(screen.queryByText('Tóth Cecília')).not.toBeInTheDocument()
  })
})
