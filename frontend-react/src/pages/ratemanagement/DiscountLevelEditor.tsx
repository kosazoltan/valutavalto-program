import { useState, useEffect, useCallback } from 'react'
import { Percent, Plus, Save } from 'lucide-react'
import { api } from '../../services/api/index'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface Workgroup {
  id: string
  name: string
  code: string
}

interface Discount {
  id?: string
  workgroupId: string
  level: number
  name: string
  buyDiscountPercent: string
  sellDiscountPercent: string
  active: boolean
}

export default function DiscountLevelEditor() {
  const { t } = useTranslation()
  const [workgroups, setWorkgroups] = useState<Workgroup[]>([])
  const [selectedWorkgroup, setSelectedWorkgroup] = useState('')
  const [discounts, setDiscounts] = useState<Discount[]>([])
  const [editing, setEditing] = useState<Discount | null>(null)
  const [loading, setLoading] = useState(false)

  const fetchWorkgroups = useCallback(async () => {
    try {
      const res = await api.get<Workgroup[]>('/rate-management/workgroups')
      const workgroupsData = safeArray<Workgroup>(res?.data)
      setWorkgroups(workgroupsData)
      const firstWorkgroup = workgroupsData[0]
      if (firstWorkgroup) setSelectedWorkgroup(firstWorkgroup.id)
    } catch {
      // Intentionally ignored here; the UI remains usable without workgroups.
    }
  }, [])

  const fetchDiscounts = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get<Discount[]>(`/rate-management/discounts/${selectedWorkgroup}`)
      const discountsData = safeArray<Discount>(res?.data)
      setDiscounts(discountsData)
    } catch {
      setDiscounts([])
    } finally {
      setLoading(false)
    }
  }, [selectedWorkgroup])

  useEffect(() => {
    void fetchWorkgroups()
  }, [fetchWorkgroups])

  useEffect(() => {
    if (selectedWorkgroup) {
      void fetchDiscounts()
    }
  }, [selectedWorkgroup, fetchDiscounts])

  const saveDiscount = useCallback(async () => {
    if (!editing) return
    try {
      if (editing.id) {
        await api.put(`/rate-management/discounts/${editing.id}`, editing)
      } else {
        await api.post('/rate-management/discounts', editing)
      }
      setEditing(null)
      void fetchDiscounts()
    } catch {
      // Save error is intentionally silent in this lightweight admin editor.
    }
  }, [editing, fetchDiscounts])

  const newDiscount = (): Discount => ({
    workgroupId: selectedWorkgroup,
    level: discounts.length + 1,
    name: '',
    buyDiscountPercent: '0',
    sellDiscountPercent: '0',
    active: true,
  })

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Percent className="h-5 w-5" />
        <label className="font-medium text-sm">{t('ratemanagement.munkacsoport')}</label>
        <select
          className="border rounded px-3 py-2 text-sm"
          value={selectedWorkgroup}
          onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
            setSelectedWorkgroup(e.target.value)
          }
        >
          {workgroups.map((wg) => (
            <option key={wg.id} value={wg.id}>
              {wg.name}
              {i18n.t('literals.lit')}
              {wg.code}
              {i18n.t('literals.lit-2')}
            </option>
          ))}
        </select>
        <button
          className="inline-flex items-center justify-center rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
          onClick={() => setEditing(newDiscount())}
          disabled={discounts.length >= 3}
        >
          <Plus className="h-4 w-4 mr-1" />
          {t('ratemanagement.ujSzint')}
        </button>
      </div>

      {editing && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4">
            <div className="grid grid-cols-4 gap-4">
              <div>
                <label className="text-sm font-medium">{t('ratemanagement.szint')}</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.level}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setEditing({ ...editing, level: parseInt(e.target.value, 10) || 1 })
                  }
                  min={1}
                  max={3}
                />
              </div>
              <div>
                <label className="text-sm font-medium">{t('competitors.nev')}</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.name}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setEditing({ ...editing, name: e.target.value })
                  }
                  placeholder="pl. VIP"
                />
              </div>
              <div>
                <label className="text-sm font-medium">
                  {t('ratemanagement.veteliKedvezmeny')}
                </label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.buyDiscountPercent}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setEditing({ ...editing, buyDiscountPercent: e.target.value })
                  }
                />
              </div>
              <div>
                <label className="text-sm font-medium">
                  {t('ratemanagement.eladasiKedvezmeny')}
                </label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.sellDiscountPercent}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setEditing({ ...editing, sellDiscountPercent: e.target.value })
                  }
                />
              </div>
            </div>
            <div className="flex gap-2 mt-4">
              <button
                className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                onClick={saveDiscount}
              >
                <Save className="h-4 w-4 mr-2" />
                {t('common.save')}
              </button>
              <button
                className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
                onClick={() => setEditing(null)}
              >
                {t('common.cancel')}
              </button>
            </div>
          </div>
        </div>
      )}

      {loading ? (
        <p>{i18n.t('literals.betoltes')}</p>
      ) : discounts.length === 0 ? (
        <div className="text-center py-8 text-muted-foreground">
          {t('ratemanagement.nincsKedvezmenySzintMax3SzintAdhatoHozza')}
        </div>
      ) : (
        <div className="space-y-2">
          {discounts.map((d) => (
            <div key={d.id} className="rounded-lg border bg-card shadow-sm">
              <div className="p-3 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium border bg-transparent">
                    {t('ratemanagement.szint')}
                    {d.level}
                  </span>
                  <span className="font-medium">{d.name}</span>
                  <span className="text-sm text-muted-foreground">
                    {t('ratemanagement.vetel')}
                    {d.buyDiscountPercent}
                    {t('ratemanagement.eladas')}
                    {d.sellDiscountPercent}
                    {i18n.t('literals.lit-30')}
                  </span>
                </div>
                <div className="flex items-center gap-2">
                  <span
                    className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                      d.active
                        ? 'bg-primary text-primary-foreground'
                        : 'bg-secondary text-secondary-foreground'
                    }`}
                  >
                    {d.active ? 'Aktív' : 'Inaktív'}
                  </span>
                  <button
                    className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                    onClick={() => setEditing(d)}
                  >
                    {t('common.edit')}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
