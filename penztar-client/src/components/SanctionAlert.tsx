/**
 * SanctionAlert — Szankciós szűrés figyelmeztetés komponens.
 *
 * JOGSZABÁLYI KÖTELEZETTSÉG — Pmt. 2017. évi LIII. tv.
 *
 * Három állapot:
 * - CLEAR → rejtett (nincs megjelenítés)
 * - POSSIBLE → SÁRGA figyelmeztetés, supervisor jóváhagyás szükséges
 * - CONFIRMED → PIROS tiltás, tranzakció NEM hajtható végre
 */

import { useState } from 'react';
import type { SanctionScreeningResult, SanctionRiskLevel } from '@/types';

interface SanctionAlertProps {
  /** Szűrés eredménye */
  result: SanctionScreeningResult;
  /** Supervisor jóváhagyás callback (POSSIBLE esetén) */
  onSupervisorApprove?: () => void;
  /** Tiltás/elutasítás callback (CONFIRMED esetén) */
  onBlock?: () => void;
}

const RISK_STYLES: Record<SanctionRiskLevel, { bg: string; border: string; icon: string; title: string }> = {
  CLEAR: {
    bg: '',
    border: '',
    icon: '',
    title: '',
  },
  POSSIBLE: {
    bg: 'bg-yellow-50',
    border: 'border-yellow-400',
    icon: '⚠️',
    title: 'LEHETSÉGES SZANKCIÓS TALÁLAT',
  },
  CONFIRMED: {
    bg: 'bg-red-50',
    border: 'border-red-500',
    icon: '🚨',
    title: 'SZANKCIÓS LISTA — TILTÁS!',
  },
};

export default function SanctionAlert({ result, onSupervisorApprove, onBlock }: SanctionAlertProps) {
  const [supervisorPassword, setSupervisorPassword] = useState('');
  const [showSupervisorInput, setShowSupervisorInput] = useState(false);

  // CLEAR → nem jelenítünk meg semmit
  if (result.riskLevel === 'CLEAR') {
    return null;
  }

  const style = RISK_STYLES[result.riskLevel];

  return (
    <div className={`rounded-xl border-2 ${style.border} ${style.bg} p-4 shadow-lg`}>
      {/* Fejléc */}
      <div className="mb-3 flex items-center gap-2">
        <span className="text-2xl">{style.icon}</span>
        <h3 className={`text-lg font-bold ${
          result.riskLevel === 'CONFIRMED' ? 'text-red-700' : 'text-yellow-700'
        }`}>
          {style.title}
        </h3>
      </div>

      {/* Találatok listája */}
      <div className="mb-3 space-y-2">
        {result.matches.map((match, idx) => (
          <div
            key={`${match.entryId}-${idx}`}
            className="rounded-lg border bg-white p-3 text-sm"
          >
            <div className="flex items-center justify-between">
              <span className="font-semibold text-gray-800">{match.fullName}</span>
              <span className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                match.matchType === 'EXACT'
                  ? 'bg-red-100 text-red-700'
                  : match.matchType === 'PARTIAL'
                  ? 'bg-yellow-100 text-yellow-700'
                  : 'bg-orange-100 text-orange-700'
              }`}>
                {match.matchType === 'EXACT' ? 'Pontos egyezés' :
                 match.matchType === 'PARTIAL' ? 'Részleges egyezés' : 'Alias egyezés'}
              </span>
            </div>
            <div className="mt-1 flex gap-4 text-xs text-gray-500">
              {match.nationality && <span>🌍 {match.nationality}</span>}
              {match.dateOfBirth && <span>📅 {match.dateOfBirth}</span>}
              {match.listType && <span>📋 {match.listType} lista</span>}
              <span>📊 {Math.round(match.score * 100)}% egyezés</span>
            </div>
          </div>
        ))}
      </div>

      {/* CONFIRMED — teljes tiltás */}
      {result.riskLevel === 'CONFIRMED' && (
        <div className="rounded-lg bg-red-100 p-3">
          <p className="text-sm font-bold text-red-800">
            🚫 A tranzakció NEM hajtható végre!
          </p>
          <p className="text-xs text-red-700">
            Az ügyfél szerepel az ENSZ/EU szankciós listán. A tranzakció végrehajtása jogszabálysértés.
            Az eset naplózásra került.
          </p>
          {onBlock && (
            <button
              onClick={onBlock}
              className="mt-2 rounded-lg bg-red-600 px-4 py-2 text-sm font-bold text-white hover:bg-red-700"
            >
              Megértettem — Tranzakció visszavonása
            </button>
          )}
        </div>
      )}

      {/* POSSIBLE — supervisor jóváhagyás */}
      {result.riskLevel === 'POSSIBLE' && (
        <div className="rounded-lg bg-yellow-100 p-3">
          <p className="text-sm font-bold text-yellow-800">
            ⚠️ Supervisor jóváhagyás szükséges a tranzakció folytatásához!
          </p>
          {!showSupervisorInput ? (
            <div className="mt-2 flex gap-2">
              <button
                onClick={() => setShowSupervisorInput(true)}
                className="rounded-lg bg-yellow-600 px-4 py-2 text-sm font-bold text-white hover:bg-yellow-700"
              >
                🔑 Supervisor engedélyezés
              </button>
              {onBlock && (
                <button
                  onClick={onBlock}
                  className="rounded-lg bg-gray-500 px-4 py-2 text-sm font-bold text-white hover:bg-gray-600"
                >
                  ✕ Mégsem
                </button>
              )}
            </div>
          ) : (
            <div className="mt-2 space-y-2">
              <input
                type="password"
                value={supervisorPassword}
                onChange={(e) => setSupervisorPassword(e.target.value)}
                placeholder="Supervisor jelszó"
                className="w-full rounded-lg border border-yellow-400 px-3 py-2 text-sm"
                autoFocus
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && supervisorPassword.length > 0) {
                    onSupervisorApprove?.();
                  }
                }}
              />
              <div className="flex gap-2">
                <button
                  onClick={() => {
                    if (supervisorPassword.length > 0) {
                      onSupervisorApprove?.();
                    }
                  }}
                  disabled={supervisorPassword.length === 0}
                  className="rounded-lg bg-green-600 px-4 py-2 text-sm font-bold text-white hover:bg-green-700 disabled:bg-gray-300"
                >
                  ✅ Engedélyezés
                </button>
                <button
                  onClick={() => {
                    setShowSupervisorInput(false);
                    setSupervisorPassword('');
                  }}
                  className="rounded-lg bg-gray-400 px-3 py-2 text-sm text-white hover:bg-gray-500"
                >
                  Mégsem
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
