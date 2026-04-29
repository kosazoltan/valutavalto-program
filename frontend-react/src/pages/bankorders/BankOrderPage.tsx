/**
 * Banki rendelés workflow oldal — v2.3.15 SKELETON
 *
 * Ez egy placeholder UI a teljes E-B8 banki workflow-hoz. A backend implementáció
 * (BankOrderController + bank_order entitás + V168 migráció) GitHub issue-ban
 * követhető — ld. https://github.com/kosazoltan/valutavalto-program/issues/279
 *
 * Tervezett funkcionalitás (v2.4.0):
 * 1. Banki rendelés workflow (request → approval → execution)
 *    - Ki: értéktár (banki valuta-rendelés)
 *    - Be: bank (Erste / OTP / KH / Raiffeisen)
 *    - Workflow: pending → approved (ügyvezető) → executed (értéktár átveszi)
 * 2. Western Union napi keret (USD-ban)
 *    - Napi limit: $10,000 (állítható)
 *    - Felhasználás-tracking: tranzakciónként csökkentés
 *    - Reset: 00:00-kor automatikus
 * 3. Sürgősségi banki kivét (ha készlet < limit)
 *    - Trigger: értéktári készlet < critical threshold
 *    - Auto-notification az ügyvezetőnek
 *    - Approval workflow: rapid (1 perc max)
 *
 * 2026-04-29 v2.3.15: csak skeleton UI, hogy a sidebar link működjön és a
 * felhasználónak látható legyen a tervezett feature.
 */

import { Building2, AlertCircle, Clock } from 'lucide-react'
import { Link } from 'react-router-dom'

export default function BankOrderPage() {
  return (
    <div className="space-y-4 p-4">
      <div className="flex items-center gap-2">
        <Building2 className="h-6 w-6 text-blue-600" />
        <h1 className="text-xl font-bold text-gray-800">Banki rendelés workflow</h1>
        <span className="px-2 py-0.5 bg-yellow-100 text-yellow-800 text-xs rounded font-semibold">
          v2.4.0 előzetes (skeleton)
        </span>
      </div>

      <div className="bg-blue-50 border border-blue-200 rounded p-4 text-sm text-blue-800 space-y-2">
        <div className="font-semibold flex items-center gap-2">
          <AlertCircle className="h-4 w-4" />
          Ez egy előzetes skeleton oldal — a teljes implementáció a v2.4.0-ben érkezik.
        </div>
        <p>
          Az E-B8 banki workflow 3 fő funkcionalitást fog tartalmazni:
        </p>
        <ul className="list-disc ml-6 space-y-1">
          <li><strong>Banki rendelés (request → approval → execution)</strong> — értéktár valuta-rendelése a banktól, ügyvezetői jóváhagyással</li>
          <li><strong>Western Union napi keret</strong> — USD napi limit ($10,000) tracking + napi automatikus reset</li>
          <li><strong>Sürgősségi banki kivét</strong> — automatikus notification ha értéktári készlet alá esik a critical threshold-nak</li>
        </ul>
        <p className="text-xs italic">
          Backend implementáció: BankOrderController + `bank_order` entity + V168 Flyway migration.
          Issue: <a href="https://github.com/kosazoltan/valutavalto-program/issues/279" target="_blank" rel="noopener noreferrer" className="underline">kosazoltan/valutavalto-program#279</a>
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <SkeletonCard
          title="Banki rendelések"
          description="Aktív + függő rendelések listázása, új rendelés indítása"
          status="placeholder"
        />
        <SkeletonCard
          title="Western Union napi keret"
          description="USD napi limit állapota + felhasználás-grafikon"
          status="placeholder"
        />
        <SkeletonCard
          title="Sürgősségi kivét"
          description="Készlet-alarms + rapid approval workflow"
          status="placeholder"
        />
      </div>

      <div className="bg-gray-50 border border-gray-200 rounded p-4 text-sm text-gray-700">
        <div className="font-semibold mb-2">Visszatérés:</div>
        <Link to="/transfers" className="text-blue-600 underline hover:text-blue-800">
          ← Átadás bank / másik értéktár (jelenlegi workflow)
        </Link>
      </div>
    </div>
  )
}

function SkeletonCard({ title, description, status }: { title: string; description: string; status: 'placeholder' | 'beta' | 'live' }) {
  const statusStyle = {
    placeholder: 'bg-gray-100 text-gray-600 border-gray-300',
    beta: 'bg-yellow-100 text-yellow-700 border-yellow-300',
    live: 'bg-green-100 text-green-700 border-green-300',
  }[status]
  const statusText = {
    placeholder: 'Placeholder',
    beta: 'Béta',
    live: 'Élő',
  }[status]
  return (
    <div className="bg-white border border-gray-200 rounded p-4 shadow-sm">
      <div className="flex items-center justify-between mb-2">
        <div className="font-semibold text-gray-800">{title}</div>
        <span className={`px-2 py-0.5 text-[10px] rounded border ${statusStyle}`}>
          {statusText}
        </span>
      </div>
      <p className="text-sm text-gray-600 mb-3">{description}</p>
      <div className="flex items-center gap-2 text-xs text-gray-400">
        <Clock className="h-3 w-3" />
        v2.4.0
      </div>
    </div>
  )
}
