#!/usr/bin/env node
/**
 * PLATFORM-BOUNDARY GUARD (2026-08-10, platform-refaktor)
 * =======================================================
 * Egyetlen szabalyt orzunk, amely a platform-reteg letenek ertelme:
 *
 *     Kliens -> PLATFORM importalhat.   Kliens -> KLIENS SOHA.
 *
 * MIERT KELL EZ A KAPU
 * --------------------
 * A 2026-08-10-i klon-meres (10 001 fuggvenytorzs) 27 komponensek KOZOTTI
 * duplikatumot talalt, es a `.github/workflows/security.yml` sajat kommentje
 * kerte a kozos Electron-modulok kiemeleset. A kiemeles utan a `vv-logger`
 * harom peldanya (193/192/192 sor) EGY forrasra csokkent, es a `google-oauth`
 * cross-client shimek a platformon keresztul mennek.
 *
 * Ez a kapu azt akadalyozza meg, hogy a csatolas VISSZASZIVARGON: egy uj
 * `../../penztar-client/...` import a kozponti kliensbol ujra osszeragasztana
 * a klienseket, es a CI-nak megint mindhармat egy jobban kellene telepitenie.
 *
 * A kivetel-lista SZANDEKOSAN egyetlen elem: a platform google-oauth modulja,
 * amely a penztar production-tesztelt RFC 8252 + PKCE implementaciojat
 * re-exportalja. Ez tudatos, dokumentalt atmeneti allapot (a forras
 * athelyezese kulon, viselkedes-semleges lepes lehet) - de mivel a PLATFORM
 * fajlja, az iranyszabaly (kliens -> platform) teljesul.
 *
 * Futtatas:
 *   node scripts/check-platform-boundaries.mjs
 * Exit 0 = minden PASS; Exit 1 = szabalysertes.
 */

import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs'
import { join, relative, sep } from 'node:path'

const CLIENTS = ['penztar-client', 'kozponti-client', 'arfolyam-keszito-client']
const PLATFORM_DIR = join('packages', 'electron-platform')

/**
 * Engedelyezett kivetelek: `<importalo fajl>` -> `<importalt utvonal-reszlet>`.
 * Uj elem CSAK explicit indoklassal es review-val kerulhet ide.
 */
const ALLOWED = [
  {
    from: join('packages', 'electron-platform', 'src', 'google-oauth.ts'),
    contains: 'penztar-client/electron/google-oauth',
    reason:
      'A platform re-exportalja a penztar production-tesztelt RFC 8252 + PKCE OAuth implementaciojat. ' +
      'Az iranyszabaly teljesul (kliens -> platform); a forras athelyezese kulon lepes.',
  },
]

let failures = 0
let checked = 0
const notes = []

function check(name, ok, detail = '') {
  if (ok) {
    console.log(`[PASS] ${name}`)
  } else {
    console.log(`[FAIL] ${name}  ${detail}`)
    failures += 1
  }
}

function walk(dir, out = []) {
  if (!existsSync(dir)) return out
  for (const entry of readdirSync(dir)) {
    if (entry === 'node_modules' || entry === 'dist' || entry === 'dist-electron') continue
    const p = join(dir, entry)
    const st = statSync(p)
    if (st.isDirectory()) walk(p, out)
    else if (entry.endsWith('.ts') || entry.endsWith('.tsx')) out.push(p)
  }
  return out
}

/** Minden import/require/dinamikus import utvonal kiszedese. */
function extractImportPaths(source) {
  const paths = []
  const patterns = [
    /(?:^|\n)\s*(?:import|export)[\s\S]*?from\s+['"]([^'"]+)['"]/g,
    /\brequire\(\s*['"]([^'"]+)['"]\s*\)/g,
    /\bimport\(\s*['"]([^'"]+)['"]\s*\)/g,
  ]
  for (const re of patterns) {
    let m
    while ((m = re.exec(source)) !== null) paths.push(m[1])
  }
  return paths
}

function isAllowed(file, importPath) {
  return ALLOWED.some(
    (a) => file.split(sep).join('/').endsWith(a.from.split(sep).join('/')) &&
           importPath.includes(a.contains),
  )
}

// --- 1. Nincs kliens -> kliens import -------------------------------------
for (const client of CLIENTS) {
  const files = walk(join(client, 'electron'))
  for (const file of files) {
    // A tesztek mockolhatnak testver-utvonalat; a production kodot orzunk.
    if (file.includes('__tests__') || /\.(test|spec)\.tsx?$/.test(file)) continue
    const src = readFileSync(file, 'utf8')
    for (const imp of extractImportPaths(src)) {
      checked += 1
      for (const other of CLIENTS) {
        if (other === client) continue
        if (imp.includes(`${other}/`)) {
          check(
            `kliens->kliens import TILOS: ${relative('.', file)}`,
            isAllowed(file, imp),
            `-> '${imp}'  (a kozos kodot a ${PLATFORM_DIR} retegbe kell emelni)`,
          )
        }
      }
    }
  }
}
check('nincs kliens->kliens import a production Electron-kodban', failures === 0)

// --- 2. A platform nem importal klienst (a dokumentalt kivetelen kivul) ---
const platformFiles = walk(join(PLATFORM_DIR, 'src'))
check(`${PLATFORM_DIR} letezik es van forrasa`, platformFiles.length > 0)

let platformViolations = 0
for (const file of platformFiles) {
  const src = readFileSync(file, 'utf8')
  for (const imp of extractImportPaths(src)) {
    for (const client of CLIENTS) {
      if (imp.includes(`${client}/`) && !isAllowed(file, imp)) {
        platformViolations += 1
        console.log(`[FAIL] platform->kliens import: ${relative('.', file)} -> '${imp}'`)
      }
    }
  }
}
check('a platform csak dokumentalt kivetellel importal klienst', platformViolations === 0)

// --- 3. A vv-logger EGY forras (nincs visszaszivargott duplikacio) --------
const loggerImpl = join(PLATFORM_DIR, 'src', 'vv-logger.ts')
check('platform vv-logger letezik', existsSync(loggerImpl))
for (const client of CLIENTS) {
  const p = join(client, 'electron', 'vv-logger.ts')
  if (!existsSync(p)) continue
  const src = readFileSync(p, 'utf8')
  const usesPlatform = src.includes('electron-platform')
  const lines = src.split('\n').length
  check(
    `${client}/electron/vv-logger.ts a platformra epul (shim, nem masolat)`,
    usesPlatform && lines < 80,
    `usesPlatform=${usesPlatform} lines=${lines} (masolat gyanu, ha nagy es nem hivatkozik a platformra)`,
  )
  // A kliens-specifikus context maradjon explicit.
  const hasCtx = /clientContext:\s*'(CASHIER|TREASURY_HQ|RFM|ADMIN)'/.test(src)
  check(`${client} explicit clientContext-et ad at`, hasCtx)
  notes.push(`${client}: ${lines} sor`)
}

// --- 4. #ERR-INST-01: CALL-TIME userData-feloldas a config/token store-ban ---
// A `kozponti-client/electron/main.ts` INDULAS KOZBEN atallitja a userData-t
// (mod-izolacio). Ha a platform modul-szintu konstansba cache-elne az utvonalat,
// a `setPath` UTANI hivasok a REGI konyvtarra mutatnanak -> a `full` es a
// `rate-maker` mod config.json-ja es auth-token.bin-je CSENDBEN osszeolvadna.
// Sem a typecheck, sem a build nem venne eszre. Ezert orzunk ra kulon.
const storePath = join(PLATFORM_DIR, 'src', 'config-store.ts')
if (existsSync(storePath)) {
  const storeSrc = readFileSync(storePath, 'utf8')

  // A ket utvonal-feloldo fuggveny torzseben ott kell lennie a getPath hivasnak.
  for (const fn of ['configPath', 'tokenPath']) {
    const body = new RegExp(
      `export function ${fn}\\(\\)[^{]*\\{[^}]*app\\.getPath\\('userData'\\)`,
    ).test(storeSrc)
    check(
      `#ERR-INST-01: ${fn}() HIVASI IDOBEN oldja fel a userData-t`,
      body,
      'az utvonalat a fuggvenytorzsben kell feloldani, nem modul-szinten',
    )
  }

  // Modul-szintu utvonal-konstans tilos (ez lenne a cache-hiba).
  const moduleLevelPathConst =
    /^\s*const\s+\w*(PATH|Path)\w*\s*=\s*[^\n]*app\.getPath\(/m.test(storeSrc)
  check(
    '#ERR-INST-01: nincs modul-szintu userData-cache a config-store-ban',
    !moduleLevelPathConst,
    'a `const X = app.getPath(...)` modul-szinten megtorne a mod-izolaciot',
  )
}

// --- 5. A token-perzisztalas utan a kliens setAuthToken-t HIV (regresszio-or) -
// A platform nem hivhatja (kliens-modul), ezert MINDKET kliensben ott kell
// maradnia: enelkul a token nem jut el a local-first / sync reteghez.
for (const client of ['kozponti-client', 'arfolyam-keszito-client']) {
  const mainPath = join(client, 'electron', 'main.ts')
  if (!existsSync(mainPath)) continue
  const src = readFileSync(mainPath, 'utf8')
  if (!src.includes('storeToken(')) continue // meg nincs atkotve erre a primitivre
  check(
    `${client}: a token-tarolas utan megmaradt a setAuthToken(token) hivas`,
    src.includes('setAuthToken(token)'),
    'enelkul a token nem jutna el a sync-motorhoz (csendes regresszio)',
  )
  check(
    `${client}: a token-torles utan megmaradt a setAuthToken(null) hivas`,
    src.includes('setAuthToken(null)'),
  )
}

// --- 6. ADAT-SZEPARACIO: a kliensek package.json `name`-je kulonbozik --------
// Az Electron a userData utat az app NEVEBOL oldja fel (productName ?? name).
// Ha ket klienst azonos nevre "harmonizalnanak", a config.json-juk es az
// auth-token.bin-juk OSSZEOLVADNA - biztonsagi incidens.
const names = new Map()
for (const client of CLIENTS) {
  const pkgPath = join(client, 'package.json')
  if (!existsSync(pkgPath)) continue
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'))
  const key = pkg.productName ?? pkg.name
  if (names.has(key)) {
    check(
      `adat-szeparacio: ${client} es ${names.get(key)} azonos app-nevet hasznal`,
      false,
      `mindketto '${key}' -> KOZOS userData konyvtar (config+token osszeolvadas)`,
    )
  }
  names.set(key, client)
}
check(
  'adat-szeparacio: minden kliens app-neve egyedi (kulon userData konyvtar)',
  names.size === CLIENTS.filter((c) => existsSync(join(c, 'package.json'))).length,
)

console.log(`\nVizsgalt import-utvonal: ${checked}`)
notes.forEach((n) => console.log('  -', n))

if (failures > 0) {
  console.log(`\n${failures} szabalysertes — a platform-hatar serult.`)
  process.exit(1)
}
console.log('\n[platform-boundaries] OK — kliens->platform irany betartva.')
