/**
 * ComplianceCheckResult - Compliance ellenőrzés eredmény komponens
 *
 * @since 2026-01-13
 */

import React from 'react'
import type { ComplianceCheck } from '../types'

interface ComplianceCheckResultProps {
  result: ComplianceCheck
  onClose?: () => void
}

/**
 * Kockázati szint színek
 */
function getRiskLevelClass(level: string): string {
  switch (level) {
    case 'LOW':
      return 'bg-green-100 text-green-800 border-green-200'
    case 'MEDIUM':
      return 'bg-yellow-100 text-yellow-800 border-yellow-200'
    case 'HIGH':
      return 'bg-orange-100 text-orange-800 border-orange-200'
    case 'CRITICAL':
      return 'bg-red-100 text-red-800 border-red-200'
    default:
      return 'bg-gray-100 text-gray-800 border-gray-200'
  }
}

/**
 * Kockázati szint magyar neve
 */
function getRiskLevelName(level: string): string {
  switch (level) {
    case 'LOW':
      return 'Alacsony'
    case 'MEDIUM':
      return 'Közepes'
    case 'HIGH':
      return 'Magas'
    case 'CRITICAL':
      return 'Kritikus'
    default:
      return level
  }
}

/**
 * Figyelmeztetés súlyosság ikon
 */
function getSeverityIcon(severity: string): string {
  switch (severity) {
    case 'INFO':
      return 'ℹ️'
    case 'WARNING':
      return '⚠️'
    case 'ERROR':
      return '❌'
    default:
      return '•'
  }
}

export const ComplianceCheckResult: React.FC<ComplianceCheckResultProps> = ({
  result,
  onClose,
}) => {
  return (
    <div
      className={`rounded-lg border-2 p-6 ${
        result.passed ? 'bg-green-50 border-green-300' : 'bg-red-50 border-red-300'
      }`}
    >
      {/* Fejléc */}
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="text-lg font-semibold">
            {result.passed ? '✓ Ellenőrzés sikeres' : '✗ Ellenőrzés sikertelen'}
          </h3>
          <p className="text-sm text-gray-600">Ügyfél: {result.customerId}</p>
        </div>
        {onClose && (
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
            aria-label="Bezárás"
          >
            ✕
          </button>
        )}
      </div>

      {/* Kockázati szint */}
      <div className="flex items-center gap-4 mb-4">
        <div
          className={`px-4 py-2 rounded-lg border ${getRiskLevelClass(result.riskLevel)}`}
        >
          <span className="font-medium">Kockázati szint: </span>
          <span className="font-bold">{getRiskLevelName(result.riskLevel)}</span>
        </div>
        <div className="text-sm">
          <span className="text-gray-500">Pontszám: </span>
          <span className="font-semibold">{result.riskScore}/100</span>
        </div>
      </div>

      {/* Figyelmeztetések */}
      {result.warnings.length > 0 && (
        <div className="mb-4">
          <h4 className="font-medium text-gray-700 mb-2">Figyelmeztetések:</h4>
          <ul className="space-y-2">
            {result.warnings.map((warning, index) => (
              <li
                key={index}
                className={`flex items-start gap-2 p-2 rounded ${
                  warning.severity === 'ERROR'
                    ? 'bg-red-100'
                    : warning.severity === 'WARNING'
                    ? 'bg-yellow-100'
                    : 'bg-blue-100'
                }`}
              >
                <span>{getSeverityIcon(warning.severity)}</span>
                <div>
                  <span className="font-medium">[{warning.code}]</span>{' '}
                  <span>{warning.message}</span>
                </div>
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Szükséges műveletek */}
      {result.requiredActions.length > 0 && (
        <div className="mb-4">
          <h4 className="font-medium text-gray-700 mb-2">Szükséges műveletek:</h4>
          <ul className="list-disc list-inside space-y-1">
            {result.requiredActions.map((action, index) => (
              <li key={index} className="text-gray-700">
                {action}
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Időbélyeg */}
      <div className="text-xs text-gray-400 text-right">
        Ellenőrizve: {new Date(result.checkedAt).toLocaleString('hu-HU')}
      </div>
    </div>
  )
}

export default ComplianceCheckResult
