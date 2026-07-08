import { useState, useEffect, useCallback } from 'react'
import { Loader2, RefreshCw, AlertCircle, CheckCircle2, Play, Save } from 'lucide-react'
import { api } from '../../services/api/client'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'

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
        <span>Bank integráció állapot betöltése...</span>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="section-title">Bank API integráció állapota</h2>
        <button
          className="form-button flex items-center gap-1"
          onClick={() => void handleRefresh()}
          disabled={refreshing}
        >
          {refreshing ? <Loader2 size={14} className="animate-spin" /> : <RefreshCw size={14} />}
          Frissítés
        </button>
      </div>

      <div className="rounded border border-blue-200 bg-blue-50 p-3 text-sm text-blue-800">
        <strong>Forrás:</strong> A `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Bank
        API/API_bank.docx` két publikus URL-t hivatkozott: <code>mnb.hu</code> árfolyam webservice +{' '}
        <code>api.rbinternational.com</code>. Az MNB és Raiffeisen árfolyam-letöltés AUTOMATIKUS. A
        Darius napi jelentés outbox-fájl-alapú (manuálisan továbbítandó a banki rendszerbe egy
        compliance kolléga által).
      </div>

      {status && (
        <>
          {/* MNB */}
          <div className="p-3 rounded border border-gray-200 bg-white">
            <h3 className="font-medium text-gray-800 mb-2">MNB (Magyar Nemzeti Bank)</h3>
            <div className="grid grid-cols-2 gap-2 text-sm">
              <div>Cache valuta:</div>
              <div className="font-mono">{status.mnb.rateCount} db</div>

              <div>Utolsó sikeres letöltés:</div>
              <div className="flex items-center gap-1">
                {status.mnb.lastFetchSuccess ? (
                  <CheckCircle2 size={14} className="text-green-600" />
                ) : (
                  <AlertCircle size={14} className="text-red-600" />
                )}
                {status.mnb.lastFetchDate ?? '—'}
              </div>

              <div>Scheduler:</div>
              <div>{status.mnb.schedulerActive ? '✅ aktív' : '❌ inaktív'}</div>
            </div>
          </div>

          {/* Raiffeisen */}
          <div className="p-3 rounded border border-gray-200 bg-white">
            <h3 className="font-medium text-gray-800 mb-2">Raiffeisen Bank</h3>
            <div className="grid grid-cols-2 gap-2 text-sm">
              <div>Scheduler:</div>
              <div>{status.raiffeisen.schedulerActive ? '✅ aktív' : '❌ inaktív'}</div>

              <div>Ütemezés:</div>
              <div className="font-mono">{status.raiffeisen.scheduledTime}</div>

              <div>Integráció:</div>
              <div>{status.raiffeisen.enabled ? '✅ engedélyezve' : '❌ tiltva'}</div>

              <div>Endpoint:</div>
              <div>{status.raiffeisen.endpointConfigured ? 'beállítva' : 'hiányzik'}</div>

              <div>Utolsó futás:</div>
              <div className="font-mono">{status.raiffeisen.lastRunStatus ?? '—'}</div>
            </div>
          </div>

          {/* Darius */}
          <div className="p-3 rounded border border-amber-200 bg-amber-50">
            <h3 className="font-medium text-gray-800 mb-2">
              Darius napi jelentés ({status.darius.currentMonth})
            </h3>
            <div className="grid grid-cols-2 gap-2 text-sm">
              <div>Időszak:</div>
              <div className="font-mono">
                {status.darius.periodStart} → {status.darius.periodEnd}
              </div>

              <div>Beküldve:</div>
              <div className="font-mono text-green-700">
                {status.darius.submittedReportsCount} db
              </div>

              <div>Folyamatban (GENERATED):</div>
              <div className="font-mono text-yellow-700">
                {status.darius.pendingReportsCount} db
              </div>

              <div>Sikertelen (FAILED):</div>
              <div className="font-mono text-red-700">{status.darius.failedReportsCount} db</div>

              <div>Utolsó beküldés:</div>
              <div className="font-mono">{status.darius.lastSubmittedAt ?? '—'}</div>

              <div>Transport:</div>
              <div className="font-mono">{status.darius.transportMode}</div>
            </div>
            {status.darius.failedReportsCount > 0 && (
              <div className="mt-2 text-sm text-red-700">
                ⚠️ Sikertelen jelentések — kérjük, lépj a Darius riport admin oldalra a retry
                futtatáshoz.
              </div>
            )}
          </div>

          <div className="text-xs text-gray-500">Ellenőrizve: {status.checkedAt}</div>
        </>
      )}

      <div className="p-3 rounded border border-gray-200 bg-white">
        <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h3 className="font-medium text-gray-800">Bank API konfiguráció</h3>
            <p className="text-xs text-gray-500">
              Secret érték nem jelenik meg; a mező üresen hagyva nem írja felül a meglévő titkot.
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
              Raiffeisen kézi fetch
            </button>
            <button
              type="button"
              className="form-button-primary inline-flex min-h-10 items-center justify-center gap-1"
              onClick={() => void handleSaveConfig()}
              disabled={savingConfig || configLoading}
            >
              {savingConfig ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
              Mentés
            </button>
          </div>
        </div>

        {configLoading && !raiffeisenConfig ? (
          <div className="flex items-center gap-2 text-sm text-gray-500">
            <Loader2 className="h-4 w-4 animate-spin" />
            Bank API konfiguráció betöltése...
          </div>
        ) : (
          <div className="grid gap-3 lg:grid-cols-[minmax(0,1fr)_minmax(260px,340px)]">
            <div className="grid gap-3 sm:grid-cols-2">
              <div>
                <label className="form-label" htmlFor="bank-api-mode">
                  Mód
                </label>
                <select
                  id="bank-api-mode"
                  className="form-input w-full"
                  value={configForm.mode}
                  onChange={(event) =>
                    setConfigForm((prev) => ({ ...prev, mode: event.target.value }))
                  }
                >
                  <option value="HTML_SCRAPING_FALLBACK">HTML scraping fallback</option>
                  <option value="REST_PRIMARY_WITH_HTML_FALLBACK">
                    REST elsődleges + HTML fallback
                  </option>
                  <option value="DISABLED">Tiltva</option>
                </select>
              </div>
              <div>
                <label className="form-label" htmlFor="bank-api-auth-type">
                  Auth típus
                </label>
                <select
                  id="bank-api-auth-type"
                  className="form-input w-full"
                  value={configForm.authType}
                  onChange={(event) =>
                    setConfigForm((prev) => ({ ...prev, authType: event.target.value }))
                  }
                >
                  <option value="NONE">Nincs</option>
                  <option value="OAUTH2_CLIENT_CREDENTIALS">OAuth2 client credentials</option>
                  <option value="OAUTH2_MTLS">OAuth2 + mTLS</option>
                </select>
              </div>
              <div className="sm:col-span-2">
                <label className="form-label" htmlFor="bank-api-endpoint">
                  Endpoint URL
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
                  Client ID
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
                  Client secret
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
                  mTLS certificate alias
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
                  Ütemezés
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
                Raiffeisen integráció engedélyezve
              </label>
            </div>

            <div className="rounded border border-gray-200 bg-gray-50 p-3 text-sm">
              <div className="font-semibold text-gray-800">Konfigurációs státusz</div>
              <div className="mt-2 grid grid-cols-2 gap-2">
                <span>Provider</span>
                <span className="font-mono">
                  {raiffeisenConfig?.providerName ?? RAIFFEISEN_PROVIDER}
                </span>
                <span>Listaelemek</span>
                <span className="font-mono">{configs.length}</span>
                <span>Secret</span>
                <span>{raiffeisenConfig?.clientSecretConfigured ? 'beállítva' : 'nincs'}</span>
                <span>Utolsó futás</span>
                <span className="break-words font-mono">
                  {raiffeisenConfig?.lastRunStatus ?? '—'}
                </span>
                <span>Frissítve</span>
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
