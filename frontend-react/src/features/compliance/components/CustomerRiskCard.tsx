/**
 * CustomerRiskCard - Ügyfél kockázati profil kártya
 *
 * @since 2026-01-13
 */

import React from 'react'
import type { CustomerRiskProfile } from '../types'

interface CustomerRiskCardProps {
  profile: CustomerRiskProfile
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

/**
 * Kockázati szint színek
 */
function getRiskLevelClass(level: string): string {
  switch (level) {
    case 'LOW':
      return 'bg-green-500'
    case 'MEDIUM':
      return 'bg-yellow-500'
    case 'HIGH':
      return 'bg-orange-500'
    case 'CRITICAL':
      return 'bg-red-500'
    default:
      return 'bg-gray-500'
  }
}

export const CustomerRiskCard: React.FC<CustomerRiskCardProps> = ({ profile }) => {
  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      {/* Fejléc */}
      <div className="flex justify-between items-start mb-6">
        <div>
          <h2 className="text-xl font-bold text-gray-800">{profile.customerName}</h2>
          <p className="text-sm text-gray-500">ID: {profile.customerId}</p>
        </div>
        <div className="flex items-center gap-2">
          {profile.isPep && (
            <span className="px-2 py-1 bg-purple-100 text-purple-800 text-xs font-medium rounded-full">
              PEP
            </span>
          )}
          {profile.isBlacklisted && (
            <span className="px-2 py-1 bg-red-100 text-red-800 text-xs font-medium rounded-full">
              Feketelistán
            </span>
          )}
        </div>
      </div>

      {/* Kockázati mutató */}
      <div className="mb-6">
        <div className="flex justify-between items-center mb-2">
          <span className="text-sm font-medium text-gray-600">Kockázati szint</span>
          <span className="text-sm font-bold">{profile.riskScore}/100</span>
        </div>
        <div className="h-3 bg-gray-200 rounded-full overflow-hidden">
          <div
            className={`h-full ${getRiskLevelClass(profile.riskLevel)} transition-all`}
            style={{ width: `${profile.riskScore}%` }}
          />
        </div>
        <p className="text-xs text-gray-500 mt-1">
          {profile.riskLevel === 'LOW' && 'Alacsony kockázat'}
          {profile.riskLevel === 'MEDIUM' && 'Közepes kockázat'}
          {profile.riskLevel === 'HIGH' && 'Magas kockázat - fokozott figyelemmel kísérni'}
          {profile.riskLevel === 'CRITICAL' && 'Kritikus kockázat - vezetői jóváhagyás szükséges'}
        </p>
      </div>

      {/* Statisztikák */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        <div className="bg-gray-50 rounded-lg p-4">
          <p className="text-sm text-gray-500">Elmúlt 30 nap</p>
          <p className="text-lg font-bold text-gray-800">
            {profile.transactionCount30Days} tranzakció
          </p>
          <p className="text-sm text-gray-600">{formatCurrency(profile.totalAmountHuf30Days)}</p>
        </div>

        <div className="bg-gray-50 rounded-lg p-4">
          <p className="text-sm text-gray-500">Elmúlt 365 nap</p>
          <p className="text-lg font-bold text-gray-800">
            {profile.transactionCount365Days} tranzakció
          </p>
          <p className="text-sm text-gray-600">{formatCurrency(profile.totalAmountHuf365Days)}</p>
        </div>

        <div className="bg-gray-50 rounded-lg p-4">
          <p className="text-sm text-gray-500">Átlagos tranzakció</p>
          <p className="text-lg font-bold text-gray-800">
            {formatCurrency(profile.avgTransactionSize)}
          </p>
        </div>

        <div className="bg-gray-50 rounded-lg p-4">
          <p className="text-sm text-gray-500">Legnagyobb tranzakció</p>
          <p className="text-lg font-bold text-gray-800">
            {formatCurrency(profile.maxTransactionSize)}
          </p>
        </div>
      </div>

      {/* Gyakori valuták */}
      {profile.frequentCurrencies.length > 0 && (
        <div className="mb-6">
          <p className="text-sm font-medium text-gray-600 mb-2">Gyakori valuták</p>
          <div className="flex flex-wrap gap-2">
            {profile.frequentCurrencies.map((currency) => (
              <span
                key={currency}
                className="px-3 py-1 bg-blue-100 text-blue-800 text-sm font-medium rounded-full"
              >
                {currency}
              </span>
            ))}
          </div>
        </div>
      )}

      {/* Kockázati tényezők */}
      {profile.riskFactors.length > 0 && (
        <div className="mb-6">
          <p className="text-sm font-medium text-gray-600 mb-2">Kockázati tényezők</p>
          <ul className="space-y-2">
            {profile.riskFactors.map((factor, index) => (
              <li
                key={index}
                className="flex justify-between items-center p-2 bg-orange-50 rounded"
              >
                <div>
                  <span className="text-sm font-medium">[{factor.code}]</span>{' '}
                  <span className="text-sm text-gray-700">{factor.description}</span>
                </div>
                <span className="text-sm font-bold text-orange-600">+{factor.points} pont</span>
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Tranzakciós időszak */}
      {(profile.firstTransactionDate || profile.lastTransactionDate) && (
        <div className="border-t pt-4">
          <p className="text-xs text-gray-500">
            {profile.firstTransactionDate && (
              <span>
                Első tranzakció:{' '}
                {new Date(profile.firstTransactionDate).toLocaleDateString('hu-HU')}
              </span>
            )}
            {profile.firstTransactionDate && profile.lastTransactionDate && ' | '}
            {profile.lastTransactionDate && (
              <span>
                Utolsó tranzakció:{' '}
                {new Date(profile.lastTransactionDate).toLocaleDateString('hu-HU')}
              </span>
            )}
          </p>
        </div>
      )}

      <div className="text-xs text-gray-400 mt-4 text-right">
        Generálva: {new Date(profile.generatedAt).toLocaleString('hu-HU')}
      </div>
    </div>
  )
}

export default CustomerRiskCard
