import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'
import { CheckCircle2, Megaphone, Plus, Search, X } from 'lucide-react'
import { api } from '@/services/api/index'
import { safeArray } from '@/utils/safeArray'
import { toast } from '../../components/ui/toaster'
import { getErrorMessage } from '../../utils/errorHandling'

interface Circular {
  id: number
  title: string
  content: string
  createdByName?: string
  urgent?: boolean
  requiresAcknowledgment?: boolean
  acknowledged?: boolean
  createdAt?: string
  circularType?: string
  circularTypeDescription?: string
  target?: string
  priority?: string
  registrationNumber?: string
  attachmentFilename?: string
  validFrom?: string
  validTo?: string
  category?: string
  archived?: boolean
  archiveYear?: number
  attachmentSize?: number
  acknowledgmentCount?: number
}

type CircularTab = 'active' | 'archived' | 'GENERAL' | 'REGULATION' | 'SECURITY_ALERT' | 'INVENTORY'

const tabs: Array<{ id: CircularTab; label: string }> = [
  { id: 'active', label: 'Aktív' },
  { id: 'GENERAL', label: 'Általános' },
  { id: 'REGULATION', label: 'Szabályzat' },
  { id: 'SECURITY_ALERT', label: 'Biztonság' },
  { id: 'INVENTORY', label: 'Készlet' },
  { id: 'archived', label: 'Archivált' },
]

const typeLabels: Record<string, string> = {
  GENERAL: 'Általános',
  REGULATION: 'Szabályzat',
  RATE_POLICY: 'Árfolyam-politika',
  SECURITY_ALERT: 'Biztonsági figyelmeztetés',
  INVENTORY: 'Készlet utasítás',
  HR: 'HR',
  TECHNICAL: 'Műszaki',
  BEST_CHANGE: 'Best Change',
  ZALOG: 'Zálog',
  MANAGEMENT: 'Központi',
  APPOINTMENT: 'Kinevezés',
  NEW_YEAR: 'Újévi',
  YEAR_END: 'Éves zárás',
  MONTHLY_SUMMARY: 'Havi összesítő',
  VIP_NOTICE: 'VIP',
  AUDIT_NOTICE: 'Audit',
  TRAINING: 'Oktatás',
}

const priorityClass: Record<string, string> = {
  LOW: 'border-slate-200 bg-slate-50 text-slate-600',
  NORMAL: 'border-blue-200 bg-blue-50 text-blue-700',
  HIGH: 'border-amber-200 bg-amber-50 text-amber-700',
  URGENT: 'border-red-200 bg-red-50 text-red-700',
}

const emptyForm = {
  title: '',
  circularType: 'GENERAL',
  category: 'GENERAL',
  content: '',
  urgent: false,
  requiresAcknowledgment: false,
}

function documentNumber(circular: Circular): string {
  return circular.registrationNumber || `KOR-${String(circular.id).padStart(4, '0')}`
}

function formatDate(value?: string): string {
  return value ? new Date(value).toLocaleDateString('hu-HU') : '-'
}

export default function CircularPage() {
  const [circulars, setCirculars] = useState<Circular[]>([])
  const [unacknowledged, setUnacknowledged] = useState<Circular[]>([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<CircularTab>('active')
  const [searchTerm, setSearchTerm] = useState('')
  const [showCreateDialog, setShowCreateDialog] = useState(false)
  const [selectedCircular, setSelectedCircular] = useState<Circular | null>(null)
  const [showViewDialog, setShowViewDialog] = useState(false)
  const [formData, setFormData] = useState(emptyForm)

  const loadCirculars = useCallback(async () => {
    setLoading(true)
    try {
      const path = activeTab === 'active'
        ? '/circulars/active'
        : activeTab === 'archived'
        ? '/circulars/archived'
        : `/circulars/by-type/${activeTab}`
      const response = await api.get<Circular[]>(path)
      setCirculars(safeArray<Circular>(response.data))
    } catch (err) {
      toast.error('Körlevél betöltési hiba', getErrorMessage(err))
      setCirculars([])
    } finally {
      setLoading(false)
    }
  }, [activeTab])

  const loadUnacknowledged = useCallback(async () => {
    try {
      const response = await api.get<Circular[]>('/circulars/my-unacknowledged')
      setUnacknowledged(safeArray<Circular>(response.data))
    } catch {
      setUnacknowledged([])
    }
  }, [])

  useEffect(() => {
    void loadCirculars()
    void loadUnacknowledged()
  }, [loadCirculars, loadUnacknowledged])

  const filteredCirculars = useMemo(() => {
    const term = searchTerm.trim().toLowerCase()
    if (!term) return circulars
    return circulars.filter((circular) =>
      [documentNumber(circular), circular.title, circular.circularType, circular.category, circular.createdByName]
        .some((value) => value && value.toLowerCase().includes(term)),
    )
  }, [circulars, searchTerm])

  const handleArchive = useCallback(async (id: number) => {
    if (!window.confirm('Biztosan archiválja a dokumentumot?')) return
    try {
      await api.post(`/circulars/${id}/archive`)
      await loadCirculars()
      toast.success('Körlevél archiválva')
    } catch (err) {
      toast.error('Archiválási hiba', getErrorMessage(err))
    }
  }, [loadCirculars])

  const handleAcknowledge = useCallback(async (id: number) => {
    try {
      await api.post(`/circulars/${id}/acknowledge-worker`)
      await loadCirculars()
      await loadUnacknowledged()
      toast.success('Körlevél nyugtázva')
    } catch (err) {
      toast.error('Nyugtázási hiba', getErrorMessage(err))
    }
  }, [loadCirculars, loadUnacknowledged])

  const handleCreateSubmit = useCallback(async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    try {
      await api.post('/circulars/typed', {
        title: formData.title,
        content: formData.content,
        urgent: formData.urgent,
        requiresAcknowledgment: formData.requiresAcknowledgment,
        circularType: formData.circularType,
        target: 'ALL_BRANCHES',
        priority: formData.urgent ? 'URGENT' : 'NORMAL',
        registrationNumber: null,
      })
      setShowCreateDialog(false)
      setFormData(emptyForm)
      await loadCirculars()
      toast.success('Körlevél létrehozva')
    } catch (err) {
      toast.error('Létrehozási hiba', getErrorMessage(err))
    }
  }, [formData, loadCirculars])

  return (
    <div className="h-full min-h-0 overflow-y-auto bg-slate-100">
      <div className="border-b border-slate-200 bg-white px-5 py-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <Megaphone className="h-5 w-5 text-slate-700" />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">Körlevelek és szabályzatok</h1>
              <div className="text-xs text-slate-500">Központi dokumentumok, nyugtázás és archiválás</div>
            </div>
          </div>
          <button
            onClick={() => setShowCreateDialog(true)}
            className="inline-flex items-center gap-1 rounded bg-blue-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-blue-700"
          >
            <Plus size={15} />
            Új dokumentum
          </button>
        </div>
      </div>

      <div className="space-y-4 p-4">
        {unacknowledged.length > 0 && (
          <section className="rounded-md border border-amber-200 bg-amber-50 p-3">
            <div className="mb-2 text-sm font-semibold text-amber-800">Elolvasásra vár: {unacknowledged.length}</div>
            <div className="space-y-2">
              {unacknowledged.map((circular) => (
                <div key={circular.id} className="flex flex-wrap items-center justify-between gap-2 rounded border border-amber-100 bg-white px-3 py-2">
                  <div>
                    <span className="font-mono text-xs text-slate-500">{documentNumber(circular)}</span>
                    <span className="ml-2 text-sm font-semibold text-slate-900">{circular.title}</span>
                  </div>
                  <div className="flex gap-2">
                    <button onClick={() => { setSelectedCircular(circular); setShowViewDialog(true) }} className="rounded border px-2 py-1 text-xs hover:bg-slate-50">Megnyitás</button>
                    <button onClick={() => void handleAcknowledge(circular.id)} className="rounded bg-green-600 px-2 py-1 text-xs font-semibold text-white hover:bg-green-700">Értettem</button>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        <section className="rounded-md border border-slate-200 bg-white p-3 shadow-sm">
          <div className="flex flex-wrap items-center gap-2">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`rounded border px-3 py-1.5 text-xs font-semibold ${
                  activeTab === tab.id ? 'border-slate-900 bg-slate-900 text-white' : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
          <label className="mt-3 flex items-center gap-2 rounded border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-600">
            <Search size={16} />
            <input
              value={searchTerm}
              onChange={(event) => setSearchTerm(event.target.value)}
              className="min-w-0 flex-1 bg-transparent text-sm text-slate-900 outline-none placeholder:text-slate-400"
              placeholder="Keresés iktatószám, cím, típus vagy készítő alapján"
            />
          </label>
        </section>

        <section className="overflow-x-auto rounded-md border border-slate-200 bg-white shadow-sm">
          <table className="min-w-[1040px] w-full text-sm">
            <thead className="border-b border-slate-200 bg-slate-50 text-[11px] uppercase text-slate-500">
              <tr>
                <th className="px-3 py-2 text-left">Szám</th>
                <th className="px-3 py-2 text-left">Cím</th>
                <th className="px-3 py-2 text-left">Típus</th>
                <th className="px-3 py-2 text-left">Prioritás</th>
                <th className="px-3 py-2 text-left">Készítő</th>
                <th className="px-3 py-2 text-left">Dátum</th>
                <th className="px-3 py-2 text-right">Nyugtázás</th>
                <th className="px-3 py-2 text-right">Művelet</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr><td colSpan={8} className="px-3 py-8 text-center text-slate-500">Betöltés...</td></tr>
              ) : filteredCirculars.length === 0 ? (
                <tr><td colSpan={8} className="px-3 py-8 text-center text-slate-500">Nincs dokumentum ebben a nézetben</td></tr>
              ) : filteredCirculars.map((circular) => (
                <tr key={circular.id} className="hover:bg-slate-50">
                  <td className="px-3 py-2 font-mono text-xs text-slate-600">{documentNumber(circular)}</td>
                  <td className="px-3 py-2">
                    <div className="font-semibold text-slate-900">{circular.title}</div>
                    {circular.attachmentFilename && <div className="text-xs text-slate-500">{circular.attachmentFilename}</div>}
                  </td>
                  <td className="px-3 py-2">{typeLabels[circular.circularType ?? ''] ?? circular.circularType ?? '-'}</td>
                  <td className="px-3 py-2">
                    <span className={`rounded border px-2 py-1 text-xs font-semibold ${priorityClass[circular.priority ?? 'NORMAL'] ?? priorityClass.NORMAL}`}>
                      {circular.priority ?? 'NORMAL'}
                    </span>
                  </td>
                  <td className="px-3 py-2">{circular.createdByName ?? '-'}</td>
                  <td className="px-3 py-2">{formatDate(circular.validFrom ?? circular.createdAt)}</td>
                  <td className="px-3 py-2 text-right">{circular.acknowledgmentCount ?? 0}</td>
                  <td className="px-3 py-2 text-right">
                    <div className="flex justify-end gap-1">
                      <button onClick={() => { setSelectedCircular(circular); setShowViewDialog(true) }} className="rounded border px-2 py-1 text-xs hover:bg-slate-50">
                        Megtekint
                      </button>
                      {!circular.archived && (
                        <button onClick={() => void handleArchive(circular.id)} className="rounded border px-2 py-1 text-xs hover:bg-slate-50">
                          Archivál
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      </div>

      {showCreateDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <form onSubmit={handleCreateSubmit} className="w-full max-w-3xl rounded-md bg-white p-4 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold">Új körlevél</h2>
              <button type="button" onClick={() => setShowCreateDialog(false)}><X size={20} /></button>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="col-span-2">
                <label className="mb-1 block text-xs font-semibold text-slate-600">Cím</label>
                <input className="w-full rounded border px-3 py-2 text-sm" value={formData.title} onChange={(e) => setFormData({ ...formData, title: e.target.value })} required />
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold text-slate-600">Típus</label>
                <select className="w-full rounded border px-3 py-2 text-sm" value={formData.circularType} onChange={(e) => setFormData({ ...formData, circularType: e.target.value })}>
                  {Object.entries(typeLabels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold text-slate-600">Sürgős</label>
                <label className="flex h-[38px] items-center gap-2 rounded border px-3 text-sm">
                  <input type="checkbox" checked={formData.urgent} onChange={(e) => setFormData({ ...formData, urgent: e.target.checked })} />
                  Azonnali nyugtázás
                </label>
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold text-slate-600">Kötelező nyugtázás</label>
                <label className="flex h-[38px] items-center gap-2 rounded border px-3 text-sm">
                  <input type="checkbox" checked={formData.requiresAcknowledgment} onChange={(e) => setFormData({ ...formData, requiresAcknowledgment: e.target.checked })} />
                  Tranzakció-blokkoló
                </label>
              </div>
              <div className="col-span-2">
                <label className="mb-1 block text-xs font-semibold text-slate-600">Tartalom</label>
                <textarea className="h-56 w-full rounded border px-3 py-2 text-sm" value={formData.content} onChange={(e) => setFormData({ ...formData, content: e.target.value })} required />
              </div>
            </div>
            <div className="mt-4 flex justify-end gap-2">
              <button type="button" onClick={() => setShowCreateDialog(false)} className="rounded border px-4 py-2 text-sm hover:bg-slate-50">Mégse</button>
              <button type="submit" className="rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700">Létrehozás</button>
            </div>
          </form>
        </div>
      )}

      {showViewDialog && selectedCircular && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-4xl rounded-md bg-white p-4 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <div>
                <div className="font-mono text-xs text-slate-500">{documentNumber(selectedCircular)}</div>
                <h2 className="text-lg font-semibold">{selectedCircular.title}</h2>
              </div>
              <button onClick={() => setShowViewDialog(false)}><X size={20} /></button>
            </div>
            <div className="mb-4 grid grid-cols-2 gap-3 text-sm md:grid-cols-4">
              <InfoBlock label="Típus" value={typeLabels[selectedCircular.circularType ?? ''] ?? selectedCircular.circularType ?? '-'} />
              <InfoBlock label="Prioritás" value={selectedCircular.priority ?? 'NORMAL'} />
              <InfoBlock label="Készítő" value={selectedCircular.createdByName ?? '-'} />
              <InfoBlock label="Dátum" value={formatDate(selectedCircular.validFrom ?? selectedCircular.createdAt)} />
            </div>
            <div className="max-h-[46vh] overflow-y-auto whitespace-pre-wrap rounded border border-slate-200 bg-slate-50 p-3 text-sm leading-6">
              {selectedCircular.content}
            </div>
            <div className="mt-4 flex justify-between gap-2">
              <button onClick={() => setShowViewDialog(false)} className="rounded border px-4 py-2 text-sm hover:bg-slate-50">Bezárás</button>
              {!selectedCircular.acknowledged && !selectedCircular.archived && (
                <button onClick={() => { void handleAcknowledge(selectedCircular.id); setShowViewDialog(false) }} className="inline-flex items-center gap-1 rounded bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700">
                  <CheckCircle2 size={16} />
                  Elolvastam és megértettem
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function InfoBlock({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded border border-slate-200 bg-slate-50 p-2">
      <div className="text-[11px] font-semibold uppercase text-slate-500">{label}</div>
      <div className="mt-1 text-sm font-medium text-slate-900">{value}</div>
    </div>
  )
}
