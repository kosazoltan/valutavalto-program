/**
 * RoleGate — szerepkör-szintű route-védelem tesztje (Codex #1056 P1).
 * Bizonyítja: a pénztáros (penztaros) közvetlen URL-belépése blokkolt, a jogosult
 * (foertektar) átengedve, és bármely szerver-szerepkör (hasSupervisoryAccess) is átengedi.
 */
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import RoleGate from './RoleGate'

const mockHasCanonicalRole = vi.fn()
vi.mock('../stores/authStore', () => ({
  useAuthStore: (selector: (s: { hasCanonicalRole: typeof mockHasCanonicalRole }) => unknown) =>
    selector({ hasCanonicalRole: mockHasCanonicalRole }),
}))

function renderGate() {
  return render(
    <MemoryRouter>
      <RoleGate canonicalRoles={['foertektar', 'belso_ellenor', 'ugyvezeto']}>
        <div>VEDETT_TARTALOM</div>
      </RoleGate>
    </MemoryRouter>,
  )
}

describe('RoleGate — #1056 P1 route-RBAC', () => {
  beforeEach(() => mockHasCanonicalRole.mockReset())

  it('pénztáros (egyetlen engedélyezett szerepkör sem) → blokkolt, a tartalom nem renderelődik', () => {
    // penztaros NINCS sem a canonicalRoles-ban, sem a SZERVER_ROLES-ban.
    mockHasCanonicalRole.mockImplementation((r: string) => r === 'penztaros')
    renderGate()
    expect(screen.queryByText('VEDETT_TARTALOM')).not.toBeInTheDocument()
  })

  it('foertektar (engedélyezett canonical role) → a védett tartalom renderelődik', () => {
    mockHasCanonicalRole.mockImplementation((r: string) => r === 'foertektar')
    renderGate()
    expect(screen.getByText('VEDETT_TARTALOM')).toBeInTheDocument()
  })

  it('belso_ellenor (engedélyezett) → átengedve', () => {
    mockHasCanonicalRole.mockImplementation((r: string) => r === 'belso_ellenor')
    renderGate()
    expect(screen.getByText('VEDETT_TARTALOM')).toBeInTheDocument()
  })

  it('P2 (Codex #1056): tágabb szerver-szerepkör (pl. irodai_dolgozo), ami NINCS a listán → blokkolt', () => {
    // A szigorítás előtt a hasSupervisoryAccess rövidzár átengedte volna; most NEM.
    mockHasCanonicalRole.mockImplementation((r: string) => r === 'irodai_dolgozo')
    renderGate()
    expect(screen.queryByText('VEDETT_TARTALOM')).not.toBeInTheDocument()
  })

  it('ADMIN (hasCanonicalRole minden role-t teljesít) → átengedve', () => {
    mockHasCanonicalRole.mockReturnValue(true)
    renderGate()
    expect(screen.getByText('VEDETT_TARTALOM')).toBeInTheDocument()
  })
})
