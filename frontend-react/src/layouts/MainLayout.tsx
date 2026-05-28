import { useState, useEffect, useCallback } from 'react'
import { useTranslation } from 'react-i18next'
import { Outlet, NavLink, useNavigate, Navigate } from 'react-router-dom'
import { useAuthStore } from '../stores/authStore'
import { dailySessionApi } from '../services/api/index'
import type { DailySession } from '../services/api/index'
import {
  LogOut,
  Menu,
  X,
  ChevronDown,
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

import { menuGroups, SZERVER_ROLES } from "./menuGroups"
import { useFeatureFlags } from "../hooks/useFeatureFlags"
import TransitBadge from "../components/TransitBadge"

export function shouldRequireDailySession(appMode: AppMode): boolean {
  return appMode === CASHIER_APP_MODE
}

export default function MainLayout() {
  const { t } = useTranslation()
  const featureFlags = useFeatureFlags()
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [sessionChecking, setSessionChecking] = useState(true)
  const [sessionReady, setSessionReady] = useState(false)
  const [sessionInfo, setSessionInfo] = useState<DailySession | null>(null)
  const [showSessionDialog, setShowSessionDialog] = useState(false)
  const [sessionError, setSessionError] = useState<string | null>(null)
  const { user, logout, hasRole, hasCanonicalRole } = useAuthStore()
  // Supervisory hozzaferes: ha a felhasznalonak van szerver-szintu canonicalRole-ja
  // (ugyvezeto, foertektar, belso_ellenor, stb.), minden lokal appMode-ban
  // lathatja a teljes menut, hogy ellenorizhesse a penztar/ertektar muveleteket.
  const hasSupervisoryAccess = SZERVER_ROLES.some((r) => hasCanonicalRole(r))
  const { mode: appMode, isLoading: appModeLoading } = useAppMode()
  const navigate = useNavigate()
  const isBrowserFallback = !isElectronRuntime() && appMode === 'full'

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
        } catch { /* session info nem kritikus */ }
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
                <h2 className="text-xl font-bold text-secondary-900">{t('layout.dayOpenFailedTitle')}</h2>
                <p className="text-sm text-secondary-500">
                  {new Date().toLocaleDateString('hu-HU', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' })}
                </p>
              </div>
            </div>
            <div className="mb-4 p-3 bg-danger-50 border border-danger-200 rounded-lg text-danger-700 text-sm">
              {sessionError === 'serverUnreachable' ? t('layout.serverUnreachable') : sessionError}
            </div>
            <p className="text-secondary-600 mb-6 text-sm">
              {t('layout.dayOpenFailedMessage')}
            </p>
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
          sidebarOpen ? 'w-64' : 'w-16'
        } bg-secondary-900 text-white transition-all duration-300 ease-in-out flex flex-col shadow-xl`}
      >
        {/* Logo/Header */}
        <div className="h-12 px-3 flex items-center justify-between border-b border-secondary-700">
          {sidebarOpen && (
            <div className="flex items-center gap-1.5">
              <Building2 size={18} className="text-accent-400" />
              <span className="font-bold text-sm">{t('layout.appName')}</span>
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
        <nav className="flex-1 py-2 overflow-y-auto">
          {menuGroups
            .filter((group) => !group.modes || group.modes.includes(appMode))
            .filter((group) => hasSupervisoryAccess || !group.canonicalRoles || group.canonicalRoles.some((r) => hasCanonicalRole(r)))
            .filter((group) => !group.featureFlagKey || featureFlags[group.featureFlagKey])
            .map((group) => (
            <div key={group.label} className="mb-3">
              {sidebarOpen && (
                <div className="px-4 mb-1 text-[10px] font-semibold text-secondary-400 uppercase tracking-wider">
                  {group.label}
                </div>
              )}
              {group.items
                .filter((item) => !item.modes || item.modes.includes(appMode))
                .filter((item) => hasSupervisoryAccess || !item.canonicalRoles || item.canonicalRoles.some((r) => hasCanonicalRole(r)))
                .filter((item) => !item.minRole || hasRole(item.minRole))
                .map((item) => (
                <NavLink
                  key={item.path}
                  to={item.path}
                  // v2.5.54 #11 fix: az `end` nélkül a NavLink prefix-matchel, így pl. a `/rates`
                  // ÉS a `/rates/history` egyszerre highlightolt. Minden menüpont valós leaf-route,
                  // ezért az exact-match (end) a helyes — egyszerre csak az aktuális oldal aktív.
                  end
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
        <div className="border-t border-secondary-700 p-2">
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
      <main className="flex-1 flex flex-col">
        {/* MODERN Header Bar */}
        <header className="h-10 bg-white border-b border-form-border flex items-center justify-between px-4 shadow-sm">
          <div className="flex items-center gap-3">
            <div className="text-xs">
              <span className="text-secondary-500">{t('layout.branchLabel')}</span>
              <span className="ml-1 font-semibold text-secondary-900">{user?.branchName || t('layout.centralFallback')}</span>
            </div>
            <div className="h-4 w-px bg-secondary-200"></div>
            <div className="text-xs text-secondary-600">
              {new Date().toLocaleDateString('hu-HU', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'short' })}
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
          
          <div className="flex items-center gap-4">
            {/* v2.1.4: Uton levo csomagok badge */}
            <TransitBadge />

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
                  <div className="text-[10px] text-secondary-500 font-mono">{t('layout.userIdPrefix', { code: user.workerCode })}</div>
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
                Elsődleges napi munkára a telepített pénztár, értéktár, RFM készítő és központi kliens használandó.
              </span>
            </div>
          </div>
        )}

        {/* Page content */}
        <div className="flex-1 p-3 overflow-auto min-h-0">
          <Outlet />
        </div>

        {/* MODERN Status bar */}
        <div className="status-bar">
          <div className="flex items-center gap-4">
            <span className="flex items-center gap-2">
              <span className="w-2 h-2 bg-success-500 rounded-full animate-pulse"></span>
              <span className="text-success-700 font-medium">{t('layout.online')}</span>
            </span>
            <span className="text-secondary-500">|</span>
            <span className="text-secondary-600">{t('layout.lastSync', { time: new Date().toLocaleTimeString('hu-HU') })}</span>
          </div>
          <span className="text-secondary-600 font-mono">{new Date().toLocaleTimeString('hu-HU')}</span>
        </div>
      </main>
    </div>
  )
}
