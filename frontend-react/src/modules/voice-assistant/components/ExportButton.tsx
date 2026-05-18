import { useCallback, useState } from 'react'
import type { IssueRecord } from '../store/issueTypes'
import { renderIssueAsMarkdown, downloadMarkdown } from '../export/markdownExporter'
import { buildExportFilename } from '../export/filenameNormalizer'
import { logger } from '../../../utils/logger'

/**
 * EBC Hangsegéd Markdown export gomb.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §7.3
 *
 * <p>Egyetlen kattintással letölti a hibajelentés/telepítési napló markdown-jét
 * a felhasználó gépére. A fájlnév ASCII-csak (Windows/Mac/Linux kompatibilis).
 */
export interface ExportButtonProps {
  issue: IssueRecord
  className?: string
}

export function ExportButton({ issue, className = '' }: ExportButtonProps) {
  const [busy, setBusy] = useState(false)

  const handleClick = useCallback(async () => {
    if (busy) return
    setBusy(true)
    try {
      const markdown = renderIssueAsMarkdown(issue)
      const filename = buildExportFilename(issue.createdAt, issue.title || 'hibajelzes')
      downloadMarkdown(filename, markdown)
      logger.info('VoiceAssistant', `Markdown export ok: ${filename}`)
    } catch (err) {
      logger.error('VoiceAssistant', 'Markdown export hiba: ' + String(err))
    } finally {
      setBusy(false)
    }
  }, [busy, issue])

  return (
    <button
      type="button"
      disabled={busy}
      onClick={handleClick}
      className={
        className ||
        'rounded bg-blue-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50'
      }
    >
      {busy ? 'Mentés…' : 'Mentés Markdown-ba'}
    </button>
  )
}
