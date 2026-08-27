import { useState, useEffect, useCallback } from 'react'
import type { ChangeEvent } from 'react'
import {
  UserCheck,
  Search,
  RefreshCw,
  Plus,
  Edit2,
  Trash2,
  AlertTriangle,
  FolderOpen,
  Upload,
} from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import EmployeeSubRecordsModal from './EmployeeSubRecordsModal'
import i18n from '../../i18n'

interface EmployeeItem {
  id: string | number
  lastName?: string
  firstName?: string
  organizationUnit?: string
  jobTitle?: string
  feorCode?: string | null
  employmentStartDate?: string
  active?: boolean
  email?: string | null
  phone?: string | null
}

interface FeorCodeItem {
  id: string | number
  code: string
  title: string
}

interface EmployeeFormState {
  id?: string | number
  lastName: string
  firstName: string
  organizationUnit: string
  jobTitle: string
  feorCode: string
  employmentStartDate: string
  email: string
  phone: string
  active: boolean
}

const readFileAsText = (file: File): Promise<string> =>
  new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(String(reader.result ?? ''))
    reader.onerror = () => reject(reader.error ?? new Error('A fájl nem olvasható.'))
    reader.readAsText(file)
  })

export default function EmployeePage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<EmployeeItem[]>([])
  const [feorCodes, setFeorCodes] = useState<FeorCodeItem[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [importing, setImporting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [subRecordsFor, setSubRecordsFor] = useState<EmployeeItem | null>(null)
  const [form, setForm] = useState<EmployeeFormState | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<EmployeeItem[]>('/employees')
      setItems(safeArray<(typeof items)[0]>(response.data))
    } catch (err) {
      const msg = getErrorMessage(err)
      logger.error('EmployeePage', 'Betöltési hiba:', err)
      setError(msg)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  useEffect(() => {
    let active = true
    api
      .get<FeorCodeItem[]>('/employees/feor-codes')
      .then((response) => {
        if (!active) return
        setFeorCodes(safeArray<FeorCodeItem>(response.data))
      })
      .catch((err) => {
        logger.error('EmployeePage', 'FEOR referencia lista betöltési hiba:', err)
      })
    return () => {
      active = false
    }
  }, [])

  const filtered = items.filter((item) => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some((v) => v != null && String(v).toLowerCase().includes(term))
  })

  const handleDelete = async (id: string | number) => {
    if (!confirm('Biztosan törli?')) return
    try {
      setMessage(null)
      await api.delete(`/employees/${id}`)
      setMessage('Alkalmazott inaktiválva.')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('EmployeePage', 'Törlési hiba:', err)
    }
  }

  const fullName = (item: EmployeeItem) =>
    `${item.lastName ?? ''} ${item.firstName ?? ''}`.trim() || String(item.id)

  const openNewForm = () => {
    setError(null)
    setMessage(null)
    setForm({
      lastName: '',
      firstName: '',
      organizationUnit: '',
      jobTitle: '',
      feorCode: '',
      employmentStartDate: new Date().toISOString().slice(0, 10),
      email: '',
      phone: '',
      active: true,
    })
  }

  const openEditForm = async (item: EmployeeItem) => {
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      const response = await api.get<EmployeeItem>(`/employees/${item.id}`)
      const employee = response.data
      setForm({
        id: employee.id,
        lastName: employee.lastName ?? '',
        firstName: employee.firstName ?? '',
        organizationUnit: employee.organizationUnit ?? '',
        jobTitle: employee.jobTitle ?? '',
        feorCode: employee.feorCode ?? '',
        employmentStartDate: employee.employmentStartDate ?? '',
        email: employee.email ?? '',
        phone: employee.phone ?? '',
        active: employee.active ?? true,
      })
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('EmployeePage', 'Szerkesztési adatok betöltési hiba:', err)
    } finally {
      setSaving(false)
    }
  }

  const saveEmployee = async () => {
    if (!form) return
    const basePayload = {
      lastName: form.lastName.trim(),
      firstName: form.firstName.trim(),
      organizationUnit: form.organizationUnit.trim() || null,
      jobTitle: form.jobTitle.trim() || null,
      feorCode: form.feorCode.trim() || null,
      employmentStartDate: form.employmentStartDate || null,
      email: form.email.trim() || null,
      phone: form.phone.trim() || null,
    }
    try {
      setSaving(true)
      setError(null)
      setMessage(null)
      if (form.id) {
        await api.put(`/employees/${form.id}`, { ...basePayload, active: form.active })
        setMessage('Alkalmazott módosítva.')
      } else {
        await api.post('/employees', basePayload)
        setMessage('Alkalmazott létrehozva.')
      }
      setForm(null)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('EmployeePage', 'Mentési hiba:', err)
    } finally {
      setSaving(false)
    }
  }

  const importEmployees = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    event.target.value = ''
    if (!file) return

    if (!window.confirm('Biztosan importálja a kiválasztott dolgozói JSON fájlt?')) {
      return
    }

    try {
      setImporting(true)
      setError(null)
      setMessage(null)
      const rawJson = await readFileAsText(file)
      JSON.parse(rawJson)
      const response = await api.post<{ imported?: number; message?: string }>(
        '/employees/import',
        rawJson,
        {
          headers: { 'Content-Type': 'application/json' },
        },
      )
      setMessage(response.data?.message ?? `${response.data?.imported ?? 0} dolgozó importálva.`)
      await loadData()
    } catch (err) {
      const msg =
        err instanceof SyntaxError ? 'Érvénytelen dolgozói JSON fájl.' : getErrorMessage(err)
      setError(msg)
      logger.error('EmployeePage', 'Dolgozói JSON import hiba:', err)
    } finally {
      setImporting(false)
    }
  }

  return (
    <div className="form-panel space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="form-title flex items-center gap-2">
          <UserCheck className="h-6 w-6" />
          {t('employees.alkalmazottak')}
        </h1>
        <div className="flex items-center gap-2">
          <label
            className={`form-button flex cursor-pointer items-center gap-1 ${importing ? 'pointer-events-none opacity-60' : ''}`}
          >
            <Upload className="h-4 w-4" />
            {i18n.t('literals.dolgozoi-json-import')}
            <input
              type="file"
              accept="application/json,.json"
              className="hidden"
              disabled={importing}
              onChange={(event) => void importEmployees(event)}
              aria-label="Dolgozói JSON import"
            />
          </label>
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button onClick={openNewForm} className="form-button-primary flex items-center gap-1">
            <Plus className="h-4 w-4" />
            {t('common.new')}
          </button>
        </div>
      </div>

      {form && (
        <div className="rounded border border-gray-200 bg-white p-4 space-y-3">
          <h2 className="text-base font-semibold">
            {form.id ? 'Alkalmazott szerkesztése' : 'Új alkalmazott'}
          </h2>
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <div>
              <label htmlFor="employee-last-name" className="form-label">
                {i18n.t('literals.vezeteknev')}
              </label>
              <input
                id="employee-last-name"
                value={form.lastName}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, lastName: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="employee-first-name" className="form-label">
                {i18n.t('literals.keresztnev')}
              </label>
              <input
                id="employee-first-name"
                value={form.firstName}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, firstName: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="employee-org-unit" className="form-label">
                {i18n.t('literals.szervezeti-egyseg')}
              </label>
              <input
                id="employee-org-unit"
                value={form.organizationUnit}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, organizationUnit: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="employee-job-title" className="form-label">
                {i18n.t('literals.beosztas-2')}
              </label>
              <input
                id="employee-job-title"
                value={form.jobTitle}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, jobTitle: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="employee-feor-code" className="form-label">
                {t('employees.feorKod')}
              </label>
              <select
                id="employee-feor-code"
                value={form.feorCode}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, feorCode: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              >
                <option value="">{t('employees.nincsMegadva')}</option>
                {feorCodes.map((item) => (
                  <option key={item.id} value={item.code}>
                    {item.code}
                    {i18n.t('literals.lit-17')}
                    {item.title}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="employee-start-date" className="form-label">
                {i18n.t('literals.beleptetes')}
              </label>
              <input
                id="employee-start-date"
                type="date"
                value={form.employmentStartDate}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, employmentStartDate: e.target.value } : current,
                  )
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="employee-email" className="form-label">
                {i18n.t('literals.email')}
              </label>
              <input
                id="employee-email"
                value={form.email}
                onChange={(e) =>
                  setForm((current) => (current ? { ...current, email: e.target.value } : current))
                }
                className="form-input w-full"
              />
            </div>
            <div>
              <label htmlFor="employee-phone" className="form-label">
                {i18n.t('literals.telefon')}
              </label>
              <input
                id="employee-phone"
                value={form.phone}
                onChange={(e) =>
                  setForm((current) => (current ? { ...current, phone: e.target.value } : current))
                }
                className="form-input w-full"
              />
            </div>
            <label className="flex items-end gap-2 pb-2 text-sm">
              <input
                type="checkbox"
                checked={form.active}
                onChange={(e) =>
                  setForm((current) =>
                    current ? { ...current, active: e.target.checked } : current,
                  )
                }
              />
              {i18n.t('literals.aktiv-2')}
            </label>
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => void saveEmployee()}
              disabled={saving || !form.lastName.trim() || !form.firstName.trim()}
              className="form-button-primary"
            >
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
            <button type="button" onClick={() => setForm(null)} className="form-button">
              {i18n.t('literals.megse')}
            </button>
          </div>
        </div>
      )}

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Keresés..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10"
          />
        </div>
      </div>

      <div
        className="rounded border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-700"
        data-testid="employee-feor-summary"
      >
        {t('employees.feorReferenciaKodok')}
        {i18n.t('literals.lit-7')} <span className="font-semibold">{feorCodes.length}</span>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      {message && (
        <div className="rounded border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
          {message}
        </div>
      )}

      <div className="grid gap-3 md:hidden">
        {loading ? (
          <div className="rounded border border-gray-200 bg-white p-4 text-center text-sm text-gray-500">
            {i18n.t('literals.betoltes')}
          </div>
        ) : filtered.length === 0 ? (
          <div className="rounded border border-gray-200 bg-white p-4 text-center text-sm text-gray-500">
            {t('common.noData')}
          </div>
        ) : (
          filtered.map((item) => (
            <article
              key={item.id}
              className="rounded border border-gray-200 bg-white p-3 shadow-sm"
              data-testid="employee-mobile-card"
            >
              <div className="mb-3 flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <p className="break-words font-semibold text-gray-900">{fullName(item)}</p>
                  <p className="text-xs text-gray-500">{item.jobTitle ?? '-'}</p>
                  <p className="text-xs text-gray-500">
                    {t('employees.feorPrefix')}
                    {i18n.t('literals.lit-22')}
                    {item.feorCode ?? '-'}
                  </p>
                </div>
                <span className={`badge ${item.active ? 'badge-green' : 'badge-gray'}`}>
                  {item.active ? 'Aktív' : 'Inaktív'}
                </span>
              </div>
              <dl className="grid grid-cols-2 gap-2 text-sm">
                <div className="rounded border border-gray-100 bg-gray-50 px-2 py-1">
                  <dt className="text-[10px] uppercase text-gray-500">{t('branch.branch')}</dt>
                  <dd className="break-words">{item.organizationUnit ?? '-'}</dd>
                </div>
                <div className="rounded border border-gray-100 bg-gray-50 px-2 py-1">
                  <dt className="text-[10px] uppercase text-gray-500">
                    {t('employees.beleptetve')}
                  </dt>
                  <dd>
                    {item.employmentStartDate
                      ? new Date(item.employmentStartDate).toLocaleDateString('hu-HU')
                      : '-'}
                  </dd>
                </div>
              </dl>
              <div className="mt-3 grid grid-cols-3 gap-2">
                <button
                  onClick={() => setSubRecordsFor(item)}
                  className="form-button justify-center p-2 text-green-600"
                  title="Al-nyilvántartások"
                >
                  <FolderOpen className="h-4 w-4" />
                </button>
                <button
                  onClick={() => void openEditForm(item)}
                  disabled={saving}
                  className="form-button justify-center p-2 text-blue-600"
                  title="Szerkesztés"
                >
                  <Edit2 className="h-4 w-4" />
                </button>
                <button
                  onClick={() => handleDelete(item.id)}
                  className="form-button justify-center p-2 text-red-600"
                  title="Törlés"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </article>
          ))
        )}
      </div>

      <div className="data-grid hidden overflow-x-auto md:block">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.name')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('employees.beosztas')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('employees.feorPrefix')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('branch.branch')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('employees.beleptetve')}
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">
                {t('common.active')}
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">
                {t('common.actions')}
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-sm text-gray-500">
                  {i18n.t('literals.betoltes')}
                </td>
              </tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-sm text-gray-500">
                  {t('common.noData')}
                </td>
              </tr>
            ) : (
              filtered.map((item) => (
                <tr key={item.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-sm">{fullName(item)}</td>
                  <td className="px-4 py-3 text-sm">{item.jobTitle ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.feorCode ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">{item.organizationUnit ?? '-'}</td>
                  <td className="px-4 py-3 text-sm">
                    {item.employmentStartDate
                      ? new Date(item.employmentStartDate).toLocaleString('hu-HU')
                      : '-'}
                  </td>
                  <td className="px-4 py-3 text-sm">{item.active ? 'Igen' : 'Nem'}</td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => setSubRecordsFor(item)}
                      className="form-button mr-2 p-1 text-green-600"
                      title="Al-nyilvántartások (üzemorvosi/szabadság/gyerekek)"
                    >
                      <FolderOpen className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => void openEditForm(item)}
                      disabled={saving}
                      className="form-button mr-2 p-1 text-blue-600"
                      title="Szerkesztés"
                    >
                      <Edit2 className="h-4 w-4" />
                    </button>
                    <button
                      onClick={() => handleDelete(item.id)}
                      className="form-button p-1 text-red-600"
                      title="Törlés"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('audit.osszesen')}
        {filtered.length}
        {i18n.t('literals.lit-10')}
        {items.length}
      </div>

      {subRecordsFor && (
        <EmployeeSubRecordsModal
          employeeId={subRecordsFor.id}
          employeeName={fullName(subRecordsFor)}
          onClose={() => setSubRecordsFor(null)}
        />
      )}
    </div>
  )
}
