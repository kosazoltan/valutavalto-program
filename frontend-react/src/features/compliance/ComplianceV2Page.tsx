/**
 * ComplianceV2Page - Új moduláris compliance oldal
 *
 * Útvonal: /compliance-v2
 *
 * @since 2026-01-13
 */

import React, { useState } from 'react'
import {
  useComplianceCheck,
  useCustomerProfile,
  useDailyComplianceSummary,
} from './hooks/useCompliance'
import { ComplianceCheckResult } from './components/ComplianceCheckResult'
import { CustomerRiskCard } from './components/CustomerRiskCard'
import { useAuthStore } from '../../stores/authStore'

/**
 * Szám formázása
 */
function formatNumber(value: number): string {
  return new Intl.NumberFormat('hu-HU').format(value)
}

/**
 * Pénzösszeg formázása
 */
function formatCurrency(value: number): string {
  return new Intl.NumberFormat('hu-HU', {
    style: 'currency',
    currency: 'HUF',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value)
}

export const ComplianceV2Page: React.FC = () => {
  const { isSupervisorOrAbove } = useAuthStore()

  // Ellenőrzés form állapot
  const [checkCustomerId, setCheckCustomerId] = useState('')
  const [checkAmount, setCheckAmount] = useState('')

  // Profil keresés állapot
  const [profileCustomerId, setProfileCustomerId] = useState('')
  const [searchedProfileId, setSearchedProfileId] = useState('')

  // Mutations és queries
  const complianceCheck = useComplianceCheck()
  const dailySummary = useDailyComplianceSummary(isSupervisorOrAbove())
  const customerProfile = useCustomerProfile(searchedProfileId, !!searchedProfileId)

  // Compliance ellenőrzés indítása
  const handleCheckCompliance = (e: React.FormEvent) => {
    e.preventDefault()
    if (!checkCustomerId || !checkAmount) return

    complianceCheck.mutate({
      customerId: checkCustomerId,
      amount: parseFloat(checkAmount),
    })
  }

  // Profil keresés
  const handleSearchProfile = (e: React.FormEvent) => {
    e.preventDefault()
    if (!profileCustomerId) return
    setSearchedProfileId(profileCustomerId)
  }

  return (
    <div className="container mx-auto px-4 py-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-800">Megfelelőség</h1>
        <p className="text-gray-600">AML ellenőrzések és ügyfél kockázati profilok (v2)</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Bal oldal - Ellenőrzések */}
        <div className="space-y-6">
          {/* Compliance ellenőrzés form */}
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-lg font-semibold text-gray-800 mb-4">
              Tranzakció előtti ellenőrzés
            </h2>
            <form onSubmit={handleCheckCompliance} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Ügyfél azonosító (okmányszám)
                </label>
                <input
                  type="text"
                  value={checkCustomerId}
                  onChange={(e) => setCheckCustomerId(e.target.value)}
                  placeholder="pl. AB123456"
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Tervezett összeg (HUF)
                </label>
                <input
                  type="number"
                  value={checkAmount}
                  onChange={(e) => setCheckAmount(e.target.value)}
                  placeholder="pl. 1000000"
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <button
                type="submit"
                disabled={complianceCheck.isPending}
                className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-md disabled:opacity-50"
              >
                {complianceCheck.isPending ? 'Ellenőrzés...' : 'Ellenőrzés indítása'}
              </button>
            </form>
          </div>

          {/* Ellenőrzés eredménye */}
          {complianceCheck.data && (
            <ComplianceCheckResult
              result={complianceCheck.data}
              onClose={() => complianceCheck.reset()}
            />
          )}

          {complianceCheck.error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
              <p className="font-medium">Hiba történt</p>
              <p className="text-sm">{complianceCheck.error.message}</p>
            </div>
          )}
        </div>

        {/* Jobb oldal - Profil és összesítés */}
        <div className="space-y-6">
          {/* Napi összesítés */}
          {isSupervisorOrAbove() && dailySummary.data && (
            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">Napi compliance összesítés</h2>
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-blue-50 rounded-lg p-4">
                  <p className="text-sm text-blue-600">Tranzakciók</p>
                  <p className="text-2xl font-bold text-blue-800">
                    {formatNumber(dailySummary.data.totalTransactions)}
                  </p>
                </div>
                <div className="bg-orange-50 rounded-lg p-4">
                  <p className="text-sm text-orange-600">Nagy tranzakciók</p>
                  <p className="text-2xl font-bold text-orange-800">
                    {formatNumber(dailySummary.data.largeTransactionCount)}
                  </p>
                </div>
                <div className="bg-green-50 rounded-lg p-4">
                  <p className="text-sm text-green-600">Ügyfelek</p>
                  <p className="text-2xl font-bold text-green-800">
                    {formatNumber(dailySummary.data.uniqueCustomers)}
                  </p>
                </div>
                <div className="bg-purple-50 rounded-lg p-4">
                  <p className="text-sm text-purple-600">Forgalom</p>
                  <p className="text-xl font-bold text-purple-800">
                    {formatCurrency(dailySummary.data.totalTurnover)}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Ügyfél profil keresés */}
          {isSupervisorOrAbove() && (
            <div className="bg-white rounded-lg shadow-md p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">Ügyfél kockázati profil</h2>
              <form onSubmit={handleSearchProfile} className="flex gap-2 mb-4">
                <input
                  type="text"
                  value={profileCustomerId}
                  onChange={(e) => setProfileCustomerId(e.target.value)}
                  placeholder="Ügyfél azonosító..."
                  className="flex-1 border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                />
                <button
                  type="submit"
                  disabled={customerProfile.isFetching}
                  className="bg-gray-600 hover:bg-gray-700 text-white font-medium py-2 px-4 rounded-md disabled:opacity-50"
                >
                  Keresés
                </button>
              </form>
            </div>
          )}

          {/* Profil eredmény */}
          {customerProfile.data && <CustomerRiskCard profile={customerProfile.data} />}

          {customerProfile.error && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
              <p className="font-medium">Hiba történt</p>
              <p className="text-sm">{customerProfile.error.message}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default ComplianceV2Page
