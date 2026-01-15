/**
 * MnbRatesTable - MNB árfolyamok táblázat komponens
 *
 * @since 2026-01-13
 */

import React from 'react'
import type { MnbRateDto } from '../types'

interface MnbRatesTableProps {
  rates: MnbRateDto[]
  loading?: boolean
}

export const MnbRatesTable: React.FC<MnbRatesTableProps> = ({ rates, loading }) => {
  if (loading) {
    return (
      <div className="flex justify-center items-center h-32">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (!rates || rates.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">Nincs megjeleníthető árfolyam</div>
    )
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Valuta
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Név
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Árfolyam
            </th>
            <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Változás
            </th>
            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Dátum
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {rates.map((rate) => (
            <tr key={rate.currencyCode} className="hover:bg-gray-50">
              <td className="px-6 py-4 whitespace-nowrap">
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-md text-sm font-medium bg-blue-100 text-blue-800">
                  {rate.currencyCode}
                </span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {rate.currencyName}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-right font-mono font-medium text-gray-900">
                {rate.rate?.toFixed(2) || '-'} HUF
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-right">
                {rate.changePercent !== undefined && rate.changePercent !== null ? (
                  <span
                    className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                      rate.changePercent > 0
                        ? 'bg-green-100 text-green-800'
                        : rate.changePercent < 0
                          ? 'bg-red-100 text-red-800'
                          : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {rate.changePercent > 0 ? '+' : ''}
                    {rate.changePercent.toFixed(2)}%
                  </span>
                ) : (
                  <span className="text-gray-400">-</span>
                )}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {rate.rateDate || '-'}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export default MnbRatesTable
