import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const failures = []
const notes = []

function readText(relativePath) {
  return fs.readFileSync(path.join(repoRoot, relativePath), 'utf8')
}

function readJson(relativePath) {
  return JSON.parse(readText(relativePath))
}

function normalizeUrl(value) {
  return String(value ?? '')
    .trim()
    .replace(/\/+$/, '')
}

function check(condition, message, detail) {
  if (!condition) {
    failures.push(detail ? `${message}: ${detail}` : message)
  }
}

function hasProductionUrlsResource(builderConfig) {
  return (
    Array.isArray(builderConfig.extraResources) &&
    builderConfig.extraResources.some(
      (resource) =>
        String(resource?.to ?? '') === 'production-urls.json' &&
        String(resource?.from ?? '')
          .replaceAll('\\', '/')
          .endsWith('config/production-urls.json'),
    )
  )
}

const productionUrls = readJson('config/production-urls.json')
const expectedApiUrl = normalizeUrl(productionUrls.api_url)
const expectedHealthUrl = `${expectedApiUrl}/auth/bootstrap-status`

check(
  expectedApiUrl === 'https://excvaluta.com/api/v1',
  'production API URL eltér a jóváhagyott éles végponttól',
  expectedApiUrl,
)
check(
  normalizeUrl(productionUrls.health_url) === expectedHealthUrl,
  'production health URL nem az API URL-ből következő bootstrap-status végpont',
  productionUrls.health_url,
)

const packagePaths = [
  'package.json',
  'frontend-react/package.json',
  'penztar-client/package.json',
  'kozponti-client/package.json',
]
const versions = packagePaths.map((relativePath) => ({
  relativePath,
  version: readJson(relativePath).version,
}))
const uniqueVersions = new Set(versions.map((entry) => entry.version))
check(
  uniqueVersions.size === 1,
  'a monorepo, frontend és két telepíthető kliens verziója nincs szinkronban',
  versions.map((entry) => `${entry.relativePath}=${entry.version}`).join(', '),
)

notes.push(`version=${versions[0]?.version ?? 'unknown'}`)
notes.push(`api=${expectedApiUrl}`)

const frontendAppModeRoles = readText('frontend-react/src/utils/appModeRoles.ts')
const backendAppModeRoles = readText(
  'backend/src/main/java/hu/puzzleir/valuta/util/AppModeRoleConstants.java',
)
const menuGroups = readText('frontend-react/src/layouts/menuGroups.ts')
const appRoutes = readText('frontend-react/src/App.tsx')
const firstRunSource = readText('penztar-client/electron/first-run.ts')
const penztarMain = readText('penztar-client/electron/main.ts')

const installers = [
  {
    name: 'penztar-client',
    packagePath: 'penztar-client/package.json',
    builderPath: 'penztar-client/electron-builder.json',
    mainPath: 'penztar-client/electron/main.ts',
    expectedAppId: 'com.bestchange.penztar',
    expectedProductName: 'Valutavalto Penztar',
    expectedArtifactName: 'Penztar-Setup-${version}.exe',
    flavor: null,
  },
  {
    // 2026-05-24: az összevont „Központi munkaállomás" — induláskori mód-választóval
    // KÉT módot szolgál ki (full = Központi irányítóközpont, rate-maker = Árfolyamkészítő),
    // mindkét frontend-flavor SAJÁT VITE_APP_FLAVOR-jával fordítva, külön dist-subdir-be.
    // 2026-08-11: a korábbi önálló `rfm-keszito-client` bejegyzés törölve — az RFM
    // mód egyetlen szállítója ez az összevont kliens (arfolyam-keszito-client megszűnt).
    name: 'kozponti-client',
    packagePath: 'kozponti-client/package.json',
    builderPath: 'kozponti-client/electron-builder.json',
    mainPath: 'kozponti-client/electron/main.ts',
    // 2026-05-24: saját appId az összevont kliensnek (NEM a régi com.bestchange.kozponti) —
    // így a friss telepítés tiszta dir-be megy, nem ágyazódik a régi Iranyitokozpont alá.
    expectedAppId: 'com.bestchange.munkaallomas',
    expectedProductName: 'Valutavalto Kozponti Munkaallomas',
    expectedArtifactName: 'Kozponti-Munkaallomas-Setup-${version}.exe',
    merged: true,
    mergedFlavors: ['central-workstation', 'rate-maker'],
  },
]

for (const installer of installers) {
  const packageJson = readJson(installer.packagePath)
  const builderConfig = readJson(installer.builderPath)
  const mainSource = readText(installer.mainPath)

  check(
    builderConfig.appId === installer.expectedAppId,
    `${installer.name}: appId eltérés`,
    builderConfig.appId,
  )
  check(
    builderConfig.productName === installer.expectedProductName,
    `${installer.name}: productName eltérés`,
    builderConfig.productName,
  )
  check(
    builderConfig.win?.artifactName === installer.expectedArtifactName,
    `${installer.name}: installer artifactName eltérés`,
    builderConfig.win?.artifactName,
  )
  check(
    hasProductionUrlsResource(builderConfig),
    `${installer.name}: production-urls.json nincs becsomagolva extraResource-ként`,
  )
  check(
    mainSource.includes('production-urls.json'),
    `${installer.name}: main process nem olvassa a production-urls.json végpontforrást`,
  )
  check(
    mainSource.includes(expectedApiUrl),
    `${installer.name}: main process fallback API URL nem egyezik a production végponttal`,
    expectedApiUrl,
  )

  const devRenderer = String(packageJson.scripts?.['dev:renderer'] ?? '')
  if (devRenderer) {
    check(
      devRenderer.includes("VITE_PROXY_TARGET='https://excvaluta.com'"),
      `${installer.name}: dev renderer proxy cél nem az excvaluta.com`,
      devRenderer,
    )
  }

  const buildFrontend = String(packageJson.scripts?.['build:frontend'] ?? '')
  if (installer.merged) {
    // Összevont kliens: a build:frontend MINDKÉT flavort lefedi (külön dist-subdir),
    // és a main.ts dinamikusan (mód-választó + dual-dist) szolgálja ki őket.
    check(
      Array.isArray(installer.mergedFlavors) && installer.mergedFlavors.length > 0,
      `${installer.name}: merged kliens mergedFlavors hiányzik vagy nem tömb`,
    )
    for (const flavor of Array.isArray(installer.mergedFlavors) ? installer.mergedFlavors : []) {
      const flavorBuilt =
        buildFrontend.includes(`VITE_APP_FLAVOR='${flavor}'`) ||
        readText(installer.packagePath).includes(`VITE_APP_FLAVOR='${flavor}'`)
      check(
        flavorBuilt,
        `${installer.name}: az összevont build nem fordítja a(z) ${flavor} flavort`,
      )
    }
    check(
      mainSource.includes('activeAppMode'),
      `${installer.name}: a main.ts nem használ dinamikus (activeAppMode) módot`,
    )
    check(
      mainSource.includes('pickWorkstationMode') || mainSource.includes('determineStartupMode'),
      `${installer.name}: a main.ts nem tartalmaz induláskori mód-választót`,
    )
    check(
      /dist['"`\)]?\s*,\s*MODE_DIST_SUBDIR/.test(mainSource) ||
        mainSource.includes('MODE_DIST_SUBDIR[activeAppMode]'),
      `${installer.name}: a protokoll-kiszolgálás nem a mód-specifikus dist-subdir-ből történik`,
    )
  } else if (installer.flavor) {
    check(
      buildFrontend.includes(`VITE_APP_FLAVOR='${installer.flavor}'`),
      `${installer.name}: frontend build flavor nincs rögzítve`,
      buildFrontend,
    )
  } else {
    check(
      !buildFrontend.includes('VITE_APP_FLAVOR='),
      `${installer.name}: pénztár/értéktár közös kliens buildje nem lehet RFM vagy központi flavorre rögzítve`,
      buildFrontend,
    )
  }

  if (installer.fixedMode) {
    check(
      mainSource.includes(`return '${installer.fixedMode}'`),
      `${installer.name}: getConfig('app_mode') nem fix ${installer.fixedMode} módot ad`,
    )
    check(
      mainSource.includes(`config.app_mode = '${installer.fixedMode}'`),
      `${installer.name}: initial config nem fix ${installer.fixedMode} módot ír`,
    )
    check(
      mainSource.includes(`appMode: '${installer.fixedMode}'`),
      `${installer.name}: backend login nem fix ${installer.fixedMode} appMode-dal történik`,
    )
  }

  notes.push(`${installer.name}: appId=${builderConfig.appId}`)
}

const functionalAreas = [
  {
    name: 'penztar',
    appMode: 'penztar',
    route: '/cashier',
    frontendRoleGuard: "appMode === 'penztar'",
    backendModeMarker: 'case "penztar"',
    menuModeMarker: 'modes: ["penztar"]',
  },
  {
    name: 'ertektar',
    appMode: 'ertektar',
    route: '/treasury',
    frontendRoleGuard: "appMode === 'ertektar'",
    backendModeMarker: 'case "ertektar"',
    menuModeMarker: 'modes: ["ertektar"]',
  },
  {
    name: 'rfm-keszito',
    appMode: 'rate-maker',
    route: '/rates/creation',
    frontendRoleGuard: "appMode === 'rate-maker'",
    backendModeMarker: 'case "rate-maker"',
    menuModeMarker: "VITE_APP_FLAVOR === 'rate-maker'",
  },
  {
    name: 'kozponti',
    appMode: 'full',
    route: '/central-workstation',
    frontendRoleGuard: "appMode === 'full'",
    backendModeMarker: 'case "full"',
    menuModeMarker: 'modes: ["full"]',
  },
]

for (const area of functionalAreas) {
  check(
    firstRunSource.includes(`'${area.appMode}'`) || area.appMode === 'full',
    `${area.name}: setup/appMode lista nem tartalmazza a működési módot`,
    area.appMode,
  )
  check(
    frontendAppModeRoles.includes(area.frontendRoleGuard),
    `${area.name}: frontend szerepkör-szűrés nem kezeli külön ezt az appMode-ot`,
    area.appMode,
  )
  check(
    backendAppModeRoles.includes(area.backendModeMarker),
    `${area.name}: backend appMode-szűrés nem kezeli külön ezt az appMode-ot`,
    area.appMode,
  )
  // Idézőjel-független: a Prettier a menuGroups.ts-ben dupla->szimpla idézőjelre formázhat
  // (modes: ["full"] -> modes: ['full']); a mód-jelölés megléte a lényeg, nem az idézőjel-stílus.
  check(
    menuGroups.replace(/'/g, '"').includes(area.menuModeMarker) || area.name === 'rfm-keszito',
    `${area.name}: menü/flavor nem tartalmazza a működési mód jelölését`,
    area.menuModeMarker,
  )
  check(
    appRoutes.includes(`path="${area.route}"`) || appRoutes.includes(`to="${area.route}"`),
    `${area.name}: fő útvonal nincs bekötve az App route-ok közé`,
    area.route,
  )
  notes.push(`${area.name}: appMode=${area.appMode}, route=${area.route}`)
}

check(
  /appMode:\s*payload\??\.appMode/.test(penztarMain) ||
    /appMode:\s*payload\.appMode/.test(firstRunSource),
  'pénztár/értéktár közös kliens: backend login nem adja tovább a kiválasztott appMode-ot',
)

if (failures.length > 0) {
  console.error(
    '[four-area-alignment] HIBA: a pénztár, értéktár, RFM készítő és központi működés nincs összhangban.',
  )
  for (const failure of failures) {
    console.error(`- ${failure}`)
  }
  process.exit(1)
}

console.log('[four-area-alignment] OK')
for (const note of notes) {
  console.log(`- ${note}`)
}
