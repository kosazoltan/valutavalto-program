import { useState, useCallback } from 'react'
import { useSearchParams } from 'react-router-dom'
import { BookOpen, Printer, Calendar, RefreshCw } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { useAuthStore } from '../../stores/authStore'
import { dailyReportApi } from '../../services/api/index'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

/**
 * FKH-027 FR-4: a nyomtatási kép cégfejléce. A `HufDaybookPdfService.COMPANY_HEADER`
 * (43. sor) képernyős párja — a PDF WinAnsi-korlát miatt ott csupa nagybetűs,
 * ékezet nélküli változat szerepel, itt a hu-HU helyesírású forma (NFR-1).
 */
const COMPANY_HEADER = 'Exclusive Best Change Zrt.'

interface DaybookRow {
  annualSequence?: number
  receiptNumber: string
  // FKH-022 FR-K3: partner-azonosító — fizikai pénztárnál numerikus (076),
  // VAULT_COUNTERPARTY partnernél betűkód (PRB, ERB, ...)
  partnerCode?: string
  timestamp: string
  atadasHuf?: number
  atvetelHuf?: number
  storno: boolean
}

interface DaybookData {
  branchId: string
  branchName: string
  // FKH-027 (9.1/9.): a backend HufDaybookDto ezeket a mezőket eddig is küldte,
  // csak a kliens-oldali interface nem ismerte — FR-1/FR-3/FR-4 előfeltétele.
  branchAddress?: string
  date: string
  rows: DaybookRow[]
  totalAtadasHuf: number
  totalAtvetelHuf: number
  openingBalanceHuf: number
  closingBalanceHuf: number
}

export default function DaybookPage() {
  const { t } = useTranslation()
  const [searchParams] = useSearchParams()
  const worker = useAuthStore((state) => state.worker)
  const branchId = searchParams.get('branchId') || worker?.branchId || ''
  const initialDate = searchParams.get('date') || localIsoDate()

  const [date, setDate] = useState(initialDate)
  const [report, setReport] = useState<DaybookData | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const loadReport = useCallback(async () => {
    if (!branchId) {
      toast.warning('Hiányzó adat', 'Fiók kiválasztása szükséges')
      return
    }
    try {
      setLoading(true)
      setError(null)
      const data = await dailyReportApi.get(branchId, date)
      setReport(data as DaybookData)
    } catch (err) {
      logger.error('DaybookPage', 'Napi HUF-napló betöltési hiba:', err)
      setReport(null)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [branchId, date])

  // NFR-2: a HUF-formázás változatlan. A paraméter azért fogad `undefined`-et is,
  // mert a válasz futásidőben cast-tal kerül a DaybookData típusra — hiányzó
  // egyenleg-mező esetén 0-t mutatunk, nem dobunk hibát.
  const fmtHuf = (n: number | undefined) =>
    (n ?? 0).toLocaleString('hu-HU', { minimumFractionDigits: 0, maximumFractionDigits: 0 }) + ' Ft'

  return (
    <div className="space-y-4">
      {/* FR-7: a képernyős oldalcím és a gombsor nyomtatáskor nem jelenik meg —
          a papíron a cégfejléc (FR-4) veszi át a szerepét. */}
      <div className="no-print flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <BookOpen />
          {t('reports.napiKonyv')}
        </h1>
        <div className="flex gap-2">
          {report && (
            /* FR-6: böngésző natív nyomtatása (TransferDocumentPage.tsx:204-206 minta). */
            <button
              onClick={() => window.print()}
              className="no-print form-button"
              title={t('common.print')}
            >
              <Printer size={16} />
              {t('common.print')}
            </button>
          )}
        </div>
      </div>

      {/* FR-7: a dátumválasztó és a "Lekérdezés" gomb csak képernyőn. */}
      <div className="no-print form-panel flex gap-3 items-end">
        <div>
          <label className="form-label">{t('common.date')}</label>
          <div className="flex items-center gap-1">
            <Calendar size={16} className="text-gray-400" />
            <input
              className="form-input"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
            />
          </div>
        </div>
        <button
          onClick={() => void loadReport()}
          disabled={loading}
          className="form-button-primary"
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />{' '}
          {loading ? 'Betöltés...' : 'Lekérdezés'}
        </button>
      </div>

      {error && (
        <div className="no-print bg-yellow-50 border border-yellow-200 text-yellow-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {report && (
        <div className="form-panel space-y-4">
          {/* FR-4: cégfejléc — tartalmilag a HufDaybookPdfService.renderHeader
              (93-107. sor) képernyős megfelelője, HTML-elrendezésben. */}
          <div
            data-testid="daybook-print-header"
            className="border-b border-gray-300 pb-3 text-center"
          >
            <div className="text-lg font-bold tracking-wide">{COMPANY_HEADER}</div>
            <div className="text-sm">{report.branchName}</div>
            {report.branchAddress && <div className="text-sm">{report.branchAddress}</div>}
            <div className="mt-2 text-sm font-semibold">
              {i18n.t('literals.naplokonyv-huf-datum')}
              {report.date}
            </div>
          </div>

          {report.rows.length === 0 ? (
            <div className="text-center text-gray-500 py-4">
              {i18n.t('literals.nincs-tetel-erre-a-napra')}
            </div>
          ) : (
            <table className="data-grid w-full text-sm">
              <thead>
                <tr>
                  <th>{i18n.t('literals.sorszam')}</th>
                  <th>{i18n.t('literals.bizonylat')}</th>
                  <th>{i18n.t('literals.partner')}</th>
                  <th>{t('misc.ido')}</th>
                  <th className="text-right">{i18n.t('literals.atadas-huf')}</th>
                  <th className="text-right">{i18n.t('literals.atvetel-huf')}</th>
                </tr>
              </thead>
              <tbody>
                {report.rows.map((row) => (
                  <tr key={`${row.receiptNumber}-${row.timestamp}`}>
                    <td>{row.annualSequence ?? '-'}</td>
                    {/* FR-10: a bizonylatszám TELJES hosszban látszik (a PDF-oldali
                        18 karakteres truncate nem öröklődik át), a sztornó-jelölés
                        pedig félkövér és SZÍN NÉLKÜLI — fekete-fehér nyomtatón is olvasható. */}
                    <td className="font-mono">
                      {row.receiptNumber}
                      {row.storno && (
                        <span data-testid="daybook-storno-badge" className="ml-2 font-bold">
                          {i18n.t('literals.sztorno-2')}
                        </span>
                      )}
                    </td>
                    <td className="font-mono">{row.partnerCode ?? '-'}</td>
                    <td>{row.timestamp}</td>
                    <td className="text-right">
                      {row.atadasHuf != null ? fmtHuf(row.atadasHuf) : ''}
                    </td>
                    <td className="text-right">
                      {row.atvetelHuf != null ? fmtHuf(row.atvetelHuf) : ''}
                    </td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="font-semibold">
                  <td colSpan={4}>{i18n.t('literals.osszesen')}</td>
                  <td className="text-right">{fmtHuf(report.totalAtadasHuf)}</td>
                  <td className="text-right">{fmtHuf(report.totalAtvetelHuf)}</td>
                </tr>
              </tfoot>
            </table>
          )}

          {/* FR-1/2/3: Nyitó / Forgalom / Záró dobozok — a HufDaybookPdfService
              renderSummaryBoxes (156-186. sor) keretes dobozainak HTML-párja. */}
          <div className="space-y-2">
            <div
              data-testid="daybook-opening-balance"
              className="flex justify-between border border-gray-400 px-3 py-2 text-sm"
            >
              <span className="font-semibold">{i18n.t('literals.nyito-egyenleg')}</span>
              <span>{fmtHuf(report.openingBalanceHuf)}</span>
            </div>
            <div className="flex justify-between border border-gray-400 px-3 py-2 text-sm">
              <span data-testid="daybook-total-atadas" className="font-semibold">
                {i18n.t('literals.atadas-osszesen')}
                {fmtHuf(report.totalAtadasHuf)}
              </span>
              <span data-testid="daybook-total-atvetel" className="font-semibold">
                {i18n.t('literals.atvetel-osszesen')}
                {fmtHuf(report.totalAtvetelHuf)}
              </span>
            </div>
            <div
              data-testid="daybook-closing-balance"
              className="flex justify-between border border-gray-400 px-3 py-2 text-sm"
            >
              <span className="font-semibold">{i18n.t('literals.zaro-egyenleg')}</span>
              <span>{fmtHuf(report.closingBalanceHuf)}</span>
            </div>
          </div>

          {/* FR-5: aláírás-sor (PDF: renderSignatures, 190-204. sor). */}
          <div
            data-testid="daybook-signatures"
            className="grid grid-cols-2 gap-8 pt-12 text-center text-sm"
          >
            <div className="border-t border-gray-500 pt-1">
              {i18n.t('literals.penztaros-alairasa')}
            </div>
            <div className="border-t border-gray-500 pt-1">
              {i18n.t('literals.ellenorzo-alairasa')}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
