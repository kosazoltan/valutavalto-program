export const PRIVACY_NOTICE_VERSION = '2026-06-09'
export const PRIVACY_NOTICE_ACK_MARKER = `ADATKEZELESI_TAJEKOZTATO_ACK v${PRIVACY_NOTICE_VERSION}`

export function appendPrivacyNoticeAcknowledgement(notes?: string | null): string {
  const trimmed = notes?.trim()
  if (trimmed?.includes(PRIVACY_NOTICE_ACK_MARKER)) {
    return trimmed
  }
  return trimmed ? `${trimmed}\n${PRIVACY_NOTICE_ACK_MARKER}` : PRIVACY_NOTICE_ACK_MARKER
}
