import { useState, useEffect } from 'react'
import { History, RefreshCw } from 'lucide-react'
import { api } from '../../services/api/client'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface Publication {
  id: string
  templateId: string | null
  workgroupId: string
  publishedBy: number
  // FR-HL-11: a módosító NEVE (backend feloldja a workerId-ból); fallback "#<id>" ismeretlennél.
  publishedByName?: string
  publishedAt: string
  affectedBranches: number
  notes: string | null
}

export default function RatePublishHistory() {
  const { t } = useTranslation()
  const [publications, setPublications] = useState<Publication[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchHistory()
  }, [])

  const fetchHistory = async () => {
    setLoading(true)
    try {
      const res = await api.get<Publication[]>('/rate-management/publications')
      const publicationsData = safeArray<Publication>(res?.data)
      setPublications(publicationsData)
    } catch (err) {
      logger.error('RatePublishHistory', 'Lekérés sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold flex items-center gap-2">
          <History className="h-5 w-5" />
          {t('ratemanagement.publikalasiNaplo')}
        </h2>
        <button
          className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
          onClick={fetchHistory}
        >
          <RefreshCw className="h-4 w-4 mr-2" />
          {t('common.refresh')}
        </button>
      </div>

      {loading ? (
        <p>{i18n.t('literals.betoltes')}</p>
      ) : publications.length === 0 ? (
        <div className="text-center py-8 text-muted-foreground">
          {t('ratemanagement.nincsPublikalasiElozmeny')}
        </div>
      ) : (
        <div className="space-y-2">
          {publications.map((pub) => (
            <div key={pub.id} className="rounded-lg border bg-card shadow-sm">
              <div className="p-3 flex items-center justify-between">
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="font-medium">
                      {new Date(pub.publishedAt).toLocaleString('hu-HU')}
                    </span>
                    <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium border bg-transparent">
                      {pub.affectedBranches} {t('ratemanagement.iroda')}
                    </span>
                  </div>
                  {pub.notes && <p className="text-sm text-muted-foreground">{pub.notes}</p>}
                </div>
                <div className="text-right text-sm text-muted-foreground">
                  {/* FR-HL-11: a módosító NEVE (workerId helyett); fallback a workerId, ha nincs név. */}
                  <p>
                    {t('ratemanagement.publikalta')}
                    {pub.publishedByName ?? pub.publishedBy}
                  </p>
                  <p className="text-xs">
                    {pub.id.substring(0, 8)}
                    {i18n.t('literals.lit-16')}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
