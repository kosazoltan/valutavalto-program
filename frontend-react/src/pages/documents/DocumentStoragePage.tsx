import { useState, useEffect, useCallback, useRef } from 'react'
import { FileText, Upload, Download, Trash2, Search, Eye, Filter, FolderOpen, File, Image, FileSpreadsheet } from 'lucide-react'
import { documentStorageApi, Document } from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '@/utils/safeArray'
import { useTranslation } from 'react-i18next'

const FILE_TYPE_ICONS: Record<string, typeof File> = {
  pdf: FileText,
  xlsx: FileSpreadsheet,
  xls: FileSpreadsheet,
  csv: FileSpreadsheet,
  jpg: Image,
  jpeg: Image,
  png: Image,
}

const DOCUMENT_TYPES = [
  { value: '', label: 'Összes típus' },
  { value: 'ID_CARD', label: 'Személyi igazolvány' },
  { value: 'PASSPORT', label: 'Útlevél' },
  { value: 'DRIVING_LICENSE', label: 'Jogosítvány' },
  { value: 'ADDRESS_CARD', label: 'Lakcímkártya' },
  { value: 'COMPANY_EXTRACT', label: 'Cégkivonat' },
  { value: 'AUTHORIZATION', label: 'Meghatalmazás' },
  { value: 'RECEIPT', label: 'Bizonylat' },
  { value: 'CONTRACT', label: 'Szerződés' },
  { value: 'AML_REPORT', label: 'AML jelentés' },
  { value: 'OTHER', label: 'Egyéb' },
]

export default function DocumentStoragePage() {
  const { t } = useTranslation()
  const [documents, setDocuments] = useState<Document[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [typeFilter, setTypeFilter] = useState('')
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [previewName, setPreviewName] = useState('')
  const [uploading, setUploading] = useState(false)
  const [dragActive, setDragActive] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const loadData = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      setDocuments(await documentStorageApi.list())
    } catch (err) {
      logger.error('DocumentStoragePage', 'Dokumentumok betöltési hiba:', err)
      setError('Hiba a dokumentumok betöltésekor')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadData()
  }, [loadData])

  const handleUpload = async (files: FileList | null) => {
    if (!files || files.length === 0) return
    try {
      setUploading(true)
      setError(null)
      for (let i = 0; i < files.length; i++) {
        const f = files[i]
        if (f) await documentStorageApi.upload(f)
      }
      await loadData()
      toast.success('Feltöltés sikeres', `${files.length} dokumentum feltöltve`)
    } catch (err) {
      logger.error('DocumentStoragePage', 'Feltöltési hiba:', err)
      setError('Hiba a feltöltésnél. Kérjük ellenőrizze a fájlt.')
      toast.error('Feltöltési hiba', getErrorMessage(err))
    } finally {
      setUploading(false)
    }
  }

  const handleFileInput = (e: React.ChangeEvent<HTMLInputElement>) => {
    void handleUpload(e.target.files)
    e.target.value = ''
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setDragActive(false)
    void handleUpload(e.dataTransfer.files)
  }

  const handleDownload = async (id: string, fileName: string) => {
    try {
      setError(null)
      const blob = await documentStorageApi.download(id)
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = fileName
      a.click()
      window.URL.revokeObjectURL(url)
    } catch (err) {
      logger.error('DocumentStoragePage', 'Letöltési hiba:', err)
      setError('Hiba a letöltésnél')
    }
  }

  const handlePreview = async (doc: Document) => {
    const ext = doc.fileName.split('.').pop()?.toLowerCase() || ''
    if (['jpg', 'jpeg', 'png', 'gif', 'pdf'].includes(ext)) {
      try {
        const blob = await documentStorageApi.download(doc.id)
        const url = window.URL.createObjectURL(blob)
        setPreviewUrl(url)
        setPreviewName(doc.fileName)
      } catch (err) {
        toast.error('Előnézet hiba', getErrorMessage(err))
      }
    } else {
      toast.warning('Előnézet', 'Csak kép és PDF fájlokhoz érhető el előnézet')
    }
  }

  const handleDelete = async (id: string) => {
    if (!confirm('Biztosan törli ezt a dokumentumot?')) return
    try {
      setError(null)
      await documentStorageApi.delete(id)
      toast.success('Dokumentum törölve')
      await loadData()
    } catch (err) {
      setError(getErrorMessage(err))
    }
  }

  const formatFileSize = (bytes: number): string => {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / 1048576).toFixed(1)} MB`
  }

  const getFileIcon = (fileName: string) => {
    const ext = fileName.split('.').pop()?.toLowerCase() || ''
    const IconComp = FILE_TYPE_ICONS[ext] || File
    return <IconComp size={16} />
  }

  const filtered = safeArray<Document>(documents).filter(d => {
    if (searchTerm && !d.fileName.toLowerCase().includes(searchTerm.toLowerCase())) return false
    if (typeFilter && d.entityType !== typeFilter) return false
    return true
  })

  const totalSize = filtered.reduce((sum, d) => sum + (d.fileSize || 0), 0)

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><FolderOpen />{t('documents.dokumentumtar')}</h1>
        <div className="flex gap-2 items-center">
          <span className="text-sm text-gray-500">{filtered.length} {t('documents.dokumentum')}{formatFileSize(totalSize)})</span>
          <button onClick={() => fileInputRef.current?.click()} disabled={uploading} className="form-button-primary">
            <Upload size={16} /> {uploading ? 'Feltöltés...' : 'Feltöltés'}
          </button>
          <input ref={fileInputRef} type="file" className="hidden" multiple onChange={handleFileInput} />
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">{error}</div>
      )}

      {/* Drag & drop zone */}
      <div
        className={`border-2 border-dashed rounded-lg p-6 text-center transition-colors ${dragActive ? 'border-blue-400 bg-blue-50' : 'border-gray-300'}`}
        onDragOver={e => { e.preventDefault(); setDragActive(true) }}
        onDragLeave={() => setDragActive(false)}
        onDrop={handleDrop}
      >
        <Upload size={32} className="mx-auto text-gray-400 mb-2" />
        <p className="text-gray-500">{t('documents.huzzaIdeAFajlokatVagyKattintsonAFeltoltesGombra')}</p>
        <p className="text-xs text-gray-400 mt-1">{t('documents.pdfJpgPngXlsxCsvMax10Mb')}</p>
      </div>

      {/* Filters */}
      <div className="flex gap-2 items-center">
        <Search size={16} className="text-gray-400" />
        <input className="form-input flex-1" placeholder="Keresés fájlnév alapján..." value={searchTerm} onChange={e => setSearchTerm(e.target.value)} />
        <Filter size={16} className="text-gray-400" />
        <select className="form-input w-48" value={typeFilter} onChange={e => setTypeFilter(e.target.value)}>
          {DOCUMENT_TYPES.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
        </select>
      </div>

      {/* Table */}
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          {filtered.length === 0 ? (
            <div className="text-center text-gray-500 py-8">{t('documents.nincsDokumentum')}</div>
          ) : (
            <table className="data-grid w-full">
              <thead>
                <tr>
                  <th></th>
                  <th>{t('documents.fajlnev')}</th>
                  <th>{t('common.type')}</th>
                  <th>{t('documents.meret')}</th>
                  <th>{t('documents.feltoltve')}</th>
                  <th>{t('documents.feltolto')}</th>
                  <th>{t('documents.kapcsolodo')}</th>
                  <th>{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(d => (
                  <tr key={d.id}>
                    <td className="text-gray-400">{getFileIcon(d.fileName)}</td>
                    <td className="font-medium">{d.fileName}</td>
                    <td className="text-sm">
                      {DOCUMENT_TYPES.find(t => t.value === d.entityType)?.label ||
                        d.fileType || '-'}
                    </td>
                    <td className="text-sm font-mono">{formatFileSize(d.fileSize)}</td>
                    <td className="text-sm">{new Date(d.uploadedAt).toLocaleString('hu-HU')}</td>
                    <td className="text-sm">{d.uploadedByName || '-'}</td>
                    <td className="text-sm">{d.entityId ? `#${d.entityId}` : '-'}</td>
                    <td>
                      <div className="flex gap-1">
                        <button onClick={() => void handlePreview(d)} className="form-button text-xs" title="Előnézet"><Eye size={12} /></button>
                        <button onClick={() => handleDownload(d.id, d.fileName)} className="form-button text-xs" title="Letöltés"><Download size={12} /></button>
                        <button onClick={() => handleDelete(d.id)} className="form-button text-xs text-red-600" title="Törlés"><Trash2 size={12} /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Preview modal */}
      {previewUrl && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50" onClick={() => { setPreviewUrl(null); setPreviewName('') }}>
          <div className="bg-white rounded-lg p-4 max-w-4xl max-h-[90vh] overflow-auto" onClick={e => e.stopPropagation()}>
            <div className="flex justify-between items-center mb-2">
              <h3 className="font-semibold">{previewName}</h3>
              <button onClick={() => { setPreviewUrl(null); setPreviewName('') }} className="form-button text-xs">{t('common.close')}</button>
            </div>
            {previewName.toLowerCase().endsWith('.pdf') ? (
              <iframe src={previewUrl} className="w-full h-[70vh]" title="Dokumentum előnézet" />
            ) : (
              <img src={previewUrl} alt={previewName} className="max-w-full max-h-[70vh] object-contain" />
            )}
          </div>
        </div>
      )}
    </div>
  )
}
