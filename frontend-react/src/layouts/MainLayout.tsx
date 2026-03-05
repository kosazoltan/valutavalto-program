import { useState } from 'react'
import { Outlet, NavLink, useNavigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
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
  Calculator,
  ChevronDown,
  Bell,
  User,
  Building2,
  LayoutDashboard,
} from 'lucide-react'

// Menüpontok csoportosítva (professzionális sidebar struktúra)
const menuGroups = [
  {
    label: 'Főoldal',
    items: [
      { path: '/dashboard', label: 'Irányítópult', icon: Home }
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
      { path: '/rates/creation', label: 'Árfolyamkészítés', icon: Calculator },
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
    label: 'Beállítások',
    items: [
      { path: '/settings', label: 'Rendszer beállítások', icon: Settings },
    ]
  }
]

export default function MainLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const { user, logout } = useAuthStore()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  return (
    <div className="min-h-screen bg-form-bg flex">
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
          {menuGroups.map((group, groupIdx) => (
            <div key={groupIdx} className="mb-6">
              {sidebarOpen && (
                <div className="px-4 mb-2 text-xs font-semibold text-secondary-400 uppercase tracking-wider">
                  {group.label}
                </div>
              )}
              {group.items.map((item) => (
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
        <div className="flex-1 p-6 overflow-auto">
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
