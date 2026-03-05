import { useState, useCallback } from 'react';
import { searchCustomers } from '@/api/customers';
import type { Customer } from '@/types';

interface CustomerSearchProps {
  onSelect: (customer: Customer) => void;
  onClose: () => void;
}

export default function CustomerSearch({ onSelect, onClose }: CustomerSearchProps) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Customer[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [searched, setSearched] = useState(false);

  const handleSearch = useCallback(async () => {
    if (query.trim().length < 2) return;

    setIsSearching(true);
    try {
      const customers = await searchCustomers({ query: query.trim() });
      setResults(customers);
      setSearched(true);
    } catch {
      setResults([]);
    } finally {
      setIsSearching(false);
    }
  }, [query]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter') {
        void handleSearch();
      }
      if (e.key === 'Escape') {
        onClose();
      }
    },
    [handleSearch, onClose],
  );

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-bold text-gray-800">👤 Ügyfél keresés</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            ✕
          </button>
        </div>

        {/* Keresés */}
        <div className="mb-4 flex gap-2">
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            className="input-field flex-1"
            placeholder="Név vagy okmányszám..."
            autoFocus
          />
          <button
            onClick={() => void handleSearch()}
            disabled={isSearching || query.trim().length < 2}
            className="btn-primary bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
          >
            {isSearching ? '⏳' : '🔍'}
          </button>
        </div>

        {/* Eredmények */}
        <div className="max-h-80 overflow-auto">
          {results.length > 0 ? (
            <div className="space-y-2">
              {results.map((customer) => (
                <button
                  key={customer.id}
                  onClick={() => onSelect(customer)}
                  className="w-full rounded-lg border p-3 text-left hover:bg-blue-50"
                >
                  <p className="font-semibold">{customer.name}</p>
                  <p className="text-sm text-gray-500">
                    {customer.documentType}: {customer.documentNumber}
                  </p>
                  <p className="text-xs text-gray-400">
                    Születési hely: {customer.birthPlace}, {customer.birthDate}
                  </p>
                </button>
              ))}
            </div>
          ) : searched ? (
            <p className="py-8 text-center text-gray-400">
              Nincs találat. Próbáljon más keresőkifejezést.
            </p>
          ) : (
            <p className="py-8 text-center text-gray-400">
              Adjon meg legalább 2 karaktert és nyomjon Enter-t.
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
