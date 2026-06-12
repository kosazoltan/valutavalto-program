import { useState, useEffect, useCallback } from 'react'
import { Settings, Plus, Trash2, Save, Eye } from 'lucide-react'
import { handlingFeeConfigApi, type HandlingFeeConfig, type HandlingFeeBracketConfig } from '../../services/api/settings'
import { logger } from '../../utils/logger'
import { useAuthStore } from '../../stores/authStore'

export default function HandlingFeeConfigPage() {
  // Batch2-B: a pénztár-kliensben pénztárosnak is látható az oldal (átláthatóság —
  // a program ezzel a konfiggal számol), de szerkeszteni csak a vezetői körök tudnak.
  // A kör a szerver-oldali PUT-joggal azonos (HandlingFeeConfigController class-szintű
  // @PreAuthorize: MANAGER/ADMIN/UGYVEZETO/FOERTEKTAR/IRODAVEZETO/BELSO_ELLENOR) — ez UX-gate.
  const canEdit = useAuthStore(s => s.hasCanonicalRole)(['ugyvezeto', 'foertektar', 'irodavezeto', 'belso_ellenor', 'admin'])
  const [config, setConfig] = useState<HandlingFeeConfig | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  const loadConfig = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await handlingFeeConfigApi.get()
      setConfig(data)
    } catch (err) {
      logger.error('HandlingFeeConfigPage', 'Konfiguráció betöltési hiba', err)
      setError('Hiba a kezelési költség konfiguráció betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { void loadConfig() }, [loadConfig])

  const handleSave = async () => {
    if (!config) return
    try {
      setSaving(true)
      setError(null)
      setSuccess(null)
      const updated = await handlingFeeConfigApi.update(config)
      setConfig(updated)
      setSuccess('Kezelési költség konfiguráció mentve!')
      setTimeout(() => setSuccess(null), 3000)
    } catch (err) {
      logger.error('HandlingFeeConfigPage', 'Mentési hiba', err)
      setError('Hiba a mentés során')
    } finally {
      setSaving(false)
    }
  }

  const addBracket = () => {
    if (!config) return
    const lastOrder = config.brackets.length > 0
      ? Math.max(...config.brackets.map(b => b.bracketOrder))
      : 0
    const lastUpperLimit = config.brackets.length > 0
      ? (config.brackets[config.brackets.length - 1]?.upperLimit ?? 0)
      : 0
    setConfig({
      ...config,
      brackets: [...config.brackets, {
        bracketOrder: lastOrder + 1,
        upperLimit: lastUpperLimit + 50000,
        feeAmount: 0,
        active: true,
      }],
    })
  }

  const removeBracket = (index: number) => {
    if (!config) return
    const newBrackets = config.brackets.filter((_, i) => i !== index)
      .map((b, i) => ({ ...b, bracketOrder: i + 1 }))
    setConfig({ ...config, brackets: newBrackets })
  }

  const updateBracket = (index: number, field: keyof HandlingFeeBracketConfig, value: number) => {
    if (!config) return
    const newBrackets = [...config.brackets]
    newBrackets[index] = { ...newBrackets[index]!, [field]: value }
    setConfig({ ...config, brackets: newBrackets })
  }

  if (loading) return <div className="p-6 text-center text-gray-500">Betöltés...</div>

  if (!config) return <div className="p-6 text-center text-red-500">{error || 'Nincs konfiguráció'}</div>

  return (
    <div className="space-y-6 p-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Settings size={24} /> Kezelési költség beállítások
        </h1>
        {canEdit && (
          <button
            type="button"
            onClick={handleSave}
            disabled={saving}
            className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
          >
            <Save size={16} /> {saving ? 'Mentés...' : 'Mentés'}
          </button>
        )}
      </div>

      {!canEdit && (
        <div className="bg-blue-50 border border-blue-200 text-blue-800 px-4 py-3 rounded flex items-center gap-2 text-sm">
          <Eye size={16} className="shrink-0" />
          Megtekintő nézet — a program ezekkel a beállításokkal számolja a kezelési díjat.
          Módosításhoz vezetői jogosultság szükséges (ügyvezető / irodavezető / főértéktáros).
        </div>
      )}

      {error && <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>}
      {success && <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">{success}</div>}

      {/* Fee type selector */}
      <div className="bg-white dark:bg-gray-800 rounded-lg border p-4">
        <h2 className="text-lg font-semibold mb-3">Díjszámítás módja</h2>
        <div className="flex gap-4">
          {([
            { value: 'NONE', label: 'Nincs kezelési díj' },
            { value: 'BRACKET', label: 'Sávos díjszámítás' },
            { value: 'PER_MILLE', label: 'Ezrelékes díjszámítás' },
          ] as const).map(opt => (
            <label key={opt.value} className={`flex items-center gap-2 ${canEdit ? 'cursor-pointer' : 'cursor-default'}`}>
              <input
                type="radio"
                name="feeType"
                value={opt.value}
                checked={config.feeType === opt.value}
                disabled={!canEdit}
                onChange={() => setConfig({ ...config, feeType: opt.value })}
                className="accent-blue-600"
              />
              <span className={config.feeType === opt.value ? 'font-semibold text-blue-700' : ''}>{opt.label}</span>
            </label>
          ))}
        </div>
      </div>

      {/* PER_MILLE config */}
      {config.feeType === 'PER_MILLE' && (
        <div className="bg-white dark:bg-gray-800 rounded-lg border p-4">
          <h2 className="text-lg font-semibold mb-3">Ezrelékes beállítások</h2>
          <div className="grid grid-cols-2 gap-4 max-w-lg">
            <div>
              <label className="block text-sm font-medium mb-1">Ezrelék mértéke (‰)</label>
              <input
                type="number"
                step="0.1"
                min="0"
                value={config.perMilleRate}
                disabled={!canEdit}
                onChange={(e) => setConfig({ ...config, perMilleRate: parseFloat(e.target.value) || 0 })}
                className="w-full border rounded px-3 py-2 disabled:bg-gray-50 disabled:text-gray-600"
              />
              <p className="text-xs text-gray-500 mt-1">Pl. 5 = a HUF összeg 5 ezreléke</p>
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Maximum összeg (Ft)</label>
              <input
                type="number"
                step="100"
                min="0"
                value={config.perMilleMaxAmount ?? ''}
                disabled={!canEdit}
                onChange={(e) => setConfig({ ...config, perMilleMaxAmount: e.target.value ? parseFloat(e.target.value) : null })}
                className="w-full border rounded px-3 py-2 disabled:bg-gray-50 disabled:text-gray-600"
                placeholder="Korlátlan"
              />
              <p className="text-xs text-gray-500 mt-1">0 vagy üres = nincs felső korlát</p>
            </div>
          </div>
          <div className="mt-3 p-3 bg-blue-50 dark:bg-blue-950/30 rounded text-sm">
            Példa: 500.000 Ft tranzakció × {config.perMilleRate}‰ = {Math.round(500000 * config.perMilleRate / 1000).toLocaleString('hu-HU')} Ft kezelési díj
            {config.perMilleMaxAmount && config.perMilleMaxAmount > 0 && (
              <> (max: {config.perMilleMaxAmount.toLocaleString('hu-HU')} Ft)</>
            )}
          </div>
        </div>
      )}

      {/* BRACKET config */}
      {config.feeType === 'BRACKET' && (
        <div className="bg-white dark:bg-gray-800 rounded-lg border p-4">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-lg font-semibold">Díjsávok</h2>
            {canEdit && (
              <button
                type="button"
                onClick={addBracket}
                className="flex items-center gap-1 text-sm bg-green-600 text-white px-3 py-1.5 rounded hover:bg-green-700"
              >
                <Plus size={14} /> Új sáv
              </button>
            )}
          </div>

          {config.brackets.length === 0 ? (
            <p className="text-gray-500 text-center py-4">Nincs még díjsáv. Kattints az "Új sáv" gombra!</p>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b text-left">
                  <th className="py-2 px-2 w-16">#</th>
                  <th className="py-2 px-2">Alsó határ (Ft)</th>
                  <th className="py-2 px-2">Felső határ (Ft)</th>
                  <th className="py-2 px-2">Kezelési díj (Ft)</th>
                  <th className="py-2 px-2 w-16"></th>
                </tr>
              </thead>
              <tbody>
                {config.brackets.map((bracket, index) => {
                  const lowerLimit = index === 0 ? 0 : (config.brackets[index - 1]?.upperLimit ?? 0) + 1
                  return (
                    <tr key={index} className="border-b hover:bg-gray-50 dark:hover:bg-gray-700/50">
                      <td className="py-2 px-2 text-gray-500">{bracket.bracketOrder}</td>
                      <td className="py-2 px-2 text-gray-500">{lowerLimit.toLocaleString('hu-HU')}</td>
                      <td className="py-2 px-2">
                        <input
                          type="number"
                          step="1000"
                          min={lowerLimit}
                          value={bracket.upperLimit}
                          disabled={!canEdit}
                          onChange={(e) => updateBracket(index, 'upperLimit', parseInt(e.target.value) || 0)}
                          className="w-full border rounded px-2 py-1 disabled:bg-gray-50 disabled:text-gray-600"
                        />
                      </td>
                      <td className="py-2 px-2">
                        <input
                          type="number"
                          step="50"
                          min="0"
                          value={bracket.feeAmount}
                          disabled={!canEdit}
                          onChange={(e) => updateBracket(index, 'feeAmount', parseInt(e.target.value) || 0)}
                          className="w-full border rounded px-2 py-1 disabled:bg-gray-50 disabled:text-gray-600"
                        />
                      </td>
                      <td className="py-2 px-2">
                        {canEdit && (
                          <button
                            type="button"
                            onClick={() => removeBracket(index)}
                            className="text-red-500 hover:text-red-700 p-1"
                            title="Sáv törlése"
                          >
                            <Trash2 size={14} />
                          </button>
                        )}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  )
}
