/**
 * EBC Valutavalto belso log+audit - PII redactor (kozos).
 *
 * Hivatkozas: dev.to/polliog 2026-03-16 PII GDPR
 *
 * Hasznalat: a log-output ELOTT futtatni, hogy a jelszo / customer-nev /
 * kartyaszam / IBAN / JWT / Bearer token SOHA NE keruljon a log-fajlba
 * vagy a network-en a backend-re.
 */

const PATTERNS = {
  email: /\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b/g,
  hu_tax_id: /\b\d{10}\b/g,                  // adoszam (10 jegyu)
  hu_id_card: /\b\d{6}[A-Z]{2}\b/g,          // szemelyi szam
  iban: /\b[A-Z]{2}\d{2}[A-Z0-9]{4,30}\b/g,  // bankszamla
  jwt: /eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/g,
  bearer: /Bearer\s+[A-Za-z0-9._\-+/=]{20,}/gi,
  card_pan: /\b(?:\d[ -]*?){13,19}\b/g,
  openai_sk: /sk-(?:proj|svcacct)-[A-Za-z0-9_-]{20,}/g,  // OpenAI API key
}

const FIELD_REDACT = new Set<string>([
  'password',
  'pwd',
  'token',
  'oauthToken',
  'oauth_token',
  'authorization',
  'cookie',
  'apiKey',
  'api_key',
  'secret',
  'clientSecret',
  'client_secret',
  'idNumber',
  'id_number',
  'taxId',
  'tax_id',
  'pan',
  'customerName',
  'customer_name',
  'address',
  'motherName',
  'mother_name',
  'birthPlace',
  'birth_place',
])

const REDACTED = '[REDACTED]'

function redactString(s: string): string {
  return s
    .replace(PATTERNS.openai_sk, '[OPENAI_KEY]')
    .replace(PATTERNS.jwt, '[JWT]')
    .replace(PATTERNS.bearer, 'Bearer [REDACTED]')
    .replace(PATTERNS.email, '[EMAIL]')
    .replace(PATTERNS.iban, '[IBAN]')
    .replace(PATTERNS.card_pan, '[PAN]')
    .replace(PATTERNS.hu_id_card, '[IDCARD]')
    .replace(PATTERNS.hu_tax_id, '[TAXID]')
}

/**
 * Rekurzivan redact-olja a payload-ot.
 * - String mezok: pattern-match cseren.
 * - Sensitive mezo-nevek (`password`, `token`, ...): teljes ertek [REDACTED].
 * - Array, object: rekurzio.
 */
export function redact(obj: unknown): unknown {
  if (obj == null) return obj
  if (typeof obj === 'string') return redactString(obj)
  if (typeof obj === 'number' || typeof obj === 'boolean') return obj
  if (Array.isArray(obj)) return obj.map(redact)
  if (typeof obj === 'object') {
    const out: Record<string, unknown> = {}
    for (const [k, v] of Object.entries(obj as Record<string, unknown>)) {
      if (FIELD_REDACT.has(k) || FIELD_REDACT.has(k.toLowerCase())) {
        out[k] = REDACTED
      } else {
        out[k] = redact(v)
      }
    }
    return out
  }
  return obj
}

/** Test-only: a regex pattern-eket ki tudja olvasni a tesztcsomag. */
export const __REDACT_PATTERNS_FOR_TESTING = PATTERNS
export const __REDACT_FIELDS_FOR_TESTING = FIELD_REDACT
