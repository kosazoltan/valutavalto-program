import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import LoginPage from './LoginPage'

// --- Mocks ---
const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  loginStore: vi.fn(),
  selectRoleStore: vi.fn(),
  logoutStore: vi.fn(),
  authLogin: vi.fn(),
  authSelectRole: vi.fn(),
  authGoogleLogin: vi.fn(),
  appMode: 'full' as string,
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return { ...actual, useNavigate: () => mocks.navigate }
})

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (
    selector: (state: {
      login: typeof mocks.loginStore
      selectRole: typeof mocks.selectRoleStore
      logout: typeof mocks.logoutStore
    }) => unknown,
  ) =>
    selector({
      login: mocks.loginStore,
      selectRole: mocks.selectRoleStore,
      logout: mocks.logoutStore,
    }),
}))

vi.mock('../../services/api/index', () => ({
  authApi: {
    login: mocks.authLogin,
    selectRole: mocks.authSelectRole,
    googleLogin: mocks.authGoogleLogin,
  },
}))

vi.mock('../../hooks/useAppMode', () => ({
  useAppMode: () => ({ mode: mocks.appMode, isLoading: false }),
}))

// --- Test data ---
function makeLoginResponse(role: string, activeRole?: string) {
  return {
    worker: {
      id: 1,
      workerCode: 'AB12',
      firstName: 'Teszt',
      lastName: 'Felhasznalo',
      fullName: 'Teszt Felhasznalo',
      role,
      branchId: 'b1',
      branchCode: 'KORUT',
      branchName: 'Korut',
      companyId: 'c1',
      companyCode: 'EBC',
      companyName: 'Exclusive Best Change',
    },
    token: 'jwt-token',
    tokenType: 'Bearer',
    expiresAt: '2099-01-01T00:00:00Z',
    activeRole: activeRole ?? role,
    permissions: ['TRADE_EXECUTE'],
    roles: [role],
    roleSelectionRequired: false,
  }
}

function renderLoginPage() {
  render(
    <MemoryRouter>
      <LoginPage />
    </MemoryRouter>,
  )
}

async function fillAndSubmitLogin(user: ReturnType<typeof userEvent.setup>) {
  const textboxes = screen.getAllByRole('textbox')
  const companyInput = textboxes[0]!
  const workerInput = textboxes[1]!
  const passwordInput = document.querySelector('input[type="password"]') as HTMLInputElement

  await user.clear(companyInput)
  await user.type(companyInput, 'ebc')
  await user.type(workerInput, 'ab12')
  await user.type(passwordInput, 'secret')
  await user.click(screen.getByRole('button', { name: 'Bejelentkezés' }))
}

// ==========================================================
// RBAC Whitelist tesztek — szerver (full) módban
// ==========================================================
describe('LoginPage RBAC Whitelist', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.appMode = 'full' // szerver mód
  })

  describe('szerver módban (full) — engedélyezett role-ok', () => {
    it.each([
      ['SUPERVISOR', '/central-workstation'],
      ['MANAGER', '/central-workstation'],
      ['ADMIN', '/central-workstation'],
    ])('%s role sikeresen belép és %s-ra navigál', async (role, expectedRoute) => {
      mocks.authLogin.mockResolvedValue(makeLoginResponse(role))
      const user = userEvent.setup()

      renderLoginPage()
      await fillAndSubmitLogin(user)

      await waitFor(() => {
        expect(mocks.authLogin).toHaveBeenCalled()
      })

      expect(mocks.loginStore).toHaveBeenCalled()
      expect(mocks.navigate).toHaveBeenCalledWith(expectedRoute)
    })
  })

  describe('szerver módban (full) — blokkolt role-ok', () => {
    it.each(['CASHIER', 'INTERN', 'VIEWER'])('%s role blokkolva hibaüzenettel', async (role) => {
      mocks.authLogin.mockResolvedValue(makeLoginResponse(role))
      const user = userEvent.setup()

      renderLoginPage()
      await fillAndSubmitLogin(user)

      await waitFor(() => {
        expect(mocks.authLogin).toHaveBeenCalled()
      })

      expect(await screen.findByText(/Hozzáférés megtagadva/)).toBeInTheDocument()
      expect(mocks.loginStore).not.toHaveBeenCalled()
      expect(mocks.navigate).not.toHaveBeenCalled()
    })
  })

  describe('szerver módban (full) — activeRole vs worker.role precedencia', () => {
    it('activeRole ADMIN felülírja worker.role CASHIER-t → belépés sikeres', async () => {
      mocks.authLogin.mockResolvedValue(makeLoginResponse('CASHIER', 'ADMIN'))
      const user = userEvent.setup()

      renderLoginPage()
      await fillAndSubmitLogin(user)

      await waitFor(() => {
        expect(mocks.authLogin).toHaveBeenCalled()
      })

      expect(mocks.loginStore).toHaveBeenCalled()
      expect(mocks.navigate).toHaveBeenCalledWith('/central-workstation')
    })

    it('activeRole CASHIER worker.role ADMIN-nal → blokkolva (activeRole dominál)', async () => {
      mocks.authLogin.mockResolvedValue(makeLoginResponse('ADMIN', 'CASHIER'))
      const user = userEvent.setup()

      renderLoginPage()
      await fillAndSubmitLogin(user)

      await waitFor(() => {
        expect(mocks.authLogin).toHaveBeenCalled()
      })

      expect(await screen.findByText(/Hozzáférés megtagadva/)).toBeInTheDocument()
      expect(mocks.loginStore).not.toHaveBeenCalled()
    })
  })
})

// ==========================================================
// Pénztár módban (penztar) — nincs RBAC korlátozás
// ==========================================================
describe('LoginPage Pénztár mód — nincs RBAC', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.appMode = 'penztar'
  })

  it.each([
    ['CASHIER', '/cashier'],
    ['SUPERVISOR', '/dashboard'],
    ['MANAGER', '/treasury'],
    ['ADMIN', '/dashboard'],
  ])('%s role sikeresen belép pénztár módban → %s', async (role, expectedRoute) => {
    mocks.authLogin.mockResolvedValue(makeLoginResponse(role))
    const user = userEvent.setup()

    renderLoginPage()
    await fillAndSubmitLogin(user)

    await waitFor(() => {
      expect(mocks.authLogin).toHaveBeenCalled()
    })

    expect(mocks.loginStore).toHaveBeenCalled()
    expect(mocks.navigate).toHaveBeenCalledWith(expectedRoute)
  })
})

// ==========================================================
// Értéktár módban (ertektar) — nincs RBAC korlátozás
// ==========================================================
describe('LoginPage Értéktár mód — nincs RBAC', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.appMode = 'ertektar'
  })

  it('CASHIER sikeresen belép értéktár módban', async () => {
    mocks.authLogin.mockResolvedValue(makeLoginResponse('CASHIER'))
    const user = userEvent.setup()

    renderLoginPage()
    await fillAndSubmitLogin(user)

    await waitFor(() => {
      expect(mocks.authLogin).toHaveBeenCalled()
    })

    expect(mocks.loginStore).toHaveBeenCalled()
    expect(mocks.navigate).toHaveBeenCalledWith('/cashier')
  })
})

// ==========================================================
// Role-alapú routing validálás
// ==========================================================
describe('LoginPage role-alapú routing', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.appMode = 'penztar' // nincs RBAC szűrés
  })

  it.each([
    ['CASHIER', '/cashier'],
    ['MANAGER', '/treasury'],
    ['TREASURY_MANAGER', '/treasury'],
    ['SUPERVISOR', '/dashboard'],
    ['ADMIN', '/dashboard'],
  ])('%s role → %s route', async (role, expectedRoute) => {
    mocks.authLogin.mockResolvedValue(makeLoginResponse(role))
    const user = userEvent.setup()

    renderLoginPage()
    await fillAndSubmitLogin(user)

    await waitFor(() => {
      expect(mocks.authLogin).toHaveBeenCalled()
    })

    expect(mocks.navigate).toHaveBeenCalledWith(expectedRoute)
  })
})

// ==========================================================
// Hibaüzenet tartalom validálás
// ==========================================================
describe('LoginPage hibaüzenetek', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mocks.appMode = 'full'
  })

  it('RBAC hibaüzenet tartalmazza a "főértéktáros" szót', async () => {
    mocks.authLogin.mockResolvedValue(makeLoginResponse('CASHIER'))
    const user = userEvent.setup()

    renderLoginPage()
    await fillAndSubmitLogin(user)

    const errorMsg = await screen.findByText(/főértéktáros/)
    expect(errorMsg).toBeInTheDocument()
  })

  it('API hiba esetén az API hibaüzenet jelenik meg, nem RBAC', async () => {
    mocks.authLogin.mockRejectedValue(new Error('Hibás jelszó'))
    const user = userEvent.setup()

    renderLoginPage()
    await fillAndSubmitLogin(user)

    expect(await screen.findByText('Hibás jelszó')).toBeInTheDocument()
  })
})
