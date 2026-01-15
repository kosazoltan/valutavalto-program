/**
 * NavStatusCard - NAV pénztárgép státusz kártya
 *
 * @since 2026-01-13
 */

import React from 'react'
import type { NavCashRegisterStatus } from '../types'

interface NavStatusCardProps {
  status: NavCashRegisterStatus
}

export const NavStatusCard: React.FC<NavStatusCardProps> = ({ status }) => {
  return (
    <div className="bg-white rounded-lg shadow p-4 border border-gray-200">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-lg font-semibold text-gray-900">{status.apNumber}</h3>
        <span
          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
            status.online
              ? 'bg-green-100 text-green-800'
              : 'bg-red-100 text-red-800'
          }`}
        >
          {status.online ? 'Online' : 'Offline'}
        </span>
      </div>

      <div className="space-y-2 text-sm">
        <div className="flex justify-between">
          <span className="text-gray-500">Státusz:</span>
          <span className="font-medium text-gray-900">{status.status}</span>
        </div>

        <div className="flex justify-between">
          <span className="text-gray-500">Függőben lévő nyugták:</span>
          <span
            className={`font-medium ${
              status.pendingReceipts > 0 ? 'text-yellow-600' : 'text-green-600'
            }`}
          >
            {status.pendingReceipts}
          </span>
        </div>

        {status.lastSync && (
          <div className="flex justify-between">
            <span className="text-gray-500">Utolsó szinkron:</span>
            <span className="text-gray-900">
              {new Date(status.lastSync).toLocaleString('hu-HU')}
            </span>
          </div>
        )}

        {status.responseTimeMs && (
          <div className="flex justify-between">
            <span className="text-gray-500">Válaszidő:</span>
            <span className="text-gray-900">{status.responseTimeMs} ms</span>
          </div>
        )}

        {status.errorMessage && (
          <div className="mt-2 p-2 bg-red-50 rounded text-red-700 text-xs">
            {status.errorMessage}
          </div>
        )}
      </div>
    </div>
  )
}

export default NavStatusCard
