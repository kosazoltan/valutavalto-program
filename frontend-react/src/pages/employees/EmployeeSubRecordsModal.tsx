import { useState, useEffect, useCallback } from 'react'
import {
  X,
  Plus,
  Trash2,
  Stethoscope,
  CalendarDays,
  Baby,
  Download,
  GraduationCap,
  Coffee,
  KeyRound,
  Clock,
  ShieldCheck,
  LockOpen,
  Copy,
} from 'lucide-react'
import { api } from '../../services/api/index'
import { getBlobErrorMessage, getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useAuthStore } from '../../stores/authStore'
import { downloadBlob } from '../../utils/downloadBlob'
import i18n from '../../i18n'

interface OccHealth {
  id: number
  status?: string
  deadlineDate?: string
  examDate?: string
  result?: string
  restriction?: string
}
interface WorkerAttendance {
  id: string
  workerId?: number
  branchId?: string
  loginAt?: string
  logoutAt?: string | null
  ipAddress?: string | null
}
interface WorkerBreak {
  id: string
  workerId?: number
  branchId?: string
  breakStart?: string
  breakEnd?: string | null
  reason?: string | null
  approvedBy?: string | null
}

/** EXCMD b9-munkavallalo FR-03: Becsüs / Eladói / Valutapénztárosi bizonyítvány (szám + dátum). */
interface Certificates {
  appraiserCertificateNumber?: string
  appraiserCertificateDate?: string
  sellerCertificateNumber?: string
  sellerCertificateDate?: string
  cashierCertificateNumber?: string
  cashierCertificateDate?: string
}
interface EmployeeDetails extends Certificates {
  workerId?: number | null
}
interface WorkerIdentity {
  id: number
  workerCode?: string | null
  fullName?: string | null
  companyCode?: string | null
}
interface WorkerSetupTokenResponse {
  success: boolean
  message?: string
  companyCode?: string
  workerCode?: string
  workerName?: string
  token?: string
  expiresAt?: string
}
interface Vacation {
  id: number
  year: number
  broughtForward: number
  vacationDays: number
  sickLeaveDays: number
  takenVacation: number
  takenSickLeave: number
  sickPayDays: number
  unpaidLeaveDays: number
}
interface Child {
  id: number
  name: string
  birthDate?: string
}

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
  const currentWorker = useAuthStore((state) => state.worker)
  const [occHealth, setOccHealth] = useState<OccHealth[]>([])
  const [vacations, setVacations] = useState<Vacation[]>([])
  const [children, setChildren] = useState<Child[]>([])
  const [attendance, setAttendance] = useState<WorkerAttendance[]>([])
  const [workerRoles, setWorkerRoles] = useState<string[]>([])
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  const [newOcc, setNewOcc] = useState({ status: '', examDate: '', result: '' })
  const [newVac, setNewVac] = useState({ year: new Date().getFullYear(), vacationDays: 0 })
  const [newChild, setNewChild] = useState({ name: '', birthDate: '' })
  // FR-03: bizonyítvány-mezők (a PUT /employees/{id} null-safe részleges frissítésével mentve)
  const [certs, setCerts] = useState<Certificates>({})
  const [certsSaving, setCertsSaving] = useState(false)
  const [breakReason, setBreakReason] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [linkedWorkerId, setLinkedWorkerId] = useState<number | null>(null)
  const [setupTokenResponse, setSetupTokenResponse] = useState<WorkerSetupTokenResponse | null>(
    null,
  )
  const [newRoleCode, setNewRoleCode] = useState('')
  const [workerActionLoading, setWorkerActionLoading] = useState<string | null>(null)

  const base = `/employees/${employeeId}`
  const managementBase = `/worker-management/${employeeId}`

  const load = useCallback(async () => {
    try {
      setError(null)
      const [oh, vac, ch, emp, attendanceResult, rolesResult] = await Promise.all([
        api.get<OccHealth[]>(`${base}/occupational-health`),
        api.get<Vacation[]>(`${base}/vacations`),
        api.get<Child[]>(`${base}/children`),
        api.get<EmployeeDetails>(base),
        api.get<{ content?: WorkerAttendance[] } | WorkerAttendance[]>(
          `${managementBase}/attendance`,
        ),
        api.get<string[]>(`/workers/${employeeId}/roles`),
      ])
      setOccHealth(safeArray<OccHealth>(oh.data))
      setVacations(safeArray<Vacation>(vac.data))
      setChildren(safeArray<Child>(ch.data))
      setAttendance(safeArray<WorkerAttendance>(attendanceResult.data))
      setWorkerRoles(safeArray<string>(rolesResult.data))
      const e = emp.data ?? {}
      setLinkedWorkerId(e.workerId ?? null)
      setCerts({
        appraiserCertificateNumber: e.appraiserCertificateNumber ?? '',
        appraiserCertificateDate: e.appraiserCertificateDate ?? '',
        sellerCertificateNumber: e.sellerCertificateNumber ?? '',
        sellerCertificateDate: e.sellerCertificateDate ?? '',
        cashierCertificateNumber: e.cashierCertificateNumber ?? '',
        cashierCertificateDate: e.cashierCertificateDate ?? '',
      })
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }, [base, employeeId, managementBase])

  const issueWorkerSetupToken = async () => {
    const companyCode = currentWorker?.companyCode?.trim()
    const workerId = linkedWorkerId ?? Number(employeeId)
    if (!companyCode) {
      setError('A bejelentkezett cégkód nem érhető el a setup-token kiállításához.')
      return
    }
    if (!Number.isFinite(workerId)) {
      setError('A dolgozó worker azonosítója nem határozható meg a setup-token kiállításához.')
      return
    }
    try {
      setWorkerActionLoading('setup-token')
      setError(null)
      setMessage(null)
      setSetupTokenResponse(null)
      const workerResponse = await api.get<WorkerIdentity>(`/workers/${workerId}`)
      const workerCode = workerResponse.data?.workerCode?.trim()
      if (!workerCode) {
        throw new Error('A dolgozó workerCode mezője hiányzik.')
      }
      const response = await api.post<WorkerSetupTokenResponse>('/auth/worker-setup-token', {
        companyCode,
        workerCode,
      })
      setSetupTokenResponse(response.data)
      setMessage('Setup-token kiállítva. A token csak most látható.')
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setWorkerActionLoading(null)
    }
  }

  const runWorkerAction = async (action: 'break-start' | 'break-end' | 'reset-password') => {
    try {
      setWorkerActionLoading(action)
      setError(null)
      setMessage(null)
      if (action === 'break-start') {
        await api.post<WorkerBreak>(`${managementBase}/break-start`, {
          reason: breakReason.trim() || undefined,
        })
        setBreakReason('')
        setMessage('Szünet elindítva.')
      } else if (action === 'break-end') {
        await api.post<WorkerBreak>(`${managementBase}/break-end`)
        setMessage('Szünet lezárva.')
      } else {
        await api.post(`${managementBase}/reset-password`, { newPassword })
        setNewPassword('')
        setMessage('Jelszó módosítva.')
      }
      await load()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setWorkerActionLoading(null)
    }
  }

  const unlockWorkerLogin = async () => {
    try {
      setWorkerActionLoading('unlock-login')
      setError(null)
      setMessage(null)
      const response = await api.post<{ remainingSeconds?: number }>(
        `/workers/${employeeId}/unlock-login`,
      )
      const remaining = response.data?.remainingSeconds ?? 0
      setMessage(
        remaining > 0
          ? `Belépési zárolás feloldva. Hátralévő idő volt: ${remaining} mp.`
          : 'Belépési zárolás feloldva.',
      )
      await load()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setWorkerActionLoading(null)
    }
  }

  const assignWorkerRole = async () => {
    const roleCode = newRoleCode.trim()
    if (!roleCode) return
    try {
      setWorkerActionLoading('assign-role')
      setError(null)
      setMessage(null)
      await api.post(`/workers/${employeeId}/roles/${encodeURIComponent(roleCode)}`)
      setNewRoleCode('')
      setMessage('Szerepkör hozzáadva.')
      await load()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setWorkerActionLoading(null)
    }
  }

  const removeWorkerRole = async (roleCode: string) => {
    try {
      setWorkerActionLoading(`remove-role-${roleCode}`)
      setError(null)
      setMessage(null)
      await api.delete(`/workers/${employeeId}/roles/${encodeURIComponent(roleCode)}`)
      setMessage('Szerepkör eltávolítva.')
      await load()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setWorkerActionLoading(null)
    }
  }

  const saveCerts = async () => {
    try {
      setCertsSaving(true)
      setError(null)
      // Review #1088 (törölhetőség): üres string = TÖRLÉS a backendnek; a null "nincs
      // változás"-t jelentene, amivel a kiürített mező nem törlődne.
      await api.put(base, {
        appraiserCertificateNumber: certs.appraiserCertificateNumber ?? '',
        appraiserCertificateDate: certs.appraiserCertificateDate ?? '',
        sellerCertificateNumber: certs.sellerCertificateNumber ?? '',
        sellerCertificateDate: certs.sellerCertificateDate ?? '',
        cashierCertificateNumber: certs.cashierCertificateNumber ?? '',
        cashierCertificateDate: certs.cashierCertificateDate ?? '',
      })
      await load()
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setCertsSaving(false)
    }
  }

  useEffect(() => {
    void load()
  }, [load])

  const addOcc = async () => {
    try {
      await api.post(`${base}/occupational-health`, {
        status: newOcc.status || null,
        examDate: newOcc.examDate || null,
        result: newOcc.result || null,
      })
      setNewOcc({ status: '', examDate: '', result: '' })
      await load()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }
  const addVac = async () => {
    if (!Number.isInteger(newVac.year) || newVac.year < 1900 || newVac.year > 2200) {
      setError('Érvényes évet adjon meg (1900–2200).')
      return
    }
    try {
      await api.post(`${base}/vacations`, { year: newVac.year, vacationDays: newVac.vacationDays })
      await load()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }
  const addChild = async () => {
    try {
      await api.post(`${base}/children`, {
        name: newChild.name,
        birthDate: newChild.birthDate || null,
      })
      setNewChild({ name: '', birthDate: '' })
      await load()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }
  const del = async (path: string) => {
    try {
      await api.delete(`${base}/${path}`)
      await load()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const downloadOccupationalHealthCsv = async () => {
    try {
      setError(null)
      const response = await api.get<Blob>('/employees/occupational-health/export', {
        responseType: 'blob',
      })
      downloadBlob(response.data, 'uzemorvosi_vizsgalatok.csv', 'text/csv;charset=utf-8;')
    } catch (err) {
      setError(await getBlobErrorMessage(err))
    }
  }

  const downloadVacationsCsv = async () => {
    try {
      setError(null)
      const response = await api.get<Blob>('/employees/vacations/export', { responseType: 'blob' })
      downloadBlob(response.data, 'szabadsagok.csv', 'text/csv;charset=utf-8;')
    } catch (err) {
      setError(await getBlobErrorMessage(err))
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="max-h-[90vh] w-full max-w-3xl overflow-y-auto rounded-lg bg-white p-4 shadow-xl">
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-lg font-bold">
            {i18n.t('literals.al-nyilvantartasok')}
            {employeeName}
          </h2>
          <button onClick={onClose} className="form-button p-1" title="Bezárás">
            <X className="h-5 w-5" />
          </button>
        </div>

        {error && <div className="form-error mb-3 text-sm">{error}</div>}
        {message && (
          <div className="mb-3 rounded border border-green-200 bg-green-50 px-3 py-2 text-sm text-green-800">
            {message}
          </div>
        )}

        <section className="mb-4 rounded border border-blue-100 bg-blue-50 p-3">
          <h3 className="mb-2 flex items-center gap-2 font-semibold text-blue-950">
            <Clock className="h-4 w-4" />
            {i18n.t('literals.vezetoi-dolgozokezeles')}
          </h3>
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <div className="rounded border border-blue-100 bg-white p-2">
              <div className="mb-2 flex items-center gap-1 text-sm font-semibold text-gray-900">
                <Clock className="h-4 w-4" />
                {i18n.t('literals.jelenlet-naplo')}
              </div>
              {attendance.length === 0 ? (
                <p className="text-sm text-gray-500">{i18n.t('literals.nincs-jelenleti-rekord')}</p>
              ) : (
                <div className="space-y-2">
                  {attendance.slice(0, 3).map((row) => (
                    <div key={row.id} className="rounded bg-gray-50 px-2 py-1 text-xs">
                      <div className="font-semibold">{formatDateTime(row.loginAt)}</div>
                      <div className="text-gray-500">
                        {row.logoutAt
                          ? `Kilépés: ${formatDateTime(row.logoutAt)}`
                          : 'Aktív vagy nyitott napló'}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
            <div className="rounded border border-blue-100 bg-white p-2">
              <div className="mb-2 flex items-center gap-1 text-sm font-semibold text-gray-900">
                <Coffee className="h-4 w-4" />
                {i18n.t('literals.szunet-kezeles')}
              </div>
              <input
                className="form-input mb-2 w-full"
                value={breakReason}
                onChange={(event) => setBreakReason(event.target.value)}
                placeholder="Szünet oka"
                data-testid="worker-break-reason"
              />
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => void runWorkerAction('break-start')}
                  disabled={workerActionLoading !== null}
                  className="form-button-primary justify-center text-xs"
                  data-testid="worker-break-start"
                >
                  {i18n.t('literals.inditas')}
                </button>
                <button
                  type="button"
                  onClick={() => void runWorkerAction('break-end')}
                  disabled={workerActionLoading !== null}
                  className="form-button justify-center text-xs"
                  data-testid="worker-break-end"
                >
                  {i18n.t('literals.lezaras')}
                </button>
              </div>
            </div>
            <div className="rounded border border-blue-100 bg-white p-2">
              <div className="mb-2 flex items-center gap-1 text-sm font-semibold text-gray-900">
                <KeyRound className="h-4 w-4" />
                {i18n.t('literals.jelszo-reset')}
              </div>
              <input
                className="form-input mb-2 w-full"
                type="password"
                value={newPassword}
                onChange={(event) => setNewPassword(event.target.value)}
                placeholder="Új jelszó"
                data-testid="worker-new-password"
              />
              <p className="mb-2 text-xs text-gray-500">
                {i18n.t('literals.8-128-karakter-legalabb-egy-nagybetu-es')}
              </p>
              <button
                type="button"
                onClick={() => void runWorkerAction('reset-password')}
                disabled={workerActionLoading !== null || !isValidManagementPassword(newPassword)}
                className="form-button-primary w-full justify-center text-xs"
                data-testid="worker-reset-password"
              >
                {i18n.t('literals.jelszo-modositasa')}
              </button>
              <button
                type="button"
                onClick={() => void issueWorkerSetupToken()}
                disabled={workerActionLoading !== null}
                className="form-button mt-2 w-full justify-center gap-1 text-xs"
                data-testid="worker-setup-token-issue"
              >
                <Copy className="h-4 w-4" />
                {i18n.t('literals.setup-token-kiallitasa')}
              </button>
              {setupTokenResponse?.token && (
                <div
                  className="mt-2 rounded border border-amber-200 bg-amber-50 p-2 text-xs text-amber-950"
                  data-testid="worker-setup-token-result"
                >
                  <div className="font-semibold">
                    {i18n.t('literals.egyszer-lathato-setup-token')}
                  </div>
                  <div className="mt-1 break-all font-mono">{setupTokenResponse.token}</div>
                  <div className="mt-1 text-amber-800">
                    {setupTokenResponse.workerCode ?? ''}
                    {setupTokenResponse.expiresAt
                      ? ` · Lejár: ${setupTokenResponse.expiresAt}`
                      : ''}
                  </div>
                </div>
              )}
            </div>
            <div className="rounded border border-blue-100 bg-white p-2">
              <div className="mb-2 flex items-center gap-1 text-sm font-semibold text-gray-900">
                <ShieldCheck className="h-4 w-4" />
                {i18n.t('literals.operativ-szerepkorok')}
              </div>
              {workerRoles.length === 0 ? (
                <p className="mb-2 text-sm text-gray-500">
                  {i18n.t('literals.nincs-szerepkor-hozzarendelve')}
                </p>
              ) : (
                <div className="mb-2 flex flex-wrap gap-1" data-testid="worker-role-list">
                  {workerRoles.map((roleCode) => (
                    <span
                      key={roleCode}
                      className="inline-flex items-center gap-1 rounded border border-blue-200 bg-blue-50 px-2 py-1 text-xs font-medium text-blue-900"
                    >
                      {roleCode}
                      <button
                        type="button"
                        onClick={() => void removeWorkerRole(roleCode)}
                        disabled={workerActionLoading !== null}
                        className="text-blue-700 hover:text-red-700"
                        title={`${roleCode} eltávolítása`}
                        data-testid={`worker-role-remove-${roleCode}`}
                      >
                        <X className="h-3 w-3" />
                      </button>
                    </span>
                  ))}
                </div>
              )}
              <div className="flex gap-2">
                <input
                  className="form-input min-w-0 flex-1"
                  value={newRoleCode}
                  onChange={(event) => setNewRoleCode(event.target.value)}
                  placeholder="roleCode"
                  data-testid="worker-role-code"
                />
                <button
                  type="button"
                  onClick={() => void assignWorkerRole()}
                  disabled={workerActionLoading !== null || !newRoleCode.trim()}
                  className="form-button-primary px-2"
                  title="Szerepkör hozzáadása"
                  data-testid="worker-role-add"
                >
                  <Plus className="h-4 w-4" />
                </button>
              </div>
              <button
                type="button"
                onClick={() => void unlockWorkerLogin()}
                disabled={workerActionLoading !== null}
                className="form-button mt-2 w-full justify-center gap-1 text-xs"
                data-testid="worker-unlock-login"
              >
                <LockOpen className="h-4 w-4" />
                {i18n.t('literals.login-zarolas-feloldasa')}
              </button>
            </div>
          </div>
        </section>

        {/* EXCMD b9-munkavallalo FR-03: szakmai bizonyítványok (Becsüs / Eladói / Valutapénztárosi) */}
        <div className="mb-4">
          <div className="mb-2 flex items-center justify-between">
            <h3 className="flex items-center gap-2 font-semibold">
              <GraduationCap className="h-4 w-4" />
              {i18n.t('literals.szakmai-bizonyitvanyok')}
            </h3>
            <button
              onClick={() => void saveCerts()}
              disabled={certsSaving}
              className="form-button-primary text-xs"
            >
              {certsSaving ? 'Mentés...' : 'Bizonyítványok mentése'}
            </button>
          </div>
          <div className="grid grid-cols-2 gap-2 text-sm">
            {(
              [
                [
                  'Becsüs bizonyítvány száma',
                  'appraiserCertificateNumber',
                  'Becsüs bizonyítvány dátuma',
                  'appraiserCertificateDate',
                ],
                [
                  'Eladói bizonyítvány száma',
                  'sellerCertificateNumber',
                  'Eladói bizonyítvány dátuma',
                  'sellerCertificateDate',
                ],
                [
                  'Valutapénztárosi bizonyítvány száma',
                  'cashierCertificateNumber',
                  'Valutapénztárosi bizonyítvány dátuma',
                  'cashierCertificateDate',
                ],
              ] as Array<[string, keyof Certificates, string, keyof Certificates]>
            ).map(([numLabel, numKey, dateLabel, dateKey]) => (
              <div key={numKey} className="contents">
                <label className="block">
                  <span className="mb-1 block text-gray-600">{numLabel}</span>
                  <input
                    type="text"
                    maxLength={100}
                    value={certs[numKey] ?? ''}
                    onChange={(e) => setCerts((c) => ({ ...c, [numKey]: e.target.value }))}
                    className="form-input w-full"
                  />
                </label>
                <label className="block">
                  <span className="mb-1 block text-gray-600">{dateLabel}</span>
                  <input
                    type="date"
                    value={certs[dateKey] ?? ''}
                    onChange={(e) => setCerts((c) => ({ ...c, [dateKey]: e.target.value }))}
                    className="form-input w-full"
                  />
                </label>
              </div>
            ))}
          </div>
        </div>

        {/* Üzemorvosi vizsgálat */}
        <section className="mb-4">
          <h3 className="mb-2 flex items-center justify-between font-semibold">
            <span className="flex items-center gap-1">
              <Stethoscope className="h-4 w-4" />
              {i18n.t('literals.uzemorvosi-vizsgalat')}
            </span>
            <button
              onClick={() => void downloadOccupationalHealthCsv()}
              className="form-button flex items-center gap-1 text-xs"
              title="CSV letöltés — cég összes dolgozója"
            >
              <Download className="h-3 w-3" />
              {i18n.t('literals.csv-export')}
            </button>
          </h3>
          <div className="space-y-2 md:hidden">
            {occHealth.length === 0 ? (
              <div className="rounded border border-gray-200 bg-white p-3 text-center text-sm text-gray-500">
                {i18n.t('literals.nincs-uzemorvosi-rekord')}
              </div>
            ) : (
              occHealth.map((o) => (
                <article
                  key={o.id}
                  className="rounded border border-gray-200 bg-white p-3 text-sm"
                  data-testid="occ-health-mobile-card"
                >
                  <div className="mb-2 flex items-start justify-between gap-2">
                    <div>
                      <div className="font-semibold text-gray-900">{o.status ?? '-'}</div>
                      <div className="text-xs text-gray-500">
                        {i18n.t('literals.vizsgalat')}
                        {o.examDate ?? '-'}
                      </div>
                    </div>
                    <button
                      onClick={() => del(`occupational-health/${o.id}`)}
                      className="text-red-600"
                      title="Törlés"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                  <div className="rounded border border-gray-100 bg-gray-50 px-2 py-1">
                    <div className="text-[10px] uppercase text-gray-500">
                      {i18n.t('literals.eredmeny')}
                    </div>
                    <div>{o.result ?? '-'}</div>
                  </div>
                </article>
              ))
            )}
          </div>
          <table className="hidden w-full text-sm md:table">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-1 text-left">{i18n.t('literals.allapot')}</th>
                <th className="p-1 text-left">{i18n.t('literals.vizsgalat-datuma')}</th>
                <th className="p-1 text-left">{i18n.t('literals.eredmeny')}</th>
                <th className="p-1"></th>
              </tr>
            </thead>
            <tbody>
              {occHealth.length === 0 ? (
                <tr>
                  <td colSpan={4} className="p-2 text-center text-gray-500">
                    {i18n.t('literals.nincs-uzemorvosi-rekord')}
                  </td>
                </tr>
              ) : (
                occHealth.map((o) => (
                  <tr key={o.id} className="border-t">
                    <td className="p-1">{o.status ?? '-'}</td>
                    <td className="p-1">{o.examDate ?? '-'}</td>
                    <td className="p-1">{o.result ?? '-'}</td>
                    <td className="p-1 text-right">
                      <button
                        onClick={() => del(`occupational-health/${o.id}`)}
                        className="text-red-600"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
          <div className="mt-2 flex flex-col gap-1 sm:flex-row">
            <input
              className="form-input flex-1"
              placeholder="Állapot"
              value={newOcc.status}
              onChange={(e) => setNewOcc({ ...newOcc, status: e.target.value })}
            />
            <input
              className="form-input"
              type="date"
              value={newOcc.examDate}
              onChange={(e) => setNewOcc({ ...newOcc, examDate: e.target.value })}
            />
            <input
              className="form-input flex-1"
              placeholder="Eredmény"
              value={newOcc.result}
              onChange={(e) => setNewOcc({ ...newOcc, result: e.target.value })}
            />
            <button onClick={addOcc} className="form-button-primary p-2">
              <Plus className="h-4 w-4" />
            </button>
          </div>
        </section>

        {/* Szabadságok */}
        <section className="mb-4">
          <h3 className="mb-2 flex items-center justify-between font-semibold">
            <span className="flex items-center gap-1">
              <CalendarDays className="h-4 w-4" />
              {i18n.t('literals.szabadsagok')}
            </span>
            <button
              onClick={() => void downloadVacationsCsv()}
              className="form-button flex items-center gap-1 text-xs"
              title="CSV letöltés — cég összes dolgozója"
            >
              <Download className="h-3 w-3" />
              {i18n.t('literals.csv-export')}
            </button>
          </h3>
          <div className="space-y-2 md:hidden">
            {vacations.length === 0 ? (
              <div className="rounded border border-gray-200 bg-white p-3 text-center text-sm text-gray-500">
                {i18n.t('literals.nincs-szabadsag-sor')}
              </div>
            ) : (
              vacations.map((v) => (
                <article
                  key={v.id}
                  className="rounded border border-gray-200 bg-white p-3 text-sm"
                  data-testid="vacation-mobile-card"
                >
                  <div className="mb-2 flex items-start justify-between gap-2">
                    <div className="font-semibold text-gray-900">{v.year}</div>
                    <button
                      onClick={() => del(`vacations/${v.id}`)}
                      className="text-red-600"
                      title="Törlés"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                  <dl className="grid grid-cols-2 gap-2">
                    <div className="rounded border border-gray-100 bg-gray-50 px-2 py-1">
                      <dt className="text-[10px] uppercase text-gray-500">
                        {i18n.t('literals.szabadsag')}
                      </dt>
                      <dd className="font-mono">{v.vacationDays}</dd>
                    </div>
                    <div className="rounded border border-gray-100 bg-gray-50 px-2 py-1">
                      <dt className="text-[10px] uppercase text-gray-500">
                        {i18n.t('literals.kivett')}
                      </dt>
                      <dd className="font-mono">{v.takenVacation}</dd>
                    </div>
                  </dl>
                </article>
              ))
            )}
          </div>
          <table className="hidden w-full text-sm md:table">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-1 text-left">{i18n.t('literals.ev')}</th>
                <th className="p-1 text-right">{i18n.t('literals.szabadsag')}</th>
                <th className="p-1 text-right">{i18n.t('literals.kivett')}</th>
                <th className="p-1"></th>
              </tr>
            </thead>
            <tbody>
              {vacations.length === 0 ? (
                <tr>
                  <td colSpan={4} className="p-2 text-center text-gray-500">
                    {i18n.t('literals.nincs-szabadsag-sor')}
                  </td>
                </tr>
              ) : (
                vacations.map((v) => (
                  <tr key={v.id} className="border-t">
                    <td className="p-1">{v.year}</td>
                    <td className="p-1 text-right">{v.vacationDays}</td>
                    <td className="p-1 text-right">{v.takenVacation}</td>
                    <td className="p-1 text-right">
                      <button onClick={() => del(`vacations/${v.id}`)} className="text-red-600">
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
          <div className="mt-2 flex flex-col gap-1 sm:flex-row">
            <input
              className="form-input w-24"
              type="number"
              placeholder="Év"
              value={newVac.year}
              onChange={(e) => setNewVac({ ...newVac, year: Number(e.target.value) })}
            />
            <input
              className="form-input w-32"
              type="number"
              placeholder="Szabadság"
              value={newVac.vacationDays}
              onChange={(e) => setNewVac({ ...newVac, vacationDays: Number(e.target.value) })}
            />
            <button onClick={addVac} className="form-button-primary p-2">
              <Plus className="h-4 w-4" />
            </button>
          </div>
        </section>

        {/* Gyerekek */}
        <section>
          <h3 className="mb-2 flex items-center gap-1 font-semibold">
            <Baby className="h-4 w-4" />
            {i18n.t('literals.gyerekek')}
          </h3>
          <div className="space-y-2 md:hidden">
            {children.length === 0 ? (
              <div className="rounded border border-gray-200 bg-white p-3 text-center text-sm text-gray-500">
                {i18n.t('literals.nincs-gyermek-rekord')}
              </div>
            ) : (
              children.map((c) => (
                <article
                  key={c.id}
                  className="rounded border border-gray-200 bg-white p-3 text-sm"
                  data-testid="child-mobile-card"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <div className="font-semibold text-gray-900">{c.name}</div>
                      <div className="text-xs text-gray-500">
                        {i18n.t('literals.szuletesi-datum-2')}
                        {c.birthDate ?? '-'}
                      </div>
                    </div>
                    <button
                      onClick={() => del(`children/${c.id}`)}
                      className="text-red-600"
                      title="Törlés"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </article>
              ))
            )}
          </div>
          <table className="hidden w-full text-sm md:table">
            <thead className="bg-gray-50">
              <tr>
                <th className="p-1 text-left">{i18n.t('literals.nev')}</th>
                <th className="p-1 text-left">{i18n.t('literals.szuletesi-datum')}</th>
                <th className="p-1"></th>
              </tr>
            </thead>
            <tbody>
              {children.length === 0 ? (
                <tr>
                  <td colSpan={3} className="p-2 text-center text-gray-500">
                    {i18n.t('literals.nincs-gyermek-rekord')}
                  </td>
                </tr>
              ) : (
                children.map((c) => (
                  <tr key={c.id} className="border-t">
                    <td className="p-1">{c.name}</td>
                    <td className="p-1">{c.birthDate ?? '-'}</td>
                    <td className="p-1 text-right">
                      <button onClick={() => del(`children/${c.id}`)} className="text-red-600">
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
          <div className="mt-2 flex flex-col gap-1 sm:flex-row">
            <input
              className="form-input flex-1"
              placeholder="Gyermek neve"
              value={newChild.name}
              onChange={(e) => setNewChild({ ...newChild, name: e.target.value })}
            />
            <input
              className="form-input"
              type="date"
              value={newChild.birthDate}
              onChange={(e) => setNewChild({ ...newChild, birthDate: e.target.value })}
            />
            <button
              onClick={addChild}
              disabled={!newChild.name.trim()}
              className="form-button-primary p-2"
            >
              <Plus className="h-4 w-4" />
            </button>
          </div>
        </section>
      </div>
    </div>
  )
}

function formatDateTime(value?: string | null): string {
  if (!value) return '-'
  return value.replace('T', ' ').slice(0, 16)
}

function isValidManagementPassword(value: string): boolean {
  return value.length >= 8 && value.length <= 128 && /[A-Z]/.test(value) && /[0-9]/.test(value)
}
