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
  Calculator
} from 'lucide-react'

const menuItems = [
  { path: '/dashboard', label: 'Főoldal', icon: Home },
  { path: '/transactions/new', label: 'Új tranzakció', icon: ArrowLeftRight },
  { path: '/transactions', label: 'Tranzakciók', icon: FileText },
  { path: '/customers', label: 'Ügyfelek', icon: Users },
  { path: '/rates', label: 'Árfolyamok', icon: TrendingUp },
  { path: '/rates/creation', label: 'Árfolyamkészítés', icon: Calculator },
  { path: '/cashdesk', label: 'Pénztár', icon: Wallet },
  { path: '/reports', label: 'Riportok', icon: FileText },
  { path: '/settings', label: 'Beállítások', icon: Settings },
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
      {/* Sidebar */}
      <aside
        className={`${
          sidebarOpen ? 'w-56' : 'w-14'
        } bg-white border-r border-form-border transition-all duration-200 flex flex-col`}
      >
        {/* Logo/Header */}
        <div className="header-bar flex items-center justify-between h-10">
          {sidebarOpen && <span className="font-bold">RepZtecH Exclusive Best Change</span>}
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="p-1 hover:bg-primary-700 rounded"
          >
            {sidebarOpen ? <X size={18} /> : <Menu size={18} />}
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 py-2">
          {menuItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) =>
                `flex items-center gap-2 px-3 py-2 text-sm hover:bg-gray-100 ${
                  isActive ? 'bg-primary-50 text-primary border-r-2 border-primary' : ''
                }`
              }
            >
              <item.icon size={18} />
              {sidebarOpen && <span>{item.label}</span>}
            </NavLink>
          ))}
        </nav>

        {/* User info & Logout */}
        <div className="border-t border-form-border p-2">
          {sidebarOpen && user && (
            <div className="text-xs text-gray-600 mb-2">
              <div className="font-semibold">{user.fullName}</div>
              <div>{user.branchName}</div>
            </div>
          )}
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-2 px-2 py-1.5 text-sm text-red-600 hover:bg-red-50 rounded"
          >
            <LogOut size={18} />
            {sidebarOpen && <span>Kijelentkezés</span>}
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 flex flex-col">
        {/* Toolbar */}
        <div className="toolbar justify-between">
          <div className="flex items-center gap-2 text-sm">
            <span className="font-semibold">{user?.branchName}</span>
            <span className="text-gray-400">|</span>
            <span>{new Date().toLocaleDateString('hu-HU')}</span>
          </div>
          <div className="flex items-center gap-2 text-sm">
            <span className="text-gray-600">Pénztáros:</span>
            <span className="font-semibold">{user?.fullName}</span>
          </div>
        </div>

        {/* Page content */}
        <div className="flex-1 p-3 overflow-auto">
          <Outlet />
        </div>

        {/* Status bar */}
        <div className="status-bar flex justify-between">
          <span>Kész</span>
          <span>{new Date().toLocaleTimeString('hu-HU')}</span>
        </div>
      </main>
    </div>
  )
}
