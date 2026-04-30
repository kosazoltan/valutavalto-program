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
import { useState, useCallback, useMemo } from 'react'
import { useAuthStore } from '../../stores/authStore'
import { useAppMode } from '../../hooks/useAppMode'

/**
 * 2026-04-29 FIX: a /treasury layout korábban hardkódolt 10 tabbal jelent meg
 * minden szerepkörnek, beleértve az "Árfolyamkészítés F5", "Banki Tx F4",
 * "ÁFA visszatérítés F7", "TRB Export F8", "Bankforgalom F10" tabokat,
 * amelyek a legacy ANTI rendszerben **kizárólag a központi főértéktár /
 * ügyvezető szerepkör hatáskörébe** tartoznak (l. ARFOLYAM/Arfolyam.exe
 * önálló app és docs/knowledge/legacy-reverse-engineering/legacy-dll-parity-matrix.md).
 *
 * A helyi értéktáros (mode='ertektar') NEM készít árfolyamot — csak megkapja a
 * központtól. Ezért ezeket a tabokat csak `foertektar` vagy `ugyvezeto`
 * canonical role esetén jelenítjük meg.
 *
 * Ld. D:\valutavalto-vault\references\legacy-anti-system.md §2-§4.
 */
// 2026-04-29 v2.3.10 (Sourcery PR #271 fix):
// `TreasuryTab`, `CENTRAL_VAULT_ROLES`, `allTreasuryTabs` exportálva, hogy a
// `TreasuryLayout.role-filter.test.ts` ezeket TÉNYLEGES forrásból importálhatja
// (NEM duplikálni). Ld. Sourcery comment #271.
export type TreasuryTab = {
  path: string
  label: string
  icon: typeof LayoutDashboard
  hotkey: string
  end: boolean
  /** Ha megadva, csak akkor látszik, ha a usernek van ezek közül egy canonical role-ja. */
  canonicalRoles?: readonly string[]
}

export const CENTRAL_VAULT_ROLES = ['foertektar', 'ugyvezeto'] as const

export const allTreasuryTabs: readonly TreasuryTab[] = [
  { path: '/treasury', label: 'Dashboard', icon: LayoutDashboard, hotkey: 'F1', end: true },
  { path: '/treasury/matrix', label: 'Készlet Mátrix', icon: Grid3X3, hotkey: 'F2', end: false },
  { path: '/treasury/movements', label: 'Mozgások', icon: ArrowLeftRight, hotkey: 'F3', end: false },
  { path: '/treasury/bank', label: 'Banki Tx', icon: Building2, hotkey: 'F4', end: false, canonicalRoles: CENTRAL_VAULT_ROLES },
  { path: '/treasury/rates', label: 'Árfolyamkészítés', icon: TrendingUp, hotkey: 'F5', end: false, canonicalRoles: CENTRAL_VAULT_ROLES },
  { path: '/treasury/reports', label: 'Jelentések', icon: FileText, hotkey: 'F6', end: false },
  { path: '/treasury/vat', label: 'ÁFA visszatérítés', icon: Receipt, hotkey: 'F7', end: false, canonicalRoles: CENTRAL_VAULT_ROLES },
  { path: '/treasury/trb-export', label: 'TRB Export', icon: Download, hotkey: 'F8', end: false, canonicalRoles: CENTRAL_VAULT_ROLES },
  { path: '/treasury/customer-turnover', label: 'Ügyfélforgalom', icon: Users, hotkey: 'F9', end: false },
  { path: '/treasury/bank-turnover', label: 'Bankforgalom', icon: Landmark, hotkey: 'F10', end: false, canonicalRoles: CENTRAL_VAULT_ROLES },
]

export default function TreasuryLayout() {
  const navigate = useNavigate()
  const [showHelp, setShowHelp] = useState(false)
  // A `roles` és `activeRole` selector-okkal a useMemo helyesen invalidálódik,
  // ha role-selection vagy login után változnak.
  const roles = useAuthStore((state) => state.roles)
  const activeRole = useAuthStore((state) => state.activeRole)
  const workerRole = useAuthStore((state) => state.worker?.role)
  const hasCanonicalRole = useAuthStore((state) => state.hasCanonicalRole)
  // v2.4.9: értéktár (lokál) módban a foértéktári funkciók (F4/F5/F7/F8/F10) NEM
  // jelenhetnek meg, akkor sem ha a user role-ja megengedné. Ott az értéktár csak
  // megnézi az árfolyamokat, nem készíti — az a foértéktár kompetencia.
  const { mode: appMode } = useAppMode()

  // 2026-04-29 v2.3.10 (Sourcery PR #271): hasCanonicalRole-t hozzáadva a deps-be,
  // valamint a `roles`/`activeRole`/`workerRole` selector-ok is — login/role-change
  // után ezek ÚJ értéket kapnak, az useMemo helyesen invalidálódik. ESLint warning-ot
  // szuppresszáljuk: a hasCanonicalRole selector stable closure, de a többi explicit
  // role-trigger fontos a refresh helyességéhez (felesleges deps figyelmeztetést ad,
  // de itt szándékos belt+suspenders pattern).
  const treasuryTabs = useMemo(
    () => allTreasuryTabs.filter((tab) => {
      // Role check
      if (tab.canonicalRoles && !hasCanonicalRole([...tab.canonicalRoles])) return false
      // v2.4.9: foértéktári funkciók (CENTRAL_VAULT_ROLES) ertektar módban rejtve
      if (tab.canonicalRoles === CENTRAL_VAULT_ROLES && appMode === 'ertektar') return false
      return true
    }),
    // eslint-disable-next-line react-hooks/exhaustive-deps -- belt+suspenders: roles/activeRole/workerRole szándékos extra trigger
    [roles, activeRole, workerRole, hasCanonicalRole, appMode],
  )

  const isVisiblePath = useCallback(
    (path: string) => treasuryTabs.some((tab) => tab.path === path),
    [treasuryTabs],
  )

  const closeHelp = useCallback(() => setShowHelp(false), [])
  const toggleHelp = useCallback(() => setShowHelp(prev => !prev), [])

  // F-key navigation — csak a látható tabokra navigálunk, DE a preventDefault
  // mindig fut (Codex PR #271 P2): F5 default browser refresh-t kell elnyomni
  // akkor is, ha a /treasury/rates tab nem látható (nem-foertektar usereknek).
  const fkeyHandler = useCallback(
    (path: string) => (e: KeyboardEvent) => {
      e.preventDefault()
      if (isVisiblePath(path)) navigate(path)
    },
    [isVisiblePath, navigate],
  )

  useHotkeys('f1', fkeyHandler('/treasury'), { enableOnFormTags: false })
  useHotkeys('f2', fkeyHandler('/treasury/matrix'), { enableOnFormTags: false })
  useHotkeys('f3', fkeyHandler('/treasury/movements'), { enableOnFormTags: false })
  useHotkeys('f4', fkeyHandler('/treasury/bank'), { enableOnFormTags: false })
  useHotkeys('f5', fkeyHandler('/treasury/rates'), { enableOnFormTags: false })
  useHotkeys('f6', fkeyHandler('/treasury/reports'), { enableOnFormTags: false })
  useHotkeys('f7', fkeyHandler('/treasury/vat'), { enableOnFormTags: false })
  useHotkeys('f8', fkeyHandler('/treasury/trb-export'), { enableOnFormTags: false })
  useHotkeys('f9', fkeyHandler('/treasury/customer-turnover'), { enableOnFormTags: false })
  useHotkeys('f10', fkeyHandler('/treasury/bank-turnover'), { enableOnFormTags: false })
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
            className="bg-white rounded-lg shadow-xl p-4 max-w-md w-full mx-4"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-lg font-bold text-secondary-900 mb-4 flex items-center gap-2">
              <Keyboard size={20} className="text-primary-600" />
              Billentyűparancsok
            </h2>
            <div className="space-y-3">
              <div className="text-sm font-semibold text-secondary-600 uppercase tracking-wider">Navigáció</div>
              {treasuryTabs.map((tab) => (
                <HotkeyRow key={tab.path} keys={tab.hotkey} desc={tab.label} />
              ))}
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
