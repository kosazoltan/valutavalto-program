import { useState, useEffect } from 'react'
import { FileText, Upload, Download } from 'lucide-react'
import { documentStorageApi, Document } from '../../services/api'

export default function DocumentStoragePage() {
  const [documents, setDocuments] = useState<Document[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      setDocuments(await documentStorageApi.list())
    } catch (err) {
      console.error('Dokumentumok betöltési hiba:', err)
      setError('Hiba a dokumentumok betöltésekor')
    } finally {
      setLoading(false)
    }
  }

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    try {
      setError(null)
      await documentStorageApi.upload(file)
      await loadData()
      alert('Feltöltés sikeres')
    } catch (err) {
      console.error('Feltöltési hiba:', err)
      setError('Hiba a feltöltésnél. Kérjük ellenőrizze a fájlt.')
    }
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
    } catch (err) {
      console.error('Letöltési hiba:', err)
      setError('Hiba a letöltésnél')
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold flex items-center gap-2"><FileText />Dokumentumok</h1>
        <label className="form-button-primary cursor-pointer">
          <Upload size={16} /> Feltöltés
          <input type="file" className="hidden" onChange={handleUpload} />
        </label>
      </div>
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}
      {loading ? <div>Betöltés...</div> : (
        <div className="form-panel">
          <table className="data-grid w-full">
            <thead><tr><th>Fájlnév</th><th>Típus</th><th>Méret</th><th>Feltöltve</th><th>Műveletek</th></tr></thead>
            <tbody>
              {documents.map(d => (
                <tr key={d.id}>
                  <td>{d.fileName}</td>
                  <td>{d.fileType}</td>
                  <td>{(d.fileSize / 1024).toFixed(2)} KB</td>
                  <td>{new Date(d.uploadedAt).toLocaleString('hu-HU')}</td>
                  <td>
                    <button onClick={() => handleDownload(d.id, d.fileName)} className="form-button text-xs"><Download size={12} />Letöltés</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
