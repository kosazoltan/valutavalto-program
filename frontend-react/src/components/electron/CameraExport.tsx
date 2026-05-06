/**
 * CameraExport — Kamera felvételek exportálása USB meghajtóra.
 *
 * CSAK Electron-ban működik (window.electronAPI.cameraExportToUsb).
 * Böngészőben null-t ad vissza.
 */

import { useState } from 'react';
import { isElectron } from '@/utils/electron';
import { useTranslation } from 'react-i18next'

export default function CameraExport() {
  const { t } = useTranslation()
  const [dateFrom, setDateFrom] = useState(() => new Date().toISOString().slice(0, 10));
  const [dateTo, setDateTo] = useState(() => new Date().toISOString().slice(0, 10));
  const [message, setMessage] = useState('');

  // Guard: only render in Electron
  if (!isElectron()) return null;

  const handleExport = async () => {
    setMessage('');
    if (!window.electronAPI?.cameraExportToUsb) {
      setMessage('Export nem elérhető (Electron IPC)');
      return;
    }

    try {
      const result = await window.electronAPI.cameraExportToUsb(dateFrom, dateTo);
      setMessage(result.success
        ? `${result.exported} fájl exportálva`
        : result.error ?? 'Ismeretlen hiba');
    } catch (err) {
      setMessage('Export hiba: ' + (err instanceof Error ? err.message : 'Ismeretlen hiba'));
    }
  };

  return (
    <div className="space-y-3 rounded-xl border bg-white p-4 shadow-sm">
      <h3 className="text-sm font-semibold text-gray-700">{t('components.kameraExportUsbRe')}</h3>
      <div className="flex flex-wrap gap-3">
        <label className="text-sm text-gray-600">
          {t('components.datumtol')}
          <input
            type="date"
            value={dateFrom}
            onChange={(e) => setDateFrom(e.target.value)}
            className="mt-1 block rounded-lg border px-3 py-2 text-sm"
          />
        </label>
        <label className="text-sm text-gray-600">
          {t('components.datumig')}
          <input
            type="date"
            value={dateTo}
            onChange={(e) => setDateTo(e.target.value)}
            className="mt-1 block rounded-lg border px-3 py-2 text-sm"
          />
        </label>
        <div className="flex items-end">
          <button
            onClick={handleExport}
            className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
          >
            {t('components.exportalasUsbRe')}
          </button>
        </div>
      </div>
      {message && <p className="text-sm text-gray-600">{message}</p>}
    </div>
  );
}
