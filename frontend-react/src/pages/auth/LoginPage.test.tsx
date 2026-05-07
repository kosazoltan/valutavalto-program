import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { vi, describe, beforeEach, it, expect } from 'vitest'
import LoginPage from './LoginPage'

const mocks = vi.hoisted(() => ({
  navigate: vi.fn(),
  loginStore: vi.fn(),
  selectRoleStore: vi.fn(),
  logoutStore: vi.fn(),
  authLogin: vi.fn(),
  authSelectRole: vi.fn(),
  authGoogleLogin: vi.fn(),
}))

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual<typeof import('react-router-dom')>('react-router-dom')
  return {
    ...actual,
    useNavigate: () => mocks.navigate,
  }
})

vi.mock('../../stores/authStore', () => ({
  useAuthStore: (selector: (state: {
    login: typeof mocks.loginStore
    selectRole: typeof mocks.selectRoleStore
    logout: typeof mocks.logoutStore
  }) => unknown) =>
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

// Mock useAppMode — teszt környezetben 'penztar' mód (nincs RBAC whitelist)
vi.mock('../../hooks/useAppMode', () => ({
  useAppMode: () => ({ mode: 'penztar', isLoading: false }),
}))

const baseResponse = {
  worker: {
    id: 1,
    workerCode: 'AB12',
    firstName: 'Teszt',
    lastName: 'Felhasznalo',
    fullName: 'Teszt Felhasznalo',
    role: 'CASHIER',
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
  activeRole: 'CASHIER',
  permissions: ['TRADE_EXECUTE'],
  roles: ['CASHIER'],
  roleSelectionRequired: false,
}

function renderLoginPage() {
  render(
    <MemoryRouter>
      <LoginPage />
    </MemoryRouter>,
  )
}

describe('LoginPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('sikeres belépéskor meghívja a login API-t és dashboardra navigál', async () => {
    mocks.authLogin.mockResolvedValue(baseResponse)
    const user = userEvent.setup()

    renderLoginPage()

    const textboxes = screen.getAllByRole('textbox')
    const companyInput = textboxes[0]!
    const workerInput = textboxes[1]!
    const passwordInput = document.querySelector('input[type="password"]') as HTMLInputElement

    await user.clear(companyInput)
    await user.type(companyInput, 'ebc')
    await user.type(workerInput, 'ab12')
    await user.type(passwordInput, 'secret')
    await user.click(screen.getByRole('button', { name: 'Bejelentkezés' }))

    await waitFor(() => {
      expect(mocks.authLogin).toHaveBeenCalledWith({
        companyCode: 'EBC',
        workerCode: 'AB12',
        password: 'secret',
        appMode: 'penztar',
      })
    })

    expect(mocks.loginStore).toHaveBeenCalled()
    expect(mocks.navigate).toHaveBeenCalledWith('/cashier')
  })

  it('hibás belépéskor hibaüzenetet jelenít meg', async () => {
    mocks.authLogin.mockRejectedValue(new Error('Hibás bejelentkezési adatok'))
    const user = userEvent.setup()

    renderLoginPage()

    const workerInput = screen.getAllByRole('textbox')[1]!
    const passwordInput = document.querySelector('input[type="password"]') as HTMLInputElement

    await user.type(workerInput, 'ab12')
    await user.type(passwordInput, 'wrong')
    await user.click(screen.getByRole('button', { name: 'Bejelentkezés' }))

    expect(await screen.findByText('Hibás bejelentkezési adatok')).toBeInTheDocument()
  })

  it('több szerepkörnél nem perzisztál ideiglenes tokent role-választás előtt', async () => {
    mocks.authLogin.mockResolvedValue({
      ...baseResponse,
      token: 'temp-token',
      activeRole: null,
      roles: ['penztar', 'ertektar'],
      roleSelectionRequired: true,
    })
    mocks.authSelectRole.mockResolvedValue({
      ...baseResponse,
      token: 'final-token',
      activeRole: 'penztar',
      roles: ['penztar', 'ertektar'],
      roleSelectionRequired: false,
    })
    const user = userEvent.setup()

    renderLoginPage()

    const workerInput = screen.getAllByRole('textbox')[1]!
    const passwordInput = document.querySelector('input[type="password"]') as HTMLInputElement
    await user.type(workerInput, 'ab12')
    await user.type(passwordInput, 'secret')
    await user.click(screen.getByRole('button', { name: 'Bejelentkezés' }))

    expect(await screen.findByText('penztar')).toBeInTheDocument()
    expect(screen.queryByText('ertektar')).not.toBeInTheDocument()
    expect(mocks.loginStore).not.toHaveBeenCalled()
    expect(mocks.navigate).not.toHaveBeenCalled()

    await user.click(screen.getByText('penztar'))
    await user.click(screen.getByRole('button', { name: 'Belépés' }))

    await waitFor(() => {
      expect(mocks.authSelectRole).toHaveBeenCalledWith({
        token: 'temp-token',
        roleCode: 'penztar',
        appMode: 'penztar',
      })
    })
    expect(mocks.loginStore).toHaveBeenCalledWith(
      baseResponse.worker,
      'final-token',
      'Bearer',
      baseResponse.expiresAt,
      'penztar',
      baseResponse.permissions,
      ['penztar', 'ertektar'],
      false,
    )
    expect(mocks.navigate).toHaveBeenCalledWith('/cashier')
  })
})
