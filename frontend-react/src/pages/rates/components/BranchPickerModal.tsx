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
