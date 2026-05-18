import { useCallback, useEffect, useRef, useState } from 'react'
import {
  auditDiagnosticsApi,
  type AuditLogEntry,
  type ErrorCodeCatalog,
  type HashChainIntegrityResponse,
} from '../../services/api/diagnostics'
import { vvLogger } from '../../utils/vvLogger'

/**
 * Admin Audit-Diagnosztika Dashboard (V234 belso log+audit modul).
 *
 * Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md (4.5)
 *
 * Funkciok:
 * - Utolso 100 audit-bejegyzes (legujabb elol)
 * - Trace-ID szerinti korrelacios kereses (kliens-backend lanc)
 * - Hash-chain integritas-ellenorzes (tamper-detection)
 * - Error-code katalogus (packages/shared-logging/error-codes.yaml)
 *
 * Csak ADMIN / SUPPORT / MANAGER szerepkor lathatja.
 */
export default function AuditDiagnosticsPage() {
  const [entries, setEntries] = useState<AuditLogEntry[]>([])
  const [catalog, setCatalog] = useState<ErrorCodeCatalog | null>(null)
  const [traceQuery, setTraceQuery] = useState('')
  const [traceResults, setTraceResults] = useState<AuditLogEntry[] | null>(null)
  const [integrity, setIntegrity] = useState<HashChainIntegrityResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedEntry, setSelectedEntry] = useState<AuditLogEntry | null>(null)

  const loadInitial = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [recent, codes] = await Promise.all([
        auditDiagnosticsApi.recentErrors(100),
        auditDiagnosticsApi.errorCodes(),
      ])
      setEntries(recent)
      setCatalog(codes)
    } catch (err) {
      vvLogger.error(
        'VV-TECH-002',
        'admin.diagnostics.load_failed',
        err,
        { page: 'AuditDiagnosticsPage' },
      )
      setError(err instanceof Error ? err.message : 'Ismeretlen hiba a betoltesnel')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadInitial()
  }, [loadInitial])

  const onTraceSearch = async () => {
    if (!traceQuery.trim()) return
    try {
      const r = await auditDiagnosticsApi.byTrace(traceQuery.trim())
      setTraceResults(r)
    } catch (err) {
      vvLogger.warn('admin.diagnostics.trace_search_failed', 'VV-TECH-002', {
        traceId: traceQuery,
        error: err instanceof Error ? err.message : String(err),
      })
      setTraceResults([])
    }
  }

  const onVerifyHashChain = async () => {
    try {
      const result = await auditDiagnosticsApi.verifyHashChain(200)
      setIntegrity(result)
    } catch (err) {
      vvLogger.error('VV-TECH-002', 'admin.diagnostics.hash_chain_verify_failed', err)
    }
  }

  if (loading) {
    return <div className="p-6">Audit-diagnosztikai adatok betoltese...</div>
  }

  if (error) {
    return (
      <div className="p-6">
        <h1 className="text-2xl font-bold mb-4">Audit Diagnosztika</h1>
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
          Hiba: {error}
        </div>
      </div>
    )
  }

  return (
    <div className="p-6 space-y-6">
      <header>
        <h1 className="text-2xl font-bold">Audit Diagnosztika (V234)</h1>
        <p className="text-sm text-gray-600">
          AI-olvashato belso log+audit modul - utolso 100 esemeny + hash-chain integritas-check
        </p>
      </header>

      {/* Hash-chain integritas check */}
      <section className="bg-white shadow rounded p-4">
        <div className="flex items-center justify-between mb-2">
          <h2 className="text-lg font-semibold">Hash-chain integritas</h2>
          <button
            type="button"
            onClick={onVerifyHashChain}
            className="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded text-sm"
          >
            Ellenorzes (utolso 200)
          </button>
        </div>
        {integrity && (
          <div
            className={`mt-2 p-3 rounded ${
              integrity.intact
                ? 'bg-green-100 border border-green-400 text-green-800'
                : 'bg-red-100 border border-red-400 text-red-800'
            }`}
          >
            <div className="font-semibold">
              {integrity.intact ? 'OK - chain ertintetlen' : 'SERTETT - tamper detektalva!'}
            </div>
            <div className="text-sm">{integrity.message}</div>
            {integrity.firstBrokenEntryId && (
              <div className="text-xs mt-1">
                Elso problemás sor ID: <code>{integrity.firstBrokenEntryId}</code>
              </div>
            )}
          </div>
        )}
      </section>

      {/* Trace-ID korrelacios kereses */}
      <section className="bg-white shadow rounded p-4">
        <h2 className="text-lg font-semibold mb-2">Trace-ID korrelacio (kliens-backend lanc)</h2>
        <div className="flex gap-2">
          <input
            type="text"
            value={traceQuery}
            onChange={(e) => setTraceQuery(e.target.value)}
            placeholder="trace_id (32 hex karakter)"
            className="flex-1 px-3 py-2 border rounded font-mono text-sm"
          />
          <button
            type="button"
            onClick={onTraceSearch}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded"
          >
            Kereses
          </button>
        </div>
        {traceResults !== null && (
          <div className="mt-3 text-sm">
            <strong>{traceResults.length}</strong> esemeny ehhez a trace-hez.
            <ul className="mt-2 space-y-1">
              {traceResults.map((e) => (
                <li key={e.id} className="border-b py-1">
                  <span className="font-mono text-xs text-gray-500">{e.ts}</span>{' '}
                  <span className="font-semibold">{e.eventType ?? e.action}</span>{' '}
                  <span className="text-gray-600">{e.entityType}#{e.entityId}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </section>

      {/* Utolso 100 esemeny */}
      <section className="bg-white shadow rounded p-4">
        <h2 className="text-lg font-semibold mb-2">Utolso 100 audit-esemeny</h2>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-3 py-2 text-left font-medium">Ido</th>
                <th className="px-3 py-2 text-left font-medium">Event type</th>
                <th className="px-3 py-2 text-left font-medium">Entity</th>
                <th className="px-3 py-2 text-left font-medium">Worker</th>
                <th className="px-3 py-2 text-left font-medium">Amount</th>
                <th className="px-3 py-2 text-left font-medium">Trace</th>
                <th className="px-3 py-2"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {entries.map((e) => (
                <tr key={e.id} className="hover:bg-gray-50">
                  <td className="px-3 py-2 font-mono text-xs whitespace-nowrap">{e.ts}</td>
                  <td className="px-3 py-2">{e.eventType ?? e.action}</td>
                  <td className="px-3 py-2 text-xs">
                    {e.entityType}
                    {e.entityId && <span className="text-gray-500">#{e.entityId.substring(0, 8)}</span>}
                  </td>
                  <td className="px-3 py-2 text-xs">{e.userName}</td>
                  <td className="px-3 py-2 text-right font-mono">
                    {e.amount && (
                      <>
                        {e.amount} {e.currency}
                      </>
                    )}
                  </td>
                  <td className="px-3 py-2 font-mono text-xs">
                    {e.traceId && e.traceId.substring(0, 8)}
                  </td>
                  <td className="px-3 py-2 text-right">
                    <button
                      type="button"
                      onClick={() => setSelectedEntry(e)}
                      className="text-blue-600 hover:underline text-xs"
                    >
                      Reszletek
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      {/* Error-code katalogus */}
      {catalog && (
        <section className="bg-white shadow rounded p-4">
          <h2 className="text-lg font-semibold mb-2">
            AI-olvashato hibakod-katalogus (v{catalog.version}, {catalog.totalCodes} kod)
          </h2>
          <div className="overflow-x-auto max-h-96 overflow-y-auto">
            <table className="min-w-full divide-y divide-gray-200 text-sm">
              <thead className="bg-gray-50 sticky top-0">
                <tr>
                  <th className="px-3 py-2 text-left font-medium">Kod</th>
                  <th className="px-3 py-2 text-left font-medium">Kategoria</th>
                  <th className="px-3 py-2 text-left font-medium">Szint</th>
                  <th className="px-3 py-2 text-left font-medium">Felhasznaloi hatas</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {catalog.codes.map((c) => (
                  <tr key={c.code} className="hover:bg-gray-50">
                    <td className="px-3 py-2 font-mono font-semibold">{c.code}</td>
                    <td className="px-3 py-2">{c.category}</td>
                    <td className="px-3 py-2">{c.level}</td>
                    <td className="px-3 py-2 text-xs">{c.userImpact}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>
      )}

      {selectedEntry && <AuditEntryModal entry={selectedEntry} onClose={() => setSelectedEntry(null)} />}
    </div>
  )
}

/**
 * Copilot PR #681 P2 a11y: role=dialog + aria-modal + Escape-to-close + focus.
 */
function AuditEntryModal({
  entry,
  onClose,
}: {
  entry: AuditLogEntry
  onClose: () => void
}) {
  const closeButtonRef = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    closeButtonRef.current?.focus()
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKeyDown)
    return () => window.removeEventListener('keydown', onKeyDown)
  }, [onClose])

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="audit-modal-title"
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      onClick={onClose}
    >
      <div
        className="bg-white rounded-lg p-6 max-w-3xl w-full max-h-[80vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <h3 id="audit-modal-title" className="text-lg font-bold mb-2">
          Audit-esemeny reszletei
        </h3>
        <pre className="bg-gray-100 p-3 rounded text-xs overflow-x-auto">
          {JSON.stringify(entry, null, 2)}
        </pre>
        <div className="mt-4 text-right">
          <button
            ref={closeButtonRef}
            type="button"
            onClick={onClose}
            className="px-4 py-2 bg-gray-600 hover:bg-gray-700 text-white rounded"
          >
            Bezaras (Esc)
          </button>
        </div>
      </div>
    </div>
  )
}
