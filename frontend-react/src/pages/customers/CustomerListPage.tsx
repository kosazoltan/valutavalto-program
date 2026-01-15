import { useState } from 'react'
import { Link } from 'react-router-dom'
import { Users, Search, Plus, Edit, Trash2, Eye } from 'lucide-react'

const mockCustomers = [
  { id: '1', name: 'Kiss János', birthDate: '1985-03-15', nationality: 'Magyar', documentType: 'Személyi ig.', documentNumber: '123456AB', phone: '+36301234567', createdAt: '2024-01-15' },
  { id: '2', name: 'Nagy Péter', birthDate: '1990-07-22', nationality: 'Magyar', documentType: 'Útlevél', documentNumber: 'AB1234567', phone: '+36201234567', createdAt: '2024-02-20' },
  { id: '3', name: 'Szabó Anna', birthDate: '1978-11-30', nationality: 'Magyar', documentType: 'Személyi ig.', documentNumber: '789012CD', phone: '+36701234567', createdAt: '2024-03-10' },
  { id: '4', name: 'Kovács István', birthDate: '1995-05-08', nationality: 'Szlovák', documentType: 'Útlevél', documentNumber: 'SK9876543', phone: '+421901234567', createdAt: '2024-04-05' },
]

export default function CustomerListPage() {
  const [search, setSearch] = useState('')

  const filteredCustomers = mockCustomers.filter(c => 
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    c.documentNumber.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="space-y-3">
      {/* Header */}
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Users />
          Ügyfelek
        </h1>
        <Link to="/customers/new" className="form-button-primary flex items-center gap-1">
          <Plus size={16} />
          Új ügyfél
        </Link>
      </div>

      {/* Search */}
      <div className="form-panel">
        <div className="flex gap-1 max-w-md">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="form-input flex-1"
            placeholder="Keresés név vagy okmányszám alapján..."
          />
          <button className="form-button">
            <Search size={16} />
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="form-panel p-0">
        <table className="data-grid w-full">
          <thead>
            <tr>
              <th>Név</th>
              <th>Születési dátum</th>
              <th>Állampolgárság</th>
              <th>Okmány típus</th>
              <th>Okmányszám</th>
              <th>Telefon</th>
              <th>Létrehozva</th>
              <th className="w-28">Műveletek</th>
            </tr>
          </thead>
          <tbody>
            {filteredCustomers.map((customer) => (
              <tr key={customer.id}>
                <td className="font-semibold">{customer.name}</td>
                <td>{customer.birthDate}</td>
                <td>{customer.nationality}</td>
                <td>{customer.documentType}</td>
                <td className="font-mono">{customer.documentNumber}</td>
                <td className="font-mono text-sm">{customer.phone}</td>
                <td className="text-sm text-gray-600">{customer.createdAt}</td>
                <td>
                  <div className="flex gap-1">
                    <Link to={`/customers/${customer.id}`} className="toolbar-button" title="Megtekintés">
                      <Eye size={14} />
                    </Link>
                    <button className="toolbar-button" title="Szerkesztés">
                      <Edit size={14} />
                    </button>
                    <button className="toolbar-button text-red-500" title="Törlés">
                      <Trash2 size={14} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Footer */}
      <div className="form-panel">
        <span className="text-sm">{filteredCustomers.length} ügyfél</span>
      </div>
    </div>
  )
}
