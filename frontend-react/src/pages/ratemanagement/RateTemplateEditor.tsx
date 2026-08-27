import { useState, useEffect, useCallback } from 'react'
import { Plus, Save, CheckCircle, Send, XCircle, Trash2 } from 'lucide-react'
import { api } from '../../services/api/index'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

interface RateTemplate {
  id?: string
  currencyId: number
  workgroupId: string
  baseBuyRate: string
  baseSellRate: string
  buySpread: string
  sellSpread: string
  officialRate: string
  limit1Amount: string
  limit1BuyRate: string
  limit1SellRate: string
  limit2Amount: string
  limit2BuyRate: string
  limit2SellRate: string
  limit3Amount: string
  limit3BuyRate: string
  limit3SellRate: string
  roundingRule: number
  status: string
  createdAt?: string
  publishedAt?: string
}

interface Workgroup {
  id: string
  name: string
  code: string
}

interface CurrencyOption {
  id: number
  code: string
  name: string
}

export default function RateTemplateEditor() {
  const { t } = useTranslation()
  const [templates, setTemplates] = useState<RateTemplate[]>([])
  const [workgroups, setWorkgroups] = useState<Workgroup[]>([])
  const [currencies, setCurrencies] = useState<CurrencyOption[]>([])
  const [selectedWorkgroup, setSelectedWorkgroup] = useState<string>('')
  const [editing, setEditing] = useState<RateTemplate | null>(null)
  const [loading, setLoading] = useState(true)
  const [loadingTemplateId, setLoadingTemplateId] = useState<string | null>(null)
  const [batchPublishing, setBatchPublishing] = useState(false)
  const [publishNotes, setPublishNotes] = useState('')
  const [error, setError] = useState<string | null>(null)

  const fetchWorkgroups = useCallback(async () => {
    try {
      const res = await api.get<Workgroup[]>('/rate-management/workgroups')
      const workgroupsData = safeArray<Workgroup>(res?.data)
      setWorkgroups(workgroupsData)
      const firstWorkgroup = workgroupsData[0]
      if (firstWorkgroup) setSelectedWorkgroup(firstWorkgroup.id)
    } catch {
      setError('Munkacsoportok lekérése sikertelen')
    }
  }, [])

  const fetchTemplates = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await api.get<RateTemplate[]>('/rate-management/templates', {
        params: { workgroupId: selectedWorkgroup },
      })
      const templatesData = safeArray<RateTemplate>(res?.data)
      setTemplates(templatesData)
    } catch {
      setError('Sablonok lekérése sikertelen')
    } finally {
      setLoading(false)
    }
  }, [selectedWorkgroup])

  const fetchCurrencies = useCallback(async () => {
    try {
      const res = await api.get<CurrencyOption[]>('/currencies')
      const currenciesData = safeArray<CurrencyOption>(res?.data)
      setCurrencies(currenciesData)
    } catch {
      setCurrencies([])
    }
  }, [])

  useEffect(() => {
    void fetchWorkgroups()
    void fetchCurrencies()
  }, [fetchWorkgroups, fetchCurrencies])

  useEffect(() => {
    if (selectedWorkgroup) {
      void fetchTemplates()
    }
  }, [selectedWorkgroup, fetchTemplates])

  const saveTemplate = useCallback(async () => {
    if (!editing) return
    setError(null)
    if (!editing.currencyId || editing.currencyId <= 0) {
      setError('Valuta kiválasztása kötelező')
      return
    }
    const buyNum = parseFloat(editing.baseBuyRate)
    const sellNum = parseFloat(editing.baseSellRate)
    if (isNaN(buyNum) || buyNum <= 0) {
      setError('Érvényes vételi árfolyam szükséges')
      return
    }
    if (isNaN(sellNum) || sellNum <= 0) {
      setError('Érvényes eladási árfolyam szükséges')
      return
    }
    if (sellNum <= buyNum) {
      setError('Az eladási árfolyamnak nagyobbnak kell lennie a vételinél')
      return
    }
    try {
      if (editing.id) {
        await api.put(`/rate-management/templates/${editing.id}`, editing)
      } else {
        await api.post('/rate-management/templates', editing)
      }
      setEditing(null)
      void fetchTemplates()
    } catch {
      setError('Mentés sikertelen')
    }
  }, [editing, fetchTemplates])

  const editTemplate = useCallback(async (id: string) => {
    setError(null)
    setLoadingTemplateId(id)
    try {
      const res = await api.get<RateTemplate>(`/rate-management/templates/${id}`)
      setEditing(res.data)
    } catch {
      setError('Sablon részleteinek lekérése sikertelen')
    } finally {
      setLoadingTemplateId(null)
    }
  }, [])

  const approveTemplate = useCallback(
    async (id: string) => {
      setError(null)
      try {
        await api.post(`/rate-management/templates/${id}/approve`)
        void fetchTemplates()
      } catch {
        setError('Jóváhagyás sikertelen')
      }
    },
    [fetchTemplates],
  )

  const publishTemplate = useCallback(
    async (id: string) => {
      setError(null)
      try {
        await api.post(`/rate-management/templates/${id}/publish`)
        void fetchTemplates()
      } catch {
        setError('Publikálás sikertelen')
      }
    },
    [fetchTemplates],
  )

  const publishWorkgroupTemplates = useCallback(async () => {
    if (!selectedWorkgroup) {
      setError('Munkacsoport kiválasztása kötelező')
      return
    }
    const templateIds = templates
      .filter((tpl) => tpl.id && (tpl.status === 'DRAFT' || tpl.status === 'APPROVED'))
      .map((tpl) => tpl.id!)
    if (templateIds.length === 0) {
      setError('Nincs publikálható DRAFT vagy APPROVED sablon a munkacsoportban')
      return
    }

    setError(null)
    setBatchPublishing(true)
    try {
      await api.post('/rate-management/publish', {
        workgroupId: selectedWorkgroup,
        templateIds,
        notes: publishNotes.trim() || undefined,
      })
      setPublishNotes('')
      void fetchTemplates()
    } catch {
      setError('Munkacsoport publikálás sikertelen')
    } finally {
      setBatchPublishing(false)
    }
  }, [fetchTemplates, publishNotes, selectedWorkgroup, templates])

  const revokeTemplate = useCallback(
    async (id: string) => {
      setError(null)
      try {
        await api.post(`/rate-management/templates/${id}/revoke`)
        void fetchTemplates()
      } catch {
        setError('Visszavonás sikertelen')
      }
    },
    [fetchTemplates],
  )

  const deleteTemplate = useCallback(
    async (id: string) => {
      if (!confirm('Biztosan torli a sablont?')) return
      setError(null)
      try {
        await api.delete(`/rate-management/templates/${id}`)
        void fetchTemplates()
      } catch {
        setError('Törlés sikertelen')
      }
    },
    [fetchTemplates],
  )

  const statusBadge = (status: string) => {
    switch (status) {
      case 'DRAFT':
        return (
          <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-secondary text-secondary-foreground">
            {t('ratemanagement.piszkozat')}
          </span>
        )
      case 'APPROVED':
        return (
          <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-blue-500 text-white">
            {t('ratemanagement.jovahagyva')}
          </span>
        )
      case 'PUBLISHED':
        return (
          <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-500 text-white">
            {t('ratemanagement.publikalva')}
          </span>
        )
      case 'REVOKED':
        return (
          <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-destructive text-destructive-foreground">
            {t('ratemanagement.visszavonva')}
          </span>
        )
      default:
        return (
          <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-primary text-primary-foreground">
            {status}
          </span>
        )
    }
  }

  const newTemplate = (): RateTemplate => ({
    currencyId: currencies[0]?.id ?? 0,
    workgroupId: selectedWorkgroup,
    baseBuyRate: '',
    baseSellRate: '',
    buySpread: '0',
    sellSpread: '0',
    officialRate: '',
    limit1Amount: '',
    limit1BuyRate: '',
    limit1SellRate: '',
    limit2Amount: '',
    limit2BuyRate: '',
    limit2SellRate: '',
    limit3Amount: '',
    limit3BuyRate: '',
    limit3SellRate: '',
    roundingRule: 0,
    status: 'DRAFT',
  })

  return (
    <div className="space-y-4">
      {/* Error display */}
      {error && (
        <div className="rounded-md bg-destructive/10 border border-destructive/20 p-3 text-sm text-destructive">
          {error}
        </div>
      )}

      {/* Workgroup selector */}
      <div className="flex items-center gap-3">
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
          onClick={() => setEditing(newTemplate())}
        >
          <Plus className="h-4 w-4 mr-1" />
          {t('ratemanagement.ujSablon')}
        </button>
        <input
          className="min-w-[220px] rounded border px-3 py-2 text-sm"
          value={publishNotes}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => setPublishNotes(e.target.value)}
          placeholder="Publikálási megjegyzés"
          aria-label="Publikálási megjegyzés"
        />
        <button
          className="inline-flex items-center justify-center rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
          onClick={() => void publishWorkgroupTemplates()}
          disabled={batchPublishing || !selectedWorkgroup}
          data-testid="rate-management-publish-batch"
        >
          <Send className="h-4 w-4 mr-1" />
          {batchPublishing ? 'Publikálás...' : 'Munkacsoport publikálása'}
        </button>
      </div>

      {/* Edit form */}
      {editing && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold">
              {editing.id ? 'Sablon szerkesztése' : 'Új árfolyam sablon'}
            </h3>
          </div>
          <div className="p-4">
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="text-sm font-medium">{t('common.currency')}</label>
                <select
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.currencyId}
                  onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
                    setEditing({ ...editing, currencyId: Number(e.target.value) })
                  }
                >
                  <option value={0}>{i18n.t('literals.valassz-valutat-2')}</option>
                  {currencies.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.code}
                      {i18n.t('literals.lit-17')}
                      {c.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-sm font-medium">{t('ratemanagement.veteliArfolyam')}</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.baseBuyRate}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setEditing({ ...editing, baseBuyRate: e.target.value })
                  }
                  placeholder="pl. 385.50"
                />
              </div>
              <div>
                <label className="text-sm font-medium">{t('ratemanagement.eladasiArfolyam')}</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.baseSellRate}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setEditing({ ...editing, baseSellRate: e.target.value })
                  }
                  placeholder="pl. 395.50"
                />
              </div>
              <div>
                <label className="text-sm font-medium">{t('ratemanagement.veteliFelar')}</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.buySpread}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setEditing({ ...editing, buySpread: e.target.value })
                  }
                />
              </div>
              <div>
                <label className="text-sm font-medium">{t('ratemanagement.eladasiFelar')}</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.sellSpread}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setEditing({ ...editing, sellSpread: e.target.value })
                  }
                />
              </div>
              <div>
                <label className="text-sm font-medium">{t('ratemanagement.kerekites')}</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.roundingRule}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setEditing({ ...editing, roundingRule: parseInt(e.target.value, 10) || 0 })
                  }
                />
              </div>
              <div>
                <label className="text-sm font-medium">
                  {t('ratemanagement.hivatalosMnbArfolyam')}
                </label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm bg-blue-50 dark:bg-blue-950/30"
                  value={editing.officialRate}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                    setEditing({ ...editing, officialRate: e.target.value })
                  }
                  placeholder="pl. 390.00"
                />
              </div>
            </div>

            {/* Limit szintek */}
            <div className="mt-4">
              <h4 className="text-sm font-medium mb-2">{t('ratemanagement.limitSzintek')}</h4>
              <div className="grid grid-cols-3 gap-4">
                {([1, 2, 3] as const).map((level) => {
                  const amountKey = `limit${level}Amount` as keyof RateTemplate
                  const buyKey = `limit${level}BuyRate` as keyof RateTemplate
                  const sellKey = `limit${level}SellRate` as keyof RateTemplate
                  return (
                    <div key={level} className="space-y-2 rounded-md border p-3">
                      <h5 className="text-xs font-semibold text-muted-foreground uppercase">
                        {t('components.limit')}
                        {level}
                      </h5>
                      <div>
                        <label className="text-xs text-muted-foreground">
                          {t('ratemanagement.osszegFt')}
                        </label>
                        <input
                          className="flex h-8 w-full rounded-md border px-2 py-1 text-xs font-mono"
                          value={editing[amountKey] as string}
                          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                            setEditing({ ...editing, [amountKey]: e.target.value })
                          }
                          placeholder={`pl. ${level * 100000}`}
                        />
                      </div>
                      <div className="grid grid-cols-2 gap-2">
                        <div>
                          <label className="text-xs text-muted-foreground">
                            {t('cashier.buy')}
                          </label>
                          <input
                            className="flex h-8 w-full rounded-md border px-2 py-1 text-xs font-mono"
                            value={editing[buyKey] as string}
                            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                              setEditing({ ...editing, [buyKey]: e.target.value })
                            }
                          />
                        </div>
                        <div>
                          <label className="text-xs text-muted-foreground">
                            {t('cashier.sell')}
                          </label>
                          <input
                            className="flex h-8 w-full rounded-md border px-2 py-1 text-xs font-mono"
                            value={editing[sellKey] as string}
                            onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                              setEditing({ ...editing, [sellKey]: e.target.value })
                            }
                          />
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
            <div className="flex gap-2 mt-4">
              <button
                className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                onClick={saveTemplate}
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

      {/* Template list */}
      {loading ? (
        <p>{t('common.loading')}</p>
      ) : templates.length === 0 ? (
        <div className="text-center py-8 text-muted-foreground">
          {t('ratemanagement.nincsArfolyamSablonEbbenAMunkacsoportban')}
        </div>
      ) : (
        <div className="space-y-2">
          {templates.map((tpl) => (
            <div key={tpl.id} className="rounded-lg border bg-card shadow-sm">
              <div className="p-4 flex items-center justify-between">
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    { }
                    <span className="font-mono font-medium">
                      {i18n.t('literals.vetel-2')}
                      {tpl.baseBuyRate}
                      {i18n.t('literals.eladas-2')}
                      {tpl.baseSellRate}
                    </span>
                    {statusBadge(tpl.status)}
                  </div>
                  { }
                  <p className="text-sm text-muted-foreground">
                    {i18n.t('literals.spread')}
                    {tpl.buySpread}
                    {i18n.t('literals.lit-42')}
                    {tpl.sellSpread}
                    {i18n.t('literals.kerekites-2')}
                    {tpl.roundingRule}
                  </p>
                  { }
                </div>
                <div className="flex gap-1">
                  {tpl.status === 'DRAFT' && (
                    <>
                      <button
                        className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                        onClick={() => tpl.id && void editTemplate(tpl.id)}
                        disabled={loadingTemplateId === tpl.id}
                      >
                        {loadingTemplateId === tpl.id
                          ? t('common.loading')
                          : t('ratemanagement.szerkesztes')}
                      </button>
                      <button
                        className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                        onClick={() => tpl.id && approveTemplate(tpl.id)}
                      >
                        <CheckCircle className="h-4 w-4 mr-1" />
                        {t('ratemanagement.jovahagyas')}
                      </button>
                      <button
                        className="inline-flex items-center justify-center rounded-md bg-destructive px-3 py-1.5 text-xs font-medium text-destructive-foreground hover:bg-destructive/90"
                        onClick={() => tpl.id && deleteTemplate(tpl.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </>
                  )}
                  {tpl.status === 'APPROVED' && (
                    <button
                      className="inline-flex items-center justify-center rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                      onClick={() => tpl.id && publishTemplate(tpl.id)}
                    >
                      <Send className="h-4 w-4 mr-1" />
                      {t('ratemanagement.publikalas')}
                    </button>
                  )}
                  {(tpl.status === 'PUBLISHED' || tpl.status === 'APPROVED') && (
                    <button
                      className="inline-flex items-center justify-center rounded-md bg-destructive px-3 py-1.5 text-xs font-medium text-destructive-foreground hover:bg-destructive/90"
                      onClick={() => tpl.id && revokeTemplate(tpl.id)}
                    >
                      <XCircle className="h-4 w-4 mr-1" />
                      {t('ratemanagement.visszavonas')}
                    </button>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
