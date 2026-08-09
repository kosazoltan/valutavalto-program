#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'
import http from 'node:http'
import https from 'node:https'

const root = process.cwd()
const memoryRoot = path.join(root, '.agent', 'memory')
const layers = ['qmd', 'yaml', 'cognee', 'vector', 'obsidian', 'reports']
const now = new Date().toISOString()

loadLocalEnv(path.join(root, '.env'))

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true })
}

function loadLocalEnv(file) {
  if (!fs.existsSync(file)) return
  const content = fs.readFileSync(file, 'utf8')
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim()
    if (!line || line.startsWith('#')) continue
    const eq = line.indexOf('=')
    if (eq <= 0) continue
    const key = line.slice(0, eq).trim()
    const repoScopedOverride = key.startsWith('OBSIDIAN_')
    if (process.env[key] && !repoScopedOverride) continue
    let value = line.slice(eq + 1).trim()
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1)
    }
    process.env[key] = value
  }
}

function obsidianTokenFromEnv() {
  return (
    process.env.OBSIDIAN_API_KEY ||
    process.env.OBSIDIAN_SYNC_TOKEN ||
    process.env.OBSIDIAN_KEY ||
    ''
  )
}

function obsidianBasesFromEnv() {
  const host = process.env.OBSIDIAN_HOST || '127.0.0.1'
  const protocol = process.env.OBSIDIAN_PROTOCOL || 'https'
  const port = process.env.OBSIDIAN_PORT || (protocol === 'http' ? '27123' : '27124')
  const primary = `${protocol}://${host}:${port}`
  return [...new Set([primary, 'https://127.0.0.1:27124', 'http://127.0.0.1:27123'])]
}

function requestLocalObsidian(urlString, options = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(urlString)
    const client = url.protocol === 'https:' ? https : http
    const body = options.body ?? ''
    const headers = { ...(options.headers || {}) }
    if (body && headers['Content-Length'] === undefined) {
      headers['Content-Length'] = Buffer.byteLength(body)
    }
    const req = client.request(
      url,
      {
        method: options.method || 'GET',
        headers,
        rejectUnauthorized: false,
      },
      (res) => {
        const chunks = []
        res.on('data', (chunk) => chunks.push(chunk))
        res.on('end', () => {
          const text = Buffer.concat(chunks).toString('utf8')
          resolve({
            ok: res.statusCode >= 200 && res.statusCode < 300,
            status: res.statusCode,
            text: async () => text,
          })
        })
      },
    )
    req.on('error', reject)
    if (body) req.write(body)
    req.end()
  })
}

function readText(file) {
  return fs.readFileSync(file, 'utf8')
}

function exists(file) {
  return fs.existsSync(file)
}

function rel(file) {
  return path.relative(root, file).replaceAll(path.sep, '/')
}

function listFiles(dir, exts) {
  const out = []
  if (!exists(dir)) return out
  const stack = [dir]
  while (stack.length) {
    const current = stack.pop()
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const full = path.join(current, entry.name)
      if (entry.isDirectory()) {
        const relPath = rel(full)
        if (
          relPath.includes('node_modules') ||
          relPath.includes('/target') ||
          relPath.includes('/dist')
        )
          continue
        stack.push(full)
      } else if (exts.some((ext) => entry.name.toLowerCase().endsWith(ext))) {
        out.push(full)
      }
    }
  }
  return out.sort()
}

function frontmatter(text) {
  if (!text.startsWith('---')) return {}
  const end = text.indexOf('\n---', 3)
  if (end === -1) return {}
  const raw = text.slice(3, end).trim()
  const data = {}
  for (const line of raw.split(/\r?\n/)) {
    const m = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/)
    if (m) data[m[1]] = m[2].replace(/^['"]|['"]$/g, '')
  }
  return data
}

function heading(text) {
  const m = text.match(/^#\s+(.+)$/m)
  return m ? m[1].trim() : ''
}

function sha(text) {
  return crypto.createHash('sha256').update(text).digest('hex')
}

function tokenize(text) {
  return Array.from(
    new Set(
      (
        text
          .toLowerCase()
          .normalize('NFD')
          .replace(/[\u0300-\u036f]/g, '')
          .match(/[a-z0-9_]{3,}/g) || []
      ).filter(
        (t) =>
          ![
            'the',
            'and',
            'for',
            'with',
            'hogy',
            'mint',
            'vagy',
            'this',
            'that',
            'true',
            'false',
            'null',
          ].includes(t),
      ),
    ),
  )
}

function summarize(text, max = 420) {
  const clean = text
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
  return clean.slice(0, max).trimEnd()
}

function classify(file, fm, title, text) {
  const r = rel(file)
  const lower = r.toLowerCase()
  if (r.includes('/feedback/')) return 'short-term-preferences'
  if (r.includes('/procedures/')) return 'operational-procedure'
  if (r.includes('/agent-archive/')) return 'operational-archive'
  if (r.includes('/references/')) return 'long-term-reference'
  if (r.includes('/sessions/')) return 'medium-term-episodic'
  if (
    lower.includes('legacy-reverse-engineering') ||
    lower.includes('legacy-analysis') ||
    lower.includes('legacy_parity') ||
    lower.includes('anti_legacy')
  )
    return 'long-term-legacy'
  if (lower.includes('receipt') || lower.includes('bizonylat') || lower.includes('materialreceipt'))
    return 'operational-receipt'
  if (r.includes('docs/knowledge/memory/')) return 'long-term-historical'
  if (r.includes('docs/operations/')) return 'operational-runbook'
  if (r.includes('docs/user-manual/')) return 'long-term-user-doc'
  if (r.includes('LESSONS_LEARNED')) return 'operational-lessons'
  if (r.includes('CLAUDE.md') || r.includes('AGENTS.md') || r.includes('AI_CONSTITUTION.md'))
    return 'short-term-core'
  return fm.type || 'semantic-reference'
}

// --- Area taxonomy -----------------------------------------------------------
// Every memory entry is tagged with zero or more product areas so that
// `memory:query --area <area>` can return only the knowledge that belongs to the
// program area currently being developed. Keep the keys stable: agent rules and
// CI gates reference them by name.
const AREA_RULES = {
  ertektar: {
    paths: ['ertektar', 'vault-', 'valuables', 'treasury'],
    keywords: [
      'ertektar',
      'értéktár',
      'vaulttransfer',
      'collection',
      'distribution',
      'ertekszallito',
      'értékszállító',
    ],
  },
  penztar: {
    paths: ['penztar-client', 'penztar', 'cashier'],
    keywords: ['penztar', 'pénztár', 'cashier', 'kktg', 'penztaros', 'pénztáros', 'cashbalance'],
  },
  napzaras: {
    paths: ['napzaras', 'dayclose', 'day-close'],
    keywords: ['napzaras', 'napzárás', 'dayclose', 'varazslo', 'varázsló', 'zaras', 'zárás'],
  },
  arfolyam: {
    paths: ['arfolyam', 'rate-maker', 'arfolyam-keszito'],
    keywords: ['arfolyam', 'árfolyam', 'mnb', 'exchangerate', 'ratemaker', 'arfolyamkeszito'],
  },
  cimletezes: {
    paths: ['denomination', 'cimlet'],
    keywords: ['cimlet', 'címlet', 'denomination', 'cimletezes', 'címletezés'],
  },
  sync: {
    paths: ['sync', 'offline', 'sync-engine'],
    keywords: ['sync', 'szinkron', 'offline', 'outbox', 'retry', 'sqljs', 'sql.js', 'local-first'],
  },
  aml: {
    paths: ['aml', 'sanction', 'pmt'],
    keywords: ['aml', 'pmt', 'gongyolites', 'göngyölítés', 'szankcio', 'szankció', 'pep', 'kyc'],
  },
  tenant: {
    paths: ['tenant', 'company'],
    keywords: ['companyid', 'multi-tenant', 'multitenant', 'tenant', 'izolacio', 'izoláció'],
  },
  riport: {
    paths: ['report', 'riport', 'nav-report'],
    keywords: ['nav', 'riport', 'report', 'adatszolgaltatas', 'adatszolgáltatás'],
  },
  database: {
    paths: ['flyway', 'migration', 'database/', 'db/'],
    keywords: ['flyway', 'migration', 'migracio', 'migráció', 'postgres', 'ddl', 'schema'],
  },
  installer: {
    paths: ['installer', 'nsis', 'electron-builder'],
    keywords: ['installer', 'telepito', 'telepítő', 'nsis', 'electron-builder', 'signing'],
  },
  deploy: {
    paths: ['deploy', 'operations', 'workflows'],
    keywords: ['deploy', 'hetzner', 'scaleway', 'neon', 'github actions', 'ci', 'release'],
  },
  security: {
    paths: ['security', 'audit'],
    keywords: ['security', 'biztonsag', 'biztonság', 'gitleaks', 'trivy', 'rbac', 'authz'],
  },
  frontend: {
    paths: ['frontend-react', 'kozponti-client'],
    keywords: ['react', 'tanstack', 'zustand', 'tailwind', 'vite', 'frontend'],
  },
  legacy: {
    paths: ['legacy', 'anti', 'excmd', 'felmeres-kb', 'reverse-engineering'],
    keywords: [
      'delphi',
      'legacy',
      'parity',
      'paritas',
      'paritás',
      'firebird',
      'pascal',
      'régi program',
      'regi program',
      'eredeti program',
    ],
  },
  // Requirement/specification corpus: what the business actually asked for.
  // Distinct from `legacy` (how the old program did it) — a feature task
  // usually needs both.
  specifikacio: {
    paths: ['excmd', 'docs/specs', 'kovetelmeny'],
    keywords: [
      'kovetelmeny',
      'követelmény',
      'specifikacio',
      'specifikáció',
      'elvaras',
      'elvárás',
      'felmeres',
      'felmérés',
      'interju',
      'interjú',
    ],
  },
}

function detectAreas(file, fm, title, text) {
  const relPath = rel(file).toLowerCase()
  const haystack = `${title}\n${fm.tags || ''}\n${text}`
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
  const found = new Set()
  for (const [area, rule] of Object.entries(AREA_RULES)) {
    if (rule.paths.some((p) => relPath.includes(p))) {
      found.add(area)
      continue
    }
    const hits = rule.keywords.filter((k) =>
      haystack.includes(k.normalize('NFD').replace(/[\u0300-\u036f]/g, '')),
    ).length
    // Two independent keyword hits keep incidental mentions out of the area.
    if (hits >= 2) found.add(area)
  }
  return Array.from(found).sort()
}

function collectSources() {
  const repoVault = path.join(root, 'vault')
  const vault = repoVault
  if (!exists(vault)) {
    throw new Error(`Repo-local vault not found: ${vault}`)
  }
  const candidates = []
  for (const file of [
    path.join(root, 'CLAUDE.md'),
    path.join(root, 'AGENTS.md'),
    path.join(root, 'AI_CONSTITUTION.md'),
    path.join(root, 'docs', 'LESSONS_LEARNED.md'),
    // Generated digest of the legacy Delphi symbol index. The corpus itself
    // (~45 MB of Pascal) is far too large to full-text index, but this map of
    // module -> exported API / form class / SQL tables answers "where did the
    // old program do X?" and is small enough to live in the bundle.
    path.join(root, '.agent', 'memory', 'legacy', 'legacy-module-map.md'),
  ])
    if (exists(file)) candidates.push(file)

  for (const dir of [
    path.join(root, 'docs', 'knowledge', 'memory'),
    path.join(root, 'docs', 'knowledge', 'analysis'),
    path.join(root, 'docs', 'knowledge', 'reviews'),
    path.join(root, 'docs', 'knowledge', 'legacy-reverse-engineering'),
    path.join(root, 'docs', 'knowledge', 'generated'),
    path.join(root, 'docs', 'operations'),
    path.join(root, 'docs', 'user-manual'),
    path.join(root, 'docs', 'legacy-analysis'),
    path.join(root, 'docs', 'architecture'),
    path.join(root, 'docs', 'specs'),
    path.join(root, 'docs', 'database'),
    path.join(root, 'docs', 'security'),
    path.join(root, 'docs', 'playbooks'),
    // EXCMD: the customer-facing specification / requirement corpus (~495 md).
    // This is where the original program's agreed behaviour is written down;
    // leaving it unindexed was the single biggest blind spot in the bundle.
    path.join(root, 'EXCMD'),
    path.join(vault, 'sessions'),
    path.join(vault, 'agent-archive'),
    path.join(vault, 'feedback'),
    path.join(vault, 'procedures'),
    path.join(vault, 'references'),
    path.join(vault, 'architecture'),
    path.join(vault, 'elvi'),
    path.join(vault, 'operations'),
  ]) {
    candidates.push(...listFiles(dir, ['.md', '.qmd', '.yaml', '.yml', '.csv', '.json', '.jsonl']))
  }

  // Top-level legacy/parity/architecture docs. These sit loose in docs/ and in
  // the repo root, and carry the Delphi-vs-modern gap analysis that a feature
  // task must consult before re-solving something the legacy already solved.
  for (const file of listFiles(path.join(root, 'docs'), ['.md'])) {
    if (rel(file).split('/').length !== 2) continue // docs/<file>.md only
    const base = path.basename(file).toUpperCase()
    if (
      base.includes('LEGACY') ||
      base.includes('ANTI') ||
      base.includes('ARCHITECTURE') ||
      base.includes('PARITY') ||
      base.includes('LESSONS') ||
      base.includes('MIGRATION') ||
      base.includes('TREASURY') ||
      base.includes('PENZTAR') ||
      base.includes('API-OVERVIEW') ||
      base.includes('CAPABILITIES')
    )
      candidates.push(file)
  }
  for (const name of [
    'ARCHITECTURE.md',
    'ARCHITECTURE_DECISIONS.md',
    'REPO_STATE.md',
    'AI_CONTRACT.md',
  ]) {
    const file = path.join(root, name)
    if (exists(file)) candidates.push(file)
  }
  for (const dir of [path.join(root, 'backend', 'src'), path.join(root, 'frontend-react', 'src')]) {
    candidates.push(
      ...listFiles(dir, ['.java', '.ts', '.tsx']).filter((file) => {
        const lower = file.toLowerCase()
        return (
          lower.includes('receipt') ||
          lower.includes('bizonylat') ||
          lower.includes('materialreceipt') ||
          lower.includes('legacy')
        )
      }),
    )
  }

  return Array.from(new Set(candidates)).filter(exists).sort()
}

function buildEntries() {
  return collectSources().map((file) => {
    const text = readText(file)
    const fm = frontmatter(text)
    const title = fm.title || heading(text) || path.basename(file)
    return {
      id: sha(rel(file)).slice(0, 16),
      path: rel(file).startsWith('..') ? file.replaceAll('\\', '/') : rel(file),
      title,
      type: classify(file, fm, title, text),
      created: fm.created || fm.date || null,
      status: fm.status || null,
      sha256: sha(text),
      bytes: Buffer.byteLength(text, 'utf8'),
      summary: summarize(text),
      areas: detectAreas(file, fm, title, text),
      keywords: tokenize(`${title}\n${text}`).slice(0, 40),
    }
  })
}

function yamlEscape(value) {
  if (value === null || value === undefined) return 'null'
  const text = String(value)
  if (/^[A-Za-z0-9_.:/# -]+$/.test(text) && !text.includes(': ')) return text
  return JSON.stringify(text)
}

function writeYaml(entries) {
  // Caps exist so the machine-readable layer stays loadable, but they must not
  // silently drop knowledge: the legacy/specification corpus is large and is
  // exactly what a feature task needs. Long-term is uncapped for that reason;
  // the query layer re-derives from source anyway, so these caps only bound the
  // browsable index, never what `memory:query` can find.
  const groups = {
    short_term: entries
      .filter((e) => e.type.startsWith('short-term') || e.type.includes('preferences'))
      .slice(0, 60),
    medium_term: entries.filter((e) => e.type.includes('episodic')).slice(-160),
    operational: entries.filter((e) => e.type.includes('operational')).slice(0, 160),
    long_term: entries.filter((e) => e.type.includes('long-term') || e.type.includes('semantic')),
  }
  const lines = []
  lines.push(`generated_at: ${now}`)
  lines.push(`schema_version: 1`)
  lines.push(`source_count: ${entries.length}`)
  for (const [name, items] of Object.entries(groups)) {
    lines.push(`${name}:`)
    for (const e of items) {
      lines.push(`  - id: ${e.id}`)
      lines.push(`    title: ${yamlEscape(e.title)}`)
      lines.push(`    type: ${yamlEscape(e.type)}`)
      lines.push(`    path: ${yamlEscape(e.path)}`)
      if (e.status) lines.push(`    status: ${yamlEscape(e.status)}`)
      lines.push(`    sha256: ${e.sha256}`)
      lines.push(`    summary: ${yamlEscape(e.summary)}`)
      lines.push(`    areas: [${e.areas.map(yamlEscape).join(', ')}]`)
      lines.push(`    keywords: [${e.keywords.slice(0, 12).map(yamlEscape).join(', ')}]`)
    }
  }
  fs.writeFileSync(path.join(memoryRoot, 'yaml', 'index.yaml'), lines.join('\n') + '\n', 'utf8')
}

function writeQmd(entries) {
  const sections = [
    [
      'Rovid Tavu Memoria',
      entries
        .filter((e) => e.type.startsWith('short-term') || e.type.includes('preferences'))
        .slice(0, 25),
    ],
    ['Kozep Tavu Memoria', entries.filter((e) => e.type.includes('episodic')).slice(-35)],
    ['Operativ Memoria', entries.filter((e) => e.type.includes('operational')).slice(0, 35)],
    [
      'Hosszu Tavu Memoria',
      entries
        .filter((e) => e.type.includes('long-term') || e.type.includes('semantic'))
        .slice(0, 50),
    ],
  ]
  const lines = [
    '---',
    'title: Repo multi-layer memory index',
    `generated: ${now}`,
    'format: gfm',
    '---',
    '',
    '# Repo Multi-Layer Memory Index',
    '',
    'Ez a fajl automatikusan generalodik a repo es az Obsidian vault ellenorzott forrasaibol.',
    '',
  ]
  for (const [title, items] of sections) {
    lines.push(`## ${title}`, '')
    for (const e of items) {
      lines.push(`- **${e.title}** (${e.type})`)
      lines.push(`  - source: \`${e.path}\``)
      lines.push(`  - summary: ${e.summary}`)
      lines.push('')
    }
  }
  fs.writeFileSync(path.join(memoryRoot, 'qmd', 'repo-memory.qmd'), lines.join('\n'), 'utf8')
}

function writeCognee(entries) {
  const lines = [
    'ingest_profile: repo-multilayer-memory',
    `generated_at: ${now}`,
    'kind: knowledge_bundle',
    'nodes:',
  ]
  for (const e of entries) {
    lines.push(`  - id: ${e.id}`)
    lines.push(`    type: ${yamlEscape(e.type)}`)
    lines.push(`    title: ${yamlEscape(e.title)}`)
    lines.push(`    source_path: ${yamlEscape(e.path)}`)
    lines.push(`    summary: ${yamlEscape(e.summary)}`)
    lines.push(`    tags: [${e.keywords.slice(0, 10).map(yamlEscape).join(', ')}]`)
    lines.push(`    areas: [${e.areas.map(yamlEscape).join(', ')}]`)
  }
  lines.push('edges:')
  for (const e of entries) {
    for (const area of e.areas) {
      lines.push(`  - from: ${e.id}`)
      lines.push(`    to: area_${area}`)
      lines.push('    relation: belongs_to_area')
    }
  }
  for (const e of entries.filter((x) => x.type.includes('episodic')).slice(-80)) {
    lines.push(`  - from: ${e.id}`)
    lines.push('    to: repo_project_state')
    lines.push('    relation: informs')
  }
  fs.writeFileSync(
    path.join(memoryRoot, 'cognee', 'knowledge-bundle.yaml'),
    lines.join('\n') + '\n',
    'utf8',
  )
}

function writeVector(entries) {
  const out =
    entries
      .map((e) =>
        JSON.stringify({
          id: e.id,
          path: e.path,
          title: e.title,
          type: e.type,
          sha256: e.sha256,
          embedding_model: 'local-keyword-hash-v1',
          areas: e.areas,
          vector: e.keywords
            .slice(0, 64)
            .map((t) => Number.parseInt(sha(t).slice(0, 8), 16) / 0xffffffff),
          keywords: e.keywords,
          text: `${e.title}\n${e.summary}`,
        }),
      )
      .join('\n') + '\n'
  fs.writeFileSync(path.join(memoryRoot, 'vector', 'vector-index.jsonl'), out, 'utf8')
}

function writeObsidian(entries) {
  const lines = [
    '---',
    'title: Repo Memory Mirror',
    `generated: ${now}`,
    '---',
    '',
    '# Repo Memory Mirror',
    '',
    'Ez a fajl a repo-lokalis memoria Obsidian-kompatibilis tukre.',
    '',
    '## Layer Counts',
    `- sources: ${entries.length}`,
    `- generated: ${now}`,
    '',
    '## Sources',
  ]
  for (const e of entries) lines.push(`- [[${e.title}]] — \`${e.path}\` (${e.type})`)
  fs.writeFileSync(
    path.join(memoryRoot, 'obsidian', 'repo-memory-mirror.md'),
    lines.join('\n') + '\n',
    'utf8',
  )
}

function copyObsidianMirrorToVault(obsMirror) {
  const repoVault = path.join(root, 'vault')
  const vaultRoot = repoVault
  if (!exists(vaultRoot)) {
    return { synced: false, reason: 'vault path missing', vaultRoot }
  }
  const targetDir = path.join(vaultRoot, 'references', 'repo-memory')
  ensureDir(targetDir)
  const target = path.join(targetDir, 'repo-memory-mirror.md')
  fs.copyFileSync(obsMirror, target)
  return { synced: true, mode: 'filesystem', path: rel(target) }
}

function detectOpenObsidianVaults() {
  const appData = process.env.APPDATA
  if (!appData) return []
  const obsidianConfig = path.join(appData, 'obsidian', 'obsidian.json')
  if (!exists(obsidianConfig)) return []
  try {
    const parsed = JSON.parse(fs.readFileSync(obsidianConfig, 'utf8'))
    const vaults = parsed?.vaults && typeof parsed.vaults === 'object' ? parsed.vaults : {}
    return Object.values(vaults)
      .filter(
        (vault) => vault?.open === true && typeof vault.path === 'string' && exists(vault.path),
      )
      .map((vault) => vault.path)
  } catch {
    return []
  }
}

function copyObsidianMirrorToOpenVaults(obsMirror) {
  const results = []
  for (const vaultRoot of detectOpenObsidianVaults()) {
    const targetDir = path.join(vaultRoot, 'Repo Memory')
    ensureDir(targetDir)
    const target = path.join(targetDir, 'repo-memory-mirror.md')
    fs.copyFileSync(obsMirror, target)
    results.push({ synced: true, mode: 'filesystem', path: target })
  }
  return results
}

async function syncCogneeBundle(cogneeBundle) {
  const base = process.env.COGNEE_URL || 'http://localhost:8098'
  try {
    const health = await fetch(`${base}/health`)
    if (!health.ok) {
      return { reachable: false, status: health.status, bundle: rel(cogneeBundle) }
    }

    const token = process.env.COGNEE_BEARER_TOKEN
    if (!token) {
      return {
        reachable: true,
        status: health.status,
        note: 'COGNEE_BEARER_TOKEN missing; generated import-ready bundle only',
        bundle: rel(cogneeBundle),
      }
    }

    const form = new FormData()
    const bytes = fs.readFileSync(cogneeBundle)
    form.append(
      'data',
      new Blob([bytes], { type: 'application/x-yaml' }),
      path.basename(cogneeBundle),
    )
    form.append('datasetName', 'valutavalto-repo-memory')
    form.append('node_set', 'repo-memory')
    const add = await fetch(`${base}/api/v1/add`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: form,
    })
    if (!add.ok) {
      return {
        reachable: true,
        uploaded: false,
        status: add.status,
        body: await add.text(),
        bundle: rel(cogneeBundle),
      }
    }

    const cognify = await fetch(`${base}/api/v1/cognify`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ datasets: ['valutavalto-repo-memory'], run_in_background: false }),
    })
    return {
      reachable: true,
      uploaded: true,
      add_status: add.status,
      cognify_status: cognify.status,
      cognified: cognify.ok,
      cognify_body: cognify.ok ? undefined : await cognify.text(),
      bundle: rel(cogneeBundle),
    }
  } catch (err) {
    return { reachable: false, error: err.message, bundle: rel(cogneeBundle) }
  }
}

async function status() {
  const report = { generated_at: now, checks: [] }
  report.checks.push({ name: 'memoryRoot', ok: exists(memoryRoot), path: rel(memoryRoot) })
  for (const layer of layers)
    report.checks.push({ name: layer, ok: exists(path.join(memoryRoot, layer)) })
  try {
    const res = await fetch('http://localhost:8098/health')
    report.checks.push({ name: 'cognee', ok: res.ok, status: res.status, detail: await res.text() })
  } catch (err) {
    report.checks.push({ name: 'cognee', ok: false, error: err.message })
  }
  for (const base of obsidianBasesFromEnv()) {
    const url = `${base}/`
    try {
      const obsidianToken = obsidianTokenFromEnv()
      const res = await requestLocalObsidian(url, {
        headers: obsidianToken ? { Authorization: `Bearer ${obsidianToken}` } : {},
      })
      const ok = res.ok || res.status === 401
      report.checks.push({ name: `obsidian:${url}`, ok, status: res.status })
      if (ok) break
    } catch (err) {
      report.checks.push({ name: `obsidian:${url}`, ok: false, error: err.message })
    }
  }
  fs.writeFileSync(
    path.join(memoryRoot, 'reports', 'status.json'),
    JSON.stringify(report, null, 2) + '\n',
    'utf8',
  )
  console.log(JSON.stringify(report, null, 2))
}

function build() {
  for (const layer of layers) ensureDir(path.join(memoryRoot, layer))
  const entries = buildEntries()
  writeYaml(entries)
  writeQmd(entries)
  writeCognee(entries)
  writeVector(entries)
  writeObsidian(entries)
  // Complete, uncapped source hash list. The QMD/YAML/Cognee layers are capped
  // per group for readability, so they cannot serve as a drift baseline; this
  // file is the authoritative one that `stale-check` compares against.
  fs.writeFileSync(
    path.join(memoryRoot, 'reports', 'sources.json'),
    JSON.stringify(
      {
        generated_at: now,
        source_count: entries.length,
        sources: entries.map((e) => ({
          path: e.path,
          sha256: e.sha256,
          type: e.type,
          areas: e.areas,
        })),
      },
      null,
      2,
    ) + '\n',
    'utf8',
  )
  fs.writeFileSync(
    path.join(memoryRoot, 'reports', 'manifest.json'),
    JSON.stringify({ generated_at: now, source_count: entries.length, layers }, null, 2) + '\n',
    'utf8',
  )
  console.log(`repo-memory build complete: ${entries.length} sources`)
}

async function sync() {
  build()
  const cogneeBundle = path.join(memoryRoot, 'cognee', 'knowledge-bundle.yaml')
  const obsMirror = path.join(memoryRoot, 'obsidian', 'repo-memory-mirror.md')
  const result = { generated_at: now, cognee: null, obsidian: null }
  result.cognee = await syncCogneeBundle(cogneeBundle)
  result.obsidian_filesystem = copyObsidianMirrorToVault(obsMirror)
  result.obsidian_open_vaults = copyObsidianMirrorToOpenVaults(obsMirror)
  const obsKey = obsidianTokenFromEnv()
  if (!obsKey) {
    result.obsidian = { synced: false, reason: 'OBSIDIAN_API_KEY missing', mirror: rel(obsMirror) }
  } else {
    let synced = false
    for (const base of obsidianBasesFromEnv()) {
      try {
        const res = await requestLocalObsidian(
          `${base}/vault/Repo%20Memory/repo-memory-mirror.md`,
          {
            method: 'PUT',
            headers: {
              Authorization: `Bearer ${obsKey}`,
              'Content-Type': 'text/markdown; charset=utf-8',
            },
            body: fs.readFileSync(obsMirror),
          },
        )
        if (res.ok) {
          result.obsidian = { synced: true, status: res.status, url: base }
          synced = true
          break
        }
        result.obsidian = { synced: false, status: res.status, url: base, body: await res.text() }
      } catch (err) {
        result.obsidian = { synced: false, url: base, error: err.message }
      }
    }
    if (!synced && !result.obsidian)
      result.obsidian = {
        synced: false,
        reason: 'Obsidian REST not reachable',
        mirror: rel(obsMirror),
      }
  }
  fs.writeFileSync(
    path.join(memoryRoot, 'reports', 'sync.json'),
    JSON.stringify(result, null, 2) + '\n',
    'utf8',
  )
  console.log(JSON.stringify(result, null, 2))
}

// --- Query layer -------------------------------------------------------------
// Read side of the memory system. Fully offline and deterministic: it re-derives
// the entry set from committed sources, so a query can never return knowledge
// that no longer exists in the repo.
function scoreEntry(entry, queryTokens) {
  if (!queryTokens.length) return 1
  const kw = new Set(entry.keywords)
  const haystack = `${entry.title}\n${entry.summary}\n${entry.path}`
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
  let score = 0
  for (const token of queryTokens) {
    if (kw.has(token)) score += 3
    if (haystack.includes(token)) score += 2
    if (entry.path.toLowerCase().includes(token)) score += 2
  }
  return score
}

// Recency and layer priority: active directives and recent episodes outrank
// historical archive material when the keyword score ties.
function entryPriority(entry) {
  let p = 0
  if (entry.type.startsWith('short-term')) p += 4
  if (entry.type.includes('operational')) p += 3
  if (entry.type.includes('episodic')) p += 2
  if (entry.status && entry.status.toLowerCase() === 'active') p += 2
  if (entry.created && /^20\d\d-\d\d-\d\d$/.test(entry.created)) {
    const ageDays = (Date.now() - Date.parse(entry.created)) / 86400000
    if (ageDays < 45) p += 3
    else if (ageDays < 120) p += 1
  }
  return p
}

function parseQueryArgs(argv) {
  const opts = { terms: [], areas: [], limit: 8, json: false, full: false }
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i]
    if (arg === '--area' || arg === '-a') {
      opts.areas.push(...String(argv[(i += 1)] || '').split(','))
    } else if (arg.startsWith('--area=')) {
      opts.areas.push(...arg.slice('--area='.length).split(','))
    } else if (arg === '--limit' || arg === '-n') {
      opts.limit = Number.parseInt(argv[(i += 1)], 10) || opts.limit
    } else if (arg.startsWith('--limit=')) {
      opts.limit = Number.parseInt(arg.slice('--limit='.length), 10) || opts.limit
    } else if (arg === '--json') {
      opts.json = true
    } else if (arg === '--full') {
      opts.full = true
    } else {
      opts.terms.push(arg)
    }
  }
  opts.areas = opts.areas.map((a) => a.trim()).filter(Boolean)
  return opts
}

function query(argv) {
  const opts = parseQueryArgs(argv)
  const unknown = opts.areas.filter((a) => !(a in AREA_RULES))
  if (unknown.length) {
    console.error(
      `Unknown area(s): ${unknown.join(', ')}\nKnown areas: ${Object.keys(AREA_RULES).join(', ')}`,
    )
    process.exit(2)
  }
  const queryTokens = tokenize(opts.terms.join(' '))
  let entries = buildEntries()
  if (opts.areas.length)
    entries = entries.filter((e) => opts.areas.some((a) => e.areas.includes(a)))

  const ranked = entries
    .map((e) => ({ entry: e, score: scoreEntry(e, queryTokens) + entryPriority(e) }))
    .filter((r) => (queryTokens.length ? r.score > entryPriority(r.entry) : true))
    .sort((a, b) => b.score - a.score || a.entry.path.localeCompare(b.entry.path))
    .slice(0, opts.limit)

  if (opts.json) {
    console.log(
      JSON.stringify(
        {
          generated_at: now,
          query: opts.terms.join(' '),
          areas: opts.areas,
          match_count: ranked.length,
          candidate_count: entries.length,
          results: ranked.map((r) => ({ score: r.score, ...r.entry, keywords: undefined })),
        },
        null,
        2,
      ),
    )
    return
  }

  console.log(`# repo-memory query`)
  console.log(`query: ${opts.terms.join(' ') || '(none)'}`)
  console.log(`areas: ${opts.areas.join(', ') || '(all)'}`)
  console.log(`candidates: ${entries.length}  matches: ${ranked.length}\n`)
  if (!ranked.length) {
    console.log('No stored knowledge matched. Treat this area as unrecorded and write memory')
    console.log(
      'at the end of the workflow (see .agent/memory/qmd/mandatory-memory-after-workflow.qmd).',
    )
    return
  }
  for (const { entry, score } of ranked) {
    console.log(`## ${entry.title}`)
    console.log(`- path: ${entry.path}`)
    console.log(`- type: ${entry.type}  areas: [${entry.areas.join(', ')}]  score: ${score}`)
    if (entry.created) console.log(`- created: ${entry.created}`)
    console.log(
      `- summary: ${opts.full ? summarize(readText(path.join(root, entry.path)), 1600) : entry.summary}`,
    )
    console.log('')
  }
}

function areasCommand() {
  const entries = buildEntries()
  const counts = Object.fromEntries(Object.keys(AREA_RULES).map((a) => [a, 0]))
  let untagged = 0
  for (const e of entries) {
    if (!e.areas.length) untagged += 1
    for (const a of e.areas) counts[a] += 1
  }
  console.log(JSON.stringify({ source_count: entries.length, untagged, areas: counts }, null, 2))
}

// --- Staleness gate ----------------------------------------------------------
// The committed bundle is only trustworthy if every source hash in it still
// matches the working tree. Any drift means an agent would read outdated
// knowledge, so this exits non-zero and is safe to wire into a push/CI gate.
function staleCheck() {
  const sourcesPath = path.join(memoryRoot, 'reports', 'sources.json')
  const result = { generated_at: now, ok: true, reasons: [] }
  if (!exists(sourcesPath)) {
    result.ok = false
    result.reasons.push('memory source manifest missing; run: npm run memory:build')
    console.log(JSON.stringify(result, null, 2))
    process.exit(1)
  }
  const committed = JSON.parse(readText(sourcesPath))
  const committedMap = new Map(committed.sources.map((s) => [s.path, s.sha256]))
  const entries = buildEntries()
  result.committed_source_count = committed.source_count
  result.current_source_count = entries.length

  const added = entries.filter((e) => !committedMap.has(e.path)).map((e) => e.path)
  const changed = entries
    .filter((e) => committedMap.has(e.path) && committedMap.get(e.path) !== e.sha256)
    .map((e) => e.path)
  const currentPaths = new Set(entries.map((e) => e.path))
  const removed = committed.sources.filter((s) => !currentPaths.has(s.path)).map((s) => s.path)

  result.added = added.length
  result.changed = changed.length
  result.removed = removed.length
  if (added.length || changed.length || removed.length) {
    result.ok = false
    result.reasons.push(
      `memory bundle is stale: ${added.length} added, ${changed.length} changed, ${removed.length} removed; run: npm run memory:build`,
    )
    result.examples = [...added, ...changed, ...removed].slice(0, 8)
  }
  console.log(JSON.stringify(result, null, 2))
  if (!result.ok) process.exit(1)
}

const cmd = process.argv[2] || 'status'
if (cmd === 'build') build()
else if (cmd === 'status') await status()
else if (cmd === 'sync') await sync()
else if (cmd === 'query') query(process.argv.slice(3))
else if (cmd === 'areas') areasCommand()
else if (cmd === 'stale-check') staleCheck()
else {
  console.error(
    'Usage: node scripts/repo-memory.mjs <build|status|sync|areas|stale-check>\n' +
      '       node scripts/repo-memory.mjs query [terms...] [--area <a[,b]>] [--limit N] [--json] [--full]',
  )
  process.exit(2)
}
