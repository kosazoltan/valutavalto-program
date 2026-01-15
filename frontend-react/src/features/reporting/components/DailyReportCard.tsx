/**
 * DailyReportCard - Napi riport összefoglaló kártya
 *
 * @since 2026-01-13
 */

import React from 'react'
import type { DailySummary } from '../types'

interface DailyReportCardProps {
  summary: DailySummary
}

/**
 * Szám formázása magyar formátumban
 */
function formatNumber(value: number): string {
  return new Intl.NumberFormat('hu-HU').format(value)
}

/**
 * Pénzösszeg formázása
 */
function formatCurrency(value: number, currency = 'HUF'): string {
  return new Intl.NumberFormat('hu-HU', {
    style: 'currency',
    currency,
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value)
}

export const DailyReportCard: React.FC<DailyReportCardProps> = ({ summary }) => {
  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold text-gray-800">Napi összesítés</h2>
        <span className="text-sm text-gray-500">{summary.date}</span>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-blue-50 rounded-lg p-4">
          <p className="text-sm text-blue-600 font-medium">Tranzakciók</p>
          <p className="text-2xl font-bold text-blue-800">{formatNumber(summary.transactionCount)}</p>
        </div>

        <div className="bg-green-50 rounded-lg p-4">
          <p className="text-sm text-green-600 font-medium">Forgalom</p>
          <p className="text-2xl font-bold text-green-800">{formatCurrency(summary.totalTurnoverHuf)}</p>
        </div>

        <div className="bg-purple-50 rounded-lg p-4">
          <p className="text-sm text-purple-600 font-medium">Nettó eredmény</p>
          <p className={`text-2xl font-bold ${summary.netProfitHuf >= 0 ? 'text-purple-800' : 'text-red-600'}`}>
            {formatCurrency(summary.netProfitHuf)}
          </p>
        </div>

        <div className="bg-gray-50 rounded-lg p-4">
          <p className="text-sm text-gray-600 font-medium">Iroda</p>
          <p className="text-lg font-semibold text-gray-800 truncate">{summary.branchName}</p>
        </div>
      </div>

      {/* Valuta bontás */}
      {summary.currencySummaries.length > 0 && (
        <div className="border-t pt-4">
          <h3 className="text-lg font-medium text-gray-700 mb-3">Valuta bontás</h3>
          <div className="overflow-x-auto">
            <table className="min-w-full">
              <thead>
                <tr className="text-left text-xs text-gray-500 uppercase">
                  <th className="pb-2">Valuta</th>
                  <th className="pb-2 text-right">Vétel db</th>
                  <th className="pb-2 text-right">Eladás db</th>
                  <th className="pb-2 text-right">Vétel HUF</th>
                  <th className="pb-2 text-right">Eladás HUF</th>
                </tr>
              </thead>
              <tbody>
                {summary.currencySummaries.map((currency) => (
                  <tr key={currency.currencyId} className="border-t border-gray-100">
                    <td className="py-2 font-medium">{currency.currencyCode}</td>
                    <td className="py-2 text-right">{currency.buyCount}</td>
                    <td className="py-2 text-right">{currency.sellCount}</td>
                    <td className="py-2 text-right">{formatCurrency(currency.buyHufTotal)}</td>
                    <td className="py-2 text-right">{formatCurrency(currency.sellHufTotal)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Kassza egyenlegek */}
      {summary.cashBalances.length > 0 && (
        <div className="border-t pt-4 mt-4">
          <h3 className="text-lg font-medium text-gray-700 mb-3">Kassza egyenlegek</h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {summary.cashBalances.map((balance) => (
              <div key={balance.currencyId} className="bg-gray-50 rounded p-3">
                <p className="text-sm font-medium text-gray-600">{balance.currencyCode}</p>
                <p className="text-lg font-bold text-gray-800">
                  {formatNumber(balance.currentBalance)}
                </p>
                <p className={`text-xs ${balance.change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                  {balance.change >= 0 ? '+' : ''}{formatNumber(balance.change)}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="text-xs text-gray-400 mt-4 text-right">
        Generálva: {new Date(summary.generatedAt).toLocaleString('hu-HU')}
      </div>
    </div>
  )
}

export default DailyReportCard
