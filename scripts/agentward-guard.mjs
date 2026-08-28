#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'
import { execFileSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const repoRoot = path.resolve(__dirname, '..')
const reportDir = path.join(repoRoot, '.agent', 'ci')
const blockedGoogleClientIds = [
  '110671459871-30f1spbu0hptbs60cb4vsmv79i7bbvqj.apps.googleusercontent.com',
]

const allowedBlocklistReferences = new Set([
  'AGENTS.md',
  'scripts/agentward-guard.mjs',
  'vault/procedures/parallax-agentward-protocol.md',
  'vault/sessions/2026-05-12-parallax-agentward-implementation.md',
])

const excludedPrefixes = [
  '.agent/ci/',
  '.agent/memory/',
  'backend/target/',
  'dist/',
  // EXCMD/Anti legacy referencia-fa (PR #1105, 9115 fajl, base64 blobok) — a
  // forrasok/Anti/ precedensevel kizarva: szandekosan nem-UTF8/nem-szkennelendo anyag.
  'legacy-transfer/',
  'forrasok/Anti/',
  'frontend-react/dist/',
  'frontend-react/node_modules/',
  'kozponti-client/dist/',
  'kozponti-client/node_modules/',
  'node_modules/',
  'penztar-client/dist/',
  'penztar-client/dist-electron/',
  'penztar-client/node_modules/',
  'vault/Repo Memory/',
  'vault/references/repo-memory/',
]

const textExtensions = new Set([
  '.cjs',
  '.conf',
  '.css',
  '.env',
  '.example',
  '.html',
  '.java',
  '.js',
  '.json',
  '.jsx',
  '.md',
  '.mjs',
  '.properties',
  '.ps1',
  '.qmd',
  '.sh',
  '.sql',
  '.toml',
  '.ts',
  '.tsx',
  '.txt',
  '.xml',
  '.yaml',
  '.yml',
])

const checks = []
const findings = []

function rel(file) {
  return path.relative(repoRoot, file).replaceAll(path.sep, '/')
}

function readText(file) {
  return fs.readFileSync(file, 'utf8')
}

function addCheck(name, ok, detail) {
  checks.push({ name, ok, detail })
  if (ok) {
    console.log(`[agentward] OK ${name}${detail ? ` - ${detail}` : ''}`)
  } else {
    console.error(`[agentward] FAIL ${name}${detail ? ` - ${detail}` : ''}`)
  }
}

function addFinding(kind, file, detail) {
  findings.push({ kind, file, detail })
}

function listGitFiles() {
  const out = execFileSync('git', ['ls-files', '--cached', '--others', '--exclude-standard'], {
    cwd: repoRoot,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    // ENOBUFS-fix (2026-06-12): a legacy-transfer/ beemelese (9115 fajl) utan a
    // ls-files kimenet tullepte a Node default 1MB-os maxBuffer-et → a guard elhalt.
    maxBuffer: 64 * 1024 * 1024,
  })
  return out
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
}

function isExcluded(file) {
  return excludedPrefixes.some((prefix) => file === prefix.slice(0, -1) || file.startsWith(prefix))
}

function isProbablyText(file) {
  const ext = path.extname(file).toLowerCase()
  if (textExtensions.has(ext)) return true
  return path.basename(file).startsWith('.env')
}

function safeReadTrackedText(file) {
  const full = path.join(repoRoot, file)
  if (!fs.existsSync(full)) return null
  const stat = fs.statSync(full)
  if (stat.size > 1_000_000) return null
  if (!isProbablyText(file)) return null
  try {
    return readText(full)
  } catch {
    return null
  }
}

function checkRequiredFiles() {
  const required = [
    'AGENTS.md',
    'scripts/agentward-guard.mjs',
    'scripts/agent-decision-log.mjs',
    'vault/procedures/parallax-agentward-protocol.md',
  ]
  const missing = required.filter((file) => !fs.existsSync(path.join(repoRoot, file)))
  addCheck(
    'global-procedure-files',
    missing.length === 0,
    missing.length ? `missing: ${missing.join(', ')}` : 'present',
  )
}

function checkPackageScripts() {
  const pkg = JSON.parse(readText(path.join(repoRoot, 'package.json')))
  const scripts = pkg.scripts ?? {}
  const requiredScripts = [
    'agent:guard',
    'agent:archive',
    'self-check:before-lint',
    'self-check:before-merge',
    'self-check:before-deploy',
  ]
  const missingScripts = requiredScripts.filter((name) => !scripts[name])
  addCheck(
    'package-script-presence',
    missingScripts.length === 0,
    missingScripts.length ? `missing: ${missingScripts.join(', ')}` : 'present',
  )

  const gateScripts = [
    'self-check:before-lint',
    'self-check:before-merge',
    'self-check:before-deploy',
  ]
  const missingGuard = gateScripts.filter(
    (name) => !String(scripts[name] ?? '').includes('agent:guard'),
  )
  addCheck(
    'agentward-in-npm-gates',
    missingGuard.length === 0,
    missingGuard.length ? `missing in: ${missingGuard.join(', ')}` : 'wired',
  )

  const prePush = readText(path.join(repoRoot, 'scripts', 'pre-push-quality-gate.ps1'))
  addCheck('agentward-in-pre-push-gate', prePush.includes('agentward-guard.mjs'), 'PowerShell gate')
}

function checkGitignore() {
  const gitignore = readText(path.join(repoRoot, '.gitignore'))
  const requiredPatterns = ['client_secret*.json', '*client_secret*.json']
  const missing = requiredPatterns.filter((pattern) => !gitignore.includes(pattern))
  addCheck(
    'oauth-secret-filename-ignore',
    missing.length === 0,
    missing.length ? `missing: ${missing.join(', ')}` : 'present',
  )
}

function scanFiles() {
  const allFiles = listGitFiles()
  let contentScanned = 0
  for (const file of allFiles) {
    // Copilot PR #1106: a FAJLNEV-alapu tiltas MINDEN fajlra fut — a kizart fak
    // (legacy-transfer/, forrasok/Anti/) alatt sem lapulhat OAuth client-secret JSON.
    if (/client_secret.*\.json$/i.test(path.basename(file))) {
      addFinding(
        'oauth-client-secret-file',
        file,
        'Google OAuth client secret JSON must stay outside the repo',
      )
    }

    // A TARTALOM-szkenneles a kizart fakra nem fut (teljesitmeny + base64-zaj).
    if (isExcluded(file)) continue
    contentScanned++

    const text = safeReadTrackedText(file)
    if (text === null) continue

    for (const clientId of blockedGoogleClientIds) {
      if (text.includes(clientId) && !allowedBlocklistReferences.has(file)) {
        addFinding('blocked-oauth-client-id', file, 'Context.ai OAuth client ID is blocklisted')
      }
    }

    if (/"client_secret"\s*:\s*"GOCSPX-[^"]{12,}"/i.test(text)) {
      addFinding('google-client-secret-json', file, 'Google client_secret literal detected')
    }
    if (hasSecretLikeEnvAssignment(text)) {
      addFinding('secret-like-env-assignment', file, 'Secret-like env assignment detected')
    }
    if (/-----BEGIN (RSA |EC |OPENSSH |)PRIVATE KEY-----/.test(text)) {
      addFinding('private-key-block', file, 'Private key material detected')
    }
  }

  addCheck(
    'secret-and-blocklist-scan',
    findings.length === 0,
    findings.length
      ? `${findings.length} finding(s)`
      : `${contentScanned} file(s) content-scanned, ${allFiles.length} filename-checked`,
  )
}

function hasSecretLikeEnvAssignment(text) {
  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim()
    if (!line || line.startsWith('#')) continue
    const match = line.match(
      /^([A-Z0-9_]*(?:SECRET|TOKEN|PASSWORD|PRIVATE_KEY)[A-Z0-9_]*)\s*=\s*(.+)$/,
    )
    if (!match) continue
    // FP-class exclusion (2026-08-28): a QUOTED enumeration of secret VARIABLE
    // NAMES (e.g. deploy-hetzner.yml `SHARED_SECRETS="JWT_SECRET ENCRYPTION_KEY ..."`,
    // PR #1654) is a name list, not a value. The RHS is a value only when it is
    // something other than bare uppercase identifiers. Unquoted name lists and
    // any lowercase content are still treated as literal values.
    // FK-098 review tightening (sourcery+copilot+codex): the exemption applies ONLY to
    // the known enumeration variable name SHARED_SECRETS (deploy-hetzner.yml, PR #1654).
    // Any OTHER quoted uppercase multi-token value is treated as a literal secret value
    // and goes through the normal length/placeholder checks (fail-closed default).
    if (
      match[1] === 'SHARED_SECRETS' &&
      /^(['"])[A-Z0-9_]+(?:\s+[A-Z0-9_]+)+\1$/.test(match[2].trim())
    ) continue
    const value = match[1] && match[2] ? match[2].trim().replace(/^['"]|['"]$/g, '') : ''
    if (!value) continue
    const normalized = value.toLowerCase()
    const placeholderPrefixes = [
      '${',
      '<',
      'change_',
      'change-',
      'change this',
      'change_me',
      'change_this',
      'changeme',
      'your_',
      'your-',
      'placeholder',
      'replace_',
      'set_by_',
      'secure_',
      'local_secure_',
      'example_',
      'dummy_',
      'test_',
      '$',
    ]
    if (placeholderPrefixes.some((prefix) => normalized.startsWith(prefix))) continue
    if (normalized.includes('placeholder') || normalized.includes('change_me')) continue
    if (value.length >= 24) return true
  }
  return false
}

function writeReport() {
  fs.mkdirSync(reportDir, { recursive: true })
  const stamp = new Date().toISOString().replaceAll(':', '-').replaceAll('.', '-')
  const reportPath = path.join(reportDir, `agentward-guard-${stamp}.md`)
  const lines = [
    '# AgentWard Guard Report',
    '',
    `generated_at: ${new Date().toISOString()}`,
    '',
    '## Checks',
    '',
    ...checks.map(
      (check) =>
        `- ${check.ok ? 'PASS' : 'FAIL'} ${check.name}${check.detail ? ` - ${check.detail}` : ''}`,
    ),
    '',
    '## Findings',
    '',
    findings.length === 0
      ? '- none'
      : findings
          .map((finding) => `- ${finding.kind}: ${finding.file} - ${finding.detail}`)
          .join('\n'),
    '',
  ]
  fs.writeFileSync(reportPath, lines.join('\n'), 'utf8')
  console.log(`[agentward] report=${rel(reportPath)}`)
}

try {
  checkRequiredFiles()
  checkPackageScripts()
  checkGitignore()
  scanFiles()
  writeReport()
} catch (error) {
  console.error(`[agentward] ERROR ${error instanceof Error ? error.message : String(error)}`)
  process.exit(1)
}

if (checks.some((check) => !check.ok) || findings.length > 0) {
  process.exit(1)
}
