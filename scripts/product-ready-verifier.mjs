// Product-Ready Verifier — emberi (külső) evidence + repo-tény alapú release gate.
//
// CÉL: gépileg eldönteni, hogy a program "Product Ready"-e, KIZÁRÓLAG igazolt
// adatok alapján. A verifier SOHA nem generál evidence-et: a külső bizonyítékokat
// (átvételi riport, jóváhagyások, DR-drill, monitoring, aláírt telepítő VM-teszt)
// embernek kell elhelyeznie a docs/release-evidence/ mappában. A script csak
// validál: kötelező mezők, placeholder-tiltás, dátum-épség, repo-keresztellenőrzés
// (verzió-egyezés, enforcement-flagek a kódból, sha256).
//
// Tényalap (kritérium-források):
//   - vault/references/product-ready-roadmap-2026-05-06.md  ("Done definition (Product Ready)")
//   - FEJLESZTESI_IRANY_AUDIT.md                            ("Definition of Done")
//   - EXCMD/2026-06-03_AML-go-live-terv.md                  (enforcement-flag go-live döntések)
//   - EXCMD/_ai-protokoll/2026-06-04-excmd-teljes-audit-statusz-es-javitas.md (nyitott gap-ek)
//
// Használat:
//   node scripts/product-ready-verifier.mjs status        # minden check, mindig exit 0
//   node scripts/product-ready-verifier.mjs final-gate    # minden check, exit 1 ha bármi FAIL
//   node scripts/product-ready-verifier.mjs <check>       # egy check (acceptance|approvals|
//                                                         #  compliance|dr-drill|monitoring|
//                                                         #  installer|evidence|internal)
//
// Evidence fájlok helye: docs/release-evidence/*.json (sablonok: templates/ alatt).

import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const evidenceDir = path.join(repoRoot, 'docs', 'release-evidence')

const MAX_EVIDENCE_AGE_DAYS = 60 // friss release-hez friss bizonyíték kell
const MIN_MONITORING_HOURS = 168 // roadmap DoD: "Monitoring dashboard 7 napja folyamatosan jelez"
const MAX_DR_RESTORE_MINUTES = 60 // roadmap DoD: "DR runbook tesztelve (van helyreallitas 1 oran belul)"
const MIN_UPTIME_PERCENT = 99.0
// roadmap P0-4: "minden forgatokonyv (vetel/eladas/sztorno/napzar/havizar)"
const REQUIRED_ACCEPTANCE_SCENARIOS = ['VETEL', 'ELADAS', 'SZTORNO', 'NAPZARAS', 'HAVIZARAS']
const REQUIRED_APPROVAL_ROLES = ['product', 'ops', 'compliance']

// Kitöltetlen sablon / kamu érték — bármely string-mezőben tiltott.
const PLACEHOLDER_PATTERN = /TODO|TBD|FIXME|KIT[ÖO]LTEND|P[ÉE]LDA|EXAMPLE|SAMPLE|CHANGE_?ME|^\s*$|^X{2,}$|^\.{3}$|<[^>]*>/i

function rootVersion() {
  return JSON.parse(fs.readFileSync(path.join(repoRoot, 'package.json'), 'utf8')).version
}

function readEvidenceJson(fileName) {
  const filePath = path.join(evidenceDir, fileName)
  if (!fs.existsSync(filePath)) {
    return { missing: true, error: `hiányzó evidence fájl: docs/release-evidence/${fileName}` }
  }
  try {
    const raw = fs.readFileSync(filePath, 'utf8').replace(/^﻿/, '')
    return { data: JSON.parse(raw) }
  } catch (err) {
    return { error: `docs/release-evidence/${fileName}: érvénytelen JSON (${err.message})` }
  }
}

// Rekurzív placeholder-vadászat: kitöltetlen sablon nem mehet át a kapun.
function findPlaceholders(value, jsonPath, found) {
  if (typeof value === 'string') {
    if (PLACEHOLDER_PATTERN.test(value)) found.push(`${jsonPath} = ${JSON.stringify(value)}`)
  } else if (Array.isArray(value)) {
    value.forEach((item, i) => findPlaceholders(item, `${jsonPath}[${i}]`, found))
  } else if (value && typeof value === 'object') {
    for (const [key, child] of Object.entries(value)) {
      findPlaceholders(child, `${jsonPath}.${key}`, found)
    }
  }
  return found
}

function checkPlaceholders(data, fileName, reasons) {
  const found = findPlaceholders(data, fileName.replace(/\.json$/, ''), [])
  for (const hit of found) reasons.push(`placeholder/kitöltetlen érték: ${hit}`)
}

function requireString(obj, field, label, reasons) {
  const value = field.split('.').reduce((acc, key) => (acc == null ? acc : acc[key]), obj)
  if (typeof value !== 'string' || value.trim() === '') {
    reasons.push(`hiányzó/üres kötelező mező: ${label}.${field}`)
    return null
  }
  return value.trim()
}

function requireDate(obj, field, label, reasons, { maxAgeDays = null } = {}) {
  const value = requireString(obj, field, label, reasons)
  if (value == null) return null
  const parsed = new Date(value)
  if (Number.isNaN(parsed.getTime())) {
    reasons.push(`${label}.${field}: érvénytelen dátum: ${JSON.stringify(value)}`)
    return null
  }
  const now = Date.now()
  if (parsed.getTime() > now + 5 * 60 * 1000) {
    reasons.push(`${label}.${field}: jövőbeli dátum (${value}) — evidence nem lehet jövőbeli`)
    return null
  }
  if (parsed.getTime() < new Date('2026-01-01').getTime()) {
    reasons.push(`${label}.${field}: gyanúsan régi dátum (${value})`)
    return null
  }
  if (maxAgeDays != null && now - parsed.getTime() > maxAgeDays * 24 * 3600 * 1000) {
    reasons.push(`${label}.${field}: ${value} régebbi, mint ${maxAgeDays} nap — friss evidence kell a release-hez`)
  }
  return parsed
}

function requireSha256(obj, field, label, reasons) {
  const value = requireString(obj, field, label, reasons)
  if (value != null && !/^[0-9a-fA-F]{64}$/.test(value)) {
    reasons.push(`${label}.${field}: nem 64 hex karakteres SHA-256: ${JSON.stringify(value)}`)
  }
  return value
}

function requireVersionMatch(obj, field, label, reasons) {
  const value = requireString(obj, field, label, reasons)
  const expected = rootVersion()
  if (value != null && value !== expected) {
    reasons.push(`${label}.${field} = ${value}, de a repo verziója ${expected} — az evidence nem erre a release-re vonatkozik`)
  }
}

// A kódban ténylegesen létező enforcement-flagek (idézőjeles string-literálok a
// backend java/sql forrásban) — a compliance-döntésnek MINDET le kell fednie.
function scanEnforcementFlags() {
  const flags = new Set()
  const roots = [
    path.join(repoRoot, 'backend', 'src', 'main', 'java'),
    path.join(repoRoot, 'backend', 'src', 'main', 'resources', 'db', 'migration'),
  ]
  const stack = roots.filter((dir) => fs.existsSync(dir))
  while (stack.length > 0) {
    const dir = stack.pop()
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name)
      if (entry.isDirectory()) {
        stack.push(full)
      } else if (/\.(java|sql)$/.test(entry.name)) {
        const text = fs.readFileSync(full, 'utf8')
        for (const match of text.matchAll(/['"]([A-Z][A-Z0-9_]*_ENFORCEMENT)['"]/g)) {
          flags.add(match[1])
        }
      }
    }
  }
  return [...flags].sort()
}

// ---------------------------------------------------------------------------
// Checkek — mind { id, title, evidenceFile?, run() => reasons[] } alakú.
// ---------------------------------------------------------------------------

function checkAcceptance() {
  const reasons = []
  const { data, error, missing } = readEvidenceJson('acceptance-report.json')
  if (error) return { reasons: [error], missing }
  checkPlaceholders(data, 'acceptance-report.json', reasons)
  const env = requireString(data, 'environment', 'acceptance', reasons)
  if (env != null && !['staging', 'production'].includes(env)) {
    reasons.push(`acceptance.environment: "${env}" — csak "staging" vagy "production" fogadható el`)
  }
  requireVersionMatch(data, 'appVersion', 'acceptance', reasons)
  requireDate(data, 'executedAt', 'acceptance', reasons, { maxAgeDays: MAX_EVIDENCE_AGE_DAYS })
  requireString(data, 'executedBy.name', 'acceptance', reasons)
  requireString(data, 'executedBy.role', 'acceptance', reasons)
  const scenarios = Array.isArray(data.scenarios) ? data.scenarios : null
  if (!scenarios) {
    reasons.push('acceptance.scenarios: hiányzó vagy nem tömb')
  } else {
    const seen = new Set()
    scenarios.forEach((scenario, i) => {
      const id = requireString(scenario, 'id', `acceptance.scenarios[${i}]`, reasons)
      requireString(scenario, 'name', `acceptance.scenarios[${i}]`, reasons)
      if (id != null) seen.add(id.toUpperCase())
      if (scenario.result !== 'PASS') {
        reasons.push(`acceptance.scenarios[${i}] (${scenario.id ?? '?'}): result = ${JSON.stringify(scenario.result)} — minden forgatókönyvnek PASS kell`)
      }
    })
    for (const required of REQUIRED_ACCEPTANCE_SCENARIOS) {
      if (!seen.has(required)) {
        reasons.push(`acceptance.scenarios: hiányzó kötelező forgatókönyv: ${required} (roadmap P0-4: vétel/eladás/sztornó/napzárás/havizárás)`)
      }
    }
  }
  if (data.overallResult !== 'PASS') {
    reasons.push(`acceptance.overallResult = ${JSON.stringify(data.overallResult)} — PASS kell`)
  }
  return { reasons }
}

function checkApprovals() {
  const reasons = []
  const { data, error, missing } = readEvidenceJson('approvals.json')
  if (error) return { reasons: [error], missing }
  checkPlaceholders(data, 'approvals.json', reasons)
  const approvals = Array.isArray(data.approvals) ? data.approvals : null
  if (!approvals) return { reasons: [...reasons, 'approvals.approvals: hiányzó vagy nem tömb'] }
  const seenRoles = new Set()
  approvals.forEach((approval, i) => {
    const role = requireString(approval, 'role', `approvals[${i}]`, reasons)
    requireString(approval, 'name', `approvals[${i}]`, reasons)
    requireString(approval, 'statement', `approvals[${i}]`, reasons)
    requireDate(approval, 'date', `approvals[${i}]`, reasons, { maxAgeDays: MAX_EVIDENCE_AGE_DAYS })
    if (approval.decision !== 'APPROVED') {
      reasons.push(`approvals[${i}] (${approval.role ?? '?'}): decision = ${JSON.stringify(approval.decision)} — APPROVED kell`)
    }
    if (role != null) seenRoles.add(role)
    // A product-jóváhagyásnak tételesen vállalnia kell az EXCMD nyitott gap-listát
    // (2026-06-04 audit: A6, B1–B4, B9, FR-EFM, FR-KC nyitott) — gap-vakon nincs release.
    if (role === 'product') {
      requireString(approval, 'acceptedOpenGapsRef', `approvals[${i}]`, reasons)
    }
  })
  for (const required of REQUIRED_APPROVAL_ROLES) {
    if (!seenRoles.has(required)) {
      reasons.push(`approvals: hiányzó kötelező jóváhagyó szerep: "${required}"`)
    }
  }
  return { reasons }
}

function checkCompliance() {
  const reasons = []
  const { data, error, missing } = readEvidenceJson('compliance-decision.json')
  if (error) return { reasons: [error], missing }
  checkPlaceholders(data, 'compliance-decision.json', reasons)
  if (data.decision !== 'APPROVED') {
    reasons.push(`compliance.decision = ${JSON.stringify(data.decision)} — APPROVED kell`)
  }
  requireString(data, 'approvedBy.name', 'compliance', reasons)
  requireString(data, 'approvedBy.role', 'compliance', reasons)
  requireString(data, 'scope', 'compliance', reasons)
  requireDate(data, 'date', 'compliance', reasons, { maxAgeDays: MAX_EVIDENCE_AGE_DAYS })

  // DB export: a dump NEM kerülhet a repóba (PII); helye + hash + időpont kell.
  const dbExport = data.dbExport
  if (!dbExport || typeof dbExport !== 'object') {
    reasons.push('compliance.dbExport: hiányzó objektum (location + sha256 + exportedAt + method)')
  } else {
    const location = requireString(dbExport, 'location', 'compliance.dbExport', reasons)
    const sha = requireSha256(dbExport, 'sha256', 'compliance.dbExport', reasons)
    requireDate(dbExport, 'exportedAt', 'compliance.dbExport', reasons, { maxAgeDays: MAX_EVIDENCE_AGE_DAYS })
    requireString(dbExport, 'method', 'compliance.dbExport', reasons)
    if (location != null && sha != null) {
      const inRepo = path.resolve(repoRoot, location)
      if (inRepo.startsWith(repoRoot + path.sep)) {
        // Nincs exists-then-read (TOCTOU): közvetlen olvasás, hiba = repón kívüli hely.
        let fileBytes = null
        try {
          fileBytes = fs.readFileSync(inRepo)
        } catch {
          fileBytes = null
        }
        if (fileBytes != null) {
          const actual = crypto.createHash('sha256').update(fileBytes).digest('hex')
          if (actual.toLowerCase() !== sha.toLowerCase()) {
            reasons.push(`compliance.dbExport: a(z) ${location} tényleges SHA-256-ja (${actual}) NEM egyezik a megadottal`)
          }
        }
      }
    }
  }

  // Enforcement-flag go-live döntések: a kódban TÉNYLEGESEN létező flagek mindegyikéről
  // explicit compliance-döntés kell (EXCMD audit: "flag-élesítés go-live üzleti döntés").
  const codeFlags = scanEnforcementFlags()
  const decisions = Array.isArray(data.enforcementFlagDecisions) ? data.enforcementFlagDecisions : []
  const decidedFlags = new Map()
  decisions.forEach((decision, i) => {
    const flag = requireString(decision, 'flag', `compliance.enforcementFlagDecisions[${i}]`, reasons)
    requireString(decision, 'justification', `compliance.enforcementFlagDecisions[${i}]`, reasons)
    if (!['ON', 'OFF', 'DEFER'].includes(decision.decision)) {
      reasons.push(`compliance.enforcementFlagDecisions[${i}] (${flag ?? '?'}): decision = ${JSON.stringify(decision.decision)} — ON/OFF/DEFER kell`)
    }
    if (flag != null) decidedFlags.set(flag, decision.decision)
  })
  for (const flag of codeFlags) {
    if (!decidedFlags.has(flag)) {
      reasons.push(`compliance: a kódban létező "${flag}" flagről nincs döntés (enforcementFlagDecisions)`)
    }
  }
  for (const flag of decidedFlags.keys()) {
    if (!codeFlags.includes(flag)) {
      reasons.push(`compliance: a(z) "${flag}" flag NEM létezik a backend kódban — hallucinált flag-döntés tilos`)
    }
  }
  return { reasons }
}

function checkDrDrill() {
  const reasons = []
  const { data, error, missing } = readEvidenceJson('dr-restore-drill.json')
  if (error) return { reasons: [error], missing }
  checkPlaceholders(data, 'dr-restore-drill.json', reasons)
  requireString(data, 'performedBy.name', 'dr-drill', reasons)
  requireString(data, 'environment', 'dr-drill', reasons)
  requireString(data, 'backupSource', 'dr-drill', reasons)
  requireDate(data, 'drillDate', 'dr-drill', reasons, { maxAgeDays: MAX_EVIDENCE_AGE_DAYS })
  const started = requireDate(data, 'restoreStartedAt', 'dr-drill', reasons)
  const completed = requireDate(data, 'restoreCompletedAt', 'dr-drill', reasons)
  if (started && completed) {
    const minutes = (completed.getTime() - started.getTime()) / 60000
    if (minutes <= 0) {
      reasons.push('dr-drill: restoreCompletedAt nem későbbi, mint restoreStartedAt')
    } else if (minutes > MAX_DR_RESTORE_MINUTES) {
      reasons.push(`dr-drill: mért helyreállítási idő ${Math.round(minutes)} perc > ${MAX_DR_RESTORE_MINUTES} perc cél (roadmap DoD: helyreállítás 1 órán belül)`)
    }
  }
  const checks = Array.isArray(data.postRestoreChecks) ? data.postRestoreChecks : null
  if (!checks || checks.length < 2) {
    reasons.push('dr-drill.postRestoreChecks: legalább 2 helyreállítás-utáni ellenőrzés kell (pl. adat-integritás + app-bejelentkezés)')
  } else {
    checks.forEach((check, i) => {
      requireString(check, 'name', `dr-drill.postRestoreChecks[${i}]`, reasons)
      if (check.result !== 'PASS') {
        reasons.push(`dr-drill.postRestoreChecks[${i}] (${check.name ?? '?'}): result = ${JSON.stringify(check.result)} — PASS kell`)
      }
    })
  }
  if (data.result !== 'PASS') {
    reasons.push(`dr-drill.result = ${JSON.stringify(data.result)} — PASS kell`)
  }
  return { reasons }
}

function checkMonitoring() {
  const reasons = []
  const { data, error, missing } = readEvidenceJson('monitoring-168h.json')
  if (error) return { reasons: [error], missing }
  checkPlaceholders(data, 'monitoring-168h.json', reasons)
  const start = requireDate(data, 'windowStart', 'monitoring', reasons)
  const end = requireDate(data, 'windowEnd', 'monitoring', reasons, { maxAgeDays: MAX_EVIDENCE_AGE_DAYS })
  if (start && end) {
    const hours = (end.getTime() - start.getTime()) / 3600000
    if (hours < MIN_MONITORING_HOURS) {
      reasons.push(`monitoring: a mért ablak ${Math.floor(hours)} óra < ${MIN_MONITORING_HOURS} óra (roadmap DoD: 7 nap folyamatos monitoring)`)
    }
  }
  requireString(data, 'source', 'monitoring', reasons)
  requireString(data, 'confirmedBy.name', 'monitoring', reasons)
  if (typeof data.uptimePercent !== 'number' || data.uptimePercent < MIN_UPTIME_PERCENT) {
    reasons.push(`monitoring.uptimePercent = ${JSON.stringify(data.uptimePercent)} — szám kell, ≥ ${MIN_UPTIME_PERCENT}`)
  }
  if (typeof data.p99LatencyMs !== 'number') {
    reasons.push('monitoring.p99LatencyMs: hiányzó számérték')
  }
  if (typeof data.errorRatePercent !== 'number') {
    reasons.push('monitoring.errorRatePercent: hiányzó számérték')
  }
  const incidents = Array.isArray(data.incidents) ? data.incidents : null
  if (!incidents) {
    reasons.push('monitoring.incidents: kötelező tömb (üres is lehet, de explicit)')
  } else {
    incidents.forEach((incident, i) => {
      requireString(incident, 'description', `monitoring.incidents[${i}]`, reasons)
      if (incident.resolved !== true) {
        reasons.push(`monitoring.incidents[${i}]: resolved = ${JSON.stringify(incident.resolved)} — megoldatlan incidenssel nincs product-ready`)
      }
    })
  }
  return { reasons }
}

function checkInstaller() {
  const reasons = []
  const { data, error, missing } = readEvidenceJson('signed-installer-vm-proof.json')
  if (error) return { reasons: [error], missing }
  checkPlaceholders(data, 'signed-installer-vm-proof.json', reasons)
  requireVersionMatch(data, 'appVersion', 'installer', reasons)
  requireString(data, 'installerFileName', 'installer', reasons)
  requireSha256(data, 'installerSha256', 'installer', reasons)
  requireDate(data, 'testedAt', 'installer', reasons, { maxAgeDays: MAX_EVIDENCE_AGE_DAYS })
  requireString(data, 'testedBy.name', 'installer', reasons)
  const signature = data.signature
  if (!signature || typeof signature !== 'object') {
    reasons.push('installer.signature: hiányzó objektum (subject + issuer + thumbprint + timestamped)')
  } else {
    requireString(signature, 'subject', 'installer.signature', reasons)
    requireString(signature, 'issuer', 'installer.signature', reasons)
    const thumbprint = requireString(signature, 'thumbprint', 'installer.signature', reasons)
    if (thumbprint != null && !/^[0-9a-fA-F]{32,64}$/.test(thumbprint)) {
      reasons.push('installer.signature.thumbprint: nem hexadecimális tanúsítvány-ujjlenyomat')
    }
    if (signature.timestamped !== true) {
      reasons.push('installer.signature.timestamped: true kell (időbélyeg nélküli aláírás lejár a tanúsítvánnyal)')
    }
  }
  const vm = data.cleanVm
  if (!vm || typeof vm !== 'object') {
    reasons.push('installer.cleanVm: hiányzó objektum (os + cleanSnapshot + steps)')
  } else {
    requireString(vm, 'os', 'installer.cleanVm', reasons)
    if (vm.cleanSnapshot !== true) {
      reasons.push('installer.cleanVm.cleanSnapshot: true kell — a teszt csak tiszta VM-en érvényes')
    }
    for (const step of ['install', 'launch', 'uninstall']) {
      const result = vm.steps?.[step]?.result
      if (result !== 'PASS') {
        reasons.push(`installer.cleanVm.steps.${step}.result = ${JSON.stringify(result)} — PASS kell`)
      }
    }
  }
  return { reasons }
}

function checkFinalEvidence() {
  const reasons = []
  const { data, error, missing } = readEvidenceJson('final-external-evidence.json')
  if (error) return { reasons: [error], missing }
  checkPlaceholders(data, 'final-external-evidence.json', reasons)
  requireVersionMatch(data, 'appVersion', 'evidence', reasons)
  requireString(data, 'statement', 'evidence', reasons)
  const requiredConfirmations = ['acceptance', 'approvals', 'compliance', 'dr-drill', 'monitoring', 'installer']
  for (const id of requiredConfirmations) {
    if (data.confirmations?.[id] !== true) {
      reasons.push(`evidence.confirmations["${id}"]: true kell — minden rész-evidence tételes megerősítése kötelező`)
    }
  }
  const signers = Array.isArray(data.signedOffBy) ? data.signedOffBy : null
  if (!signers || signers.length === 0) {
    reasons.push('evidence.signedOffBy: legalább egy névvel/szereppel/dátummal aláírt sign-off kell')
  } else {
    signers.forEach((signer, i) => {
      requireString(signer, 'name', `evidence.signedOffBy[${i}]`, reasons)
      requireString(signer, 'role', `evidence.signedOffBy[${i}]`, reasons)
      requireDate(signer, 'date', `evidence.signedOffBy[${i}]`, reasons, { maxAgeDays: MAX_EVIDENCE_AGE_DAYS })
    })
  }
  return { reasons }
}

// Repo-oldali gépi tények (FEJLESZTESI_IRANY_AUDIT DoD + roadmap P0-1/P0-2/P0-4).
function checkInternal() {
  const reasons = []

  const requiredFiles = [
    ['docs/user-manual/penztaros-kezikonyv.md', 'P0-1 pénztáros kézikönyv'],
    ['docs/user-manual/ertektaros-kezikonyv.md', 'P0-1 értéktáros kézikönyv'],
    ['docs/user-manual/admin-kezikonyv.md', 'P0-1 admin kézikönyv'],
    ['docs/operations/dr-backup-runbook.md', 'P0-2 DR/backup runbook'],
    ['docs/operations/monitoring-runbook.md', 'P0-3 monitoring runbook'],
    ['docs/operations/compliance-audit-checklist.md', 'P1-4 compliance checklist'],
    ['frontend-react/playwright/production-acceptance.spec.ts', 'P0-4 acceptance test suite'],
  ]
  for (const [relative, label] of requiredFiles) {
    if (!fs.existsSync(path.join(repoRoot, relative))) {
      reasons.push(`hiányzó repo-artifact: ${relative} (${label})`)
    }
  }

  // 4-way verzió-szinkron (FEJLESZTESI DoD: "Verzió-szinkron OK telepítő-buildnél").
  const sync = spawnSync(process.execPath, [path.join(repoRoot, 'scripts', 'check-version-sync.mjs')], {
    cwd: repoRoot,
    encoding: 'utf8',
  })
  if (sync.status !== 0) {
    reasons.push(`verzió-szinkron sértés: ${(sync.stderr || sync.stdout || '').trim().split('\n')[0]}`)
  }

  // Friss, zöld security gate riport (AGENTS/CLAUDE: deploy/release előtt kötelező).
  const gatePath = path.join(repoRoot, 'security-reports', 'latest', 'gate-status.json')
  if (!fs.existsSync(gatePath)) {
    reasons.push('hiányzó security gate riport: security-reports/latest/gate-status.json (futtasd: scripts/security/run-security-gate.ps1)')
  } else {
    try {
      const gate = JSON.parse(fs.readFileSync(gatePath, 'utf8').replace(/^﻿/, ''))
      if (gate.status !== 'PASSED') {
        reasons.push(`security gate státusz: ${JSON.stringify(gate.status)} — PASSED kell (riport: ${gate.timestamp ?? '?'})`)
      }
      const age = Date.now() - new Date(gate.timestamp).getTime()
      if (!gate.timestamp || Number.isNaN(age) || age > 30 * 24 * 3600 * 1000) {
        reasons.push(`security gate riport elavult (${gate.timestamp ?? 'nincs timestamp'}) — 30 napnál frissebb kell`)
      }
    } catch (err) {
      reasons.push(`security gate riport olvashatatlan: ${err.message}`)
    }
  }

  return { reasons }
}

// ---------------------------------------------------------------------------

const CHECKS = [
  { id: 'acceptance', title: 'Staging/production acceptance riport', run: checkAcceptance },
  { id: 'approvals', title: 'Product/ops/compliance jóváhagyások', run: checkApprovals },
  { id: 'compliance', title: 'Compliance döntés + DB export + flag-döntések', run: checkCompliance },
  { id: 'dr-drill', title: 'Valódi DR restore drill', run: checkDrDrill },
  { id: 'monitoring', title: '168 órás monitoring evidence', run: checkMonitoring },
  { id: 'installer', title: 'Aláírt telepítő + tiszta VM proof', run: checkInstaller },
  { id: 'evidence', title: 'Final external evidence (összegző sign-off)', run: checkFinalEvidence },
  { id: 'internal', title: 'Repo-oldali gépi DoD (manuálok, runbookok, verzió-sync, security gate)', run: checkInternal },
]

function runCheck(check) {
  const { reasons, missing } = check.run()
  return { ...check, status: reasons.length === 0 ? 'PASS' : missing ? 'MISSING' : 'FAIL', reasons }
}

function printResult(result, { verbose = true } = {}) {
  const mark = result.status === 'PASS' ? 'PASS   ' : result.status === 'MISSING' ? 'MISSING' : 'FAIL   '
  console.log(`[product-ready] ${mark} ${result.id} — ${result.title}`)
  if (verbose) {
    for (const reason of result.reasons) console.log(`                  - ${reason}`)
  }
}

function runAll() {
  return CHECKS.map(runCheck)
}

function finalGate({ exitOnFail }) {
  console.log(`[product-ready] Verifier — repo verzió: ${rootVersion()} — evidence: docs/release-evidence/`)
  const results = runAll()
  for (const result of results) printResult(result)
  const failed = results.filter((result) => result.status !== 'PASS')
  console.log('')
  if (failed.length === 0) {
    console.log('[product-ready] VERDIKT: PRODUCT READY — mind a 8 kapu igazolt evidence-szel zöld.')
    return 0
  }
  console.log(`[product-ready] VERDIKT: NEM PRODUCT READY — ${failed.length}/8 kapu nem teljesül:`)
  for (const result of failed) {
    console.log(`  - ${result.id}: ${result.status === 'MISSING' ? 'evidence fájl hiányzik' : `${result.reasons.length} hiba`}`)
  }
  console.log('  Sablonok: docs/release-evidence/templates/ — kitöltés után futtasd újra a kaput.')
  return exitOnFail ? 1 : 0
}

const command = (process.argv[2] ?? 'status').replace(/:complete$/, '')

if (command === 'status') {
  process.exit(finalGate({ exitOnFail: false }))
} else if (command === 'final-gate') {
  process.exit(finalGate({ exitOnFail: true }))
} else {
  const check = CHECKS.find((candidate) => candidate.id === command)
  if (!check) {
    console.error(`[product-ready] ismeretlen check: "${command}". Választható: status, final-gate, ${CHECKS.map((c) => c.id).join(', ')}`)
    process.exit(2)
  }
  const result = runCheck(check)
  printResult(result)
  process.exit(result.status === 'PASS' ? 0 : 1)
}
