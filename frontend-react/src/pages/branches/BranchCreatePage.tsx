import { useEffect, useState, type FormEvent, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import { AlertCircle, ArrowLeft, Building2, Save } from 'lucide-react'
import { branchApi, dictionaryApi, type DictionaryEntry } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'

/**
 * FK-021 (2026-06-05): Új iroda (pénztár / értéktár) felrögzítése — teljes törzsadat-form
 * 5 logikai csoportban, a Pénztár Törzs Adatbázis modulból (FK-020 "Új pénztár" gomb).
 *
 * Backend: POST /branches/simple-cashier (kibővítve). Kötelező: kód, cím, terület.
 * "Tartósan zárva" → is_active=false. Mentés után vissza a listára (/admin/branches).
 */
type FormState = {
  code: string
  name: string
  shortName: string
  isVault: boolean
  address: string
  zipCode: string
  city: string
  phone: string
  email: string
  regionCode: string
  bankCode: string
  hasAfa: boolean
  hasWu: boolean
  hasMg: boolean
  hasPos: boolean
  closedSaturday: boolean
  closedSunday: boolean
  tartosanZarva: boolean
}

const INITIAL: FormState = {
  code: '', name: '', shortName: '', isVault: false,
  address: '', zipCode: '', city: '', phone: '', email: '',
  regionCode: '', bankCode: '',
  hasAfa: false, hasWu: false, hasMg: false, hasPos: false,
  closedSaturday: false, closedSunday: false, tartosanZarva: false,
}

/** Logikai csoport-keret a formon. */
function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <fieldset className="border border-gray-200 rounded-lg p-4">
      <legend className="px-2 text-sm font-semibold text-gray-700">{title}</legend>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">{children}</div>
    </fieldset>
  )
}

function Check({ label, checked, onChange, hint }: { label: string; checked: boolean; onChange: (v: boolean) => void; hint?: string }) {
  return (
    <label className="inline-flex items-start gap-2 cursor-pointer">
      <input type="checkbox" className="form-checkbox h-4 w-4 mt-0.5" checked={checked} onChange={(e) => onChange(e.target.checked)} />
      <span className="text-sm">
        {label}
        {hint ? <span className="block text-xs text-gray-500">{hint}</span> : null}
      </span>
    </label>
  )
}

export default function BranchCreatePage() {
  const navigate = useNavigate()
  const [form, setForm] = useState<FormState>(INITIAL)
  const [regions, setRegions] = useState<DictionaryEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let active = true
    dictionaryApi.getByCategory('REGION')
      .then((list) => {
        if (!active) return
        setRegions(list.filter((r) => r.code !== 'IRODA'))
      })
      .catch((err) => {
        if (!active) return
        logger.error('BranchCreatePage', 'Region-lista betöltési hiba:', err)
        setError(getErrorMessage(err))
      })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [])

  const patch = (values: Partial<FormState>) => setForm((current) => ({ ...current, ...values }))

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setError(null)
    // FR-2 / NFR-3: kötelező mezők — kód, pontos cím, területi besorolás.
    if (!form.code.trim() || !form.address.trim() || !form.regionCode) {
      setError('A pénztár száma, a pontos cím és a területi besorolás megadása kötelező.')
      return
    }
    setSaving(true)
    try {
      const created = await branchApi.createSimpleCashier({
        code: form.code.trim().toUpperCase(),
        address: form.address.trim(),
        regionCode: form.regionCode,
        name: form.name.trim() || undefined,
        city: form.city.trim() || undefined,
        zipCode: form.zipCode.trim() || undefined,
        shortName: form.shortName.trim() || undefined,
        phone: form.phone.trim() || undefined,
        email: form.email.trim() || undefined,
        bankCode: form.bankCode.trim() || undefined,
        isVault: form.isVault,
        // FR-5: "Tartósan zárva" → inaktív.
        isActive: !form.tartosanZarva,
        hasAfa: form.hasAfa,
        hasWu: form.hasWu,
        hasMg: form.hasMg,
        hasPos: form.hasPos,
        closedSaturday: form.closedSaturday,
        closedSunday: form.closedSunday,
      })
      logger.info('BranchCreatePage', `Iroda felrögzítve: ${created.code}`)
      // FR-8: sikeres mentés után vissza a Pénztár Törzs Adatbázis listára (FK-020).
      navigate('/admin/branches')
    } catch (err) {
      logger.error('BranchCreatePage', 'Iroda-felrögzítési hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const disabled = loading || saving

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Building2 />
          Új iroda felrögzítése
        </h1>
        <button type="button" onClick={() => navigate('/admin/branches')} className="form-button-secondary flex items-center gap-2">
          <ArrowLeft size={16} /> Vissza a listára
        </button>
      </div>

      {error && (
        <div className="form-panel border border-red-300 bg-red-50 text-red-700 flex items-start gap-2">
          <AlertCircle size={18} className="mt-0.5 flex-shrink-0" />
          <span>{error}</span>
        </div>
      )}

      <form onSubmit={submit} className="space-y-4">
        {/* 1. Alapadatok */}
        <Section title="1. Alapadatok">
          <label className="block">
            <span className="form-label">Pénztár száma / azonosítója <span className="text-red-600">*</span></span>
            <input type="text" className="form-input uppercase" placeholder="pl. BR099" maxLength={20}
              value={form.code} disabled={disabled}
              onChange={(e) => patch({ code: e.target.value.toUpperCase() })} />
            <span className="text-xs text-gray-500">Csak nagybetűk és számok (pl. BR099). Egyedi a rendszerben.</span>
          </label>
          <label className="block">
            <span className="form-label">Megjelenítendő név</span>
            <input type="text" className="form-input" placeholder='pl. "Szeged Belváros"' maxLength={255}
              value={form.name} disabled={disabled}
              onChange={(e) => patch({ name: e.target.value })} />
            <span className="text-xs text-gray-500">Ha üres, a rendszer „Pénztár &lt;kód&gt;" formára generálja.</span>
          </label>
          <label className="block">
            <span className="form-label">Rövid név</span>
            <input type="text" className="form-input" placeholder="pl. Belváros" maxLength={100}
              value={form.shortName} disabled={disabled}
              onChange={(e) => patch({ shortName: e.target.value })} />
          </label>
          <div className="block">
            <span className="form-label">Iroda típusa <span className="text-red-600">*</span></span>
            <div className="flex gap-4 mt-1">
              <label className="inline-flex items-center gap-2 cursor-pointer">
                <input type="radio" name="isVault" checked={!form.isVault} disabled={disabled}
                  onChange={() => patch({ isVault: false })} />
                <span className="text-sm">Pénztár</span>
              </label>
              <label className="inline-flex items-center gap-2 cursor-pointer">
                <input type="radio" name="isVault" checked={form.isVault} disabled={disabled}
                  onChange={() => patch({ isVault: true })} />
                <span className="text-sm">Értéktár</span>
              </label>
            </div>
          </div>
        </Section>

        {/* 2. Elérhetőség */}
        <Section title="2. Elérhetőség">
          <label className="block md:col-span-2">
            <span className="form-label">Pénztár pontos címe <span className="text-red-600">*</span></span>
            <input type="text" className="form-input" placeholder='pl. "6720 Szeged, Tisza Lajos krt. 1."' maxLength={500}
              value={form.address} disabled={disabled}
              onChange={(e) => patch({ address: e.target.value })} />
          </label>
          <label className="block">
            <span className="form-label">Irányítószám</span>
            <input type="text" className="form-input" placeholder="pl. 6720" maxLength={4} inputMode="numeric"
              value={form.zipCode} disabled={disabled}
              onChange={(e) => patch({ zipCode: e.target.value.replace(/\D/g, '').slice(0, 4) })} />
          </label>
          <label className="block">
            <span className="form-label">Város</span>
            <input type="text" className="form-input" placeholder="pl. Szeged" maxLength={100}
              value={form.city} disabled={disabled}
              onChange={(e) => patch({ city: e.target.value })} />
            <span className="text-xs text-gray-500">Ha üres, a terület nevéből töltjük ki.</span>
          </label>
          <label className="block">
            <span className="form-label">Telefon</span>
            <input type="text" className="form-input" placeholder="pl. 06701234567" maxLength={50}
              value={form.phone} disabled={disabled}
              onChange={(e) => patch({ phone: e.target.value })} />
          </label>
          <label className="block">
            <span className="form-label">Email</span>
            <input type="email" className="form-input" placeholder="pl. szeged@ebc.hu" maxLength={255}
              value={form.email} disabled={disabled}
              onChange={(e) => patch({ email: e.target.value })} />
          </label>
        </Section>

        {/* 3. Területi besorolás */}
        <Section title="3. Területi besorolás">
          <label className="block">
            <span className="form-label">Terület / Régió hozzárendelése <span className="text-red-600">*</span></span>
            <select className="form-input" value={form.regionCode} disabled={disabled}
              onChange={(e) => patch({ regionCode: e.target.value })}>
              <option value="">{loading ? 'Régiók betöltése…' : '— válasszon területet —'}</option>
              {regions.map((r) => (
                <option key={r.id} value={r.code}>{r.nameHu || r.name}</option>
              ))}
            </select>
            <span className="text-xs text-gray-500">A pénztárt ez a terület (értéktárhoz) köti.</span>
          </label>
          <label className="block">
            <span className="form-label">Bankkód</span>
            <input type="text" className="form-input" placeholder="pl. 210" maxLength={50}
              value={form.bankCode} disabled={disabled}
              onChange={(e) => patch({ bankCode: e.target.value })} />
            <span className="text-xs text-gray-500">Banki hivatkozási szám. Ha üres, a kód lesz a bankkód.</span>
          </label>
        </Section>

        {/* 4. Szolgáltatások */}
        <Section title="4. Szolgáltatások">
          <Check label="ÁFA-visszatérítés" checked={form.hasAfa} onChange={(v) => patch({ hasAfa: v })} />
          <Check label="Western Union (WU)" checked={form.hasWu} onChange={(v) => patch({ hasWu: v })} />
          <Check label="MoneyGram (MG)" checked={form.hasMg} onChange={(v) => patch({ hasMg: v })} />
          <Check label="Bankkártya elfogadás (POS)" checked={form.hasPos} onChange={(v) => patch({ hasPos: v })} />
        </Section>

        {/* 5. Nyitvatartás */}
        <Section title="5. Nyitvatartás">
          <Check label="Szombaton zárva" checked={form.closedSaturday} onChange={(v) => patch({ closedSaturday: v })} />
          <Check label="Vasárnap zárva" checked={form.closedSunday} onChange={(v) => patch({ closedSunday: v })} />
          <Check label="Tartósan zárva" checked={form.tartosanZarva}
            hint="Bejelölve: az iroda INAKTÍV státusszal kerül mentésre."
            onChange={(v) => patch({ tartosanZarva: v })} />
        </Section>

        <div className="flex justify-end">
          <button type="submit" className="form-button-primary flex items-center gap-2" disabled={disabled}>
            <Save size={16} />{saving ? 'Mentés…' : 'Pénztár felrögzítése'}
          </button>
        </div>
      </form>
    </div>
  )
}
