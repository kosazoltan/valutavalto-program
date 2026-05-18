/**
 * EBC Hangsegéd Markdown export — biztonságos fájlnév normalizálás.
 *
 * <p>A Windows / Mac / Linux mind eltérő tilalmas-karakter-listával dolgozik.
 * A legbiztonságosabb az ASCII-csak fájlnév (ékezet → ASCII transliterate).
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §7.2
 */

const ACCENT_MAP: Record<string, string> = {
  á: 'a', é: 'e', í: 'i', ó: 'o', ö: 'o', ő: 'o', ú: 'u', ü: 'u', ű: 'u',
  Á: 'A', É: 'E', Í: 'I', Ó: 'O', Ö: 'O', Ő: 'O', Ú: 'U', Ü: 'U', Ű: 'U',
}

/**
 * Magyar ekezetek + nem-ASCII karakterek lecserelese sima ASCII-ra.
 * Tilalmas Windows-karakterek (`<>:"/\\|?*`) eltavolitasa.
 * Whitespace → underscore. Tobbszoros underscore → egy.
 *
 * @param input nyers szöveg (pl. issue.title)
 * @param fallback ha az eredmeny ures, ezt hasznalja (default: "issue")
 * @returns biztonsagos filename-fragment
 */
export function normalizeForFilename(input: string, fallback = 'issue'): string {
  if (!input) return fallback

  let out = ''
  for (const ch of input) {
    if (ACCENT_MAP[ch]) {
      out += ACCENT_MAP[ch]
    } else if (/[a-zA-Z0-9._-]/.test(ch)) {
      out += ch
    } else if (/\s/.test(ch)) {
      out += '_'
    } else {
      out += '_'
    }
  }

  out = out
    .replace(/[<>:"/\\|?*]/g, '')
    .replace(/_+/g, '_')
    .replace(/^[_.-]+|[_.-]+$/g, '')

  return out || fallback
}

/**
 * Teljes filename osszealitasa: `<dateIso>-<normalized>.md`.
 * A dateIso `YYYY-MM-DD` (NEM teljes ISO timestamp — kettospont tilos Windows-on).
 */
export function buildExportFilename(
  dateIso: string,
  title: string,
  extension = 'md'
): string {
  const datePart = (dateIso || new Date().toISOString()).slice(0, 10)
  const titlePart = normalizeForFilename(title, 'hibajelzes')
  const ext = extension.replace(/^\.+/, '')
  return `${datePart}-${titlePart}.${ext}`
}
