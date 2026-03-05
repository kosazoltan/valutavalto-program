import { useState, useEffect } from 'react'
import { Shield } from 'lucide-react'
import { useCompanyTheme } from '../../contexts/CompanyThemeContext'

/**
 * Penztar fejlec — minden cashier kepernyoen megjelenik.
 * Legacy: UNIT1.PAS foablak fejlece
 *   - Cegnev + logo (ceg szerinti szin)
 *   - Penztar kod + nev + cim + telefon
 *   - Penztaros neve + ID
 *   - Aktualis datum + ido (masodpercre)
 *   - Verzio szam
 */

interface CashierHeaderProps {
  branchCode?: string
  branchName?: string
  workerName?: string
  workerId?: string
}

export function CashierHeader({
  branchCode = '101',
  branchName = 'Kozponti Iroda',
  workerName = 'Admin',
  workerId = 'ADMIN',
}: CashierHeaderProps) {
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
            Penztar: {branchCode} | {branchName}
          </p>
        </div>
      </div>

      <div className="text-right">
        <p className="text-sm text-gray-600 dark:text-gray-400">
          Penztaros: {workerName} (ID: {workerId})
        </p>
        <p className="text-lg font-mono font-semibold text-gray-900 dark:text-white">
          {dateStr} | {timeStr}
        </p>
      </div>
    </header>
  )
}
