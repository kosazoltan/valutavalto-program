import { useMemo, useState } from 'react'
import { Download, Loader2, Save, Upload } from 'lucide-react'
import { toast } from '../../components/ui/toaster'
import { translationApi, type TranslationMap } from '../../services/api/translations'
import { getErrorMessage } from '../../utils/errorHandling'
import { logger } from '../../utils/logger'
import i18n from '../../i18n'

export default function TranslationSettingsPage() {
  const [languageCode, setLanguageCode] = useState('hu')
  const [moduleName, setModuleName] = useState('UI')
  const [translations, setTranslations] = useState<TranslationMap>({})
  const [messageKey, setMessageKey] = useState('common.save')
  const [messageValue, setMessageValue] = useState('')
  const [importJson, setImportJson] = useState('{\n  "common.save": "Mentés"\n}')
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [importing, setImporting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const rows = useMemo(
    () =>
      Object.entries(translations)
        .sort(([left], [right]) => left.localeCompare(right, 'hu'))
        .slice(0, 40),
    [translations],
  )

  const normalizedLanguage = languageCode.trim() || 'hu'
  const normalizedModule = moduleName.trim() || 'UI'

  const loadLanguage = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await translationApi.getLanguage(normalizedLanguage)
      setTranslations(data)
      toast.success('Fordítások betöltve', `${Object.keys(data).length} kulcs`)
    } catch (err) {
      const message = getErrorMessage(err)
      setError(message)
      logger.error('TranslationSettingsPage', 'language load failed', err)
      toast.error('Hiba', message)
    } finally {
      setLoading(false)
    }
  }

  const loadModule = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await translationApi.getModule(normalizedLanguage, normalizedModule)
      setTranslations(data)
      toast.success('Modul fordítások betöltve', `${Object.keys(data).length} kulcs`)
    } catch (err) {
      const message = getErrorMessage(err)
      setError(message)
      logger.error('TranslationSettingsPage', 'module load failed', err)
      toast.error('Hiba', message)
    } finally {
      setLoading(false)
    }
  }

  const saveTranslation = async () => {
    const key = messageKey.trim()
    if (!key || !messageValue.trim()) {
      setError('A kulcs és a fordítási érték kötelező.')
      return
    }

    try {
      setSaving(true)
      setError(null)
      const saved = await translationApi.save({
        languageCode: normalizedLanguage,
        module: normalizedModule,
        messageKey: key,
        messageValue,
      })
      setTranslations((prev) => ({ ...prev, [saved.messageKey]: saved.messageValue }))
      toast.success('Fordítás mentve', saved.messageKey)
    } catch (err) {
      const message = getErrorMessage(err)
      setError(message)
      logger.error('TranslationSettingsPage', 'save failed', err)
      toast.error('Hiba', message)
    } finally {
      setSaving(false)
    }
  }

  const importTranslations = async () => {
    let parsed: TranslationMap
    try {
      const value = JSON.parse(importJson) as unknown
      if (!value || typeof value !== 'object' || Array.isArray(value)) {
        throw new Error('Az import JSON objektum legyen.')
      }
      parsed = Object.fromEntries(
        Object.entries(value as Record<string, unknown>).map(([key, val]) => [key, String(val)]),
      )
    } catch (err) {
      setError(getErrorMessage(err))
      return
    }

    try {
      setImporting(true)
      setError(null)
      const result = await translationApi.importMany(normalizedLanguage, parsed)
      setTranslations((prev) => ({ ...prev, ...parsed }))
      toast.success('Import kész', `${result.imported} kulcs importálva`)
    } catch (err) {
      const message = getErrorMessage(err)
      setError(message)
      logger.error('TranslationSettingsPage', 'import failed', err)
      toast.error('Hiba', message)
    } finally {
      setImporting(false)
    }
  }

  return (
    <div className="space-y-4">
      <div>
        <h2 className="section-title">{i18n.t('literals.forditasok')}</h2>
        <p className="text-sm text-gray-500">
          {i18n.t('literals.backend-i18n-kulcsok-lekerese-es-karbant')}
        </p>
      </div>

      <div className="grid gap-3 lg:grid-cols-[minmax(0,1fr)_minmax(280px,360px)]">
        <section className="rounded border border-gray-200 bg-white p-3">
          <h3 className="mb-3 text-sm font-semibold text-gray-800">
            {i18n.t('literals.lekerdezes')}
          </h3>
          <div className="grid gap-2 sm:grid-cols-[120px_minmax(0,1fr)_auto_auto] sm:items-end">
            <div>
              <label className="form-label" htmlFor="translation-language">
                {i18n.t('literals.nyelv')}
              </label>
              <input
                id="translation-language"
                className="form-input w-full"
                value={languageCode}
                onChange={(event) => setLanguageCode(event.target.value)}
              />
            </div>
            <div>
              <label className="form-label" htmlFor="translation-module">
                {i18n.t('literals.modul-2')}
              </label>
              <input
                id="translation-module"
                className="form-input w-full"
                value={moduleName}
                onChange={(event) => setModuleName(event.target.value)}
              />
            </div>
            <button
              type="button"
              className="form-button inline-flex min-h-10 items-center justify-center gap-1"
              onClick={() => void loadLanguage()}
              disabled={loading}
            >
              {loading ? <Loader2 size={14} className="animate-spin" /> : <Download size={14} />}
              {i18n.t('literals.nyelv')}
            </button>
            <button
              type="button"
              className="form-button inline-flex min-h-10 items-center justify-center gap-1"
              onClick={() => void loadModule()}
              disabled={loading}
            >
              {loading ? <Loader2 size={14} className="animate-spin" /> : <Download size={14} />}
              {i18n.t('literals.modul-2')}
            </button>
          </div>

          <div className="mt-3 grid gap-2 md:hidden">
            {rows.map(([key, value]) => (
              <div key={key} className="rounded border border-gray-200 bg-gray-50 p-3">
                <div className="break-words font-mono text-xs font-semibold text-gray-800">
                  {key}
                </div>
                <div className="mt-1 break-words text-sm text-gray-700">{value}</div>
              </div>
            ))}
          </div>

          <div className="data-grid mt-3 hidden overflow-x-auto md:block">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                    {i18n.t('literals.kulcs')}
                  </th>
                  <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                    {i18n.t('literals.ertek')}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {rows.map(([key, value]) => (
                  <tr key={key}>
                    <td className="px-3 py-2 font-mono text-xs">{key}</td>
                    <td className="px-3 py-2 text-sm">{value}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {rows.length === 0 && (
            <p className="mt-3 rounded border border-gray-200 bg-gray-50 p-3 text-sm text-gray-500">
              {i18n.t('literals.nincs-betoltott-forditas')}
            </p>
          )}
        </section>

        <section className="rounded border border-gray-200 bg-white p-3">
          <h3 className="mb-3 text-sm font-semibold text-gray-800">
            {i18n.t('literals.egyedi-kulcs-mentese')}
          </h3>
          <div className="space-y-2">
            <div>
              <label className="form-label" htmlFor="translation-key">
                {i18n.t('literals.kulcs')}
              </label>
              <input
                id="translation-key"
                className="form-input w-full"
                value={messageKey}
                onChange={(event) => setMessageKey(event.target.value)}
              />
            </div>
            <div>
              <label className="form-label" htmlFor="translation-value">
                {i18n.t('literals.forditas')}
              </label>
              <textarea
                id="translation-value"
                className="form-input min-h-24 w-full"
                value={messageValue}
                onChange={(event) => setMessageValue(event.target.value)}
              />
            </div>
            <button
              type="button"
              className="form-button-primary inline-flex min-h-10 w-full items-center justify-center gap-1"
              onClick={() => void saveTranslation()}
              disabled={saving}
            >
              {saving ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
              {i18n.t('literals.forditas-mentese')}
            </button>
          </div>
        </section>
      </div>

      <section className="rounded border border-gray-200 bg-white p-3">
        <h3 className="mb-3 text-sm font-semibold text-gray-800">
          {i18n.t('literals.json-import')}
        </h3>
        <textarea
          className="form-input min-h-32 w-full font-mono text-xs"
          aria-label="Fordítás JSON import"
          value={importJson}
          onChange={(event) => setImportJson(event.target.value)}
        />
        <button
          type="button"
          className="form-button mt-3 inline-flex min-h-10 items-center justify-center gap-1"
          onClick={() => void importTranslations()}
          disabled={importing}
        >
          {importing ? <Loader2 size={14} className="animate-spin" /> : <Upload size={14} />}
          {i18n.t('literals.import')}
        </button>
      </section>

      {error && <div className="form-error break-words">{error}</div>}
    </div>
  )
}
