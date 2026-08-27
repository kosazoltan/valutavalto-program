import { useState, useEffect, useCallback } from 'react'
import {
  Download,
  Shield,
  CheckCircle,
  XCircle,
  Clock,
  Eye,
  AlertTriangle,
  ShieldCheck,
  FileText,
} from 'lucide-react'
import {
  cameraExportApi,
  CameraExportRequest,
  ChainOfCustodyRecord,
  branchApi,
  BranchInfo,
} from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '../../utils/safeArray'
import { useTranslation } from 'react-i18next'
import { useTextReasonModal } from '../../components/TextReasonModal'
import i18n from '../../i18n'

const STATUS_MAP: Record<string, { label: string; color: string; icon: typeof CheckCircle }> = {
  REQUESTED: { label: 'Jóváhagyásra vár', color: 'bg-yellow-100 text-yellow-700', icon: Clock },
  AWAITING_SECOND_APPROVAL: {
    label: 'Második jóváhagyásra vár',
    color: 'bg-orange-100 text-orange-700',
    icon: Clock,
  },
  APPROVED: { label: 'Jóváhagyva', color: 'bg-blue-100 text-blue-700', icon: CheckCircle },
  REJECTED: { label: 'Elutasítva', color: 'bg-red-100 text-red-700', icon: XCircle },
  EXPORTING: {
    label: 'Export folyamatban',
    color: 'bg-purple-100 text-purple-700',
    icon: Download,
  },
  COMPLETED: { label: 'Kész', color: 'bg-green-100 text-green-700', icon: CheckCircle },
  FAILED: { label: 'Sikertelen', color: 'bg-red-100 text-red-700', icon: XCircle },
}

function fmtDt(s?: string) {
  return s ? new Date(s).toLocaleString('hu-HU') : '—'
}
function fmtSize(b?: number) {
  return b != null ? (b / 1024 / 1024).toFixed(1) + ' MB' : '—'
}
function isAwaitingSecondApproval(request: CameraExportRequest) {
  return request.status === 'AWAITING_SECOND_APPROVAL'
}

export default function CameraExportPage() {
  const { t } = useTranslation()
  const [requests, setRequests] = useState<CameraExportRequest[]>([])
  const [pending, setPending] = useState<CameraExportRequest[]>([])
  const [selected, setSelected] = useState<CameraExportRequest | null>(null)
  const [custody, setCustody] = useState<ChainOfCustodyRecord[]>([])
  const [branches, setBranches] = useState<BranchInfo[]>([])
  const [loading, setLoading] = useState(false)
  const [detailLoadingId, setDetailLoadingId] = useState<string | null>(null)
  const [error, setError] = useState('')
  const [showNewForm, setShowNewForm] = useState(false)
  const [chainResult, setChainResult] = useState<{
    chainIntact: boolean
    verifiedAt: string
  } | null>(null)
  const { modal: reasonModal, requestReason } = useTextReasonModal()

  // New request form
  const [form, setForm] = useState({
    branchId: '',
    cameraId: '',
    from: '',
    to: '',
    reason: '',
    referenceNumber: '',
  })

  useEffect(() => {
    branchApi
      .listActive()
      .then((r) => setBranches(r))
      .catch(() => {})
  }, [])

  const loadPending = useCallback(async () => {
    try {
      const res = await cameraExportApi.getPending()
      setPending(safeArray<CameraExportRequest>(res?.data))
    } catch {
      /* */
    }
  }, [])

  const loadByBranch = useCallback(async (branchId: string) => {
    if (!branchId) return
    setLoading(true)
    try {
      const res = await cameraExportApi.getByBranch(branchId)
      setRequests(safeArray<CameraExportRequest>(res?.data))
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadPending()
  }, [loadPending])

  const loadCustody = async (id: string) => {
    try {
      const res = await cameraExportApi.getCustody(id)
      setCustody(safeArray<ChainOfCustodyRecord>(res?.data))
    } catch {
      setCustody([])
    }
  }

  const handleSelectRequest = async (r: CameraExportRequest) => {
    setSelected(r)
    setChainResult(null)
    setDetailLoadingId(r.id)
    try {
      const res = await cameraExportApi.getById(r.id)
      setSelected(res.data)
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setDetailLoadingId(null)
    }
    await loadCustody(r.id)
  }

  const handleCreate = async () => {
    setError('')
    try {
      const res = await cameraExportApi.createRequest(form)
      setSelected(res.data)
      setShowNewForm(false)
      loadPending()
      if (form.branchId) loadByBranch(form.branchId)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handleApprove = async (id: string) => {
    try {
      const request = pending.find((item) => item.id === id) ?? selected
      const res =
        request && isAwaitingSecondApproval(request)
          ? await cameraExportApi.approveSecond(id)
          : await cameraExportApi.approve(id)
      setSelected(res.data)
      loadPending()
      loadCustody(id)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handleReject = async (id: string) => {
    const reason = await requestReason({ title: 'Elutasítás indoka' })
    if (!reason) return
    try {
      const res = await cameraExportApi.reject(id, reason)
      setSelected(res.data)
      loadPending()
      loadCustody(id)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handleExecute = async (id: string) => {
    try {
      const res = await cameraExportApi.execute(id)
      setSelected(res.data)
      loadCustody(id)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const handleVerifyChain = async () => {
    if (!selected) return
    try {
      const res = await cameraExportApi.verifyChain(selected.branchId, selected.cameraId || '')
      setChainResult(res.data)
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const StatusBadge = ({ status }: { status: string }) => {
    const s = STATUS_MAP[status] ?? STATUS_MAP.REQUESTED!
    const Icon = s!.icon
    return (
      <span
        className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${s!.color}`}
      >
        <Icon size={12} />
        {s!.label}
      </span>
    )
  }

  return (
    <div className="space-y-3">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Shield />
          {t('camera.kameraExportChainOfCustody')}
        </h1>
        <button
          onClick={() => setShowNewForm(!showNewForm)}
          className="btn-primary text-sm flex items-center gap-1"
        >
          <Download size={14} />
          {t('camera.ujExportKerelem')}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 rounded p-2 text-red-700 text-sm flex items-center gap-2">
          <AlertTriangle size={16} />
          {error}
        </div>
      )}

      {/* New request form */}
      {showNewForm && (
        <div className="p-3 border rounded bg-gray-50 space-y-2">
          <h3 className="font-medium text-sm">{t('camera.ujExportKerelem')}</h3>
          <div className="grid grid-cols-3 gap-2">
            <div>
              <label className="text-xs text-gray-500">{t('camera.iroda')}</label>
              <select
                value={form.branchId}
                onChange={(e) => {
                  setForm({ ...form, branchId: e.target.value })
                  loadByBranch(e.target.value)
                }}
                className="input-field text-sm w-full"
              >
                <option value="">{i18n.t('literals.valasszon')}</option>
                {safeArray<BranchInfo>(branches).map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.code}
                    {i18n.t('literals.lit-18')}
                    {b.name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="text-xs text-gray-500">{t('camera.kameraId')}</label>
              <input
                value={form.cameraId}
                onChange={(e) => setForm({ ...form, cameraId: e.target.value })}
                className="input-field text-sm w-full"
                placeholder="pl. CAM-01"
              />
            </div>
            <div>
              <label className="text-xs text-gray-500">{t('cashier.receiptNumber')}</label>
              <input
                value={form.referenceNumber}
                onChange={(e) => setForm({ ...form, referenceNumber: e.target.value })}
                className="input-field text-sm w-full"
              />
            </div>
          </div>
          <div className="grid grid-cols-3 gap-2">
            <div>
              <label className="text-xs text-gray-500">{t('camera.idoszakTol')}</label>
              <input
                type="datetime-local"
                value={form.from}
                onChange={(e) => setForm({ ...form, from: e.target.value })}
                className="input-field text-sm w-full"
              />
            </div>
            <div>
              <label className="text-xs text-gray-500">{t('camera.idoszakIg')}</label>
              <input
                type="datetime-local"
                value={form.to}
                onChange={(e) => setForm({ ...form, to: e.target.value })}
                className="input-field text-sm w-full"
              />
            </div>
            <div>
              <label className="text-xs text-gray-500">{t('camera.indoklas')}</label>
              <input
                value={form.reason}
                onChange={(e) => setForm({ ...form, reason: e.target.value })}
                className="input-field text-sm w-full"
                placeholder="pl. Rendőrségi megkeresés"
              />
            </div>
          </div>
          <div className="flex gap-2">
            <button onClick={handleCreate} className="btn-primary text-xs">
              {t('camera.kerelemLetrehozasa')}
            </button>
            <button onClick={() => setShowNewForm(false)} className="btn-secondary text-xs">
              {t('common.cancel')}
            </button>
          </div>
        </div>
      )}

      {/* Pending approvals */}
      {pending.length > 0 && (
        <div className="p-3 border border-yellow-300 bg-yellow-50 rounded space-y-2">
          <h3 className="font-medium text-sm flex items-center gap-1">
            <Clock size={14} />
            {t('camera.jovahagyasraVaroKerelmek')}
            {pending.length}
            {i18n.t('literals.lit-2')}
          </h3>
          {pending.map((r) => (
            <div
              key={r.id}
              className="flex justify-between items-center p-2 bg-white rounded border text-sm"
            >
              <div>
                <span className="font-medium">
                  {fmtDt(r.periodFrom)}
                  {i18n.t('literals.lit-18')}
                  {fmtDt(r.periodTo)}
                </span>
                <span className="ml-2 text-gray-500 text-xs">
                  {t('camera.kerte')}
                  {r.requestedBy}
                </span>
                <span className="ml-2 text-gray-500 text-xs">
                  {t('camera.indok')}
                  {r.reason}
                </span>
              </div>
              <div className="flex gap-1">
                <button
                  onClick={() => handleApprove(r.id)}
                  className="btn-primary text-xs px-2 py-1"
                >
                  {isAwaitingSecondApproval(r) ? 'Második jóváhagyás' : t('common.approve')}
                </button>
                <button
                  onClick={() => handleReject(r.id)}
                  className="btn-secondary text-xs px-2 py-1"
                >
                  {t('common.reject')}
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="grid grid-cols-3 gap-3">
        {/* Request list */}
        <div className="col-span-2 space-y-1">
          {loading && (
            <div className="text-center py-4 text-gray-400">{i18n.t('literals.betoltes')}</div>
          )}
          {!loading && requests.length === 0 && (
            <div className="text-gray-400 text-sm text-center py-4">
              {t('camera.valasszonIrodatAzExportKerelmek')}
            </div>
          )}
          {requests.map((r) => (
            <div
              key={r.id}
              role="button"
              tabIndex={0}
              data-testid={`camera-export-request-${r.id}`}
              onClick={() => void handleSelectRequest(r)}
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault()
                  void handleSelectRequest(r)
                }
              }}
              className={`p-3 rounded border cursor-pointer hover:bg-gray-50 transition ${selected?.id === r.id ? 'border-blue-400 bg-blue-50' : 'border-gray-200'}`}
            >
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-2">
                  <StatusBadge status={r.status} />
                  <span className="text-sm">
                    {fmtDt(r.periodFrom)}
                    {i18n.t('literals.lit-18')}
                    {fmtDt(r.periodTo)}
                  </span>
                </div>
                <span className="text-xs text-gray-500">{fmtDt(r.createdAt)}</span>
              </div>
              <div className="text-xs text-gray-500 mt-1">
                {t('camera.kerte')}
                {r.requestedBy} {t('camera.indok')} {r.reason}
                {r.referenceNumber && (
                  <>
                    {' '}
                    {t('camera.ref')} {r.referenceNumber}
                  </>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Detail + Custody */}
        <div className="space-y-2">
          {selected ? (
            <>
              <div className="p-3 border rounded space-y-2">
                <h3 className="font-medium text-sm flex items-center gap-1">
                  <FileText size={14} />
                  {t('camera.kerelemReszletek')}
                </h3>
                {detailLoadingId === selected.id && (
                  <div className="text-xs text-blue-600">{t('common.loading')}</div>
                )}
                <div className="text-xs space-y-1">
                  <div>
                    <StatusBadge status={selected.status} />
                  </div>
                  <div>
                    {t('camera.idoszak')}
                    {fmtDt(selected.periodFrom)}
                    {i18n.t('literals.lit-18')}
                    {fmtDt(selected.periodTo)}
                  </div>
                  <div>
                    {t('camera.kerte')}
                    {selected.requestedBy}
                  </div>
                  <div>
                    {t('camera.indok')}
                    {selected.reason}
                  </div>
                  {selected.approvedBy && (
                    <div>
                      {t('camera.jovahagyta')} {selected.approvedBy}
                      {i18n.t('literals.lit')}
                      {fmtDt(selected.approvedAt)}
                      {i18n.t('literals.lit-2')}
                    </div>
                  )}
                  {selected.secondApprovedBy && (
                    <div>
                      {t('camera.masodikJovahagyo')} {selected.secondApprovedBy}
                      {i18n.t('literals.lit')}
                      {fmtDt(selected.secondApprovedAt)}
                      {i18n.t('literals.lit-2')}
                    </div>
                  )}
                  {selected.rejectionReason && (
                    <div className="text-red-600">
                      {t('common.reject')} {selected.rejectionReason}
                    </div>
                  )}
                  {selected.exportPath && (
                    <div>
                      {t('commissions.export')} {selected.exportPath}
                    </div>
                  )}
                  {selected.exportSizeBytes && (
                    <div>
                      {t('documents.meret')} {fmtSize(selected.exportSizeBytes)}
                    </div>
                  )}
                  {selected.manifestHash && (
                    <div>
                      {t('camera.manifestHash')}{' '}
                      <code className="text-[10px] bg-gray-100 px-1">
                        {selected.manifestHash.slice(0, 16)}
                        {i18n.t('literals.lit-16')}
                      </code>
                    </div>
                  )}
                  {selected.errorMessage && (
                    <div className="text-red-600">
                      {t('foertektar.hiba')} {selected.errorMessage}
                    </div>
                  )}
                </div>

                <div className="flex gap-2 pt-2 border-t">
                  {selected.status === 'APPROVED' && (
                    <button
                      onClick={() => handleExecute(selected.id)}
                      className="btn-primary text-xs flex items-center gap-1"
                    >
                      <Download size={12} />
                      {t('camera.exportInditasa')}
                    </button>
                  )}
                  <button
                    onClick={handleVerifyChain}
                    className="btn-secondary text-xs flex items-center gap-1"
                  >
                    <ShieldCheck size={12} />
                    {t('camera.hashChainEllenorzes')}
                  </button>
                </div>

                {chainResult && (
                  <div
                    className={`p-2 rounded text-xs flex items-center gap-2 ${chainResult.chainIntact ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'}`}
                  >
                    {chainResult.chainIntact ? <CheckCircle size={14} /> : <XCircle size={14} />}
                    {chainResult.chainIntact ? 'Hash-lánc ép' : 'Hash-lánc SÉRÜLT!'}
                    <span className="text-gray-400 ml-auto">{fmtDt(chainResult.verifiedAt)}</span>
                  </div>
                )}
              </div>

              {/* Chain of Custody */}
              <div className="p-3 border rounded space-y-2">
                <h3 className="font-medium text-sm flex items-center gap-1">
                  <Eye size={14} />
                  {t('camera.chainOfCustody')}
                </h3>
                {custody.length === 0 ? (
                  <div className="text-xs text-gray-400">{t('camera.nincsBejegyzes')}</div>
                ) : (
                  <div className="space-y-1 max-h-60 overflow-y-auto">
                    {custody.map((c) => (
                      <div key={c.id} className="text-[10px] border-l-2 border-gray-300 pl-2 py-1">
                        <div className="flex justify-between">
                          <span className="font-medium">{c.eventType.replace(/_/g, ' ')}</span>
                          <span className="text-gray-400">{fmtDt(c.eventTimestamp)}</span>
                        </div>
                        <div className="text-gray-500">
                          {c.actor}
                          {i18n.t('literals.lit-18')}
                          {c.details}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </>
          ) : (
            <div className="text-gray-400 text-sm text-center py-8">
              {t('camera.valasszonEgyKerelmet')}
            </div>
          )}
        </div>
      </div>
      {reasonModal}
    </div>
  )
}
