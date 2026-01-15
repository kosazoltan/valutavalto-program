/**
 * WorkerStatsTable - Pénztáros statisztika táblázat
 *
 * @since 2026-01-13
 */

import React from 'react'
import type { WorkerStats } from '../types'

interface WorkerStatsTableProps {
  stats: WorkerStats
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
 * Szerepkör badge színek
 */
function getRoleBadgeClass(role: string): string {
  switch (role) {
    case 'ADMIN':
      return 'bg-red-100 text-red-800'
    case 'MANAGER':
      return 'bg-purple-100 text-purple-800'
    case 'SUPERVISOR':
      return 'bg-blue-100 text-blue-800'
    case 'CASHIER':
      return 'bg-green-100 text-green-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

/**
 * Szerepkör magyar neve
 */
function getRoleName(role: string): string {
  switch (role) {
    case 'ADMIN':
      return 'Admin'
    case 'MANAGER':
      return 'Vezető'
    case 'SUPERVISOR':
      return 'Felügyelő'
    case 'CASHIER':
      return 'Pénztáros'
    default:
      return role
  }
}

export const WorkerStatsTable: React.FC<WorkerStatsTableProps> = ({ stats }) => {
  // Rendezés teljes forgalom szerint csökkenő sorrendben
  const sortedWorkers = [...stats.workers].sort(
    (a, b) => b.totalTurnoverHuf - a.totalTurnoverHuf
  )

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold text-gray-800">Pénztáros statisztika</h2>
        <span className="text-sm text-gray-500">
          {stats.startDate} - {stats.endDate}
        </span>
      </div>

      {sortedWorkers.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          Nincs adat a megadott időszakban.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="min-w-full">
            <thead>
              <tr className="text-left text-xs text-gray-500 uppercase border-b">
                <th className="pb-3 pr-4">Pénztáros</th>
                <th className="pb-3 pr-4">Szerepkör</th>
                <th className="pb-3 pr-4 text-right">Tranzakciók</th>
                <th className="pb-3 pr-4 text-right">Vétel</th>
                <th className="pb-3 pr-4 text-right">Eladás</th>
                <th className="pb-3 pr-4 text-right">Forgalom</th>
                <th className="pb-3 pr-4 text-right">Átlag/nap</th>
                <th className="pb-3 text-right">Napok</th>
              </tr>
            </thead>
            <tbody>
              {sortedWorkers.map((worker, index) => (
                <tr
                  key={worker.workerId}
                  className={`border-b border-gray-100 hover:bg-gray-50 ${
                    index === 0 ? 'bg-yellow-50' : ''
                  }`}
                >
                  <td className="py-3 pr-4">
                    <div>
                      <p className="font-medium text-gray-800">{worker.workerName}</p>
                      <p className="text-xs text-gray-500">{worker.workerCode}</p>
                    </div>
                  </td>
                  <td className="py-3 pr-4">
                    <span
                      className={`px-2 py-1 text-xs font-medium rounded-full ${getRoleBadgeClass(
                        worker.role
                      )}`}
                    >
                      {getRoleName(worker.role)}
                    </span>
                  </td>
                  <td className="py-3 pr-4 text-right">
                    <p className="font-medium">{formatNumber(worker.totalTransactions)}</p>
                    <p className="text-xs text-gray-500">
                      V: {worker.buyCount} | E: {worker.sellCount}
                    </p>
                  </td>
                  <td className="py-3 pr-4 text-right text-blue-600">
                    {formatCurrency(worker.totalBuyHuf)}
                  </td>
                  <td className="py-3 pr-4 text-right text-green-600">
                    {formatCurrency(worker.totalSellHuf)}
                  </td>
                  <td className="py-3 pr-4 text-right font-semibold">
                    {formatCurrency(worker.totalTurnoverHuf)}
                  </td>
                  <td className="py-3 pr-4 text-right">
                    {worker.avgTransactionsPerDay.toFixed(1)}
                  </td>
                  <td className="py-3 text-right">{worker.workingDays}</td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr className="bg-gray-50 font-semibold">
                <td className="py-3 pr-4">Összesen</td>
                <td className="py-3 pr-4">{sortedWorkers.length} fő</td>
                <td className="py-3 pr-4 text-right">
                  {formatNumber(sortedWorkers.reduce((sum, w) => sum + w.totalTransactions, 0))}
                </td>
                <td className="py-3 pr-4 text-right text-blue-600">
                  {formatCurrency(sortedWorkers.reduce((sum, w) => sum + w.totalBuyHuf, 0))}
                </td>
                <td className="py-3 pr-4 text-right text-green-600">
                  {formatCurrency(sortedWorkers.reduce((sum, w) => sum + w.totalSellHuf, 0))}
                </td>
                <td className="py-3 pr-4 text-right">
                  {formatCurrency(sortedWorkers.reduce((sum, w) => sum + w.totalTurnoverHuf, 0))}
                </td>
                <td className="py-3 pr-4 text-right">-</td>
                <td className="py-3 text-right">-</td>
              </tr>
            </tfoot>
          </table>
        </div>
      )}

      <div className="text-xs text-gray-400 mt-4 text-right">
        Generálva: {new Date(stats.generatedAt).toLocaleString('hu-HU')}
      </div>
    </div>
  )
}

export default WorkerStatsTable
