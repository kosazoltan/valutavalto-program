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

// 2026-08-11: az arfolyam-keszito-client torolve (a kozponti-client rate-maker
// flavorja szolgalja ki az RFM modot; bizonyitek: .hermes/evidence/2026-08-11/).
const CLIENTS = ['penztar-client', 'kozponti-client']
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
// A platform nem hivhatja (kliens-modul), ezert MINDEN megmaradt Electron-kliensben
// ott kell maradnia: enelkul a token nem jut el a local-first / sync reteghez.
// (2026-08-11: az arfolyam-keszito-client torolve; a kozponti-client rate-maker
// flavorja szolgalja ki az RFM modot.)
for (const client of ['kozponti-client']) {
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

// --- 7. BIZTONSAGI SZABALYOK EGY FORRASBOL (platform-refaktor 3. kor) --------
// A media-permission szabaly (F-006 default-deny + explicit origin-allowlist) es
// az `app:` protokoll path-traversal vedelme korabban HAROM, ill. KET masolatban
// elt a kliensekben. A kiemeles utan egy forras van. Ez a szakasz azt orzi, hogy
// a masolat ne szivarogjon vissza: ha egy kliens ujra sajat inline handlert irna,
// a szabaly ket helyen driftelhetne szet - es a driftet semmilyen typecheck
// vagy build nem venne eszre.
const RUNTIME_MODULE = join(PLATFORM_DIR, 'src', 'app-runtime.ts')
check('platform app-runtime modul letezik', existsSync(RUNTIME_MODULE))

for (const client of CLIENTS) {
  const mainPath = join(client, 'electron', 'main.ts')
  if (!existsSync(mainPath)) continue
  const src = readFileSync(mainPath, 'utf8')

  // 7a. A permission-handler a platformbol jon, nem inline lambda.
  if (src.includes('setPermissionRequestHandler')) {
    check(
      `${client}: a media-permission handler a PLATFORMBOL jon (F-006 egy forras)`,
      src.includes('setPermissionRequestHandler(createMediaPermissionHandler('),
      'inline permission-handler visszaszivargott — a default-deny szabaly ket helyen driftelne',
    )
    // A regi masolat jellegzetes belso sora nem maradhat a kliensben.
    check(
      `${client}: nincs visszamasolt origin-allowlist a kliensben`,
      !src.includes("url.hostname === 'excvaluta.com'"),
      'az origin-ellenorzes a platform app-runtime moduljaba tartozik',
    )
  }

  // 7b. Az `app:` protokoll-kiszolgalo path-traversal vedelme.
  // A penztar-client valtozata SZANDEKOSAN kulon marad (kerdesenkenti log.info +
  // eltero valtozo-elnevezes), ezert csak a masik ket kliensre kotelezo.
  if (client !== 'penztar-client' && src.includes("protocol.handle('app'")) {
    check(
      `${client}: az app: protokoll-kiszolgalo a PLATFORMBOL jon`,
      src.includes("protocol.handle('app', createAppProtocolHandler("),
      'a path-traversal vedelem egy forrasbol jon; inline masolat tilos',
    )
  }

  // 7c. A userData/.env promocio.
  if (src.includes('userData/.env') || src.includes('promoteUserDataEnv')) {
    check(
      `${client}: a userData/.env promocio a PLATFORMBOL jon`,
      src.includes('promoteUserDataEnv({'),
      'inline dotenv-promocio visszaszivargott',
    )
    // A kliens-specifikus kulonbseg legyen EXPLICIT parameter, ne rejtett default.
    check(
      `${client}: explicit missingEnvMessage-t ad at (nincs rejtett default)`,
      /missingEnvMessage:\s*\n?\s*'/.test(src),
      'a hianyzo-.env uzenet kliensenkent elter, ezert kotelezo parameter',
    )
  }
}

// 7d. Az api-url modul PURE marad: `electron` import a platform-oldalon
// megtorne a `penztar-client` vitest node-kornyezeteben futo tesztjeit.
const apiUrlModule = join(PLATFORM_DIR, 'src', 'api-url.ts')
if (existsSync(apiUrlModule)) {
  const src = readFileSync(apiUrlModule, 'utf8')
  check(
    'a platform api-url modulja PURE (nincs electron import)',
    !/from\s+['"]electron['"]/.test(src),
    'az electron import miatt a modul nem lenne unit-tesztelheto',
  )
}

// 7e. A `resolveConfiguredApiUrl` a platform dontesere epul mindharom kliensben.
for (const client of CLIENTS) {
  const mainPath = join(client, 'electron', 'main.ts')
  if (!existsSync(mainPath)) continue
  const src = readFileSync(mainPath, 'utf8')
  if (!src.includes('function resolveConfiguredApiUrl')) continue
  check(
    `${client}: resolveConfiguredApiUrl a platform decideApiUrl-jere epul`,
    src.includes('decideApiUrl('),
    'a sema-ellenorzes (http/https allowlist) egy forrasbol jon',
  )
  check(
    `${client}: nincs visszamasolt normalizeApiUrl a kliensben`,
    !src.includes('function normalizeApiUrl'),
    'a normalizalas a platform api-url moduljaban van',
  )
}

// 7f. Auto-update (4. kor): a kozponti kliens a PLATFORM updater-et hasznalja, es a
// penztar auto-update.ts NEM elesztheto ujra (suite-telepito -> duplikalt install).
{
  const platformUpdater = join('packages', 'electron-platform', 'src', 'auto-update.ts')
  if (existsSync(platformUpdater)) {
    const src = readFileSync(platformUpdater, 'utf8')
    check(
      'a platform auto-update modulja NEM importal electron-updater-t',
      !/from\s+['"]electron-updater['"]/.test(src),
      'a kliens adja at az autoUpdater peldanyt (UpdaterLike) — igy a platformnak nem kell uj dependency, amit minden CI-jobnak telepitenie kellene (v2.28.76 TS2307 lecke), es a dontesi logika unit-tesztelheto',
    )
    check(
      'a platform updater exportalja az isInRollout kill-switch kaput',
      src.includes('export function isInRollout'),
      'a `rolloutPercent: 0` a flotta-frissites kill-switche',
    )
  }

  const kozpontiMain = join('kozponti-client', 'electron', 'main.ts')
  if (existsSync(kozpontiMain)) {
    const src = readFileSync(kozpontiMain, 'utf8')
    check(
      'kozponti-client: az onfrissites a PLATFORM initElectronUpdater-ebol jon',
      src.includes('initElectronUpdater('),
      'nincs inline updater-masolat a kliensben',
    )
    check(
      "kozponti-client: explicit clientLabel-t ad at (nincs rejtett default)",
      /clientLabel:\s*'kozponti'/.test(src),
      'a ket kliens naploja szetvalaszthato kell legyen',
    )
    check(
      "kozponti-client: on-quit telepitesi mod (nincs munkat megszakito restart)",
      /installMode:\s*'on-quit'/.test(src),
      'a 2. dontes szerint a telepites app-kilepesnel tortenik',
    )
  }

  // A penztar suite-telepitoje miatt TILOS a `penztar.yml`/`latest.yml` feed
  // (docs/auto-update-terv-es-vegrehajtas.md 3.2). A release-workflow gepi kapuja
  // ezt orzi — itt azt assertaljuk, hogy a kapu maga nem tunt el.
  const releaseWorkflow = join('.github', 'workflows', 'windows-signed-release.yml')
  if (existsSync(releaseWorkflow)) {
    const src = readFileSync(releaseWorkflow, 'utf8')
    check(
      'release-workflow: tiltja a penztar.yml/latest.yml release-assetet',
      src.includes("'penztar.yml', 'latest.yml'"),
      'feed nelkul a regi penztar-flotta nem inditja el az electron-updater duplikalt telepitesi utat',
    )
    check(
      'release-workflow: felkerul a munkaallomas.yml auto-update feed',
      src.includes('release-flat/munkaallomas.yml'),
      'enelkul a kozponti kliens onfrissitese nem talal manifestet',
    )
  }

  // 2. FAZIS — penztar suite-updater invariansok. Ezek penzugyi/biztonsagi
  // szabalyok, nem stilus: a telepites nem szakithat meg nyitott muszakot, es
  // ellenorizetlen exe SOHA nem indulhat el.
  const suiteUpdate = join('penztar-client', 'electron', 'suite-update.ts')
  if (existsSync(suiteUpdate)) {
    const src = readFileSync(suiteUpdate, 'utf8')
    check(
      'penztar suite-updater: NEM importal electron-updater-t',
      !/from\s+['"]electron-updater['"]/.test(src),
      'a suite-telepito sajat registry-kulcsa mellett az electron-updater parhuzamos, masodik telepitest hozna letre (3.2 szakasz)',
    )
    check(
      'penztar suite-updater: a telepitesi ablak kapuja letezik (isInstallWindow)',
      src.includes('export function isInstallWindow'),
      'a READY -> INSTALLING atmenet csak IDLE_BEFORE_OPEN / CLOSED_AFTER_DAY_END allapotban engedett (3.6)',
    )
    check(
      'penztar suite-updater: nyitott muszak NEM telepitheto allapot',
      /INSTALLABLE_STATES[^=]*=\s*\[[^\]]*'IDLE_BEFORE_OPEN'[^\]]*'CLOSED_AFTER_DAY_END'[^\]]*\]/s.test(src) &&
        !/INSTALLABLE_STATES[^=]*=\s*\[[^\]]*'SHIFT_OPEN'/s.test(src),
      'SHIFT_OPEN alatt csak jelzes mehet, telepito nem indulhat',
    )
    check(
      'penztar suite-updater: ismeretlen muszak-allapot -> konzervativ SHIFT_OPEN',
      /normaliseShiftState[\s\S]*?return 'SHIFT_OPEN'/.test(src),
      'ha az allapot nem megallapithato, NEM telepitunk (fail-safe)',
    )
    check(
      'penztar suite-updater: SHA-256 ellenorzes a telepites elott',
      src.includes('sha256File(') && src.includes('manifest.penztar.sha256'),
      'rontott hash-u exe soha nem indulhat el',
    )
    check(
      'penztar suite-updater: Authenticode subject-ellenorzes (nem csak status)',
      src.includes('verifyAuthenticode(') && src.includes('EXPECTED_SUBJECT'),
      'egy masik ceg ervenyes tanusitvanyaval alairt exe sem fogadhato el',
    )
    check(
      'penztar suite-updater: downgrade tilalom (isNewerVersion kapu)',
      src.includes('isNewerVersion(manifest.version'),
      'csak szigoruan nagyobb semver telepitheto',
    )
    check(
      'penztar suite-updater: a rollout kapu a PLATFORMBOL jon',
      src.includes('isInRollout('),
      'a kill-switch logika egy forrasbol (platform auto-update modul)',
    )
  }

  // A regi, electron-updater alapu penztar-modul nem eleszthető ujra.
  check(
    'penztar-client: a legacy auto-update.ts nem tert vissza',
    !existsSync(join('penztar-client', 'electron', 'auto-update.ts')),
    'a penztar frissitesi egysege a suite-telepito; egy visszahozott electron-updater modul duplikalt telepitest okozna',
  )

  const releaseWorkflowPath = join('.github', 'workflows', 'windows-signed-release.yml')
  if (existsSync(releaseWorkflowPath)) {
    const src = readFileSync(releaseWorkflowPath, 'utf8')
    check(
      'release-workflow: generalja es feltolti az update-manifest.json-t',
      src.includes('update-manifest.json') && src.includes('release-flat/update-manifest.json'),
      'enelkul a penztar suite-updater nem talal manifestet',
    )
    check(
      'release-workflow: a manifest hash a SHA-256 manifestbol jon (egy igazsagforras)',
      src.includes('$manifestLines') && src.includes('$penztarHash'),
      'ujraszamolt hash elcsuszhatna a kozolt manifesttol',
    )
    check(
      'release-workflow: rollout_percent input letezik (kill-switch)',
      src.includes('rollout_percent:'),
      'a staged rollout / kill-switch a release inputjabol jon',
    )
  }
}

console.log(`\nVizsgalt import-utvonal: ${checked}`)
notes.forEach((n) => console.log('  -', n))

if (failures > 0) {
  console.log(`\n${failures} szabalysertes — a platform-hatar serult.`)
  process.exit(1)
}
console.log('\n[platform-boundaries] OK — kliens->platform irany betartva.')
