import { HelpCircle, X } from 'lucide-react'

/**
 * T9.F (FK-04) — Képletszintaxis használati útmutató a csoport árfolyamlapokhoz.
 *
 * A 0-s lap (FK_01) súgóját egészíti ki a J–S és #NNL hivatkozásokkal, ott megjelenítve,
 * ahol a felhasználó ténylegesen ír ilyen képleteket: az árfolyamkészítő csoport-lap
 * szerkesztőjében. A tartalom a `workgroupSheetFormula.ts` által ténylegesen kiértékelt
 * négy hivatkozástípust dokumentálja (A–I, J–S, !FXXX, #NNL).
 */
export function FormulaSyntaxHelp({ open, onClose }: { open: boolean; onClose: () => void }) {
  if (!open) return null
  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="formula-help-title"
        className="bg-emerald-50 border-2 border-emerald-700 rounded-lg p-6 max-w-2xl w-full max-h-[90vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between mb-3">
          <h2 id="formula-help-title" className="text-lg font-bold text-emerald-900">
            Képletszintaxis — csoport árfolyamlap
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="text-emerald-700 hover:text-emerald-900"
            title="Bezárás"
            aria-label="Bezárás"
          >
            <X size={18} />
          </button>
        </div>

        <div className="bg-white border border-emerald-300 rounded p-3 mb-3">
          <div className="font-bold text-sm mb-2 text-center">CELLA-MÓDOK</div>
          <table className="w-full text-xs">
            <tbody>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300 w-28">
                  (üres)
                </td>
                <td className="py-1 px-2 italic">
                  Automatikus érték (a J elszámoló a 0-s lap A oszlopát veszi át).
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">123,45</td>
                <td className="py-1 px-2 italic">
                  Fix érték — kézi felülírás. (Tizedeselválasztó: <b>vessző</b>.)
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">képlet</td>
                <td className="py-1 px-2 italic">
                  A képlet eredménye jelenik meg, és <b>automatikusan újraszámolódik</b>, ha a
                  hivatkozott érték változik.
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div className="bg-white border border-emerald-300 rounded p-3 mb-3">
          <div className="font-bold text-sm mb-2 text-center">HIVATKOZÁSOK</div>
          <table className="w-full text-xs">
            <tbody>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300 w-28">
                  A–C, E–I
                </td>
                <td className="py-1 px-2 italic">
                  A <b>0-s lap</b> adott érték-oszlopa az aktuális valuta sorában (pl.{' '}
                  <span className="font-mono">A</span> = elszámoló). A <b>D</b> a 0-s lap valuta ISO
                  kódja — <b>nem hivatkozható értékként</b> (mint a csoportlap K oszlopa).
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">J–S</td>
                <td className="py-1 px-2 italic">
                  Az <b>aktuális csoportlap</b> adott oszlopa az aktuális valuta sorában (pl.{' '}
                  <span className="font-mono">L</span> = alap vételi).
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">!Fxxx</td>
                <td className="py-1 px-2 italic">
                  Másik valuta oszlopa a <b>0-s lapon</b> (F=oszlop, xxx=valutakód). Pl.{' '}
                  <span className="font-mono">!FEUR</span> = az EUR sor F (eladás) oszlopa.
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">#NNL</td>
                <td className="py-1 px-2 italic">
                  Másik <b>csoportlap</b> oszlopa az aktuális valuta sorában.{' '}
                  <span className="font-mono">#</span> + kétjegyű csoportazonosító + oszlopbetű. Pl.{' '}
                  <span className="font-mono">#01L</span> = az 1-es csoport L oszlopa.
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">
                  Műveletek
                </td>
                <td className="py-1 px-2 italic">
                  + − * / és zárójel (eltérő prioritásnál a zárójel kötelező). Pl.{' '}
                  <span className="font-mono">J*0,985</span> vagy{' '}
                  <span className="font-mono">(L+M)/2</span>.
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">K</td>
                <td className="py-1 px-2 italic text-slate-500">
                  <b>Védett</b> (valuta ISO kód) — nem szerkeszthető, nem hivatkozható értékként.
                </td>
              </tr>
            </tbody>
          </table>
          <div className="mt-2 text-[11px] text-slate-500">
            A hivatkozás mindig a hivatkozott cella <b>aktuális értékét</b> adja (nem a mögöttes
            képletet). A képlet NEM kezdődik „=" jellel. Körkörös vagy hibás hivatkozás esetén a
            cella az eredeti értékét tartja, a szerkesztő jelzi a hibát.
          </div>
        </div>

        <div className="bg-white border border-emerald-300 rounded p-3 mb-4 text-xs">
          <div className="font-bold mb-1">Példák</div>
          <ul className="list-disc pl-5 space-y-0.5">
            <li>
              <span className="font-mono">J*0,985</span> — a vételi az elszámoló 98,5%-a (saját
              sor).
            </li>
            <li>
              <span className="font-mono">!FEUR</span> — az EUA eladása legyen mindig az EUR eladása
              (0-s lap).
            </li>
            <li>
              <span className="font-mono">#03M</span> — a 3-as csoport eladási árfolyamát veszi át.
            </li>
          </ul>
        </div>

        <div className="text-center">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 bg-emerald-700 text-white rounded hover:bg-emerald-800 font-medium"
          >
            Vissza a munkához
          </button>
        </div>
      </div>
    </div>
  )
}

/** Súgó-gomb (fejlécbe) — az árfolyamlap-szerkesztő képletszintaxis-súgóját nyitja. */
export function FormulaSyntaxHelpButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex items-center gap-1 px-2 py-0.5 text-[11px] font-medium border border-emerald-400 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 rounded"
      title="Képletszintaxis súgó (A–I, J–S, !Fxxx, #NNL)"
    >
      <HelpCircle size={11} /> Képlet-súgó
    </button>
  )
}
