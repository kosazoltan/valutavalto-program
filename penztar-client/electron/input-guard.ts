/**
 * Billentyű-input őr a látható BrowserWindow-okhoz (before-input-event).
 *
 * Cél: a Chromium beépített print-accelerator (Ctrl+P / Cmd+P) letiltása —
 * bizonylat-nyomtatás KIZÁRÓLAG a saját printReceipt (silent) úton mehet,
 * böngésző-print soha (data_text_html...pdf szemétfájl-hiba, 2026-07-11).
 *
 * Pure modul: szándékosan nem importál semmit az 'electron'-ból, hogy
 * vitest-tel electron-mock nélkül tesztelhető legyen (strukturális típusok).
 */

/** A handler számára szükséges input-mezők (Electron.Input strukturális részhalmaza). */
export interface GuardedInput {
  key: string;
  type: string;
  control: boolean;
  meta: boolean;
  alt: boolean;
}

/** Az event-ből csak a preventDefault kell (Electron.Event részhalmaza). */
export interface PreventableEvent {
  preventDefault: () => void;
}

export interface BeforeInputHandlerOptions {
  /** F12-re hívott DevTools-toggle. Ha nincs megadva (pl. ügyfélkijelző), F12 = no-op. */
  toggleDevTools?: () => void;
}

/**
 * before-input-event handler factory.
 *  - F12 keyDown → toggleDevTools (preventDefault NÉLKÜL — meglévő main.ts viselkedés)
 *  - (Ctrl|Cmd)+P (Alt nélkül) → preventDefault: se page-keydown, se Chromium print
 */
export function createBeforeInputHandler(options: BeforeInputHandlerOptions = {}) {
  return (event: PreventableEvent, input: GuardedInput): void => {
    if (input.key === 'F12' && input.type === 'keyDown') {
      options.toggleDevTools?.();
      return;
    }

    // AltGr (= Ctrl+Alt magyar kiosztáson) kombinációt nem fogjuk el (!input.alt).
    // Típus-szűrés szándékosan nincs: a blokkolt kombináció keyUp-ját is eldobjuk
    // (mellékhatása nincs, fail-closed).
    const isBrowserPrintCombo =
      (input.control || input.meta) && !input.alt && input.key.toLowerCase() === 'p';
    if (isBrowserPrintCombo) {
      event.preventDefault();
    }
  };
}
