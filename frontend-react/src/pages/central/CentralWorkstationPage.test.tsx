/**
 * CentralWorkstationPage — FK-107 tile RBAC test (FR-1).
 *
 * Proves that the received-data tile is visible for foertektar/belso_ellenor/ADMIN
 * and hidden for irodavezeto. The component falls back to client-side role check
 * when centralModules is null — canSeeModule: hasRole('ADMIN') || module.roles.some(...).
 */
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import CentralWorkstationPage from './CentralWorkstationPage'

// FK-107: C3 — "Beérkezett adatok" (line 97). Plain getByText, no new testid.
const TITLE = 'Beérkezett adatok'

const mockHasCanonicalRole = vi.fn()
const mockHasRole = vi.fn()

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (
    selector: (s: {
      centralModules: string[] | null
      hasCanonicalRole: typeof mockHasCanonicalRole
      hasRole: typeof mockHasRole
    }) => unknown,
  ) =>
    selector({
      centralModules: null,
      hasCanonicalRole: mockHasCanonicalRole,
      hasRole: mockHasRole,
    }),
}))

function renderPage(roles: string | string[], admin = false) {
  mockHasCanonicalRole.mockReset()
  mockHasRole.mockReset()

  const roleList = Array.isArray(roles) ? roles : [roles]
  mockHasCanonicalRole.mockImplementation((r: string | string[]) => {
    const check = Array.isArray(r) ? r : [r]
    return check.some((c) => roleList.includes(c))
  })
  mockHasRole.mockImplementation((r: string) => admin && r === 'ADMIN')

  return render(
    <MemoryRouter>
      <CentralWorkstationPage />
    </MemoryRouter>,
  )
}

describe('CentralWorkstationPage — FK-107 tile RBAC (FR-1)', () => {
  beforeEach(() => {
    mockHasCanonicalRole.mockReset()
    mockHasRole.mockReset()
  })

  // Case 1: FR-1 foertektar — canonical foertektar → title present
  it('foertektar → Beérkezett adatok tile látszik', () => {
    renderPage('foertektar')
    expect(screen.getByText(TITLE)).toBeInTheDocument()
  })

  // Case 2: FR-1 belso_ellenor — canonical belso_ellenor → title present
  it('belso_ellenor → Beérkezett adatok tile látszik', () => {
    renderPage('belso_ellenor')
    expect(screen.getByText(TITLE)).toBeInTheDocument()
  })

  // Case 3: FR-1 ADMIN — hasRole('ADMIN') → title present
  it('ADMIN → Beérkezett adatok tile látszik', () => {
    renderPage([], true) // no canonical roles, admin=true
    expect(screen.getByText(TITLE)).toBeInTheDocument()
  })

  // Case 4: FR-1 irodavezeto — canonical irodavezeto → title absent
  it('irodavezeto → Beérkezett adatok tile NEM látszik', () => {
    renderPage('irodavezeto')
    expect(screen.queryByText(TITLE)).not.toBeInTheDocument()
  })
})

describe('CentralWorkstationPage — FK-110 Darius tile', () => {
  const DARIUS = 'Darius riport'

  it('foertektar → Darius riport tile látszik', () => {
    renderPage('foertektar')
    expect(screen.getByText(DARIUS)).toBeInTheDocument()
  })

  it('belso_ellenor → Darius riport tile látszik', () => {
    renderPage('belso_ellenor')
    expect(screen.getByText(DARIUS)).toBeInTheDocument()
  })

  it('irodavezeto → Darius riport tile NEM látszik', () => {
    renderPage('irodavezeto')
    expect(screen.queryByText(DARIUS)).not.toBeInTheDocument()
  })
})

describe('CentralWorkstationPage — FK-109 FR-4 booking-export tile szöveg', () => {
  it('a booking-export tile leírása a könyvelési CSV export, Raiffeisen/NAV említés nélkül', () => {
    renderPage('foertektar')
    const description = screen.getByText('Napi, havi és leltár könyvelési CSV export')
    expect(description).toBeInTheDocument()
    expect(screen.queryByText('Raiffeisen, Darius, NAV export')).toBeNull()
  })
})
