import { useEffect, useState, useCallback } from 'react'
import { FileWarning, Plus, Check, RefreshCw } from 'lucide-react'
import { documentShortageApi, type DocumentShortage } from '../../services/api/documentShortages'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { safeArray } from '../../utils/safeArray'
import i18n from '../../i18n'

/**
 * Okmányhiány-regiszter (legacy OKMANYHIANY / OKMCTRL.dll).
 * Hiányos okmánnyal rögzített tranzakciók követő-listája: rögzítés + lezárás (pótolva).
 */
export default function DocumentShortagePage() {
  const [items, setItems] = useState<DocumentShortage[]>([])
  const [openOnly, setOpenOnly] = useState(true)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState({
    missingDocument: '',
    customerName: '',
    branchCode: '',
    receiptNumber: '',
    note: '',
  })

  const load = useCallback(async (open: boolean) => {
    try {
      setLoading(true)
      setItems(safeArray(await documentShortageApi.list(open)))
      setError(null)
    } catch (err) {
      setError(getErrorMessage(err))
      logger.error('DocumentShortagePage', 'load', err)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void load(openOnly)
  }, [load, openOnly])

  const add = async () => {
    if (!form.missingDocument.trim()) {
      setError('A hiányzó okmány megnevezése kötelező.')
      return
    }
    try {
      await documentShortageApi.create({
        missingDocument: form.missingDocument.trim(),
        customerName: form.customerName.trim() || undefined,
        branchCode: form.branchCode.trim() || undefined,
        receiptNumber: form.receiptNumber.trim() || undefined,
        note: form.note.trim() || undefined,
      })
      setForm({
        missingDocument: '',
        customerName: '',
        branchCode: '',
        receiptNumber: '',
        note: '',
      })
      await load(openOnly)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const resolve = async (id: string) => {
    try {
      await documentShortageApi.resolve(id)
      await load(openOnly)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <FileWarning className="h-6 w-6" />
          {i18n.t('literals.okmanyhiany-regiszter')}
        </h1>
        <div className="flex items-center gap-2">
          <label className="text-sm flex items-center gap-1">
            <input
              type="checkbox"
              checked={openOnly}
              onChange={(e) => setOpenOnly(e.target.checked)}
            />
            {i18n.t('literals.csak-nyitott')}
          </label>
          <button onClick={() => void load(openOnly)} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {error && <div className="form-error">{error}</div>}

      <div className="grid grid-cols-12 gap-2 items-end">
        <div className="col-span-3">
          <label className="form-label required">{i18n.t('literals.hianyzo-okmany')}</label>
          <input
            className="form-input"
            value={form.missingDocument}
            onChange={(e) => setForm((f) => ({ ...f, missingDocument: e.target.value }))}
            placeholder="pl. Lakcímkártya"
          />
        </div>
        <div className="col-span-3">
          <label className="form-label">{i18n.t('literals.ugyfel-2')}</label>
          <input
            className="form-input"
            value={form.customerName}
            onChange={(e) => setForm((f) => ({ ...f, customerName: e.target.value }))}
          />
        </div>
        <div className="col-span-2">
          <label className="form-label">{i18n.t('literals.iroda-kod')}</label>
          <input
            className="form-input"
            value={form.branchCode}
            onChange={(e) => setForm((f) => ({ ...f, branchCode: e.target.value }))}
          />
        </div>
        <div className="col-span-2">
          <label className="form-label">{i18n.t('literals.bizonylatszam-2')}</label>
          <input
            className="form-input"
            value={form.receiptNumber}
            onChange={(e) => setForm((f) => ({ ...f, receiptNumber: e.target.value }))}
          />
        </div>
        <div className="col-span-2">
          <button
            onClick={() => void add()}
            className="form-button-primary flex items-center gap-1 w-full justify-center"
          >
            <Plus className="h-4 w-4" />
            {i18n.t('literals.rogzit')}
          </button>
        </div>
      </div>

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.rogzitve')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.iroda')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.ugyfel-2')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.bizonylat')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.hianyzo-okmany')}
              </th>
              <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                {i18n.t('literals.allapot')}
              </th>
              <th className="px-3 py-2"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {items.length === 0 && (
              <tr>
                <td colSpan={7} className="px-3 py-4 text-center text-gray-400">
                  {i18n.t('literals.nincs-tetel')}
                </td>
              </tr>
            )}
            {items.map((it) => (
              <tr key={it.id}>
                <td className="px-3 py-2 text-sm">
                  {it.recordedAt?.slice(0, 16).replace('T', ' ')}
                </td>
                <td className="px-3 py-2 text-sm font-mono">{it.branchCode}</td>
                <td className="px-3 py-2 text-sm">{it.customerName}</td>
                <td className="px-3 py-2 text-sm font-mono">{it.receiptNumber}</td>
                <td className="px-3 py-2 text-sm">{it.missingDocument}</td>
                <td className="px-3 py-2 text-sm">
                  {it.resolvedAt ? (
                    <span className="text-green-600">
                      {i18n.t('literals.potolva')}
                      {it.resolvedAt.slice(0, 10)}
                      {i18n.t('literals.lit-2')}
                    </span>
                  ) : (
                    <span className="text-orange-600">{i18n.t('literals.nyitott')}</span>
                  )}
                </td>
                <td className="px-3 py-2 text-right">
                  {!it.resolvedAt && (
                    <button
                      onClick={() => void resolve(it.id)}
                      className="text-green-600 hover:text-green-800 flex items-center gap-1 text-sm"
                      title="Pótolva"
                    >
                      <Check className="h-4 w-4" />
                      {i18n.t('literals.potolva-2')}
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
