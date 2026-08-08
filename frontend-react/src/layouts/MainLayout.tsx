import { useState, useEffect, useCallback, useMemo } from 'react'
import { useTranslation } from 'react-i18next'
import { Outlet, NavLink, useNavigate, Navigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
import { authApi, dailySessionApi } from '../services/api/index'
import type { DailySession } from '../services/api/index'
import {
  LogOut,
  Menu,
  X,
  ChevronDown,
  ChevronRight,
  Bell,
  User,
  Building2,
  Sun,
  Loader2,
  ShieldAlert,
} from 'lucide-react'
import { useAppMode } from '../hooks/useAppMode'
import { CASHIER_APP_MODE } from '../types/appMode'
import type { AppMode } from '../types/appMode'
import { isElectron as isElectronRuntime } from '../utils/electron'
import { logger } from '../utils/logger'

import { menuGroups } from './menuGroups'
import { isMenuGroupVisible, isMenuItemVisible, type MenuVisibilityContext } from './menuVisibility'
import { useFeatureFlags } from '../hooks/useFeatureFlags'
import TransitBadge from '../components/TransitBadge'

export function shouldRequireDailySession(appMode: AppMode): boolean {
  return appMode === CASHIER_APP_MODE
}

export async function performBackendAwareLogout(
  remoteLogout: () => Promise<void>,
  localLogout: () => void,
  navigateToLogin: () => void,
  warn: (err: unknown) => void = () => undefined,
): Promise<void> {
  try {
    await remoteLogout()
  } catch (err) {
    warn(err)
  } finally {
    localLogout()
    navigateToLogin()
  }
}

export default function MainLayout() {
  const { t } = useTranslation()
  const featureFlags = useFeatureFlags()
  const [sidebarOpen, setSidebarOpen] = useState(() => {
    if (typeof window === 'undefined') return true
    return window.matchMedia('(min-width: 768px)').matches
  })
  const [sessionChecking, setSessionChecking] = useState(true)
  // FK-069 (FR-1, FR-4): csoportonként összecsukható navigáció. A Set a NYITOTT
  // csoportok label-jeit tartalmazza; kezdőérték az összes definiált csoport-label,
  // hogy az alapértelmezett viselkedés a mai (mind nyitva) állapottal egyezzen.
  // Munkamenet-szintű állapot — szándékosan NINCS perzisztálás (§2 OUT).
  // Minta: BranchGroupPage.tsx expandedIds/toggleExpand.
  const [openMenuGroups, setOpenMenuGroups] = useState<Set<string>>(
    () => new Set(menuGroups.map((g) => g.label)),
  )
  const toggleMenuGroup = (label: string) => {
    setOpenMenuGroups((prev) => {
      const next = new Set(prev)
      if (next.has(label)) next.delete(label)
      else next.add(label)
      return next
    })
  }
  const [sessionReady, setSessionReady] = useState(false)
  const [sessionInfo, setSessionInfo] = useState<DailySession | null>(null)
  const [showSessionDialog, setShowSessionDialog] = useState(false)
  const [sessionError, setSessionError] = useState<string | null>(null)
  const { user, logout, hasRole, hasCanonicalRole } = useAuthStore()

  // Codex #904: a NavLink `end` (exact-match) CSAK azokra a menüpontokra kell, amelyek egy másik
  // menüpont szegmens-prefixei (pl. `/rates` ⊂ `/rates/history`) — különben együtt highlightolnának.
  // A többi menüpontnál NINCS `end`, így a szülő-route a detail-aloldalakon (pl. `/customers/:id`,
  // amelyhez nincs külön menüpont) továbbra is kiemelve marad.
  const parentPrefixPaths = useMemo(() => {
    const allPaths = menuGroups.flatMap((g) => g.items.map((it) => it.path))
    const prefixes = new Set<string>()
    for (const p of allPaths) {
      if (allPaths.some((other) => other !== p && other.startsWith(p + '/'))) prefixes.add(p)
    }
    return prefixes
  }, [])
  const { mode: appMode, isLoading: appModeLoading } = useAppMode()
  const navigate = useNavigate()
  const isBrowserFallback = !isElectronRuntime() && appMode === 'full'

  // RBAC-audit (2026-06-05): a menü-láthatóság tiszta logikája a menuVisibility modulban
  // (least-privilege full módban, lokál oversight-bypass, öröklés, csoport-ha-van-látható-item).
  const menuVisibilityCtx: MenuVisibilityContext = {
    appMode,
    hasCanonicalRole,
    hasRole,
    featureFlags,
  }

  // FKH-026 v3 (TBD-3): a fejléc-jelző az "Úton lévő csomagok" menüpont
  // láthatóságához kötött — ugyanaz a forrás (isMenuGroupVisible/isMenuItemVisible),
  // mint a sidebar szűrése, nem párhuzamos feltétel. Rejtett menüpont
  // (pénztáros/értéktáros) → nincs badge; felügyeleti bypass (Főértéktáros/
  // helyettes) → a menüpont és a badge is látszik.
  const transitBadgeVisible = menuGroups.some(
    (group) =>
      isMenuGroupVisible(group, menuVisibilityCtx) &&
      group.items.some(
        (item) => item.path === '/transit' && isMenuItemVisible(item, group, menuVisibilityCtx),
      ),
  )

  const markSessionReadyWithoutDailyGate = useCallback(() => {
    setSessionInfo(null)
    setSessionError(null)
    setShowSessionDialog(false)
    setSessionReady(true)
    setSessionChecking(false)
  }, [])

  const initSession = useCallback(async () => {
    if (!shouldRequireDailySession(appMode)) {
      markSessionReadyWithoutDailyGate()
      return
    }

    try {
      setSessionChecking(true)
      setSessionError(null)

      // 1. Ellenőrizzük van-e nyitott session
      const isOpen = await dailySessionApi.isOpen()

      if (isOpen) {
        // Már nyitott — lekérjük az infót és folytatjuk
        try {
          const current = await dailySessionApi.getCurrent()
          setSessionInfo(current)
        } catch {
          /* session info nem kritikus */
        }
        setSessionReady(true)
        return
      }

      // 2. Nincs nyitott session → redirect napnyitás képernyőre
      setSessionError('redirect-day-open')
      setShowSessionDialog(true)
    } catch {
      // Backend nem elérhető — uzenetkulcsot tarunk a state-ben, t() rendereleskor.
      setSessionError('serverUnreachable')
      setShowSessionDialog(true)
    } finally {
      setSessionChecking(false)
    }
  }, [appMode, markSessionReadyWithoutDailyGate])

  useEffect(() => {
    if (appModeLoading) {
      return
    }

    initSession()
  }, [appModeLoading, initSession])

  const handleRetryOpen = async () => {
    try {
      setShowSessionDialog(false)
      setSessionChecking(true)
      await initSession()
    } catch {
      setSessionError('serverUnreachable')
      setShowSessionDialog(true)
    }
  }

  const handleLogout = () => {
    void performBackendAwareLogout(
      () => authApi.logout(),
      logout,
      () => navigate('/login'),
      (err) =>
        logger.warn(
          'MainLayout',
          'Backend logout sikertelen, lokális kijelentkeztetés folytatódik',
          err,
        ),
    )
  }

  const closeMobileSidebar = () => {
    if (typeof window !== 'undefined' && window.matchMedia('(max-width: 767px)').matches) {
      setSidebarOpen(false)
    }
  }

  return (
    <div className="app-layout-root h-screen overflow-hidden bg-form-bg flex flex-col md:flex-row">
      {/* Napnyitás hiba dialógus — csak ha az automatikus nyitás nem sikerült */}
      {showSessionDialog && !sessionReady && sessionError === 'redirect-day-open' && (
        <Navigate to="/cashdesk/day-open" replace />
      )}

      {showSessionDialog &&
        !sessionReady &&
        sessionError &&
        sessionError !== 'redirect-day-open' && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
            <div className="bg-white rounded-2xl shadow-2xl p-8 max-w-md w-full mx-4">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-12 h-12 bg-danger-100 rounded-xl flex items-center justify-center">
                  <Sun size={28} className="text-danger-600" />
                </div>
                <div>
                  <h2 className="text-xl font-bold text-secondary-900">
                    {t('layout.dayOpenFailedTitle')}
                  </h2>
                  <p className="text-sm text-secondary-500">
                    {new Date().toLocaleDateString('hu-HU', {
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                      weekday: 'long',
                    })}
                  </p>
                </div>
              </div>
              <div className="mb-4 p-3 bg-danger-50 border border-danger-200 rounded-lg text-danger-700 text-sm">
                {sessionError === 'serverUnreachable'
                  ? t('layout.serverUnreachable')
                  : sessionError}
              </div>
              <p className="text-secondary-600 mb-6 text-sm">{t('layout.dayOpenFailedMessage')}</p>
              <div className="flex gap-3">
                <button
                  onClick={handleLogout}
                  className="flex-1 px-4 py-3 border border-secondary-300 text-secondary-700 rounded-lg hover:bg-secondary-50 transition-colors font-medium"
                >
                  {t('layout.logoutButton')}
                </button>
                <button
                  onClick={handleRetryOpen}
                  className="flex-1 px-4 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium flex items-center justify-center gap-2"
                >
                  <Sun size={18} />
                  {t('layout.retryOpen')}
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
            <p className="text-secondary-600 font-medium">{t('layout.checkingSession')}</p>
          </div>
        </div>
      )}
      {/* MODERN Sidebar */}
      <aside
        className={`${
          sidebarOpen
            ? 'w-full md:w-64'
            : 'h-12 w-full overflow-hidden md:h-auto md:w-16 md:overflow-visible'
        } min-h-0 max-h-full bg-secondary-900 text-white transition-all duration-300 ease-in-out flex flex-col shadow-xl`}
      >
        {/* Logo/Header */}
        <div className="h-12 px-3 flex items-center justify-between border-b border-secondary-700">
          <div className={`${sidebarOpen ? 'flex' : 'flex md:hidden'} items-center gap-1.5`}>
            <Building2 size={18} className="text-accent-400" />
            <div className="flex flex-col leading-tight">
              <span className="font-bold text-sm">{t('layout.appName')}</span>
              {/* FR-FM-01 (b5-fomenu hibalista): verziószám a fejlécen. */}
              <span className="text-[10px] text-secondary-300 font-mono">
                v{import.meta.env.VITE_APP_VERSION ?? __APP_VERSION__}
              </span>
            </div>
          </div>
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="p-2 hover:bg-secondary-700 rounded-lg transition-colors"
          >
            {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>

        {/* Navigation Groups */}
        <nav
          className={`${sidebarOpen ? 'block' : 'hidden md:block'} flex-1 min-h-0 py-2 overflow-y-auto`}
        >
          {menuGroups
            .filter((group) => isMenuGroupVisible(group, menuVisibilityCtx))
            .map((group) => (
              <div key={group.label} className="mb-3">
                {sidebarOpen && (
                  // FK-069 FR-1/FR-3: kattintható csoport-fejléc chevronnal.
                  <button
                    type="button"
                    onClick={() => toggleMenuGroup(group.label)}
                    aria-expanded={openMenuGroups.has(group.label)}
                    data-testid={`menu-group-toggle-${group.label}`}
                    className="w-full flex items-center gap-1 px-4 mb-1 text-[10px] font-semibold text-secondary-400 uppercase tracking-wider hover:text-secondary-200 transition-colors"
                  >
                    <ChevronRight
                      size={12}
                      className={`shrink-0 transition-transform ${
                        openMenuGroups.has(group.label) ? 'rotate-90' : ''
                      }`}
                    />
                    <span className="truncate">{group.label}</span>
                  </button>
                )}
                {/* FK-069 FR-2: csukott állapotban az itemek nem renderelődnek.
                    Összecsukott sidebaron (ikonsáv) az itemek mindig látszanak,
                    mert ott nincs kattintható fejléc. */}
                {(!sidebarOpen || openMenuGroups.has(group.label)) &&
                  group.items
                    .filter((item) => isMenuItemVisible(item, group, menuVisibilityCtx))
                    .map((item) => (
                      <NavLink
                        key={item.path}
                        to={item.path}
                        // v2.5.54 #11 + Codex #904: `end` CSAK a prefix-szülő útvonalakra (pl. /rates),
                        // hogy ne ütközzön a /rates/history-val; a sima menüpontok szülő-highlightja megmarad.
                        end={parentPrefixPaths.has(item.path)}
                        onClick={closeMobileSidebar}
                        className={({ isActive }) =>
                          `flex items-center gap-2 px-4 py-1.5 text-xs font-medium transition-all duration-200 ${
                            isActive
                              ? 'bg-primary-600 text-white border-l-4 border-accent-400'
                              : 'text-secondary-300 hover:bg-secondary-800 hover:text-white'
                          }`
                        }
                      >
                        <item.icon size={16} className="shrink-0" />
                        {sidebarOpen && <span className="truncate">{item.label}</span>}
                      </NavLink>
                    ))}
              </div>
            ))}
        </nav>

        {/* User info & Logout */}
        <div
          className={`${sidebarOpen ? 'block' : 'hidden md:block'} border-t border-secondary-700 p-2`}
        >
          {sidebarOpen && user && (
            <div className="mb-2 px-2 py-1.5 bg-secondary-800 rounded-lg">
              <div className="flex items-center gap-1.5">
                <User size={14} className="text-secondary-400" />
                <div className="text-xs font-semibold truncate">{user.fullName}</div>
              </div>
              <div className="text-[10px] text-secondary-400 truncate pl-5">{user.branchName}</div>
            </div>
          )}
          <button
            onClick={handleLogout}
            className={`w-full flex items-center ${sidebarOpen ? 'justify-start' : 'justify-center'} gap-1.5 px-3 py-1.5 text-xs font-medium text-danger-300 hover:bg-danger-900/20 rounded-lg transition-colors`}
          >
            <LogOut size={14} />
            {sidebarOpen && <span>{t('layout.logoutButton')}</span>}
          </button>
        </div>
      </aside>

      {/* Main content */}
      {/* FK-033: min-w-0 — a flex-item alapértelmezett min-width:auto miatt a main a széles tartalom
          (pl. Átlag árfolyam riport táblázata) szélességére tágulna, és a body görgetne vízszintesen
          a .app-print-content helyett → a sticky VALUTA oszlop elcsúszna. A min-w-0 engedi a main
          zsugorodását, így a .app-print-content (overflow-auto) lesz az EGYETLEN vízszintes scroll. */}
      <main className="flex-1 flex flex-col min-w-0" style={{ minHeight: 0 }}>
        {/* MODERN Header Bar */}
        <header className="no-print min-h-10 bg-white border-b border-form-border flex flex-col gap-2 px-4 py-2 shadow-sm md:flex-row md:items-center md:justify-between md:py-0">
          <div className="flex min-w-0 flex-wrap items-center gap-3">
            <div className="text-xs">
              <span className="text-secondary-500">{t('layout.branchLabel')}</span>
              <span className="ml-1 font-semibold text-secondary-900">
                {user?.branchName || t('layout.centralFallback')}
              </span>
            </div>
            <div className="h-4 w-px bg-secondary-200"></div>
            <div className="text-xs text-secondary-600">
              {new Date().toLocaleDateString('hu-HU', {
                year: 'numeric',
                month: 'long',
                day: 'numeric',
                weekday: 'short',
              })}
            </div>
            {sessionInfo && (
              <>
                <div className="h-6 w-px bg-secondary-200"></div>
                <div className="flex items-center gap-1.5 text-sm">
                  <span className="w-2 h-2 bg-success-500 rounded-full"></span>
                  <span className="text-success-700 font-medium">{t('layout.dayOpenStatus')}</span>
                </div>
              </>
            )}
          </div>

          <div className="flex min-w-0 flex-wrap items-center gap-4">
            {/* v2.1.4: Uton levo csomagok badge — FKH-026 v3: menüpont-láthatósághoz kötve */}
            {transitBadgeVisible && <TransitBadge />}

            {/* Notification Bell */}
            <button className="relative p-1.5 hover:bg-secondary-50 rounded-lg transition-colors">
              <Bell size={16} className="text-secondary-600" />
              <span className="absolute top-0.5 right-0.5 w-1.5 h-1.5 bg-danger-500 rounded-full"></span>
            </button>

            {/* User Menu */}
            <div className="flex items-center gap-2 px-2 py-1 hover:bg-secondary-50 rounded-lg cursor-pointer transition-colors">
              <div className="w-6 h-6 bg-primary-600 rounded-full flex items-center justify-center text-white font-semibold text-xs">
                {user?.fullName?.charAt(0) || 'U'}
              </div>
              <div className="text-xs hidden sm:block leading-tight">
                <div className="font-semibold text-secondary-900">{user?.fullName}</div>
                {user?.workerCode && (
                  <div className="text-[10px] text-secondary-500 font-mono">
                    {t('layout.userIdPrefix', { code: user.workerCode })}
                  </div>
                )}
              </div>
              <ChevronDown size={14} className="text-secondary-400" />
            </div>
          </div>
        </header>

        {isBrowserFallback && (
          <div className="border-b border-amber-200 bg-amber-50 px-4 py-2 text-xs text-amber-900">
            <div className="flex flex-wrap items-center gap-2">
              <ShieldAlert size={14} className="shrink-0 text-amber-700" />
              <span className="font-semibold">Tartalék webes szerverfelület</span>
              <span className="text-amber-800">
                Elsődleges napi munkára a telepített pénztár, értéktár, RFM készítő és központi
                kliens használandó.
              </span>
            </div>
          </div>
        )}

        {/* Page content */}
        {/* FK-033: min-w-0 a min-h-0 mellé — egyetlen, kanonikus görgető kontextus mindkét tengelyen
            (overflow-auto): a táblázatos riportok (sticky VALUTA + fejléc) megbízhatóan ehhez kötnek. */}
        <div className="app-print-content flex-1 p-3 overflow-auto min-h-0 min-w-0">
          <Outlet />
        </div>

        {/* MODERN Status bar */}
        <div className="status-bar flex-wrap gap-2">
          <div className="flex flex-wrap items-center gap-4">
            <span className="flex items-center gap-2">
              <span className="w-2 h-2 bg-success-500 rounded-full animate-pulse"></span>
              <span className="text-success-700 font-medium">{t('layout.online')}</span>
            </span>
            <span className="text-secondary-500">|</span>
            <span className="text-secondary-600">
              {t('layout.lastSync', { time: new Date().toLocaleTimeString('hu-HU') })}
            </span>
          </div>
          <span className="text-secondary-600 font-mono">
            {new Date().toLocaleTimeString('hu-HU')}
          </span>
        </div>
      </main>
    </div>
  )
}
