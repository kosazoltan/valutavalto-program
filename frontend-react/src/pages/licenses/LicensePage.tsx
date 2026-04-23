import { useState, useEffect, useCallback } from 'react'
import { Key, RefreshCw, AlertTriangle, CheckCircle, XCircle } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'

/**
 * Fix #148 live UI re-test P1: LicenseResponse tenyleges mezonevek:
 *   - validTo (nem validUntil)
 *   - isActive, maxBranches, maxWorkers, remainingDays, status
 *   - features: STRING (nem array!) - valoszinuleg vesszo-separated
 */
interface LicenseResponse {
  id?: string | number
  companyId?: string | number
  licenseKey?: string
  validFrom?: string
  validTo?: string
  maxBranches?: number
  maxWorkers?: number
  features?: string
  isActive?: boolean
  status?: string
  remainingDays?: number
}

function parseFeatures(s: string | undefined): string[] {
  if (!s) return []
  // Comma, semicolon vagy pipe separator fallback
  return s.split(/[,;|]/).map(x => x.trim()).filter(Boolean)
}

export default function LicensePage() {
  const [license, setLicense] = useState<LicenseResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<LicenseResponse>('/license/current')
      setLicense(response.data ?? null)
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('LicensePage', 'Betoltesi hiba:', err)
      setError(msg)
      setLicense(null)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { void loadData() }, [loadData])

  const active = license?.isActive ?? false
  const features = parseFeatures(license?.features)

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Key className="h-6 w-6" />
          Licenc (aktualis)
        </h1>
        <div className="flex items-center gap-2">
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissites">
            <RefreshCw className={loading ? 'h-4 w-4 animate-spin' : 'h-4 w-4'} />
          </button>
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {loading ? (
        <div className="text-center text-sm text-gray-500 py-8">Betoltes...</div>
      ) : !license ? (
        <div className="text-center text-sm text-gray-500 py-8">Nincs aktiv licenc</div>
      ) : (
        <div className="bg-white rounded shadow p-4 space-y-3">
          <div className="flex items-center gap-2">
            {active ? (
              <><CheckCircle className="h-5 w-5 text-green-600" /> <span className="font-semibold text-green-700">Aktiv</span></>
            ) : (
              <><XCircle className="h-5 w-5 text-red-600" /> <span className="font-semibold text-red-700">Inaktiv</span></>
            )}
            {license.status && <span className="text-sm text-gray-500 ml-2">({license.status})</span>}
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
            <div><span className="text-gray-500">Kulcs:</span> <span className="font-mono">{license.licenseKey ?? '-'}</span></div>
            <div><span className="text-gray-500">Ervenyes:</span> {license.validFrom ? new Date(license.validFrom).toLocaleDateString('hu-HU') : '-'}</div>
            <div><span className="text-gray-500">Lejar:</span> {license.validTo ? new Date(license.validTo).toLocaleDateString('hu-HU') : '-'}</div>
            {license.remainingDays != null && <div><span className="text-gray-500">Hatralevo napok:</span> <b>{license.remainingDays}</b></div>}
            {license.maxBranches != null && <div><span className="text-gray-500">Max penztari egyseg:</span> {license.maxBranches}</div>}
            {license.maxWorkers != null && <div><span className="text-gray-500">Max dolgozo:</span> {license.maxWorkers}</div>}
          </div>
          {features.length > 0 && (
            <div>
              <div className="text-gray-500 text-sm mb-1">Feature-ek:</div>
              <div className="flex flex-wrap gap-1">
                {features.map((f) => (
                  <span key={f} className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded">{f}</span>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}