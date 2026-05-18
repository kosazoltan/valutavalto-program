/**
 * EBC Hangsegéd telepítő-állapot-gép — lépés-definíciók.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §6.3
 *
 * <p>Az `installStateMachine.next(current, success)` hívás ezeket a lépéseket
 * adja vissza a Realtime API-nak a `next_install_step` tool eredményeként.
 *
 * <p>Phase 9 = a struktúra + a default lépéssor. Az Electron Setup Wizard
 * (Phase 9.5) ezeket fogja megjeleníteni párhuzamosan a hangsegéd
 * elmondásával.
 */

export interface InstallStep {
  step_number: number
  title: string
  instructions: string
  /** opcionális gomb-feliratok a wizard panelhez */
  primaryButton?: string
  secondaryButton?: string
}

/**
 * Az EBC Pénztár telepítés kanonikus 7-lépéses workflow-ja
 * (lásd Telepítő integráció §6.3).
 */
export const INSTALL_STEPS: InstallStep[] = [
  {
    step_number: 1,
    title: 'Mikrofon engedély',
    instructions:
      'Most engedelyezem hogy a mikrofonbol halljam mit mondasz. A bongeszo megkerdezi, csak nyomd meg az "Engedelyezem" gombot.',
    primaryButton: 'Engedelyezem',
  },
  {
    step_number: 2,
    title: 'Bemutatkozas',
    instructions:
      'Tokeletes! Eloszor is mondd meg, hogy hivnak es melyik EBC fiokban dolgozol.',
  },
  {
    step_number: 3,
    title: 'Backend kapcsolat ellenorzes',
    instructions:
      'Egy pillanat, megnezem hogy a kozponti szerverrel van-e kapcsolat. Ez automatikus.',
  },
  {
    step_number: 4,
    title: 'Google bejelentkezes',
    instructions:
      'Most a Google fiok valasztojaban kell a sajat EBC ceges Gmail fiokoddal bejelentkezned. Klikkelj a kek "Sign in with Google" gombra.',
    primaryButton: 'Tovabb a Google bejelentkezes utan',
  },
  {
    step_number: 5,
    title: 'Iroda valasztas',
    instructions:
      'Most valasztd ki azt az irodat ahol most ulsz. A listaban szerepel mindegyik EBC fiok.',
  },
  {
    step_number: 6,
    title: 'Penztarnyitas',
    instructions:
      'Reggeli penztarnyitas: szamold meg a kezdo keszletet (HUF + valutak) es ird be a megfelelo mezokbe.',
  },
  {
    step_number: 7,
    title: 'Telepites kesz',
    instructions:
      'Gratulalok! A telepites kesz, hasznalhatod a programot. Ha barmilyen problemad van, csak szolj — itt vagyok a hibajegyzeshez.',
    primaryButton: 'Bezarom a hangsegedet',
  },
]

export const TOTAL_INSTALL_STEPS = INSTALL_STEPS.length
