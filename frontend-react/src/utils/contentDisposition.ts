/** Content-Disposition "attachment; filename=..." fájlnév-kinyerés (RFC 5987 filename* elsőbbséggel). */
export function filenameFromContentDisposition(header?: string): string | null {
  if (!header) return null

  const star = /filename\*=(?:UTF-8'')?([^;]+)/i.exec(header)
  if (star?.[1]) {
    try {
      return decodeURIComponent(star[1].trim().replace(/^"|"$/g, ''))
    } catch {
      // Rossz kódolás esetén a sima filename értékére esünk vissza.
    }
  }

  const plain = /filename="?([^";]+)"?/i.exec(header)
  return plain?.[1]?.trim() || null
}
