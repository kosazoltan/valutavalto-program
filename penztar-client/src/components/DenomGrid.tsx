import { useState, useEffect, useMemo, useCallback } from 'react';
import type { Denomination } from '@/types';

interface DenomGridProps {
  currencyCode: string;
  onSave: (denominations: Denomination[]) => void;
  onClose: () => void;
}

// HUF címletek
const HUF_DENOMINATIONS = [20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5];

// Fő deviza címletek
const FOREIGN_DENOMINATIONS: Record<string, number[]> = {
  EUR: [500, 200, 100, 50, 20, 10, 5, 2, 1],
  USD: [100, 50, 20, 10, 5, 2, 1],
  GBP: [50, 20, 10, 5, 2, 1],
  CHF: [1000, 200, 100, 50, 20, 10, 5, 2, 1],
};

export default function DenomGrid({ currencyCode, onSave, onClose }: DenomGridProps) {
  const denomValues = useMemo(() => {
    if (currencyCode === 'HUF') return HUF_DENOMINATIONS;
    return FOREIGN_DENOMINATIONS[currencyCode] ?? [100, 50, 20, 10, 5, 1];
  }, [currencyCode]);

  const [counts, setCounts] = useState<Record<number, number>>(() => {
    const init: Record<number, number> = {};
    denomValues.forEach((v) => {
      init[v] = 0;
    });
    return init;
  });

  // Reset counts when currency changes
  useEffect(() => {
    const init: Record<number, number> = {};
    denomValues.forEach((v) => {
      init[v] = 0;
    });
    setCounts(init);
  }, [denomValues]);

  const total = useMemo(() => {
    return denomValues.reduce((sum, v) => sum + v * (counts[v] ?? 0), 0);
  }, [counts, denomValues]);

  const handleChange = useCallback((value: number, count: string) => {
    const num = parseInt(count, 10);
    setCounts((prev) => ({
      ...prev,
      [value]: isNaN(num) || num < 0 ? 0 : num,
    }));
  }, []);

  const handleSave = useCallback(() => {
    const denoms: Denomination[] = denomValues
      .filter((v) => (counts[v] ?? 0) > 0)
      .map((v) => ({
        value: v,
        count: counts[v] ?? 0,
        currencyCode: currencyCode as Denomination['currencyCode'],
      }));
    onSave(denoms);
  }, [counts, denomValues, currencyCode, onSave]);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-bold text-gray-800">
            🪙 Címletezés ({currencyCode})
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            ✕
          </button>
        </div>

        <div className="max-h-96 overflow-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b text-left text-sm text-gray-500">
                <th className="pb-2">Címlet</th>
                <th className="pb-2 text-center">Darab</th>
                <th className="pb-2 text-right">Összeg</th>
              </tr>
            </thead>
            <tbody>
              {denomValues.map((value) => (
                <tr key={value} className="border-b">
                  <td className="py-2 font-semibold">
                    {value.toLocaleString('hu-HU')} {currencyCode}
                  </td>
                  <td className="py-2 text-center">
                    <input
                      type="number"
                      value={counts[value] ?? 0}
                      onChange={(e) => handleChange(value, e.target.value)}
                      className="w-20 rounded border px-2 py-1 text-center"
                      min="0"
                    />
                  </td>
                  <td className="py-2 text-right font-mono">
                    {(value * (counts[value] ?? 0)).toLocaleString('hu-HU')}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Összesítés */}
        <div className="mt-4 flex items-center justify-between border-t pt-4">
          <span className="text-lg font-bold">
            Összesen: {total.toLocaleString('hu-HU')} {currencyCode}
          </span>
          <div className="flex gap-2">
            <button
              onClick={onClose}
              className="rounded-lg border px-4 py-2 text-sm hover:bg-gray-50"
            >
              Mégse
            </button>
            <button
              onClick={handleSave}
              className="btn-primary bg-blue-600 hover:bg-blue-700"
            >
              Mentés
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
