import { useNavigate, Link } from 'react-router-dom'
import { Package, ArrowLeft, Info } from 'lucide-react'

/**
 * v2.4.7 (Bug #1 — /shipments/new 404 fix):
 *
 * Az "Új szállítmányigény" Link a `ShipmentListPage`-en `/shipments/new`-re mutat,
 * de a router config + page komponens hiányzott → 404 ("Oldal nem található").
 *
 * Ez egy átmeneti placeholder: a teljes szállítmányigény-létrehozási flow
 * (multi-step wizard, AML check, branch source/target select, currency table)
 * a v2.5.0 sprintben érkezik a B9 LISTAK.dll funkciókkal együtt.
 *
 * A backend POST /api/v1/shipments endpoint MÁR létezik (ShipmentController.java:52),
 * a frontend API service is implementált (transactions.ts), csak a UI hiányzott.
 *
 * Ez a placeholder:
 * - 404 megszűnik (route registry-be regisztrálva App.tsx-ben)
 * - UX: világos üzenet a featuról
 * - Vissza a listára gomb
 * - NEM hozz létre tranzakciót, NEM modify-olja a backend-et
 */
export default function ShipmentNewPage() {
  const navigate = useNavigate()

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h1 className="text-xl font-bold text-gray-800 flex items-center gap-2">
          <Package />
          Új szállítmányigény
        </h1>
        <button
          onClick={() => navigate('/shipments')}
          className="form-button flex items-center gap-2"
        >
          <ArrowLeft size={16} />
          Vissza a listához
        </button>
      </div>

      <div className="form-panel">
        <div className="flex gap-3 items-start p-4 bg-blue-50 border border-blue-200 rounded">
          <Info className="text-blue-600 flex-shrink-0 mt-0.5" size={20} />
          <div className="space-y-2">
            <h2 className="font-semibold text-blue-900">A funkció v2.5.0-ban érkezik</h2>
            <p className="text-sm text-blue-800">
              A teljes szállítmányigény-létrehozási flow (forrás-pénztár / cél-pénztár
              kiválasztás, devizanemek + címletezés, AML ellenőrzés, supervisor jóváhagyás)
              fejlesztés alatt áll a v2.5.0 sprintben.
            </p>
            <p className="text-sm text-blue-800">
              <strong>Jelenleg elérhető:</strong> a meglévő szállítmányigények listázása,
              jóváhagyása vagy elutasítása a{' '}
              <Link to="/shipments" className="underline text-blue-900 hover:text-blue-700">
                szállítmányigények listáján
              </Link>
              .
            </p>
            <p className="text-xs text-blue-700 mt-3">
              Ha sürgős átadás-átvétel szükséges, a Pénztár (Valutaváltó) menüben a
              megfelelő művelet (átadás-átvétel pénztáraknak / banki átadás) elérhető.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}
