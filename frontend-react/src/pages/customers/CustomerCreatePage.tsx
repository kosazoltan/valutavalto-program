import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Save, User, Building } from 'lucide-react'

export default function CustomerCreatePage() {
  const navigate = useNavigate()
  const [customerType, setCustomerType] = useState<'person' | 'company'>('person')
  const [formData, setFormData] = useState({
    // Person fields
    name: '',
    birthName: '',
    birthDate: '',
    birthPlace: '',
    motherName: '',
    nationality: 'Magyar',
    taxNumber: '',
    // Company fields
    companyName: '',
    registrationNumber: '',
    vatNumber: '',
    // Common fields
    documentType: 'Személyi igazolvány',
    documentNumber: '',
    documentExpiry: '',
    zip: '',
    city: '',
    street: '',
    country: 'Magyarország',
    phone: '',
    email: ''
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    // API call would go here
    navigate('/customers')
  }

  const updateField = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-3">
          <Link to="/customers" className="toolbar-button">
            <ArrowLeft size={18} />
          </Link>
          <h1 className="text-xl font-bold text-gray-800">Új ügyfél rögzítése</h1>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-3">
        {/* Customer Type Selection */}
        <div className="form-panel">
          <h2 className="section-title">Ügyfél típusa</h2>
          <div className="flex gap-3">
            <button
              type="button"
              onClick={() => setCustomerType('person')}
              className={`flex items-center gap-2 px-4 py-2 rounded border-2 transition-colors ${
                customerType === 'person' 
                  ? 'border-blue-500 bg-blue-50 text-blue-700' 
                  : 'border-gray-300 hover:border-gray-400'
              }`}
            >
              <User size={18} />
              Magánszemély
            </button>
            <button
              type="button"
              onClick={() => setCustomerType('company')}
              className={`flex items-center gap-2 px-4 py-2 rounded border-2 transition-colors ${
                customerType === 'company' 
                  ? 'border-blue-500 bg-blue-50 text-blue-700' 
                  : 'border-gray-300 hover:border-gray-400'
              }`}
            >
              <Building size={18} />
              Céges ügyfél
            </button>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          {/* Basic Info */}
          <div className="form-panel">
            <h2 className="section-title">
              {customerType === 'person' ? 'Személyes adatok' : 'Cégadatok'}
            </h2>
            
            {customerType === 'person' ? (
              <div className="space-y-3">
                <div>
                  <label className="form-label required">Név</label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => updateField('name', e.target.value)}
                    className="form-input"
                    required
                  />
                </div>
                <div>
                  <label className="form-label">Születési név</label>
                  <input
                    type="text"
                    value={formData.birthName}
                    onChange={(e) => updateField('birthName', e.target.value)}
                    className="form-input"
                  />
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="form-label required">Születési dátum</label>
                    <input
                      type="date"
                      value={formData.birthDate}
                      onChange={(e) => updateField('birthDate', e.target.value)}
                      className="form-input"
                      required
                    />
                  </div>
                  <div>
                    <label className="form-label">Születési hely</label>
                    <input
                      type="text"
                      value={formData.birthPlace}
                      onChange={(e) => updateField('birthPlace', e.target.value)}
                      className="form-input"
                    />
                  </div>
                </div>
                <div>
                  <label className="form-label required">Anyja neve</label>
                  <input
                    type="text"
                    value={formData.motherName}
                    onChange={(e) => updateField('motherName', e.target.value)}
                    className="form-input"
                    required
                  />
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="form-label">Állampolgárság</label>
                    <input
                      type="text"
                      value={formData.nationality}
                      onChange={(e) => updateField('nationality', e.target.value)}
                      className="form-input"
                    />
                  </div>
                  <div>
                    <label className="form-label">Adószám</label>
                    <input
                      type="text"
                      value={formData.taxNumber}
                      onChange={(e) => updateField('taxNumber', e.target.value)}
                      className="form-input font-mono"
                    />
                  </div>
                </div>
              </div>
            ) : (
              <div className="space-y-3">
                <div>
                  <label className="form-label required">Cégnév</label>
                  <input
                    type="text"
                    value={formData.companyName}
                    onChange={(e) => updateField('companyName', e.target.value)}
                    className="form-input"
                    required
                  />
                </div>
                <div>
                  <label className="form-label required">Cégjegyzékszám</label>
                  <input
                    type="text"
                    value={formData.registrationNumber}
                    onChange={(e) => updateField('registrationNumber', e.target.value)}
                    className="form-input font-mono"
                    required
                  />
                </div>
                <div>
                  <label className="form-label required">Adószám</label>
                  <input
                    type="text"
                    value={formData.vatNumber}
                    onChange={(e) => updateField('vatNumber', e.target.value)}
                    className="form-input font-mono"
                    required
                  />
                </div>
              </div>
            )}
          </div>

          {/* Document Info */}
          <div className="form-panel">
            <h2 className="section-title">Okmány adatok</h2>
            <div className="space-y-3">
              <div>
                <label className="form-label required">Okmány típusa</label>
                <select
                  value={formData.documentType}
                  onChange={(e) => updateField('documentType', e.target.value)}
                  className="form-input"
                  required
                >
                  <option>Személyi igazolvány</option>
                  <option>Útlevél</option>
                  <option>Vezetői engedély</option>
                  <option>Tartózkodási engedély</option>
                </select>
              </div>
              <div>
                <label className="form-label required">Okmányszám</label>
                <input
                  type="text"
                  value={formData.documentNumber}
                  onChange={(e) => updateField('documentNumber', e.target.value)}
                  className="form-input font-mono"
                  required
                />
              </div>
              <div>
                <label className="form-label">Okmány érvényessége</label>
                <input
                  type="date"
                  value={formData.documentExpiry}
                  onChange={(e) => updateField('documentExpiry', e.target.value)}
                  className="form-input"
                />
              </div>
            </div>
          </div>

          {/* Address */}
          <div className="form-panel">
            <h2 className="section-title">Lakcím / Székhely</h2>
            <div className="space-y-3">
              <div className="grid grid-cols-3 gap-2">
                <div>
                  <label className="form-label required">Irányítószám</label>
                  <input
                    type="text"
                    value={formData.zip}
                    onChange={(e) => updateField('zip', e.target.value)}
                    className="form-input"
                    required
                  />
                </div>
                <div className="col-span-2">
                  <label className="form-label required">Város</label>
                  <input
                    type="text"
                    value={formData.city}
                    onChange={(e) => updateField('city', e.target.value)}
                    className="form-input"
                    required
                  />
                </div>
              </div>
              <div>
                <label className="form-label required">Utca, házszám</label>
                <input
                  type="text"
                  value={formData.street}
                  onChange={(e) => updateField('street', e.target.value)}
                  className="form-input"
                  required
                />
              </div>
              <div>
                <label className="form-label">Ország</label>
                <input
                  type="text"
                  value={formData.country}
                  onChange={(e) => updateField('country', e.target.value)}
                  className="form-input"
                />
              </div>
            </div>
          </div>

          {/* Contact */}
          <div className="form-panel">
            <h2 className="section-title">Elérhetőségek</h2>
            <div className="space-y-3">
              <div>
                <label className="form-label">Telefonszám</label>
                <input
                  type="tel"
                  value={formData.phone}
                  onChange={(e) => updateField('phone', e.target.value)}
                  className="form-input font-mono"
                  placeholder="+36..."
                />
              </div>
              <div>
                <label className="form-label">E-mail cím</label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => updateField('email', e.target.value)}
                  className="form-input"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Submit */}
        <div className="form-panel flex justify-end gap-2">
          <Link to="/customers" className="form-button">
            Mégse
          </Link>
          <button type="submit" className="form-button-primary flex items-center gap-1">
            <Save size={16} />
            Mentés
          </button>
        </div>
      </form>
    </div>
  )
}
