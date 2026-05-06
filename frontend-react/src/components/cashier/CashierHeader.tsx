import { useState, useEffect } from 'react'
import { Shield } from 'lucide-react'
import { useCompanyTheme } from '../../contexts/CompanyThemeContext'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'

/**
 * Penztar fejlec — minden cashier kepernyoen megjelenik.
 * Legacy: UNIT1.PAS foablak fejlece
 *   - Cegnev + logo (ceg szerinti szin)
 *   - Penztar kod + nev + cim + telefon
 *   - Penztaros neve + ID
 *   - Aktualis datum + ido (masodpercre)
 *   - Verzio szam
 *
 * v2.3.33 (B4): A komponens elsodlegesen a `useAuthStore`-bol toltodik,
 * a hardkodolt props-fallback (`Admin / Kozponti Iroda`) ELTAVOLITVA.
 * A komponens a logged-in worker mezoit hasznalja, ha auth nem aktiv,
 * akkor egyertelmuen "—" jelennek meg (hiba forrast jelzo helyettesito).
 */

/** v2.3.34 (Sourcery #298 P3): Hianyzo ertek placeholder — extract konstans
 * (lokalizacio + jovobeli theme-config konnyu modositast tesz lehetove). */
export const MISSING_VALUE_PLACEHOLDER = '—'

interface CashierHeaderProps {
  /** Override-okra van lehetoseg, de default a `useAuthStore` worker. */
  branchCode?: string
  branchName?: string
  workerName?: string
  workerId?: string
}

export function CashierHeader(props: CashierHeaderProps = {}) {
  const { t } = useTranslation()
  const worker = useAuthStore((s) => s.worker)
  const branchCode = props.branchCode ?? worker?.branchCode ?? MISSING_VALUE_PLACEHOLDER
  const branchName = props.branchName ?? worker?.branchName ?? MISSING_VALUE_PLACEHOLDER
  const workerName = props.workerName ?? worker?.fullName ?? MISSING_VALUE_PLACEHOLDER
  const workerId = props.workerId ?? worker?.workerCode ?? MISSING_VALUE_PLACEHOLDER

  const { theme } = useCompanyTheme()
  const [time, setTime] = useState(new Date())

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000)
    return () => clearInterval(timer)
  }, [])

  const dateStr = time.toLocaleDateString('hu-HU', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  })
  const timeStr = time.toLocaleTimeString('hu-HU', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  })

  return (
    <header
      className="border-b px-6 py-3 flex items-center justify-between"
      style={{ borderColor: theme.primary, backgroundColor: `${theme.primary}08` }}
    >
      <div className="flex items-center gap-4">
        <div
          className="w-10 h-10 rounded-lg flex items-center justify-center"
          style={{ backgroundColor: theme.primary }}
        >
          <Shield className="w-6 h-6 text-white" />
        </div>
        <div>
          <h1 className="text-lg font-bold text-gray-900 dark:text-white">
            {theme.name}
          </h1>
          <p className="text-sm text-gray-600 dark:text-gray-400">
            {t('components.penztar')}{branchCode} | {branchName}
          </p>
        </div>
      </div>

      <div className="text-right">
        <p className="text-sm text-gray-600 dark:text-gray-400">
          {t('components.penztaros')}{workerName} {t('components.id')} {workerId})
        </p>
        <p className="text-lg font-mono font-semibold text-gray-900 dark:text-white">
          {dateStr} | {timeStr}
        </p>
      </div>
    </header>
  )
}
