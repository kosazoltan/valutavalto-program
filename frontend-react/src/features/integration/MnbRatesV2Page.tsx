/**
 * MnbRatesV2Page - MNB Árfolyamok oldal
 *
 * ÚJ moduláris oldal a /mnb-rates-v2 útvonalon.
 *
 * @since 2026-01-13
 */

import React, { useState } from 'react'
import { useMnbCurrentRates, useMnbRateComparison } from './hooks'
import { MnbRatesTable, RateComparisonTable } from './components'

type TabType = 'current' | 'comparison'

export const MnbRatesV2Page: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabType>('current')
  const [selectedDate, setSelectedDate] = useState<string>(
    new Date().toISOString().substring(0, 10)
  )

  // Query hooks
  const { data: currentRates, isLoading: loadingCurrent, error: errorCurrent } = useMnbCurrentRates()
  const {
    data: comparison,
    isLoading: loadingComparison,
    error: errorComparison,
  } = useMnbRateComparison(selectedDate ? new Date(selectedDate) : undefined, activeTab === 'comparison')

  const tabs = [
    { id: 'current' as const, label: 'Aktuális árfolyamok' },
    { id: 'comparison' as const, label: 'Összehasonlítás' },
  ]

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">MNB Árfolyamok</h1>
        <p className="mt-1 text-sm text-gray-500">
          Magyar Nemzeti Bank hivatalos árfolyamai és összehasonlítás
        </p>
      </div>

      {/* Status badge */}
      {currentRates && (
        <div className="mb-4 flex items-center gap-4">
          <span
            className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
              currentRates.fromCache
                ? 'bg-yellow-100 text-yellow-800'
                : 'bg-green-100 text-green-800'
            }`}
          >
            {currentRates.fromCache ? 'Cache' : 'Friss adat'}
          </span>
          <span className="text-sm text-gray-500">
            Forrás: {currentRates.source} | Árfolyam dátum: {currentRates.rateDate}
          </span>
        </div>
      )}

      {/* Tabs */}
      <div className="border-b border-gray-200 mb-6">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === tab.id
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab content */}
      <div className="bg-white shadow rounded-lg">
        {activeTab === 'current' && (
          <div className="p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Mai napi MNB árfolyamok
            </h2>

            {errorCurrent && (
              <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-md">
                <p className="text-sm text-red-600">{errorCurrent.message}</p>
              </div>
            )}

            <MnbRatesTable rates={currentRates?.rates || []} loading={loadingCurrent} />

            {currentRates && (
              <div className="mt-4 text-sm text-gray-500">
                Összesen {currentRates.currencyCount} valuta | Lekérdezve:{' '}
                {new Date(currentRates.fetchedAt).toLocaleString('hu-HU')}
              </div>
            )}
          </div>
        )}

        {activeTab === 'comparison' && (
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900">
                MNB vs. Belső árfolyamok
              </h2>
              <div className="flex items-center gap-2">
                <label htmlFor="comparison-date" className="text-sm text-gray-600">
                  Dátum:
                </label>
                <input
                  id="comparison-date"
                  type="date"
                  value={selectedDate}
                  onChange={(e) => setSelectedDate(e.target.value)}
                  className="px-3 py-1.5 border border-gray-300 rounded-md text-sm focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </div>

            {errorComparison && (
              <div className="mb-4 p-4 bg-red-50 border border-red-200 rounded-md">
                <p className="text-sm text-red-600">{errorComparison.message}</p>
              </div>
            )}

            <RateComparisonTable
              comparisons={comparison?.comparisons || []}
              loading={loadingComparison}
            />

            {comparison && (
              <div className="mt-4 text-sm text-gray-500">
                {comparison.comparedCount} valuta összehasonlítva | Generálva:{' '}
                {new Date(comparison.generatedAt).toLocaleString('hu-HU')}
              </div>
            )}

            {/* Legend */}
            <div className="mt-6 p-4 bg-gray-50 rounded-md">
              <h3 className="text-sm font-medium text-gray-700 mb-2">Jelmagyarázat</h3>
              <div className="flex items-center gap-6 text-sm">
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-green-500"></span>
                  <span className="text-gray-600">Spread &lt; 1%</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-yellow-500"></span>
                  <span className="text-gray-600">Spread 1-3%</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-red-500"></span>
                  <span className="text-gray-600">Spread &gt; 3%</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

export default MnbRatesV2Page
