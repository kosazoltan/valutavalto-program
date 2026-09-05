import { useCallback, useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { retroactiveClosingApi, type RetroactiveReconciliation } from '../../services/api/settings'
import { useAuthStore } from '../../stores/authStore'
import RetroactiveClosingBanner from '../../components/closing/RetroactiveClosingBanner'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import i18n from '../../i18n'

/**
 * FKH-050 (FR-3/FR-4/FR-5/FR-6): the simplified RETROACTIVE closing flow for one
 * past day — 3 steps (< 9, FR-3) under a prominent amber banner (FR-4):
 *   1. denomination entry for that date (reuses DenominationEntryPage via the
 *      businessDate query param — no clone, D9),
 *   2. reconciliation (expected from that day's daily_balance, FR-5),
 *   3. send + close (disabled while any row is blocking, FR-6/D7).
 */
export default function RetroactiveClosingPage() {
  const { date = '' } = useParams<{ date: string }>()
  const navigate = useNavigate()

  const worker = useAuthStore((s: { worker: { branchId: string } | null }) => s.worker)
  const branchId = worker?.branchId ?? ''

  const [reconciliation, setReconciliation] = useState<RetroactiveReconciliation | null>(null)
  const [loading, setLoading] = useState(false)
  const [closing, setClosing] = useState(false)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  const loadReconciliation = useCallback(async () => {
    if (!branchId || !date) return
    setLoading(true)
    setErrorMessage(null)
    try {
      setReconciliation(await retroactiveClosingApi.reconcile(branchId, date))
    } catch (error) {
      logger.error('RetroactiveClosingPage', 'Reconciliation load failed:', error)
      setErrorMessage(getErrorMessage(error))
    } finally {
      setLoading(false)
    }
  }, [branchId, date])

  useEffect(() => {
    void loadReconciliation()
  }, [loadReconciliation])

  const handleClose = useCallback(async () => {
    if (!branchId || !date || closing) return
    setClosing(true)
    try {
      await retroactiveClosingApi.close(branchId, date)
      navigate('/closing/retroactive')
    } catch (error) {
      logger.error('RetroactiveClosingPage', 'Retroactive close failed:', error)
      setErrorMessage(getErrorMessage(error))
      setClosing(false)
    }
  }, [branchId, date, closing, navigate])

  const anyBlocking = reconciliation?.anyBlocking ?? false

  return (
    <div className="mx-auto max-w-4xl p-6">
      <RetroactiveClosingBanner date={date} />

      <ol className="mb-6 space-y-3">
        {/* Step 1 — denomination entry for the past date (reuses the shared page). */}
        <li
          data-testid="retroactive-step"
          className="rounded-lg border border-slate-300 bg-white p-4"
        >
          <h3 className="font-semibold">{i18n.t('literals.utolagos-1-lepes', { date })}</h3>
          <p className="mb-2 text-sm text-slate-600">
            {i18n.t('literals.utolagos-rogzitse-a-nap-esti-keszletet', { date })}
          </p>
          <Link
            className="inline-block rounded bg-blue-600 px-3 py-1.5 text-sm text-white hover:bg-blue-700"
            to={`/closing/denomination-entry/EVENING?businessDate=${date}&returnTo=/closing/retroactive/${date}`}
          >
            {i18n.t('literals.cimletezes-megnyitasa')}
          </Link>
        </li>

        {/* Step 2 — reconciliation against the past day's book value. */}
        <li
          data-testid="retroactive-step"
          className="rounded-lg border border-slate-300 bg-white p-4"
        >
          <h3 className="mb-2 font-semibold">{i18n.t('literals.utolagos-2-lepes')}</h3>
          {loading && (
            <p className="text-sm text-slate-600">{i18n.t('literals.utolagos-betoltes')}</p>
          )}
          {errorMessage && (
            <p className="text-sm text-red-600" data-testid="retroactive-error">
              {errorMessage}
            </p>
          )}
          {reconciliation && (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b text-left">
                  <th className="py-1">{i18n.t('literals.utolagos-valuta')}</th>
                  <th className="py-1 text-right">{i18n.t('literals.utolagos-elvart')}</th>
                  <th className="py-1 text-right">{i18n.t('literals.utolagos-tenyleges')}</th>
                  <th className="py-1 text-right">{i18n.t('literals.utolagos-elteres')}</th>
                </tr>
              </thead>
              <tbody>
                {reconciliation.rows.map((row) => (
                  <tr key={row.currencyCode} className="border-b">
                    <td className="py-1">{row.currencyCode}</td>
                    <td
                      className="py-1 text-right"
                      data-testid={`retroactive-expected-${row.currencyCode}`}
                    >
                      {row.expected}
                    </td>
                    <td
                      className="py-1 text-right"
                      data-testid={`retroactive-actual-${row.currencyCode}`}
                    >
                      {row.actual}
                    </td>
                    <td
                      className={`py-1 text-right ${row.blocking ? 'font-bold text-red-600' : ''}`}
                      data-testid={`retroactive-difference-${row.currencyCode}`}
                    >
                      {row.difference}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </li>

        {/* Step 3 — send + close (FR-6: disabled while any row is blocking). */}
        <li
          data-testid="retroactive-step"
          className="rounded-lg border border-slate-300 bg-white p-4"
        >
          <h3 className="mb-2 font-semibold">{i18n.t('literals.utolagos-3-lepes')}</h3>
          <button
            type="button"
            data-testid="retroactive-close-button"
            className="rounded bg-amber-600 px-4 py-2 font-semibold text-white hover:bg-amber-700 disabled:cursor-not-allowed disabled:opacity-50"
            disabled={anyBlocking || loading || closing || !reconciliation}
            onClick={() => void handleClose()}
          >
            {closing
              ? i18n.t('literals.utolagos-zaras-folyamatban')
              : i18n.t('literals.utolagos-nap-zarasa', { date })}
          </button>
          {anyBlocking && (
            <p className="mt-2 text-sm text-red-600">
              {i18n.t('literals.utolagos-az-egyeztetes-elterest-talalt')}
            </p>
          )}
        </li>
      </ol>
    </div>
  )
}
