import { useState, useEffect, useCallback } from 'react'
import { UserCheck, Search, RefreshCw, Plus, Edit2, Trash2, AlertTriangle, FolderOpen } from 'lucide-react'
import { api } from '../../services/api/index'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import EmployeeSubRecordsModal from './EmployeeSubRecordsModal'

interface EmployeeItem {
  id: string | number
  fullName?: string
  position?: string
  branchName?: string
  hireDate?: string
  isActive?: boolean
}

export default function EmployeePage() {
  const { t } = useTranslation()
  const [items, setItems] = useState<EmployeeItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [subRecordsFor, setSubRecordsFor] = useState<EmployeeItem | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await api.get<EmployeeItem[]>('/employees')
      setItems(safeArray<typeof items[0]>(response.data))
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

  const filtered = items.filter(item => {
    if (!searchTerm) return true
    const term = searchTerm.toLowerCase()
    return Object.values(item).some(v =>
      v != null && String(v).toLowerCase().includes(term)
    )
  })

  const handleDelete = async (id: string | number) => {
    if (!confirm('Biztosan törli?')) return
    try {
      await api.delete(`/employees/${id}`)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      logger.error('EmployeePage', 'Törlési hiba:', err)
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
          <button onClick={() => void loadData()} className="form-button p-2" title="Frissítés">
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button className="form-button-primary flex items-center gap-1">
            <Plus className="h-4 w-4" />{t('common.new')}
          </button>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Keresés..."
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            className="form-input w-full pl-10"
          />
        </div>
      </div>

      {error && (
        <div className="form-error flex items-center gap-2">
          <AlertTriangle className="h-4 w-4" />
          {error}
        </div>
      )}

      <div className="data-grid overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('common.name')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('employees.beosztas')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('branch.branch')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('employees.beleptetve')}</th>
              <th className="px-4 py-3 text-left text-xs font-medium uppercase text-gray-500">{t('common.active')}</th>
              <th className="px-4 py-3 text-right text-xs font-medium uppercase text-gray-500">{t('common.actions')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {loading ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">Betöltés...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-sm text-gray-500">{t('common.noData')}</td></tr>
            ) : filtered.map(item => (
              <tr key={item.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm">{item.fullName ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.position ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.branchName ?? '-'}</td>
                <td className="px-4 py-3 text-sm">{item.hireDate ? new Date(item.hireDate).toLocaleString('hu-HU') : '-'}</td>
                <td className="px-4 py-3 text-sm">{item.isActive ? 'Igen' : 'Nem'}</td>
                <td className="px-4 py-3 text-right">
                  <button onClick={() => setSubRecordsFor(item)} className="form-button mr-2 p-1 text-green-600" title="Al-nyilvántartások (üzemorvosi/szabadság/gyerekek)">
                    <FolderOpen className="h-4 w-4" />
                  </button>
                  <button className="form-button mr-2 p-1 text-blue-600" title="Szerkesztés">
                    <Edit2 className="h-4 w-4" />
                  </button>
                  <button onClick={() => handleDelete(item.id)} className="form-button p-1 text-red-600" title="Törlés">
                    <Trash2 className="h-4 w-4" />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="text-sm text-gray-500">
        {t('audit.osszesen')}{filtered.length} / {items.length}
      </div>

      {subRecordsFor && (
        <EmployeeSubRecordsModal
          employeeId={subRecordsFor.id}
          employeeName={subRecordsFor.fullName ?? String(subRecordsFor.id)}
          onClose={() => setSubRecordsFor(null)}
        />
      )}
    </div>
  )
}
