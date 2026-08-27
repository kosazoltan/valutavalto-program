import { useState, useEffect, useCallback } from 'react'
import { Loader2, RefreshCw, AlertCircle, CheckCircle2, Play, Save } from 'lucide-react'
import { api } from '../../services/api/client'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

interface MnbStatus {
  rateCount: number
  lastFetchSuccess: boolean
  lastFetchDate: string | null
  schedulerActive: boolean
}

interface RaiffeisenStatus {
  schedulerActive: boolean
  scheduledTime: string
  enabled?: boolean
  mode?: string
  endpointConfigured?: boolean
  lastRunStatus?: string
  lastRunTimestamp?: string | null
  lastRunMessage?: string | null
}

interface DariusStatus {
  currentMonth: string
  periodStart: string
  periodEnd: string
  pendingReportsCount: number
  failedReportsCount: number
  submittedReportsCount: number
  lastSubmittedAt: string | null
  transportMode: string
}

interface BankIntegrationStatusResponse {
  mnb: MnbStatus
  raiffeisen: RaiffeisenStatus
  darius: DariusStatus
  checkedAt: string
}

interface BankApiConfig {
  id?: string
  providerName: string
  mode: 'HTML_SCRAPING_FALLBACK' | 'REST_PRIMARY_WITH_HTML_FALLBACK' | 'DISABLED' | string
  endpointUrl?: string | null
  authType: 'NONE' | 'OAUTH2_CLIENT_CREDENTIALS' | 'OAUTH2_MTLS' | string
  clientId?: string | null
  clientSecretConfigured?: boolean
  mtlsCertificateAlias?: string | null
  updateFrequency: string
  enabled: boolean
  lastRunTimestamp?: string | null
  lastRunStatus?: string | null
  lastRunMessage?: string | null
  updatedAt?: string | null
}

interface FetchNowResponse {
  savedRates: number
  config: BankApiConfig
}

const RAIFFEISEN_PROVIDER = 'RAIFFEISEN'

/**
 * v2.5.50 Sprint 2: Bank API integráció admin monitoring.
 *
 * Megjeleníti az MNB, Raiffeisen és Darius integráció állapotát.
 * Manual refresh és Darius retry triggerek.
 */
export default function BankIntegrationStatusPage() {
  const [status, setStatus] = useState<BankIntegrationStatusResponse | null>(null)
  const [configs, setConfigs] = useState<BankApiConfig[]>([])
  const [raiffeisenConfig, setRaiffeisenConfig] = useState<BankApiConfig | null>(null)
  const [configForm, setConfigForm] = useState({
    mode: 'HTML_SCRAPING_FALLBACK',
    endpointUrl: '',
    authType: 'NONE',
    clientId: '',
    clientSecret: '',
    mtlsCertificateAlias: '',
    updateFrequency: '0 0 8 * * MON-FRI',
    enabled: true,
  })
  const [loading, setLoading] = useState(false)
  const [refreshing, setRefreshing] = useState(false)
  const [configLoading, setConfigLoading] = useState(false)
  const [savingConfig, setSavingConfig] = useState(false)
  const [fetchingRaiffeisen, setFetchingRaiffeisen] = useState(false)

  const applyConfig = (config: BankApiConfig) => {
    setRaiffeisenConfig(config)
    setConfigForm({
      mode: config.mode ?? 'HTML_SCRAPING_FALLBACK',
      endpointUrl: config.endpointUrl ?? '',
      authType: config.authType ?? 'NONE',
      clientId: config.clientId ?? '',
      clientSecret: '',
      mtlsCertificateAlias: config.mtlsCertificateAlias ?? '',
      updateFrequency: config.updateFrequency ?? '0 0 8 * * MON-FRI',
      enabled: Boolean(config.enabled),
    })
  }

  // Returns true ha sikeres a lekérdezés (Codex P2 #567)
  const loadStatus = useCallback(async (): Promise<boolean> => {
    setLoading(true)
    try {
      const response = await api.get<BankIntegrationStatusResponse>(
        '/admin/bank-integration/status',
      )
      setStatus(response.data)
      return true
    } catch (err) {
      logger.error('BankIntegrationStatus', 'Status betöltési hiba:', err)
      toast.error('Hiba', 'Bank integráció állapot lekérdezése sikertelen')
      return false
    } finally {
      setLoading(false)
    }
  }, [])

  const loadConfig = useCallback(async (): Promise<boolean> => {
    setConfigLoading(true)
    try {
      const [listResponse, raiffeisenResponse] = await Promise.all([
        api.get<BankApiConfig[]>('/bank-api-config'),
        api.get<BankApiConfig>(`/bank-api-config/${RAIFFEISEN_PROVIDER}`),
      ])
      setConfigs(listResponse.data)
      applyConfig(raiffeisenResponse.data)
      return true
    } catch (err) {
      logger.error('BankIntegrationStatus', 'Konfiguráció betöltési hiba:', err)
      toast.error('Hiba', 'Bank API konfiguráció lekérdezése sikertelen')
      return false
    } finally {
      setConfigLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadStatus()
    void loadConfig()
  }, [loadConfig, loadStatus])

  const handleRefresh = async () => {
    setRefreshing(true)
    const [statusOk, configOk] = await Promise.all([loadStatus(), loadConfig()])
    setRefreshing(false)
    if (statusOk && configOk) {
      toast.success('Frissítve', 'Bank integráció állapot újraolvasva')
    }
    // Hiba esetén a loadStatus már mutatott egy error toast-ot — ne mondj contradictory success-t
  }

  const handleSaveConfig = async () => {
    setSavingConfig(true)
    try {
      const response = await api.put<BankApiConfig>(`/bank-api-config/${RAIFFEISEN_PROVIDER}`, {
        mode: configForm.mode,
        endpointUrl: configForm.endpointUrl.trim() || null,
        authType: configForm.authType,
        clientId: configForm.clientId.trim() || null,
        clientSecret: configForm.clientSecret.trim() || null,
        mtlsCertificateAlias: configForm.mtlsCertificateAlias.trim() || null,
        updateFrequency: configForm.updateFrequency.trim(),
        enabled: configForm.enabled,
      })
      applyConfig(response.data)
      await loadStatus()
      toast.success('Mentve', 'Raiffeisen Bank API konfiguráció mentve')
    } catch (err) {
      logger.error('BankIntegrationStatus', 'Konfiguráció mentési hiba:', err)
      toast.error('Hiba', 'Raiffeisen konfiguráció mentése sikertelen')
    } finally {
      setSavingConfig(false)
    }
  }

  const handleFetchRaiffeisenNow = async () => {
    setFetchingRaiffeisen(true)
    try {
      const response = await api.post<FetchNowResponse>('/bank-api-config/raiffeisen/fetch-now')
      applyConfig(response.data.config)
      await loadStatus()
      toast.success('Raiffeisen frissítés', `${response.data.savedRates} árfolyam mentve`)
    } catch (err) {
      logger.error('BankIntegrationStatus', 'Raiffeisen kézi frissítés hiba:', err)
      toast.error('Hiba', 'Raiffeisen kézi frissítés sikertelen')
    } finally {
      setFetchingRaiffeisen(false)
    }
  }

  if (loading && !status) {
    return (
      <div className="flex items-center gap-2 text-gray-500 p-4">
        <Loader2 className="h-4 w-4 animate-spin" />
        <span>{i18n.t('literals.bank-integracio-allapot-betoltese')}</span>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="section-title">{i18n.t('literals.bank-api-integracio-allapota')}</h2>
        <button
          className="form-button flex items-center gap-1"
          onClick={() => void handleRefresh()}
          disabled={refreshing}
        >
          {refreshing ? <Loader2 size={14} className="animate-spin" /> : <RefreshCw size={14} />}
          {i18n.t('literals.frissites')}
        </button>
      </div>

      <div className="rounded border border-blue-200 bg-blue-50 p-3 text-sm text-blue-800">
        <strong>{i18n.t('literals.forras-3')}</strong>
        {i18n.t('literals.a-felmeres-valuta-kosa-tervezes-es-fejle')}
        <code>{i18n.t('literals.mnb-hu')}</code>
        {i18n.t('literals.arfolyam-webservice')}{' '}
        <code>{i18n.t('literals.api-rbinternational-com')}</code>
        {i18n.t('literals.az-mnb-es-raiffeisen-arfolyam-letoltes-a')}
      </div>

      {status && (
        <>
          {/* MNB */}
          <div className="p-3 rounded border border-gray-200 bg-white">
            <h3 className="font-medium text-gray-800 mb-2">
              {i18n.t('literals.mnb-magyar-nemzeti-bank')}
            </h3>
            <div className="grid grid-cols-2 gap-2 text-sm">
              <div>{i18n.t('literals.cache-valuta')}</div>
              <div className="font-mono">
                {status.mnb.rateCount}
                {i18n.t('literals.db')}
              </div>

              <div>{i18n.t('literals.utolso-sikeres-letoltes')}</div>
              <div className="flex items-center gap-1">
                {status.mnb.lastFetchSuccess ? (
                  <CheckCircle2 size={14} className="text-green-600" />
                ) : (
                  <AlertCircle size={14} className="text-red-600" />
                )}
                {status.mnb.lastFetchDate ?? '—'}
              </div>

              <div>{i18n.t('literals.scheduler')}</div>
              <div>{status.mnb.schedulerActive ? '✅ aktív' : '❌ inaktív'}</div>
            </div>
          </div>

          {/* Raiffeisen */}
          <div className="p-3 rounded border border-gray-200 bg-white">
            <h3 className="font-medium text-gray-800 mb-2">{i18n.t('literals.raiffeisen-bank')}</h3>
            <div className="grid grid-cols-2 gap-2 text-sm">
              <div>{i18n.t('literals.scheduler')}</div>
              <div>{status.raiffeisen.schedulerActive ? '✅ aktív' : '❌ inaktív'}</div>

              <div>{i18n.t('literals.utemezes')}</div>
              <div className="font-mono">{status.raiffeisen.scheduledTime}</div>

              <div>{i18n.t('literals.integracio')}</div>
              <div>{status.raiffeisen.enabled ? '✅ engedélyezve' : '❌ tiltva'}</div>

              <div>{i18n.t('literals.endpoint')}</div>
              <div>{status.raiffeisen.endpointConfigured ? 'beállítva' : 'hiányzik'}</div>

              <div>{i18n.t('literals.utolso-futas')}</div>
              <div className="font-mono">{status.raiffeisen.lastRunStatus ?? '—'}</div>
            </div>
          </div>

          {/* Darius */}
          <div className="p-3 rounded border border-amber-200 bg-amber-50">
            <h3 className="font-medium text-gray-800 mb-2">
              {i18n.t('literals.darius-napi-jelentes')}
              {status.darius.currentMonth}
              {i18n.t('literals.lit-2')}
            </h3>
            <div className="grid grid-cols-2 gap-2 text-sm">
              <div>{i18n.t('literals.idoszak-3')}</div>
              <div className="font-mono">
                {status.darius.periodStart}
                {i18n.t('literals.lit-56')}
                {status.darius.periodEnd}
              </div>

              <div>{i18n.t('literals.bekuldve')}</div>
              <div className="font-mono text-green-700">
                {status.darius.submittedReportsCount}
                {i18n.t('literals.db')}
              </div>

              <div>{i18n.t('literals.folyamatban-generated')}</div>
              <div className="font-mono text-yellow-700">
                {status.darius.pendingReportsCount}
                {i18n.t('literals.db')}
              </div>

              <div>{i18n.t('literals.sikertelen-failed')}</div>
              <div className="font-mono text-red-700">
                {status.darius.failedReportsCount}
                {i18n.t('literals.db')}
              </div>

              <div>{i18n.t('literals.utolso-bekuldes')}</div>
              <div className="font-mono">{status.darius.lastSubmittedAt ?? '—'}</div>

              <div>{i18n.t('literals.transport')}</div>
              <div className="font-mono">{status.darius.transportMode}</div>
            </div>
            {status.darius.failedReportsCount > 0 && (
              <div className="mt-2 text-sm text-red-700">
                {i18n.t('literals.sikertelen-jelentesek-kerjuk-lepj-a-dari')}
              </div>
            )}
          </div>

          <div className="text-xs text-gray-500">
            {i18n.t('literals.ellenorizve')}
            {status.checkedAt}
          </div>
        </>
      )}

      <div className="p-3 rounded border border-gray-200 bg-white">
        <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h3 className="font-medium text-gray-800">
              {i18n.t('literals.bank-api-konfiguracio')}
            </h3>
            <p className="text-xs text-gray-500">
              {i18n.t('literals.secret-ertek-nem-jelenik-meg-a-mezo-ures')}
            </p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <button
              type="button"
              className="form-button inline-flex min-h-10 items-center justify-center gap-1"
              onClick={() => void handleFetchRaiffeisenNow()}
              disabled={fetchingRaiffeisen || configLoading}
            >
              {fetchingRaiffeisen ? (
                <Loader2 size={14} className="animate-spin" />
              ) : (
                <Play size={14} />
              )}
              {i18n.t('literals.raiffeisen-kezi-fetch')}
            </button>
            <button
              type="button"
              className="form-button-primary inline-flex min-h-10 items-center justify-center gap-1"
              onClick={() => void handleSaveConfig()}
              disabled={savingConfig || configLoading}
            >
              {savingConfig ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
              {i18n.t('literals.mentes-2')}
            </button>
          </div>
        </div>

        {configLoading && !raiffeisenConfig ? (
          <div className="flex items-center gap-2 text-sm text-gray-500">
            <Loader2 className="h-4 w-4 animate-spin" />
            {i18n.t('literals.bank-api-konfiguracio-betoltese')}
          </div>
        ) : (
          <div className="grid gap-3 lg:grid-cols-[minmax(0,1fr)_minmax(260px,340px)]">
            <div className="grid gap-3 sm:grid-cols-2">
              <div>
                <label className="form-label" htmlFor="bank-api-mode">
                  {i18n.t('literals.mod-2')}
                </label>
                <select
                  id="bank-api-mode"
                  className="form-input w-full"
                  value={configForm.mode}
                  onChange={(event) =>
                    setConfigForm((prev) => ({ ...prev, mode: event.target.value }))
                  }
                >
                  <option value="HTML_SCRAPING_FALLBACK">
                    {i18n.t('literals.html-scraping-fallback')}
                  </option>
                  <option value="REST_PRIMARY_WITH_HTML_FALLBACK">
                    {i18n.t('literals.rest-elsodleges-html-fallback')}
                  </option>
                  <option value="DISABLED">{i18n.t('literals.tiltva')}</option>
                </select>
              </div>
              <div>
                <label className="form-label" htmlFor="bank-api-auth-type">
                  {i18n.t('literals.auth-tipus')}
                </label>
                <select
                  id="bank-api-auth-type"
                  className="form-input w-full"
                  value={configForm.authType}
                  onChange={(event) =>
                    setConfigForm((prev) => ({ ...prev, authType: event.target.value }))
                  }
                >
                  <option value="NONE">{i18n.t('literals.nincs')}</option>
                  <option value="OAUTH2_CLIENT_CREDENTIALS">
                    {i18n.t('literals.oauth2-client-credentials')}
                  </option>
                  <option value="OAUTH2_MTLS">{i18n.t('literals.oauth2-mtls')}</option>
                </select>
              </div>
              <div className="sm:col-span-2">
                <label className="form-label" htmlFor="bank-api-endpoint">
                  {i18n.t('literals.endpoint-url')}
                </label>
                <input
                  id="bank-api-endpoint"
                  className="form-input w-full"
                  value={configForm.endpointUrl}
                  onChange={(event) =>
                    setConfigForm((prev) => ({ ...prev, endpointUrl: event.target.value }))
                  }
                  placeholder="https://..."
                />
              </div>
              <div>
                <label className="form-label" htmlFor="bank-api-client-id">
                  {i18n.t('literals.client-id')}
                </label>
                <input
                  id="bank-api-client-id"
                  className="form-input w-full"
                  value={configForm.clientId}
                  onChange={(event) =>
                    setConfigForm((prev) => ({ ...prev, clientId: event.target.value }))
                  }
                />
              </div>
              <div>
                <label className="form-label" htmlFor="bank-api-client-secret">
                  {i18n.t('literals.client-secret')}
                </label>
                <input
                  id="bank-api-client-secret"
                  type="password"
                  className="form-input w-full"
                  value={configForm.clientSecret}
                  onChange={(event) =>
                    setConfigForm((prev) => ({ ...prev, clientSecret: event.target.value }))
                  }
                  placeholder={
                    raiffeisenConfig?.clientSecretConfigured ? 'Már beállítva' : 'Nincs beállítva'
                  }
                  autoComplete="new-password"
                />
              </div>
              <div>
                <label className="form-label" htmlFor="bank-api-mtls-alias">
                  {i18n.t('literals.mtls-certificate-alias')}
                </label>
                <input
                  id="bank-api-mtls-alias"
                  className="form-input w-full"
                  value={configForm.mtlsCertificateAlias}
                  onChange={(event) =>
                    setConfigForm((prev) => ({ ...prev, mtlsCertificateAlias: event.target.value }))
                  }
                />
              </div>
              <div>
                <label className="form-label" htmlFor="bank-api-frequency">
                  {i18n.t('literals.utemezes-2')}
                </label>
                <input
                  id="bank-api-frequency"
                  className="form-input w-full"
                  value={configForm.updateFrequency}
                  onChange={(event) =>
                    setConfigForm((prev) => ({ ...prev, updateFrequency: event.target.value }))
                  }
                />
              </div>
              <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
                <input
                  type="checkbox"
                  checked={configForm.enabled}
                  onChange={(event) =>
                    setConfigForm((prev) => ({ ...prev, enabled: event.target.checked }))
                  }
                />
                {i18n.t('literals.raiffeisen-integracio-engedelyezve')}
              </label>
            </div>

            <div className="rounded border border-gray-200 bg-gray-50 p-3 text-sm">
              <div className="font-semibold text-gray-800">
                {i18n.t('literals.konfiguracios-statusz')}
              </div>
              <div className="mt-2 grid grid-cols-2 gap-2">
                <span>{i18n.t('literals.provider')}</span>
                <span className="font-mono">
                  {raiffeisenConfig?.providerName ?? RAIFFEISEN_PROVIDER}
                </span>
                <span>{i18n.t('literals.listaelemek')}</span>
                <span className="font-mono">{configs.length}</span>
                <span>{i18n.t('literals.secret')}</span>
                <span>{raiffeisenConfig?.clientSecretConfigured ? 'beállítva' : 'nincs'}</span>
                <span>{i18n.t('literals.utolso-futas-2')}</span>
                <span className="break-words font-mono">
                  {raiffeisenConfig?.lastRunStatus ?? '—'}
                </span>
                <span>{i18n.t('literals.frissitve-3')}</span>
                <span className="break-words font-mono">{raiffeisenConfig?.updatedAt ?? '—'}</span>
              </div>
              {raiffeisenConfig?.lastRunMessage && (
                <div className="mt-3 break-words rounded border border-gray-200 bg-white p-2 text-xs text-gray-600">
                  {raiffeisenConfig.lastRunMessage}
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
