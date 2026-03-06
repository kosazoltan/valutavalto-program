import { useState, useEffect } from 'react'
import { History, RefreshCw } from 'lucide-react'

interface Publication {
  id: string
  templateId: string | null
  workgroupId: string
  publishedBy: number
  publishedAt: string
  affectedBranches: number
  notes: string | null
}

export default function RatePublishHistory() {
  const [publications, setPublications] = useState<Publication[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchHistory()
  }, [])

  const fetchHistory = async () => {
    setLoading(true)
    try {
      const res = await fetch('/api/v1/rate-management/publications')
      if (res.ok) setPublications(await res.json())
    } catch (err) {
      console.error('Lekeres sikertelen:', err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold flex items-center gap-2">
          <History className="h-5 w-5" />
          Publikalasi naplo
        </h2>
        <button
          className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
          onClick={fetchHistory}
        >
          <RefreshCw className="h-4 w-4 mr-2" />
          Frissites
        </button>
      </div>

      {loading ? (
        <p>Betoltes...</p>
      ) : publications.length === 0 ? (
        <div className="text-center py-8 text-muted-foreground">Nincs publikalasi elozmeny</div>
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
                    <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium border bg-transparent">{pub.affectedBranches} iroda</span>
                  </div>
                  {pub.notes && <p className="text-sm text-muted-foreground">{pub.notes}</p>}
                </div>
                <div className="text-right text-sm text-muted-foreground">
                  <p>Publikalта: #{pub.publishedBy}</p>
                  <p className="text-xs">{pub.id.substring(0, 8)}...</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
