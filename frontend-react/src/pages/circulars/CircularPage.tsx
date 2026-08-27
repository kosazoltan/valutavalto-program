import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'
import { CheckCircle2, Download, Megaphone, Plus, Search, Upload, X } from 'lucide-react'
import { api } from '@/services/api/index'
import { safeArray } from '@/utils/safeArray'
import { toast } from '../../components/ui/toaster'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { getElectronAPI } from '../../utils/electron'
import { downloadBlob } from '../../utils/downloadBlob'
import i18n from '../../i18n'

interface Circular {
  id: number
  title: string
  content: string
  createdByName?: string
  urgent?: boolean
  requiresAcknowledgment?: boolean
  allowsReply?: boolean
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

interface CircularTypeOption {
  type: string
  description?: string
  defaultTarget?: string
  defaultPriority?: string
}

interface AcknowledgmentStatus {
  circularId?: number
  title?: string
  totalAcknowledged?: number
  acknowledgments?: Array<{ workerId?: number; acknowledgedAt?: string }>
}

interface CircularReply {
  id: number
  circularId?: number
  workerId?: number
  workerName?: string
  branchId?: string
  replyText: string
  createdAt?: string
}

type CircularTab = string

const fallbackTabs: Array<{ id: CircularTab; label: string }> = [
  { id: 'active', label: 'Aktív' },
  { id: 'relevant', label: 'Irodához releváns' },
  { id: 'category', label: 'Kategória' },
  { id: 'GENERAL', label: 'Általános' },
  { id: 'REGULATION', label: 'Szabályzat' },
  { id: 'SECURITY_ALERT', label: 'Biztonság' },
  { id: 'INVENTORY', label: 'Készlet' },
  { id: 'archived', label: 'Archivált' },
  { id: 'archived-year', label: 'Éves archívum' },
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

const categoryOptions = [
  { id: 'GENERAL', label: 'Általános' },
  { id: 'VIP', label: 'VIP' },
  { id: 'ZALOG', label: 'Zálog' },
]

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
  allowsReply: false,
}

function documentNumber(circular: Circular): string {
  return circular.registrationNumber || `KOR-${String(circular.id).padStart(4, '0')}`
}

function formatDate(value?: string): string {
  return value ? new Date(value).toLocaleDateString('hu-HU') : '-'
}

export default function CircularPage() {
  const defaultArchiveYear = useMemo(() => String(new Date().getFullYear() - 1), [])
  const [circulars, setCirculars] = useState<Circular[]>([])
  const [unacknowledged, setUnacknowledged] = useState<Circular[]>([])
  const [legacyUnacknowledged, setLegacyUnacknowledged] = useState<Circular[]>([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<CircularTab>('active')
  const [searchTerm, setSearchTerm] = useState('')
  const [showCreateDialog, setShowCreateDialog] = useState(false)
  const [selectedCircular, setSelectedCircular] = useState<Circular | null>(null)
  const [showViewDialog, setShowViewDialog] = useState(false)
  const [detailLoading, setDetailLoading] = useState(false)
  const [acknowledgmentStatus, setAcknowledgmentStatus] = useState<AcknowledgmentStatus | null>(
    null,
  )
  const [acknowledgmentBreakdown, setAcknowledgmentBreakdown] = useState<Record<string, number>>({})
  const [replies, setReplies] = useState<CircularReply[]>([])
  const [replyText, setReplyText] = useState('')
  const [formData, setFormData] = useState(emptyForm)
  const [typeOptions, setTypeOptions] = useState<CircularTypeOption[]>([])
  const [attachmentFile, setAttachmentFile] = useState<File | null>(null)
  const [serverSearchActive, setServerSearchActive] = useState(false)
  const [categoryFilter, setCategoryFilter] = useState('GENERAL')
  const [archiveYear, setArchiveYear] = useState(defaultArchiveYear)

  const tabs = useMemo<Array<{ id: CircularTab; label: string }>>(() => {
    if (typeOptions.length === 0) return fallbackTabs
    return [
      { id: 'active', label: 'Aktív' },
      { id: 'relevant', label: 'Irodához releváns' },
      { id: 'category', label: 'Kategória' },
      ...typeOptions.map((option) => ({
        id: option.type,
        label: typeLabels[option.type] ?? option.description ?? option.type,
      })),
      { id: 'archived', label: 'Archivált' },
      { id: 'archived-year', label: 'Éves archívum' },
    ]
  }, [typeOptions])

  const loadCirculars = useCallback(async () => {
    const normalizedArchiveYear = archiveYear.trim()
    if (activeTab === 'archived-year' && !normalizedArchiveYear) {
      toast.error('Archív év hiányzik', 'Adjon meg egy évet az éves archívum betöltéséhez.')
      setCirculars([])
      setLoading(false)
      return
    }

    setLoading(true)
    try {
      const path =
        activeTab === 'active'
          ? '/circulars/active'
          : activeTab === 'relevant'
            ? '/circulars/relevant'
            : activeTab === 'category'
              ? `/circulars/by-category/${encodeURIComponent(categoryFilter)}`
              : activeTab === 'archived'
                ? '/circulars/archived'
                : activeTab === 'archived-year'
                  ? `/circulars/archived/${encodeURIComponent(normalizedArchiveYear)}`
                  : `/circulars/by-type/${activeTab}`
      const response = await api.get<Circular[]>(path)
      setCirculars(safeArray<Circular>(response.data))
      setServerSearchActive(false)
    } catch (err) {
      toast.error('Körlevél betöltési hiba', getErrorMessage(err))
      setCirculars([])
      setServerSearchActive(false)
    } finally {
      setLoading(false)
    }
  }, [activeTab, archiveYear, categoryFilter])

  const loadUnacknowledged = useCallback(async () => {
    try {
      const [myResponse, legacyResponse] = await Promise.all([
        api.get<Circular[]>('/circulars/my-unacknowledged'),
        api.get<Circular[]>('/circulars/unacknowledged'),
      ])
      setUnacknowledged(safeArray<Circular>(myResponse.data))
      setLegacyUnacknowledged(safeArray<Circular>(legacyResponse.data))
    } catch {
      setUnacknowledged([])
      setLegacyUnacknowledged([])
    }
  }, [])

  const loadTypes = useCallback(async () => {
    try {
      const response = await api.get<CircularTypeOption[]>('/circulars/types')
      setTypeOptions(safeArray<CircularTypeOption>(response.data))
    } catch {
      setTypeOptions([])
    }
  }, [])

  useEffect(() => {
    void loadTypes()
    void loadCirculars()
    void loadUnacknowledged()
  }, [loadCirculars, loadTypes, loadUnacknowledged])

  const filteredCirculars = useMemo(() => {
    const term = searchTerm.trim().toLowerCase()
    if (serverSearchActive) return circulars
    if (!term) return circulars
    return circulars.filter((circular) =>
      [
        documentNumber(circular),
        circular.title,
        circular.circularType,
        circular.category,
        circular.createdByName,
      ].some((value) => value && value.toLowerCase().includes(term)),
    )
  }, [circulars, searchTerm, serverSearchActive])

  const handleTabChange = useCallback((tab: CircularTab) => {
    setActiveTab(tab)
    setServerSearchActive(false)
  }, [])

  const handleServerSearch = useCallback(async () => {
    const query = searchTerm.trim()
    if (!query) {
      await loadCirculars()
      return
    }

    setLoading(true)
    try {
      const response = await api.get<Circular[]>('/circulars/search', { params: { q: query } })
      setCirculars(safeArray<Circular>(response.data))
      setServerSearchActive(true)
    } catch (err) {
      toast.error('Körlevél keresési hiba', getErrorMessage(err))
      setCirculars([])
      setServerSearchActive(false)
    } finally {
      setLoading(false)
    }
  }, [loadCirculars, searchTerm])

  const openCircularDetails = useCallback(async (circular: Circular) => {
    setSelectedCircular(circular)
    setShowViewDialog(true)
    setDetailLoading(true)
    setAcknowledgmentStatus(null)
    setAcknowledgmentBreakdown({})
    setReplies([])
    setReplyText('')

    try {
      const detailResponse = await api.get<Circular>(`/circulars/${circular.id}`)
      setSelectedCircular(detailResponse.data)
    } catch (err) {
      toast.error('Körlevél részlet betöltési hiba', getErrorMessage(err))
    }

    const [statusResult, breakdownResult, repliesResult] = await Promise.allSettled([
      api.get<AcknowledgmentStatus>(`/circulars/${circular.id}/acknowledgment-status`),
      api.get<Record<string, number>>(`/circulars/${circular.id}/acknowledgment-breakdown`),
      api.get<CircularReply[]>(`/circulars/${circular.id}/replies`),
    ])

    if (statusResult.status === 'fulfilled') {
      setAcknowledgmentStatus(statusResult.value.data)
    }
    if (breakdownResult.status === 'fulfilled') {
      setAcknowledgmentBreakdown(breakdownResult.value.data ?? {})
    }
    if (repliesResult.status === 'fulfilled') {
      setReplies(safeArray<CircularReply>(repliesResult.value.data))
    }

    setDetailLoading(false)
  }, [])

  const handleSendReply = useCallback(
    async (circular: Circular) => {
      const text = replyText.trim()
      if (!text) return
      try {
        const electronAPI = getElectronAPI()
        if (electronAPI && typeof electronAPI.savePendingCircularReply === 'function') {
          // Electron (pénztár): offline-first outbox + azonnali flush-kísérlet.
          await electronAPI.savePendingCircularReply({ circularId: circular.id, replyText: text })
          void electronAPI.syncOffline()
          toast.success('Válasz rögzítve', 'A válasz szinkronizálásra ütemezve a központ felé.')
        } else {
          // Web (center) vagy régi Electron-main: közvetlen POST.
          const response = await api.post<CircularReply>(`/circulars/${circular.id}/reply`, {
            replyText: text,
          })
          if (response.data?.replyText) {
            setReplies((current) => [...current, response.data])
          }
          toast.success('Válasz elküldve')
        }
        setReplyText('')
      } catch (err) {
        toast.error('Válasz küldési hiba', getErrorMessage(err))
      }
    },
    [replyText],
  )

  const handleArchive = useCallback(
    async (id: number) => {
      if (!window.confirm('Biztosan archiválja a dokumentumot?')) return
      try {
        await api.post(`/circulars/${id}/archive`)
        await loadCirculars()
        toast.success('Körlevél archiválva')
      } catch (err) {
        toast.error('Archiválási hiba', getErrorMessage(err))
      }
    },
    [loadCirculars],
  )

  const handleAcknowledge = useCallback(
    async (id: number) => {
      try {
        await api.post(`/circulars/${id}/acknowledge-worker`)
        await loadCirculars()
        await loadUnacknowledged()
        toast.success('Körlevél nyugtázva')
      } catch (err) {
        toast.error('Nyugtázási hiba', getErrorMessage(err))
      }
    },
    [loadCirculars, loadUnacknowledged],
  )

  const handleGlobalAcknowledge = useCallback(
    async (id: number) => {
      try {
        await api.post(`/circulars/${id}/acknowledge`)
        await loadCirculars()
        await loadUnacknowledged()
        toast.success('Körlevél globálisan nyugtázva')
      } catch (err) {
        toast.error('Globális nyugtázási hiba', getErrorMessage(err))
      }
    },
    [loadCirculars, loadUnacknowledged],
  )

  const closeCreateDialog = useCallback(() => {
    setShowCreateDialog(false)
    setFormData(emptyForm)
    setAttachmentFile(null)
  }, [])

  const downloadAttachment = useCallback(async (circular: Circular) => {
    try {
      const response = await api.get<Blob>(`/circulars/${circular.id}/attachment`, {
        responseType: 'blob',
      })
      // FK-058 follow-up (FK-051 v2 FR-7 minta): defenzív Blob-becsomagolás a fájlnév szerinti
      // MIME-típussal — másodlagos védelmi réteg az Electron IPC proxy whitelist-detekciója mellett
      // (odt/docx/pdf mind bináris; a docx content-type-ja is tartalmazza az "xml" szót).
      const filename = circular.attachmentFilename ?? `korlevel-${circular.id}`
      const mimeType = filename.endsWith('.odt')
        ? 'application/vnd.oasis.opendocument.text'
        : filename.endsWith('.docx')
          ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          : filename.endsWith('.pdf')
            ? 'application/pdf'
            : 'application/octet-stream'
      const raw = response.data
      const blob = raw instanceof Blob ? raw : new Blob([raw as BlobPart], { type: mimeType })
      downloadBlob(blob, filename)
    } catch (err) {
      toast.error('Csatolmány letöltési hiba', await getBlobErrorMessage(err))
    }
  }, [])

  const handleCreateSubmit = useCallback(
    async (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault()
      try {
        const createPayload = {
          title: formData.title,
          content: formData.content,
          urgent: formData.urgent,
          requiresAcknowledgment: formData.requiresAcknowledgment,
          allowsReply: formData.allowsReply,
        }
        const useSimpleCreate = formData.circularType === 'GENERAL' && !attachmentFile
        const response = useSimpleCreate
          ? await api.post<Circular>('/circulars', createPayload)
          : await api.post<Circular>('/circulars/typed', {
              ...createPayload,
              circularType: formData.circularType,
              target: 'ALL_BRANCHES',
              priority: formData.urgent ? 'URGENT' : 'NORMAL',
              registrationNumber: null,
            })
        if (attachmentFile) {
          const uploadData = new FormData()
          uploadData.append('file', attachmentFile)
          await api.post(`/circulars/${response.data.id}/attachment`, uploadData, {
            headers: { 'Content-Type': 'multipart/form-data' },
          })
        }
        closeCreateDialog()
        await loadCirculars()
        toast.success('Körlevél létrehozva')
      } catch (err) {
        toast.error('Létrehozási hiba', getErrorMessage(err))
      }
    },
    [attachmentFile, closeCreateDialog, formData, loadCirculars],
  )

  return (
    <div className="h-full min-h-0 overflow-y-auto bg-slate-100">
      <div className="border-b border-slate-200 bg-white px-5 py-3">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <Megaphone className="h-5 w-5 text-slate-700" />
            <div>
              <h1 className="text-lg font-semibold text-slate-900">
                {i18n.t('literals.korlevelek-es-szabalyzatok')}
              </h1>
              <div className="text-xs text-slate-500">
                {i18n.t('literals.kozponti-dokumentumok-nyugtazas-es-archi')}
              </div>
            </div>
          </div>
          <button
            onClick={() => setShowCreateDialog(true)}
            className="inline-flex items-center gap-1 rounded bg-blue-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-blue-700"
          >
            <Plus size={15} />
            {i18n.t('literals.uj-dokumentum')}
          </button>
        </div>
      </div>

      <div className="space-y-4 p-4">
        {unacknowledged.length > 0 && (
          <section className="rounded-md border border-amber-200 bg-amber-50 p-3">
            <div className="mb-2 text-sm font-semibold text-amber-800">
              {i18n.t('literals.elolvasasra-var')}
              {unacknowledged.length}
            </div>
            <div className="space-y-2">
              {unacknowledged.map((circular) => (
                <div
                  key={circular.id}
                  className="flex flex-wrap items-center justify-between gap-2 rounded border border-amber-100 bg-white px-3 py-2"
                >
                  <div>
                    <span className="font-mono text-xs text-slate-500">
                      {documentNumber(circular)}
                    </span>
                    <span className="ml-2 text-sm font-semibold text-slate-900">
                      {circular.title}
                    </span>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => void openCircularDetails(circular)}
                      className="rounded border px-2 py-1 text-xs hover:bg-slate-50"
                    >
                      {i18n.t('literals.megnyitas-2')}
                    </button>
                    <button
                      onClick={() => void handleAcknowledge(circular.id)}
                      className="rounded bg-green-600 px-2 py-1 text-xs font-semibold text-white hover:bg-green-700"
                    >
                      {i18n.t('literals.ertettem')}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </section>
        )}

        {legacyUnacknowledged.length > 0 && (
          <section className="rounded-md border border-blue-200 bg-blue-50 p-3">
            <div className="mb-2 text-sm font-semibold text-blue-800">
              {i18n.t('literals.globalisan-nem-nyugtazott-korlevelek')}
              {legacyUnacknowledged.length}
            </div>
            <div className="grid gap-2 md:grid-cols-2">
              {legacyUnacknowledged.slice(0, 4).map((circular) => (
                <div
                  key={circular.id}
                  className="flex flex-wrap items-center justify-between gap-2 rounded border border-blue-100 bg-white px-3 py-2"
                >
                  <div>
                    <span className="font-mono text-xs text-slate-500">
                      {documentNumber(circular)}
                    </span>
                    <span className="ml-2 text-sm font-semibold text-slate-900">
                      {circular.title}
                    </span>
                  </div>
                  <button
                    type="button"
                    onClick={() => void handleGlobalAcknowledge(circular.id)}
                    className="rounded border border-blue-300 px-2 py-1 text-xs font-semibold text-blue-800 hover:bg-blue-50"
                  >
                    {i18n.t('literals.globalis-nyugtazas')}
                  </button>
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
                onClick={() => handleTabChange(tab.id)}
                className={`rounded border px-3 py-1.5 text-xs font-semibold ${
                  activeTab === tab.id
                    ? 'border-slate-900 bg-slate-900 text-white'
                    : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
          <div className="mt-3 flex flex-wrap items-center gap-2">
            <label className="flex min-w-[260px] flex-1 items-center gap-2 rounded border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-600">
              <Search size={16} />
              <input
                value={searchTerm}
                onChange={(event) => setSearchTerm(event.target.value)}
                className="min-w-0 flex-1 bg-transparent text-sm text-slate-900 outline-none placeholder:text-slate-400"
                placeholder="Keresés iktatószám, cím, típus vagy készítő alapján"
              />
            </label>
            <button
              type="button"
              onClick={() => void handleServerSearch()}
              className="rounded border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50"
            >
              {i18n.t('literals.iktatoszam-kereses')}
            </button>
          </div>
          {serverSearchActive && (
            <div className="mt-2 text-xs text-slate-500">
              {i18n.t('literals.backend-iktatoszam-kereses-eredmenye')}
              {filteredCirculars.length}
              {i18n.t('literals.dokumentum')}
            </div>
          )}
          {activeTab === 'category' && (
            <div className="mt-3 flex flex-wrap items-end gap-2 rounded border border-slate-200 bg-slate-50 p-3">
              <label
                htmlFor="circular-category-filter"
                className="flex min-w-[180px] flex-col gap-1 text-xs font-semibold text-slate-600"
              >
                {i18n.t('literals.kategoria-szuro')}
                <select
                  id="circular-category-filter"
                  value={categoryFilter}
                  onChange={(event) => setCategoryFilter(event.target.value)}
                  className="rounded border border-slate-300 bg-white px-3 py-2 text-sm font-normal text-slate-900"
                >
                  {categoryOptions.map((option) => (
                    <option key={option.id} value={option.id}>
                      {option.label}
                    </option>
                  ))}
                </select>
              </label>
              <button
                type="button"
                onClick={() => void loadCirculars()}
                className="rounded border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-100"
              >
                {i18n.t('literals.kategoria-betoltese')}
              </button>
              <span className="text-xs text-slate-500">
                {i18n.t('literals.backend-kategoria-nezet')}
                {categoryFilter}
              </span>
            </div>
          )}
          {activeTab === 'archived-year' && (
            <div className="mt-3 flex flex-wrap items-end gap-2 rounded border border-slate-200 bg-slate-50 p-3">
              <label
                htmlFor="circular-archive-year"
                className="flex min-w-[160px] flex-col gap-1 text-xs font-semibold text-slate-600"
              >
                {i18n.t('literals.archiv-ev')}
                <input
                  id="circular-archive-year"
                  type="number"
                  min="2000"
                  max="2100"
                  value={archiveYear}
                  onChange={(event) => setArchiveYear(event.target.value)}
                  className="rounded border border-slate-300 bg-white px-3 py-2 text-sm font-normal text-slate-900"
                />
              </label>
              <button
                type="button"
                onClick={() => void loadCirculars()}
                className="rounded border border-slate-300 bg-white px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-100"
              >
                {i18n.t('literals.ev-betoltese')}
              </button>
              <span className="text-xs text-slate-500">
                {i18n.t('literals.backend-eves-archivum')}
                {archiveYear || '-'}
              </span>
            </div>
          )}
        </section>

        <section className="overflow-x-auto rounded-md border border-slate-200 bg-white shadow-sm">
          <table className="min-w-[1040px] w-full text-sm">
            <thead className="border-b border-slate-200 bg-slate-50 text-[11px] uppercase text-slate-500">
              <tr>
                <th className="px-3 py-2 text-left">{i18n.t('literals.szam')}</th>
                <th className="px-3 py-2 text-left">{i18n.t('literals.cim')}</th>
                <th className="px-3 py-2 text-left">{i18n.t('literals.tipus')}</th>
                <th className="px-3 py-2 text-left">{i18n.t('literals.prioritas')}</th>
                <th className="px-3 py-2 text-left">{i18n.t('literals.keszito')}</th>
                <th className="px-3 py-2 text-left">{i18n.t('literals.datum-2')}</th>
                <th className="px-3 py-2 text-right">{i18n.t('literals.nyugtazas')}</th>
                <th className="px-3 py-2 text-right">{i18n.t('literals.muvelet')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={8} className="px-3 py-8 text-center text-slate-500">
                    {i18n.t('literals.betoltes')}
                  </td>
                </tr>
              ) : filteredCirculars.length === 0 ? (
                <tr>
                  <td colSpan={8} className="px-3 py-8 text-center text-slate-500">
                    {i18n.t('literals.nincs-dokumentum-ebben-a-nezetben')}
                  </td>
                </tr>
              ) : (
                filteredCirculars.map((circular) => (
                  <tr key={circular.id} className="hover:bg-slate-50">
                    <td className="px-3 py-2 font-mono text-xs text-slate-600">
                      {documentNumber(circular)}
                    </td>
                    <td className="px-3 py-2">
                      <div className="font-semibold text-slate-900">{circular.title}</div>
                      {circular.attachmentFilename && (
                        <button
                          type="button"
                          onClick={() => void downloadAttachment(circular)}
                          className="mt-1 inline-flex items-center gap-1 text-xs text-blue-700 hover:underline"
                        >
                          <Download size={12} />
                          {circular.attachmentFilename}
                        </button>
                      )}
                    </td>
                    <td className="px-3 py-2">
                      {typeLabels[circular.circularType ?? ''] ?? circular.circularType ?? '-'}
                    </td>
                    <td className="px-3 py-2">
                      <span
                        className={`rounded border px-2 py-1 text-xs font-semibold ${priorityClass[circular.priority ?? 'NORMAL'] ?? priorityClass.NORMAL}`}
                      >
                        {circular.priority ?? 'NORMAL'}
                      </span>
                    </td>
                    <td className="px-3 py-2">{circular.createdByName ?? '-'}</td>
                    <td className="px-3 py-2">
                      {formatDate(circular.validFrom ?? circular.createdAt)}
                    </td>
                    <td className="px-3 py-2 text-right">{circular.acknowledgmentCount ?? 0}</td>
                    <td className="px-3 py-2 text-right">
                      <div className="flex justify-end gap-1">
                        <button
                          onClick={() => void openCircularDetails(circular)}
                          className="rounded border px-2 py-1 text-xs hover:bg-slate-50"
                        >
                          {i18n.t('literals.megtekint')}
                        </button>
                        {!circular.archived && (
                          <button
                            onClick={() => void handleArchive(circular.id)}
                            className="rounded border px-2 py-1 text-xs hover:bg-slate-50"
                          >
                            {i18n.t('literals.archival')}
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </section>
      </div>

      {showCreateDialog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <form
            onSubmit={handleCreateSubmit}
            className="w-full max-w-3xl rounded-md bg-white p-4 shadow-xl"
          >
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold">{i18n.t('literals.uj-korlevel')}</h2>
              <button type="button" onClick={closeCreateDialog}>
                <X size={20} />
              </button>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="col-span-2">
                <label
                  htmlFor="circular-title"
                  className="mb-1 block text-xs font-semibold text-slate-600"
                >
                  {i18n.t('literals.cim')}
                </label>
                <input
                  id="circular-title"
                  className="w-full rounded border px-3 py-2 text-sm"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  required
                />
              </div>
              <div>
                <label
                  htmlFor="circular-type"
                  className="mb-1 block text-xs font-semibold text-slate-600"
                >
                  {i18n.t('literals.tipus')}
                </label>
                <select
                  id="circular-type"
                  className="w-full rounded border px-3 py-2 text-sm"
                  value={formData.circularType}
                  onChange={(e) => setFormData({ ...formData, circularType: e.target.value })}
                >
                  {(typeOptions.length > 0
                    ? typeOptions
                    : Object.keys(typeLabels).map<CircularTypeOption>((type) => ({ type }))
                  ).map((option) => (
                    <option key={option.type} value={option.type}>
                      {typeLabels[option.type] ?? option.description ?? option.type}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold text-slate-600">
                  {i18n.t('literals.surgos')}
                </label>
                <label
                  htmlFor="circular-urgent"
                  className="flex h-[38px] items-center gap-2 rounded border px-3 text-sm"
                >
                  <input
                    id="circular-urgent"
                    type="checkbox"
                    checked={formData.urgent}
                    onChange={(e) => setFormData({ ...formData, urgent: e.target.checked })}
                  />
                  {i18n.t('literals.azonnali-nyugtazas')}
                </label>
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold text-slate-600">
                  {i18n.t('literals.kotelezo-nyugtazas')}
                </label>
                <label
                  htmlFor="circular-requires-acknowledgment"
                  className="flex h-[38px] items-center gap-2 rounded border px-3 text-sm"
                >
                  <input
                    id="circular-requires-acknowledgment"
                    type="checkbox"
                    checked={formData.requiresAcknowledgment}
                    onChange={(e) =>
                      setFormData({ ...formData, requiresAcknowledgment: e.target.checked })
                    }
                  />
                  {i18n.t('literals.tranzakcio-blokkolo')}
                </label>
              </div>
              <div>
                <label className="mb-1 block text-xs font-semibold text-slate-600">
                  {i18n.t('literals.valasz-engedelyezese')}
                </label>
                <label
                  htmlFor="circular-allows-reply"
                  className="flex h-[38px] items-center gap-2 rounded border px-3 text-sm"
                >
                  <input
                    id="circular-allows-reply"
                    type="checkbox"
                    checked={formData.allowsReply}
                    onChange={(e) => setFormData({ ...formData, allowsReply: e.target.checked })}
                  />
                  {i18n.t('literals.ketiranyu-valasz')}
                </label>
              </div>
              <div className="col-span-2">
                <label
                  htmlFor="circular-content"
                  className="mb-1 block text-xs font-semibold text-slate-600"
                >
                  {i18n.t('literals.tartalom')}
                </label>
                <textarea
                  id="circular-content"
                  className="h-56 w-full rounded border px-3 py-2 text-sm"
                  value={formData.content}
                  onChange={(e) => setFormData({ ...formData, content: e.target.value })}
                  required
                />
              </div>
              <div className="col-span-2">
                <label className="mb-1 block text-xs font-semibold text-slate-600">
                  {i18n.t('literals.csatolmany')}
                </label>
                <label className="flex cursor-pointer items-center gap-2 rounded border border-dashed border-slate-300 px-3 py-2 text-sm text-slate-600 hover:bg-slate-50">
                  <Upload size={16} />
                  <span>
                    {attachmentFile ? attachmentFile.name : 'ODT, DOCX vagy PDF fájl kiválasztása'}
                  </span>
                  <input
                    type="file"
                    accept=".odt,.docx,.pdf,application/pdf,application/vnd.oasis.opendocument.text,application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                    className="sr-only"
                    onChange={(event) => setAttachmentFile(event.target.files?.[0] ?? null)}
                  />
                </label>
              </div>
            </div>
            <div className="mt-4 flex justify-end gap-2">
              <button
                type="button"
                onClick={closeCreateDialog}
                className="rounded border px-4 py-2 text-sm hover:bg-slate-50"
              >
                {i18n.t('literals.megse')}
              </button>
              <button
                type="submit"
                className="rounded bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
              >
                {i18n.t('literals.letrehozas')}
              </button>
            </div>
          </form>
        </div>
      )}

      {showViewDialog && selectedCircular && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-4xl rounded-md bg-white p-4 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <div>
                <div className="font-mono text-xs text-slate-500">
                  {documentNumber(selectedCircular)}
                </div>
                <h2 className="text-lg font-semibold">{selectedCircular.title}</h2>
              </div>
              <button onClick={() => setShowViewDialog(false)}>
                <X size={20} />
              </button>
            </div>
            <div className="mb-4 grid grid-cols-2 gap-3 text-sm md:grid-cols-4">
              <InfoBlock
                label="Típus"
                value={
                  typeLabels[selectedCircular.circularType ?? ''] ??
                  selectedCircular.circularType ??
                  '-'
                }
              />
              <InfoBlock label="Prioritás" value={selectedCircular.priority ?? 'NORMAL'} />
              <InfoBlock label="Készítő" value={selectedCircular.createdByName ?? '-'} />
              <InfoBlock
                label="Dátum"
                value={formatDate(selectedCircular.validFrom ?? selectedCircular.createdAt)}
              />
            </div>
            {detailLoading && (
              <div className="mb-3 rounded border border-blue-100 bg-blue-50 px-3 py-2 text-xs text-blue-700">
                {i18n.t('literals.backend-reszletek-betoltese')}
              </div>
            )}
            <div className="max-h-[46vh] overflow-y-auto whitespace-pre-wrap rounded border border-slate-200 bg-slate-50 p-3 text-sm leading-6">
              {selectedCircular.content}
            </div>
            {(acknowledgmentStatus || Object.keys(acknowledgmentBreakdown).length > 0) && (
              <section
                className="mt-3 rounded border border-slate-200 bg-white p-3 text-sm"
                data-testid="circular-acknowledgment-summary"
              >
                <div className="mb-2 text-xs font-semibold uppercase text-slate-500">
                  {i18n.t('literals.nyugtazasi-allapot')}
                </div>
                {acknowledgmentStatus && (
                  <div className="mb-2 font-medium text-slate-900">
                    {i18n.t('literals.osszes-nyugtazas')}
                    {acknowledgmentStatus.totalAcknowledged ?? 0}
                  </div>
                )}
                {Object.keys(acknowledgmentBreakdown).length > 0 && (
                  <div className="grid gap-2 sm:grid-cols-2">
                    {Object.entries(acknowledgmentBreakdown).map(([role, count]) => (
                      <div
                        key={role}
                        className="flex items-center justify-between rounded border border-slate-100 bg-slate-50 px-2 py-1"
                      >
                        <span className="font-mono text-xs text-slate-600">{role}</span>
                        <span className="font-semibold text-slate-900">{count}</span>
                      </div>
                    ))}
                  </div>
                )}
              </section>
            )}
            {selectedCircular.allowsReply && (
              <section
                className="mt-3 rounded border border-slate-200 bg-white p-3 text-sm"
                data-testid="circular-reply-section"
              >
                <div className="mb-2 text-xs font-semibold uppercase text-slate-500">
                  {i18n.t('literals.valaszok')}
                </div>
                {replies.length > 0 && (
                  <div className="mb-3 space-y-2">
                    {replies.map((reply) => (
                      <div
                        key={reply.id}
                        className="rounded border border-slate-100 bg-slate-50 px-3 py-2"
                      >
                        <div className="text-xs text-slate-500">
                          {reply.workerName ?? `Dolgozó #${reply.workerId ?? '?'}`}
                          {i18n.t('literals.lit-29')} {formatDate(reply.createdAt)}
                        </div>
                        <div className="mt-1 whitespace-pre-wrap text-sm text-slate-900">
                          {reply.replyText}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
                <div className="flex gap-2">
                  <textarea
                    value={replyText}
                    onChange={(event) => setReplyText(event.target.value)}
                    maxLength={4000}
                    placeholder="Válasz a központnak..."
                    className="h-20 min-w-0 flex-1 rounded border border-slate-300 px-3 py-2 text-sm"
                    data-testid="circular-reply-input"
                  />
                  <button
                    type="button"
                    onClick={() => void handleSendReply(selectedCircular)}
                    disabled={!replyText.trim()}
                    className="self-end rounded bg-blue-600 px-3 py-2 text-sm font-semibold text-white hover:bg-blue-700 disabled:opacity-50"
                  >
                    {i18n.t('literals.kuldes')}
                  </button>
                </div>
              </section>
            )}
            {selectedCircular.attachmentFilename && (
              <div className="mt-3 rounded border border-slate-200 bg-white p-3 text-sm">
                <button
                  type="button"
                  onClick={() => void downloadAttachment(selectedCircular)}
                  className="inline-flex items-center gap-2 text-blue-700 hover:underline"
                >
                  <Download size={16} />
                  {selectedCircular.attachmentFilename}
                </button>
              </div>
            )}
            <div className="mt-4 flex justify-between gap-2">
              <button
                onClick={() => setShowViewDialog(false)}
                className="rounded border px-4 py-2 text-sm hover:bg-slate-50"
              >
                {i18n.t('literals.bezaras')}
              </button>
              {!selectedCircular.acknowledged && !selectedCircular.archived && (
                <button
                  onClick={() => {
                    void handleAcknowledge(selectedCircular.id)
                    setShowViewDialog(false)
                  }}
                  className="inline-flex items-center gap-1 rounded bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700"
                >
                  <CheckCircle2 size={16} />
                  {i18n.t('literals.elolvastam-es-megertettem')}
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
