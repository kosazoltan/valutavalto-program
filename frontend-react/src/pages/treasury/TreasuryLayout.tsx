import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { useHotkeys } from 'react-hotkeys-hook'
import {
  LayoutDashboard,
  Grid3X3,
  ArrowLeftRight,
  TrendingUp,
  FileText,
  Keyboard,
  Building2,
  Receipt,
  Download,
  Users,
  Landmark,
} from 'lucide-react'
import { useState, useCallback } from 'react'

const treasuryTabs = [
  { path: '/treasury', label: 'Dashboard', icon: LayoutDashboard, hotkey: 'F1', end: true },
  { path: '/treasury/matrix', label: 'Készlet Mátrix', icon: Grid3X3, hotkey: 'F2', end: false },
  { path: '/treasury/movements', label: 'Mozgások', icon: ArrowLeftRight, hotkey: 'F3', end: false },
  { path: '/treasury/bank', label: 'Banki Tx', icon: Building2, hotkey: 'F4', end: false },
  { path: '/treasury/rates', label: 'Árfolyamkészítés', icon: TrendingUp, hotkey: 'F5', end: false },
  { path: '/treasury/reports', label: 'Jelentések', icon: FileText, hotkey: 'F6', end: false },
  { path: '/treasury/vat', label: 'ÁFA visszatérítés', icon: Receipt, hotkey: 'F7', end: false },
  { path: '/treasury/trb-export', label: 'TRB Export', icon: Download, hotkey: 'F8', end: false },
  { path: '/treasury/customer-turnover', label: 'Ügyfélforgalom', icon: Users, hotkey: 'F9', end: false },
  { path: '/treasury/bank-turnover', label: 'Bankforgalom', icon: Landmark, hotkey: 'F10', end: false },
] as const

export default function TreasuryLayout() {
  const navigate = useNavigate()
  const [showHelp, setShowHelp] = useState(false)

  const closeHelp = useCallback(() => setShowHelp(false), [])
  const toggleHelp = useCallback(() => setShowHelp(prev => !prev), [])

  // F-key navigation
  useHotkeys('f1', (e) => { e.preventDefault(); navigate('/treasury') }, { enableOnFormTags: false })
  useHotkeys('f2', (e) => { e.preventDefault(); navigate('/treasury/matrix') }, { enableOnFormTags: false })
  useHotkeys('f3', (e) => { e.preventDefault(); navigate('/treasury/movements') }, { enableOnFormTags: false })
  useHotkeys('f4', (e) => { e.preventDefault(); navigate('/treasury/bank') }, { enableOnFormTags: false })
  useHotkeys('f5', (e) => { e.preventDefault(); navigate('/treasury/rates') }, { enableOnFormTags: false })
  useHotkeys('f6', (e) => { e.preventDefault(); navigate('/treasury/reports') }, { enableOnFormTags: false })
  useHotkeys('f7', (e) => { e.preventDefault(); navigate('/treasury/vat') }, { enableOnFormTags: false })
  useHotkeys('f8', (e) => { e.preventDefault(); navigate('/treasury/trb-export') }, { enableOnFormTags: false })
  useHotkeys('f9', (e) => { e.preventDefault(); navigate('/treasury/customer-turnover') }, { enableOnFormTags: false })
  useHotkeys('f10', (e) => { e.preventDefault(); navigate('/treasury/bank-turnover') }, { enableOnFormTags: false })
  useHotkeys('shift+/', () => toggleHelp(), { enableOnFormTags: false })
  useHotkeys('escape', () => closeHelp(), { enableOnFormTags: true })

  return (
    <div className="space-y-4">
      {/* Tab navigation */}
      <div className="flex items-center justify-between border-b border-form-border pb-0">
        <nav className="flex gap-0">
          {treasuryTabs.map((tab) => (
            <NavLink
              key={tab.path}
              to={tab.path}
              end={tab.end}
              className={({ isActive }) =>
                `flex items-center gap-2 px-4 py-2.5 text-sm font-medium border-b-2 transition-colors duration-200 ${
                  isActive
                    ? 'border-primary-600 text-primary-700 bg-primary-50/50'
                    : 'border-transparent text-secondary-500 hover:text-secondary-700 hover:border-secondary-300'
                }`
              }
            >
              <tab.icon size={16} />
              <span>{tab.label}</span>
              <kbd className="hidden lg:inline-block ml-1 px-1.5 py-0.5 text-[10px] font-mono bg-secondary-100 text-secondary-500 rounded">
                {tab.hotkey}
              </kbd>
            </NavLink>
          ))}
        </nav>
        <button
          onClick={toggleHelp}
          className="form-button h-8 text-xs mr-1 mb-0.5"
          title="Billentyűparancsok (?)"
        >
          <Keyboard size={14} />
          <span className="hidden sm:inline">?</span>
        </button>
      </div>

      {/* Help modal */}
      {showHelp && (
        <div className="fixed inset-0 bg-black/40 z-50 flex items-center justify-center" onClick={closeHelp}>
          <div
            className="bg-white rounded-lg shadow-xl p-6 max-w-md w-full mx-4"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-lg font-bold text-secondary-900 mb-4 flex items-center gap-2">
              <Keyboard size={20} className="text-primary-600" />
              Billentyűparancsok
            </h2>
            <div className="space-y-3">
              <div className="text-sm font-semibold text-secondary-600 uppercase tracking-wider">Navigáció</div>
              <HotkeyRow keys="F1" desc="Dashboard" />
              <HotkeyRow keys="F2" desc="Készlet Mátrix" />
              <HotkeyRow keys="F3" desc="Mozgások" />
              <HotkeyRow keys="F4" desc="Banki Tranzakciók" />
              <HotkeyRow keys="F5" desc="Árfolyamkészítés" />
              <HotkeyRow keys="F6" desc="Jelentések" />
              <HotkeyRow keys="F7" desc="ÁFA visszatérítés" />
              <HotkeyRow keys="F8" desc="TRB Export" />
              <HotkeyRow keys="F9" desc="Ügyfélforgalom" />
              <HotkeyRow keys="F10" desc="Bankforgalom" />
              <div className="border-t border-secondary-200 pt-3 mt-3">
                <div className="text-sm font-semibold text-secondary-600 uppercase tracking-wider mb-3">Általános</div>
                <HotkeyRow keys="?" desc="Billentyűparancsok" />
                <HotkeyRow keys="Esc" desc="Bezárás / Mégse" />
                <HotkeyRow keys="R" desc="Frissítés (képernyőtől függ)" />
              </div>
            </div>
            <button onClick={closeHelp} className="form-button-primary w-full mt-6">
              Bezárás
            </button>
          </div>
        </div>
      )}

      {/* Page content */}
      <Outlet />
    </div>
  )
}

function HotkeyRow({ keys, desc }: { keys: string; desc: string }) {
  return (
    <div className="flex items-center justify-between text-sm">
      <span className="text-secondary-700">{desc}</span>
      <kbd className="px-2 py-1 text-xs font-mono bg-secondary-100 text-secondary-600 rounded border border-secondary-200">
        {keys}
      </kbd>
    </div>
  )
}
