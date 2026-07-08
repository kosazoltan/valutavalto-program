/**
 * EBC Valutavalto belso log+audit - PII redactor (kozos).
 *
 * Hivatkozas: dev.to/polliog 2026-03-16 PII GDPR
 *
 * Hasznalat: a log-output ELOTT futtatni, hogy a jelszo / customer-nev /
 * kartyaszam / IBAN / JWT / Bearer token SOHA NE keruljon a log-fajlba
 * vagy a network-en a backend-re.
 */

// Copilot PR #681 P1: a hu_tax_id (10 jegy) es hu_id_card (6+2) NEM standalone,
// hanem kontextus-fuggo (kulcsszo melle). A card_pan IIN prefix-szel gateolt.
// Az iban hossz tightened (11..30 az alphanumeric body).
const PATTERNS = {
  email: /\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b/g,
  iban: /\b[A-Z]{2}\d{2}[A-Z0-9]{11,30}\b/g,
  jwt: /eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/g,
  bearer: /Bearer\s+[A-Za-z0-9._\-+/=]{20,}/gi,
  // IIN prefix-szel: Visa(4), MasterCard(51..55), Amex(34/37), Discover(6011|65xx)
  card_pan: /\b(?:4\d{12}(?:\d{3})?|5[1-5]\d{14}|3[47]\d{13}|6(?:011|5\d{2})\d{12})\b/g,
  openai_sk: /sk-(?:proj|svcacct)-[A-Za-z0-9_-]{20,}/g,
  // Kontextus-fuggo: kulcsszo + 5char + ertek - csak az erteket cserelni
  hu_id_card_ctx:
    /(szig\.?szam|szemelyi\.?ig\.?|id[_-]?card|identity[_-]?card)([^A-Za-z0-9]{0,5})(\d{6}[A-Z]{2})/gi,
  hu_tax_id_ctx: /(adoszam|tax[_-]?id)([^A-Za-z0-9]{0,5})(\d{10})/gi,
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
  return (
    s
      .replace(PATTERNS.openai_sk, '[OPENAI_KEY]')
      .replace(PATTERNS.jwt, '[JWT]')
      .replace(PATTERNS.bearer, 'Bearer [REDACTED]')
      .replace(PATTERNS.email, '[EMAIL]')
      .replace(PATTERNS.iban, '[IBAN]')
      .replace(PATTERNS.card_pan, '[PAN]')
      // Kontextus-fuggo: a kulcsszo + separator megmarad, csak az ertek redact
      .replace(PATTERNS.hu_id_card_ctx, '$1$2[IDCARD]')
      .replace(PATTERNS.hu_tax_id_ctx, '$1$2[TAXID]')
  )
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
