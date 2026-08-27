import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { AlertCircle, ArrowLeft, Building2, Save } from 'lucide-react'
import {
  api,
  branchApi,
  dictionaryApi,
  type BranchInfo,
  type BranchUpdateRequest,
  type DictionaryEntry,
} from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import { Check, Section } from './branchFormShared'
import i18n from '../../i18n'

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

type BranchAdminDetails = {
  id: string
  code: string
  name: string
  active: boolean
  companyName?: string
  workerCount?: number
  totalInventoryHuf?: number
  lastSyncAt?: string | null
  openingHours?: string | null
}

const formatHuf = (value: number) => `${value.toLocaleString('hu-HU')} Ft`

const formatDateTime = (value?: string | null) => {
  if (!value) return 'nincs adat'
  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) return value
  return parsed.toLocaleString('hu-HU')
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
  const [branchPath, setBranchPath] = useState<BranchInfo[]>([])
  const [childBranches, setChildBranches] = useState<BranchInfo[]>([])
  const [adminDetails, setAdminDetails] = useState<BranchAdminDetails | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  // FR-4/FR-5: státuszváltás megerősítő kérdés. Nem = vissza a formhoz, változtatás nélkül.
  const [confirmMessage, setConfirmMessage] = useState<string | null>(null)

  useEffect(() => {
    if (!id) return
    let active = true
    Promise.all([
      branchApi.getById(id),
      dictionaryApi.getByCategory('REGION'),
      api.get<BranchInfo[]>(`/branches/${id}/path`),
      api.get<BranchInfo[]>(`/branches/${id}/children`),
      // FK-038: a /admin/branches/{id} ADMIN-only (CompanyAdminController osztály-szintű
      // @PreAuthorize("hasRole('ADMIN')")), ezért foertektar/ugyvezeto felhasználónak 403-at ad.
      // Ez a hívás best-effort (csak admin metaadatot tölt), ezért a globális 403-toast itt
      // félrevezető — `_skipGlobal403Toast: true`-val elnyomjuk; a Promise.all tovább tölt.
      api
        .get<BranchAdminDetails>(`/admin/branches/${id}`, { _skipGlobal403Toast: true })
        .catch((err: unknown) => {
          // FK-038 (Copilot review): best-effort admin-metaadat. Foertektar/ugyvezeto 403-at kap
          // (VÁRT állapot, ADMIN-only végpont) — ezért warn, nem error, hogy ne legyen zajos a Sentry/console.
          logger.warn(
            'BranchEditPage',
            'Admin branch részlet nem tölthető (best-effort, pl. 403 ADMIN-only):',
            err,
          )
          return null
        }),
    ])
      .then(([loaded, regionList, pathResponse, childrenResponse, adminResponse]) => {
        if (!active) return
        setBranch(loaded)
        setForm(formFromBranch(loaded))
        setRegions(regionList.filter((r) => r.code !== 'IRODA'))
        setBranchPath(pathResponse.data ?? [])
        setChildBranches(childrenResponse.data ?? [])
        setAdminDetails(adminResponse?.data ?? null)
      })
      .catch((err) => {
        if (!active) return
        logger.error('BranchEditPage', 'Iroda-betöltési hiba:', err)
        setError(getErrorMessage(err))
      })
      .finally(() => {
        if (active) setLoading(false)
      })
    return () => {
      active = false
    }
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
    // FR-10 / NFR-3: kötelező mezők — név, pontos cím, területi besorolás (a kód read-only).
    // Copilot #1076: legacy/hiányos irodánál a region üres lehet — ilyenkor a mentéshez
    // kötelező területet választani, hogy a törzsadat ne maradjon besorolás nélkül.
    if (!form.name.trim() || !form.address.trim() || !form.regionCode) {
      setError('A megjelenítendő név, a pontos cím és a területi besorolás megadása kötelező.')
      return
    }
    // FR-4/FR-5: státuszváltás mindkét irányban megerősítő kérdéssel.
    const originalIsActive = branch.isActive ?? true
    const newIsActive = !form.tartosanZarva
    if (originalIsActive !== newIsActive) {
      setConfirmMessage(
        newIsActive
          ? 'Biztosan aktívra állítja ezt az irodát?'
          : 'Biztosan inaktívra állítja ezt az irodát?',
      )
      return
    }
    void submitUpdate(form)
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">{i18n.t('literals.betoltes')}</div>
      </div>
    )
  }

  const disabled = saving

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Building2 />
          {i18n.t('literals.iroda-szerkesztese')}
          {branch ? ` — ${branch.code}` : ''}
        </h1>
        <button
          type="button"
          onClick={() => navigate('/admin/branches')}
          className="form-button-secondary flex items-center gap-2"
        >
          <ArrowLeft size={16} />
          {i18n.t('literals.vissza-a-listara')}
        </button>
      </div>

      {error && (
        <div
          className="form-panel border border-red-300 bg-red-50 text-red-700 flex items-start gap-2"
          role="alert"
          aria-live="assertive"
        >
          <AlertCircle size={18} className="mt-0.5 flex-shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {form && branch && (
        <form onSubmit={submit} className="space-y-4">
          <Section title="Szervezeti kapcsolat">
            <div className="md:col-span-2 space-y-3">
              <div>
                <div className="text-xs font-semibold uppercase text-gray-500">
                  {i18n.t('literals.utvonal')}
                </div>
                <div
                  className="mt-1 flex flex-wrap items-center gap-1 text-sm text-gray-700"
                  data-testid="branch-path"
                >
                  {branchPath.length > 0 ? (
                    branchPath.map((item, index) => (
                      <span key={item.id} className="inline-flex items-center gap-1">
                        <span className="rounded border border-gray-200 bg-gray-50 px-2 py-1 font-medium">
                          {item.code}
                          {i18n.t('literals.lit-17')}
                          {item.name}
                        </span>
                        {index < branchPath.length - 1 && (
                          <span className="text-gray-400">{i18n.t('literals.lit-4')}</span>
                        )}
                      </span>
                    ))
                  ) : (
                    <span className="text-gray-500">
                      {i18n.t('literals.nincs-szervezeti-utvonal-adat')}
                    </span>
                  )}
                </div>
              </div>
              <div>
                <div className="text-xs font-semibold uppercase text-gray-500">
                  {i18n.t('literals.kozvetlen-alirodak')}
                </div>
                <div className="mt-1 flex flex-wrap gap-2" data-testid="branch-children">
                  {childBranches.length > 0 ? (
                    childBranches.map((item) => (
                      <span
                        key={item.id}
                        className="rounded border border-blue-100 bg-blue-50 px-2 py-1 text-sm font-medium text-blue-800"
                      >
                        {item.code}
                        {i18n.t('literals.lit-17')}
                        {item.name}
                      </span>
                    ))
                  ) : (
                    <span className="text-sm text-gray-500">
                      {i18n.t('literals.nincs-kozvetlen-aliroda')}
                    </span>
                  )}
                </div>
              </div>
            </div>
          </Section>

          <Section title="Admin statisztika">
            {adminDetails ? (
              <>
                <div>
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    {i18n.t('literals.ceg')}
                  </div>
                  <div className="mt-1 text-sm font-medium text-gray-800">
                    {adminDetails.companyName ?? '-'}
                  </div>
                </div>
                <div>
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    {i18n.t('literals.statusz')}
                  </div>
                  <div className="mt-1">
                    <span className={`badge ${adminDetails.active ? 'badge-green' : 'badge-red'}`}>
                      {adminDetails.active ? 'Aktív' : 'Inaktív'}
                    </span>
                  </div>
                </div>
                <div>
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    {i18n.t('literals.aktiv-munkatarsak')}
                  </div>
                  <div className="mt-1 text-sm font-medium text-gray-800">
                    {adminDetails.workerCount ?? 0}
                    {i18n.t('literals.fo')}
                  </div>
                </div>
                <div>
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    {i18n.t('literals.teljes-keszlet-huf')}
                  </div>
                  <div className="mt-1 text-sm font-medium text-gray-800">
                    {formatHuf(adminDetails.totalInventoryHuf ?? 0)}
                  </div>
                </div>
                <div>
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    {i18n.t('literals.utolso-szinkron')}
                  </div>
                  <div className="mt-1 text-sm font-medium text-gray-800">
                    {formatDateTime(adminDetails.lastSyncAt)}
                  </div>
                </div>
                <div>
                  <div className="text-xs font-semibold uppercase text-gray-500">
                    {i18n.t('literals.nyitvatartas')}
                  </div>
                  <div className="mt-1 text-sm font-medium text-gray-800">
                    {adminDetails.openingHours ?? '-'}
                  </div>
                </div>
              </>
            ) : (
              <div className="md:col-span-2 text-sm text-gray-500">
                {i18n.t('literals.admin-statisztika-nem-erheto-el')}
              </div>
            )}
          </Section>

          {/* 1. Alapadatok */}
          <Section title="1. Alapadatok">
            <label className="block">
              <span className="form-label">{i18n.t('literals.penztar-szama-azonositoja-2')}</span>
              {/* FR-3: a kód nem szerkeszthető — read-only mező, nem része a payloadnak. */}
              <input
                type="text"
                className="form-input bg-gray-100 text-gray-500"
                value={branch.code}
                readOnly
                disabled
              />
              <span className="text-xs text-gray-500">
                {i18n.t('literals.a-penztar-kodja-nem-modosithato')}
              </span>
            </label>
            <label className="block">
              <span className="form-label">
                {i18n.t('literals.megjelenitendo-nev-2')}
                <span className="text-red-600">{i18n.t('literals.lit-3')}</span>
              </span>
              <input
                type="text"
                className="form-input"
                maxLength={255}
                value={form.name}
                disabled={disabled}
                onChange={(e) => patch({ name: e.target.value })}
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.rovid-nev')}</span>
              <input
                type="text"
                className="form-input"
                placeholder="pl. Belváros"
                maxLength={100}
                value={form.shortName}
                disabled={disabled}
                onChange={(e) => patch({ shortName: e.target.value })}
              />
            </label>
            <div className="block">
              <span className="form-label">{i18n.t('literals.iroda-tipusa-2')}</span>
              <div className="flex gap-4 mt-1">
                <label className="inline-flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="isVault"
                    checked={!form.isVault}
                    disabled={disabled}
                    onChange={() => patch({ isVault: false })}
                  />
                  <span className="text-sm">{i18n.t('literals.penztar-2')}</span>
                </label>
                <label className="inline-flex items-center gap-2 cursor-pointer">
                  <input
                    type="radio"
                    name="isVault"
                    checked={form.isVault}
                    disabled={disabled}
                    onChange={() => patch({ isVault: true })}
                  />
                  <span className="text-sm">{i18n.t('literals.ertektar')}</span>
                </label>
              </div>
            </div>
          </Section>

          {/* 2. Elérhetőség */}
          <Section title="2. Elérhetőség">
            <label className="block md:col-span-2">
              <span className="form-label">
                {i18n.t('literals.penztar-pontos-cime')}
                <span className="text-red-600">{i18n.t('literals.lit-3')}</span>
              </span>
              <input
                type="text"
                className="form-input"
                placeholder='pl. "6720 Szeged, Tisza Lajos krt. 1."'
                maxLength={500}
                value={form.address}
                disabled={disabled}
                onChange={(e) => patch({ address: e.target.value })}
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.iranyitoszam')}</span>
              <input
                type="text"
                className="form-input"
                placeholder="pl. 6720"
                maxLength={4}
                inputMode="numeric"
                value={form.zipCode}
                disabled={disabled}
                onChange={(e) => patch({ zipCode: e.target.value.replace(/\D/g, '').slice(0, 4) })}
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.varos')}</span>
              <input
                type="text"
                className="form-input"
                placeholder="pl. Szeged"
                maxLength={100}
                value={form.city}
                disabled={disabled}
                onChange={(e) => patch({ city: e.target.value })}
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.telefon')}</span>
              <input
                type="text"
                className="form-input"
                placeholder="pl. 06701234567"
                maxLength={50}
                value={form.phone}
                disabled={disabled}
                onChange={(e) => patch({ phone: e.target.value })}
              />
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.email')}</span>
              <input
                type="email"
                className="form-input"
                placeholder="pl. szeged@ebc.hu"
                maxLength={255}
                value={form.email}
                disabled={disabled}
                onChange={(e) => patch({ email: e.target.value })}
              />
            </label>
          </Section>

          {/* 3. Területi besorolás */}
          <Section title="3. Területi besorolás">
            <label className="block">
              <span className="form-label">
                {i18n.t('literals.terulet-regio-hozzarendelese')}
                <span className="text-red-600">{i18n.t('literals.lit-3')}</span>
              </span>
              <select
                className="form-input"
                value={form.regionCode}
                disabled={disabled}
                onChange={(e) => patch({ regionCode: e.target.value })}
                aria-label="Terület / Régió hozzárendelése"
              >
                <option value="">{i18n.t('literals.valasszon-teruletet')}</option>
                {regions.map((r) => (
                  <option key={r.id} value={r.code}>
                    {r.nameHu || r.name}
                  </option>
                ))}
              </select>
              <span className="text-xs text-gray-500">
                {i18n.t('literals.a-penztart-ez-a-terulet-ertektarhoz-koti')}
              </span>
            </label>
            <label className="block">
              <span className="form-label">{i18n.t('literals.bankkod')}</span>
              <input
                type="text"
                className="form-input"
                placeholder="pl. 210"
                maxLength={20}
                value={form.bankCode}
                disabled={disabled}
                onChange={(e) => patch({ bankCode: e.target.value })}
              />
              <span className="text-xs text-gray-500">
                {i18n.t('literals.banki-hivatkozasi-szam')}
              </span>
            </label>
          </Section>

          {/* 4. Szolgáltatások */}
          <Section title="4. Szolgáltatások">
            <Check
              label="ÁFA-visszatérítés"
              checked={form.hasAfa}
              onChange={(v) => patch({ hasAfa: v })}
            />
            <Check
              label="Western Union (WU)"
              checked={form.hasWu}
              onChange={(v) => patch({ hasWu: v })}
            />
            <Check
              label="MoneyGram (MG)"
              checked={form.hasMg}
              onChange={(v) => patch({ hasMg: v })}
            />
            <Check
              label="Bankkártya elfogadás (POS)"
              checked={form.hasPos}
              onChange={(v) => patch({ hasPos: v })}
            />
          </Section>

          {/* 5. Nyitvatartás */}
          <Section title="5. Nyitvatartás">
            <Check
              label="Szombaton zárva"
              checked={form.closedSaturday}
              onChange={(v) => patch({ closedSaturday: v })}
            />
            <Check
              label="Vasárnap zárva"
              checked={form.closedSunday}
              onChange={(v) => patch({ closedSunday: v })}
            />
            <Check
              label="Tartósan zárva"
              checked={form.tartosanZarva}
              hint="Bejelölve: az iroda INAKTÍV státuszra vált (megerősítő kérdéssel)."
              onChange={(v) => patch({ tartosanZarva: v })}
            />
          </Section>

          <div className="flex justify-end">
            <button
              type="submit"
              className="form-button-primary flex items-center gap-2"
              disabled={disabled}
            >
              <Save size={16} />
              {saving ? 'Mentés…' : 'Mentés'}
            </button>
          </div>
        </form>
      )}

      {/* FR-4/FR-5: státuszváltás megerősítő kérdés — Igen = mentés, Nem = vissza a formhoz. */}
      {confirmMessage && form && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
          role="dialog"
          aria-modal="true"
        >
          <div className="bg-white rounded-lg p-6 w-full max-w-md space-y-4">
            <p className="text-gray-800">{confirmMessage}</p>
            <div className="flex justify-end gap-2">
              <button type="button" className="form-button" onClick={() => setConfirmMessage(null)}>
                {i18n.t('literals.nem')}
              </button>
              <button
                type="button"
                className="form-button-primary"
                onClick={() => {
                  setConfirmMessage(null)
                  void submitUpdate(form)
                }}
              >
                {i18n.t('literals.igen')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
