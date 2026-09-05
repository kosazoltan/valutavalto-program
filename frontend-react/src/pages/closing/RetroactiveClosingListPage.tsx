import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  retroactiveClosingApi,
  type RetroactiveDayInspection,
  type RetroactiveOpenPastDay,
} from '../../services/api/settings'
import { useAuthStore } from '../../stores/authStore'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import i18n from '../../i18n'

/**
 * FKH-050 (FR-1/D3): entry point of the retroactive closing flow — lists the
 * caller's own open past days OLDEST FIRST, and only the oldest day is
 * actionable (the opening-balance chain requires chronological closing; the
 * backend enforces the same gate).
 *
 * FKH-051 (plan D4/D5/D6): a plain ISO date input inspects a typed past date
 * and routes by the server kind enum: OPEN -> start the existing FKH-050 flow;
 * FALSE_CLOSED -> warning + reprocess confirm (reopen, then navigate); other
 * kinds -> render the server message, never navigate. List rows carrying kind
 * FALSE_CLOSED render the reprocess action instead of the start action; a
 * missing kind (older cached response) is treated as OPEN.
 */
export default function RetroactiveClosingListPage() {
  const navigate = useNavigate()
  const worker = useAuthStore((s: { worker: { branchId: string } | null }) => s.worker)
  const branchId = worker?.branchId ?? ''

  const [days, setDays] = useState<RetroactiveOpenPastDay[]>([])
  const [loading, setLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [dateInput, setDateInput] = useState('')
  const [inspection, setInspection] = useState<RetroactiveDayInspection | null>(null)
  const [dateError, setDateError] = useState<string | null>(null)
  const [inspecting, setInspecting] = useState(false)
  const [reprocessing, setReprocessing] = useState(false)

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

  const startFlow = (date: string) => {
    navigate(`/closing/retroactive/${date}`)
  }

  const reprocess = async (date: string) => {
    setReprocessing(true)
    try {
      await retroactiveClosingApi.reopen(branchId, date)
      startFlow(date)
    } catch (error) {
      logger.error('RetroactiveClosingListPage', 'reprocess (reopen) failed:', error)
      setDateError(getErrorMessage(error))
    } finally {
      setReprocessing(false)
    }
  }

  const handleDateSubmit = async () => {
    const date = dateInput.trim()
    if (!date || !branchId) return
    setInspecting(true)
    setInspection(null)
    setDateError(null)
    try {
      const result = await retroactiveClosingApi.inspect(branchId, date)
      // D4: branch on the kind enum ONLY, never on message text.
      if (result.kind === 'OPEN') {
        startFlow(result.date || date)
        return
      }
      if (result.kind === 'FALSE_CLOSED') {
        setInspection(result)
        return
      }
      setInspection(result)
      setDateError(result.message)
    } catch (error) {
      logger.error('RetroactiveClosingListPage', 'inspect failed:', error)
      setDateError(getErrorMessage(error))
    } finally {
      setInspecting(false)
    }
  }

  return (
    <div className="mx-auto max-w-3xl p-6">
      <h1 className="mb-4 text-2xl font-bold">{i18n.t('literals.utolagos-napzaras')}</h1>

      {/* FKH-051: typed-date inspection (plain ISO date input, no calendar widget — NFR-4). */}
      <div className="mb-4 flex items-center gap-2">
        <input
          type="date"
          data-testid="retroactive-date-input"
          value={dateInput}
          max={new Date(Date.now() - 86400000).toISOString().slice(0, 10)}
          onChange={(e) => setDateInput(e.target.value)}
          className="rounded border border-slate-300 px-2 py-1.5 text-sm focus:border-blue-500 focus:outline-none"
        />
        <button
          type="button"
          data-testid="retroactive-date-submit"
          disabled={inspecting || !dateInput.trim()}
          onClick={() => void handleDateSubmit()}
          className="rounded bg-blue-600 px-3 py-1.5 text-sm text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {i18n.t('literals.utolagos-nap-megvizsgalasa')}
        </button>
      </div>

      {dateError && (
        <div
          data-testid="retroactive-date-error"
          className="mb-4 rounded-lg border border-red-300 bg-red-50 p-3 text-sm text-red-700"
        >
          {dateError}
        </div>
      )}

      {inspection?.kind === 'FALSE_CLOSED' && (
        <div
          data-testid="retroactive-false-closed-warning"
          className="mb-4 rounded-lg border border-amber-300 bg-amber-50 p-3 text-sm text-amber-800"
        >
          <p>{inspection.message}</p>
          <button
            type="button"
            data-testid="retroactive-reprocess-confirm"
            disabled={reprocessing}
            onClick={() => void reprocess(inspection.date || dateInput.trim())}
            className="mt-2 rounded bg-amber-600 px-3 py-1.5 text-sm text-white hover:bg-amber-700 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {i18n.t('literals.tevesen-lezart-nap-ujranyitasa')}
          </button>
        </div>
      )}

      {loading && <p className="text-slate-600">{i18n.t('literals.utolagos-betoltes')}</p>}
      {errorMessage && <p className="text-red-600">{errorMessage}</p>}

      {!loading && !errorMessage && days.length === 0 && (
        <div
          data-testid="retroactive-empty-state"
          className="rounded-lg border border-slate-300 bg-white p-6 text-center text-slate-600"
        >
          {i18n.t('literals.nincs-nyitott-multbeli-nap')}
        </div>
      )}

      {!loading && days.length > 0 && (
        <ul className="space-y-2">
          {days.map((day, index) => {
            // D3: only the OLDEST day is actionable.
            const actionable = index === 0
            // FKH-051 (D6): a missing kind (older cached response) is OPEN.
            const kind = day.kind ?? 'OPEN'
            return (
              <li
                key={day.date}
                data-testid={`open-day-row-${day.date}`}
                className="flex items-center justify-between rounded-lg border border-slate-300 bg-white p-3"
              >
                <span className="font-medium">{day.date}</span>
                {kind === 'FALSE_CLOSED' ? (
                  <button
                    type="button"
                    data-testid={`open-day-reprocess-${day.date}`}
                    className="rounded bg-amber-600 px-3 py-1.5 text-sm text-white hover:bg-amber-700 disabled:cursor-not-allowed disabled:opacity-50"
                    disabled={!actionable || reprocessing}
                    title={
                      actionable
                        ? undefined
                        : i18n.t('literals.elobb-a-legregebbi-nyitott-napot-kell-lezarni')
                    }
                    onClick={() => void reprocess(day.date)}
                  >
                    {i18n.t('literals.tevesen-lezart-nap-ujranyitasa')}
                  </button>
                ) : (
                  <button
                    type="button"
                    data-testid={`open-day-action-${day.date}`}
                    className="rounded bg-blue-600 px-3 py-1.5 text-sm text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                    disabled={!actionable}
                    title={
                      actionable
                        ? undefined
                        : i18n.t('literals.elobb-a-legregebbi-nyitott-napot-kell-lezarni')
                    }
                    onClick={() => navigate(`/closing/retroactive/${day.date}`)}
                  >
                    {actionable
                      ? i18n.t('literals.utolagos-zaras-inditasa')
                      : i18n.t('literals.zarolva')}
                  </button>
                )}
              </li>
            )
          })}
        </ul>
      )}
    </div>
  )
}
