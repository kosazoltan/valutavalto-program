import { useState, useEffect, useCallback } from 'react'
import { Outlet, NavLink, useNavigate, Navigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
import { dailySessionApi } from '../services/api/index'
import {
  Home,
  ArrowLeftRight,
  Users,
  TrendingUp,
  Wallet,
  FileText,
  Settings,
  LogOut,
  Menu,
  X,
  ChevronDown,
  Bell,
  User,
  Building2,
  LayoutDashboard,
  Shield,
  Sun,
  Loader2,
  HardDrive,
  Camera,
  Download,
} from 'lucide-react'

// Menüpontok csoportosítva (professzionális sidebar struktúra)
const menuGroups = [
  {
    label: 'Főoldal',
    items: [
      { path: '/dashboard', label: 'Irányítópult', icon: Home },
      { path: '/cashier', label: 'Pénztáros műveletek', icon: LayoutDashboard },
    ]
  },
  {
    label: 'Tranzakciók',
    items: [
      { path: '/transactions/new', label: 'Új tranzakció', icon: ArrowLeftRight },
      { path: '/transactions', label: 'Tranzakciólista', icon: FileText },
    ]
  },
  {
    label: 'Ügyfelek & Árfolyamok',
    items: [
      { path: '/customers', label: 'Ügyfelek', icon: Users },
      { path: '/rates', label: 'Árfolyamok', icon: TrendingUp },
    ]
  },
  {
    label: 'Pénztár & Riportok',
    items: [
      { path: '/cashdesk', label: 'Pénztár', icon: Wallet },
      { path: '/reports', label: 'Riportok', icon: FileText },
    ]
  },
  {
    label: 'Értéktár',
    items: [
      { path: '/treasury', label: 'Értéktári Dashboard', icon: LayoutDashboard },
    ]
  },
  {
    label: 'Kamera',
    items: [
      { path: '/camera/live', label: 'Élő kép', icon: Camera },
      { path: '/camera/playback', label: 'Visszajátszás', icon: Camera },
      { path: '/camera/export', label: 'Export & Custody', icon: Download },
      { path: '/camera/status', label: 'Állapot', icon: Camera },
    ]
  },
  {
    label: 'Adminisztráció',
    items: [
      { path: '/audit-log', label: 'Audit Log', icon: Shield },
      { path: '/local-queue', label: 'Helyi Queue', icon: HardDrive },
      { path: '/settings', label: 'Rendszer beállítások', icon: Settings },
    ]
  }
]

interface SessionInfo {
  id: number
  sessionDate: string
  status: string
  openedAt?: string
  openedByWorkerName?: string
  openingBalanceHuf: number
  transactionCount: number
}

export default function MainLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [sessionChecking, setSessionChecking] = useState(true)
  const [sessionReady, setSessionReady] = useState(false)
  const [sessionInfo, setSessionInfo] = useState<SessionInfo | null>(null)
  const [showSessionDialog, setShowSessionDialog] = useState(false)
  const [sessionError, setSessionError] = useState<string | null>(null)
  const { user, logout, hasRole } = useAuthStore()
  const navigate = useNavigate()

  const initSession = useCallback(async () => {
    try {
      setSessionChecking(true)
      setSessionError(null)

      // 1. Ellenőrizzük van-e nyitott session
      const isOpen = await dailySessionApi.isOpen()

      if (isOpen) {
        // Már nyitott — lekérjük az infót és folytatjuk
        try {
          const current = await dailySessionApi.getCurrent()
          setSessionInfo(current as unknown as SessionInfo)
        } catch { /* session info nem kritikus */ }
        setSessionReady(true)
        return
      }

      // 2. Nincs nyitott session → redirect napnyitás képernyőre
      setSessionError('redirect-day-open')
      setShowSessionDialog(true)
    } catch {
      // Backend nem elérhető
      setSessionError('A szerver nem elérhető. Ellenőrizze a kapcsolatot!')
      setShowSessionDialog(true)
    } finally {
      setSessionChecking(false)
    }
  }, [])

  useEffect(() => {
    initSession()
  }, [initSession])

  const handleRetryOpen = async () => {
    try {
      setShowSessionDialog(false)
      setSessionChecking(true)
      await initSession()
    } catch {
      setSessionError('A szerver nem elérhető. Ellenőrizze a kapcsolatot!')
      setShowSessionDialog(true)
    }
  }

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-form-bg flex">
      {/* Napnyitás hiba dialógus — csak ha az automatikus nyitás nem sikerült */}
      {showSessionDialog && !sessionReady && sessionError === 'redirect-day-open' && (
        <Navigate to="/cashdesk/day-open" replace />
      )}

      {showSessionDialog && !sessionReady && sessionError && sessionError !== 'redirect-day-open' && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="bg-white rounded-2xl shadow-2xl p-8 max-w-md w-full mx-4">
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 bg-danger-100 rounded-xl flex items-center justify-center">
                <Sun size={28} className="text-danger-600" />
              </div>
              <div>
                <h2 className="text-xl font-bold text-secondary-900">Napnyitás sikertelen</h2>
                <p className="text-sm text-secondary-500">
                  {new Date().toLocaleDateString('hu-HU', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' })}
                </p>
              </div>
            </div>
            <div className="mb-4 p-3 bg-danger-50 border border-danger-200 rounded-lg text-danger-700 text-sm">
              {sessionError}
            </div>
            <p className="text-secondary-600 mb-6 text-sm">
              Az automatikus napnyitás nem sikerült. Kérjük, ellenőrizze a hibaüzenetet és próbálja újra.
            </p>
            <div className="flex gap-3">
              <button
                onClick={handleLogout}
                className="flex-1 px-4 py-3 border border-secondary-300 text-secondary-700 rounded-lg hover:bg-secondary-50 transition-colors font-medium"
              >
                Kijelentkezés
              </button>
              <button
                onClick={handleRetryOpen}
                className="flex-1 px-4 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium flex items-center justify-center gap-2"
              >
                <Sun size={18} />
                Újrapróbálás
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Loading spinner amíg a session check fut */}
      {sessionChecking && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-form-bg">
          <div className="flex flex-col items-center gap-4">
            <Loader2 size={48} className="animate-spin text-primary-600" />
            <p className="text-secondary-600 font-medium">Munkamenet ellenőrzése...</p>
          </div>
        </div>
      )}
      {/* MODERN Sidebar */}
      <aside
        className={`${
          sidebarOpen ? 'w-64' : 'w-16'
        } bg-secondary-900 text-white transition-all duration-300 ease-in-out flex flex-col shadow-xl`}
      >
        {/* Logo/Header */}
        <div className="h-16 px-4 flex items-center justify-between border-b border-secondary-700">
          {sidebarOpen && (
            <div className="flex items-center gap-2">
              <Building2 size={24} className="text-accent-400" />
              <span className="font-bold text-base">EBC Valutaváltó</span>
            </div>
          )}
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="p-2 hover:bg-secondary-700 rounded-lg transition-colors"
          >
            {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>

        {/* Navigation Groups */}
        <nav className="flex-1 py-4 overflow-y-auto">
          {menuGroups.map((group) => (
            <div key={group.label} className="mb-6">
              {sidebarOpen && (
                <div className="px-4 mb-2 text-xs font-semibold text-secondary-400 uppercase tracking-wider">
                  {group.label}
                </div>
              )}
              {group.items
                .filter((item) => !('minRole' in item) || hasRole((item as { minRole: string }).minRole))
                .map((item) => (
                <NavLink
                  key={item.path}
                  to={item.path}
                  className={({ isActive }) =>
                    `flex items-center gap-3 px-4 py-2.5 text-sm font-medium transition-all duration-200 ${
                      isActive 
                        ? 'bg-primary-600 text-white border-l-4 border-accent-400' 
                        : 'text-secondary-300 hover:bg-secondary-800 hover:text-white'
                    }`
                  }
                >
                  <item.icon size={20} className="shrink-0" />
                  {sidebarOpen && <span className="truncate">{item.label}</span>}
                </NavLink>
              ))}
            </div>
          ))}
        </nav>

        {/* User info & Logout */}
        <div className="border-t border-secondary-700 p-4">
          {sidebarOpen && user && (
            <div className="mb-3 px-3 py-2 bg-secondary-800 rounded-lg">
              <div className="flex items-center gap-2 mb-1">
                <User size={16} className="text-secondary-400" />
                <div className="text-sm font-semibold truncate">{user.fullName}</div>
              </div>
              <div className="text-xs text-secondary-400 truncate">{user.branchName}</div>
            </div>
          )}
          <button
            onClick={handleLogout}
            className={`w-full flex items-center ${sidebarOpen ? 'justify-start' : 'justify-center'} gap-2 px-3 py-2 text-sm font-medium text-danger-300 hover:bg-danger-900/20 rounded-lg transition-colors`}
          >
            <LogOut size={18} />
            {sidebarOpen && <span>Kijelentkezés</span>}
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 flex flex-col">
        {/* MODERN Header Bar */}
        <header className="h-16 bg-white border-b border-form-border flex items-center justify-between px-6 shadow-sm">
          <div className="flex items-center gap-4">
            <div className="text-sm">
              <span className="text-secondary-500">Telephely:</span>
              <span className="ml-2 font-semibold text-secondary-900">{user?.branchName || 'Központi'}</span>
            </div>
            <div className="h-6 w-px bg-secondary-200"></div>
            <div className="text-sm text-secondary-600">
              {new Date().toLocaleDateString('hu-HU', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'short' })}
            </div>
            {sessionInfo && (
              <>
                <div className="h-6 w-px bg-secondary-200"></div>
                <div className="flex items-center gap-1.5 text-sm">
                  <span className="w-2 h-2 bg-success-500 rounded-full"></span>
                  <span className="text-success-700 font-medium">Nap nyitva</span>
                </div>
              </>
            )}
          </div>
          
          <div className="flex items-center gap-4">
            {/* Notification Bell */}
            <button className="relative p-2 hover:bg-secondary-50 rounded-lg transition-colors">
              <Bell size={20} className="text-secondary-600" />
              <span className="absolute top-1 right-1 w-2 h-2 bg-danger-500 rounded-full"></span>
            </button>
            
            {/* User Menu */}
            <div className="flex items-center gap-3 px-3 py-2 hover:bg-secondary-50 rounded-lg cursor-pointer transition-colors">
              <div className="w-8 h-8 bg-primary-600 rounded-full flex items-center justify-center text-white font-semibold text-sm">
                {user?.fullName?.charAt(0) || 'U'}
              </div>
              <div className="text-sm hidden sm:block">
                <div className="font-semibold text-secondary-900">{user?.fullName}</div>
                <div className="text-xs text-secondary-500">Pénztáros</div>
              </div>
              <ChevronDown size={16} className="text-secondary-400" />
            </div>
          </div>
        </header>

        {/* Page content */}
        <div className="flex-1 p-6 overflow-auto min-h-0">
          <Outlet />
        </div>

        {/* MODERN Status bar */}
        <div className="status-bar">
          <div className="flex items-center gap-4">
            <span className="flex items-center gap-2">
              <span className="w-2 h-2 bg-success-500 rounded-full animate-pulse"></span>
              <span className="text-success-700 font-medium">Online</span>
            </span>
            <span className="text-secondary-500">|</span>
            <span className="text-secondary-600">Utolsó szinkron: {new Date().toLocaleTimeString('hu-HU')}</span>
          </div>
          <span className="text-secondary-600 font-mono">{new Date().toLocaleTimeString('hu-HU')}</span>
        </div>
      </main>
    </div>
  )
}
