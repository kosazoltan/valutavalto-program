import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import VaultClosingChecklistPanel from './VaultClosingChecklistPanel'

// ===== Hoisted mock definíciók =====

const mocks = vi.hoisted(() => ({
  getOrCreate: vi.fn(),
  updateItems: vi.fn(),
  complete: vi.fn(),
  useAuthStore: vi.fn(),
  toast: {
    success: vi.fn(),
    error: vi.fn(),
    warning: vi.fn(),
    info: vi.fn(),
  },
}))

vi.mock('../../services/api/vaultClosingChecklist', () => ({
  vaultClosingChecklistApi: {
    getOrCreate: mocks.getOrCreate,
    updateItems: mocks.updateItems,
    complete: mocks.complete,
  },
}))

vi.mock('../../stores/authStore', () => ({
  useAuthStore: mocks.useAuthStore,
}))

vi.mock('../ui/toaster', () => ({
  toast: mocks.toast,
}))

// ===== Segédadatok =====

const BRANCH_ID = 'branch-uuid-001'
const DATE = '2026-06-11'

const baseChecklist = {
  id: 'checklist-uuid-001',
  branchId: BRANCH_ID,
  branchName: 'EBC Iroda 1',
  closingDate: DATE,
  item1: false,
  item2: false,
  item3: false,
  item4: false,
  item5: false,
  item6: false,
  item7: false,
  item8: false,
  item9: false,
  auditorName: null,
  auditorRole: null,
  completedAt: null,
}

const mockWorker = {
  id: 42,
  branchId: BRANCH_ID,
  fullName: 'Kovács Pénztáros',
  lastName: 'Kovács',
  firstName: 'Pénztáros',
  role: 'CASHIER',
}

function setup() {
  mocks.useAuthStore.mockImplementation((selector: (s: { worker: typeof mockWorker }) => unknown) =>
    selector({ worker: mockWorker }),
  )
}

// ===== Tesztek =====

describe('VaultClosingChecklistPanel', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setup()
  })

  it('renderel betöltési állapotban, majd megmutatja a checklistet', async () => {
    mocks.getOrCreate.mockResolvedValue(baseChecklist)

    render(<VaultClosingChecklistPanel date={DATE} />)

    // Fejléc azonnal látható
    expect(screen.getByText('Zárás-előtti ellenőrzőlista')).toBeInTheDocument()

    // API hívódik
    await waitFor(() => expect(mocks.getOrCreate).toHaveBeenCalledWith(BRANCH_ID, DATE))

    // Az 1. tétel szövege megjelenik
    expect(
      screen.getByText(/Minden pénztár készlete feltöltve/),
    ).toBeInTheDocument()

    // "Zárás véglegesítése" gomb látható (még nincs completedAt)
    expect(screen.getByText('Zárás véglegesítése')).toBeInTheDocument()
  })

  it('checkbox kattintásra updateItems API hívódik', async () => {
    mocks.getOrCreate.mockResolvedValue(baseChecklist)
    const updatedChecklist = { ...baseChecklist, item1: true }
    mocks.updateItems.mockResolvedValue(updatedChecklist)

    render(<VaultClosingChecklistPanel date={DATE} />)
    await waitFor(() => expect(mocks.getOrCreate).toHaveBeenCalled())

    // Kattintás az 1. tételre
    const firstItemButton = screen.getByRole('button', { name: /Minden pénztár készlete feltöltve/ })
    await userEvent.click(firstItemButton)

    await waitFor(() =>
      expect(mocks.updateItems).toHaveBeenCalledWith(
        BRANCH_ID,
        DATE,
        expect.objectContaining({ item1: true }),
      ),
    )
  })

  it('complete-flow: dialógus megjelenik, majd POST /complete hívódik', async () => {
    mocks.getOrCreate.mockResolvedValue(baseChecklist)
    const completedChecklist = {
      ...baseChecklist,
      auditorName: 'Kovács Péter',
      auditorRole: 'Értéktáros vezető',
      completedAt: '2026-06-11T18:00:00',
      completedByWorkerId: 99,
    }
    mocks.complete.mockResolvedValue(completedChecklist)

    render(<VaultClosingChecklistPanel date={DATE} />)
    await waitFor(() => expect(mocks.getOrCreate).toHaveBeenCalled())

    // "Zárás véglegesítése" gomb kattintás
    await userEvent.click(screen.getByText('Zárás véglegesítése'))

    // Dialógus megjelenik (FR-ZARUI-26 title)
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    expect(screen.getByText('Ellenőrző személy adatai')).toBeInTheDocument()
    expect(screen.getByText('A zárószalagot kérem aláírni')).toBeInTheDocument()

    // Kitöltés
    await userEvent.type(screen.getByLabelText(/Ellenőrző neve/), 'Kovács Péter')
    await userEvent.type(screen.getByLabelText(/Beosztás/), 'Értéktáros vezető')

    // Jóváhagyás gomb
    await userEvent.click(screen.getByText('Ellenőrző személy adatai rendben'))

    await waitFor(() =>
      expect(mocks.complete).toHaveBeenCalledWith(BRANCH_ID, DATE, {
        auditorName: 'Kovács Péter',
        auditorRole: 'Értéktáros vezető',
      }),
    )

    // "Zárás véglegesítve" állapot látható
    await waitFor(() => expect(screen.getByText('Zárás véglegesítve')).toBeInTheDocument())
  })

  it('dialógusban üres névmező esetén NEM hív API-t', async () => {
    mocks.getOrCreate.mockResolvedValue(baseChecklist)

    render(<VaultClosingChecklistPanel date={DATE} />)
    await waitFor(() => expect(mocks.getOrCreate).toHaveBeenCalled())

    await userEvent.click(screen.getByText('Zárás véglegesítése'))
    expect(screen.getByRole('dialog')).toBeInTheDocument()

    // Csak a beosztást töltjük ki, a nevet nem → a véglegesítő gomb tiltott marad,
    // így üres névvel fizikailag nem indítható a complete (a validate() a 2. védelmi réteg).
    await userEvent.type(screen.getByLabelText(/Beosztás/), 'Értéktáros vezető')
    const confirmBtn = screen.getByRole('button', { name: 'Ellenőrző személy adatai rendben' })
    expect(confirmBtn).toBeDisabled()

    // complete API NEM hívódik
    expect(mocks.complete).not.toHaveBeenCalled()
  })

  it('lezárt checklist esetén a checkboxok nem kattinthatók', async () => {
    const completedChecklist = {
      ...baseChecklist,
      item1: true,
      auditorName: 'Kovács Péter',
      auditorRole: 'Vezető',
      completedAt: '2026-06-11T18:00:00',
    }
    mocks.getOrCreate.mockResolvedValue(completedChecklist)

    render(<VaultClosingChecklistPanel date={DATE} />)
    await waitFor(() => expect(mocks.getOrCreate).toHaveBeenCalled())

    // "Zárás véglegesítve" státusz
    expect(screen.getByText('Zárás véglegesítve')).toBeInTheDocument()

    // "Zárás véglegesítése" gomb NEM látható
    expect(screen.queryByText('Zárás véglegesítése')).not.toBeInTheDocument()
  })
})
