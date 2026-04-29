import { useHotkeys } from 'react-hotkeys-hook'

/**
 * v2.3.47 (Sourcery #310 P3): F-key union (NEM raw string), igy a compiler
 * megakadalyozza a non-F-key bind-okat ezen a helper-en keresztul.
 * Ha pl. 'a' / 'ctrl+s' / 'esc' kell, akkor a useHotkeys-t hasznald direkt.
 */
export type FunctionKey =
  | 'f1' | 'f2' | 'f3' | 'f4' | 'f5' | 'f6'
  | 'f7' | 'f8' | 'f9' | 'f10' | 'f11' | 'f12'

/**
 * v2.3.45 (Sourcery #308 P3): F-key hotkey helper.
 *
 * Az F1-F12 kulcsoknak a böngészőkben default akciójuk van (F1=Help,
 * F3=Find, F5=Reload, F7=Caret, F8=DevTools, F11=Fullscreen, F12=DevTools).
 * Minden F-key bind-nak `preventDefault()`-tel kell rendelkeznie, kulonben
 * a felhasznalo billentyuzet-navigacioja megbizhatatlan lesz.
 *
 * Ez a helper egy egysoros wrapper a `useHotkeys`-on, ami:
 *  - automatikusan hivja `e.preventDefault()`-et
 *  - mindig `enableOnFormTags: true` (form-input-okban is mukodik)
 *  - a callback NEM kapja meg az event-et (NEM is kell — a preventDefault
 *    mar megvolt)
 *  - a `key` parameter egy `FunctionKey` union (NEM raw string), igy
 *    csak F1-F12 kulcsra hivhato (compile-time guard, Sourcery #310 P3)
 *
 * Hasznalat:
 *   useFKeyHotkey('f1', () => setMode('buy'))
 *   useFKeyHotkey('f5', () => navigate('/storno'))
 */
export function useFKeyHotkey(key: FunctionKey, callback: () => void): void {
  useHotkeys(
    key,
    (e: KeyboardEvent) => {
      e.preventDefault()
      callback()
    },
    { enableOnFormTags: true },
  )
}
