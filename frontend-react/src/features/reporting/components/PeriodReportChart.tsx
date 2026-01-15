/**
 * PeriodReportChart - Időszaki riport diagram
 *
 * @since 2026-01-13
 */

import React from 'react'
import type { PeriodReport } from '../types'

interface PeriodReportChartProps {
  report: PeriodReport
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
function formatCurrency(value: number): string {
  return new Intl.NumberFormat('hu-HU', {
    style: 'currency',
    currency: 'HUF',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(value)
}

/**
 * Egyszerű oszlop diagram komponens
 */
const SimpleBarChart: React.FC<{ data: PeriodReport['dailyBreakdown']; maxValue: number }> = ({
  data,
  maxValue,
}) => {
  if (data.length === 0) return null

  return (
    <div className="flex items-end space-x-1 h-40 overflow-x-auto pb-6">
      {data.map((day, index) => {
        const buyHeight = maxValue > 0 ? (day.buyHuf / maxValue) * 100 : 0
        const sellHeight = maxValue > 0 ? (day.sellHuf / maxValue) * 100 : 0

        return (
          <div key={index} className="flex flex-col items-center min-w-8 group relative">
            <div className="flex space-x-0.5 h-32">
              <div
                className="w-3 bg-blue-400 rounded-t transition-all hover:bg-blue-500"
                style={{ height: `${buyHeight}%` }}
                title={`Vétel: ${formatCurrency(day.buyHuf)}`}
              />
              <div
                className="w-3 bg-green-400 rounded-t transition-all hover:bg-green-500"
                style={{ height: `${sellHeight}%` }}
                title={`Eladás: ${formatCurrency(day.sellHuf)}`}
              />
            </div>
            <span className="text-xs text-gray-400 mt-1 transform -rotate-45 origin-top-left whitespace-nowrap">
              {new Date(day.date).toLocaleDateString('hu-HU', { month: '2-digit', day: '2-digit' })}
            </span>

            {/* Tooltip */}
            <div className="absolute bottom-full mb-2 hidden group-hover:block bg-gray-800 text-white text-xs rounded px-2 py-1 whitespace-nowrap z-10">
              <p>Vétel: {formatCurrency(day.buyHuf)}</p>
              <p>Eladás: {formatCurrency(day.sellHuf)}</p>
              <p>Nettó: {formatCurrency(day.netHuf)}</p>
            </div>
          </div>
        )
      })}
    </div>
  )
}

export const PeriodReportChart: React.FC<PeriodReportChartProps> = ({ report }) => {
  // Maximum érték meghatározása a skálához
  const maxValue = Math.max(
    ...report.dailyBreakdown.map((d) => Math.max(d.buyHuf, d.sellHuf)),
    1
  )

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold text-gray-800">Időszaki riport</h2>
        <span className="text-sm text-gray-500">
          {report.startDate} - {report.endDate}
        </span>
      </div>

      {/* Összesítő statisztikák */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-blue-50 rounded-lg p-4">
          <p className="text-sm text-blue-600 font-medium">Összes tranzakció</p>
          <p className="text-2xl font-bold text-blue-800">
            {formatNumber(report.totalTransactionCount)}
          </p>
          <p className="text-xs text-blue-500">
            Átlag: {report.avgDailyTransactions.toFixed(1)}/nap
          </p>
        </div>

        <div className="bg-green-50 rounded-lg p-4">
          <p className="text-sm text-green-600 font-medium">Összes eladás</p>
          <p className="text-2xl font-bold text-green-800">{formatCurrency(report.totalSellHuf)}</p>
          <p className="text-xs text-green-500">{report.totalSellCount} db</p>
        </div>

        <div className="bg-orange-50 rounded-lg p-4">
          <p className="text-sm text-orange-600 font-medium">Összes vétel</p>
          <p className="text-2xl font-bold text-orange-800">{formatCurrency(report.totalBuyHuf)}</p>
          <p className="text-xs text-orange-500">{report.totalBuyCount} db</p>
        </div>

        <div className="bg-purple-50 rounded-lg p-4">
          <p className="text-sm text-purple-600 font-medium">Nettó forgalom</p>
          <p
            className={`text-2xl font-bold ${
              report.netTurnoverHuf >= 0 ? 'text-purple-800' : 'text-red-600'
            }`}
          >
            {formatCurrency(report.netTurnoverHuf)}
          </p>
          <p className="text-xs text-purple-500">Átlag: {formatCurrency(report.avgDailyTurnover)}/nap</p>
        </div>
      </div>

      {/* Diagram */}
      <div className="border-t pt-4">
        <h3 className="text-lg font-medium text-gray-700 mb-3">Napi bontás</h3>
        <div className="flex items-center space-x-4 mb-2">
          <div className="flex items-center">
            <div className="w-3 h-3 bg-blue-400 rounded mr-1" />
            <span className="text-xs text-gray-600">Vétel</span>
          </div>
          <div className="flex items-center">
            <div className="w-3 h-3 bg-green-400 rounded mr-1" />
            <span className="text-xs text-gray-600">Eladás</span>
          </div>
        </div>
        <SimpleBarChart data={report.dailyBreakdown} maxValue={maxValue} />
      </div>

      {/* További statisztikák */}
      <div className="grid grid-cols-3 gap-4 mt-4 pt-4 border-t">
        <div className="text-center">
          <p className="text-sm text-gray-500">Napok száma</p>
          <p className="text-lg font-semibold">{report.dayCount}</p>
        </div>
        <div className="text-center">
          <p className="text-sm text-gray-500">Kezelési díjak</p>
          <p className="text-lg font-semibold">{formatCurrency(report.totalHandlingFees)}</p>
        </div>
        <div className="text-center">
          <p className="text-sm text-gray-500">Kedvezmények</p>
          <p className="text-lg font-semibold">{formatCurrency(report.totalDiscounts)}</p>
        </div>
      </div>

      <div className="text-xs text-gray-400 mt-4 text-right">
        Generálva: {new Date(report.generatedAt).toLocaleString('hu-HU')}
      </div>
    </div>
  )
}

export default PeriodReportChart
