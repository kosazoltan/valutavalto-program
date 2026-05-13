import { useState, useEffect, useCallback } from 'react'
import { Loader2, RefreshCw, AlertCircle, CheckCircle2 } from 'lucide-react'
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

/**
 * v2.5.50 Sprint 2: Bank API integráció admin monitoring.
 *
 * Megjeleníti az MNB, Raiffeisen és Darius integráció állapotát.
 * Manual refresh és Darius retry triggerek.
 */
export default function BankIntegrationStatusPage() {
  const [status, setStatus] = useState<BankIntegrationStatusResponse | null>(null)
  const [loading, setLoading] = useState(false)
  const [refreshing, setRefreshing] = useState(false)

  const loadStatus = useCallback(async () => {
    setLoading(true)
    try {
      const response = await api.get<BankIntegrationStatusResponse>('/admin/bank-integration/status')
      setStatus(response.data)
    } catch (err) {
      logger.error('BankIntegrationStatus', 'Status betöltési hiba:', err)
      toast.error('Hiba', 'Bank integráció állapot lekérdezése sikertelen')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadStatus()
  }, [loadStatus])

  const handleRefresh = async () => {
    setRefreshing(true)
    await loadStatus()
    setRefreshing(false)
    toast.success('Frissítve', 'Bank integráció állapot újraolvasva')
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
        <strong>Forrás:</strong> A `Felmérés/Valuta/Kósa Tervezés és fejlesztés/Bank API/API_bank.docx`
        két publikus URL-t hivatkozott: <code>mnb.hu</code> árfolyam webservice + <code>api.rbinternational.com</code>.
        Az MNB és Raiffeisen árfolyam-letöltés AUTOMATIKUS. A Darius napi jelentés outbox-fájl-alapú
        (manuálisan továbbítandó a banki rendszerbe egy compliance kolléga által).
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
            </div>
          </div>

          {/* Darius */}
          <div className="p-3 rounded border border-amber-200 bg-amber-50">
            <h3 className="font-medium text-gray-800 mb-2">Darius napi jelentés ({status.darius.currentMonth})</h3>
            <div className="grid grid-cols-2 gap-2 text-sm">
              <div>Időszak:</div>
              <div className="font-mono">{status.darius.periodStart} → {status.darius.periodEnd}</div>

              <div>Beküldve:</div>
              <div className="font-mono text-green-700">{status.darius.submittedReportsCount} db</div>

              <div>Folyamatban (GENERATED):</div>
              <div className="font-mono text-yellow-700">{status.darius.pendingReportsCount} db</div>

              <div>Sikertelen (FAILED):</div>
              <div className="font-mono text-red-700">{status.darius.failedReportsCount} db</div>

              <div>Utolsó beküldés:</div>
              <div className="font-mono">{status.darius.lastSubmittedAt ?? '—'}</div>

              <div>Transport:</div>
              <div className="font-mono">{status.darius.transportMode}</div>
            </div>
            {status.darius.failedReportsCount > 0 && (
              <div className="mt-2 text-sm text-red-700">
                ⚠️ Sikertelen jelentések — kérjük, lépj a Darius riport admin oldalra a retry futtatáshoz.
              </div>
            )}
          </div>

          <div className="text-xs text-gray-500">
            Ellenőrizve: {status.checkedAt}
          </div>
        </>
      )}
    </div>
  )
}
