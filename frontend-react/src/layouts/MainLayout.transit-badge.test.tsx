import { act, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeAll, beforeEach, describe, expect, it, vi } from 'vitest'
import MainLayout from './MainLayout'
import type { AppMode } from '../types/appMode'

/**
 * FKH-026 FR-4 (RED-fázis, 2026-07-30; v3-ra frissítve a 2. körben): az
 * "Úton lévő csomagok" fejléc-jelző (TransitBadge, MainLayout.tsx:365) a
 * MENÜPONT-LÁTHATÓSÁGHOZ kötött (TBD-3 lezárva, v3):
 *  - Pénztáros/Értéktáros (és helyettesük): a jelző NEM jelenhet meg,
 *    FÜGGETLENÜL attól, hány tétel van ténylegesen úton → ma RED;
 *  - Főértéktáros(-helyettes): a jelző VÁLTOZATLANUL látszik, a tényleges
 *    darabszámmal → ma is zöld ŐR-teszt (ld. lentebb, miért zöld már ma).
 *
 * Fázis 0 felderítés (1.+2. kör): a jelenlegi TransitBadge-en SEMMILYEN
 * role-alapú feltétel nincs — a menürendszertől teljesen független, egyetlen
 * feltétele a count>0 (count===0 → null). Ezért a lokál-szerepkörös tesztek
 * 1 elemű listával mockolnak (a jelenlegi kód ilyenkor megjeleníti → RED), a
 * foertektar-tesztek pedig NEM a bypass miatt zöldek ma, hanem mert a badge
 * mindenkinek megjelenik — a GREEN-fázis után is zöldnek kell maradniuk.
 *
 * (A repo meglévő MainLayout-tesztjei forrás-olvasó szerkezeti tesztek; a FR-4
 * viselkedés-szintű állítás, ezért itt a teljes MainLayout renderelődik mockolt
 * session/auth/api réteggel — ld. MainLayout.sticky.test.tsx megjegyzése.)
 */

const mocks = vi.hoisted(() => ({
  getIncoming: vi.fn(),
  isOpen: vi.fn(),
  getCurrent: vi.fn(),
  logout: vi.fn(),
  appMode: { mode: 'penztar' as AppMode, isLoading: false },
  canonicalRoles: ['penztar'] as string[],
}))

vi.mock('../services/api/index', () => ({
  authApi: { logout: mocks.logout },
  dailySessionApi: { isOpen: mocks.isOpen, getCurrent: mocks.getCurrent },
  transitApi: { getIncoming: mocks.getIncoming },
}))

vi.mock('../stores/authStore', () => ({
  useAuthStore: () => ({
    user: {
      id: 1,
      fullName: 'Teszt Elek',
      workerCode: 'T001',
      branchName: 'Szeged 01',
    },
    logout: mocks.logout,
    hasRole: () => false,
    hasCanonicalRole: (role: string) => mocks.canonicalRoles.includes(role),
  }),
}))

vi.mock('../hooks/useAppMode', () => ({
  useAppMode: () => mocks.appMode,
}))

vi.mock('../hooks/useFeatureFlags', () => ({
  useFeatureFlags: () => ({}),
}))

function renderLayout(mode: AppMode, canonicalRole: string) {
  mocks.appMode = { mode, isLoading: false }
  mocks.canonicalRoles = [canonicalRole]
  return render(
    <MemoryRouter initialEntries={['/']}>
      <Routes>
        <Route element={<MainLayout />}>
          <Route index element={<div data-testid="outlet-child" />} />
        </Route>
      </Routes>
    </MemoryRouter>,
  )
}

describe('MainLayout — FKH-026 FR-4: úton lévő csomagok fejléc-jelző', () => {
  beforeAll(() => {
    // jsdom nem ad matchMedia-t; a MainLayout a sidebar-állapothoz használja.
    // Desktop-viselkedés: '(min-width: 768px)' → true (sidebar nyitva).
    Object.defineProperty(window, 'matchMedia', {
      writable: true,
      value: (query: string) => ({
        matches: query.includes('min-width'),
        media: query,
        onchange: null,
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        addListener: vi.fn(),
        removeListener: vi.fn(),
        dispatchEvent: vi.fn(),
      }),
    })
  })

  beforeEach(() => {
    vi.clearAllMocks()
    // Van 1 db ténylegesen úton lévő tétel — a jelenlegi TransitBadge ilyenkor renderel.
    mocks.getIncoming.mockResolvedValue([{ id: 'transit-1' }])
    mocks.isOpen.mockResolvedValue(true)
    mocks.getCurrent.mockResolvedValue({ id: 'session-1' })
  })

  it.each([
    ['penztar', 'penztar'],
    ['ertektar', 'ertektar'],
  ])(
    'FR-4: %s módban (%s szerepkör, helyettesre is érvényes) a fejlécen NEM jelenik meg a jelző, pedig van úton lévő tétel',
    async (mode, role) => {
      renderLayout(mode as AppMode, role)

      await screen.findByTestId('outlet-child')
      // FKH-026 GREEN (Tomi-döntés 2026-07-30): a RED-kori szinkronizáció
      // (waitFor: getIncoming hívódott) a badge akkori feltétel-nélküli
      // mountolását kódolta. Az FK v3 Fázis 2 a HÍVÁS feltételessé tételét írja
      // elő — a rejtett badge nem is mountolódik, így nem is polloz. Ez a csere
      // a teszt-szinkronizáció frissítése, nem az FR-4 tartalmi módosítása:
      // a lényegi állítás (a jelző nem jelenik meg) változatlan, és KIEGÉSZÜL
      // azzal, hogy felesleges /transit/incoming poll sem indul.
      await act(async () => {
        await Promise.resolve()
        await Promise.resolve()
      })

      expect(screen.queryByTitle(/Úton lévő csomagok/)).not.toBeInTheDocument()
      expect(mocks.getIncoming).not.toHaveBeenCalled()
    },
  )

  // v3 (TBD-3): foertektar(-helyettes) esetén a jelző VÁLTOZATLANUL látszik, a
  // tényleges darabszámmal. MA IS ZÖLD — de nem a bypass miatt, hanem mert a
  // badge jelenleg mindenkinek megjelenik (nincs role-feltétel rajta); a
  // GREEN-fázis (menü-láthatósághoz kötés) után is zöldnek KELL maradnia.
  it.each([['penztar'], ['ertektar']])(
    'FR-4 kiegészítés (v3, őr): %s módban a foertektar TOVÁBBRA IS látja a jelzőt a tényleges darabszámmal',
    async (mode) => {
      mocks.getIncoming.mockResolvedValue([{ id: 'transit-1' }, { id: 'transit-2' }])
      renderLayout(mode as AppMode, 'foertektar')

      await screen.findByTestId('outlet-child')
      const badge = await screen.findByTitle(/Úton lévő csomagok: 2 db/)
      expect(badge).toBeInTheDocument()
      expect(badge).toHaveTextContent('2')
    },
  )
})
