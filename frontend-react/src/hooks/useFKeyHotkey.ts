import { useHotkeys } from 'react-hotkeys-hook'

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
 *
 * Hasznalat:
 *   useFKeyHotkey('f1', () => setMode('buy'))
 *   useFKeyHotkey('f5', () => navigate('/storno'))
 *
 * Pattern matching: `useHotkeys('f1', (e) => { e.preventDefault(); ... }, { enableOnFormTags: true })`
 */
export function useFKeyHotkey(key: string, callback: () => void): void {
  useHotkeys(
    key,
    (e: KeyboardEvent) => {
      e.preventDefault()
      callback()
    },
    { enableOnFormTags: true },
  )
}
