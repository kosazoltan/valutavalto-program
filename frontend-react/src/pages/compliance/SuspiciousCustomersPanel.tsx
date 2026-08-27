import { useMemo, useState, type ChangeEvent, type FormEvent } from 'react'
import { FileSpreadsheet, Search } from 'lucide-react'
import {
  suspiciousCustomersApi,
  type SuspiciousCustomerDto,
  type SuspiciousCustomerQuery,
} from '../../services/api/suspiciousCustomers'
import type { PagedResponse } from '../../services/api/client'
import { toast } from '../../components/ui/toaster'
import { downloadBlob } from '../../utils/downloadBlob'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { localIsoDate } from '../../utils/dateFormat'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

const XLSX_MIME = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

interface FormState {
  startDate: string
  endDate: string
  byTransactionCount: boolean
  minTransactionCount: string
  byTotalValue: boolean
  minTotalHuf: string
  byBranchCount: boolean
  minBranchCount: string
}

function defaultStartDate(): string {
  const date = new Date()
  date.setDate(date.getDate() - 30)
  return localIsoDate(date)
}

function createInitialForm(): FormState {
  return {
    startDate: defaultStartDate(),
    endDate: localIsoDate(),
    byTransactionCount: true,
    minTransactionCount: '',
    byTotalValue: true,
    minTotalHuf: '',
    byBranchCount: true,
    minBranchCount: '',
  }
}

function toQuery(form: FormState): SuspiciousCustomerQuery {
  return {
    startDate: form.startDate,
    endDate: form.endDate,
    byTransactionCount: form.byTransactionCount,
    minTransactionCount: form.minTransactionCount,
    byTotalValue: form.byTotalValue,
    minTotalHuf: form.minTotalHuf,
    byBranchCount: form.byBranchCount,
    minBranchCount: form.minBranchCount,
  }
}

function formatHuf(value: string | number): string {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed.toLocaleString('hu-HU') : String(value)
}

function badge(label: string, active: boolean) {
  if (!active) return null
  return (
    <span className="rounded bg-red-100 px-2 py-1 text-xs font-semibold text-red-700">{label}</span>
  )
}

export default function SuspiciousCustomersPanel() {
  const [form, setForm] = useState<FormState>(() => createInitialForm())
  const [activeQuery, setActiveQuery] = useState<SuspiciousCustomerQuery | null>(null)
  const [page, setPage] = useState(0)
  const [result, setResult] = useState<PagedResponse<SuspiciousCustomerDto> | null>(null)
  const [loading, setLoading] = useState(false)
  const [exporting, setExporting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const rows = result?.content ?? []
  const totalPages = Math.max(result?.totalPages ?? 0, 1)
  const currentPage = result ? result.number + 1 : page + 1
  const today = useMemo(() => localIsoDate(), [])

  function updateTextField(key: keyof FormState, event: ChangeEvent<HTMLInputElement>): void {
    setForm((current) => ({ ...current, [key]: event.target.value }))
  }

  function updateCheckbox(key: keyof FormState, event: ChangeEvent<HTMLInputElement>): void {
    setForm((current) => ({ ...current, [key]: event.target.checked }))
  }

  async function runSearch(query: SuspiciousCustomerQuery, targetPage: number): Promise<void> {
    setLoading(true)
    setError(null)
    try {
      const data = await suspiciousCustomersApi.search(query, targetPage, 50)
      setResult(data)
      setPage(data.number)
      setActiveQuery(query)
    } catch (err) {
      const message = getErrorMessage(err)
      logger.error('SuspiciousCustomersPanel', 'Gyanús ügyfél lekérdezés sikertelen:', message)
      setError(message)
      toast.error('Lekérdezés sikertelen', message)
    } finally {
      setLoading(false)
    }
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>): void {
    event.preventDefault()
    const query = toQuery(form)
    void runSearch(query, 0)
  }

  function goToPage(targetPage: number): void {
    if (!activeQuery || loading) return
    void runSearch(activeQuery, targetPage)
  }

  async function handleExport(): Promise<void> {
    if (exporting) return
    setExporting(true)
    try {
      const data = await suspiciousCustomersApi.exportXlsx(form.startDate, form.endDate)
      downloadBlob(data, `gyanus_ugyfelek_ertekhatart_elertek_${today}.xlsx`, XLSX_MIME)
      toast.success('Export letöltve')
    } catch (err) {
      const message = await getBlobErrorMessage(err)
      logger.error('SuspiciousCustomersPanel', 'Gyanús ügyfél export sikertelen:', message)
      setError(message)
      toast.error('Export sikertelen', message)
    } finally {
      setExporting(false)
    }
  }

  return (
    <div className="mb-6 overflow-hidden rounded bg-white shadow">
      <div className="bg-purple-100 px-4 py-2 text-purple-900 font-semibold">
        {i18n.t('literals.gyanus-ugyfel-mintak')}
      </div>
      <form onSubmit={handleSubmit} className="space-y-4 p-4">
        <div className="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-4">
          <div>
            <label className="form-label">{i18n.t('literals.kezdo-datum')}</label>
            <input
              type="date"
              value={form.startDate}
              onChange={(event) => updateTextField('startDate', event)}
              className="form-input"
              data-testid="suspicious-start-date"
            />
          </div>
          <div>
            <label className="form-label">{i18n.t('literals.zaro-datum')}</label>
            <input
              type="date"
              value={form.endDate}
              onChange={(event) => updateTextField('endDate', event)}
              className="form-input"
              data-testid="suspicious-end-date"
            />
          </div>
          <div className="flex items-end">
            <button
              type="submit"
              disabled={loading}
              className="form-button-primary w-full justify-center"
              data-testid="suspicious-search-button"
            >
              <Search className="mr-1 h-4 w-4" />
              {loading ? 'Lekérdezés...' : 'Lekérdezés'}
            </button>
          </div>
          <div className="flex items-end">
            <button
              type="button"
              onClick={() => void handleExport()}
              disabled={exporting}
              className="form-button w-full justify-center"
              data-testid="suspicious-export-button"
            >
              <FileSpreadsheet className="mr-1 h-4 w-4" />
              {exporting ? 'Export...' : '10M-et elért ügyfelek (XLSX)'}
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-3 lg:grid-cols-3">
          <label className="rounded border border-slate-200 p-3">
            <span className="flex items-center gap-2 text-sm font-medium text-slate-800">
              <input
                type="checkbox"
                checked={form.byTransactionCount}
                onChange={(event) => updateCheckbox('byTransactionCount', event)}
              />
              {i18n.t('literals.nagy-tranzakcioszam')}
            </span>
            <input
              type="number"
              min="1"
              value={form.minTransactionCount}
              onChange={(event) => updateTextField('minTransactionCount', event)}
              className="form-input mt-2"
              placeholder="alapért. 10"
            />
          </label>
          <label className="rounded border border-slate-200 p-3">
            <span className="flex items-center gap-2 text-sm font-medium text-slate-800">
              <input
                type="checkbox"
                checked={form.byTotalValue}
                onChange={(event) => updateCheckbox('byTotalValue', event)}
              />
              {i18n.t('literals.magas-ossz-tranzakcios-ertek')}
            </span>
            <input
              type="number"
              min="1"
              value={form.minTotalHuf}
              onChange={(event) => updateTextField('minTotalHuf', event)}
              className="form-input mt-2"
              placeholder="alapért. 10 000 000 (értéksáv)"
            />
          </label>
          <label className="rounded border border-slate-200 p-3">
            <span className="flex items-center gap-2 text-sm font-medium text-slate-800">
              <input
                type="checkbox"
                checked={form.byBranchCount}
                onChange={(event) => updateCheckbox('byBranchCount', event)}
              />
              {i18n.t('literals.sok-valtoponton-valtott')}
            </span>
            <input
              type="number"
              min="1"
              value={form.minBranchCount}
              onChange={(event) => updateTextField('minBranchCount', event)}
              className="form-input mt-2"
              placeholder="alapért. 3"
            />
          </label>
        </div>
      </form>

      {error && (
        <div
          className="mx-4 mb-4 rounded border border-red-200 bg-red-50 p-3 text-sm text-red-700"
          role="alert"
        >
          {error}
        </div>
      )}

      {result && (
        <div className="border-t border-slate-200">
          {rows.length === 0 ? (
            <div className="p-6 text-center text-sm text-gray-500">
              {i18n.t('literals.nincs-talalat-a-megadott-szurokkel')}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table
                className="w-full min-w-[760px] text-sm"
                data-testid="suspicious-results-table"
              >
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-4 py-2 text-left">{i18n.t('literals.ugyfel-2')}</th>
                    <th className="px-4 py-2 text-right">{i18n.t('literals.tranzakcioszam')}</th>
                    <th className="px-4 py-2 text-right">{i18n.t('literals.ossz-ertek-ft')}</th>
                    <th className="px-4 py-2 text-right">{i18n.t('literals.valtopontok')}</th>
                    <th className="px-4 py-2 text-left">{i18n.t('literals.talalati-minta')}</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((row) => (
                    <tr key={row.customerId} className="border-t">
                      <td className="px-4 py-2">
                        <div className="font-medium">{row.customerName || row.customerId}</div>
                        <div className="text-xs text-gray-500">{row.customerId}</div>
                      </td>
                      <td className="px-4 py-2 text-right font-mono">{row.transactionCount}</td>
                      <td className="px-4 py-2 text-right font-mono">
                        {formatHuf(row.totalHufAmount)}
                      </td>
                      <td className="px-4 py-2 text-right font-mono">{row.branchCount}</td>
                      <td className="px-4 py-2">
                        <div className="flex flex-wrap gap-1">
                          {badge('Tranzakciószám', row.highTransactionCount)}
                          {badge('Összérték', row.highTotalValue)}
                          {badge('Váltópont', row.manyBranches)}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
          <div className="flex items-center justify-between px-4 py-3 text-sm">
            <span>
              {currentPage}
              {i18n.t('literals.lit-10')}
              {totalPages}
              {i18n.t('literals.oldal-2')}
            </span>
            <div className="space-x-2">
              <button
                type="button"
                disabled={page <= 0 || loading}
                onClick={() => goToPage(Math.max(0, page - 1))}
                className="rounded border px-3 py-1 disabled:opacity-50"
              >
                {i18n.t('literals.elozo-2')}
              </button>
              <button
                type="button"
                disabled={page + 1 >= totalPages || loading}
                onClick={() => goToPage(page + 1)}
                className="rounded border px-3 py-1 disabled:opacity-50"
              >
                {i18n.t('literals.kovetkezo-2')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
