import { useState, useEffect, useCallback } from 'react'
import { Building2, Plus, Edit2, Trash2, ChevronRight } from 'lucide-react'
import { branchGroupApi, BranchGroup } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { safeArray } from '@/utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface GroupForm {
  code: string
  name: string
  parentGroupId: string
  isActive: boolean
}

const emptyForm: GroupForm = { code: '', name: '', parentGroupId: '', isActive: true }

export default function BranchGroupPage() {
  const { t } = useTranslation()
  const worker = useAuthStore((state) => state.worker)
  const workerId = worker?.id ? String(worker.id) : ''

  const [groups, setGroups] = useState<BranchGroup[]>([])
  const [roots, setRoots] = useState<BranchGroup[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editingLoadingId, setEditingLoadingId] = useState<string | null>(null)
  const [form, setForm] = useState<GroupForm>(emptyForm)
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set())

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const [all, rootGroups] = await Promise.all([
        branchGroupApi.list(),
        branchGroupApi.getRoots().catch(() => []),
      ])
      setGroups(all)
      setRoots(rootGroups as BranchGroup[])
    } catch (err) {
      logger.error('BranchGroupPage', 'Hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const handleSave = async () => {
    if (!form.code || !form.name) {
      toast.warning('Kód és név kötelező')
      return
    }
    try {
      setError(null)
      if (editingId) {
        await branchGroupApi.update(editingId, form)
        toast.success('Fiókcsoport frissítve')
      } else {
        await branchGroupApi.create(form, workerId)
        toast.success('Fiókcsoport létrehozva')
      }
      setShowForm(false)
      setEditingId(null)
      setForm(emptyForm)
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const handleEdit = async (g: BranchGroup) => {
    try {
      setEditingLoadingId(g.id)
      const detail = await branchGroupApi.getById(g.id)
      setForm({
        code: detail.code,
        name: detail.name,
        parentGroupId: detail.parentGroupId || '',
        isActive: detail.isActive,
      })
      setEditingId(detail.id)
      setShowForm(true)
    } catch (err) {
      logger.error('BranchGroupPage', 'Fiókcsoport részlet betöltési hiba:', err)
      toast.error('Hiba', getErrorMessage(err))
    } finally {
      setEditingLoadingId(null)
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törli a fiókcsoportot?')) return
    try {
      await branchGroupApi.delete(id)
      toast.success('Fiókcsoport törölve')
      await loadData()
    } catch (err) {
      toast.error('Hiba', getErrorMessage(err))
    }
  }

  const toggleExpand = (id: string) => {
    setExpandedIds((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const getChildren = (parentId: string) => groups.filter((g) => g.parentGroupId === parentId)

  const renderGroup = (g: BranchGroup, depth: number) => {
    const children = getChildren(g.id)
    const hasChildren = children.length > 0
    const isExpanded = expandedIds.has(g.id)

    return (
      <div key={g.id}>
        <div
          className={`flex items-center gap-2 py-2 px-3 hover:bg-gray-50 border-b ${depth > 0 ? 'ml-' + depth * 6 : ''}`}
          style={{ marginLeft: depth * 24 }}
        >
          {hasChildren ? (
            <button
              onClick={() => toggleExpand(g.id)}
              className="text-gray-400 hover:text-gray-600"
            >
              <ChevronRight
                size={16}
                className={`transition-transform ${isExpanded ? 'rotate-90' : ''}`}
              />
            </button>
          ) : (
            <span className="w-4" />
          )}
          <span className="font-mono text-sm text-gray-500">{g.code}</span>
          <span className="font-medium flex-1">{g.name}</span>
          <span className="text-sm text-gray-500">
            {g.branchIds?.length || 0} {t('branches.fiok')}
          </span>
          <span className={`badge ${g.isActive ? 'badge-green' : 'badge-red'}`}>
            {g.isActive ? 'Aktív' : 'Inaktív'}
          </span>
          <button
            onClick={() => void handleEdit(g)}
            disabled={editingLoadingId === g.id}
            aria-label={`Szerkesztés: ${g.name}`}
            className="form-button text-xs disabled:opacity-50"
          >
            <Edit2 size={12} />
          </button>
          <button
            onClick={() => void handleDelete(g.id)}
            className="form-button text-xs text-red-600"
          >
            <Trash2 size={12} />
          </button>
        </div>
        {isExpanded && children.map((c) => renderGroup(c, depth + 1))}
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Building2 />
          {t('branches.fiokcsoportok')}
        </h1>
        <button
          onClick={() => {
            setShowForm(true)
            setEditingId(null)
            setForm(emptyForm)
          }}
          className="form-button-primary"
        >
          <Plus size={16} />
          {t('branches.ujCsoport')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      {showForm && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">{editingId ? 'Csoport szerkesztése' : 'Új fiókcsoport'}</h2>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="form-label">{t('common.codeRequired')}</label>
              <input
                className="form-input"
                value={form.code}
                onChange={(e) => setForm({ ...form, code: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('common.nameRequired')}</label>
              <input
                className="form-input"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
              />
            </div>
            <div>
              <label className="form-label">{t('branches.szuloCsoport')}</label>
              <select
                className="form-input"
                value={form.parentGroupId}
                onChange={(e) => setForm({ ...form, parentGroupId: e.target.value })}
              >
                <option value="">{t('branches.NincsGyoker')}</option>
                {safeArray<BranchGroup>(groups)
                  .filter((g) => g.id !== editingId)
                  .map((g) => (
                    <option key={g.id} value={g.id}>
                      {g.name}
                    </option>
                  ))}
              </select>
            </div>
          </div>
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              checked={form.isActive}
              onChange={(e) => setForm({ ...form, isActive: e.target.checked })}
            />
            {t('common.active')}
          </label>
          <div className="flex gap-2">
            <button onClick={() => void handleSave()} className="form-button-primary">
              {t('common.save')}
            </button>
            <button
              onClick={() => {
                setShowForm(false)
                setEditingId(null)
              }}
              className="form-button"
            >
              {t('common.cancel')}
            </button>
          </div>
        </div>
      )}

      <div className="form-panel">
        {loading ? (
          <div>{i18n.t('literals.betoltes')}</div>
        ) : safeArray<BranchGroup>(groups).length === 0 ? (
          <div className="text-center text-gray-500 py-4">{t('branches.nincsFiokcsoport')}</div>
        ) : (
          <div>
            {roots.length > 0
              ? roots.map((r) => renderGroup(r, 0))
              : safeArray<BranchGroup>(groups).map((g) => renderGroup(g, 0))}
          </div>
        )}
      </div>
    </div>
  )
}
