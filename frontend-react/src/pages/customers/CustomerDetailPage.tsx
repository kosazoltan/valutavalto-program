import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import {
  User, ArrowLeft, Save, Edit, Clock, FileText,
  Phone, MapPin, CreditCard, Calendar, AlertCircle, Loader2, Users
} from 'lucide-react'
import { customerApi, Customer, CustomerCreateRequest } from '../../services/api/transactions'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'

export default function CustomerDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [isEditing, setIsEditing] = useState(false)
  const [customer, setCustomer] = useState<Customer | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!id) return
    const load = async () => {
      try {
        setLoading(true)
        setError(null)
        const data = await customerApi.getById(Number(id))
        setCustomer(data)
      } catch (err) {
        setError(getErrorMessage(err))
        logger.error('CustomerDetailPage', 'Failed to load customer:', err)
      } finally {
        setLoading(false)
      }
    }
    void load()
  }, [id])

  const handleSave = async () => {
    if (!customer || !id) return
    try {
      setSaving(true)
      setError(null)
      const req: CustomerCreateRequest = {
        name: customer.name,
        birthName: customer.birthName,
        motherName: customer.motherName,
        birthDate: customer.birthDate,
        birthPlace: customer.birthPlace,
        nationality: customer.nationality,
        documentNumber: customer.documentNumber,
        documentType: customer.documentType,
        documentExpiry: customer.documentExpiry,
        address: customer.address,
        postalCode: customer.postalCode,
        city: customer.city,
        country: customer.country,
        phone: customer.phone,
        email: customer.email,
        isCompany: customer.isCompany,
        companyName: customer.companyName,
        taxNumber: customer.taxNumber,
        registrationNumber: customer.registrationNumber,
        isVip: customer.isVip,
        notes: customer.notes,
      }
      const updated = await customerApi.update(Number(id), req)
      setCustomer(updated)
      setIsEditing(false)
    } catch (err) {
      setError(getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12 text-gray-500 gap-2">
        <Loader2 size={20} className="animate-spin" />
        Betöltés...
      </div>
    )
  }

  if (!customer) {
    return (
      <div className="form-panel text-center py-8">
        <AlertCircle className="inline mr-2" size={16} />
        {error || 'Ügyfél nem található'}
        <div className="mt-4">
          <Link to="/customers" className="form-button">Vissza</Link>
        </div>
      </div>
    )
  }

  const updateField = <K extends keyof Customer>(field: K, value: Customer[K]) => {
    setCustomer(prev => prev ? { ...prev, [field]: value } : prev)
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-3">
          <Link to="/customers" className="toolbar-button">
            <ArrowLeft size={18} />
          </Link>
          <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
            <User />
            Ügyfél adatai
            {customer.isVip && <span className="text-xs bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded">VIP</span>}
          </h1>
        </div>
        <div className="flex gap-2">
          <Link
            to={`/customers/${id}/representatives`}
            className="form-button flex items-center gap-1"
          >
            <Users size={16} />
            Meghatalmazottak
          </Link>
          {isEditing ? (
            <>
              <button onClick={() => setIsEditing(false)} className="form-button">
                Mégse
              </button>
              <button onClick={() => void handleSave()} disabled={saving} className="form-button-primary flex items-center gap-1">
                <Save size={16} />
                {saving ? 'Mentés...' : 'Mentés'}
              </button>
            </>
          ) : (
            <button onClick={() => setIsEditing(true)} className="form-button flex items-center gap-1">
              <Edit size={16} />
              Szerkesztés
            </button>
          )}
        </div>
      </div>

      {error && (
        <div className="form-panel bg-red-50 border-red-200">
          <div className="flex items-center gap-2 text-red-700">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        </div>
      )}

      <div className="grid grid-cols-3 gap-3">
        {/* Basic Info */}
        <div className="form-panel col-span-2">
          <h2 className="section-title">Alapadatok</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label">Név</label>
              <input type="text" value={customer.name || ''} onChange={(e) => updateField('name', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">Születési név</label>
              <input type="text" value={customer.birthName || ''} onChange={(e) => updateField('birthName', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">Születési dátum</label>
              <input type="date" value={customer.birthDate || ''} onChange={(e) => updateField('birthDate', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">Születési hely</label>
              <input type="text" value={customer.birthPlace || ''} onChange={(e) => updateField('birthPlace', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">Anyja neve</label>
              <input type="text" value={customer.motherName || ''} onChange={(e) => updateField('motherName', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">Állampolgárság</label>
              <input type="text" value={customer.nationality || ''} onChange={(e) => updateField('nationality', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">Adószám</label>
              <input type="text" value={customer.taxNumber || ''} onChange={(e) => updateField('taxNumber', e.target.value)} disabled={!isEditing} className="form-input font-mono" />
            </div>
            <div>
              <label className="form-label">Megjegyzés</label>
              <input type="text" value={customer.notes || ''} onChange={(e) => updateField('notes', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
          </div>
        </div>

        {/* Stats Card */}
        <div className="form-panel">
          <h2 className="section-title">Statisztika</h2>
          <div className="space-y-3">
            <div className="bg-blue-50 p-3 rounded">
              <div className="text-sm text-blue-600">Összes tranzakció</div>
              <div className="text-2xl font-bold text-blue-800">{customer.transactionCount ?? 0}</div>
            </div>
            {customer.lastTransactionDate && (
              <div className="bg-gray-50 p-3 rounded">
                <div className="text-sm text-gray-600 flex items-center gap-1">
                  <Clock size={14} />
                  Utolsó tranzakció
                </div>
                <div className="text-lg font-semibold">
                  {new Date(customer.lastTransactionDate).toLocaleDateString('hu-HU')}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Document Info */}
        <div className="form-panel">
          <h2 className="section-title flex items-center gap-2">
            <FileText size={16} />
            Okmány adatok
          </h2>
          <div className="space-y-3">
            <div>
              <label className="form-label">Okmány típusa</label>
              <select value={customer.documentType || ''} onChange={(e) => updateField('documentType', e.target.value)} disabled={!isEditing} className="form-input">
                <option value="">—</option>
                <option value="Személyi igazolvány">Személyi igazolvány</option>
                <option value="Útlevél">Útlevél</option>
                <option value="Vezetői engedély">Vezetői engedély</option>
                <option value="Tartózkodási engedély">Tartózkodási engedély</option>
              </select>
            </div>
            <div>
              <label className="form-label">Okmányszám</label>
              <input type="text" value={customer.documentNumber || ''} onChange={(e) => updateField('documentNumber', e.target.value)} disabled={!isEditing} className="form-input font-mono" />
            </div>
            <div>
              <label className="form-label">Érvényesség</label>
              <input type="date" value={customer.documentExpiry || ''} onChange={(e) => updateField('documentExpiry', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
          </div>
        </div>

        {/* Contact Info */}
        <div className="form-panel">
          <h2 className="section-title flex items-center gap-2">
            <Phone size={16} />
            Elérhetőségek
          </h2>
          <div className="space-y-3">
            <div>
              <label className="form-label">Telefon</label>
              <input type="tel" value={customer.phone || ''} onChange={(e) => updateField('phone', e.target.value)} disabled={!isEditing} className="form-input font-mono" />
            </div>
            <div>
              <label className="form-label">E-mail</label>
              <input type="email" value={customer.email || ''} onChange={(e) => updateField('email', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
          </div>
        </div>

        {/* Address */}
        <div className="form-panel">
          <h2 className="section-title flex items-center gap-2">
            <MapPin size={16} />
            Lakcím
          </h2>
          <div className="space-y-3">
            <div className="grid grid-cols-2 gap-2">
              <div>
                <label className="form-label">Irányítószám</label>
                <input type="text" value={customer.postalCode || ''} onChange={(e) => updateField('postalCode', e.target.value)} disabled={!isEditing} className="form-input" />
              </div>
              <div>
                <label className="form-label">Város</label>
                <input type="text" value={customer.city || ''} onChange={(e) => updateField('city', e.target.value)} disabled={!isEditing} className="form-input" />
              </div>
            </div>
            <div>
              <label className="form-label">Utca, házszám</label>
              <input type="text" value={customer.address || ''} onChange={(e) => updateField('address', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
            <div>
              <label className="form-label">Ország</label>
              <input type="text" value={customer.country || ''} onChange={(e) => updateField('country', e.target.value)} disabled={!isEditing} className="form-input" />
            </div>
          </div>
        </div>
      </div>

      {/* Metadata */}
      <div className="form-panel">
        <div className="flex gap-6 text-sm text-gray-500">
          <span className="flex items-center gap-1">
            <Calendar size={14} />
            Létrehozva: {customer.createdAt ? new Date(customer.createdAt).toLocaleString('hu-HU') : '-'}
          </span>
          <span className="flex items-center gap-1">
            <Clock size={14} />
            Módosítva: {customer.updatedAt ? new Date(customer.updatedAt).toLocaleString('hu-HU') : '-'}
          </span>
          <span className="flex items-center gap-1">
            <CreditCard size={14} />
            ID: {id}
          </span>
        </div>
      </div>
    </div>
  )
}
