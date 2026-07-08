import { useEffect, useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { AlertCircle, ArrowLeft, Building2, Save } from 'lucide-react'
import { branchApi, dictionaryApi, type DictionaryEntry } from '../../services/api/index'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'

/**
 * Bali Henriett 2. pont (2026-05-27): manuális lakossági pénztár-felrögzítés
 * értéktáros / főértéktáros által. Csak 3 kötelező mező (kód, cím, terület),
 * a backend kitölti a default-okat (HU/PENZTAR/ACTIVE/today/bankCode=code).
 * A frissen rögzített pénztár automatikusan megjelenik a megfelelő értéktár
 * területi szűrt listáiban (FK-005/B4).
 */
type FormState = {
  code: string
  address: string
  regionCode: string
  name: string
  city: string
  zipCode: string
}

const INITIAL: FormState = {
  code: '',
  address: '',
  regionCode: '',
  name: '',
  city: '',
  zipCode: '',
}

export default function NewCashierBranchPage() {
  const navigate = useNavigate()
  const [form, setForm] = useState<FormState>(INITIAL)
  const [regions, setRegions] = useState<DictionaryEntry[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  useEffect(() => {
    let active = true
    dictionaryApi
      .getByCategory('REGION')
      .then((list) => {
        if (!active) return
        // IRODA = központi iroda kategória, nem terület → kihagyjuk a pénztár-régió-választóból.
        setRegions(list.filter((r) => r.code !== 'IRODA'))
      })
      .catch((err) => {
        if (!active) return
        logger.error('NewCashierBranchPage', 'Region-lista betöltési hiba:', err)
        setError(getErrorMessage(err))
      })
      .finally(() => {
        if (active) setLoading(false)
      })
    return () => {
      active = false
    }
  }, [])

  const patch = (values: Partial<FormState>) => setForm((current) => ({ ...current, ...values }))

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setError(null)
    setSuccess(null)
    if (!form.code.trim() || !form.address.trim() || !form.regionCode) {
      setError('A pénztár száma, címe és a területi besorolás megadása kötelező.')
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
      })
      setSuccess(
        `A(z) "${created.code}" pénztár sikeresen felrögzítve a(z) ${form.regionCode} területhez.`,
      )
      setForm(INITIAL)
    } catch (err) {
      logger.error('NewCashierBranchPage', 'Pénztár-felrögzítési hiba:', err)
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
          Új pénztár felrögzítése
        </h1>
        <button
          type="button"
          onClick={() => navigate(-1)}
          className="form-button-secondary flex items-center gap-2"
        >
          <ArrowLeft size={16} /> Vissza
        </button>
      </div>

      <p className="text-sm text-gray-600">
        Ha új lakossági pénztár (iroda) nyílik a területéhez tartozóan, itt rögzítheti fel a
        rendszerbe. A felrögzítés után a pénztár automatikusan megjelenik a területi szűrt listákban
        — pl. az „Átadás-átvétel" képernyő Kérő / Cél iroda legördülőjében.
      </p>

      {error && (
        <div className="form-panel border border-red-300 bg-red-50 text-red-700 flex items-start gap-2">
          <AlertCircle size={18} className="mt-0.5 flex-shrink-0" />
          <span>{error}</span>
        </div>
      )}
      {success && (
        <div className="form-panel border border-green-300 bg-green-50 text-green-800">
          {success}
        </div>
      )}

      <form onSubmit={submit} className="form-panel space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <label className="block">
            <span className="form-label">
              Pénztár száma / azonosítója <span className="text-red-600">*</span>
            </span>
            <input
              type="text"
              className="form-input uppercase"
              placeholder="pl. BR099"
              value={form.code}
              disabled={disabled}
              onChange={(e) => patch({ code: e.target.value.toUpperCase() })}
              maxLength={20}
            />
            <span className="text-xs text-gray-500">
              Csak nagybetűk és számok (pl. BR099, TESCO12). Egyedi a rendszerben.
            </span>
          </label>
          <label className="block">
            <span className="form-label">Megjelenítendő név (opcionális)</span>
            <input
              type="text"
              className="form-input"
              placeholder='pl. "Szeged Belváros"'
              value={form.name}
              disabled={disabled}
              onChange={(e) => patch({ name: e.target.value })}
              maxLength={255}
            />
            <span className="text-xs text-gray-500">
              Ha üresen hagyja, a rendszer „Pénztár &lt;kód&gt;" formára generálja.
            </span>
          </label>
          <label className="block md:col-span-2">
            <span className="form-label">
              Pénztár pontos címe <span className="text-red-600">*</span>
            </span>
            <input
              type="text"
              className="form-input"
              placeholder='pl. "6720 Szeged, Tisza Lajos krt. 47."'
              value={form.address}
              disabled={disabled}
              onChange={(e) => patch({ address: e.target.value })}
              maxLength={500}
            />
          </label>
          <label className="block">
            <span className="form-label">
              Terület / Régió hozzárendelése <span className="text-red-600">*</span>
            </span>
            <select
              className="form-input"
              value={form.regionCode}
              disabled={disabled}
              onChange={(e) => patch({ regionCode: e.target.value })}
            >
              <option value="">{loading ? 'Régiók betöltése…' : '— válasszon területet —'}</option>
              {regions.map((r) => (
                <option key={r.id} value={r.code}>
                  {r.nameHu || r.name}
                </option>
              ))}
            </select>
            <span className="text-xs text-gray-500">
              A pénztárt ez a területhez (értéktárhoz) köti.
            </span>
          </label>
          <label className="block">
            <span className="form-label">Város (opcionális)</span>
            <input
              type="text"
              className="form-input"
              placeholder="pl. Szeged"
              value={form.city}
              disabled={disabled}
              onChange={(e) => patch({ city: e.target.value })}
              maxLength={100}
            />
            <span className="text-xs text-gray-500">Ha üres, a terület nevéből töltjük ki.</span>
          </label>
          <label className="block">
            <span className="form-label">Irányítószám (opcionális)</span>
            <input
              type="text"
              className="form-input"
              placeholder="pl. 6720"
              value={form.zipCode}
              disabled={disabled}
              onChange={(e) => patch({ zipCode: e.target.value.replace(/\D/g, '').slice(0, 4) })}
              maxLength={4}
              inputMode="numeric"
            />
          </label>
        </div>
        <div className="flex justify-end">
          <button
            type="submit"
            className="form-button-primary flex items-center gap-2"
            disabled={disabled}
          >
            <Save size={16} />
            {saving ? 'Mentés…' : 'Pénztár felrögzítése'}
          </button>
        </div>
      </form>
    </div>
  )
}
