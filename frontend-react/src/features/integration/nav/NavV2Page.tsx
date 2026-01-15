/**
 * NavV2Page - NAV Integráció oldal
 *
 * ÚJ moduláris oldal a /nav-v2 útvonalon.
 *
 * @since 2026-01-13
 */

import React, { useState } from 'react'
import {
  useNavCashRegisterStatus,
  useNavPendingReceipts,
  useNavDailyReceipts,
  useNavDailyStatistics,
  useNavSync,
} from './hooks'
import { NavStatusCard, NavReceiptTable } from './components'

type TabType = 'status' | 'pending' | 'daily' | 'statistics'

export const NavV2Page: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabType>('status')
  const [selectedDate, setSelectedDate] = useState<string>(
    new Date().toISOString().substring(0, 10)
  )

  // Query hooks
  const { data: statuses, isLoading: loadingStatus } = useNavCashRegisterStatus()
  const { data: pendingReceipts, isLoading: loadingPending } = useNavPendingReceipts(
    undefined,
    activeTab === 'pending'
  )
  const { data: dailyReceipts, isLoading: loadingDaily } = useNavDailyReceipts(
    selectedDate ? new Date(selectedDate) : undefined,
    undefined,
    activeTab === 'daily'
  )
  const { data: statistics, isLoading: loadingStats } = useNavDailyStatistics(
    selectedDate ? new Date(selectedDate) : undefined,
    activeTab === 'statistics'
  )

  // Mutation
  const syncMutation = useNavSync()

  const tabs = [
    { id: 'status' as const, label: 'Pénztárgép státusz' },
    { id: 'pending' as const, label: 'Függőben lévő' },
    { id: 'daily' as const, label: 'Napi nyugták' },
    { id: 'statistics' as const, label: 'Statisztika' },
  ]

  const handleSync = () => {
    syncMutation.mutate(undefined)
  }

  return (
    <div className="p-6">
      {/* Header */}
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">NAV Integráció</h1>
          <p className="mt-1 text-sm text-gray-500">
            NAV Online Pénztárgép kezelés és szinkronizálás
          </p>
        </div>
        <button
          onClick={handleSync}
          disabled={syncMutation.isPending}
          className={`px-4 py-2 rounded-md font-medium text-sm ${
            syncMutation.isPending
              ? 'bg-gray-300 text-gray-500 cursor-not-allowed'
              : 'bg-blue-600 hover:bg-blue-700 text-white'
          }`}
        >
          {syncMutation.isPending ? 'Szinkronizálás...' : 'Szinkronizálás indítása'}
        </button>
      </div>

      {/* Sync result */}
      {syncMutation.isSuccess && (
        <div
          className={`mb-4 p-4 rounded-md ${
            syncMutation.data.success
              ? 'bg-green-50 border border-green-200'
              : 'bg-yellow-50 border border-yellow-200'
          }`}
        >
          <p className="text-sm">
            Szinkronizálás befejezve: {syncMutation.data.successCount} sikeres,{' '}
            {syncMutation.data.failedCount} sikertelen ({syncMutation.data.sentCount}{' '}
            összesen)
          </p>
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
        {activeTab === 'status' && (
          <div className="p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Pénztárgép státusz
            </h2>

            {loadingStatus ? (
              <div className="flex justify-center items-center h-32">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {statuses?.map((status) => (
                  <NavStatusCard key={status.apNumber} status={status} />
                ))}
              </div>
            )}
          </div>
        )}

        {activeTab === 'pending' && (
          <div className="p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">
              Függőben lévő nyugták
            </h2>
            <NavReceiptTable receipts={pendingReceipts || []} loading={loadingPending} />
          </div>
        )}

        {activeTab === 'daily' && (
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900">Napi nyugták</h2>
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="px-3 py-1.5 border border-gray-300 rounded-md text-sm focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
            <NavReceiptTable receipts={dailyReceipts || []} loading={loadingDaily} />
          </div>
        )}

        {activeTab === 'statistics' && (
          <div className="p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-gray-900">Napi statisztika</h2>
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="px-3 py-1.5 border border-gray-300 rounded-md text-sm focus:ring-blue-500 focus:border-blue-500"
              />
            </div>

            {loadingStats ? (
              <div className="flex justify-center items-center h-32">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              </div>
            ) : statistics ? (
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                <div className="bg-blue-50 rounded-lg p-4">
                  <p className="text-sm text-blue-600">Összes nyugta</p>
                  <p className="text-2xl font-bold text-blue-900">
                    {statistics.totalReceipts}
                  </p>
                </div>
                <div className="bg-green-50 rounded-lg p-4">
                  <p className="text-sm text-green-600">Sikeres szinkron</p>
                  <p className="text-2xl font-bold text-green-900">
                    {statistics.successfulSyncs}
                  </p>
                </div>
                <div className="bg-red-50 rounded-lg p-4">
                  <p className="text-sm text-red-600">Sikertelen</p>
                  <p className="text-2xl font-bold text-red-900">
                    {statistics.failedSyncs}
                  </p>
                </div>
                <div className="bg-yellow-50 rounded-lg p-4">
                  <p className="text-sm text-yellow-600">Sztornó</p>
                  <p className="text-2xl font-bold text-yellow-900">
                    {statistics.stornoCount}
                  </p>
                </div>
                <div className="bg-gray-50 rounded-lg p-4 col-span-2">
                  <p className="text-sm text-gray-600">Teljes összeg</p>
                  <p className="text-2xl font-bold text-gray-900">
                    {statistics.totalAmount?.toLocaleString('hu-HU')} HUF
                  </p>
                </div>
                <div className="bg-gray-50 rounded-lg p-4 col-span-2">
                  <p className="text-sm text-gray-600">Átlagos válaszidő</p>
                  <p className="text-2xl font-bold text-gray-900">
                    {statistics.averageResponseTimeMs} ms
                  </p>
                </div>
              </div>
            ) : (
              <div className="text-center py-8 text-gray-500">
                Nincs elérhető statisztika
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}

export default NavV2Page
