import type { IssueRecord } from '../store/issueTypes'

/**
 * EBC Hangsegéd Markdown report generálás.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §7.1
 *
 * <p>A kimenet a fejlesztő számára emberi-olvasható .md fájl. Felépítés:
 * <pre>
 * # &lt;mode&gt; — &lt;title&gt;
 * **Hibakod:** ...
 * ## Sulyossag
 * ## Modul
 * ## Bejelento
 * ## Leiras
 * ## Reprodukcios lepesek
 * ## Elvart viselkedes
 * ## Tenyleges viselkedes
 * ## Mellekletek
 * ## Gyors-jegyzetek
 * ## Metaadat
 * </pre>
 */

const MODE_LABEL: Record<IssueRecord['mode'], string> = {
  install: 'Telepités-kísérő',
  test: 'Tesztelés-kísérő',
  support: 'Hibajelzés',
}

const SEVERITY_LABEL: Record<IssueRecord['severity'], string> = {
  low: 'Alacsony',
  medium: 'Közepes',
  high: 'Magas',
  critical: 'Kritikus',
}

function block(title: string, body: string | null | undefined): string {
  if (!body || !body.trim()) return ''
  return `## ${title}\n\n${body.trim()}\n`
}

function listBlock(title: string, items: string[]): string {
  if (!items.length) return ''
  const lines = items.map((item) => `- ${item}`).join('\n')
  return `## ${title}\n\n${lines}\n`
}

export interface MarkdownExportOptions {
  /** ha true: a végén szerepel a UUID + DB timestamp */
  includeMetadata?: boolean
}

export function renderIssueAsMarkdown(
  issue: IssueRecord,
  options: MarkdownExportOptions = {},
): string {
  const { includeMetadata = true } = options
  const lines: string[] = []

  lines.push(`# ${MODE_LABEL[issue.mode]} — ${issue.title || '(név nélkül)'}`)
  lines.push('')
  if (issue.errorCode) {
    lines.push(`**Hibakód:** \`${issue.errorCode}\``)
    lines.push('')
  }

  lines.push(`**Súlyosság:** ${SEVERITY_LABEL[issue.severity]}`)
  if (issue.module) lines.push(`**Modul:** ${issue.module}`)
  lines.push('')

  const reporter = issue.reporter
  const reporterParts: string[] = []
  if (reporter.displayName) reporterParts.push(reporter.displayName)
  if (reporter.workerCode) reporterParts.push(`(${reporter.workerCode})`)
  if (reporter.branchCode) reporterParts.push(`@ ${reporter.branchCode}`)
  if (reporterParts.length) {
    lines.push(`**Bejelentő:** ${reporterParts.join(' ')}`)
    lines.push('')
  }

  lines.push(block('Leírás', issue.description))
  lines.push(block('Reprodukciós lépések', issue.reproSteps))
  lines.push(block('Elvárt viselkedés', issue.expected))
  lines.push(block('Tényleges viselkedés', issue.actual))

  lines.push(
    listBlock(
      'Mellékletek',
      issue.attachments.map((a) => `${a.description} (\`${a.ref}\`)`),
    ),
  )
  lines.push(listBlock('Gyors-jegyzetek', issue.quickNotes))

  if (includeMetadata) {
    lines.push(`## Metaadat\n`)
    lines.push(`- ID: \`${issue.id}\``)
    lines.push(`- Létrehozva: ${issue.createdAt}`)
    lines.push(`- Frissítve: ${issue.updatedAt}`)
    lines.push(`- Állapot: ${issue.status}`)
    lines.push('')
  }

  return lines
    .filter((l) => l !== undefined)
    .join('\n')
    .replace(/\n{3,}/g, '\n\n')
}

/**
 * Browser-kontextusban letolti a renderelt markdown-t kliens-oldali blob-kent.
 */
export function downloadMarkdown(filename: string, markdown: string): void {
  const blob = new Blob([markdown], { type: 'text/markdown;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = filename
  document.body.appendChild(anchor)
  anchor.click()
  document.body.removeChild(anchor)
  setTimeout(() => URL.revokeObjectURL(url), 0)
}
