import { useState, useEffect, useCallback, useRef } from 'react'
import {
  FileText,
  Upload,
  Download,
  Trash2,
  Search,
  Eye,
  Filter,
  FolderOpen,
  File,
  Image,
  FileSpreadsheet,
  RefreshCw,
  ScanLine,
} from 'lucide-react'
import {
  documentScannerApi,
  documentStorageApi,
  type Document,
  type DocumentScannerDevicesResponse,
  type ScannedDocument,
} from '../../services/api/index'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import { getErrorMessage } from '../../utils/errorHandling'
import { safeArray } from '@/utils/safeArray'
import { useTranslation } from 'react-i18next'
import DocumentImagePair from '../../components/documents/DocumentImagePair'
import { downloadBlob } from '../../utils/downloadBlob'

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

const SCANNED_DOCUMENT_TYPES = [
  { value: 'ID_CARD', label: 'Személyi igazolvány' },
  { value: 'PASSPORT', label: 'Útlevél' },
  { value: 'DRIVERS_LICENSE', label: 'Jogosítvány' },
  { value: 'OTHER', label: 'Egyéb' },
] as const

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
  const [scannerStatus, setScannerStatus] = useState<DocumentScannerDevicesResponse | null>(null)
  const [scannerLoading, setScannerLoading] = useState(false)
  const [scannerUploading, setScannerUploading] = useState(false)
  const [scannedLookupType, setScannedLookupType] = useState<'customer' | 'transaction'>('customer')
  const [scannedLookupId, setScannedLookupId] = useState('')
  const [scannedDocuments, setScannedDocuments] = useState<ScannedDocument[]>([])
  const [scannedLoading, setScannedLoading] = useState(false)
  const [scannedDocumentType, setScannedDocumentType] =
    useState<(typeof SCANNED_DOCUMENT_TYPES)[number]['value']>('OTHER')
  const [scannedNotes, setScannedNotes] = useState('')
  const [imagePairDoc, setImagePairDoc] = useState<ScannedDocument | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const scannerScanInputRef = useRef<HTMLInputElement>(null)
  const scannerUploadInputRef = useRef<HTMLInputElement>(null)
  const scannedUploadInputRef = useRef<HTMLInputElement>(null)

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

  const loadScannerDevices = useCallback(async () => {
    try {
      setScannerLoading(true)
      setScannerStatus(await documentScannerApi.devices())
    } catch (err) {
      logger.error('DocumentStoragePage', 'Szkenner eszközlista betöltési hiba:', err)
      setScannerStatus({
        devices: [],
        mode: 'UNKNOWN',
        message: 'A szkenner eszközlista jelenleg nem érhető el.',
      })
    } finally {
      setScannerLoading(false)
    }
  }, [])

  useEffect(() => {
    void loadScannerDevices()
  }, [loadScannerDevices])

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

  const handleScannerFileInput =
    (mode: 'scan' | 'upload') => async (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0]
      e.target.value = ''
      if (!file) return

      try {
        setScannerUploading(true)
        setError(null)
        if (mode === 'scan') {
          await documentScannerApi.scan(file, { documentType: 'OTHER' })
        } else {
          await documentScannerApi.upload(file, { documentType: 'OTHER' })
        }
        toast.success('Szkennelt dokumentum mentve', file.name)
        await loadData()
      } catch (err) {
        logger.error('DocumentStoragePage', 'Szkennelt dokumentum feltöltési hiba:', err)
        setError('Hiba a szkennelt dokumentum mentésénél')
        toast.error('Szkenner hiba', getErrorMessage(err))
      } finally {
        setScannerUploading(false)
      }
    }

  const parsedScannedLookupId = (): number | null => {
    const parsed = Number(scannedLookupId)
    return Number.isInteger(parsed) && parsed > 0 ? parsed : null
  }

  const loadScannedDocuments = useCallback(async () => {
    const id = parsedScannedLookupId()
    if (!id) {
      setError('Adj meg pozitív ügyfél vagy tranzakció azonosítót.')
      setScannedDocuments([])
      return
    }

    try {
      setScannedLoading(true)
      setError(null)
      const data =
        scannedLookupType === 'customer'
          ? await documentScannerApi.getCustomerDocuments(id)
          : await documentScannerApi.getTransactionDocuments(id)
      setScannedDocuments(data)
    } catch (err) {
      logger.error('DocumentStoragePage', 'Szkennelt dokumentum lista hiba:', err)
      setError('Hiba a szkennelt dokumentumok betöltésekor')
      toast.error('Szkennelt dokumentumok', getErrorMessage(err))
    } finally {
      setScannedLoading(false)
    }
    // Lint-audit 2026-08-09: a `parsedScannedLookupId` egy nem memoizalt helper,
    // amely KIZAROLAG a lenti ket deps-bol (`scannedLookupId`, `scannedLookupType`)
    // szamol. Deps-be veve minden renderben uj referenciat kapna es folyamatos
    // refetch-et okozna; a kihagyasa nem hoz stale erteket — a forras-state benne van.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [scannedLookupId, scannedLookupType])

  const handleScannedUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    e.target.value = ''
    if (!file) return

    const id = parsedScannedLookupId()
    if (!id) {
      setError('Feltöltés előtt adj meg pozitív ügyfél vagy tranzakció azonosítót.')
      return
    }

    try {
      setScannedLoading(true)
      setError(null)
      await documentScannerApi.uploadScannedDocument(file, {
        documentType: scannedDocumentType,
        notes: scannedNotes.trim() || undefined,
        ...(scannedLookupType === 'customer' ? { customerId: id } : { transactionId: id }),
      })
      toast.success('Szkennelt dokumentum feltöltve', file.name)
      await loadScannedDocuments()
    } catch (err) {
      logger.error('DocumentStoragePage', 'Szkennelt dokumentum feltöltési hiba:', err)
      setError('Hiba a szkennelt dokumentum feltöltésénél')
      toast.error('Szkennelt dokumentum', getErrorMessage(err))
    } finally {
      setScannedLoading(false)
    }
  }

  const handleDeleteScannedDocument = async (id: string) => {
    if (!confirm('Biztosan törli ezt a szkennelt dokumentumot?')) return
    try {
      setScannedLoading(true)
      setError(null)
      await documentScannerApi.deleteScannedDocument(id)
      toast.success('Szkennelt dokumentum törölve')
      await loadScannedDocuments()
    } catch (err) {
      logger.error('DocumentStoragePage', 'Szkennelt dokumentum törlési hiba:', err)
      setError(getErrorMessage(err))
    } finally {
      setScannedLoading(false)
    }
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
      downloadBlob(blob, fileName)
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

  const filtered = safeArray<Document>(documents).filter((d) => {
    if (searchTerm && !d.fileName.toLowerCase().includes(searchTerm.toLowerCase())) return false
    if (typeFilter && d.entityType !== typeFilter) return false
    return true
  })

  const totalSize = filtered.reduce((sum, d) => sum + (d.fileSize || 0), 0)

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <FolderOpen />
          {t('documents.dokumentumtar')}
        </h1>
        <div className="flex flex-wrap gap-2 items-center">
          <span className="text-sm text-gray-500">
            {filtered.length} dokumentum ({formatFileSize(totalSize)})
          </span>
          <button
            onClick={() => fileInputRef.current?.click()}
            disabled={uploading}
            className="form-button-primary whitespace-nowrap"
          >
            <Upload size={16} /> {uploading ? 'Feltöltés...' : 'Feltöltés'}
          </button>
          <input
            ref={fileInputRef}
            type="file"
            className="hidden"
            multiple
            onChange={handleFileInput}
          />
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <section className="rounded border border-blue-100 bg-blue-50 p-3">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div className="flex min-w-0 gap-3">
            <ScanLine size={20} className="mt-0.5 shrink-0 text-blue-700" />
            <div className="min-w-0">
              <h2 className="font-semibold text-blue-950">Szkenner kapcsolat</h2>
              <p className="text-sm text-blue-900">
                {scannerStatus?.message || 'Szkenner eszközlista betöltése...'}
              </p>
              <p className="mt-1 text-xs text-blue-700">
                Mód: {scannerStatus?.mode || '-'} · Eszközök: {scannerStatus?.devices?.length ?? 0}
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => void loadScannerDevices()}
            disabled={scannerLoading || scannerUploading}
            className="form-button w-full justify-center sm:w-auto"
          >
            <RefreshCw size={16} />
            {scannerLoading ? 'Frissítés...' : 'Szkenner frissítés'}
          </button>
          <button
            type="button"
            onClick={() => scannerScanInputRef.current?.click()}
            disabled={scannerUploading}
            className="form-button w-full justify-center sm:w-auto"
          >
            <ScanLine size={16} />
            {scannerUploading ? 'Mentés...' : 'Szkennelés'}
          </button>
          <button
            type="button"
            onClick={() => scannerUploadInputRef.current?.click()}
            disabled={scannerUploading}
            className="form-button w-full justify-center sm:w-auto"
          >
            <Upload size={16} />
            Upload bridge
          </button>
          <input
            ref={scannerScanInputRef}
            type="file"
            className="hidden"
            data-testid="scanner-scan-input"
            accept="image/jpeg,image/png,application/pdf"
            onChange={(e) => void handleScannerFileInput('scan')(e)}
          />
          <input
            ref={scannerUploadInputRef}
            type="file"
            className="hidden"
            data-testid="scanner-upload-input"
            accept="image/jpeg,image/png,application/pdf"
            onChange={(e) => void handleScannerFileInput('upload')(e)}
          />
        </div>
      </section>

      <section
        className="rounded border border-gray-200 bg-white p-3"
        data-testid="scanned-documents-panel"
      >
        <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="font-semibold text-gray-900">Szkennelt dokumentumok</h2>
            <p className="text-sm text-gray-500">
              Ügyfélhez vagy tranzakcióhoz kötött okmányok listázása és feltöltése.
            </p>
          </div>
          <span className="text-sm text-gray-500">{scannedDocuments.length} elem</span>
        </div>
        <div className="grid grid-cols-1 gap-2 md:grid-cols-[160px_1fr_180px_auto_auto] md:items-end">
          <div>
            <label className="form-label" htmlFor="scanned-lookup-type">
              Kapcsolat
            </label>
            <select
              id="scanned-lookup-type"
              className="form-input w-full"
              value={scannedLookupType}
              onChange={(e) => setScannedLookupType(e.target.value as 'customer' | 'transaction')}
            >
              <option value="customer">Ügyfél</option>
              <option value="transaction">Tranzakció</option>
            </select>
          </div>
          <div>
            <label className="form-label" htmlFor="scanned-lookup-id">
              Azonosító
            </label>
            <input
              id="scanned-lookup-id"
              className="form-input w-full"
              inputMode="numeric"
              pattern="[0-9]*"
              value={scannedLookupId}
              onChange={(e) => setScannedLookupId(e.target.value)}
              placeholder="pl. 123"
            />
          </div>
          <div>
            <label className="form-label" htmlFor="scanned-document-type">
              Dokumentumtípus
            </label>
            <select
              id="scanned-document-type"
              className="form-input w-full"
              value={scannedDocumentType}
              onChange={(e) => setScannedDocumentType(e.target.value as typeof scannedDocumentType)}
            >
              {SCANNED_DOCUMENT_TYPES.map((type) => (
                <option key={type.value} value={type.value}>
                  {type.label}
                </option>
              ))}
            </select>
          </div>
          <button
            type="button"
            className="form-button justify-center"
            onClick={() => void loadScannedDocuments()}
            disabled={scannedLoading}
          >
            <Search size={16} />
            {scannedLoading ? 'Betöltés...' : 'Lista'}
          </button>
          <button
            type="button"
            className="form-button-primary justify-center"
            onClick={() => scannedUploadInputRef.current?.click()}
            disabled={scannedLoading}
          >
            <Upload size={16} />
            Feltöltés
          </button>
          <input
            ref={scannedUploadInputRef}
            type="file"
            className="hidden"
            data-testid="scanned-documents-upload-input"
            accept="image/jpeg,image/png,application/pdf"
            onChange={(e) => void handleScannedUpload(e)}
          />
        </div>
        <div className="mt-2">
          <label className="form-label" htmlFor="scanned-notes">
            Megjegyzés
          </label>
          <input
            id="scanned-notes"
            className="form-input w-full"
            value={scannedNotes}
            onChange={(e) => setScannedNotes(e.target.value)}
            placeholder="Opcionális megjegyzés a feltöltött dokumentumhoz"
          />
        </div>

        <div className="mt-3 space-y-2">
          {scannedDocuments.length === 0 ? (
            <p className="text-sm text-gray-500">Nincs betöltött szkennelt dokumentum.</p>
          ) : (
            scannedDocuments.map((doc) => (
              <article
                key={doc.id}
                className="flex flex-col gap-2 rounded border border-gray-200 p-3 sm:flex-row sm:items-center sm:justify-between"
              >
                <div className="min-w-0">
                  <p className="break-words font-semibold text-gray-900">{doc.fileName}</p>
                  <p className="text-sm text-gray-500">
                    {doc.documentType} · {formatFileSize(doc.fileSizeBytes)} ·{' '}
                    {new Date(doc.scannedAt).toLocaleString('hu-HU')}
                  </p>
                  {doc.notes && <p className="text-sm text-gray-600">{doc.notes}</p>}
                </div>
                <div className="flex gap-2">
                  {(doc.hasFrontImage || doc.hasBackImage) && (
                    <button
                      type="button"
                      className="form-button justify-center"
                      onClick={() => setImagePairDoc(doc)}
                      disabled={scannedLoading}
                    >
                      <Image size={14} />
                      {t('documents.okmanyKepek')}
                    </button>
                  )}
                  <button
                    type="button"
                    className="form-button justify-center text-red-600"
                    onClick={() => void handleDeleteScannedDocument(doc.id)}
                    disabled={scannedLoading}
                  >
                    <Trash2 size={14} />
                    Törlés
                  </button>
                </div>
              </article>
            ))
          )}
        </div>
      </section>

      {/* Drag & drop zone */}
      <div
        className={`border-2 border-dashed rounded-lg p-6 text-center transition-colors ${dragActive ? 'border-blue-400 bg-blue-50' : 'border-gray-300'}`}
        onDragOver={(e) => {
          e.preventDefault()
          setDragActive(true)
        }}
        onDragLeave={() => setDragActive(false)}
        onDrop={handleDrop}
      >
        <Upload size={32} className="mx-auto text-gray-400 mb-2" />
        <p className="text-gray-500">
          {t('documents.huzzaIdeAFajlokatVagyKattintsonAFeltoltesGombra')}
        </p>
        <p className="text-xs text-gray-400 mt-1">{t('documents.pdfJpgPngXlsxCsvMax10Mb')}</p>
      </div>

      {/* Filters */}
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
        <Search size={16} className="text-gray-400" />
        <input
          className="form-input flex-1"
          placeholder="Keresés fájlnév alapján..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
        />
        <div className="flex items-center gap-2">
          <Filter size={16} className="text-gray-400" />
          <select
            className="form-input w-full sm:w-48"
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
          >
            {DOCUMENT_TYPES.map((t) => (
              <option key={t.value} value={t.value}>
                {t.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Table */}
      {loading ? (
        <div>Betöltés...</div>
      ) : (
        <div className="form-panel">
          {filtered.length === 0 ? (
            <div className="text-center text-gray-500 py-8">{t('documents.nincsDokumentum')}</div>
          ) : (
            <>
              <div className="space-y-3 md:hidden">
                {filtered.map((d) => (
                  <article
                    key={d.id}
                    className="rounded border border-gray-200 bg-white p-3 shadow-sm"
                  >
                    <div className="mb-3 flex items-start gap-3">
                      <div className="mt-1 shrink-0 text-gray-500">{getFileIcon(d.fileName)}</div>
                      <div className="min-w-0 flex-1">
                        <p className="break-words font-semibold text-gray-900">{d.fileName}</p>
                        <p className="text-sm text-gray-500">
                          {DOCUMENT_TYPES.find((t) => t.value === d.entityType)?.label ||
                            d.fileType ||
                            '-'}
                        </p>
                      </div>
                      <span className="shrink-0 font-mono text-xs text-gray-600">
                        {formatFileSize(d.fileSize)}
                      </span>
                    </div>
                    <dl className="grid grid-cols-2 gap-x-3 gap-y-2 text-sm">
                      <div>
                        <dt className="text-gray-500">{t('documents.feltoltve')}</dt>
                        <dd className="text-gray-900">
                          {new Date(d.uploadedAt).toLocaleString('hu-HU')}
                        </dd>
                      </div>
                      <div>
                        <dt className="text-gray-500">{t('documents.feltolto')}</dt>
                        <dd className="text-gray-900">{d.uploadedByName || '-'}</dd>
                      </div>
                      <div className="col-span-2">
                        <dt className="text-gray-500">{t('documents.kapcsolodo')}</dt>
                        <dd className="text-gray-900">{d.entityId ? `#${d.entityId}` : '-'}</dd>
                      </div>
                    </dl>
                    <div className="mt-3 grid grid-cols-3 gap-2">
                      <button
                        onClick={() => void handlePreview(d)}
                        className="form-button justify-center text-xs"
                        title="Előnézet"
                      >
                        <Eye size={14} />
                      </button>
                      <button
                        onClick={() => handleDownload(d.id, d.fileName)}
                        className="form-button justify-center text-xs"
                        title="Letöltés"
                      >
                        <Download size={14} />
                      </button>
                      <button
                        onClick={() => handleDelete(d.id)}
                        className="form-button justify-center text-xs text-red-600"
                        title="Törlés"
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </article>
                ))}
              </div>
              <div className="hidden overflow-x-auto md:block">
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
                    {filtered.map((d) => (
                      <tr key={d.id}>
                        <td className="text-gray-400">{getFileIcon(d.fileName)}</td>
                        <td className="font-medium">{d.fileName}</td>
                        <td className="text-sm">
                          {DOCUMENT_TYPES.find((t) => t.value === d.entityType)?.label ||
                            d.fileType ||
                            '-'}
                        </td>
                        <td className="text-sm font-mono">{formatFileSize(d.fileSize)}</td>
                        <td className="text-sm">
                          {new Date(d.uploadedAt).toLocaleString('hu-HU')}
                        </td>
                        <td className="text-sm">{d.uploadedByName || '-'}</td>
                        <td className="text-sm">{d.entityId ? `#${d.entityId}` : '-'}</td>
                        <td>
                          <div className="flex gap-1">
                            <button
                              onClick={() => void handlePreview(d)}
                              className="form-button text-xs"
                              title="Előnézet"
                            >
                              <Eye size={12} />
                            </button>
                            <button
                              onClick={() => handleDownload(d.id, d.fileName)}
                              className="form-button text-xs"
                              title="Letöltés"
                            >
                              <Download size={12} />
                            </button>
                            <button
                              onClick={() => handleDelete(d.id)}
                              className="form-button text-xs text-red-600"
                              title="Törlés"
                            >
                              <Trash2 size={12} />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </>
          )}
        </div>
      )}

      {/* Preview modal */}
      {previewUrl && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
          onClick={() => {
            setPreviewUrl(null)
            setPreviewName('')
          }}
        >
          <div
            className="bg-white rounded-lg p-4 max-w-4xl max-h-[90vh] overflow-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex justify-between items-center mb-2">
              <h3 className="font-semibold">{previewName}</h3>
              <button
                onClick={() => {
                  setPreviewUrl(null)
                  setPreviewName('')
                }}
                className="form-button text-xs"
              >
                {t('common.close')}
              </button>
            </div>
            {previewName.toLowerCase().endsWith('.pdf') ? (
              <iframe src={previewUrl} className="w-full h-[70vh]" title="Dokumentum előnézet" />
            ) : (
              <img
                src={previewUrl}
                alt={previewName}
                className="max-w-full max-h-[70vh] object-contain"
              />
            )}
          </div>
        </div>
      )}

      {/* FS-5: okmány képpár (thumbnail + nagyítás-engedély) */}
      {imagePairDoc && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50"
          onClick={() => setImagePairDoc(null)}
        >
          <div
            className="bg-white rounded-lg p-4 max-w-2xl max-h-[90vh] overflow-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex justify-between items-center mb-3">
              <h3 className="font-semibold">{t('documents.okmanyKepek')}</h3>
              <button onClick={() => setImagePairDoc(null)} className="form-button text-xs">
                {t('common.close')}
              </button>
            </div>
            <DocumentImagePair
              documentId={imagePairDoc.id}
              hasFront={!!imagePairDoc.hasFrontImage}
              hasBack={!!imagePairDoc.hasBackImage}
            />
          </div>
        </div>
      )}
    </div>
  )
}
