/**
 * RateComparisonTable - Árfolyam összehasonlítás táblázat
 *
 * @since 2026-01-13
 */

import React from 'react'
import type { RateComparison } from '../types'

interface RateComparisonTableProps {
  comparisons: RateComparison[]
  loading?: boolean
}

export const RateComparisonTable: React.FC<RateComparisonTableProps> = ({
  comparisons,
  loading,
}) => {
  if (loading) {
    return (
      <div className="flex justify-center items-center h-32">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (!comparisons || comparisons.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        Nincs megjeleníthető összehasonlítás
      </div>
    )
  }

  const getSpreadColor = (spread: number) => {
    if (Math.abs(spread) < 1) return 'text-green-600'
    if (Math.abs(spread) < 3) return 'text-yellow-600'
    return 'text-red-600'
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Valuta
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              MNB árfolyam
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Vételi árfolyam
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Vételi spread
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Eladási árfolyam
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Eladási spread
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {comparisons.map((comparison) => (
            <tr key={comparison.currencyCode} className="hover:bg-gray-50">
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-md text-sm font-medium bg-blue-100 text-blue-800">
                  {comparison.currencyCode}
                </span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-right font-mono text-gray-900">
                {comparison.mnbRate?.toFixed(2) || '-'}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-right font-mono text-gray-900">
                {comparison.internalBuyRate?.toFixed(2) || '-'}
              </td>
              <td
                className={`px-6 py-4 whitespace-nowrap text-sm text-right font-mono font-medium ${getSpreadColor(comparison.buySpread)}`}
              >
                {comparison.buySpread?.toFixed(2) || '-'}%
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-right font-mono text-gray-900">
                {comparison.internalSellRate?.toFixed(2) || '-'}
              </td>
              <td
                className={`px-6 py-4 whitespace-nowrap text-sm text-right font-mono font-medium ${getSpreadColor(comparison.sellSpread)}`}
              >
                {comparison.sellSpread?.toFixed(2) || '-'}%
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export default RateComparisonTable
