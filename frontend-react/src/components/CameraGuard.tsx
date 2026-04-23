import { ReactNode } from 'react'
import { Camera, Info } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useFeatureFlags } from '../hooks/useFeatureFlags'

/**
 * Fix #148 P2 UX: ha a backend `camera.enabled=false`, a /camera/* oldalak
 * API 404-et dobnak. A CameraGuard a user-t figyelmezteti a feature flag
 * statuszra, igy nem jut el a hibas page-re, es nem kap crash-t.
 *
 * Hasznalat: wrap-eld a /camera/* route-okat az App.tsx-ben.
 */
export default function CameraGuard({ children }: { children: ReactNode }) {
  const flags = useFeatureFlags()

  if (!flags.camera) {
    return (
      <div className="form-panel">
        <div className="flex items-center gap-2 mb-4">
          <Camera className="h-6 w-6 text-gray-400" />
          <h1 className="form-title">Kamera modul</h1>
        </div>
        <div className="bg-blue-50 border border-blue-200 rounded p-4 flex gap-3">
          <Info className="h-5 w-5 text-blue-600 shrink-0 mt-1" />
          <div className="text-sm space-y-2">
            <p className="font-semibold text-blue-900">A kamera modul jelenleg nincs engedelyezve.</p>
            <p className="text-gray-700">
              A backend <code className="bg-blue-100 px-1 rounded">camera.enabled=false</code>
              konfiguracioban van. Ahhoz hogy a live stream, visszajatszas es
              export funkciok elerhetok legyenek, az uzemelteto rendszergazdanak
              engedelyeznie kell az integraciot.
            </p>
            <p className="text-gray-600">
              Kerdes esetén: <a href="mailto:info@excvaluta.com" className="text-blue-700 underline">info@excvaluta.com</a>
            </p>
            <div className="mt-3">
              <Link to="/dashboard" className="form-button-primary inline-block">
                Vissza az iranyitopultra
              </Link>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return <>{children}</>
}