import { useState, useEffect, useCallback } from 'react'
import { X, Plus, Trash2, Stethoscope, CalendarDays, Baby } from 'lucide-react'
import { api } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'

interface OccHealth { id: number; status?: string; deadlineDate?: string; examDate?: string; result?: string; restriction?: string }
interface Vacation { id: number; year: number; broughtForward: number; vacationDays: number; sickLeaveDays: number; takenVacation: number; takenSickLeave: number; sickPayDays: number; unpaidLeaveDays: number }
interface Child { id: number; name: string; birthDate?: string }

interface Props {
  employeeId: number | string
  employeeName: string
  onClose: () => void
}

/**
 * G19 (EXCMD b9-munkavallalo): munkavállaló al-nyilvántartások kezelő modal —
 * üzemorvosi vizsgálat (FR-22), szabadságok (FR-19), gyerekek (FR-20).
 */
export default function EmployeeSubRecordsModal({ employeeId, employeeName, onClose }: Props) {
  const [occHealth, setOccHealth] = useState<OccHealth[]>([])
  const [vacations, setVacations] = useState<Vacation[]>([])
  const [children, setChildren] = useState<Child[]>([])
  const [error, setError] = useState<string | null>(null)

  const [newOcc, setNewOcc] = useState({ status: '', examDate: '', result: '' })
  const [newVac, setNewVac] = useState({ year: new Date().getFullYear(), vacationDays: 0 })
  const [newChild, setNewChild] = useState({ name: '', birthDate: '' })

  const base = `/employees/${employeeId}`

  const load = useCallback(async () => {
    try {
      setError(null)
      const [oh, vac, ch] = await Promise.all([
        api.get<OccHealth[]>(`${base}/occupational-health`),
        api.get<Vacation[]>(`${base}/vacations`),
        api.get<Child[]>(`${base}/children`),
      ])
      setOccHealth(safeArray<OccHealth>(oh.data))
      setVacations(safeArray<Vacation>(vac.data))
      setChildren(safeArray<Child>(ch.data))
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }, [base])

  useEffect(() => { void load() }, [load])

  const addOcc = async () => {
    try {
      await api.post(`${base}/occupational-health`, {
        status: newOcc.status || null,
        examDate: newOcc.examDate || null,
        result: newOcc.result || null,
      })
      setNewOcc({ status: '', examDate: '', result: '' })
      await load()
    } catch (err) { setError(getErrorMessage(err)) }
  }
  const addVac = async () => {
    if (!Number.isInteger(newVac.year) || newVac.year < 1900 || newVac.year > 2200) {
      setError('Érvényes évet adjon meg (1900–2200).')
      return
    }
    try {
      await api.post(`${base}/vacations`, { year: newVac.year, vacationDays: newVac.vacationDays })
      await load()
    } catch (err) { setError(getErrorMessage(err)) }
  }
  const addChild = async () => {
    try {
      await api.post(`${base}/children`, { name: newChild.name, birthDate: newChild.birthDate || null })
      setNewChild({ name: '', birthDate: '' })
      await load()
    } catch (err) { setError(getErrorMessage(err)) }
  }
  const del = async (path: string) => {
    try { await api.delete(`${base}/${path}`); await load() } catch (err) { setError(getErrorMessage(err)) }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-lg bg-white p-4 shadow-xl">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-lg font-bold">Al-nyilvántartások — {employeeName}</h2>
          <button onClick={onClose} className="form-button p-1" title="Bezárás"><X className="h-5 w-5" /></button>
        </div>

        {error && <div className="form-error mb-3 text-sm">{error}</div>}

        {/* Üzemorvosi vizsgálat */}
        <section className="mb-4">
          <h3 className="mb-2 flex items-center gap-1 font-semibold"><Stethoscope className="h-4 w-4" />Üzemorvosi vizsgálat</h3>
          <table className="w-full text-sm">
            <thead className="bg-gray-50"><tr>
              <th className="p-1 text-left">Állapot</th><th className="p-1 text-left">Vizsgálat dátuma</th>
              <th className="p-1 text-left">Eredmény</th><th className="p-1"></th>
            </tr></thead>
            <tbody>
              {occHealth.length === 0 ? (
                <tr><td colSpan={4} className="p-2 text-center text-gray-500">Nincs üzemorvosi rekord.</td></tr>
              ) : occHealth.map(o => (
                <tr key={o.id} className="border-t">
                  <td className="p-1">{o.status ?? '-'}</td><td className="p-1">{o.examDate ?? '-'}</td>
                  <td className="p-1">{o.result ?? '-'}</td>
                  <td className="p-1 text-right"><button onClick={() => del(`occupational-health/${o.id}`)} className="text-red-600"><Trash2 className="h-4 w-4" /></button></td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="mt-1 flex gap-1">
            <input className="form-input flex-1" placeholder="Állapot" value={newOcc.status} onChange={e => setNewOcc({ ...newOcc, status: e.target.value })} />
            <input className="form-input" type="date" value={newOcc.examDate} onChange={e => setNewOcc({ ...newOcc, examDate: e.target.value })} />
            <input className="form-input flex-1" placeholder="Eredmény" value={newOcc.result} onChange={e => setNewOcc({ ...newOcc, result: e.target.value })} />
            <button onClick={addOcc} className="form-button-primary p-2"><Plus className="h-4 w-4" /></button>
          </div>
        </section>

        {/* Szabadságok */}
        <section className="mb-4">
          <h3 className="mb-2 flex items-center gap-1 font-semibold"><CalendarDays className="h-4 w-4" />Szabadságok</h3>
          <table className="w-full text-sm">
            <thead className="bg-gray-50"><tr>
              <th className="p-1 text-left">Év</th><th className="p-1 text-right">Szabadság</th>
              <th className="p-1 text-right">Kivett</th><th className="p-1"></th>
            </tr></thead>
            <tbody>
              {vacations.length === 0 ? (
                <tr><td colSpan={4} className="p-2 text-center text-gray-500">Nincs szabadság-sor.</td></tr>
              ) : vacations.map(v => (
                <tr key={v.id} className="border-t">
                  <td className="p-1">{v.year}</td><td className="p-1 text-right">{v.vacationDays}</td>
                  <td className="p-1 text-right">{v.takenVacation}</td>
                  <td className="p-1 text-right"><button onClick={() => del(`vacations/${v.id}`)} className="text-red-600"><Trash2 className="h-4 w-4" /></button></td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="mt-1 flex gap-1">
            <input className="form-input w-24" type="number" placeholder="Év" value={newVac.year} onChange={e => setNewVac({ ...newVac, year: Number(e.target.value) })} />
            <input className="form-input w-32" type="number" placeholder="Szabadság" value={newVac.vacationDays} onChange={e => setNewVac({ ...newVac, vacationDays: Number(e.target.value) })} />
            <button onClick={addVac} className="form-button-primary p-2"><Plus className="h-4 w-4" /></button>
          </div>
        </section>

        {/* Gyerekek */}
        <section>
          <h3 className="mb-2 flex items-center gap-1 font-semibold"><Baby className="h-4 w-4" />Gyerekek</h3>
          <table className="w-full text-sm">
            <thead className="bg-gray-50"><tr>
              <th className="p-1 text-left">Név</th><th className="p-1 text-left">Születési dátum</th><th className="p-1"></th>
            </tr></thead>
            <tbody>
              {children.length === 0 ? (
                <tr><td colSpan={3} className="p-2 text-center text-gray-500">Nincs gyermek-rekord.</td></tr>
              ) : children.map(c => (
                <tr key={c.id} className="border-t">
                  <td className="p-1">{c.name}</td><td className="p-1">{c.birthDate ?? '-'}</td>
                  <td className="p-1 text-right"><button onClick={() => del(`children/${c.id}`)} className="text-red-600"><Trash2 className="h-4 w-4" /></button></td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="mt-1 flex gap-1">
            <input className="form-input flex-1" placeholder="Gyermek neve" value={newChild.name} onChange={e => setNewChild({ ...newChild, name: e.target.value })} />
            <input className="form-input" type="date" value={newChild.birthDate} onChange={e => setNewChild({ ...newChild, birthDate: e.target.value })} />
            <button onClick={addChild} disabled={!newChild.name.trim()} className="form-button-primary p-2"><Plus className="h-4 w-4" /></button>
          </div>
        </section>
      </div>
    </div>
  )
}
