import { ReactNode } from 'react'
import { Camera, Info } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useFeatureFlags } from '../hooks/useFeatureFlags'
import { useTranslation } from 'react-i18next'

/**
 * Fix #148 P2 UX: ha a backend `camera.enabled=false`, a /camera/* oldalak
 * API 404-et dobnak. A CameraGuard a user-t figyelmezteti a feature flag
 * statuszra, igy nem jut el a hibas page-re, es nem kap crash-t.
 *
 * Hasznalat: wrap-eld a /camera/* route-okat az App.tsx-ben.
 */
export default function CameraGuard({ children }: { children: ReactNode }) {
  const { t } = useTranslation()
  const flags = useFeatureFlags()

  if (!flags.camera) {
    return (
      <div className="form-panel">
        <div className="flex items-center gap-2 mb-4">
          <Camera className="h-6 w-6 text-gray-400" />
          <h1 className="form-title">{t('components.kameraModul')}</h1>
        </div>
        <div className="bg-blue-50 border border-blue-200 rounded p-4 flex gap-3">
          <Info className="h-5 w-5 text-blue-600 shrink-0 mt-1" />
          <div className="text-sm space-y-2">
            <p className="font-semibold text-blue-900">
              {t('components.aKameraModulJelenlegNincsEngedelyezve')}
            </p>
            <p className="text-gray-700">
              {t('components.aBackend')}
              <code className="bg-blue-100 px-1 rounded">{t('components.cameraEnabledfalse')}</code>
              {t('components.konfiguraciobanVanAhhozHogyALiveStreamVisszajatszasEs')}
              {t('components.exportFunkciokElerhetokLegyenekAzUzemeltetoRendszergazdanak')}
              {t('components.engedelyeznieKellAzIntegraciot')}
            </p>
            <p className="text-gray-600">
              {t('components.kerdesEseten')}
              <a href="mailto:info@excvaluta.com" className="text-blue-700 underline">
                {t('components.infoexcvalutacom')}
              </a>
            </p>
            <div className="mt-3">
              <Link to="/dashboard" className="form-button-primary inline-block">
                {t('components.visszaAzIranyitopultra')}
              </Link>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return <>{children}</>
}
