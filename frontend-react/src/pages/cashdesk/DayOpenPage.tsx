import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Sun, AlertTriangle, Loader2, CheckCircle } from 'lucide-react'
import { CashierHeader } from '../../components/cashier/CashierHeader'
import { toast } from '../../components/ui/toaster'
import { dailySessionApi, cashBalanceApi } from '../../services/api/index'
import type { CashBalance } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { clearPersistedToken } from '../../services/api/index'
import { logger } from '../../utils/logger'

/**
 * Napnyitás képernyő — pénztáros megerősíti a nyitó egyenleget, utána indul a nap.
 *
 * Legacy: NAPNYIT.DLL
 * Flow: készlet lekérés → egyenleg megjelenítés → megerősítés → dailySession.open() → redirect
 */

export default function DayOpenPage() {
  const navigate = useNavigate()
  const worker = useAuthStore((s) => s.worker)
  const logout = useAuthStore((s) => s.logout)

  const [loading, setLoading] = useState(true)
  const [balances, setBalances] = useState<CashBalance[]>([])
  const [balanceError, setBalanceError] = useState<string | null>(null)
  const [opening, setOpening] = useState(false)
  const [alreadyOpen, setAlreadyOpen] = useState(false)

  // Ellenőrizzük, hogy van-e már nyitott nap
  const checkAndLoad = useCallback(async () => {
    setLoading(true)
    setBalanceError(null)
    try {
      const isOpen = await dailySessionApi.isOpen()
      if (isOpen) {
        setAlreadyOpen(true)
        setLoading(false)
        return
      }

      // Készlet lekérés
      try {
        const bal = await cashBalanceApi.list()
        setBalances(bal)
      } catch (err) {
        logger.warn('DayOpenPage', 'Keszlet lekerdezes sikertelen:', err)
        setBalanceError('A készlet nem kérdezhető le. A napot nyitó egyenleg nélkül is megnyithatod.')
      }
    } catch (err) {
      logger.error('DayOpenPage', 'Session ellenorzes hiba:', err)
      setBalanceError('A szerver nem elérhető.')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    checkAndLoad()
  }, [checkAndLoad])

  const handleOpenDay = async () => {
    if (!worker) {
      toast.error('Hiba', 'Nincs bejelentkezett felhasználó!')
      return
    }

    setOpening(true)
    try {
      await dailySessionApi.open()
      toast.success('Nap megnyitva', `${new Date().toLocaleDateString('hu-HU')} — ${worker.fullName}`)
      navigate('/cashier')
    } catch (err: unknown) {
      const axErr = err as { response?: { data?: { message?: string } }; message?: string }
      const msg = axErr?.response?.data?.message || axErr?.message || 'Ismeretlen hiba'

      // Ha már nyitott → továbbengedjük
      if (msg.includes('már') && (msg.includes('nyitott') || msg.includes('létezik'))) {
        toast.success('Nap már nyitva', 'Továbbhaladás...')
        navigate('/cashier')
        return
      }

      toast.error('Napnyitás sikertelen', msg)
    } finally {
      setOpening(false)
    }
  }

  const hufBalance = balances.find((b) => b.currencyCode === 'HUF')
  const foreignBalances = balances.filter((b) => b.currencyCode !== 'HUF')

  if (loading) {
    return (
      <div className="flex h-screen flex-col">
        <CashierHeader />
        <div className="flex flex-1 items-center justify-center">
          <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
          <span className="ml-3 text-lg text-gray-600">Betöltés...</span>
        </div>
      </div>
    )
  }

  if (alreadyOpen) {
    return (
      <div className="flex h-screen flex-col">
        <CashierHeader />
        <div className="flex flex-1 flex-col items-center justify-center gap-4">
          <CheckCircle className="h-12 w-12 text-green-500" />
          <h2 className="text-xl font-bold text-gray-800">A nap mar nyitva van</h2>
          <button
            onClick={() => navigate('/cashier')}
            className="rounded-lg bg-blue-600 px-6 py-3 text-white hover:bg-blue-700"
          >
            Tovabb a penztarhoz
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="flex h-screen flex-col">
      <CashierHeader />
      <div className="flex flex-1 flex-col items-center justify-center p-6">
        <div className="w-full max-w-lg space-y-6">
          {/* Header */}
          <div className="text-center">
            <Sun className="mx-auto h-12 w-12 text-amber-500" />
            <h1 className="mt-3 text-2xl font-bold text-gray-900">Napnyitas</h1>
            <p className="mt-1 text-sm text-gray-500">
              {new Date().toLocaleDateString('hu-HU', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
              {' — '}
              {worker?.fullName ?? 'Ismeretlen pentaros'}
            </p>
          </div>

          {/* Balance error */}
          {balanceError && (
            <div className="flex items-start gap-3 rounded-lg border border-amber-200 bg-amber-50 p-4">
              <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-amber-600" />
              <p className="text-sm text-amber-800">{balanceError}</p>
            </div>
          )}

          {/* Opening balance display */}
          {balances.length > 0 && (
            <div className="rounded-lg border border-gray-200 bg-white p-4 shadow-sm">
              <h3 className="mb-3 text-sm font-semibold uppercase tracking-wider text-gray-500">
                Nyito egyenleg
              </h3>

              {/* HUF balance — highlighted */}
              {hufBalance && (
                <div className="mb-3 flex items-center justify-between rounded-md bg-blue-50 p-3">
                  <span className="text-lg font-bold text-blue-900">HUF</span>
                  <span className="text-lg font-bold text-blue-900">
                    {hufBalance.currentBalance.toLocaleString('hu-HU')} Ft
                  </span>
                </div>
              )}

              {/* Foreign currency balances */}
              {foreignBalances.length > 0 && (
                <div className="space-y-1">
                  {foreignBalances.map((b) => (
                    <div key={b.id} className="flex items-center justify-between px-3 py-1.5 text-sm">
                      <span className="font-medium text-gray-700">{b.currencyCode}</span>
                      <span className="text-gray-900">
                        {b.currentBalance.toLocaleString('hu-HU', { minimumFractionDigits: 2 })}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Open day button */}
          <button
            onClick={handleOpenDay}
            disabled={opening}
            className="w-full rounded-lg bg-green-600 py-4 text-lg font-bold text-white transition-colors hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            {opening ? (
              <span className="flex items-center justify-center gap-2">
                <Loader2 className="h-5 w-5 animate-spin" />
                Megnyitas...
              </span>
            ) : (
              'Nap megnyitasa'
            )}
          </button>

          {/* Back */}
          <button
            onClick={async () => {
              logout()
              await clearPersistedToken()
              navigate('/login', { replace: true })
            }}
            className="w-full text-center text-sm text-gray-500 hover:text-gray-700"
          >
            Kijelentkezes
          </button>
        </div>
      </div>
    </div>
  )
}
