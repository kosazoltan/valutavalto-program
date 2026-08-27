import { HelpCircle, X } from 'lucide-react'
import i18n from '../../i18n'

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
            {i18n.t('literals.kepletszintaxis-csoport-arfolyamlap')}
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
          <div className="font-bold text-sm mb-2 text-center">{i18n.t('literals.cella-modok')}</div>
          <table className="w-full text-xs">
            <tbody>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300 w-28">
                  {i18n.t('literals.ures')}
                </td>
                <td className="py-1 px-2 italic">
                  {i18n.t('literals.automatikus-ertek-a-j-elszamolo-a-0-s-la')}
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">
                  {i18n.t('literals.123-45')}
                </td>
                <td className="py-1 px-2 italic">
                  {i18n.t('literals.fix-ertek-kezi-feluliras-tizedeselvalasz')}
                  <b>{i18n.t('literals.vesszo')}</b>
                  {i18n.t('literals.lit-44')}
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">
                  {i18n.t('literals.keplet')}
                </td>
                <td className="py-1 px-2 italic">
                  {i18n.t('literals.a-keplet-eredmenye-jelenik-meg-es')}
                  <b>{i18n.t('literals.automatikusan-ujraszamolodik')}</b>
                  {i18n.t('literals.ha-a-hivatkozott-ertek-valtozik')}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div className="bg-white border border-emerald-300 rounded p-3 mb-3">
          <div className="font-bold text-sm mb-2 text-center">
            {i18n.t('literals.hivatkozasok')}
          </div>
          <table className="w-full text-xs">
            <tbody>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300 w-28">
                  {i18n.t('literals.a-c-e-i')}
                </td>
                <td className="py-1 px-2 italic">
                  {i18n.t('literals.a')}
                  <b>{i18n.t('literals.0-s-lap')}</b>
                  {i18n.t('literals.adott-ertek-oszlopa-az-aktualis-valuta-s')}{' '}
                  <span className="font-mono">{i18n.t('literals.a-2')}</span>
                  {i18n.t('literals.elszamolo-a')}
                  <b>{i18n.t('literals.d')}</b>
                  {i18n.t('literals.a-0-s-lap-valuta-iso-kodja')}
                  <b>{i18n.t('literals.nem-hivatkozhato-ertekkent')}</b>
                  {i18n.t('literals.mint-a-csoportlap-k-oszlopa')}
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">
                  {i18n.t('literals.j-s')}
                </td>
                <td className="py-1 px-2 italic">
                  {i18n.t('literals.az')}
                  <b>{i18n.t('literals.aktualis-csoportlap')}</b>
                  {i18n.t('literals.adott-oszlopa-az-aktualis-valuta-soraban')}{' '}
                  <span className="font-mono">{i18n.t('literals.l')}</span>
                  {i18n.t('literals.alap-veteli')}
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">
                  {i18n.t('literals.fxxx')}
                </td>
                <td className="py-1 px-2 italic">
                  {i18n.t('literals.masik-valuta-oszlopa-a')}
                  <b>{i18n.t('literals.0-s-lapon')}</b>
                  {i18n.t('literals.f-oszlop-xxx-valutakod-pl')}{' '}
                  <span className="font-mono">{i18n.t('literals.feur')}</span>
                  {i18n.t('literals.az-eur-sor-f-eladas-oszlopa')}
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">
                  {i18n.t('literals.nnl')}
                </td>
                <td className="py-1 px-2 italic">
                  {i18n.t('literals.masik')}
                  <b>{i18n.t('literals.csoportlap')}</b>
                  {i18n.t('literals.oszlopa-az-aktualis-valuta-soraban')}{' '}
                  <span className="font-mono">{i18n.t('literals.lit-12')}</span>
                  {i18n.t('literals.ketjegyu-csoportazonosito-oszlopbetu-pl')}{' '}
                  <span className="font-mono">{i18n.t('literals.01l')}</span>
                  {i18n.t('literals.az-1-es-csoport-l-oszlopa')}
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">
                  {i18n.t('literals.muveletek')}
                </td>
                <td className="py-1 px-2 italic">
                  {i18n.t('literals.es-zarojel-eltero-prioritasnal-a-zarojel')}{' '}
                  <span className="font-mono">{i18n.t('literals.j-0-985')}</span>
                  {i18n.t('literals.vagy')}{' '}
                  <span className="font-mono">{i18n.t('literals.l-m-2')}</span>
                  {i18n.t('literals.lit-5')}
                </td>
              </tr>
              <tr>
                <td className="py-1 px-2 font-mono font-bold border-r border-slate-300">
                  {i18n.t('literals.k')}
                </td>
                <td className="py-1 px-2 italic text-slate-500">
                  <b>{i18n.t('literals.vedett')}</b>
                  {i18n.t('literals.valuta-iso-kod-nem-szerkesztheto-nem-hiv')}
                </td>
              </tr>
            </tbody>
          </table>
          <div className="mt-2 text-[11px] text-slate-500">
            {i18n.t('literals.a-hivatkozas-mindig-a-hivatkozott-cella')}
            <b>{i18n.t('literals.aktualis-erteket')}</b>
            {i18n.t('literals.adja-nem-a-mogottes-kepletet-a-keplet-ne')}
          </div>
        </div>

        <div className="bg-white border border-emerald-300 rounded p-3 mb-4 text-xs">
          <div className="font-bold mb-1">{i18n.t('literals.peldak')}</div>
          <ul className="list-disc pl-5 space-y-0.5">
            <li>
              <span className="font-mono">{i18n.t('literals.j-0-985')}</span>
              {i18n.t('literals.a-veteli-az-elszamolo-98-5-a-sajat-sor')}
            </li>
            <li>
              <span className="font-mono">{i18n.t('literals.feur')}</span>
              {i18n.t('literals.az-eua-eladasa-legyen-mindig-az-eur-elad')}
            </li>
            <li>
              <span className="font-mono">{i18n.t('literals.03m')}</span>
              {i18n.t('literals.a-3-as-csoport-eladasi-arfolyamat-veszi')}
            </li>
          </ul>
        </div>

        <div className="text-center">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 bg-emerald-700 text-white rounded hover:bg-emerald-800 font-medium"
          >
            {i18n.t('literals.vissza-a-munkahoz')}
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
      <HelpCircle size={11} />
      {i18n.t('literals.keplet-sugo')}
    </button>
  )
}
