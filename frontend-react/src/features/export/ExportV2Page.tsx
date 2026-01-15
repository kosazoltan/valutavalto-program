/**
 * ExportV2Page - Új moduláris export oldal
 *
 * Útvonal: /export-v2
 *
 * @since 2026-01-13
 */

import React, { useState } from 'react'
import {
  useExportTypes,
  useExportTransactionsCsv,
  useExportDailyReportCsv,
  useExportInfo,
} from './hooks/useExport'
import { ExportButton } from './components/ExportButton'
import { useAuthStore } from '../../stores/authStore'

/**
 * Dátum formázása input mezőhöz
 */
function formatDateForInput(date: Date): string {
  return date.toISOString().substring(0, 10)
}

/**
 * Fájl méret formázása
 */
function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

export const ExportV2Page: React.FC = () => {
  const { isSupervisorOrAbove } = useAuthStore()

  // Dátum szűrők
  const [selectedDate, setSelectedDate] = useState<Date>(new Date())
  const [startDate, setStartDate] = useState<Date>(() => {
    const date = new Date()
    date.setDate(date.getDate() - 7)
    return date
  })
  const [endDate, setEndDate] = useState<Date>(new Date())

  // Queries és mutations
  const exportTypes = useExportTypes()
  const exportTransactions = useExportTransactionsCsv()
  const exportDailyReport = useExportDailyReportCsv()
  const exportInfo = useExportInfo(startDate, endDate, isSupervisorOrAbove())

  // Export kezelők
  const handleExportTransactions = () => {
    exportTransactions.mutate({ startDate, endDate })
  }

  const handleExportDailyReport = () => {
    exportDailyReport.mutate({ date: selectedDate })
  }

  return (
    <div className="container mx-auto px-4 py-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Export</h1>
        <p className="text-gray-600">Adatok exportálása különböző formátumokban (v2)</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Napi riport export */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Napi riport exportálása</h2>
          <p className="text-sm text-gray-600 mb-4">
            A kiválasztott nap tranzakcióinak exportálása CSV formátumban.
          </p>

          <div className="flex items-center gap-4 mb-4">
            <label className="text-sm font-medium text-gray-700">Dátum:</label>
            <input
              type="date"
              value={formatDateForInput(selectedDate)}
              onChange={(e) => setSelectedDate(new Date(e.target.value))}
              className="border border-gray-300 rounded-md px-3 py-2 text-sm focus:ring-blue-500 focus:border-blue-500"
            />
            <button
              onClick={() => setSelectedDate(new Date())}
              className="px-3 py-2 text-sm bg-gray-100 hover:bg-gray-200 rounded-md"
            >
              Ma
            </button>
          </div>

          <ExportButton
            onClick={handleExportDailyReport}
            loading={exportDailyReport.isPending}
            format="CSV"
          >
            Napi riport letöltése
          </ExportButton>

          {exportDailyReport.isSuccess && (
            <p className="mt-2 text-sm text-green-600">Export sikeres!</p>
          )}

          {exportDailyReport.error && (
            <p className="mt-2 text-sm text-red-600">{exportDailyReport.error.message}</p>
          )}
        </div>

        {/* Időszaki tranzakciók export */}
        {isSupervisorOrAbove() && (
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-lg font-semibold text-gray-800 mb-4">
              Tranzakciók exportálása
            </h2>
            <p className="text-sm text-gray-600 mb-4">
              A kiválasztott időszak összes tranzakciójának exportálása.
            </p>

            <div className="flex items-center gap-4 mb-4 flex-wrap">
              <label className="text-sm font-medium text-gray-700">Időszak:</label>
              <input
                type="date"
                value={formatDateForInput(startDate)}
                onChange={(e) => setStartDate(new Date(e.target.value))}
                className="border border-gray-300 rounded-md px-3 py-2 text-sm focus:ring-blue-500 focus:border-blue-500"
              />
              <span className="text-gray-500">-</span>
              <input
                type="date"
                value={formatDateForInput(endDate)}
                onChange={(e) => setEndDate(new Date(e.target.value))}
                className="border border-gray-300 rounded-md px-3 py-2 text-sm focus:ring-blue-500 focus:border-blue-500"
              />
            </div>

            <div className="flex gap-2 mb-4">
              <button
                onClick={() => {
                  const today = new Date()
                  const weekAgo = new Date()
                  weekAgo.setDate(today.getDate() - 7)
                  setStartDate(weekAgo)
                  setEndDate(today)
                }}
                className="px-3 py-2 text-sm bg-gray-100 hover:bg-gray-200 rounded-md"
              >
                Utolsó 7 nap
              </button>
              <button
                onClick={() => {
                  const today = new Date()
                  const monthAgo = new Date()
                  monthAgo.setMonth(today.getMonth() - 1)
                  setStartDate(monthAgo)
                  setEndDate(today)
                }}
                className="px-3 py-2 text-sm bg-gray-100 hover:bg-gray-200 rounded-md"
              >
                Utolsó hónap
              </button>
            </div>

            {/* Export info előnézet */}
            {exportInfo.data && (
              <div className="bg-gray-50 rounded-lg p-4 mb-4">
                <p className="text-sm text-gray-600">
                  <span className="font-medium">Rekordok száma:</span>{' '}
                  {exportInfo.data.recordCount.toLocaleString('hu-HU')}
                </p>
                <p className="text-sm text-gray-600">
                  <span className="font-medium">Becsült méret:</span>{' '}
                  {formatFileSize(exportInfo.data.fileSize)}
                </p>
              </div>
            )}

            <ExportButton
              onClick={handleExportTransactions}
              loading={exportTransactions.isPending}
              format="CSV"
            >
              Tranzakciók letöltése
            </ExportButton>

            {exportTransactions.isSuccess && (
              <p className="mt-2 text-sm text-green-600">Export sikeres!</p>
            )}

            {exportTransactions.error && (
              <p className="mt-2 text-sm text-red-600">{exportTransactions.error.message}</p>
            )}
          </div>
        )}
      </div>

      {/* Elérhető export típusok */}
      {exportTypes.data && exportTypes.data.length > 0 && (
        <div className="mt-6 bg-white rounded-lg shadow-md p-6">
          <h2 className="text-lg font-semibold text-gray-800 mb-4">Elérhető export típusok</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {exportTypes.data.map((type) => (
              <div key={type.code} className="bg-gray-50 rounded-lg p-4">
                <p className="font-medium text-gray-800">{type.name}</p>
                <p className="text-sm text-gray-500">
                  Formátumok: {type.formats.join(', ')}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}

export default ExportV2Page
