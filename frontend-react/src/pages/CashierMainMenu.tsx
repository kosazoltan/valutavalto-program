import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useHotkeys } from 'react-hotkeys-hook'
import type { LucideIcon } from 'lucide-react'
import {
  Banknote, Coins, Repeat, ArrowRight, XCircle,
  TrendingUp, Wallet, BarChart3, Lock, FileText,
  Building2, List, Users, Calendar, Archive,
  RefreshCw, Settings, ChevronLeft, ChevronRight,
} from 'lucide-react'
import { CashierHeader } from '../components/cashier/CashierHeader'
import { useCompanyTheme } from '../contexts/CompanyThemeContext'

/**
 * Penztaros fomenu — 2 oldalas, legacy-hu.
 *
 * Legacy: Unit47.pas — 9+9 menupont, animalt lapozas
 * 1.oldal: VETEL | ELADAS | KONVERZIO | ATADAS | --- | STORNO | ARFOLYAM | KESZLET | FORGALOM
 * 2.oldal: ZARAS | BIZONYLATOK | TARSPENZTARAK | LISTAK | PENZTAROSOK | NAPI FORGALOM | REGI ZARAS | REGENERALAS | EGYEB
 *
 * Szam billentyuvel kivalaszthato (1-9), nyilakkal lapozhato.
 */

interface MenuItem {
  key: string
  label: string
  icon: LucideIcon | null
  color: string
  route: string
}

const PAGE1: MenuItem[] = [
  { key: '1', label: 'VETEL', icon: Banknote, color: 'from-emerald-500 to-emerald-600', route: '/transactions/cashier?mode=buy' },
  { key: '2', label: 'ELADAS', icon: Coins, color: 'from-blue-500 to-blue-600', route: '/transactions/cashier?mode=sell' },
  { key: '3', label: 'KONVERZIÓ', icon: Repeat, color: 'from-purple-500 to-purple-600', route: '/transactions/conversion' },
  { key: '4', label: 'ÁTADÁS', icon: ArrowRight, color: 'from-orange-500 to-orange-600', route: '/transfers' },
  { key: '5', label: '', icon: null, color: '', route: '' },
  { key: '6', label: 'STORNÓ', icon: XCircle, color: 'from-red-500 to-red-600', route: '/transactions' },
  { key: '7', label: 'ÁRFOLYAM', icon: TrendingUp, color: 'from-cyan-500 to-cyan-600', route: '/rates' },
  { key: '8', label: 'KÉSZLET', icon: Wallet, color: 'from-teal-500 to-teal-600', route: '/cashdesk' },
  { key: '9', label: 'FORGALOM', icon: BarChart3, color: 'from-indigo-500 to-indigo-600', route: '/reports' },
]

const PAGE2: MenuItem[] = [
  { key: '1', label: 'NAPI ZÁRÁS', icon: Lock, color: 'from-red-500 to-red-600', route: '/closing/wizard' },
  { key: '2', label: 'BIZONYLATOK', icon: FileText, color: 'from-blue-500 to-blue-600', route: '/receipts' },
  { key: '3', label: 'TÁRSPÉNZTÁRAK', icon: Building2, color: 'from-purple-500 to-purple-600', route: '/branch-groups' },
  { key: '4', label: 'LISTÁK', icon: List, color: 'from-gray-500 to-gray-600', route: '/transactions' },
  { key: '5', label: 'PÉNZTÁROSOK', icon: Users, color: 'from-emerald-500 to-emerald-600', route: '/settings/users' },
  { key: '6', label: 'NAPI FORGALOM', icon: Calendar, color: 'from-orange-500 to-orange-600', route: '/reports/extended' },
  { key: '7', label: 'RÉGI ZÁRÁS', icon: Archive, color: 'from-amber-500 to-amber-600', route: '/archiving' },
  { key: '8', label: 'REGENERÁLÁS', icon: RefreshCw, color: 'from-cyan-500 to-cyan-600', route: '/cashdesk/denominations' },
  { key: '9', label: 'EGYEB', icon: Settings, color: 'from-gray-500 to-gray-600', route: '/settings' },
]

export default function CashierMainMenu() {
  const navigate = useNavigate()
  const { theme: _theme } = useCompanyTheme()
  const [page, setPage] = useState(1)
  const items = page === 1 ? PAGE1 : PAGE2

  // Nyilak: lapozo
  useHotkeys('arrowleft', () => setPage(1))
  useHotkeys('arrowright', () => setPage(2))

  // Szam billentyuk: menupont kivalasztasa
  useHotkeys('1,2,3,4,5,6,7,8,9', (e) => {
    const idx = parseInt(e.key) - 1
    const item = items[idx]
    if (item && item.route) navigate(item.route)
  }, [items])

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-950">
      <CashierHeader />

      <div className="p-8">
        <header className="text-center mb-10">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-2">FOMENU</h1>
          <p className="text-lg text-gray-500 dark:text-gray-400">
            {page === 1 ? '1. oldal — Napi muveletek' : '2. oldal — Adminisztracio'}
          </p>
        </header>

        {/* 3x3 GRID */}
        <div className="grid grid-cols-3 gap-6 max-w-4xl mx-auto">
          {items.map((item) => {
            if (!item.icon) {
              return <div key={item.key} className="aspect-square rounded-2xl bg-gray-200 dark:bg-gray-800 opacity-30" />
            }
            const Icon = item.icon
            return (
              <button
                key={item.key}
                onClick={() => navigate(item.route)}
                className={`group relative aspect-square rounded-2xl bg-gradient-to-br ${item.color} shadow-lg transition-all duration-200 hover:scale-105 hover:shadow-2xl focus:outline-none focus:ring-4 focus:ring-white/40`}
              >
                <div className="absolute inset-0 flex flex-col items-center justify-center text-white p-4">
                  <Icon className="w-14 h-14 mb-3 group-hover:scale-110 transition-transform" />
                  <span className="text-lg font-bold text-center">{item.label}</span>
                  <kbd className="absolute top-3 right-3 px-2.5 py-1 bg-black/30 rounded-lg text-xs font-mono">
                    {item.key}
                  </kbd>
                </div>
              </button>
            )
          })}
        </div>

        {/* LAPOZO */}
        <div className="flex items-center justify-center gap-6 mt-10">
          <button
            onClick={() => setPage(1)}
            disabled={page === 1}
            className="flex items-center gap-2 px-5 py-2.5 rounded-lg border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-30 transition-colors"
          >
            <ChevronLeft className="w-5 h-5" />
            Előző
          </button>

          <div className="flex gap-2">
            <div className={`w-3 h-3 rounded-full transition-colors ${page === 1 ? 'bg-[var(--primary)]' : 'bg-gray-300 dark:bg-gray-700'}`} />
            <div className={`w-3 h-3 rounded-full transition-colors ${page === 2 ? 'bg-[var(--primary)]' : 'bg-gray-300 dark:bg-gray-700'}`} />
          </div>

          <button
            onClick={() => setPage(2)}
            disabled={page === 2}
            className="flex items-center gap-2 px-5 py-2.5 rounded-lg border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 disabled:opacity-30 transition-colors"
          >
            Kovetkezo
            <ChevronRight className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  )
}
