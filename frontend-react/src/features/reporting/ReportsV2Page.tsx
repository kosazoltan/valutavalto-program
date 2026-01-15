/**
 * ReportsV2Page - Új moduláris riportok oldal
 *
 * Útvonal: /reports-v2
 *
 * @since 2026-01-13
 */

import React, { useState } from 'react'
import { useDailySummary, usePeriodReport, useWorkerStats } from './hooks/useReporting'
import { DailyReportCard } from './components/DailyReportCard'
import { PeriodReportChart } from './components/PeriodReportChart'
import { WorkerStatsTable } from './components/WorkerStatsTable'
import { useAuthStore } from '../../stores/authStore'

type TabType = 'daily' | 'period' | 'workers'

/**
 * Dátum input formázása
 */
function formatDateForInput(date: Date): string {
  return date.toISOString().substring(0, 10)
}

export const ReportsV2Page: React.FC = () => {
  const { isManagerOrAbove, isSupervisorOrAbove } = useAuthStore()

  // Tab állapot
  const [activeTab, setActiveTab] = useState<TabType>('daily')

  // Dátum szűrők
  const [selectedDate, setSelectedDate] = useState<Date>(new Date())
  const [startDate, setStartDate] = useState<Date>(() => {
    const date = new Date()
    date.setDate(date.getDate() - 7)
    return date
  })
  const [endDate, setEndDate] = useState<Date>(new Date())

  // Query-k
  const dailySummaryQuery = useDailySummary(selectedDate, activeTab === 'daily')
  const periodReportQuery = usePeriodReport(startDate, endDate, activeTab === 'period')
  const workerStatsQuery = useWorkerStats(
    startDate,
    endDate,
    activeTab === 'workers' && isManagerOrAbove()
  )

  // Tab váltás
  const handleTabChange = (tab: TabType) => {
    setActiveTab(tab)
  }

  // Loading és error komponensek
  const LoadingSpinner = () => (
    <div className="flex justify-center items-center py-12">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      <span className="ml-3 text-gray-600">Betöltés...</span>
    </div>
  )

  const ErrorMessage: React.FC<{ message: string }> = ({ message }) => (
    <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
      <p className="font-medium">Hiba történt</p>
      <p className="text-sm">{message}</p>
    </div>
  )

  return (
    <div className="container mx-auto px-4 py-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Riportok</h1>
        <p className="text-gray-600">Moduláris riport modul (v2)</p>
      </div>

      {/* Tab navigáció */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => handleTabChange('daily')}
            className={`py-4 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'daily'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Napi összesítés
          </button>

          {isSupervisorOrAbove() && (
            <button
              onClick={() => handleTabChange('period')}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'period'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              Időszaki riport
            </button>
          )}

          {isManagerOrAbove() && (
            <button
              onClick={() => handleTabChange('workers')}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'workers'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              Pénztáros statisztika
            </button>
          )}
        </nav>
      </div>

      {/* Dátum szűrők */}
      <div className="bg-white rounded-lg shadow-md p-4 mb-6">
        {activeTab === 'daily' ? (
          <div className="flex items-center space-x-4">
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
        ) : (
          <div className="flex items-center space-x-4 flex-wrap gap-y-2">
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
            <div className="flex space-x-2">
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
          </div>
        )}
      </div>

      {/* Tab tartalom */}
      {activeTab === 'daily' && (
        <>
          {dailySummaryQuery.isLoading && <LoadingSpinner />}
          {dailySummaryQuery.error && <ErrorMessage message={dailySummaryQuery.error.message} />}
          {dailySummaryQuery.data && <DailyReportCard summary={dailySummaryQuery.data} />}
        </>
      )}

      {activeTab === 'period' && isSupervisorOrAbove() && (
        <>
          {periodReportQuery.isLoading && <LoadingSpinner />}
          {periodReportQuery.error && <ErrorMessage message={periodReportQuery.error.message} />}
          {periodReportQuery.data && <PeriodReportChart report={periodReportQuery.data} />}
        </>
      )}

      {activeTab === 'workers' && isManagerOrAbove() && (
        <>
          {workerStatsQuery.isLoading && <LoadingSpinner />}
          {workerStatsQuery.error && <ErrorMessage message={workerStatsQuery.error.message} />}
          {workerStatsQuery.data && <WorkerStatsTable stats={workerStatsQuery.data} />}
        </>
      )}
    </div>
  )
}

export default ReportsV2Page
