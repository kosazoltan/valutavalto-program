import { useState, useEffect } from 'react'
import { Plus, Save, CheckCircle, Send, XCircle, Trash2 } from 'lucide-react'
import { api } from '../../services/api'

interface RateTemplate {
  id?: string
  currencyId: number | string
  workgroupId: string
  baseBuyRate: string
  baseSellRate: string
  buySpread: string
  sellSpread: string
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

export default function RateTemplateEditor() {
  const [templates, setTemplates] = useState<RateTemplate[]>([])
  const [workgroups, setWorkgroups] = useState<Workgroup[]>([])
  const [selectedWorkgroup, setSelectedWorkgroup] = useState<string>('')
  const [editing, setEditing] = useState<RateTemplate | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchWorkgroups()
  }, [])

  useEffect(() => {
    if (selectedWorkgroup) fetchTemplates()
  }, [selectedWorkgroup])

  const fetchWorkgroups = async () => {
    try {
      const { data } = await api.get<Workgroup[]>('/rate-management/workgroups')
      setWorkgroups(data)
      if (data.length > 0) setSelectedWorkgroup(data[0].id)
    } catch (err) {
      console.error('Munkacsoport lekeres sikertelen:', err)
      setError('Munkacsoportok lekérése sikertelen')
    }
  }

  const fetchTemplates = async () => {
    setLoading(true)
    setError(null)
    try {
      const { data } = await api.get<RateTemplate[]>('/rate-management/templates', {
        params: { workgroupId: selectedWorkgroup }
      })
      setTemplates(data)
    } catch (err) {
      console.error('Sablon lekeres sikertelen:', err)
      setError('Sablonok lekérése sikertelen')
    } finally {
      setLoading(false)
    }
  }

  const saveTemplate = async () => {
    if (!editing) return
    setError(null)
    try {
      if (editing.id) {
        await api.put(`/rate-management/templates/${editing.id}`, editing)
      } else {
        await api.post('/rate-management/templates', editing)
      }
      setEditing(null)
      fetchTemplates()
    } catch (err) {
      console.error('Mentes sikertelen:', err)
      setError('Mentés sikertelen')
    }
  }

  const approveTemplate = async (id: string) => {
    setError(null)
    try {
      await api.post(`/rate-management/templates/${id}/approve`)
      fetchTemplates()
    } catch (err) {
      console.error('Jovahagyas sikertelen:', err)
      setError('Jóváhagyás sikertelen')
    }
  }

  const publishTemplate = async (id: string) => {
    setError(null)
    try {
      await api.post(`/rate-management/templates/${id}/publish`)
      fetchTemplates()
    } catch (err) {
      console.error('Publikalas sikertelen:', err)
      setError('Publikálás sikertelen')
    }
  }

  const revokeTemplate = async (id: string) => {
    setError(null)
    try {
      await api.post(`/rate-management/templates/${id}/revoke`)
      fetchTemplates()
    } catch (err) {
      console.error('Visszavonas sikertelen:', err)
      setError('Visszavonás sikertelen')
    }
  }

  const deleteTemplate = async (id: string) => {
    if (!confirm('Biztosan torli a sablont?')) return
    setError(null)
    try {
      await api.delete(`/rate-management/templates/${id}`)
      fetchTemplates()
    } catch (err) {
      console.error('Torles sikertelen:', err)
      setError('Törlés sikertelen')
    }
  }

  const statusBadge = (status: string) => {
    switch (status) {
      case 'DRAFT':
        return <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-secondary text-secondary-foreground">Piszkozat</span>
      case 'APPROVED':
        return <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-blue-500 text-white">Jovahagyva</span>
      case 'PUBLISHED':
        return <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-green-500 text-white">Publikalva</span>
      case 'REVOKED':
        return <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-destructive text-destructive-foreground">Visszavonva</span>
      default:
        return <span className="inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium bg-primary text-primary-foreground">{status}</span>
    }
  }

  const newTemplate = (): RateTemplate => ({
    currencyId: '',  // will be parsed to number before sending
    workgroupId: selectedWorkgroup,
    baseBuyRate: '',
    baseSellRate: '',
    buySpread: '0',
    sellSpread: '0',
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
        <label className="font-medium text-sm">Munkacsoport:</label>
        <select
          className="border rounded px-3 py-2 text-sm"
          value={selectedWorkgroup}
          onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setSelectedWorkgroup(e.target.value)}
        >
          {workgroups.map((wg) => (
            <option key={wg.id} value={wg.id}>{wg.name} ({wg.code})</option>
          ))}
        </select>
        <button
          className="inline-flex items-center justify-center rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
          onClick={() => setEditing(newTemplate())}
        >
          <Plus className="h-4 w-4 mr-1" />
          Uj sablon
        </button>
      </div>

      {/* Edit form */}
      {editing && (
        <div className="rounded-lg border bg-card shadow-sm">
          <div className="p-4 pb-2">
            <h3 className="text-lg font-semibold">{editing.id ? 'Sablon szerkesztese' : 'Uj arfolyam sablon'}</h3>
          </div>
          <div className="p-4">
            <div className="grid grid-cols-3 gap-4">
              <div>
                <label className="text-sm font-medium">Valuta ID</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.currencyId}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, currencyId: e.target.value ? parseInt(e.target.value, 10) : '' })}
                  placeholder="Valuta ID (szam)"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Veteli arfolyam</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.baseBuyRate}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, baseBuyRate: e.target.value })}
                  placeholder="pl. 385.50"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Eladasi arfolyam</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.baseSellRate}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, baseSellRate: e.target.value })}
                  placeholder="pl. 395.50"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Veteli felar</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.buySpread}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, buySpread: e.target.value })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Eladasi felar</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  value={editing.sellSpread}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, sellSpread: e.target.value })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Kerekites</label>
                <input
                  className="flex h-10 w-full rounded-md border px-3 py-2 text-sm"
                  type="number"
                  value={editing.roundingRule}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => setEditing({ ...editing, roundingRule: parseInt(e.target.value, 10) || 0 })}
                />
              </div>
            </div>
            <div className="flex gap-2 mt-4">
              <button
                className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                onClick={saveTemplate}
              >
                <Save className="h-4 w-4 mr-2" />
                Mentes
              </button>
              <button
                className="inline-flex items-center justify-center rounded-md border px-4 py-2 text-sm font-medium hover:bg-muted disabled:opacity-50"
                onClick={() => setEditing(null)}
              >
                Megse
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Template list */}
      {loading ? (
        <p>Betoltes...</p>
      ) : templates.length === 0 ? (
        <div className="text-center py-8 text-muted-foreground">Nincs arfolyam sablon ebben a munkacsoportban</div>
      ) : (
        <div className="space-y-2">
          {templates.map((t) => (
            <div key={t.id} className="rounded-lg border bg-card shadow-sm">
              <div className="p-4 flex items-center justify-between">
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="font-mono font-medium">Vetel: {t.baseBuyRate} | Eladas: {t.baseSellRate}</span>
                    {statusBadge(t.status)}
                  </div>
                  <p className="text-sm text-muted-foreground">
                    Spread: +{t.buySpread} / +{t.sellSpread} | Kerekites: {t.roundingRule}
                  </p>
                </div>
                <div className="flex gap-1">
                  {t.status === 'DRAFT' && (
                    <>
                      <button
                        className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                        onClick={() => setEditing(t)}
                      >
                        Szerkesztes
                      </button>
                      <button
                        className="inline-flex items-center justify-center rounded-md border px-3 py-1.5 text-xs font-medium hover:bg-muted disabled:opacity-50"
                        onClick={() => t.id && approveTemplate(t.id)}
                      >
                        <CheckCircle className="h-4 w-4 mr-1" />
                        Jovahagyas
                      </button>
                      <button
                        className="inline-flex items-center justify-center rounded-md bg-destructive px-3 py-1.5 text-xs font-medium text-destructive-foreground hover:bg-destructive/90"
                        onClick={() => t.id && deleteTemplate(t.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </>
                  )}
                  {(t.status === 'APPROVED' || t.status === 'DRAFT') && (
                    <button
                      className="inline-flex items-center justify-center rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground hover:bg-primary/90 disabled:opacity-50"
                      onClick={() => t.id && publishTemplate(t.id)}
                    >
                      <Send className="h-4 w-4 mr-1" />
                      Publikalas
                    </button>
                  )}
                  {(t.status === 'PUBLISHED' || t.status === 'APPROVED') && (
                    <button
                      className="inline-flex items-center justify-center rounded-md bg-destructive px-3 py-1.5 text-xs font-medium text-destructive-foreground hover:bg-destructive/90"
                      onClick={() => t.id && revokeTemplate(t.id)}
                    >
                      <XCircle className="h-4 w-4 mr-1" />
                      Visszavonas
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
