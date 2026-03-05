import { useState, useCallback } from 'react';
import apiClient from '@/api/client';

interface DocumentScannerProps {
  customerId: number;
  onClose: () => void;
  onSaved?: () => void;
}

export default function DocumentScanner({ customerId, onClose, onSaved }: DocumentScannerProps) {
  const [preview, setPreview] = useState<string | null>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [fileName, setFileName] = useState('');

  const handleScan = useCallback(async () => {
    setIsScanning(true);
    setError('');
    try {
      if (window.electronAPI?.scanDocument) {
        // Electron IPC — TWAIN/WIA driver (TODO: implementáció)
        const result = await window.electronAPI.scanDocument();
        setPreview(result.imageBase64);
        setFileName(result.fileName);
      } else {
        // Placeholder — nincs szkenner elérhető
        // Szimulált előnézet
        setPreview('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');
        setFileName(`scan_${Date.now()}.png`);
        setError('ℹ️ Szkenner nem elérhető — placeholder mód. Töltsön fel fájlt manuálisan.');
      }
    } catch (err) {
      console.error('[DocumentScanner] Szkenner hiba:', err);
      setError('Szkennelés sikertelen. Ellenőrizze a szkenner csatlakozást.');
    } finally {
      setIsScanning(false);
    }
  }, []);

  const handleFileUpload = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Max 5MB
    if (file.size > 5 * 1024 * 1024) {
      setError('A fájl mérete nem haladhatja meg az 5 MB-ot!');
      return;
    }

    // Csak JPG/PNG
    if (!['image/jpeg', 'image/png'].includes(file.type)) {
      setError('Csak JPG vagy PNG fájl tölthető fel!');
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      setPreview(reader.result as string);
      setFileName(file.name);
      setError('');
    };
    reader.readAsDataURL(file);
  }, []);

  const handleSave = useCallback(async () => {
    if (!preview) return;
    setIsSaving(true);
    setError('');
    setSuccess('');
    try {
      // Base64 → Blob → FormData
      const response = await fetch(preview);
      const blob = await response.blob();

      const formData = new FormData();
      formData.append('file', blob, fileName || 'document.png');

      await apiClient.post(`/customers/${customerId}/documents`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });

      setSuccess('✅ Okmány sikeresen mentve az ügyfélhez!');
      setPreview(null);
      setFileName('');
      onSaved?.();
    } catch (err) {
      console.error('[DocumentScanner] Mentés hiba:', err);
      setError('❌ Okmány mentés sikertelen.');
    } finally {
      setIsSaving(false);
    }
  }, [preview, fileName, customerId, onSaved]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="w-[600px] rounded-xl bg-white p-6 shadow-xl">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-lg font-bold">📷 Okmány szkennelés</h3>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">✕</button>
        </div>

        {/* Szkennelés / Fájl feltöltés */}
        <div className="mb-4 flex gap-3">
          <button onClick={handleScan} disabled={isScanning}
            className="btn-primary flex-1 bg-blue-600 hover:bg-blue-700 disabled:opacity-50">
            {isScanning ? '⏳ Szkennelés...' : '📷 Szkennelés indítása'}
          </button>
          <label className="flex flex-1 cursor-pointer items-center justify-center rounded-lg border-2 border-dashed border-gray-300 px-4 py-2 text-sm text-gray-600 hover:border-blue-400 hover:text-blue-600">
            📁 Fájl feltöltés
            <input type="file" accept="image/jpeg,image/png"
              onChange={handleFileUpload} className="hidden" />
          </label>
        </div>

        {/* Előnézet */}
        <div className="mb-4 flex h-64 items-center justify-center rounded-lg border-2 border-dashed bg-gray-50">
          {preview ? (
            <img src={preview} alt="Okmány előnézet"
              className="max-h-full max-w-full object-contain" />
          ) : (
            <p className="text-gray-400">Még nincs szkennelt okmány</p>
          )}
        </div>

        {/* Fájl info */}
        {fileName && (
          <p className="mb-2 text-xs text-gray-500">Fájl: {fileName}</p>
        )}

        {/* Üzenetek */}
        {error && <div className="mb-3 rounded-lg bg-red-50 p-2 text-sm text-red-700">{error}</div>}
        {success && <div className="mb-3 rounded-lg bg-green-50 p-2 text-sm text-green-700">{success}</div>}

        {/* Mentés */}
        <div className="flex gap-3">
          <button onClick={handleSave} disabled={!preview || isSaving}
            className="btn-primary flex-1 bg-green-600 hover:bg-green-700 disabled:opacity-50">
            {isSaving ? '⏳ Mentés...' : '💾 Mentés ügyfélhez'}
          </button>
          <button onClick={onClose}
            className="flex-1 rounded-lg border px-4 py-2 text-sm hover:bg-gray-50">
            Bezárás
          </button>
        </div>
      </div>
    </div>
  );
}
