/**
 * FK-021 — Új iroda felrögzítése form tesztjei.
 * Lefedi: 5 csoport (FR-1), kötelező validáció (FR-2), tartósan-zárva→inaktív (FR-5),
 * iroda típusa Értéktár→isVault (FR-4), sikeres mentés + navigáció a listára (FR-8).
 */
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import BranchCreatePage from './BranchCreatePage'

const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return { ...actual, useNavigate: () => mockNavigate }
})

const mockCreate = vi.fn()
const mockGetByCategory = vi.fn()
vi.mock('../../services/api/index', () => ({
  branchApi: { createSimpleCashier: (...args: unknown[]) => mockCreate(...args) },
  dictionaryApi: { getByCategory: (...args: unknown[]) => mockGetByCategory(...args) },
}))

function renderPage() {
  return render(
    <MemoryRouter>
      <BranchCreatePage />
    </MemoryRouter>,
  )
}

async function fillRequired() {
  await waitFor(() => expect(screen.getByText('3. Területi besorolás')).toBeInTheDocument())
  fireEvent.change(screen.getByPlaceholderText('pl. BR099'), { target: { value: 'BR099' } })
  fireEvent.change(screen.getByPlaceholderText(/Tisza Lajos krt/), {
    target: { value: '6720 Szeged, Fő tér 1.' },
  })
  fireEvent.change(screen.getByRole('combobox'), { target: { value: 'SZEGED' } })
}

describe('BranchCreatePage — FK-021 Új iroda felrögzítése', () => {
  beforeEach(() => {
    mockNavigate.mockReset()
    mockCreate.mockReset().mockResolvedValue({ code: 'BR099' })
    mockGetByCategory.mockReset().mockResolvedValue([
      { id: 'r1', code: 'SZEGED', name: 'Szeged', nameHu: 'Szeged' },
      { id: 'r2', code: 'PECS', name: 'Pécs', nameHu: 'Pécs' },
    ])
  })

  it('FR-1: a form 5 logikai csoportban jelenik meg', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByText('1. Alapadatok')).toBeInTheDocument())
    expect(screen.getByText('2. Elérhetőség')).toBeInTheDocument()
    expect(screen.getByText('3. Területi besorolás')).toBeInTheDocument()
    expect(screen.getByText('4. Szolgáltatások')).toBeInTheDocument()
    expect(screen.getByText('5. Nyitvatartás')).toBeInTheDocument()
  })

  it('FR-2: kötelező mezők hiányában hibát ad, nem ment', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByText('1. Alapadatok')).toBeInTheDocument())
    fireEvent.click(screen.getByRole('button', { name: /Pénztár felrögzítése/ }))
    await waitFor(() => expect(screen.getByText(/kötelező/)).toBeInTheDocument())
    expect(mockCreate).not.toHaveBeenCalled()
  })

  it('FR-8: helyes kitöltés után ment és visszanavigál a listára', async () => {
    renderPage()
    await fillRequired()
    fireEvent.click(screen.getByRole('button', { name: /Pénztár felrögzítése/ }))
    await waitFor(() => expect(mockCreate).toHaveBeenCalledTimes(1))
    expect(mockCreate.mock.calls[0]?.[0]).toMatchObject({
      code: 'BR099',
      address: '6720 Szeged, Fő tér 1.',
      regionCode: 'SZEGED',
      isVault: false,
      isActive: true,
    })
    await waitFor(() => expect(mockNavigate).toHaveBeenCalledWith('/admin/branches'))
  })

  it('FR-5: "Tartósan zárva" → isActive=false a payloadban', async () => {
    renderPage()
    await fillRequired()
    fireEvent.click(screen.getByRole('checkbox', { name: /Tartósan zárva/ }))
    fireEvent.click(screen.getByRole('button', { name: /Pénztár felrögzítése/ }))
    await waitFor(() => expect(mockCreate).toHaveBeenCalled())
    expect(mockCreate.mock.calls[0]?.[0]).toMatchObject({ isActive: false })
  })

  it('FR-4: "Értéktár" típus → isVault=true a payloadban', async () => {
    renderPage()
    await fillRequired()
    fireEvent.click(screen.getByRole('radio', { name: 'Értéktár' }))
    fireEvent.click(screen.getByRole('button', { name: /Pénztár felrögzítése/ }))
    await waitFor(() => expect(mockCreate).toHaveBeenCalled())
    expect(mockCreate.mock.calls[0]?.[0]).toMatchObject({ isVault: true })
  })

  it('Sourcery #1058: a kód-mező kiszűri a nem [A-Z0-9] karaktereket', async () => {
    renderPage()
    await waitFor(() => expect(screen.getByText('3. Területi besorolás')).toBeInTheDocument())
    fireEvent.change(screen.getByPlaceholderText(/Tisza Lajos krt/), { target: { value: 'Cím' } })
    fireEvent.change(screen.getByRole('combobox'), { target: { value: 'SZEGED' } })
    // szóköz, ékezet, írásjel → kiszűrve, csak nagybetű+szám marad
    fireEvent.change(screen.getByPlaceholderText('pl. BR099'), { target: { value: 'br 0-9!9á' } })
    expect((screen.getByPlaceholderText('pl. BR099') as HTMLInputElement).value).toBe('BR099')
    fireEvent.click(screen.getByRole('button', { name: /Pénztár felrögzítése/ }))
    await waitFor(() => expect(mockCreate).toHaveBeenCalled())
    expect(mockCreate.mock.calls[0]?.[0]).toMatchObject({ code: 'BR099' })
  })

  it('FR-6: szolgáltatás-flagek a payloadban', async () => {
    renderPage()
    await fillRequired()
    fireEvent.click(screen.getByRole('checkbox', { name: /ÁFA-visszatérítés/ }))
    fireEvent.click(screen.getByRole('checkbox', { name: /Western Union/ }))
    fireEvent.click(screen.getByRole('button', { name: /Pénztár felrögzítése/ }))
    await waitFor(() => expect(mockCreate).toHaveBeenCalled())
    expect(mockCreate.mock.calls[0]?.[0]).toMatchObject({
      hasAfa: true,
      hasWu: true,
      hasMg: false,
      hasPos: false,
    })
  })
})
