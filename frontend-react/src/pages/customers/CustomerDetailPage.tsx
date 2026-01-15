import { useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { 
  User, ArrowLeft, Save, Edit, Clock, FileText, 
  Phone, MapPin, CreditCard, Calendar
} from 'lucide-react'

const mockCustomer = {
  id: '1',
  type: 'person',
  name: 'Kiss János',
  birthName: 'Kiss János Péter',
  birthDate: '1985-03-15',
  birthPlace: 'Budapest',
  motherName: 'Szabó Mária',
  nationality: 'Magyar',
  taxNumber: '8123456789',
  documentType: 'Személyi igazolvány',
  documentNumber: '123456AB',
  documentExpiry: '2028-05-20',
  address: {
    zip: '1011',
    city: 'Budapest',
    street: 'Fő utca 12.',
    country: 'Magyarország'
  },
  contact: {
    phone: '+36301234567',
    email: 'kiss.janos@email.hu'
  },
  stats: {
    totalTransactions: 45,
    totalVolume: 12500000,
    lastTransaction: '2024-05-15'
  },
  createdAt: '2024-01-15 10:30:00',
  updatedAt: '2024-05-15 14:22:00'
}

export default function CustomerDetailPage() {
  const { id } = useParams()
  const [isEditing, setIsEditing] = useState(false)
  const [customer, setCustomer] = useState(mockCustomer)

  const handleSave = () => {
    setIsEditing(false)
    // API call would go here
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
          </h1>
        </div>
        <div className="flex gap-2">
          {isEditing ? (
            <>
              <button onClick={() => setIsEditing(false)} className="form-button">
                Mégse
              </button>
              <button onClick={handleSave} className="form-button-primary flex items-center gap-1">
                <Save size={16} />
                Mentés
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

      <div className="grid grid-cols-3 gap-3">
        {/* Basic Info */}
        <div className="form-panel col-span-2">
          <h2 className="section-title">Alapadatok</h2>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label">Név</label>
              <input
                type="text"
                value={customer.name}
                onChange={(e) => setCustomer({...customer, name: e.target.value})}
                disabled={!isEditing}
                className="form-input"
              />
            </div>
            <div>
              <label className="form-label">Születési név</label>
              <input
                type="text"
                value={customer.birthName}
                onChange={(e) => setCustomer({...customer, birthName: e.target.value})}
                disabled={!isEditing}
                className="form-input"
              />
            </div>
            <div>
              <label className="form-label">Születési dátum</label>
              <input
                type="date"
                value={customer.birthDate}
                onChange={(e) => setCustomer({...customer, birthDate: e.target.value})}
                disabled={!isEditing}
                className="form-input"
              />
            </div>
            <div>
              <label className="form-label">Születési hely</label>
              <input
                type="text"
                value={customer.birthPlace}
                onChange={(e) => setCustomer({...customer, birthPlace: e.target.value})}
                disabled={!isEditing}
                className="form-input"
              />
            </div>
            <div>
              <label className="form-label">Anyja neve</label>
              <input
                type="text"
                value={customer.motherName}
                onChange={(e) => setCustomer({...customer, motherName: e.target.value})}
                disabled={!isEditing}
                className="form-input"
              />
            </div>
            <div>
              <label className="form-label">Állampolgárság</label>
              <input
                type="text"
                value={customer.nationality}
                onChange={(e) => setCustomer({...customer, nationality: e.target.value})}
                disabled={!isEditing}
                className="form-input"
              />
            </div>
            <div>
              <label className="form-label">Adószám</label>
              <input
                type="text"
                value={customer.taxNumber}
                onChange={(e) => setCustomer({...customer, taxNumber: e.target.value})}
                disabled={!isEditing}
                className="form-input font-mono"
              />
            </div>
          </div>
        </div>

        {/* Stats Card */}
        <div className="form-panel">
          <h2 className="section-title">Statisztika</h2>
          <div className="space-y-3">
            <div className="bg-blue-50 p-3 rounded">
              <div className="text-sm text-blue-600">Összes tranzakció</div>
              <div className="text-2xl font-bold text-blue-800">{customer.stats.totalTransactions}</div>
            </div>
            <div className="bg-green-50 p-3 rounded">
              <div className="text-sm text-green-600">Összes forgalom</div>
              <div className="text-xl font-bold text-green-800">
                {customer.stats.totalVolume.toLocaleString('hu-HU')} Ft
              </div>
            </div>
            <div className="bg-gray-50 p-3 rounded">
              <div className="text-sm text-gray-600 flex items-center gap-1">
                <Clock size={14} />
                Utolsó tranzakció
              </div>
              <div className="text-lg font-semibold">{customer.stats.lastTransaction}</div>
            </div>
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
              <select
                value={customer.documentType}
                onChange={(e) => setCustomer({...customer, documentType: e.target.value})}
                disabled={!isEditing}
                className="form-input"
              >
                <option>Személyi igazolvány</option>
                <option>Útlevél</option>
                <option>Vezetői engedély</option>
                <option>Tartózkodási engedély</option>
              </select>
            </div>
            <div>
              <label className="form-label">Okmányszám</label>
              <input
                type="text"
                value={customer.documentNumber}
                onChange={(e) => setCustomer({...customer, documentNumber: e.target.value})}
                disabled={!isEditing}
                className="form-input font-mono"
              />
            </div>
            <div>
              <label className="form-label">Érvényesség</label>
              <input
                type="date"
                value={customer.documentExpiry}
                onChange={(e) => setCustomer({...customer, documentExpiry: e.target.value})}
                disabled={!isEditing}
                className="form-input"
              />
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
              <input
                type="tel"
                value={customer.contact.phone}
                onChange={(e) => setCustomer({
                  ...customer, 
                  contact: {...customer.contact, phone: e.target.value}
                })}
                disabled={!isEditing}
                className="form-input font-mono"
              />
            </div>
            <div>
              <label className="form-label">E-mail</label>
              <input
                type="email"
                value={customer.contact.email}
                onChange={(e) => setCustomer({
                  ...customer, 
                  contact: {...customer.contact, email: e.target.value}
                })}
                disabled={!isEditing}
                className="form-input"
              />
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
                <input
                  type="text"
                  value={customer.address.zip}
                  onChange={(e) => setCustomer({
                    ...customer, 
                    address: {...customer.address, zip: e.target.value}
                  })}
                  disabled={!isEditing}
                  className="form-input"
                />
              </div>
              <div>
                <label className="form-label">Város</label>
                <input
                  type="text"
                  value={customer.address.city}
                  onChange={(e) => setCustomer({
                    ...customer, 
                    address: {...customer.address, city: e.target.value}
                  })}
                  disabled={!isEditing}
                  className="form-input"
                />
              </div>
            </div>
            <div>
              <label className="form-label">Utca, házszám</label>
              <input
                type="text"
                value={customer.address.street}
                onChange={(e) => setCustomer({
                  ...customer, 
                  address: {...customer.address, street: e.target.value}
                })}
                disabled={!isEditing}
                className="form-input"
              />
            </div>
            <div>
              <label className="form-label">Ország</label>
              <input
                type="text"
                value={customer.address.country}
                onChange={(e) => setCustomer({
                  ...customer, 
                  address: {...customer.address, country: e.target.value}
                })}
                disabled={!isEditing}
                className="form-input"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Metadata */}
      <div className="form-panel">
        <div className="flex gap-6 text-sm text-gray-500">
          <span className="flex items-center gap-1">
            <Calendar size={14} />
            Létrehozva: {customer.createdAt}
          </span>
          <span className="flex items-center gap-1">
            <Clock size={14} />
            Módosítva: {customer.updatedAt}
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
