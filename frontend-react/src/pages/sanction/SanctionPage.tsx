import { useCallback, useEffect, useState, useRef } from 'react'
import {
  ShieldAlert,
  Search,
  Upload,
  RefreshCw,
  AlertTriangle,
  CheckCircle2,
  XCircle,
  Database,
  FileText,
} from 'lucide-react'
import {
  sanctionApi,
  type SanctionEntry,
  type SanctionScreeningResult,
  type SanctionStatusResponse,
  type SanctionImportResult,
  type SanctionRiskLevel,
  type FatfTier,
} from '../../services/api/sanction'
import { logger } from '../../utils/logger'
import { useTranslation } from 'react-i18next'
import i18n from '../../i18n'

type Tab = 'screen' | 'list' | 'admin'

const RISK_COLOR: Record<SanctionRiskLevel, string> = {
  CLEAR: 'bg-green-100 text-green-800 border-green-300',
  POSSIBLE: 'bg-amber-100 text-amber-800 border-amber-300',
  CONFIRMED: 'bg-red-100 text-red-800 border-red-300',
}

const RISK_LABEL: Record<SanctionRiskLevel, string> = {
  CLEAR: 'TISZTA',
  POSSIBLE: 'LEHETSEGES EGYEZES',
  CONFIRMED: 'MEGEROSITETT EGYEZES',
}

const FATF_LABEL: Record<FatfTier, string> = {
  TIER_1A_COUNTERMEASURE: '1/a — ellenintézkedéssel érintett ország',
  TIER_1B_ENHANCED_DD: '1/b — fokozott átvilágítás szükséges',
  TIER_2_INCREASED_MONITORING: '2. csoport — fokozott monitoring',
  NONE: '—',
}

export default function SanctionPage() {
  const { t } = useTranslation()
  const [tab, setTab] = useState<Tab>('screen')
  const [status, setStatus] = useState<SanctionStatusResponse | null>(null)

  // Load status on mount + on refresh
  const [statusTick, setStatusTick] = useState(0)
  const refreshStatus = useCallback(() => setStatusTick((t) => t + 1), [])

  useEffect(() => {
    sanctionApi
      .status()
      .then(setStatus)
      .catch((e) => logger.error('Sanction', 'status err', e))
  }, [statusTick])

  return (
    <div className="space-y-2">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-base font-bold text-secondary-900 flex items-center gap-2">
            <ShieldAlert className="text-red-600" size={18} />
            {t('sanction.szankciosListaAmlKyc')}
          </h1>
          <p className="text-sm text-secondary-500 mt-1">
            {t('sanction.enszEuEsOfacListakKotelezoSzuresMinden300000FtFelettiTranzakcional')}
          </p>
        </div>
        <button onClick={refreshStatus} className="form-button">
          <RefreshCw size={16} />
          <span>{t('sanction.allapotFrissites')}</span>
        </button>
      </div>

      {/* Status card */}
      {status && (
        <div className="form-panel p-4 flex items-center gap-6">
          <Database className="text-blue-600" size={32} />
          <div className="flex-1">
            <div className="text-xs text-secondary-500">{t('sanction.aktivBejegyzesek')}</div>
            <div className="text-xl font-bold">
              {status.activeEntryCount.toLocaleString('hu-HU')}
            </div>
          </div>
          <div className="flex-1">
            <div className="text-xs text-secondary-500">{t('sanction.utolsoFrissites')}</div>
            <div className="text-xl font-bold">
              {status.lastUpdateDate ?? (
                <span className="text-amber-600">{t('common.noData')}</span>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Tabs */}
      <div className="flex border-b border-secondary-200">
        <TabButton
          active={tab === 'screen'}
          onClick={() => setTab('screen')}
          icon={<Search size={14} />}
        >
          {t('common.filter')}
        </TabButton>
        <TabButton
          active={tab === 'list'}
          onClick={() => setTab('list')}
          icon={<FileText size={14} />}
        >
          {t('sanction.listazasSupervisor')}
        </TabButton>
        <TabButton
          active={tab === 'admin'}
          onClick={() => setTab('admin')}
          icon={<Upload size={14} />}
        >
          {t('sanction.adminImportManager')}
        </TabButton>
      </div>

      {/* Tab content */}
      {tab === 'screen' && <ScreeningTab />}
      {tab === 'list' && <ListTab />}
      {tab === 'admin' && <AdminTab onImported={refreshStatus} />}
    </div>
  )
}

// ==================== TAB: SCREENING ====================

function ScreeningTab() {
  const { t } = useTranslation()
  const [name, setName] = useState('')
  const [documentNumber, setDocumentNumber] = useState('')
  const [dateOfBirth, setDateOfBirth] = useState('')
  const [nationality, setNationality] = useState('')
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<SanctionScreeningResult | null>(null)
  const [err, setErr] = useState<string | null>(null)

  const handleScreen = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim()) return
    setLoading(true)
    setErr(null)
    setResult(null)
    try {
      const r = await sanctionApi.screen({
        name: name.trim(),
        documentNumber: documentNumber.trim() || undefined,
        dateOfBirth: dateOfBirth || undefined,
        nationality: nationality.trim() || undefined,
      })
      setResult(r)
    } catch (e) {
      logger.error('Sanction', 'screen err', e)
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-4">
      <form onSubmit={(e) => void handleScreen(e)} className="form-panel p-4 space-y-3">
        <div>
          <label className="form-label">{t('sanction.ugyfelNeveKotelezo')}</label>
          <input
            type="text"
            className="form-input w-full"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="pl. Kovács János"
            required
            autoFocus
          />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="form-label">{t('sanction.okmanyszamOpcionalis')}</label>
            <input
              type="text"
              className="form-input w-full"
              value={documentNumber}
              onChange={(e) => setDocumentNumber(e.target.value)}
              placeholder="pl. AB1234567"
            />
          </div>
          <div>
            <label className="form-label">{t('sanction.szuletesiDatumOpcionalis')}</label>
            <input
              type="date"
              className="form-input w-full"
              value={dateOfBirth}
              onChange={(e) => setDateOfBirth(e.target.value)}
            />
          </div>
        </div>
        <div>
          <label className="form-label">
            {i18n.t('literals.allampolgarsag-orszag-fatf-opcionalis')}
          </label>
          <input
            type="text"
            className="form-input w-full"
            value={nationality}
            onChange={(e) => setNationality(e.target.value)}
            placeholder="pl. Törökország, Irán, Magyarország"
          />
        </div>
        <button type="submit" className="form-button-primary" disabled={loading || !name.trim()}>
          <Search size={16} />
          <span>{loading ? 'Szűrés...' : 'Szűrés indítása'}</span>
        </button>
      </form>

      {err && (
        <div className="p-4 rounded-lg bg-red-50 border border-red-200 text-red-800 flex items-center gap-2">
          <AlertTriangle size={18} />
          <span className="text-sm">{err}</span>
        </div>
      )}

      {result && (
        <div className={`form-panel p-4 border-2 ${RISK_COLOR[result.riskLevel]}`}>
          <div className="flex items-center gap-3 mb-3">
            {result.riskLevel === 'CLEAR' ? (
              <CheckCircle2 className="text-green-600" size={24} />
            ) : result.riskLevel === 'POSSIBLE' ? (
              <AlertTriangle className="text-amber-600" size={24} />
            ) : (
              <XCircle className="text-red-600" size={24} />
            )}
            <div>
              <div className="text-xs uppercase tracking-wide">{t('sanction.eredmeny')}</div>
              <div className="text-xl font-bold">{RISK_LABEL[result.riskLevel]}</div>
            </div>
            <div className="ml-auto text-sm">
              {result.matches.length} {t('common.talalat')}
            </div>
          </div>
          {result.fatfTier && result.fatfTier !== 'NONE' && (
            <div
              className={`mt-2 mb-1 p-3 rounded border-2 ${
                result.fatfTier === 'TIER_2_INCREASED_MONITORING'
                  ? 'bg-amber-50 border-amber-300 text-amber-800'
                  : 'bg-red-50 border-red-300 text-red-800'
              }`}
            >
              <div className="flex items-center gap-2 font-semibold">
                <AlertTriangle size={16} />
                <span>
                  {i18n.t('literals.fatf-orszag-kockazat')}
                  {FATF_LABEL[result.fatfTier]}
                </span>
              </div>
              {result.fatfRiskCountry && (
                <div className="text-sm mt-1">
                  {i18n.t('literals.orszag')}
                  <strong>{result.fatfRiskCountry}</strong>
                  {(result.fatfTier === 'TIER_1A_COUNTERMEASURE' ||
                    result.fatfTier === 'TIER_1B_ENHANCED_DD') &&
                    ' — fokozott ügyfél-átvilágítás kötelező!'}
                </div>
              )}
            </div>
          )}
          {result.matches.length > 0 && (
            <div className="mt-3 space-y-2">
              {result.matches.map((m) => (
                <div key={m.entryId} className="bg-white rounded p-3 border border-secondary-200">
                  <div className="flex items-center justify-between mb-1">
                    <div className="font-semibold text-secondary-900">{m.fullName}</div>
                    <div className="flex gap-2">
                      <span className="badge badge-blue text-xs">{m.listType}</span>
                      <span className="badge badge-orange text-xs">{m.matchType}</span>
                      <span className="text-xs font-mono">
                        {(m.score * 100).toFixed(0)}
                        {i18n.t('literals.lit-30')}
                      </span>
                    </div>
                  </div>
                  {m.aliases && (
                    <div className="text-xs text-secondary-600">
                      {t('sanction.alias')} {m.aliases}
                    </div>
                  )}
                  {m.dateOfBirth && (
                    <div className="text-xs text-secondary-600">
                      {i18n.t('literals.szul')}
                      {m.dateOfBirth}
                    </div>
                  )}
                  {m.nationality && (
                    <div className="text-xs text-secondary-600">
                      {t('sanction.nemzetiseg')} {m.nationality}
                    </div>
                  )}
                  {m.documentNumber && (
                    <div className="text-xs text-secondary-600">
                      {t('sanction.okmany')} {m.documentNumber}
                    </div>
                  )}
                  {m.listReference && (
                    <div className="text-xs text-secondary-500 mt-1">
                      {t('sanction.ref')}
                      {m.listReference}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
          {result.riskLevel !== 'CLEAR' && (
            <div className="mt-3 p-3 bg-white border border-red-300 rounded text-sm text-red-800">
              <strong>{t('sanction.fontos')}</strong>
              {t('sanction.possibleEsConfirmedEredmenynelSupervisorJovahagyasSzukseges')}
              {t('sanction.aTranzakcioFolytatasahozAmlWorkflowRogzitveVanAScreeningLogBan')}
            </div>
          )}
        </div>
      )}
    </div>
  )
}

// ==================== TAB: LIST ====================

function ListTab() {
  const { t } = useTranslation()
  const [entries, setEntries] = useState<SanctionEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [err, setErr] = useState<string | null>(null)
  const [page, setPage] = useState(0)
  const [filter, setFilter] = useState('')
  const PAGE_SIZE = 50

  useEffect(() => {
    let cancelled = false
    setLoading(true)
    setErr(null)
    sanctionApi
      .list(page, PAGE_SIZE)
      .then((data) => {
        if (!cancelled) setEntries(data)
      })
      .catch((e) => {
        if (!cancelled) {
          logger.error('Sanction', 'list err', e)
          setErr(e instanceof Error ? e.message : String(e))
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [page])

  const filtered = entries.filter(
    (e) =>
      filter === '' ||
      e.fullName.toLowerCase().includes(filter.toLowerCase()) ||
      (e.aliases ?? '').toLowerCase().includes(filter.toLowerCase()) ||
      (e.documentNumber ?? '').toLowerCase().includes(filter.toLowerCase()),
  )

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <input
          type="text"
          className="form-input flex-1"
          placeholder="Keres a listaban (nev, alias, okmanyszam)..."
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        />
        <button
          type="button"
          onClick={() => setPage((p) => Math.max(0, p - 1))}
          disabled={page === 0}
          className="form-button"
        >
          {t('sanction.elozo')}
        </button>
        <span className="text-sm text-secondary-600 px-2">
          {t('audit.oldal')}
          {page + 1}
        </span>
        <button
          type="button"
          onClick={() => setPage((p) => p + 1)}
          disabled={entries.length < PAGE_SIZE}
          className="form-button"
        >
          {t('sanction.kovetkezo')}
        </button>
      </div>

      {err && (
        <div className="p-4 rounded-lg bg-red-50 border border-red-200 text-red-800 text-sm">
          {err}
        </div>
      )}

      <div className="form-panel">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>{t('competitors.nev')}</th>
              <th>{t('sanction.lista')}</th>
              <th>{t('sanction.nemzetiseg')}</th>
              <th>{t('sanction.szul')}</th>
              <th>{t('sanction.okmany')}</th>
              <th>{t('competitors.aktiv')}</th>
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr>
                <td colSpan={6} className="text-center py-8 text-secondary-400">
                  {i18n.t('literals.betoltes-4')}
                </td>
              </tr>
            )}
            {!loading && filtered.length === 0 && (
              <tr>
                <td colSpan={6} className="text-center py-8 text-secondary-400">
                  {t('common.noData')}
                </td>
              </tr>
            )}
            {!loading &&
              filtered.map((e) => (
                <tr key={e.id}>
                  <td className="font-semibold">{e.fullName}</td>
                  <td>
                    <span className="badge badge-blue text-xs">{e.listType}</span>
                  </td>
                  <td className="text-sm">{e.nationality ?? '—'}</td>
                  <td className="text-sm font-mono">{e.dateOfBirth ?? '—'}</td>
                  <td className="text-sm font-mono">{e.documentNumber ?? '—'}</td>
                  <td>
                    {e.active ? (
                      <CheckCircle2 className="text-green-600" size={16} />
                    ) : (
                      <XCircle className="text-secondary-400" size={16} />
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

// ==================== TAB: ADMIN / IMPORT ====================

function AdminTab({ onImported }: { onImported: () => void }) {
  const { t } = useTranslation()
  const fileRef = useRef<HTMLInputElement>(null)
  const [importing, setImporting] = useState(false)
  const [result, setResult] = useState<SanctionImportResult | null>(null)
  const [err, setErr] = useState<string | null>(null)

  const handleImport = async (e: React.FormEvent) => {
    e.preventDefault()
    const file = fileRef.current?.files?.[0]
    if (!file) return
    setImporting(true)
    setErr(null)
    setResult(null)
    try {
      const r = await sanctionApi.import(file)
      setResult(r)
      onImported() // refresh status
    } catch (e) {
      logger.error('Sanction', 'import err', e)
      setErr(e instanceof Error ? e.message : String(e))
    } finally {
      setImporting(false)
    }
  }

  return (
    <div className="space-y-3">
      <div className="form-panel p-4">
        <h3 className="font-semibold text-secondary-900 mb-2">
          {t('sanction.ujSzankciosListaImportXml')}
        </h3>
        <p className="text-sm text-secondary-600 mb-4">{t('sanction.tamogatottForrasok')}</p>
        <ul className="text-sm text-secondary-600 mb-4 list-disc list-inside space-y-1">
          <li>
            {t('sanction.ensz')}
            <a
              className="text-blue-600 underline"
              href="https://scsanctions.un.org/resources/xml/en/consolidated.xml"
              target="_blank"
              rel="noreferrer"
            >
              {t('sanction.scsanctionsunorg')}
            </a>
          </li>
          <li>
            {t('sanction.eu')}
            <a
              className="text-blue-600 underline"
              href="https://webgate.ec.europa.eu/fsd/fsf/public/files/xmlFullSanctionsList_1_1"
              target="_blank"
              rel="noreferrer"
            >
              {t('sanction.euFsfXml')}
            </a>
          </li>
          <li>{t('sanction.ofacKeszuloben')}</li>
        </ul>
        <form onSubmit={(e) => void handleImport(e)} className="flex items-center gap-2">
          <input
            ref={fileRef}
            type="file"
            accept=".xml,text/xml,application/xml"
            className="form-input flex-1"
            required
            aria-label="XML fajl"
          />
          <button type="submit" className="form-button-primary" disabled={importing}>
            <Upload size={16} />
            <span>{importing ? 'Import...' : 'Import inditasa'}</span>
          </button>
        </form>
      </div>

      {err && (
        <div className="p-4 rounded-lg bg-red-50 border border-red-200 text-red-800 flex items-center gap-2">
          <AlertTriangle size={18} />
          <span className="text-sm">{err}</span>
        </div>
      )}

      {result && (
        <div className="p-4 rounded-lg bg-green-50 border border-green-200 text-green-800">
          <div className="flex items-center gap-2 mb-2">
            <CheckCircle2 size={18} />
            <span className="font-semibold">{t('sanction.importSikeres')}</span>
          </div>
          <div className="text-sm">
            {t('sanction.ujFrissitettBejegyzesek')}
            <strong>{result.imported}</strong>
          </div>
          <div className="text-sm">{result.message}</div>
        </div>
      )}
    </div>
  )
}

// ==================== Helper: TabButton ====================

function TabButton({
  active,
  onClick,
  icon,
  children,
}: {
  active: boolean
  onClick: () => void
  icon: React.ReactNode
  children: React.ReactNode
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`px-4 py-2 text-sm font-semibold border-b-2 flex items-center gap-2 transition-all ${
        active
          ? 'text-primary-600 border-primary-600'
          : 'text-secondary-500 border-transparent hover:text-secondary-800'
      }`}
    >
      {icon}
      {children}
    </button>
  )
}
