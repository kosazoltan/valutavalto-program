import { useEffect, useState } from 'react'
import { diagnosticsApi, ErrorSummary, ClientErrorLog } from '../../services/api/diagnostics'
import { logger } from '../../utils/logger'

/**
 * Admin Hiba-Monitor Dashboard.
 *
 * <p>A V182 client_error_log tábla read-only áttekintése. Admin/manager/supervisor
 * role-nak látható. Megmutatja:</p>
 * <ul>
 *   <li>Aggregált statisztika (24 óra / 7 nap / 30 nap)</li>
 *   <li>Komponens-szerinti megoszlás (utolsó 7 nap)</li>
 *   <li>Verzió-szerinti megoszlás (utolsó 7 nap)</li>
 *   <li>Lapozható hiba-lista</li>
 * </ul>
 *
 * Hivatkozás: docs/operations/monitoring-runbook.md
 */
export default function ErrorMonitorPage() {
  const [summary, setSummary] = useState<ErrorSummary | null>(null)
  const [errors, setErrors] = useState<ClientErrorLog[]>([])
  const [page, setPage] = useState(0)
  const [totalPages, setTotalPages] = useState(1)
  const [selectedError, setSelectedError] = useState<ClientErrorLog | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)
  const [detailError, setDetailError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    const load = async () => {
      setLoading(true)
      setError(null)
      try {
        const [summaryData, listData] = await Promise.all([
          diagnosticsApi.getErrorSummary(),
          diagnosticsApi.listErrors(page, 50),
        ])
        if (!cancelled) {
          setSummary(summaryData)
          setErrors(listData.content)
          setTotalPages(listData.totalPages)
        }
      } catch (err) {
        logger.error('ErrorMonitorPage', 'Hiba az adatok betöltésekor:', err)
        if (!cancelled) {
          setError(err instanceof Error ? err.message : 'Ismeretlen hiba a betöltésnél')
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    void load()
    return () => {
      cancelled = true
    }
  }, [page])

  const openErrorDetails = async (entry: ClientErrorLog) => {
    setSelectedError(entry)
    setDetailLoading(true)
    setDetailError(null)
    try {
      setSelectedError(await diagnosticsApi.getError(entry.id))
    } catch (err) {
      logger.error('ErrorMonitorPage', 'Hibarészlet betöltése sikertelen:', err)
      setDetailError(err instanceof Error ? err.message : 'Ismeretlen hiba a részletlekérésnél')
    } finally {
      setDetailLoading(false)
    }
  }

  if (loading && !summary) {
    return <div className="p-6">Betöltés…</div>
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="rounded border border-red-300 bg-red-50 p-4 text-red-800">
          Hiba a betöltésnél: {error}
        </div>
      </div>
    )
  }

  return (
    <div className="p-6 space-y-6">
      <header>
        <h1 className="text-2xl font-bold">Hiba-monitor</h1>
        <p className="text-sm text-gray-600">
          Kliens-oldali hibajelentések — automatikusan érkeznek a Pénztár klienseiről.
          {summary?.generatedAt && (
            <span className="ml-2 text-gray-400">
              (Frissítve: {new Date(summary.generatedAt).toLocaleString('hu-HU')})
            </span>
          )}
        </p>
      </header>

      {summary && (
        <>
          <section className="grid grid-cols-2 gap-4 md:grid-cols-4">
            <SummaryCard label="Összes (valaha)" value={summary.totalAllTime} />
            <SummaryCard
              label="Utolsó 24 óra"
              value={summary.last24h}
              highlight={summary.last24h > 10}
            />
            <SummaryCard label="Utolsó 7 nap" value={summary.last7d} />
            <SummaryCard label="Utolsó 30 nap" value={summary.last30d} />
          </section>

          <section className="grid gap-4 md:grid-cols-2">
            <BreakdownTable
              title="Komponens-megoszlás (7 nap)"
              rows={summary.componentBreakdown7d.map((c) => ({
                key: c.component,
                count: c.errorCount,
              }))}
            />
            <BreakdownTable
              title="Verzió-megoszlás (7 nap)"
              rows={summary.versionBreakdown7d.map((v) => ({
                key: v.version,
                count: v.errorCount,
              }))}
            />
          </section>
        </>
      )}

      <section>
        <h2 className="mb-3 text-lg font-semibold">Hibanapló (lapozható)</h2>
        <div className="overflow-x-auto rounded border border-gray-200">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-left">
              <tr>
                <th className="p-2">Idő</th>
                <th className="p-2">Komponens</th>
                <th className="p-2">Verzió</th>
                <th className="p-2">Felhasználó</th>
                <th className="p-2">Hibaüzenet</th>
                <th className="p-2"></th>
              </tr>
            </thead>
            <tbody>
              {errors.length === 0 && (
                <tr>
                  <td colSpan={6} className="p-4 text-center text-gray-500">
                    Nincs jelentett hiba. Ez jó hír.
                  </td>
                </tr>
              )}
              {errors.map((e) => (
                <tr key={e.id} className="border-t border-gray-100 hover:bg-gray-50">
                  <td className="p-2 whitespace-nowrap">
                    {new Date(e.createdAt).toLocaleString('hu-HU')}
                  </td>
                  <td className="p-2">{e.component}</td>
                  <td className="p-2">{e.version ?? '-'}</td>
                  <td className="p-2">{e.userIdentifier ?? '-'}</td>
                  <td className="p-2 max-w-md truncate" title={e.errorMessage}>
                    {e.errorMessage}
                  </td>
                  <td className="p-2">
                    <button
                      onClick={() => void openErrorDetails(e)}
                      className="text-blue-600 hover:underline"
                    >
                      Részletek
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="mt-3 flex items-center justify-between">
          <span className="text-sm text-gray-600">
            Oldal {page + 1} / {Math.max(totalPages, 1)}
          </span>
          <div className="space-x-2">
            <button
              disabled={page === 0}
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              className="rounded border px-3 py-1 disabled:opacity-50"
            >
              ← Előző
            </button>
            <button
              disabled={page + 1 >= totalPages}
              onClick={() => setPage((p) => p + 1)}
              className="rounded border px-3 py-1 disabled:opacity-50"
            >
              Következő →
            </button>
          </div>
        </div>
      </section>

      {selectedError && (
        <ErrorDetailModal
          error={selectedError}
          loading={detailLoading}
          detailError={detailError}
          onClose={() => setSelectedError(null)}
        />
      )}
    </div>
  )
}

function SummaryCard({
  label,
  value,
  highlight,
}: {
  label: string
  value: number
  highlight?: boolean
}) {
  return (
    <div
      className={`rounded border p-4 ${highlight ? 'border-red-300 bg-red-50' : 'border-gray-200 bg-white'}`}
    >
      <div className="text-sm text-gray-600">{label}</div>
      <div className={`text-2xl font-bold ${highlight ? 'text-red-700' : 'text-gray-900'}`}>
        {value}
      </div>
    </div>
  )
}

function BreakdownTable({
  title,
  rows,
}: {
  title: string
  rows: { key: string; count: number }[]
}) {
  return (
    <div className="rounded border border-gray-200">
      <h3 className="border-b bg-gray-50 p-2 font-semibold">{title}</h3>
      <table className="w-full text-sm">
        <tbody>
          {rows.length === 0 && (
            <tr>
              <td colSpan={2} className="p-2 text-center text-gray-500">
                Nincs adat
              </td>
            </tr>
          )}
          {rows.map((r) => (
            <tr key={r.key} className="border-t">
              <td className="p-2">{r.key}</td>
              <td className="p-2 text-right font-mono">{r.count}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function ErrorDetailModal({
  error,
  loading,
  detailError,
  onClose,
}: {
  error: ClientErrorLog
  loading: boolean
  detailError: string | null
  onClose: () => void
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="max-h-[90vh] w-full max-w-3xl overflow-auto rounded bg-white p-6 shadow-lg">
        <div className="mb-4 flex items-start justify-between">
          <h2 className="text-lg font-bold">Hiba #{error.id}</h2>
          <button onClick={onClose} className="text-gray-500 hover:text-gray-700">
            ✕
          </button>
        </div>
        {loading && (
          <div className="mb-3 rounded border border-blue-200 bg-blue-50 p-2 text-sm text-blue-800">
            Részletek betöltése…
          </div>
        )}
        {detailError && (
          <div className="mb-3 rounded border border-amber-200 bg-amber-50 p-2 text-sm text-amber-800">
            A teljes hibarészlet nem tölthető be: {detailError}
          </div>
        )}
        <dl className="space-y-2 text-sm">
          <Row label="Idő">{new Date(error.createdAt).toLocaleString('hu-HU')}</Row>
          <Row label="Komponens">{error.component}</Row>
          <Row label="Verzió">{error.version ?? '-'}</Row>
          <Row label="OS">{error.osInfo ?? '-'}</Row>
          <Row label="Felhasználó">{error.userIdentifier ?? '-'}</Row>
          <Row label="Kliens IP">{error.clientIp ?? '-'}</Row>
          <Row label="User-Agent">{error.userAgent ?? '-'}</Row>
          <Row label="Üzenet">
            <pre className="whitespace-pre-wrap font-mono text-xs">{error.errorMessage}</pre>
          </Row>
          {error.stackTrace && (
            <Row label="Stack trace">
              <pre className="whitespace-pre-wrap rounded bg-gray-100 p-2 font-mono text-xs">
                {error.stackTrace}
              </pre>
            </Row>
          )}
          {error.contextJson && (
            <Row label="Kontextus">
              <pre className="whitespace-pre-wrap rounded bg-gray-100 p-2 font-mono text-xs">
                {error.contextJson}
              </pre>
            </Row>
          )}
        </dl>
      </div>
    </div>
  )
}

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="grid grid-cols-[120px_1fr] gap-2">
      <dt className="text-gray-600">{label}</dt>
      <dd>{children}</dd>
    </div>
  )
}
