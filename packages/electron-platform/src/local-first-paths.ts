/**
 * Local-first futtatokornyezeti utvonal-feloldas — platform-reteg.
 *
 * === MIERT VAN ITT (platform-refaktor, 2026-08-10, S2 szelet) ===
 * A `kozponti-client/electron/local-first.ts` (:56-68) es az
 * `arfolyam-keszito-client/electron/local-first.ts` (:47-59) `resolveWasmPath`
 * fuggvenye BAJTRA AZONOS volt (fuggveny-szintu normalizalt diff igazolta).
 *
 * === FIGYELEM: A PENZTAR-KLIENS VALTOZATA NEM AZONOS - NEM HASZNALJA EZT ===
 * A `penztar-client/electron/sqlite.ts:286-307` sajat, GAZDAGABB valtozatot
 * tartalmaz (tobb jelolt utvonal + reszletes, mod-fuggo hibauzenet). Az
 * osszevonasuk viselkedes-valtozas lenne, ezert a penztar valtozata SZANDEKOSAN
 * kulon marad. Ez a modul kizarolag a kozponti + arfolyam parost szolgalja ki.
 *
 * === BUNDLE-FUGGOSEG (fontos megkotes) ===
 * A dev-agban `__dirname` es `process.cwd()` szerepel, ezert ez a modul CSAK
 * addig helyes, amig a platform BE-BUNDLE-ODIK a kliens `dist-electron/main.js`
 * fajljaba (ma igen: a kliensek vite `nodeExternals` listaja nem externalizalja
 * a platformot, a shimek relativ forras-importtal hivatkoznak ra). Ha a platform
 * valaha kulon forditott, runtime-ban importalt csomagga valna, a `__dirname`
 * a platform konyvtarara mutatna es a dev-ag eltorne.
 */

import { app } from 'electron'
import * as fs from 'node:fs'
import * as path from 'node:path'

/**
 * A sql.js WASM binaris feloldasa.
 *
 * Csomagolt modban az `extraResources`-bol (`resources/sql-wasm.wasm`), dev
 * modban a `node_modules`-bol. Ha egyik jelolt sem letezik, dob - a hibauzenet
 * felsorolja a probalt utvonalakat.
 */
export function resolveWasmPath(): string {
  if (app.isPackaged) {
    return path.join(process.resourcesPath, 'sql-wasm.wasm')
  }
  const candidates = [
    path.join(__dirname, '../node_modules/sql.js/dist/sql-wasm.wasm'),
    path.join(process.cwd(), 'node_modules/sql.js/dist/sql-wasm.wasm'),
  ]
  for (const c of candidates) {
    if (fs.existsSync(c)) return c
  }
  throw new Error(`sql-wasm.wasm not found. Tried: ${candidates.join(', ')}`)
}
