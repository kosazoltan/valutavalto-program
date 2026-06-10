/**
 * FK-022 — Iroda adatainak szerkesztése form tesztjei.
 * Lefedi: előtöltés 5 csoportban (FR-1), minden mező szerkeszthető (FR-2), read-only kód (FR-3),
 * státuszváltás megerősítő kérdés mindkét irányban + "Nem" ág (FR-4/FR-5), mentés után
 * visszanavigálás (FR-6), kötelező mező validáció (FR-10), tartósan zárva → isActive=false (FR-11).
 */
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import BranchEditPage from './BranchEditPage'

const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return { ...actual, useNavigate: () => mockNavigate }
})

const mockGetById = vi.fn()
const mockUpdate = vi.fn()
const mockGetByCategory = vi.fn()
vi.mock('../../services/api/index', () => ({
  branchApi: {
    getById: (...args: unknown[]) => mockGetById(...args),
    update: (...args: unknown[]) => mockUpdate(...args),
  },
  dictionaryApi: { getByCategory: (...args: unknown[]) => mockGetByCategory(...args) },
}))

const ACTIVE_BRANCH = {
  id: 'b-1',
  code: 'BR027',
  name: 'Szeged Tesco',
  shortName: 'Tesco',
  address: '6723 Szeged, Rókusi krt. 42.',
  zipCode: '6723',
  city: 'Szeged',
  phone: '06701112233',
  email: 'szeged@ebc.hu',
  bankCode: '210',
  region: 'SZEGED',
  isActive: true,
  isVault: false,
  hasAfa: true,
  hasWu: false,
  hasMg: false,
  hasPos: true,
  closedSaturday: false,
  closedSunday: true,
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/admin/branches/b-1/edit']}>
      <Routes>
        <Route path="/admin/branches/:id/edit" element={<BranchEditPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

async function waitLoaded() {
  await waitFor(() => expect(screen.getByText('1. Alapadatok')).toBeInTheDocument())
}

describe('BranchEditPage — FK-022 Iroda adatainak szerkesztése', () => {
  beforeEach(() => {
    mockNavigate.mockReset()
    mockGetById.mockReset().mockResolvedValue({ ...ACTIVE_BRANCH })
    mockUpdate.mockReset().mockResolvedValue({ ...ACTIVE_BRANCH, name: 'Új Név' })
    mockGetByCategory.mockReset().mockResolvedValue([
      { id: 'r1', code: 'SZEGED', name: 'Szeged', nameHu: 'Szeged' },
      { id: 'r2', code: 'PECS', name: 'Pécs', nameHu: 'Pécs' },
    ])
  })

  it('FR-1: a form 5 logikai csoportban, a meglévő iroda adataival előtöltve jelenik meg', async () => {
    renderPage()
    await waitLoaded()
    expect(screen.getByText('2. Elérhetőség')).toBeInTheDocument()
    expect(screen.getByText('3. Területi besorolás')).toBeInTheDocument()
    expect(screen.getByText('4. Szolgáltatások')).toBeInTheDocument()
    expect(screen.getByText('5. Nyitvatartás')).toBeInTheDocument()
    expect(mockGetById).toHaveBeenCalledWith('b-1')
    expect(screen.getByLabelText(/Megjelenítendő név/)).toHaveValue('Szeged Tesco')
    expect(screen.getByLabelText(/Pénztár pontos címe/)).toHaveValue('6723 Szeged, Rókusi krt. 42.')
    expect(screen.getByLabelText(/Terület \/ Régió/)).toHaveValue('SZEGED')
    expect(screen.getByRole('checkbox', { name: /ÁFA-visszatérítés/ })).toBeChecked()
    expect(screen.getByRole('checkbox', { name: /Vasárnap zárva/ })).toBeChecked()
  })

  it('FR-3: a pénztár kódja read-only, és nem kerül a mentési payloadba', async () => {
    renderPage()
    await waitLoaded()
    const codeInput = screen.getByLabelText(/Pénztár száma/) as HTMLInputElement
    expect(codeInput).toHaveValue('BR027')
    expect(codeInput).toBeDisabled()
    expect(codeInput).toHaveAttribute('readonly')

    fireEvent.click(screen.getByRole('button', { name: /Mentés/ }))
    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1))
    expect(mockUpdate.mock.calls[0]?.[1]).not.toHaveProperty('code')
  })

  it('FR-2/FR-6: mezőmódosítás után mentés → PUT payload + visszanavigálás a listára', async () => {
    renderPage()
    await waitLoaded()
    fireEvent.change(screen.getByLabelText(/Megjelenítendő név/), { target: { value: 'Új Név' } })
    fireEvent.click(screen.getByRole('checkbox', { name: /Western Union/ }))
    fireEvent.click(screen.getByRole('button', { name: /Mentés/ }))

    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1))
    expect(mockUpdate).toHaveBeenCalledWith('b-1', expect.objectContaining({
      name: 'Új Név',
      hasWu: true,
      isActive: true,
    }))
    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith('/admin/branches'))
  })

  it('Területi besorolás: változatlan régiónál NEM küld regionCode-ot, módosításnál igen', async () => {
    renderPage()
    await waitLoaded()
    // 1. mentés változatlan régióval
    fireEvent.click(screen.getByRole('button', { name: /Mentés/ }))
    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1))
    expect(mockUpdate.mock.calls[0]?.[1]).not.toHaveProperty('regionCode')

    // 2. régióváltás → regionCode a payloadban
    fireEvent.change(screen.getByLabelText(/Terület \/ Régió/), { target: { value: 'PECS' } })
    fireEvent.click(screen.getByRole('button', { name: /Mentés/ }))
    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(2))
    expect(mockUpdate.mock.calls[1]?.[1]).toMatchObject({ regionCode: 'PECS' })
  })

  it('FR-4/FR-11: aktív iroda + "Tartósan zárva" → megerősítő kérdés, Igen → isActive=false', async () => {
    renderPage()
    await waitLoaded()
    fireEvent.click(screen.getByRole('checkbox', { name: /Tartósan zárva/ }))
    fireEvent.click(screen.getByRole('button', { name: /Mentés/ }))

    // megerősítő kérdés — mentés MÉG nem történt
    expect(screen.getByText('Biztosan inaktívra állítja ezt az irodát?')).toBeInTheDocument()
    expect(mockUpdate).not.toHaveBeenCalled()

    fireEvent.click(screen.getByRole('button', { name: 'Igen' }))
    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1))
    expect(mockUpdate.mock.calls[0]?.[1]).toMatchObject({ isActive: false })
  })

  it('FR-4: megerősítő kérdésnél "Nem" → nincs mentés, a form megmarad', async () => {
    renderPage()
    await waitLoaded()
    fireEvent.click(screen.getByRole('checkbox', { name: /Tartósan zárva/ }))
    fireEvent.click(screen.getByRole('button', { name: /Mentés/ }))
    expect(screen.getByText('Biztosan inaktívra állítja ezt az irodát?')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Nem' }))
    expect(screen.queryByText('Biztosan inaktívra állítja ezt az irodát?')).not.toBeInTheDocument()
    expect(mockUpdate).not.toHaveBeenCalled()
    expect(mockNavigate).not.toHaveBeenCalled()
    // a checkbox állapota megmarad, a felhasználó tovább szerkeszthet
    expect(screen.getByRole('checkbox', { name: /Tartósan zárva/ })).toBeChecked()
  })

  it('FR-5: inaktív iroda visszaaktiválása → "Biztosan aktívra állítja..." + isActive=true', async () => {
    mockGetById.mockResolvedValue({ ...ACTIVE_BRANCH, isActive: false })
    renderPage()
    await waitLoaded()
    expect(screen.getByRole('checkbox', { name: /Tartósan zárva/ })).toBeChecked()

    fireEvent.click(screen.getByRole('checkbox', { name: /Tartósan zárva/ }))
    fireEvent.click(screen.getByRole('button', { name: /Mentés/ }))
    expect(screen.getByText('Biztosan aktívra állítja ezt az irodát?')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: 'Igen' }))
    await waitFor(() => expect(mockUpdate).toHaveBeenCalledTimes(1))
    expect(mockUpdate.mock.calls[0]?.[1]).toMatchObject({ isActive: true })
  })

  it('FR-10: üresre törölt név → validációs hiba, nincs mentés', async () => {
    renderPage()
    await waitLoaded()
    fireEvent.change(screen.getByLabelText(/Megjelenítendő név/), { target: { value: '   ' } })
    fireEvent.click(screen.getByRole('button', { name: /Mentés/ }))

    await waitFor(() => expect(screen.getByText(/kötelező/)).toBeInTheDocument())
    expect(mockUpdate).not.toHaveBeenCalled()
  })

  it('NFR-3: üres területi besorolás → validációs hiba, nincs mentés (Copilot #1076)', async () => {
    renderPage()
    await waitLoaded()
    fireEvent.change(screen.getByLabelText(/Terület \/ Régió/), { target: { value: '' } })
    fireEvent.click(screen.getByRole('button', { name: /Mentés/ }))

    await waitFor(() => expect(screen.getByText(/területi besorolás megadása kötelező/)).toBeInTheDocument())
    expect(mockUpdate).not.toHaveBeenCalled()
  })

  it('Betöltési hiba esetén hibaüzenet jelenik meg, a form nem renderelődik', async () => {
    mockGetById.mockRejectedValue(new Error('Fiók nem található'))
    renderPage()
    await waitFor(() => expect(screen.getByText(/Fiók nem található/)).toBeInTheDocument())
    expect(screen.queryByText('1. Alapadatok')).not.toBeInTheDocument()
  })
})
