// 4-way (3+1) verzió-szinkron ellenőrző — release-atomikusság (VV-ELVI 11.1).
//
// CSAK a verziókat hasonlítja össze, semmilyen más invariánst (URL, route, electron-builder)
// — ellentétben a check-four-area-alignment.mjs-szel, ami sok egyéb dolgot is ellenőriz és
// ezért nem alkalmas szűk, blocking "version drift" gate-nek.
//
// Ellenőrzött 5 forrás (mind egyeznie KELL):
//   - package.json (root)
//   - frontend-react/package.json
//   - penztar-client/package.json
//   - kozponti-client/package.json
//   - backend/pom.xml  <project><version>   (a valuta-backend artifact verziója, NEM a parent)
//
// (2026-08-11: az arfolyam-keszito-client megszűnt → 6 forrásból 5 maradt.)
//
// Eltérés esetén exit 1 (BLOCKING gate a business-invariant-guard.yml #14-ben).

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')

function readText(relativePath) {
  return fs.readFileSync(path.join(repoRoot, relativePath), 'utf8')
}

const packageJsonPaths = [
  'package.json',
  'frontend-react/package.json',
  'penztar-client/package.json',
  'kozponti-client/package.json',
]

const sources = packageJsonPaths.map((relativePath) => ({
  source: relativePath,
  version: JSON.parse(readText(relativePath)).version,
}))

// backend/pom.xml: a projekt <version> a <artifactId>valuta-backend</artifactId> után álló
// <version>, NEM a <parent> spring-boot-starter-parent verziója.
const pomXml = readText('backend/pom.xml')
const pomMatch = pomXml.match(
  /<artifactId>valuta-backend<\/artifactId>\s*<version>([^<]+)<\/version>/,
)
const pomVersion = pomMatch ? pomMatch[1].trim() : null
sources.push({ source: 'backend/pom.xml (valuta-backend)', version: pomVersion })

const failures = []
if (!pomVersion) {
  failures.push(
    'backend/pom.xml: nem található a valuta-backend <artifactId> utáni <version> (projekt-verzió)',
  )
}

const uniqueVersions = new Set(sources.map((entry) => entry.version))
if (uniqueVersions.size > 1) {
  failures.push('a 4-way (4+1) verziók NINCSENEK összhangban (release nem atomikus):')
  for (const entry of sources) {
    failures.push(`  - ${entry.source} = ${entry.version}`)
  }
}

if (failures.length > 0) {
  console.error('[version-sync] HIBA: 4-way (4+1) verzió-szinkron sértés.')
  for (const failure of failures) {
    console.error(failure)
  }
  process.exit(1)
}

console.log(`[version-sync] OK — mind az 5 forrás verziója egyezik: ${sources[0].version}`)
