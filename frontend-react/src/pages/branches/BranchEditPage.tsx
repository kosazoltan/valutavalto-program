import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { AlertCircle, ArrowLeft, Building2, Save } from 'lucide-react'
import { branchApi, dictionaryApi, type BranchInfo, type BranchUpdateRequest, type DictionaryEntry } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { Check, Section } from './branchFormShared'

/**
 * FK-022 (2026-06-10): Meglévő iroda adatainak szerkesztése — a Pénztár Törzs Adatbázis
 * (FK-020) lista "Szerkesztés" gombjáról nyílik, az FK-021 formmal azonos 5 logikai
 * csoportban, a meglévő iroda adataival előtöltve.
 *
 * - A pénztár kódja NEM szerkeszthető (FR-3) — read-only mező, nem kerül a payloadba.
 * - Státuszváltáskor (Aktív ↔ Inaktív, "Tartósan zárva") megerősítő kérdés (FR-4/FR-5).
 * - Sikeres mentés után vissza a listára (FR-6). Backend: PUT /branches/{id} + audit (FR-7).
 */
type FormState = {
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

function formFromBranch(b: BranchInfo): FormState {
  return {
    name: b.name ?? '',
    shortName: b.shortName ?? '',
    isVault: b.isVault ?? false,
    address: b.address ?? '',
    zipCode: b.zipCode ?? '',
    city: b.city ?? '',
    phone: b.phone ?? '',
    email: b.email ?? '',
    // A Branch.region a szöveges REGION dictionary-kód (pl. SZEGED) — ez tölti elő a selectet.
    regionCode: b.region ?? '',
    bankCode: b.bankCode ?? '',
    hasAfa: b.hasAfa ?? false,
    hasWu: b.hasWu ?? false,
    hasMg: b.hasMg ?? false,
    hasPos: b.hasPos ?? false,
    closedSaturday: b.closedSaturday ?? false,
    closedSunday: b.closedSunday ?? false,
    // FR-4/FR-11: "Tartósan zárva" = inaktív iroda.
    tartosanZarva: !(b.isActive ?? true),
  }
}

export default function BranchEditPage() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const [branch, setBranch] = useState<BranchInfo | null>(null)
  const [form, setForm] = useState<FormState | null>(null)
  const [regions, setRegions] = useState<DictionaryEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  // FR-4/FR-5: státuszváltás megerősítő kérdés. Nem = vissza a formhoz, változtatás nélkül.
  const [confirmMessage, setConfirmMessage] = useState<string | null>(null)

  useEffect(() => {
    if (!id) return
    let active = true
    Promise.all([branchApi.getById(id), dictionaryApi.getByCategory('REGION')])
      .then(([loaded, regionList]) => {
        if (!active) return
        setBranch(loaded)
        setForm(formFromBranch(loaded))
        setRegions(regionList.filter((r) => r.code !== 'IRODA'))
      })
      .catch((err) => {
        if (!active) return
        logger.error('BranchEditPage', 'Iroda-betöltési hiba:', err)
        setError(getErrorMessage(err))
      })
      .finally(() => { if (active) setLoading(false) })
    return () => { active = false }
  }, [id])

  const patch = (values: Partial<FormState>) =>
    setForm((current) => (current ? { ...current, ...values } : current))

  const submitUpdate = async (current: FormState) => {
    if (!id) return
    setSaving(true)
    try {
      const payload: BranchUpdateRequest = {
        name: current.name.trim(),
        shortName: current.shortName.trim(),
        address: current.address.trim(),
        zipCode: current.zipCode.trim(),
        city: current.city.trim(),
        phone: current.phone.trim(),
        email: current.email.trim(),
        bankCode: current.bankCode.trim(),
        isVault: current.isVault,
        // FR-11: "Tartósan zárva" → is_active=false (és fordítva).
        isActive: !current.tartosanZarva,
        hasAfa: current.hasAfa,
        hasWu: current.hasWu,
        hasMg: current.hasMg,
        hasPos: current.hasPos,
        closedSaturday: current.closedSaturday,
        closedSunday: current.closedSunday,
      }
      // Területi besorolás: csak akkor küldjük, ha a felhasználó választott és az eltér a
      // jelenlegitől — így a legacy (dictionary-n kívüli) region-érték érintetlen marad.
      if (current.regionCode && current.regionCode !== (branch?.region ?? '')) {
        payload.regionCode = current.regionCode
      }
      const updated = await branchApi.update(id, payload)
      logger.info('BranchEditPage', `Iroda módosítva: ${updated.code}`)
      // FR-6: sikeres mentés után vissza a Pénztár Törzs Adatbázis listára (FK-020).
      navigate('/admin/branches')
    } catch (err) {
      logger.error('BranchEditPage', 'Iroda-módosítási hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setSaving(false)
    }
  }

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!form || !branch) return
    setError(null)
    // FR-10 / NFR-3: kötelező mezők — név, pontos cím (a kód read-only, a terület előtöltött).
    if (!form.name.trim() || !form.address.trim()) {
      setError('A megjelenítendő név és a pontos cím megadása kötelező.')
      return
    }
    // FR-4/FR-5: státuszváltás mindkét irányban megerősítő kérdéssel.
    const originalIsActive = branch.isActive ?? true
    const newIsActive = !form.tartosanZarva
    if (originalIsActive !== newIsActive) {
      setConfirmMessage(newIsActive
        ? 'Biztosan aktívra állítja ezt az irodát?'
        : 'Biztosan inaktívra állítja ezt az irodát?')
      return
    }
    void submitUpdate(form)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Betöltés...</div>
      </div>
    )
  }

  const disabled = saving

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Building2 />
          Iroda szerkesztése{branch ? ` — ${branch.code}` : ''}
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

      {form && branch && (
        <form onSubmit={submit} className="space-y-4">
          {/* 1. Alapadatok */}
          <Section title="1. Alapadatok">
            <label className="block">
              <span className="form-label">Pénztár száma / azonosítója</span>
              {/* FR-3: a kód nem szerkeszthető — read-only mező, nem része a payloadnak. */}
              <input type="text" className="form-input bg-gray-100 text-gray-500" value={branch.code} readOnly disabled />
              <span className="text-xs text-gray-500">A pénztár kódja nem módosítható.</span>
            </label>
            <label className="block">
              <span className="form-label">Megjelenítendő név <span className="text-red-600">*</span></span>
              <input type="text" className="form-input" maxLength={255}
                value={form.name} disabled={disabled}
                onChange={(e) => patch({ name: e.target.value })} />
            </label>
            <label className="block">
              <span className="form-label">Rövid név</span>
              <input type="text" className="form-input" placeholder="pl. Belváros" maxLength={100}
                value={form.shortName} disabled={disabled}
                onChange={(e) => patch({ shortName: e.target.value })} />
            </label>
            <div className="block">
              <span className="form-label">Iroda típusa</span>
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
              <span className="form-label">Terület / Régió hozzárendelése</span>
              <select className="form-input" value={form.regionCode} disabled={disabled}
                onChange={(e) => patch({ regionCode: e.target.value })}
                aria-label="Terület / Régió hozzárendelése">
                <option value="">— válasszon területet —</option>
                {regions.map((r) => (
                  <option key={r.id} value={r.code}>{r.nameHu || r.name}</option>
                ))}
              </select>
              <span className="text-xs text-gray-500">A pénztárt ez a terület (értéktárhoz) köti.</span>
            </label>
            <label className="block">
              <span className="form-label">Bankkód</span>
              <input type="text" className="form-input" placeholder="pl. 210" maxLength={20}
                value={form.bankCode} disabled={disabled}
                onChange={(e) => patch({ bankCode: e.target.value })} />
              <span className="text-xs text-gray-500">Banki hivatkozási szám.</span>
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
              hint="Bejelölve: az iroda INAKTÍV státuszra vált (megerősítő kérdéssel)."
              onChange={(v) => patch({ tartosanZarva: v })} />
          </Section>

          <div className="flex justify-end">
            <button type="submit" className="form-button-primary flex items-center gap-2" disabled={disabled}>
              <Save size={16} />{saving ? 'Mentés…' : 'Mentés'}
            </button>
          </div>
        </form>
      )}

      {/* FR-4/FR-5: státuszváltás megerősítő kérdés — Igen = mentés, Nem = vissza a formhoz. */}
      {confirmMessage && form && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" role="dialog" aria-modal="true">
          <div className="bg-white rounded-lg p-6 w-full max-w-md space-y-4">
            <p className="text-gray-800">{confirmMessage}</p>
            <div className="flex justify-end gap-2">
              <button type="button" className="form-button"
                onClick={() => setConfirmMessage(null)}>
                Nem
              </button>
              <button type="button" className="form-button-primary"
                onClick={() => {
                  setConfirmMessage(null)
                  void submitUpdate(form)
                }}>
                Igen
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
