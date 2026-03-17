/**
 * Electron detektálás — true ha az app Electron-ban fut (preload.ts exposeálta a window.electronAPI-t).
 */
export function isElectron(): boolean {
  return typeof window !== 'undefined' && !!window.electronAPI;
}

/**
 * ElectronAPI elérése — null ha böngészőben fut.
 */
export function getElectronAPI() {
  return window.electronAPI ?? null;
}
