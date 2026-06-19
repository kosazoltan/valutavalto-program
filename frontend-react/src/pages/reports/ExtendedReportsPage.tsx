import { useState } from 'react'
import { FileText, Calendar, Download } from 'lucide-react'
import { reportApi, reportExtendedApi } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger';
import { useTranslation } from 'react-i18next'

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  link.remove()
  URL.revokeObjectURL(url)
}

export default function ExtendedReportsPage() {
  const { t } = useTranslation()
  const [reportType, setReportType] = useState('transaction-list')
  const [startDate, setStartDate] = useState('')
  const [endDate, setEndDate] = useState('')
  const [year, setYear] = useState(new Date().getFullYear())
  const [month, setMonth] = useState(new Date().getMonth() + 1)
  const [branchId, setBranchId] = useState('')
  const [currencyId, setCurrencyId] = useState('1')
  const [cashDeskId, setCashDeskId] = useState('cashdesk-1')
  const [loading, setLoading] = useState(false)
  const [exporting, setExporting] = useState(false)
  const [reportData, setReportData] = useState<Record<string, unknown> | null>(null)

  const handleGenerateReport = async () => {
    try {
      setLoading(true)
      const selectedBranchId = branchId.trim() || undefined
      let data
      switch (reportType) {
        case 'transaction-list':
          data = await reportExtendedApi.getTransactionList(selectedBranchId, startDate, endDate)
          break
        case 'receipt-list':
          data = await reportExtendedApi.getReceiptList(selectedBranchId, startDate, endDate)
          break
        case 'fee-summary':
          data = await reportExtendedApi.getFeeSummary(selectedBranchId, startDate, endDate)
          break
        case 'daily-full':
          if (!selectedBranchId || !startDate) {
            toast.warning('Telephely és dátum szükséges')
            return
          }
          data = await reportApi.getDailyFullReport(selectedBranchId, startDate)
          break
        case 'period-turnover':
          data = await reportApi.getPeriod(startDate, endDate)
          break
        case 'monthly-inventory':
          data = await reportExtendedApi.getMonthlyInventory(selectedBranchId, year, month)
          break
        case 'monthly-turnover':
          data = await reportApi.getMonthlyTurnover(year, month)
          break
        case 'transfer-summary':
          data = await reportApi.getTransferReport(startDate, endDate)
          break
        case 'monthly-transfers':
          data = await reportExtendedApi.getMonthlyTransfers(selectedBranchId, year, month)
          break
        case 'handling-cost':
          data = await reportApi.getHandlingFeeReport(startDate, endDate)
          break
        case 'extended-monthly-turnover':
          data = await reportExtendedApi.getMonthlyTurnover(selectedBranchId, year, month)
          break
        case 'extended-handling-cost':
          data = await reportExtendedApi.getHandlingCost(selectedBranchId, startDate, endDate)
          break
        case 'daily-cash-desk': {
          const selectedCashDeskId = cashDeskId.trim()
          if (!selectedCashDeskId || !startDate) {
            toast.warning('Pénztár azonosító és dátum szükséges')
            return
          }
          data = await reportExtendedApi.getDailyCashDesk(selectedCashDeskId, startDate)
          break
        }
        case 'current-cash-desk-status': {
          const selectedCashDeskId = cashDeskId.trim()
          if (!selectedCashDeskId) {
            toast.warning('Pénztár azonosító szükséges')
            return
          }
          data = await reportExtendedApi.getCurrentCashDeskStatus(selectedCashDeskId)
          break
        }
        case 'cash-status':
          data = await reportApi.getCashStatus()
          break
        case 'today-summary':
          data = await reportApi.getTodaySummary()
          break
        case 'currency-report': {
          const parsedCurrencyId = Number(currencyId)
          if (!Number.isFinite(parsedCurrencyId) || parsedCurrencyId <= 0 || !startDate || !endDate) {
            toast.warning('Valuta azonosító és időszak szükséges')
            return
          }
          data = await reportApi.getCurrencyReport(parsedCurrencyId, startDate, endDate)
          break
        }
        case 'suspicious-transactions':
          data = await reportExtendedApi.getSuspiciousTransactions(selectedBranchId, startDate, endDate)
          break
        case 'card-transaction-fees':
          data = await reportExtendedApi.getCardTransactionFees(selectedBranchId, startDate, endDate)
          break
        default:
          return
      }
      setReportData(data as Record<string, unknown>)
    } catch (error) {
      logger.error('ExtendedReportsPage', 'Hiba a riport generálásánál:', error)
      toast.error('Riport hiba', 'Hiba történt a riport generálása során')
    } finally {
      setLoading(false)
    }
  }

  const handleExportCsv = async () => {
    try {
      setExporting(true)
      if (reportType === 'monthly-turnover') {
        const blob = await reportApi.exportMonthlyTurnoverCsv(year, month)
        downloadBlob(blob, `havi-forgalom-${year}-${String(month).padStart(2, '0')}.csv`)
        toast.success('CSV export elkészült')
        return
      }

      if (reportType === 'period-turnover') {
        if (!startDate || !endDate) {
          toast.warning('Időszak szükséges')
          return
        }
        const blob = await reportApi.exportPeriodCsv(startDate, endDate)
        downloadBlob(blob, `idoszaki-forgalom-${startDate}-${endDate}.csv`)
        toast.success('CSV export elkészült')
      }
    } catch (error) {
      logger.error('ExtendedReportsPage', 'CSV export hiba:', error)
      toast.error('Export hiba', 'Hiba történt a CSV export során')
    } finally {
      setExporting(false)
    }
  }

  const handleExportDailyPdf = async () => {
    const selectedBranchId = branchId.trim()
    if (!selectedBranchId || !startDate) {
      toast.warning('Telephely és dátum szükséges')
      return
    }

    try {
      setExporting(true)
      const blob = await reportApi.exportDailyClosingPdf(selectedBranchId, startDate)
      downloadBlob(blob, `napi-zaras-${selectedBranchId}-${startDate}.pdf`)
      toast.success('PDF export elkészült')
    } catch (error) {
      logger.error('ExtendedReportsPage', 'PDF export hiba:', error)
      toast.error('Export hiba', 'Hiba történt a PDF export során')
    } finally {
      setExporting(false)
    }
  }

  const reportTypes = [
    { value: 'transaction-list', label: 'Tranzakció lista' },
    { value: 'receipt-list', label: 'Bizonylat lista' },
    { value: 'fee-summary', label: 'Díj összesítés' },
    { value: 'daily-full', label: 'Napi zárás teljes' },
    { value: 'period-turnover', label: 'Időszaki forgalom' },
    { value: 'monthly-inventory', label: 'Havi készlet' },
    { value: 'monthly-turnover', label: 'Havi forgalom' },
    { value: 'transfer-summary', label: 'Átadás-átvétel összesítő' },
    { value: 'monthly-transfers', label: 'Havi átutalások' },
    { value: 'handling-cost', label: 'Kezelési díj összesítő' },
    { value: 'extended-monthly-turnover', label: 'Bővített havi forgalom' },
    { value: 'extended-handling-cost', label: 'Bővített kezelési költség' },
    { value: 'daily-cash-desk', label: 'Napi pénztár riport' },
    { value: 'current-cash-desk-status', label: 'Aktuális pénztár riport' },
    { value: 'cash-status', label: 'Aktuális pénztár státusz' },
    { value: 'today-summary', label: 'Mai zárási összesítő' },
    { value: 'currency-report', label: 'Valuta forgalmi riport' },
    { value: 'suspicious-transactions', label: 'Gyanús tranzakciók' },
    { value: 'card-transaction-fees', label: 'Kártyás tranzakció díjak' }
  ]
  const csvExportAvailable = reportType === 'monthly-turnover' || reportType === 'period-turnover'
  const dailyPdfExportAvailable = reportType === 'daily-full'
  const isMonthlyReport = reportType === 'monthly-inventory' || reportType === 'monthly-turnover' || reportType === 'monthly-transfers' || reportType === 'extended-monthly-turnover'
  const currencyReportSelected = reportType === 'currency-report'
  const noParameterReport = reportType === 'cash-status' || reportType === 'today-summary'
  const cashDeskReportSelected = reportType === 'daily-cash-desk' || reportType === 'current-cash-desk-status'
  const cashDeskDateRequired = reportType === 'daily-cash-desk'

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileText />
          {t('reports.bovitettRiportok')}
        </h1>
      </div>

      <div className="form-panel space-y-4">
        <div>
          <label className="form-label">{t('reports.riportTipus')}</label>
          <select className="form-input" value={reportType} onChange={(e) => setReportType(e.target.value)}>
            {reportTypes.map(rt => <option key={rt.value} value={rt.value}>{rt.label}</option>)}
          </select>
        </div>

        {dailyPdfExportAvailable && (
          <div>
            <label className="form-label">{t('reports.telephelyAzonosito')}</label>
            <input
              type="text"
              data-testid="daily-report-branch-id"
              className="form-input"
              value={branchId}
              onChange={(e) => setBranchId(e.target.value)}
              placeholder="branch-1"
            />
          </div>
        )}

        {currencyReportSelected && (
          <div>
            <label className="form-label">{t('reports.valutaAzonosito')}</label>
            <input
              type="number"
              min="1"
              data-testid="currency-report-id"
              className="form-input"
              value={currencyId}
              onChange={(e) => setCurrencyId(e.target.value)}
            />
          </div>
        )}

        {cashDeskReportSelected && (
          <div>
            <label className="form-label">{t('reports.penztarAzonosito')}</label>
            <input
              type="text"
              data-testid="cash-desk-report-id"
              className="form-input"
              value={cashDeskId}
              onChange={(e) => setCashDeskId(e.target.value)}
              placeholder="cashdesk-1"
            />
          </div>
        )}

        {isMonthlyReport ? (
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div>
              <label className="form-label">{t('decade.ev')}</label>
              <input type="number" className="form-input" value={year} onChange={(e) => setYear(parseInt(e.target.value))} />
            </div>
            <div>
              <label className="form-label">{t('monthlyClose.month')}</label>
              <input type="number" className="form-input" min="1" max="12" value={month} onChange={(e) => setMonth(parseInt(e.target.value))} />
            </div>
          </div>
        ) : noParameterReport || reportType === 'current-cash-desk-status' ? (
          <div className="rounded-md border border-blue-100 bg-blue-50 px-3 py-2 text-sm text-blue-900">
            {t('reports.riportNemKerSzurot')}
          </div>
        ) : (
          <div className={dailyPdfExportAvailable || cashDeskDateRequired ? 'grid grid-cols-1 gap-4' : 'grid grid-cols-1 gap-4 sm:grid-cols-2'}>
            <div>
              <label className="form-label">{dailyPdfExportAvailable ? 'Zárás dátuma' : cashDeskDateRequired ? t('common.date') : t('common.startDate')}</label>
              <input
                type="date"
                data-testid={dailyPdfExportAvailable ? 'daily-report-date' : undefined}
                className="form-input"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
              />
            </div>
            {!dailyPdfExportAvailable && !cashDeskDateRequired && (
              <div>
                <label className="form-label">{t('common.endDate')}</label>
                <input type="date" className="form-input" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
              </div>
            )}
          </div>
        )}

        <div className="flex flex-wrap gap-2">
          <button onClick={handleGenerateReport} disabled={loading} className="form-button-primary flex items-center gap-2">
            <Calendar size={16} />
            {loading ? 'Generálás...' : 'Riport generálása'}
          </button>
          {csvExportAvailable && (
            <button
              type="button"
              onClick={() => void handleExportCsv()}
              disabled={exporting}
              className="form-button flex items-center gap-2"
            >
              <Download size={16} />
              {exporting ? 'CSV export...' : 'CSV export'}
            </button>
          )}
          {dailyPdfExportAvailable && (
            <button
              type="button"
              onClick={() => void handleExportDailyPdf()}
              disabled={exporting}
              className="form-button flex items-center gap-2"
            >
              <Download size={16} />
              {exporting ? 'PDF export...' : 'PDF export'}
            </button>
          )}
        </div>
      </div>

      {reportData && (
        <div className="form-panel">
          <h2 className="text-lg font-bold mb-4">{t('reports.riportEredmenyek')}</h2>
          <pre className="bg-gray-50 p-4 rounded overflow-auto max-h-96">{JSON.stringify(reportData, null, 2)}</pre>
        </div>
      )}
    </div>
  )
}

