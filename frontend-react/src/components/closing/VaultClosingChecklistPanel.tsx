import { useState, useEffect, useCallback } from 'react'
import { CheckSquare, Square, ClipboardList, Loader2, CheckCircle } from 'lucide-react'
import { toast } from '../ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { useAuthStore } from '../../stores/authStore'
import { vaultClosingChecklistApi } from '../../services/api/vaultClosingChecklist'
import type {
  VaultClosingChecklistDto,
  UpdateChecklistItemsRequest,
} from '../../services/api/vaultClosingChecklist'
import VaultClosingAuditorDialog from './VaultClosingAuditorDialog'
import type { CompleteChecklistRequest } from '../../services/api/vaultClosingChecklist'
import i18n from '../../i18n'

/**
 * Értéktári zárás-előtti ellenőrzőlista panel.
 *
 * FR-ZARUI-16..26 (b2-zaras-kepernyok-bizonylatok.md)
 *
 * A 9 tétel pontos szövege a spec szerint (FR-ZARUI-17..25).
 * "Zárás véglegesítése" gomb: FR-ZARUI-26 ellenőrző személy dialógust nyit.
 *
 * Az integrációs pont: EveningClosingPage, "Zárás-előtti ellenőrzőlista" szekció.
 */

/** A 9 checklist-tétel a spec PONTOS szövegeivel (FR-ZARUI-17..25). */
const CHECKLIST_ITEMS: Array<{
  key: keyof UpdateChecklistItemsRequest
  label: string
  fr: string
}> = [
  {
    key: 'item1',
    label: 'Minden pénztár készlete feltöltve (címletek, fém euró)',
    fr: 'FR-ZARUI-17',
  },
  {
    key: 'item2',
    label: 'Esetleges helyettesítéskor kollégának minden infó átadólapon átadva',
    fr: 'FR-ZARUI-18',
  },
  {
    key: 'item3',
    label: 'Grafikon kitöltve, kifüggesztve, érintetteknek továbbítva',
    fr: 'FR-ZARUI-19',
  },
  {
    key: 'item4',
    label:
      'Konkurencia árfolyamainak/készleteinek figyelemmel követése; konkurencia-jelentés megírása (eseti)',
    fr: 'FR-ZARUI-20',
  },
  {
    key: 'item5',
    label: 'Próbaváltás (eseti); havi beszámoló megírása, lefűzése (eseti)',
    fr: 'FR-ZARUI-21',
  },
  {
    key: 'item6',
    label: 'Bizonylatok párosítása, lefűzése; Kkts/E-ker/jutalék beszedése-befizetése (eseti)',
    fr: 'FR-ZARUI-22',
  },
  {
    key: 'item7',
    label:
      'TRB tábla kitöltése; egyedi árfolyamos tábla kitöltése+továbbítása (eseti); egyedi árfolyamok ellenőrzése+továbbítása (eseti)',
    fr: 'FR-ZARUI-23',
  },
  {
    key: 'item8',
    label:
      'Nagy ügyfélkártyák begyűjtése/összesítése, továbbítása (eseti); könyvelések lenyomtatása, lefűzése, adatainak ellenőrzése (eseti)',
    fr: 'FR-ZARUI-24',
  },
  {
    key: 'item9',
    label:
      'Hóvégi egyeztetés területekkel (eseti); hóvégi egyeztetés pénztárakkal; napi jelentések leszavainak elküldése SMS-ben a pénztáraknak/értéktárosoknak stb. (eseti)',
    fr: 'FR-ZARUI-25',
  },
]

interface Props {
  /** Zárás dátuma (ISO: yyyy-MM-dd) */
  date: string
}

export default function VaultClosingChecklistPanel({ date }: Props) {
  const worker = useAuthStore((s) => s.worker)
  const branchId = worker?.branchId ?? ''
  const workerName =
    worker?.fullName ?? `${worker?.lastName ?? ''} ${worker?.firstName ?? ''}`.trim()

  const [checklist, setChecklist] = useState<VaultClosingChecklistDto | null>(null)
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [completing, setCompleting] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [auditorDialogOpen, setAuditorDialogOpen] = useState(false)
  const [expanded, setExpanded] = useState(true)

  const loadChecklist = useCallback(async () => {
    if (!branchId || !date) return
    try {
      setLoading(true)
      setError(null)
      const data = await vaultClosingChecklistApi.getOrCreate(branchId, date)
      setChecklist(data)
    } catch (err) {
      logger.error('VaultClosingChecklistPanel', 'Betöltés hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [branchId, date])

  useEffect(() => {
    void loadChecklist()
  }, [loadChecklist])

  const handleToggle = async (key: keyof UpdateChecklistItemsRequest) => {
    if (!checklist || saving || completing || checklist.completedAt) return
    const updated: UpdateChecklistItemsRequest = {
      item1: checklist.item1,
      item2: checklist.item2,
      item3: checklist.item3,
      item4: checklist.item4,
      item5: checklist.item5,
      item6: checklist.item6,
      item7: checklist.item7,
      item8: checklist.item8,
      item9: checklist.item9,
      [key]: !checklist[key],
    }
    // optimista frissítés
    setChecklist((prev) => (prev ? { ...prev, [key]: !prev[key] } : prev))
    try {
      setSaving(true)
      const saved = await vaultClosingChecklistApi.updateItems(branchId, date, updated)
      setChecklist(saved)
    } catch (err) {
      logger.error('VaultClosingChecklistPanel', 'Mentés hiba:', err)
      toast.error('Mentési hiba', getErrorMessage(err))
      // visszaáll az eredeti
      await loadChecklist()
    } finally {
      setSaving(false)
    }
  }

  const handleCompleteRequest = () => {
    setAuditorDialogOpen(true)
  }

  const handleComplete = async (req: CompleteChecklistRequest) => {
    if (!branchId || !date) return
    try {
      setCompleting(true)
      const result = await vaultClosingChecklistApi.complete(branchId, date, req)
      setChecklist(result)
      setAuditorDialogOpen(false)
      toast.success('Zárás véglegesítve', `Ellenőrző: ${req.auditorName} (${req.auditorRole})`)
    } catch (err) {
      logger.error('VaultClosingChecklistPanel', 'Véglegesítés hiba:', err)
      toast.error('Véglegesítési hiba', getErrorMessage(err))
    } finally {
      setCompleting(false)
    }
  }

  const isCompleted = !!checklist?.completedAt
  const checkedCount = checklist ? CHECKLIST_ITEMS.filter((item) => checklist[item.key]).length : 0

  return (
    <>
      <div className="rounded-lg border border-blue-200 bg-blue-50">
        {/* Fejléc / összefoglaló sor — kattintható (összecsukás) */}
        <button
          type="button"
          onClick={() => setExpanded((v) => !v)}
          className="flex w-full items-center justify-between px-4 py-3 text-left"
        >
          <div className="flex items-center gap-2">
            <ClipboardList size={18} className="text-blue-600" />
            <span className="font-semibold text-blue-800">
              {i18n.t('literals.zaras-elotti-ellenorzolista')}
            </span>
            {!loading && checklist && (
              <span className="ml-2 rounded-full bg-blue-200 px-2 py-0.5 text-xs font-medium text-blue-800">
                {checkedCount}
                {i18n.t('literals.lit-4')}
                {CHECKLIST_ITEMS.length}
              </span>
            )}
          </div>
          <div className="flex items-center gap-2">
            {isCompleted && (
              <span className="flex items-center gap-1 text-xs font-semibold text-green-700">
                <CheckCircle size={14} />
                {i18n.t('literals.lezarva')}
              </span>
            )}
            {saving && <Loader2 size={14} className="animate-spin text-blue-500" />}
            <span className="text-xs text-gray-400">{expanded ? '▲' : '▼'}</span>
          </div>
        </button>

        {expanded && (
          <div className="border-t border-blue-200 px-4 pb-4 pt-3">
            {/* Fejléc: dátum + zárást végző pénztáros */}
            <div className="mb-3 flex flex-wrap gap-x-6 gap-y-1 text-sm text-gray-600">
              <span>
                <span className="font-medium">{i18n.t('literals.datum')}</span> {date}
              </span>
              {workerName && (
                <span>
                  <span className="font-medium">{i18n.t('literals.penztaros')}</span> {workerName}
                </span>
              )}
            </div>

            {loading && (
              <div className="flex items-center gap-2 py-2 text-sm text-gray-500">
                <Loader2 size={14} className="animate-spin" />
                {i18n.t('literals.betoltes-2')}
              </div>
            )}

            {error && !loading && (
              <div className="mb-3 rounded border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
                {error}
              </div>
            )}

            {checklist && !loading && (
              <>
                {/* 9 checklist-tétel */}
                <ul className="space-y-2">
                  {CHECKLIST_ITEMS.map((item, idx) => {
                    const checked = checklist[item.key] as boolean
                    return (
                      <li key={item.key}>
                        <button
                          type="button"
                          onClick={() => void handleToggle(item.key)}
                          disabled={saving || completing || isCompleted}
                          className={`flex w-full items-start gap-3 rounded px-2 py-1.5 text-left transition-colors
                            ${isCompleted ? 'cursor-default opacity-75' : 'hover:bg-blue-100'}
                            ${saving || completing ? 'opacity-60' : ''}
                          `}
                          aria-label={`${idx + 1}. tétel: ${item.label} — ${checked ? 'kipipálva' : 'nem pipa'}`}
                        >
                          <span className="mt-0.5 shrink-0">
                            {checked ? (
                              <CheckSquare size={18} className="text-green-600" />
                            ) : (
                              <Square size={18} className="text-gray-400" />
                            )}
                          </span>
                          <span
                            className={`text-sm leading-snug ${checked ? 'text-gray-700' : 'text-gray-800'}`}
                          >
                            <span className="mr-1 font-medium text-gray-500">
                              {idx + 1}
                              {i18n.t('literals.lit-5')}
                            </span>
                            {item.label}
                          </span>
                        </button>
                      </li>
                    )
                  })}
                </ul>

                {/* Véglegesítés gomb / lezárva státusz */}
                <div className="mt-4 border-t border-blue-200 pt-3">
                  {isCompleted ? (
                    <div className="rounded border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
                      <div className="flex items-center gap-1 font-semibold">
                        <CheckCircle size={14} />
                        {i18n.t('literals.zaras-veglegesitve')}
                      </div>
                      {checklist.auditorName && (
                        <div className="mt-1 text-xs">
                          {i18n.t('literals.ellenorzo')}
                          {checklist.auditorName}
                          {checklist.auditorRole && ` (${checklist.auditorRole})`}
                        </div>
                      )}
                      {checklist.completedAt && (
                        <div className="mt-0.5 text-xs text-gray-500">
                          {new Date(checklist.completedAt).toLocaleString('hu-HU')}
                        </div>
                      )}
                    </div>
                  ) : (
                    <button
                      type="button"
                      onClick={handleCompleteRequest}
                      disabled={saving || completing}
                      className="w-full rounded bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700 disabled:opacity-50"
                    >
                      {completing ? (
                        <span className="flex items-center justify-center gap-2">
                          <Loader2 size={14} className="animate-spin" />
                          {i18n.t('literals.mentes')}
                        </span>
                      ) : (
                        'Zárás véglegesítése'
                      )}
                    </button>
                  )}
                </div>
              </>
            )}
          </div>
        )}
      </div>

      {/* FR-ZARUI-26 dialógus */}
      <VaultClosingAuditorDialog
        open={auditorDialogOpen}
        onConfirm={(req) => void handleComplete(req)}
        onCancel={() => setAuditorDialogOpen(false)}
        submitting={completing}
      />
    </>
  )
}
