import { X } from 'lucide-react'
import type { BranchListItem } from '../../../services/api/index'
import { useTranslation } from 'react-i18next'

interface BranchPickerModalProps {
  open: boolean
  selectedWgName?: string
  branchFilter: string
  setBranchFilter: (value: string) => void
  groupedBranches: [string, BranchListItem[]][]
  selectedBranchIds: Set<string>
  toggleBranch: (id: string) => void
  onClose: () => void
  onSave: () => void
  saving: boolean
  canWriteRateCreation: boolean
  /**
   * FK05 (FR-6): a kijelölt, de MÁSIK munkacsoporthoz tartozó pénztárak figyelmeztetése —
   * a backend move-strategy-vel ÁTHELYEZI őket (V234 uk_branch_workgroup_exclusive), a
   * felhasználó ezt mentés ELŐTT látja a modalban. Elem: "kód — név (jelenlegi csoport)".
   */
  moveWarnings?: string[]
  /** FK05 (FR-6): mentési hiba a MODALON BELÜL (nem csak toast) — pl. constraint-ütközés. */
  saveError?: string | null
}

export default function BranchPickerModal({
  open,
  selectedWgName,
  branchFilter,
  setBranchFilter,
  groupedBranches,
  selectedBranchIds,
  toggleBranch,
  onClose,
  onSave,
  saving,
  canWriteRateCreation,
  moveWarnings,
  saveError,
}: BranchPickerModalProps) {
  const { t } = useTranslation()
  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div className="bg-white rounded-lg shadow-xl w-[600px] max-h-[80vh] flex flex-col">
        <div className="flex items-center justify-between px-4 py-2 border-b">
          <h2 className="text-sm font-bold text-gray-800">
            {t('rates.irodakKezelese')}{selectedWgName}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <X size={18} />
          </button>
        </div>

        <div className="px-4 py-2 border-b">
          <input
            type="text"
            placeholder="Keresés név, kód vagy város szerint..."
            value={branchFilter}
            onChange={e => setBranchFilter(e.target.value)}
            className="w-full px-3 py-1.5 text-sm border rounded focus:border-blue-400 focus:outline-none"
          />
        </div>

        <div className="flex-1 overflow-y-auto px-4 py-2">
          {groupedBranches.map(([city, branches]) => (
            <div key={city} className="mb-2">
              <div className="text-[10px] font-bold text-gray-500 uppercase mb-0.5">{city}</div>
              <div className="space-y-0.5">
                {branches.map(b => (
                  <label key={b.id} className="flex items-center gap-2 px-2 py-1 rounded hover:bg-gray-50 cursor-pointer text-xs">
                    <input
                      type="checkbox"
                      checked={selectedBranchIds.has(b.id)}
                      onChange={() => toggleBranch(b.id)}
                      className="rounded border-gray-300 text-green-600 focus:ring-green-500"
                    />
                    <span className="font-mono text-gray-500 w-12">{b.code}</span>
                    <span className="text-gray-800">{b.name}</span>
                  </label>
                ))}
              </div>
            </div>
          ))}
          {groupedBranches.length === 0 && (
            <div className="text-center text-gray-400 py-8 text-sm">{t('common.noResult')}</div>
          )}
        </div>

        {(moveWarnings?.length ?? 0) > 0 && (
          <div data-testid="branch-move-warning"
            className="px-4 py-2 border-t bg-amber-50 text-xs text-amber-800">
            <div className="font-semibold">{t('rates.athelyezesMasikCsoportbol')}</div>
            <ul className="list-disc ml-4">
              {moveWarnings!.map((w) => <li key={w}>{w}</li>)}
            </ul>
            <div className="mt-1">{t('rates.athelyezesMagyarazat')}</div>
          </div>
        )}
        {saveError && (
          <div data-testid="branch-save-error"
            className="px-4 py-2 border-t bg-red-50 text-xs text-red-700 font-semibold">
            {saveError}
          </div>
        )}
        <div className="flex items-center justify-between px-4 py-2 border-t bg-gray-50">
          <span className="text-xs text-gray-500">{selectedBranchIds.size} {t('rates.irodaKivalasztva')}</span>
          <div className="flex gap-2">
            <button onClick={onClose}
              className="px-3 py-1.5 text-xs border rounded hover:bg-gray-100">
              {t('common.cancel')}
            </button>
            <button onClick={onSave} disabled={saving || !canWriteRateCreation}
              className="px-3 py-1.5 text-xs bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white rounded font-bold">
              {saving ? 'Mentés...' : 'Mentés'}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
