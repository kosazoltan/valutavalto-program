import { useCallback, useEffect, useRef, useState } from 'react'
import {
  auditDiagnosticsApi,
  diagnosticsApi,
  type AuditLogEntry,
  type DiagnosticsHealth,
  type ErrorCodeCatalog,
  type HashChainIntegrityResponse,
  type StaticAuditCheck,
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
  const [errorEntries, setErrorEntries] = useState<AuditLogEntry[]>([])
  const [catalog, setCatalog] = useState<ErrorCodeCatalog | null>(null)
  const [traceQuery, setTraceQuery] = useState('')
  const [traceResults, setTraceResults] = useState<AuditLogEntry[] | null>(null)
  const [integrity, setIntegrity] = useState<HashChainIntegrityResponse | null>(null)
  const [staticAuditToken, setStaticAuditToken] = useState('')
  const [staticAuditChecks, setStaticAuditChecks] = useState<StaticAuditCheck[] | null>(null)
  const [staticAuditLoading, setStaticAuditLoading] = useState(false)
  const [staticAuditError, setStaticAuditError] = useState<string | null>(null)
  const [health, setHealth] = useState<DiagnosticsHealth | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedEntry, setSelectedEntry] = useState<AuditLogEntry | null>(null)

  const loadInitial = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [recent, recentErrors, codes, healthStatus] = await Promise.all([
        auditDiagnosticsApi.recent(100),
        auditDiagnosticsApi.recentErrors(100),
        auditDiagnosticsApi.errorCodes(),
        diagnosticsApi.health(),
      ])
      setEntries(recent)
      setErrorEntries(recentErrors)
      setCatalog(codes)
      setHealth(healthStatus)
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

  const onRunStaticAudit = async () => {
    try {
      setStaticAuditLoading(true)
      setStaticAuditError(null)
      setStaticAuditChecks(await auditDiagnosticsApi.staticAudit(staticAuditToken))
    } catch (err) {
      vvLogger.error('VV-TECH-002', 'admin.diagnostics.static_audit_failed', err)
      setStaticAuditChecks(null)
      setStaticAuditError(err instanceof Error ? err.message : 'Ismeretlen hiba a static audit futtatasnal')
    } finally {
      setStaticAuditLoading(false)
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

      <section className="grid gap-3 sm:grid-cols-3" data-testid="diagnostics-health-panel">
        <div className={`rounded border p-4 ${health?.ok ? 'border-green-200 bg-green-50 text-green-900' : 'border-amber-200 bg-amber-50 text-amber-900'}`}>
          <div className="text-sm font-semibold">Diagnostics ingest</div>
          <div className="mt-2 text-2xl font-bold">{health?.ok ? 'OK' : 'Nincs adat'}</div>
        </div>
        <div className="rounded border border-gray-200 bg-white p-4">
          <div className="text-sm font-semibold text-gray-700">DB-ben rögzített klienshibák</div>
          <div className="mt-2 text-2xl font-bold text-gray-900">{health?.totalReportedErrors ?? 0}</div>
        </div>
        <div className="rounded border border-gray-200 bg-white p-4">
          <div className="text-sm font-semibold text-gray-700">Katalógus</div>
          <div className="mt-2 text-2xl font-bold text-gray-900">{catalog?.totalCodes ?? 0}</div>
        </div>
      </section>

      {/* Static audit: /api/static-audit (nem /api/v1) */}
      <section className="bg-white shadow rounded p-4">
        <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
          <div className="min-w-0">
            <h2 className="text-lg font-semibold">Static audit</h2>
            <p className="mt-1 text-sm text-gray-600">
              DB kapcsolat, kotelezo kornyezeti valtozok es mail konfiguracio gyors ellenorzese.
            </p>
          </div>
          <div className="grid w-full gap-2 md:w-auto md:min-w-[24rem] md:grid-cols-[minmax(0,1fr)_auto]">
            <label className="min-w-0">
              <span className="sr-only">Static audit admin token</span>
              <input
                type="password"
                value={staticAuditToken}
                onChange={(e) => setStaticAuditToken(e.target.value)}
                placeholder="Static audit admin token"
                className="w-full min-w-0 rounded border px-3 py-2 text-sm"
                autoComplete="off"
              />
            </label>
            <button
              type="button"
              onClick={onRunStaticAudit}
              disabled={staticAuditLoading}
              className="min-h-10 rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-60"
            >
              {staticAuditLoading ? 'Futtatas...' : 'Static audit futtatasa'}
            </button>
          </div>
        </div>

        {staticAuditError && (
          <div className="mt-3 rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
            Static audit hiba: {staticAuditError}
          </div>
        )}

        {staticAuditChecks && (
          <div className="mt-4 grid gap-2 sm:grid-cols-2 xl:grid-cols-3" data-testid="static-audit-results">
            {staticAuditChecks.map((check) => (
              <div
                key={check.name}
                className={`rounded border p-3 ${
                  check.pass
                    ? 'border-green-200 bg-green-50 text-green-900'
                    : 'border-red-200 bg-red-50 text-red-900'
                }`}
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0 break-words text-sm font-semibold">{check.name}</div>
                  <span className="shrink-0 rounded bg-white px-2 py-1 text-xs font-bold">
                    {check.pass ? 'OK' : 'FAIL'}
                  </span>
                </div>
                <div className="mt-2 break-words text-xs">{check.detail ?? '-'}</div>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Utolso hibas audit-bejegyzesek */}
      <section className="bg-white shadow rounded p-4">
        <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
          <h2 className="text-lg font-semibold">Hibas audit-esemenyek</h2>
          <span className="text-sm text-gray-600">{errorEntries.length} ERROR / WARN / FATAL sor</span>
        </div>
        {errorEntries.length === 0 ? (
          <p className="mt-3 rounded border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
            Nincs friss hibas audit-bejegyzes.
          </p>
        ) : (
          <div className="mt-3 grid gap-2 md:grid-cols-2">
            {errorEntries.slice(0, 4).map((e) => (
              <div key={e.id} className="rounded border border-amber-200 bg-amber-50 px-3 py-2">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0 break-words text-sm font-semibold text-amber-900">
                    {e.eventType ?? e.action ?? e.id}
                  </div>
                  <span className="shrink-0 rounded bg-white px-2 py-1 text-xs font-semibold text-amber-800">
                    {e.action ?? 'AUDIT'}
                  </span>
                </div>
                <div className="mt-1 break-all font-mono text-xs text-amber-800">{e.traceId ?? e.id}</div>
              </div>
            ))}
          </div>
        )}
      </section>

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
