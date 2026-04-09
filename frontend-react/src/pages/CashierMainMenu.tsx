import { useNavigate } from 'react-router-dom'
import { useHotkeys } from 'react-hotkeys-hook'
import type { LucideIcon } from 'lucide-react'
import {
  Banknote, Coins, Repeat, ArrowRight, XCircle,
  TrendingUp, Wallet, BarChart3, Lock, FileText,
  Building2, List, Users, Calendar, Archive,
  RefreshCw, Settings,
} from 'lucide-react'

/**
 * Pénztáros főmenü — konzervatív üzleti megjelenés, MainLayout sidebar-on belül.
 *
 * Legacy: Unit47.pas — 9+9 menüpont, 2 oldal.
 * Billentyűparancsok: F1-F9 (1. oldal), Shift+F1-F9 (2. oldal)
 * Szám billentyűk: 1-9 az aktuális oldalon
 */

interface MenuItem {
  key: string
  label: string
  description: string
  icon: LucideIcon
  route: string
  shortcut: string
}

const MENU_ITEMS_PRIMARY: MenuItem[] = [
  { key: '1', label: 'Vétel', description: 'Deviza vásárlás ügyféltől', icon: Banknote, route: '/transactions/cashier?mode=buy', shortcut: 'F1' },
  { key: '2', label: 'Eladás', description: 'Deviza eladás ügyfélnek', icon: Coins, route: '/transactions/cashier?mode=sell', shortcut: 'F2' },
  { key: '3', label: 'Konverzió', description: 'Devizacsere (nem HUF)', icon: Repeat, route: '/transactions/conversion', shortcut: 'F3' },
  { key: '4', label: 'Átadás-átvétel', description: 'Pénztárak közötti átadás', icon: ArrowRight, route: '/transfers', shortcut: 'F4' },
  { key: '5', label: 'Stornó', description: 'Tranzakció visszavonás', icon: XCircle, route: '/transactions', shortcut: 'F5' },
  { key: '6', label: 'Árfolyamok', description: 'Aktuális árfolyamok kezelése', icon: TrendingUp, route: '/rates', shortcut: 'F6' },
  { key: '7', label: 'Készlet', description: 'Pénztár készletállomány', icon: Wallet, route: '/cashdesk', shortcut: 'F7' },
  { key: '8', label: 'Forgalom', description: 'Napi forgalmi kimutatás', icon: BarChart3, route: '/reports', shortcut: 'F8' },
]

const MENU_ITEMS_ADMIN: MenuItem[] = [
  { key: '1', label: 'Napi zárás', description: 'Pénztár napi lezárása', icon: Lock, route: '/closing/wizard', shortcut: 'Shift+F1' },
  { key: '2', label: 'Bizonylatok', description: 'Bizonylatok kezelése', icon: FileText, route: '/receipts', shortcut: 'Shift+F2' },
  { key: '3', label: 'Társpénztárak', description: 'Kapcsolódó pénztárak', icon: Building2, route: '/branch-groups', shortcut: 'Shift+F3' },
  { key: '4', label: 'Listák', description: 'Tranzakciós listák', icon: List, route: '/transactions', shortcut: 'Shift+F4' },
  { key: '5', label: 'Pénztárosok', description: 'Felhasználók kezelése', icon: Users, route: '/settings/users', shortcut: 'Shift+F5' },
  { key: '6', label: 'Napi forgalom', description: 'Részletes forgalmi adatok', icon: Calendar, route: '/reports/extended', shortcut: 'Shift+F6' },
  { key: '7', label: 'Régi zárás', description: 'Archív napi zárások', icon: Archive, route: '/archiving', shortcut: 'Shift+F7' },
  { key: '8', label: 'Címletezés', description: 'Címlet összetétel kezelése', icon: RefreshCw, route: '/cashdesk/denominations', shortcut: 'Shift+F8' },
  { key: '9', label: 'Beállítások', description: 'Rendszer konfiguráció', icon: Settings, route: '/settings', shortcut: 'Shift+F9' },
]

export default function CashierMainMenu() {
  const navigate = useNavigate()

  // Szám billentyűk: napi műveletek (1. csoport)
  useHotkeys('1,2,3,4,5,6,7,8', (e) => {
    const idx = parseInt(e.key) - 1
    const item = MENU_ITEMS_PRIMARY[idx]
    if (item?.route) navigate(item.route)
  })

  // F1-F8: napi műveletek
  useHotkeys('f1,f2,f3,f4,f5,f6,f7,f8', (e) => {
    e.preventDefault()
    const fKey = parseInt(e.key.replace('F', '').replace('f', '')) - 1
    const item = MENU_ITEMS_PRIMARY[fKey]
    if (item?.route) navigate(item.route)
  })

  return (
    <div className="space-y-8">
      {/* Page header */}
      <div>
        <h1 className="text-lg font-bold text-secondary-900">Pénztáros műveletek</h1>
        <p className="text-sm text-secondary-500 mt-1">
          Válasszon műveletet a listából, vagy használja a billentyűparancsokat (1-8, F1-F8)
        </p>
      </div>

      {/* Napi műveletek */}
      <section>
        <h2 className="text-sm font-semibold text-secondary-400 uppercase tracking-wider mb-3">
          Napi műveletek
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          {MENU_ITEMS_PRIMARY.map((item) => (
            <MenuCard key={item.key} item={item} onClick={() => navigate(item.route)} />
          ))}
        </div>
      </section>

      {/* Adminisztráció */}
      <section>
        <h2 className="text-sm font-semibold text-secondary-400 uppercase tracking-wider mb-3">
          Adminisztráció
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {MENU_ITEMS_ADMIN.map((item) => (
            <MenuCard key={`admin-${item.key}`} item={item} onClick={() => navigate(item.route)} />
          ))}
        </div>
      </section>
    </div>
  )
}

function MenuCard({ item, onClick }: { item: MenuItem; onClick: () => void }) {
  const Icon = item.icon
  return (
    <button
      onClick={onClick}
      className="flex items-start gap-3 p-4 bg-white border border-secondary-200 rounded-lg text-left
        hover:border-primary-300 hover:bg-primary-50 hover:shadow-sm
        focus:outline-none focus:ring-2 focus:ring-primary-500 focus:ring-offset-1
        transition-all duration-150 group"
    >
      <div className="w-10 h-10 bg-secondary-100 rounded-lg flex items-center justify-center shrink-0
        group-hover:bg-primary-100 transition-colors">
        <Icon size={20} className="text-secondary-600 group-hover:text-primary-600 transition-colors" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between">
          <span className="text-sm font-semibold text-secondary-900 group-hover:text-primary-700">
            {item.label}
          </span>
          <kbd className="text-[10px] font-mono px-1.5 py-0.5 bg-secondary-100 text-secondary-500 rounded border border-secondary-200">
            {item.shortcut}
          </kbd>
        </div>
        <p className="text-xs text-secondary-500 mt-0.5 truncate">{item.description}</p>
      </div>
    </button>
  )
}
