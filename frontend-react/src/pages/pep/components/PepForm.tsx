import { useState } from 'react'
import type { PepFormData, PoliticallyExposedPerson } from '../hooks/usePepData'

interface PepFormProps {
  pep: PoliticallyExposedPerson | null
  onSubmit: (data: PepFormData) => void
  onCancel: () => void
}

export default function PepForm({ pep, onSubmit, onCancel }: PepFormProps) {
  const [formData, setFormData] = useState<PepFormData>({
    customerId: pep?.customerId || '',
    customerName: pep?.customerName || '',
    documentNumber: pep?.documentNumber || '',
    pepCategory: pep?.pepCategory || 'DIRECT',
    positionType: pep?.positionType || 'GOVERNMENT_MEMBER',
    positionDescription: pep?.positionDescription || '',
    country: pep?.country || 'HU',
    appointmentStartDate: pep?.appointmentStartDate?.split('T')[0] || '',
    appointmentEndDate: pep?.appointmentEndDate?.split('T')[0] || '',
    sourceOfWealth: pep?.sourceOfWealth || '',
    sourceOfFunds: pep?.sourceOfFunds || '',
    requiresEdd: pep?.requiresEdd ?? true,
    requiresApproval: pep?.requiresApproval ?? true,
    maxAmountWithoutApproval: pep?.maxAmountWithoutApproval?.toString() || '',
    reviewDate: pep?.reviewDate?.split('T')[0] || '',
    notes: pep?.notes || '',
    isActive: pep?.isActive ?? true,
  })

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    onSubmit(formData)
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="grid grid-cols-2 gap-4">
        <div>
          <label htmlFor="customerName" className="block text-sm font-medium mb-1">Ügyfél neve *</label>
          <input
            id="customerName"
            type="text"
            value={formData.customerName}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, customerName: e.target.value })}
            placeholder="Teljes név"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label htmlFor="documentNumber" className="block text-sm font-medium mb-1">Okmányszám *</label>
          <input
            id="documentNumber"
            type="text"
            value={formData.documentNumber}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, documentNumber: e.target.value })}
            placeholder="Személyi ig. vagy útlevél szám"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label htmlFor="pepCategory" className="block text-sm font-medium mb-1">PEP kategória *</label>
          <select
            id="pepCategory"
            value={formData.pepCategory}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, pepCategory: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="DIRECT">Közvetlen PEP</option>
            <option value="FAMILY">Családtag</option>
            <option value="ASSOCIATE">Közeli kapcsolat</option>
          </select>
        </div>
        <div>
          <label htmlFor="positionType" className="block text-sm font-medium mb-1">Pozíció típusa *</label>
          <select
            id="positionType"
            value={formData.positionType}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) => setFormData({ ...formData, positionType: e.target.value })}
            className="w-full p-2 border rounded"
          >
            <option value="HEAD_OF_STATE">Államfő</option>
            <option value="GOVERNMENT_MEMBER">Kormánytag</option>
            <option value="PARLIAMENT_MEMBER">Parlamenti képviselő</option>
            <option value="SUPREME_COURT_MEMBER">Legfelsőbb bírósági tag</option>
            <option value="CENTRAL_BANK_MEMBER">Jegybanki vezető</option>
            <option value="AMBASSADOR">Nagykövet</option>
            <option value="MILITARY_OFFICER">Magas rangú tiszt</option>
            <option value="STATE_ENTERPRISE_EXECUTIVE">Állami vállalat vezetője</option>
            <option value="POLITICAL_PARTY_LEADER">Politikai párt vezetője</option>
            <option value="INTERNATIONAL_ORG_LEADER">Nemzetközi szervezet vezetője</option>
          </select>
        </div>
        <div className="col-span-2">
          <label htmlFor="positionDescription" className="block text-sm font-medium mb-1">Pozíció leírása</label>
          <input
            id="positionDescription"
            type="text"
            value={formData.positionDescription}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, positionDescription: e.target.value })}
            placeholder="pl. Pénzügyminisztérium államtitkára"
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="country" className="block text-sm font-medium mb-1">Ország *</label>
          <input
            id="country"
            type="text"
            value={formData.country}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, country: e.target.value })}
            maxLength={3}
            placeholder="HU"
            className="w-full p-2 border rounded"
            required
          />
        </div>
        <div>
          <label htmlFor="reviewDate" className="block text-sm font-medium mb-1">Felülvizsgálat dátuma</label>
          <input
            id="reviewDate"
            type="date"
            value={formData.reviewDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, reviewDate: e.target.value })}
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="appointmentStartDate" className="block text-sm font-medium mb-1">Kinevezés kezdete</label>
          <input
            id="appointmentStartDate"
            type="date"
            value={formData.appointmentStartDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, appointmentStartDate: e.target.value })}
            className="w-full p-2 border rounded"
          />
        </div>
        <div>
          <label htmlFor="appointmentEndDate" className="block text-sm font-medium mb-1">Kinevezés vége</label>
          <input
            id="appointmentEndDate"
            type="date"
            value={formData.appointmentEndDate}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, appointmentEndDate: e.target.value })}
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="col-span-2">
          <label htmlFor="sourceOfWealth" className="block text-sm font-medium mb-1">Vagyon eredete</label>
          <textarea
            id="sourceOfWealth"
            value={formData.sourceOfWealth}
            onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setFormData({ ...formData, sourceOfWealth: e.target.value })}
            rows={2}
            placeholder="Vagyon forrásának leírása"
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="col-span-2">
          <label htmlFor="sourceOfFunds" className="block text-sm font-medium mb-1">Pénzeszközök forrása</label>
          <textarea
            id="sourceOfFunds"
            value={formData.sourceOfFunds}
            onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setFormData({ ...formData, sourceOfFunds: e.target.value })}
            rows={2}
            placeholder="Tranzakciókhoz használt pénzeszközök forrása"
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="flex items-center gap-2">
          <input
            id="requiresEdd"
            type="checkbox"
            checked={formData.requiresEdd}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, requiresEdd: e.target.checked })}
            className="h-4 w-4"
          />
          <label htmlFor="requiresEdd" className="text-sm font-medium">Fokozott átvilágítás (EDD) szükséges</label>
        </div>
        <div className="flex items-center gap-2">
          <input
            id="requiresApproval"
            type="checkbox"
            checked={formData.requiresApproval}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, requiresApproval: e.target.checked })}
            className="h-4 w-4"
          />
          <label htmlFor="requiresApproval" className="text-sm font-medium">Vezetői jóváhagyás szükséges</label>
        </div>
        {formData.requiresApproval && (
          <div>
            <label htmlFor="maxAmountWithoutApproval" className="block text-sm font-medium mb-1">Jóváhagyás nélküli max összeg (Ft)</label>
            <input
              id="maxAmountWithoutApproval"
              type="number"
              value={formData.maxAmountWithoutApproval}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, maxAmountWithoutApproval: e.target.value })}
              placeholder="pl. 500000"
              className="w-full p-2 border rounded"
            />
          </div>
        )}
        <div className="col-span-2">
          <label htmlFor="notes" className="block text-sm font-medium mb-1">Megjegyzések</label>
          <textarea
            id="notes"
            value={formData.notes}
            onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setFormData({ ...formData, notes: e.target.value })}
            rows={3}
            placeholder="Egyéb megjegyzések"
            className="w-full p-2 border rounded"
          />
        </div>
        <div className="flex items-center gap-2">
          <input
            id="isActive"
            type="checkbox"
            checked={formData.isActive}
            onChange={(e: React.ChangeEvent<HTMLInputElement>) => setFormData({ ...formData, isActive: e.target.checked })}
            className="h-4 w-4"
          />
          <label htmlFor="isActive" className="text-sm font-medium">Aktív</label>
        </div>
      </div>
      <div className="flex justify-end gap-2">
        <button
          type="button"
          onClick={onCancel}
          className="px-4 py-2 border rounded hover:bg-gray-50"
        >
          Mégse
        </button>
        <button
          type="submit"
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          {pep ? 'Mentés' : 'Regisztrálás'}
        </button>
      </div>
    </form>
  )
}
