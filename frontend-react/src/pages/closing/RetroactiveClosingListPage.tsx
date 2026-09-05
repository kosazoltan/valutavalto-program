import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { retroactiveClosingApi, type RetroactiveOpenPastDay } from '../../services/api/settings'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

/**
 * FKH-050 (FR-1/D3): entry point of the retroactive closing flow — lists the
 * caller's own open past days OLDEST FIRST, and only the oldest day is
 * actionable (the opening-balance chain requires chronological closing; the
 * backend enforces the same gate).
 */
export default function RetroactiveClosingListPage() {
  const navigate = useNavigate()
  const worker = useAuthStore((s: { worker: { branchId: string } | null }) => s.worker)
  const branchId = worker?.branchId ?? ''

  const [days, setDays] = useState<RetroactiveOpenPastDay[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const loadDays = useCallback(async () => {
    if (!branchId) return
    setLoading(true)
    setErrorMessage(null)
    try {
      setDays(await retroactiveClosingApi.listOpenDays(branchId))
    } catch (error) {
      logger.error('RetroactiveClosingListPage', 'open-days load failed:', error)
      setErrorMessage(getErrorMessage(error))
    } finally {
      setLoading(false)
    }
  }, [branchId])

  useEffect(() => {
    void loadDays()
  }, [loadDays])

  return (
    <div className="mx-auto max-w-3xl p-6">
      <h1 className="mb-4 text-2xl font-bold">Utólagos napzárás</h1>
      {loading && <p className="text-slate-600">Betöltés…</p>}
      {errorMessage && <p className="text-red-600">{errorMessage}</p>}

      {!loading && !errorMessage && days.length === 0 && (
        <div
          data-testid="retroactive-empty-state"
          className="rounded-lg border border-slate-300 bg-white p-6 text-center text-slate-600"
        >
          Nincs nyitott múlt-beli nap — minden korábbi nap le van zárva.
        </div>
      )}

      {!loading && days.length > 0 && (
        <ul className="space-y-2">
          {days.map((day, index) => {
            // D3: only the OLDEST open day is actionable.
            const actionable = index === 0
            return (
              <li
                key={day.date}
                data-testid={`open-day-row-${day.date}`}
                className="flex items-center justify-between rounded-lg border border-slate-300 bg-white p-3"
              >
                <span className="font-medium">{day.date}</span>
                <button
                  type="button"
                  data-testid={`open-day-action-${day.date}`}
                  className="rounded bg-blue-600 px-3 py-1.5 text-sm text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                  disabled={!actionable}
                  title={actionable ? undefined : 'Előbb a legrégebbi nyitott napot kell lezárni'}
                  onClick={() => navigate(`/closing/retroactive/${day.date}`)}
                >
                  {actionable ? 'Zárás indítása' : 'Zárolva'}
                </button>
              </li>
            )
          })}
        </ul>
      )}
    </div>
  )
}
