/**
 * EBC Valutavalto belso log+audit modul - egyseges log schema.
 *
 * Forras: vault/feedback/valutavalto-belso-log-audit-modul-tervezet-2026-05-18.md
 * (user-direkt iva 2026-05-18, in-app implementacio, NEM kulso Loki/Sentry)
 *
 * Minden komponens (backend Java, frontend React, Electron 3 kliens) ezt a
 * schema-t hasznalja. A JSON output ezt a tipust kovetheti -> az AI Javito
 * Program (Claude Code) konnyen olvashato.
 */

export type LogLevel = 'TRACE' | 'DEBUG' | 'INFO' | 'WARN' | 'ERROR' | 'FATAL'

export type LogService = 'backend' | 'frontend' | 'penztar' | 'kozponti' | 'arfolyamkeszito'

export type LogEnv = 'dev' | 'staging' | 'prod'

export type ErrorCategory =
  | 'AML'
  | 'BUSINESS'
  | 'TECHNICAL'
  | 'NETWORK'
  | 'SECURITY'
  | 'INTEGRATION'

export interface VVLogEntry {
  // === Kotelezo mezok ===
  ts: string                    // ISO 8601, pl. "2026-05-18T12:34:56.789Z"
  level: LogLevel
  service: LogService
  service_version: string       // pl. "2.5.57"
  env: LogEnv
  hostname: string              // OS hostname
  message: string               // Rovid (< 200 char), human-readable

  // === Trace korrelacio (W3C TraceContext) ===
  trace_id?: string             // 32-hex
  span_id?: string              // 16-hex
  parent_span_id?: string

  // === Uzleti kontextus ===
  company_id?: string
  branch_id?: string
  worker_id?: string
  worker_role?: string
  business_unit?: 'CURRENCY' | 'PAWN' | 'JEWELRY'
  client_context?: 'CASHIER' | 'TREASURY_HQ' | 'RFM' | 'ADMIN'

  // === Esemeny-specifikus ===
  event_type?: string           // pl. "transaction.committed", "rate.published"
  entity_type?: string          // pl. "Transaction", "Rate", "Receipt"
  entity_id?: string
  receipt_number?: string
  amount?: number
  currency?: string

  // === Hibakod (AI-olvashato) ===
  error_code?: string           // pl. "VV-AML-001", lasd error-codes.yaml
  error_category?: ErrorCategory
  error?: {
    type: string                // exception class
    message: string
    stack?: string
    cause?: { type: string; message: string }
  }

  // === Performance ===
  duration_ms?: number
  http_status?: number
  http_method?: string
  http_path?: string

  // === Hashed PII (NEM nyers!) ===
  customer_id_hash?: string     // SHA-256 hash, sosem nyers nev

  // === AI hint (opcionalis) ===
  ai_hint?: string
  related_logs?: string[]       // trace_id-k

  // === Szabad attributumok (vigyazat a kardinalitassal!) ===
  attrs?: Record<string, unknown>
}

/**
 * AI-olvashato error code katalogus entry.
 * A `packages/shared-logging/error-codes.yaml` parse-olasanak eredmenye.
 */
export interface ErrorCodeEntry {
  name: string                  // ember-olvashato leiras
  category: ErrorCategory
  level: LogLevel
  user_impact?: string          // ami a felhasznalo lat
  ai_fix_hint: string           // Claude Code-nak: hogyan javitsd
}

export interface ErrorCodeCatalog {
  version: number
  last_updated: string
  total_codes: number
  codes: Record<string, ErrorCodeEntry>
}
