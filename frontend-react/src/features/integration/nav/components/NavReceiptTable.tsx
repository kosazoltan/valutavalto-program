/**
 * NavReceiptTable - NAV nyugta táblázat
 *
 * @since 2026-01-13
 */

import React from 'react'
import type { NavReceipt } from '../types'

interface NavReceiptTableProps {
  receipts: NavReceipt[]
  loading?: boolean
}

export const NavReceiptTable: React.FC<NavReceiptTableProps> = ({ receipts, loading }) => {
  if (loading) {
    return (
      <div className="flex justify-center items-center h-32">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (!receipts || receipts.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">Nincs megjeleníthető nyugta</div>
    )
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              Nyugta szám
            </th>
            <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              AP szám
            </th>
            <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              Típus
            </th>
            <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">
              Összeg
            </th>
            <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">
              NAV státusz
            </th>
            <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">
              Időpont
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {receipts.map((receipt) => (
            <tr key={receipt.id} className="hover:bg-gray-50">
              <td className="px-4 py-3 whitespace-nowrap text-sm font-medium text-gray-900">
                {receipt.receiptNumber}
              </td>
              <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                {receipt.apNumber}
              </td>
              <td className="px-4 py-3 whitespace-nowrap">
                <span
                  className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${
                    receipt.receiptType === 'STORNO'
                      ? 'bg-red-100 text-red-800'
                      : receipt.receiptType === 'COPY'
                        ? 'bg-gray-100 text-gray-800'
                        : 'bg-blue-100 text-blue-800'
                  }`}
                >
                  {receipt.receiptType}
                </span>
              </td>
              <td className="px-4 py-3 whitespace-nowrap text-sm text-right font-mono">
                {receipt.totalAmount?.toLocaleString('hu-HU')} {receipt.currency}
              </td>
              <td className="px-4 py-3 whitespace-nowrap text-center">
                {receipt.sentToNav ? (
                  <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    Küldve
                  </span>
                ) : (
                  <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                    Függőben
                  </span>
                )}
              </td>
              <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                {new Date(receipt.createdAt).toLocaleString('hu-HU')}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

export default NavReceiptTable
