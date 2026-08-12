import { useTranslation } from 'react-i18next'
import { Download } from 'lucide-react'
import type { SuiteUpdateReady } from '../hooks/useSuiteUpdate'

type SuiteUpdateBadgeProps = {
  readyUpdate: SuiteUpdateReady | null
}

/**
 * „Frissítés készen áll" jelölő a fejlécben.
 *
 * MIÉRT ÍGY: a pénztárgépen a frissítés nem szakíthat meg pénzügyi folyamatot, de a
 * kollégának LÁTNIA kell, hogy van kész frissítés — különben nem tudja, mi történik,
 * és a gép csendben elmaradhatna. Ezért:
 *
 *  - nyitott műszak alatt: állandó, nem tolakodó jelölő azzal a szöveggel, hogy a
 *    telepítés a következő napnyitás előtt / napzárás után indul;
 *  - telepíthető ablakban (napnyitás előtt vagy napzárás után): kiemelt jelölő, mert
 *    ilyenkor a main process fel is ajánlja a telepítést egy dialógussal.
 *
 * Ez a komponens SEMMIT nem indít el — a telepítés kizárólag a main process
 * állapotgépén keresztül, felhasználói megerősítéssel történhet
 * (`docs/auto-update-terv-es-vegrehajtas.md` 3.6).
 */
export default function SuiteUpdateBadge({ readyUpdate }: SuiteUpdateBadgeProps) {
  const { t } = useTranslation()
  if (!readyUpdate) return null

  const installable = readyUpdate.installableNow
  const title = installable
    ? t('suiteUpdate.readyInstallable', { version: readyUpdate.version })
    : t('suiteUpdate.readyWaiting', { version: readyUpdate.version })

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
    </div>
  )
}
