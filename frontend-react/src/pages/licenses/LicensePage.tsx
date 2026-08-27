import { useState, useEffect, useCallback } from 'react'
import { Key, RefreshCw, AlertTriangle, CheckCircle, XCircle } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

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

interface LicenseStatusResponse {
  status?: string
  remainingDays?: number
  maxBranches?: number
  maxWorkers?: number
  features?: string
}

function parseFeatures(s: string | undefined): string[] {
  if (!s) return []
  // Comma, semicolon vagy pipe separator fallback
  return s
    .split(/[,;|]/)
    .map((x) => x.trim())
    .filter(Boolean)
}

export default function LicensePage() {
  const { t } = useTranslation()
  const [license, setLicense] = useState<LicenseResponse | null>(null)
  const [status, setStatus] = useState<LicenseStatusResponse | null>(null)
  const [licenseKey, setLicenseKey] = useState('')
  const [loading, setLoading] = useState(true)
  const [activating, setActivating] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const [statusResult, licenseResult] = await Promise.allSettled([
        api.get<LicenseStatusResponse>('/license/status'),
        api.get<LicenseResponse>('/license/current'),
      ])

      if (statusResult.status === 'fulfilled') {
        setStatus(statusResult.value.data ?? null)
      } else {
        logger.error('LicensePage', 'Statusz betoltesi hiba:', statusResult.reason)
        setStatus(null)
      }

      if (licenseResult.status === 'fulfilled') {
        setLicense(licenseResult.value.data ?? null)
      } else {
        logger.error('LicensePage', 'Aktualis licenc betoltesi hiba:', licenseResult.reason)
        setLicense(null)
        if (statusResult.status === 'rejected') {
          setError(getErrorMessage(licenseResult.reason))
        }
      }
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('LicensePage', 'Betoltesi hiba:', err)
      setError(msg)
      setLicense(null)
      setStatus(null)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const active = license?.isActive ?? false
  const features = parseFeatures(license?.features ?? status?.features)

  const activateLicense = async () => {
    const trimmedKey = licenseKey.trim()
    if (!trimmedKey) {
      setError('Licenckulcs megadása kötelező.')
      setMessage(null)
      return
    }

    try {
      setActivating(true)
      setError(null)
      setMessage(null)
      const response = await api.post<LicenseResponse>('/license/activate', {
        licenseKey: trimmedKey,
      })
      setLicense(response.data ?? null)
      setLicenseKey('')
      setMessage('Licenc aktiválva.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('LicensePage', 'Aktivalasi hiba:', err)
      setError(msg)
    } finally {
      setActivating(false)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <Key className="h-6 w-6" />
          {t('licenses.licencAktualis')}
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

      {message && (
        <div className="rounded border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
          {message}
        </div>
      )}

      <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
        <h2 className="text-base font-semibold">{i18n.t('literals.licenc-statusz')}</h2>
        <div className="grid grid-cols-1 gap-3 text-sm md:grid-cols-4">
          <div>
            <div className="text-gray-500">{i18n.t('literals.statusz')}</div>
            <div className="font-semibold">{status?.status ?? '-'}</div>
          </div>
          <div>
            <div className="text-gray-500">{t('licenses.hatralevoNapok')}</div>
            <div className="font-mono">{status?.remainingDays ?? '-'}</div>
          </div>
          <div>
            <div className="text-gray-500">{t('licenses.maxPenztariEgyseg')}</div>
            <div className="font-mono">{status?.maxBranches ?? '-'}</div>
          </div>
          <div>
            <div className="text-gray-500">{t('licenses.maxDolgozo')}</div>
            <div className="font-mono">{status?.maxWorkers ?? '-'}</div>
          </div>
        </div>
      </div>

      <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
        <h2 className="text-base font-semibold">{i18n.t('literals.licenc-aktivalas')}</h2>
        <div className="grid gap-3 md:grid-cols-[1fr_auto]">
          <div>
            <label htmlFor="license-key" className="form-label">
              {i18n.t('literals.licenckulcs')}
            </label>
            <input
              id="license-key"
              type="text"
              value={licenseKey}
              onChange={(event) => setLicenseKey(event.target.value)}
              className="form-input w-full font-mono"
              placeholder="XXXX-XXXX-XXXX"
              autoComplete="off"
            />
          </div>
          <div className="flex items-end">
            <button
              type="button"
              onClick={() => void activateLicense()}
              disabled={activating || !licenseKey.trim()}
              className="form-button w-full md:w-auto"
            >
              {activating ? 'Aktiválás...' : 'Aktiválás'}
            </button>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="text-center text-sm text-gray-500 py-8">{i18n.t('literals.betoltes')}</div>
      ) : !license ? (
        <div className="text-center text-sm text-gray-500 py-8">
          {t('licenses.nincsAktivLicenc')}
        </div>
      ) : (
        <div className="bg-white rounded shadow p-4 space-y-3">
          <div className="flex items-center gap-2">
            {active ? (
              <>
                <CheckCircle className="h-5 w-5 text-green-600" />{' '}
                <span className="font-semibold text-green-700">{t('competitors.aktiv')}</span>
              </>
            ) : (
              <>
                <XCircle className="h-5 w-5 text-red-600" />{' '}
                <span className="font-semibold text-red-700">{t('licenses.inaktiv')}</span>
              </>
            )}
            {license.status && (
              <span className="text-sm text-gray-500 ml-2">
                {i18n.t('literals.lit-19')}
                {license.status}
                {i18n.t('literals.lit-2')}
              </span>
            )}
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm">
            <div>
              <span className="text-gray-500">{t('licenses.kulcs')}</span>{' '}
              <span className="font-mono">{license.licenseKey ?? '-'}</span>
            </div>
            <div>
              <span className="text-gray-500">{t('licenses.ervenyes')}</span>{' '}
              {license.validFrom ? new Date(license.validFrom).toLocaleDateString('hu-HU') : '-'}
            </div>
            <div>
              <span className="text-gray-500">{t('licenses.lejar')}</span>{' '}
              {license.validTo ? new Date(license.validTo).toLocaleDateString('hu-HU') : '-'}
            </div>
            {license.remainingDays != null && (
              <div>
                <span className="text-gray-500">{t('licenses.hatralevoNapok')}</span>{' '}
                <b>{license.remainingDays}</b>
              </div>
            )}
            {license.maxBranches != null && (
              <div>
                <span className="text-gray-500">{t('licenses.maxPenztariEgyseg')}</span>{' '}
                {license.maxBranches}
              </div>
            )}
            {license.maxWorkers != null && (
              <div>
                <span className="text-gray-500">{t('licenses.maxDolgozo')}</span>{' '}
                {license.maxWorkers}
              </div>
            )}
          </div>
          {features.length > 0 && (
            <div>
              <div className="text-gray-500 text-sm mb-1">{t('licenses.featureEk')}</div>
              <div className="flex flex-wrap gap-1">
                {features.map((f) => (
                  <span key={f} className="bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded">
                    {f}
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
