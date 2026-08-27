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
import i18n from '../../i18n'

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
  const [entityTypeQuery, setEntityTypeQuery] = useState('')
  const [entityIdQuery, setEntityIdQuery] = useState('')
  const [entityResults, setEntityResults] = useState<AuditLogEntry[] | null>(null)
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
      vvLogger.error('VV-TECH-002', 'admin.diagnostics.load_failed', err, {
        page: 'AuditDiagnosticsPage',
      })
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

  const onEntitySearch = async () => {
    const entityType = entityTypeQuery.trim()
    const entityId = entityIdQuery.trim()
    if (!entityType || !entityId) return
    try {
      const r = await auditDiagnosticsApi.entityChain(entityType, entityId)
      setEntityResults(r)
    } catch (err) {
      vvLogger.warn('admin.diagnostics.entity_chain_failed', 'VV-TECH-002', {
        entityType,
        entityId,
        error: err instanceof Error ? err.message : String(err),
      })
      setEntityResults([])
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
      setStaticAuditError(
        err instanceof Error ? err.message : 'Ismeretlen hiba a static audit futtatasnal',
      )
    } finally {
      setStaticAuditLoading(false)
    }
  }

  if (loading) {
    return <div className="p-6">{i18n.t('literals.audit-diagnosztikai-adatok-betoltese')}</div>
  }

  if (error) {
    return (
      <div className="p-6">
        <h1 className="text-2xl font-bold mb-4">{i18n.t('literals.audit-diagnosztika')}</h1>
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
          {i18n.t('literals.hiba')}
          {error}
        </div>
      </div>
    )
  }

  return (
    <div className="p-6 space-y-6">
      <header>
        <h1 className="text-2xl font-bold">{i18n.t('literals.audit-diagnosztika-v234')}</h1>
        <p className="text-sm text-gray-600">
          {i18n.t('literals.ai-olvashato-belso-log-audit-modul-utols')}
        </p>
      </header>

      <section className="grid gap-3 sm:grid-cols-3" data-testid="diagnostics-health-panel">
        <div
          className={`rounded border p-4 ${health?.ok ? 'border-green-200 bg-green-50 text-green-900' : 'border-amber-200 bg-amber-50 text-amber-900'}`}
        >
          <div className="text-sm font-semibold">{i18n.t('literals.diagnostics-ingest')}</div>
          <div className="mt-2 text-2xl font-bold">{health?.ok ? 'OK' : 'Nincs adat'}</div>
        </div>
        <div className="rounded border border-gray-200 bg-white p-4">
          <div className="text-sm font-semibold text-gray-700">
            {i18n.t('literals.db-ben-rogzitett-klienshibak')}
          </div>
          <div className="mt-2 text-2xl font-bold text-gray-900">
            {health?.totalReportedErrors ?? 0}
          </div>
        </div>
        <div className="rounded border border-gray-200 bg-white p-4">
          <div className="text-sm font-semibold text-gray-700">{i18n.t('literals.katalogus')}</div>
          <div className="mt-2 text-2xl font-bold text-gray-900">{catalog?.totalCodes ?? 0}</div>
        </div>
      </section>

      {/* Static audit: /api/static-audit (nem /api/v1) */}
      <section className="bg-white shadow rounded p-4">
        <div className="flex flex-col gap-3 md:flex-row md:items-end md:justify-between">
          <div className="min-w-0">
            <h2 className="text-lg font-semibold">{i18n.t('literals.static-audit')}</h2>
            <p className="mt-1 text-sm text-gray-600">
              {i18n.t('literals.db-kapcsolat-kotelezo-kornyezeti-valtozo')}
            </p>
          </div>
          <div className="grid w-full gap-2 md:w-auto md:min-w-[24rem] md:grid-cols-[minmax(0,1fr)_auto]">
            <label className="min-w-0">
              <span className="sr-only">{i18n.t('literals.static-audit-admin-token')}</span>
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
            {i18n.t('literals.static-audit-hiba')}
            {staticAuditError}
          </div>
        )}

        {staticAuditChecks && (
          <div
            className="mt-4 grid gap-2 sm:grid-cols-2 xl:grid-cols-3"
            data-testid="static-audit-results"
          >
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
          <h2 className="text-lg font-semibold">{i18n.t('literals.hibas-audit-esemenyek')}</h2>
          <span className="text-sm text-gray-600">
            {errorEntries.length}
            {i18n.t('literals.error-warn-fatal-sor')}
          </span>
        </div>
        {errorEntries.length === 0 ? (
          <p className="mt-3 rounded border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
            {i18n.t('literals.nincs-friss-hibas-audit-bejegyzes')}
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
                <div className="mt-1 break-all font-mono text-xs text-amber-800">
                  {e.traceId ?? e.id}
                </div>
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Hash-chain integritas check */}
      <section className="bg-white shadow rounded p-4">
        <div className="flex items-center justify-between mb-2">
          <h2 className="text-lg font-semibold">{i18n.t('literals.hash-chain-integritas')}</h2>
          <button
            type="button"
            onClick={onVerifyHashChain}
            className="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded text-sm"
          >
            {i18n.t('literals.ellenorzes-utolso-200')}
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
                {i18n.t('literals.elso-problemas-sor-id')}
                <code>{integrity.firstBrokenEntryId}</code>
              </div>
            )}
          </div>
        )}
      </section>

      {/* Trace-ID korrelacios kereses */}
      <section className="bg-white shadow rounded p-4">
        <h2 className="text-lg font-semibold mb-2">
          {i18n.t('literals.trace-id-korrelacio-kliens-backend-lanc')}
        </h2>
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
            {i18n.t('literals.kereses')}
          </button>
        </div>
        {traceResults !== null && (
          <div className="mt-3 text-sm">
            <strong>{traceResults.length}</strong>
            {i18n.t('literals.esemeny-ehhez-a-trace-hez')}
            <ul className="mt-2 space-y-1">
              {traceResults.map((e) => (
                <li key={e.id} className="border-b py-1">
                  <span className="font-mono text-xs text-gray-500">{e.ts}</span>{' '}
                  <span className="font-semibold">{e.eventType ?? e.action}</span>{' '}
                  <span className="text-gray-600">
                    {e.entityType}
                    {i18n.t('literals.lit-12')}
                    {e.entityId}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </section>

      {/* Entity audit-lanc kereses */}
      <section className="bg-white shadow rounded p-4">
        <h2 className="text-lg font-semibold mb-2">{i18n.t('literals.entity-audit-lanc')}</h2>
        <div className="grid gap-2 md:grid-cols-[minmax(0,12rem)_minmax(0,1fr)_auto]">
          <input
            type="text"
            value={entityTypeQuery}
            onChange={(e) => setEntityTypeQuery(e.target.value)}
            placeholder="entityType"
            className="px-3 py-2 border rounded font-mono text-sm"
          />
          <input
            type="text"
            value={entityIdQuery}
            onChange={(e) => setEntityIdQuery(e.target.value)}
            placeholder="entityId"
            className="px-3 py-2 border rounded font-mono text-sm"
          />
          <button
            type="button"
            onClick={onEntitySearch}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded"
          >
            {i18n.t('literals.audit-lanc')}
          </button>
        </div>
        {entityResults !== null && (
          <div className="mt-3 text-sm" data-testid="entity-chain-results">
            <strong>{entityResults.length}</strong>
            {i18n.t('literals.esemeny-ehhez-az-entityhez')}
            <ul className="mt-2 space-y-1">
              {entityResults.map((e) => (
                <li key={e.id} className="border-b py-1">
                  <span className="font-mono text-xs text-gray-500">{e.ts}</span>{' '}
                  <span className="font-semibold">{e.eventType ?? e.action}</span>{' '}
                  <span className="text-gray-600">
                    {e.entityType}
                    {i18n.t('literals.lit-12')}
                    {e.entityId}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </section>

      {/* Utolso 100 esemeny */}
      <section className="bg-white shadow rounded p-4">
        <h2 className="text-lg font-semibold mb-2">
          {i18n.t('literals.utolso-100-audit-esemeny')}
        </h2>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 text-sm">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-3 py-2 text-left font-medium">{i18n.t('literals.ido')}</th>
                <th className="px-3 py-2 text-left font-medium">{i18n.t('literals.event-type')}</th>
                <th className="px-3 py-2 text-left font-medium">{i18n.t('literals.entity')}</th>
                <th className="px-3 py-2 text-left font-medium">{i18n.t('literals.worker')}</th>
                <th className="px-3 py-2 text-left font-medium">{i18n.t('literals.amount')}</th>
                <th className="px-3 py-2 text-left font-medium">{i18n.t('literals.trace')}</th>
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
                    {e.entityId && (
                      <span className="text-gray-500">
                        {i18n.t('literals.lit-12')}
                        {e.entityId.substring(0, 8)}
                      </span>
                    )}
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
                      {i18n.t('literals.reszletek')}
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
            {i18n.t('literals.ai-olvashato-hibakod-katalogus-v')}
            {catalog.version}
            {i18n.t('literals.lit-13')}
            {catalog.totalCodes}
            {i18n.t('literals.kod')}
          </h2>
          <div className="overflow-x-auto max-h-96 overflow-y-auto">
            <table className="min-w-full divide-y divide-gray-200 text-sm">
              <thead className="bg-gray-50 sticky top-0">
                <tr>
                  <th className="px-3 py-2 text-left font-medium">{i18n.t('literals.kod-2')}</th>
                  <th className="px-3 py-2 text-left font-medium">
                    {i18n.t('literals.kategoria')}
                  </th>
                  <th className="px-3 py-2 text-left font-medium">{i18n.t('literals.szint')}</th>
                  <th className="px-3 py-2 text-left font-medium">
                    {i18n.t('literals.felhasznaloi-hatas')}
                  </th>
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

      {selectedEntry && (
        <AuditEntryModal entry={selectedEntry} onClose={() => setSelectedEntry(null)} />
      )}
    </div>
  )
}

/**
 * Copilot PR #681 P2 a11y: role=dialog + aria-modal + Escape-to-close + focus.
 */
function AuditEntryModal({ entry, onClose }: { entry: AuditLogEntry; onClose: () => void }) {
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
          {i18n.t('literals.audit-esemeny-reszletei')}
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
            {i18n.t('literals.bezaras-esc')}
          </button>
        </div>
      </div>
    </div>
  )
}
