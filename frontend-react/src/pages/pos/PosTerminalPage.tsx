import { useState, useEffect, useCallback } from 'react'
import { CreditCard, Plus, Edit2, Trash2, Power, PowerOff, RefreshCw, Search } from 'lucide-react'
import { posTerminalApi, PosTerminal } from '../../services/api/index'
import { safeArray } from '@/utils/safeArray'
import { logger } from '../../utils/logger'
import { toast } from '../../components/ui/toaster'
import { getErrorMessage } from '../../utils/errorHandling'
import { useTranslation } from 'react-i18next'

interface PosTerminalForm {
  terminalId: string
  terminalName: string
  branchId: string
  comPort: string
  baudRate: number
  connectionType: string
  ipAddress: string
  port: number
}

const emptyForm: PosTerminalForm = {
  terminalId: '',
  terminalName: '',
  branchId: '',
  comPort: 'COM1',
  baudRate: 9600,
  connectionType: 'SERIAL',
  ipAddress: '',
  port: 0,
}

export default function PosTerminalPage() {
  const { t } = useTranslation()
  const [terminals, setTerminals] = useState<PosTerminal[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [showForm, setShowForm] = useState(false)
  const [editingId, setEditingId] = useState<string | null>(null)
  const [form, setForm] = useState<PosTerminalForm>(emptyForm)
  const [saving, setSaving] = useState(false)
  const [testResult, setTestResult] = useState<{ id: string; success: boolean; message: string } | null>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      setTerminals(await posTerminalApi.list())
    } catch (err) {
      logger.error('PosTerminalPage', 'POS terminálok betöltési hiba:', err)
      setError('Nem sikerült betölteni a POS terminálokat')
      toast.error('Hiba', 'POS terminálok betöltése sikertelen')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const handleSave = async () => {
    if (!form.terminalId || !form.terminalName) {
      toast.warning('Hiányzó adat', 'Terminál ID és név megadása kötelező')
      return
    }
    try {
      setSaving(true)
      setError(null)
      if (editingId) {
        await posTerminalApi.update(editingId, form)
        toast.success('Terminál frissítve')
      } else {
        await posTerminalApi.create(form)
        toast.success('Terminál létrehozva')
      }
      setShowForm(false)
      setEditingId(null)
      setForm(emptyForm)
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      toast.error('Hiba', msg)
    } finally {
      setSaving(false)
    }
  }

  const handleEdit = (terminal: PosTerminal) => {
    setEditingId(terminal.id)
    setForm({
      terminalId: terminal.terminalId,
      terminalName: terminal.terminalName,
      branchId: terminal.branchId || '',
      comPort: terminal.comPort || 'COM1',
      baudRate: terminal.baudRate || 9600,
      connectionType: terminal.connectionType || 'SERIAL',
      ipAddress: terminal.ipAddress || '',
      port: terminal.port || 0,
    })
    setShowForm(true)
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törli ezt a terminált?')) return
    try {
      setError(null)
      await posTerminalApi.delete(id)
      toast.success('Terminál törölve')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
      toast.error('Hiba', msg)
    }
  }

  const handleToggleActive = async (terminal: PosTerminal) => {
    try {
      setError(null)
      await posTerminalApi.update(terminal.id, { isActive: !terminal.isActive })
      toast.success(terminal.isActive ? 'Terminál deaktiválva' : 'Terminál aktiválva')
      await loadData()
    } catch (err) {
      const msg = getErrorMessage(err)
      setError(msg)
    }
  }

  const handleTestConnection = async (id: string) => {
    try {
      setTestResult(null)
      const result = await posTerminalApi.testConnection(id)
      setTestResult({ id, success: result.success, message: result.message || (result.success ? 'Kapcsolat OK' : 'Sikertelen') })
      if (result.success) {
        toast.success('Kapcsolat OK')
      } else {
        toast.error('Kapcsolat sikertelen', result.message)
      }
    } catch (err) {
      setTestResult({ id, success: false, message: getErrorMessage(err) })
    }
  }

  const filtered = safeArray<PosTerminal>(terminals).filter(t =>
    !searchTerm || t.terminalId.toLowerCase().includes(searchTerm.toLowerCase()) ||
    t.terminalName.toLowerCase().includes(searchTerm.toLowerCase())
  )

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><CreditCard />{t('pos.posTerminalok')}</h1>
        <button onClick={() => { setShowForm(true); setEditingId(null); setForm(emptyForm) }} className="form-button-primary">
          <Plus size={16} />{t('pos.ujTerminal')}
        </button>
      </div>

      {/* Keresés */}
      <div className="flex gap-2 items-center">
        <Search size={16} className="text-gray-400" />
        <input
          className="form-input flex-1"
          placeholder="Keresés terminál ID vagy név alapján..."
          value={searchTerm}
          onChange={e => setSearchTerm(e.target.value)}
        />
        <button onClick={() => void loadData()} className="form-button" title="Frissítés">
          <RefreshCw size={16} />
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
      )}

      {/* Új/Szerkesztés form */}
      {showForm && (
        <div className="form-panel space-y-3 border-2 border-blue-200">
          <h2 className="font-semibold">{editingId ? 'Terminál szerkesztése' : 'Új terminál'}</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label">{t('pos.terminalId')}</label>
              <input className="form-input" value={form.terminalId} onChange={e => setForm({...form, terminalId: e.target.value})} disabled={!!editingId} />
            </div>
            <div>
              <label className="form-label">{t('pos.megnevezes')}</label>
              <input className="form-input" value={form.terminalName} onChange={e => setForm({...form, terminalName: e.target.value})} />
            </div>
            <div>
              <label className="form-label">{t('pos.kapcsolatTipusa')}</label>
              <select className="form-input" value={form.connectionType} onChange={e => setForm({...form, connectionType: e.target.value})}>
                <option value="SERIAL">{t('pos.sorosPortRs232')}</option>
                <option value="TCP">{t('pos.tcpIpHalozat')}</option>
                <option value="USB">USB</option>
              </select>
            </div>
            {form.connectionType === 'SERIAL' && (
              <>
                <div>
                  <label className="form-label">{t('display.comPort')}</label>
                  <select className="form-input" value={form.comPort} onChange={e => setForm({...form, comPort: e.target.value})}>
                    {['COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8'].map(p => <option key={p} value={p}>{p}</option>)}
                  </select>
                </div>
                <div>
                  <label className="form-label">{t('display.baudRate')}</label>
                  <select className="form-input" value={form.baudRate} onChange={e => setForm({...form, baudRate: Number(e.target.value)})}>
                    {[9600, 19200, 38400, 57600, 115200].map(b => <option key={b} value={b}>{b}</option>)}
                  </select>
                </div>
              </>
            )}
            {form.connectionType === 'TCP' && (
              <>
                <div>
                  <label className="form-label">{t('common.ipAddress')}</label>
                  <input className="form-input" value={form.ipAddress} onChange={e => setForm({...form, ipAddress: e.target.value})} placeholder="192.168.1.100" />
                </div>
                <div>
                  <label className="form-label">{t('display.port')}</label>
                  <input className="form-input" type="number" value={form.port} onChange={e => setForm({...form, port: Number(e.target.value)})} placeholder="8000" />
                </div>
              </>
            )}
          </div>
          <div className="flex gap-2">
            <button onClick={handleSave} disabled={saving} className="form-button-primary">{saving ? 'Mentés...' : 'Mentés'}</button>
            <button onClick={() => { setShowForm(false); setEditingId(null) }} className="form-button">{t('common.cancel')}</button>
          </div>
        </div>
      )}

      {/* Terminálok lista */}
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          {filtered.length === 0 ? (
            <div className="text-center text-gray-500 py-8">{t('pos.nincsPosTerminalKonfiguralva')}</div>
          ) : (
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th>{t('pos.terminalId2')}</th>
                  <th>{t('display.megnevezes')}</th>
                  <th>{t('commissions.fiok')}</th>
                  <th>{t('display.kapcsolat')}</th>
                  <th>{t('customers.utolsoTranzakcio')}</th>
                  <th>{t('common.status')}</th>
                  <th>{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(t => (
                  <tr key={t.id}>
                    <td className="font-mono text-sm">{t.terminalId}</td>
                    <td>{t.terminalName}</td>
                    <td>{t.branchName || '-'}</td>
                    <td className="text-sm">{t.connectionType || 'SERIAL'} {t.comPort || ''}</td>
                    <td className="text-sm">{t.lastTransactionAt ? new Date(t.lastTransactionAt).toLocaleString('hu-HU') : '-'}</td>
                    <td>
                      <span className={`badge ${t.isActive ? 'badge-green' : 'badge-gray'}`}>
                        {t.isActive ? 'Aktív' : 'Inaktív'}
                      </span>
                      {testResult && testResult.id === t.id && (
                        <span className={`ml-1 badge ${testResult.success ? 'badge-green' : 'badge-red'}`}>
                          {testResult.message}
                        </span>
                      )}
                    </td>
                    <td>
                      <div className="flex gap-1">
                        <button onClick={() => handleEdit(t)} className="form-button text-xs" title="Szerkesztés">
                          <Edit2 size={12} />
                        </button>
                        <button onClick={() => handleToggleActive(t)} className="form-button text-xs" title={t.isActive ? 'Deaktiválás' : 'Aktiválás'}>
                          {t.isActive ? <PowerOff size={12} /> : <Power size={12} />}
                        </button>
                        <button onClick={() => void handleTestConnection(t.id)} className="form-button text-xs" title="Kapcsolat teszt">
                          <RefreshCw size={12} />
                        </button>
                        <button onClick={() => handleDelete(t.id)} className="form-button text-xs text-red-600" title="Törlés">
                          <Trash2 size={12} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  )
}
