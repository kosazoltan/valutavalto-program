import { useTranslation } from 'react-i18next'
import { Download, AlertTriangle } from 'lucide-react'
import type { SuiteUpdateReady, SuiteUpdateInstallFailure } from '../hooks/useSuiteUpdate'
import { getElectronAPI } from '../utils/electron'
import { logger } from '../utils/logger'

type SuiteUpdateBadgeProps = {
  readyUpdate: SuiteUpdateReady | null
  /** kanban #8: a failed install must stay VISIBLE (no silent READY revert). */
  installFailure?: SuiteUpdateInstallFailure | null
}

/**
 * Header marker for a verified suite update.
 *
 * Display-only until the user confirms "Telepítés most". Auto-install still
 * runs in the main process on CLOSED_AFTER_DAY_END / IDLE_BEFORE_OPEN.
 * Explicit start is allowed while SHIFT_OPEN (kanban #7).
 *
 * kanban #8: when the install attempt FAILED (UAC refused / launch error) the
 * badge switches to an error variant carrying the version and installer path —
 * the failure is never invisible.
 */
export default function SuiteUpdateBadge({ readyUpdate, installFailure }: SuiteUpdateBadgeProps) {
  const { t } = useTranslation()

  // Shared explicit-install flow: confirm, then ask the main process to start.
  // The error variant uses the SAME control (kanban #8 rework: the cashier
  // must be able to retry the prompt from the failure surface; the main
  // process accepts INSTALL_FAILED via canStartInstallOnDemand).
  const confirmAndStartInstall = (message: string) => {
    const ok = window.confirm(message)
    if (!ok) return
    void getElectronAPI()
      ?.suiteUpdate?.startInstall()
      ?.catch((error: unknown) => logger.warn('SuiteUpdate', 'startInstall failed', error))
  }

  if (installFailure) {
    const failedTitle =
      installFailure.reason === 'ELEVATION_REFUSED'
        ? t('suiteUpdate.installFailedElevation', {
            version: installFailure.version,
            path: installFailure.installerPath,
          })
        : t('suiteUpdate.installFailed', {
            version: installFailure.version,
            path: installFailure.installerPath,
          })
    return (
      <div
        data-testid="suite-update-failed"
        title={failedTitle}
        className="flex items-center gap-2 rounded-lg border border-danger-300 bg-danger-50 px-3 py-1.5 text-sm font-medium text-danger-800"
      >
        <AlertTriangle size={16} aria-hidden="true" />
        <span>{failedTitle}</span>
        <button
          type="button"
          data-testid="suite-update-install-now"
          className="ml-1 rounded border border-current px-2 py-0.5 text-xs font-semibold"
          onClick={() => confirmAndStartInstall(failedTitle)}
        >
          {t('suiteUpdate.installNow')}
        </button>
      </div>
    )
  }

  if (!readyUpdate) return null

  const installable = readyUpdate.installableNow
  const title = installable
    ? t('suiteUpdate.readyInstallable', { version: readyUpdate.version })
    : t('suiteUpdate.readyWaiting', { version: readyUpdate.version })

  const onInstallNow = () => {
    confirmAndStartInstall(t('suiteUpdate.readyInstallable', { version: readyUpdate.version }))
  }

  return (
    <div
      data-testid="suite-update-badge"
      title={title}
      className={
        installable
          ? 'flex items-center gap-2 rounded-lg border border-success-300 bg-success-50 px-3 py-1.5 text-sm font-medium text-success-800'
          : 'flex items-center gap-2 rounded-lg border border-secondary-300 bg-secondary-50 px-3 py-1.5 text-sm font-medium text-secondary-700'
      }
    >
      <Download size={16} aria-hidden="true" />
      <span>
        {installable
          ? t('suiteUpdate.badgeInstallable', { version: readyUpdate.version })
          : t('suiteUpdate.badgeWaiting', { version: readyUpdate.version })}
      </span>
      <button
        type="button"
        data-testid="suite-update-install-now"
        className="ml-1 rounded border border-current px-2 py-0.5 text-xs font-semibold"
        onClick={onInstallNow}
      >
        {t('suiteUpdate.installNow')}
      </button>
    </div>
  )
}
