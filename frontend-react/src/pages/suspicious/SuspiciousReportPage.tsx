import { useEffect, useMemo, useState } from 'react'
import { AlertTriangle, FileWarning, Loader2, Plus, RefreshCw, Save } from 'lucide-react'
import { amlApi, type AmlReportDto, type CreateAmlReportRequest } from '../../services/api/aml'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

type FormState = {
  customerId: string
  transactionId: string
  reportType: CreateAmlReportRequest['reportType']
  riskLevel: NonNullable<CreateAmlReportRequest['riskLevel']>
  amountHuf: string
  currencyCode: string
  originalAmount: string
  customerName: string
  documentType: string
  documentNumber: string
  workerNotes: string
}

const initialForm: FormState = {
  customerId: '',
  transactionId: '',
  reportType: 'SUSPICIOUS',
  riskLevel: 'HIGH',
  amountHuf: '',
  currencyCode: 'HUF',
  originalAmount: '',
  customerName: '',
  documentType: '',
  documentNumber: '',
  workerNotes: '',
}

function formatDateTime(value: string | null): string {
  return value ? new Date(value).toLocaleString('hu-HU') : '-'
}

function formatMoney(value: number | null | undefined): string {
  return typeof value === 'number' && Number.isFinite(value)
    ? `${value.toLocaleString('hu-HU')} Ft`
    : '-'
}

export default function SuspiciousReportPage() {
  const [pending, setPending] = useState<AmlReportDto[]>([])
  const [overdue, setOverdue] = useState<AmlReportDto[]>([])
  const [form, setForm] = useState<FormState>(initialForm)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)

  const reports = useMemo(() => {
    const byId = new Map<string, AmlReportDto>()
    for (const item of pending) byId.set(item.id, item)
    for (const item of overdue) byId.set(item.id, { ...item, overdue: true })
    return Array.from(byId.values()).sort((a, b) =>
      (b.createdAt ?? '').localeCompare(a.createdAt ?? ''),
    )
  }, [pending, overdue])

  const load = async () => {
    try {
      setLoading(true)
      setError(null)
      const [pendingReports, overdueReports] = await Promise.all([
        amlApi.pendingReports(),
        amlApi.overdueReports(),
      ])
      setPending(pendingReports)
      setOverdue(overdueReports)
    } catch (err) {
      logger.error('SuspiciousReportPage', 'AML report load failed:', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void load()
  }, [])

  const patch = (values: Partial<FormState>) => setForm((current) => ({ ...current, ...values }))

  const submit = async (event: React.FormEvent) => {
    event.preventDefault()
    const amountHuf = Number(form.amountHuf)
    const transactionId = form.transactionId ? Number(form.transactionId) : undefined
    const originalAmount = form.originalAmount ? Number(form.originalAmount) : undefined

    if (!Number.isFinite(amountHuf) || amountHuf <= 0) {
      setError('A HUF összeg megadása kötelező és pozitív szám kell legyen.')
      return
    }
    if (form.transactionId && (!Number.isInteger(transactionId) || Number(transactionId) <= 0)) {
      setError('A tranzakcióazonosító pozitív egész szám lehet.')
      return
    }

    try {
      setSaving(true)
      setError(null)
      await amlApi.submitReport({
        customerId: form.customerId.trim() || undefined,
        transactionId,
        reportType: form.reportType,
        riskLevel: form.riskLevel,
        amountHuf,
        currencyCode: form.currencyCode.trim() || undefined,
        originalAmount: Number.isFinite(originalAmount) ? originalAmount : undefined,
        customerName: form.customerName.trim() || undefined,
        documentType: form.documentType.trim() || undefined,
        documentNumber: form.documentNumber.trim() || undefined,
        workerNotes: form.workerNotes.trim() || undefined,
      })
      setForm(initialForm)
      setShowForm(false)
      await load()
    } catch (err) {
      logger.error('SuspiciousReportPage', 'AML report submit failed:', err)
      setError(getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <FileWarning />
          {i18n.t('literals.gyanus-ugyletek')}
          <span className="text-sm font-normal text-gray-500">
            {i18n.t('literals.lit-19')}
            {reports.length}
            {i18n.t('literals.nyitott-aml-bejelentes')}
          </span>
        </h1>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => void load()}
            className="form-button flex items-center gap-1"
            disabled={loading || saving}
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            {i18n.t('literals.frissites')}
          </button>
          <button
            type="button"
            onClick={() => setShowForm((value) => !value)}
            className="form-button-primary flex items-center gap-1"
            disabled={saving}
          >
            <Plus size={16} />
            {i18n.t('literals.uj-bejelentes')}
          </button>
        </div>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertTriangle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      {showForm && (
        <form onSubmit={(event) => void submit(event)} className="form-panel space-y-3">
          <h2 className="section-title">{i18n.t('literals.aml-bejelentes-rogzitese')}</h2>
          <div className="grid grid-cols-3 gap-3">
            <label className="block">
              <span className="form-label">{i18n.t('literals.tipus')}</span>
              <select
                className="form-input"
                value={form.reportType}
                onChange={(e) => patch({ reportType: e.target.value as FormState['reportType'] })}
              >
                <option value="SUSPICIOUS">{i18n.t('literals.gyanus')}</option>
                <option value="THRESHOLD">{i18n.t('literals.kuszob')}</option>
                <option value="ENHANCED">{i18n.t('literals.megerositett')}</option>
                <option value="STANDARD">{i18n.t('literals.standard-2')}</option>
              </select>
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.kockazat')}</span>
              <select
                className="form-input"
                value={form.riskLevel}
                onChange={(e) => patch({ riskLevel: e.target.value as FormState['riskLevel'] })}
              >
                <option value="LOW">{i18n.t('literals.alacsony-2')}</option>
                <option value="MEDIUM">{i18n.t('literals.kozepes')}</option>
                <option value="HIGH">{i18n.t('literals.magas-2')}</option>
                <option value="CRITICAL">{i18n.t('literals.kritikus')}</option>
              </select>
            </label>
            <label className="block">
              <span className="form-label required">{i18n.t('literals.huf-osszeg')}</span>
              <input
                className="form-input text-right"
                inputMode="decimal"
                value={form.amountHuf}
                onChange={(e) => patch({ amountHuf: e.target.value })}
                required
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.ugyfel-id-2')}</span>
              <input
                className="form-input"
                value={form.customerId}
                onChange={(e) => patch({ customerId: e.target.value })}
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.ugyfel-neve')}</span>
              <input
                className="form-input"
                value={form.customerName}
                onChange={(e) => patch({ customerName: e.target.value })}
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.tranzakcio-id')}</span>
              <input
                className="form-input text-right"
                inputMode="numeric"
                value={form.transactionId}
                onChange={(e) => patch({ transactionId: e.target.value })}
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.valuta')}</span>
              <input
                className="form-input font-mono uppercase"
                value={form.currencyCode}
                onChange={(e) => patch({ currencyCode: e.target.value.toUpperCase() })}
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.eredeti-osszeg')}</span>
              <input
                className="form-input text-right"
                inputMode="decimal"
                value={form.originalAmount}
                onChange={(e) => patch({ originalAmount: e.target.value })}
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.okmanyszam')}</span>
              <input
                className="form-input font-mono"
                value={form.documentNumber}
                onChange={(e) => patch({ documentNumber: e.target.value })}
              />
            </label>
            <label className="block col-span-3">
              <span className="form-label">{i18n.t('literals.megjegyzes')}</span>
              <textarea
                className="form-input min-h-24"
                value={form.workerNotes}
                onChange={(e) => patch({ workerNotes: e.target.value })}
              />
            </label>
          </div>
          <div className="flex justify-end">
            <button
              type="submit"
              className="form-button-primary flex items-center gap-1"
              disabled={saving}
            >
              <Save size={16} />
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
          </div>
        </form>
      )}

      <div className="form-panel p-0">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{i18n.t('literals.ugyfel-2')}</th>
              <th>{i18n.t('literals.tipus')}</th>
              <th>{i18n.t('literals.kockazat')}</th>
              <th className="text-right">{i18n.t('literals.osszeg')}</th>
              <th>{i18n.t('literals.statusz')}</th>
              <th>{i18n.t('literals.hatarido')}</th>
              <th>{i18n.t('literals.letrehozva-2')}</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={7} className="text-center py-8 text-gray-500">
                  <Loader2 size={18} className="inline animate-spin mr-2" />
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : reports.length === 0 ? (
              <tr>
                <td colSpan={7} className="text-center py-8 text-gray-500">
                  {i18n.t('literals.nincs-nyitott-aml-bejelentes')}
                </td>
              </tr>
            ) : (
              reports.map((report) => (
                <tr key={report.id} className={report.overdue ? 'bg-red-50' : ''}>
                  <td>
                    <div className="font-semibold">
                      {report.customerName || report.customerId || '-'}
                    </div>
                    {report.documentNumber && (
                      <div className="text-xs text-gray-500 font-mono">{report.documentNumber}</div>
                    )}
                  </td>
                  <td className="font-mono text-sm">{report.reportType}</td>
                  <td className="font-mono text-sm">{report.riskLevel}</td>
                  <td className="text-right font-mono">{formatMoney(report.amountHuf)}</td>
                  <td>
                    <span className={`badge ${report.overdue ? 'badge-red' : 'badge-yellow'}`}>
                      {report.status}
                    </span>
                  </td>
                  <td className="text-sm">{formatDateTime(report.deadlineAt)}</td>
                  <td className="text-sm">{formatDateTime(report.createdAt)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
