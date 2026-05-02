import { useState, useEffect, useCallback, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { Sun, AlertTriangle, Loader2, CheckCircle, Coins } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { dailySessionApi, cashBalanceApi } from '../../services/api/index'
import type { CashBalance } from '../../services/api/index'
import { useAuthStore } from '../../stores/authStore'
import { clearPersistedToken } from '../../services/api/index'
import { logger } from '../../utils/logger'

/** HUF cimletek — csökkeno sorrendben */
const HUF_DENOMINATIONS = [20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5] as const

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
  const [showDenomination, setShowDenomination] = useState(false)
  const [denomQuantities, setDenomQuantities] = useState<Record<number, number>>(
    () => Object.fromEntries(HUF_DENOMINATIONS.map((d) => [d, 0]))
  )

  const denomTotal = useMemo(
    () => HUF_DENOMINATIONS.reduce((sum, d) => sum + d * (denomQuantities[d] ?? 0), 0),
    [denomQuantities],
  )

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
        setBalanceError('A készlet nem kérdezhető le. Ellenőrizd a szerver kapcsolatot!')
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
      <div className="flex flex-1 items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
        <span className="ml-3 text-lg text-gray-600">Betöltés...</span>
      </div>
    )
  }

  if (alreadyOpen) {
    return (
      <div className="flex flex-1 flex-col items-center justify-center gap-3">
        <CheckCircle className="h-10 w-10 text-green-500" />
        <h2 className="text-lg font-bold text-gray-800">A nap már nyitva van</h2>
        <button
          onClick={() => navigate('/cashier')}
          className="rounded-lg bg-blue-600 px-4 py-2 text-white hover:bg-blue-700"
        >
          Tovább a pénztárhoz
        </button>
      </div>
    )
  }

  return (
    <div className="flex flex-col items-center justify-center">
      <div className="w-full max-w-lg space-y-2">
          {/* Header */}
          <div className="text-center">
            <Sun className="mx-auto h-8 w-8 text-amber-500" />
            <h1 className="mt-1 text-base font-bold text-gray-900">Napnyitás</h1>
            <p className="text-xs text-gray-500">
              {new Date().toLocaleDateString('hu-HU', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
              {' — '}
              {worker?.fullName ?? 'Ismeretlen pénztáros'}
            </p>
          </div>

          {/* Balance error */}
          {balanceError && (
            <div className="flex items-start gap-2 rounded-lg border border-amber-200 bg-amber-50 p-2">
              <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-amber-600" />
              <p className="text-xs text-amber-800">{balanceError}</p>
            </div>
          )}

          {/* Opening balance display */}
          {balances.length > 0 && (
            <div className="rounded-lg border border-gray-200 bg-white p-2 shadow-sm">
              <h3 className="mb-1 text-xs font-semibold uppercase tracking-wider text-gray-500">
                Nyito egyenleg
              </h3>

              {/* HUF balance — highlighted */}
              {hufBalance && (
                <div className="mb-1 flex items-center justify-between rounded bg-blue-50 px-2 py-1">
                  <span className="text-sm font-bold text-blue-900">HUF</span>
                  <span className="text-sm font-bold text-blue-900">
                    {hufBalance.currentBalance.toLocaleString('hu-HU')} Ft
                  </span>
                </div>
              )}

              {/* Foreign currency balances */}
              {foreignBalances.length > 0 && (
                <div className="grid grid-cols-2 gap-x-3">
                  {foreignBalances.map((b) => (
                    <div key={b.id} className="flex items-center justify-between px-1 py-0.5 text-xs">
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

          {/* Denomination input toggle */}
          <button
            onClick={() => setShowDenomination((v) => !v)}
            className="flex w-full items-center justify-center gap-2 rounded border border-gray-300 bg-white py-1.5 text-xs font-medium text-gray-700 hover:bg-gray-50"
          >
            <Coins className="h-3.5 w-3.5" />
            {showDenomination ? 'Címletezés elrejtése' : 'Nyitó címletezés kitöltése'}
          </button>

          {/* Denomination grid */}
          {showDenomination && (
            <div className="rounded-lg border border-gray-200 bg-white p-2 shadow-sm">
              <h3 className="mb-1 text-xs font-semibold uppercase tracking-wider text-gray-500">
                HUF címletezés
              </h3>
              <div className="grid grid-cols-2 gap-x-3 gap-y-0.5">
                {HUF_DENOMINATIONS.map((faceValue) => (
                  <div key={faceValue} className="flex items-center gap-3">
                    <span className="w-20 text-right text-sm font-medium text-gray-700">
                      {faceValue.toLocaleString('hu-HU')} Ft
                    </span>
                    <input
                      type="number"
                      min={0}
                      value={denomQuantities[faceValue] || ''}
                      onChange={(e) => {
                        const val = Math.max(0, parseInt(e.target.value) || 0)
                        setDenomQuantities((prev) => ({ ...prev, [faceValue]: val }))
                      }}
                      className="w-20 rounded border border-gray-300 px-2 py-1.5 text-center text-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500"
                      placeholder="0"
                    />
                    <span className="text-sm text-gray-500">
                      = {(faceValue * (denomQuantities[faceValue] ?? 0)).toLocaleString('hu-HU')} Ft
                    </span>
                  </div>
                ))}
              </div>
              {/* Total */}
              <div className="mt-3 flex items-center justify-between border-t border-gray-200 pt-3">
                <span className="text-sm font-bold text-gray-800">Osszesen:</span>
                <span className="text-lg font-bold text-blue-900">
                  {denomTotal.toLocaleString('hu-HU')} Ft
                </span>
              </div>
              {/* Comparison with system balance */}
              {hufBalance && (
                <div className={`mt-2 rounded-md p-2 text-sm ${
                  denomTotal === hufBalance.currentBalance
                    ? 'bg-green-50 text-green-800'
                    : 'bg-red-50 text-red-800'
                }`}>
                  {denomTotal === hufBalance.currentBalance
                    ? '✓ A cimletezés megegyezik a rendszer egyenleggel'
                    : `✗ Eltérés: ${(denomTotal - hufBalance.currentBalance).toLocaleString('hu-HU')} Ft (rendszer: ${hufBalance.currentBalance.toLocaleString('hu-HU')} Ft)`}
                </div>
              )}
            </div>
          )}

          {/* Open day button */}
          <button
            onClick={handleOpenDay}
            disabled={opening || !!balanceError}
            className="w-full rounded-lg bg-green-600 py-2 text-base font-bold text-white transition-colors hover:bg-green-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            {opening ? (
              <span className="flex items-center justify-center gap-2">
                <Loader2 className="h-4 w-4 animate-spin" />
                Megnyitás...
              </span>
            ) : (
              'Nap megnyitása'
            )}
          </button>

          {/* Back */}
          <button
            onClick={async () => {
              logout()
              await clearPersistedToken()
              navigate('/login', { replace: true })
            }}
            className="w-full text-center text-xs text-gray-500 hover:text-gray-700"
          >
            Kijelentkezés
          </button>
      </div>
    </div>
  )
}
