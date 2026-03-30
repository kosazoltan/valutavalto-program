import { useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { ArrowLeft, Save, AlertCircle } from 'lucide-react'
import { authorizedRepresentativeApi, RepresentativeRegistrationRequest } from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'

export default function RepresentativeCreatePage() {
  const { customerId } = useParams<{ customerId: string }>()
  const navigate = useNavigate()
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState({
    name: '',
    documentType: 'Személyi igazolvány',
    documentNumber: '',
    documentExpiry: '',
    address: '',
    phone: '',
    email: '',
    relationship: '',
  })

  const update = (field: string, value: string) => {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!customerId) return
    try {
      setSaving(true)
      setError(null)
      const req: RepresentativeRegistrationRequest = {
        name: form.name,
        documentType: form.documentType,
        documentNumber: form.documentNumber,
        documentExpiry: form.documentExpiry || undefined,
        address: form.address || undefined,
        phone: form.phone || undefined,
        email: form.email || undefined,
        relationship: form.relationship || undefined,
      }
      await authorizedRepresentativeApi.register(customerId, req, '')
      navigate(`/customers/${customerId}/representatives`)
    } catch (err) {
      setError(getErrorMessage(err))
      logger.error('RepresentativeCreatePage', 'Failed to create representative:', err)
    } finally {
      setSaving(false)
    }
  }

  if (!customerId) {
    return <div className="form-panel text-center py-8 text-gray-500">Ügyfél ID hiányzik</div>
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-3">
        <Link to={`/customers/${customerId}/representatives`} className="toolbar-button">
          <ArrowLeft size={18} />
        </Link>
        <h1 className="text-xl font-bold text-gray-800">Új meghatalmazott</h1>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      <form onSubmit={(e) => void handleSubmit(e)} className="space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <div className="form-panel">
            <h2 className="section-title">Személyes adatok</h2>
            <div className="space-y-3">
              <div>
                <label className="form-label required">Teljes név</label>
                <input type="text" value={form.name} onChange={(e) => update('name', e.target.value)} className="form-input" required />
              </div>
              <div>
                <label className="form-label">Cím</label>
                <input type="text" value={form.address} onChange={(e) => update('address', e.target.value)} className="form-input" />
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="form-label">Telefon</label>
                  <input type="tel" value={form.phone} onChange={(e) => update('phone', e.target.value)} className="form-input font-mono" />
                </div>
                <div>
                  <label className="form-label">E-mail</label>
                  <input type="email" value={form.email} onChange={(e) => update('email', e.target.value)} className="form-input" />
                </div>
              </div>
              <div>
                <label className="form-label">Kapcsolat típusa</label>
                <select value={form.relationship} onChange={(e) => update('relationship', e.target.value)} className="form-input">
                  <option value="">—</option>
                  <option value="FAMILY">Családtag</option>
                  <option value="COLLEAGUE">Munkatárs</option>
                  <option value="FRIEND">Barát</option>
                  <option value="PROFESSIONAL">Szakmai</option>
                  <option value="BUSINESS">Üzleti</option>
                  <option value="OTHER">Egyéb</option>
                </select>
              </div>
            </div>
          </div>

          <div className="form-panel">
            <h2 className="section-title">Okmány adatok</h2>
            <div className="space-y-3">
              <div>
                <label className="form-label required">Okmány típusa</label>
                <select value={form.documentType} onChange={(e) => update('documentType', e.target.value)} className="form-input" required>
                  <option>Személyi igazolvány</option>
                  <option>Útlevél</option>
                  <option>Vezetői engedély</option>
                  <option>Tartózkodási engedély</option>
                </select>
              </div>
              <div>
                <label className="form-label required">Okmányszám</label>
                <input type="text" value={form.documentNumber} onChange={(e) => update('documentNumber', e.target.value)} className="form-input font-mono" required />
              </div>
              <div>
                <label className="form-label">Okmány érvényessége</label>
                <input type="date" value={form.documentExpiry} onChange={(e) => update('documentExpiry', e.target.value)} className="form-input" />
              </div>
            </div>
          </div>
        </div>

        <div className="form-panel flex justify-end gap-2">
          <Link to={`/customers/${customerId}/representatives`} className="form-button">Mégse</Link>
          <button type="submit" disabled={saving} className="form-button-primary flex items-center gap-1">
            <Save size={16} />
            {saving ? 'Mentés...' : 'Mentés'}
          </button>
        </div>
      </form>
    </div>
  )
}
