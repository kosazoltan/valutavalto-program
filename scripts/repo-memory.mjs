#!/usr/bin/env node
import fs from 'node:fs'
import path from 'node:path'
import crypto from 'node:crypto'

const root = process.cwd()
const memoryRoot = path.join(root, '.agent', 'memory')
const layers = ['qmd', 'yaml', 'cognee', 'vector', 'obsidian', 'reports']
const now = new Date().toISOString()

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true })
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
        if (relPath.includes('node_modules') || relPath.includes('/target') || relPath.includes('/dist')) continue
        stack.push(full)
      } else if (exts.some(ext => entry.name.toLowerCase().endsWith(ext))) {
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
  return Array.from(new Set((text.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').match(/[a-z0-9_]{3,}/g) || [])
    .filter(t => !['the','and','for','with','hogy','mint','vagy','this','that','true','false','null'].includes(t))))
}

function summarize(text, max = 420) {
  const clean = text.replace(/```[\s\S]*?```/g, ' ').replace(/\s+/g, ' ').trim()
  return clean.slice(0, max)
}

function classify(file, fm, title, text) {
  const r = rel(file)
  const lower = r.toLowerCase()
  if (r.includes('/feedback/')) return 'short-term-preferences'
  if (r.includes('/procedures/')) return 'operational-procedure'
  if (r.includes('/references/')) return 'long-term-reference'
  if (r.includes('/sessions/')) return 'medium-term-episodic'
  if (lower.includes('legacy-reverse-engineering') || lower.includes('legacy-analysis') || lower.includes('legacy_parity') || lower.includes('anti_legacy')) return 'long-term-legacy'
  if (lower.includes('receipt') || lower.includes('bizonylat') || lower.includes('materialreceipt')) return 'operational-receipt'
  if (r.includes('docs/knowledge/memory/')) return 'long-term-historical'
  if (r.includes('docs/operations/')) return 'operational-runbook'
  if (r.includes('docs/user-manual/')) return 'long-term-user-doc'
  if (r.includes('LESSONS_LEARNED')) return 'operational-lessons'
  if (r.includes('CLAUDE.md') || r.includes('AGENTS.md') || r.includes('AI_CONSTITUTION.md')) return 'short-term-core'
  return fm.type || 'semantic-reference'
}

function collectSources() {
  const repoVault = path.join(root, 'vault')
  const vault = process.env.VALUTA_VAULT_PATH || repoVault
  if (!exists(vault)) {
    throw new Error(`Repo-local vault not found: ${vault}`)
  }
  const candidates = []
  for (const file of [
    path.join(root, 'CLAUDE.md'),
    path.join(root, 'AGENTS.md'),
    path.join(root, 'AI_CONSTITUTION.md'),
    path.join(root, 'docs', 'LESSONS_LEARNED.md'),
  ]) if (exists(file)) candidates.push(file)

  for (const dir of [
    path.join(root, 'docs', 'knowledge', 'memory'),
    path.join(root, 'docs', 'operations'),
    path.join(root, 'docs', 'user-manual'),
    path.join(root, 'docs', 'knowledge', 'legacy-reverse-engineering'),
    path.join(root, 'docs', 'legacy-analysis'),
    path.join(root, 'docs', 'knowledge', 'analysis'),
    path.join(vault, 'sessions'),
    path.join(vault, 'feedback'),
    path.join(vault, 'procedures'),
    path.join(vault, 'references'),
  ]) {
    candidates.push(...listFiles(dir, ['.md', '.qmd', '.yaml', '.yml', '.csv', '.json']))
  }
  for (const dir of [path.join(root, 'backend', 'src'), path.join(root, 'frontend-react', 'src')]) {
    candidates.push(...listFiles(dir, ['.java', '.ts', '.tsx'])
      .filter(file => {
        const lower = file.toLowerCase()
        return lower.includes('receipt')
          || lower.includes('bizonylat')
          || lower.includes('materialreceipt')
          || lower.includes('legacy')
      }))
  }

  return Array.from(new Set(candidates)).filter(exists).sort()
}

function buildEntries() {
  return collectSources().map(file => {
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
  const groups = {
    short_term: entries.filter(e => e.type.startsWith('short-term') || e.type.includes('preferences')).slice(0, 40),
    medium_term: entries.filter(e => e.type.includes('episodic')).slice(-80),
    operational: entries.filter(e => e.type.includes('operational')).slice(0, 80),
    long_term: entries.filter(e => e.type.includes('long-term') || e.type.includes('semantic')).slice(0, 140),
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
      lines.push(`    keywords: [${e.keywords.slice(0, 12).map(yamlEscape).join(', ')}]`)
    }
  }
  fs.writeFileSync(path.join(memoryRoot, 'yaml', 'index.yaml'), lines.join('\n') + '\n', 'utf8')
}

function writeQmd(entries) {
  const sections = [
    ['Rovid Tavu Memoria', entries.filter(e => e.type.startsWith('short-term') || e.type.includes('preferences')).slice(0, 25)],
    ['Kozep Tavu Memoria', entries.filter(e => e.type.includes('episodic')).slice(-35)],
    ['Operativ Memoria', entries.filter(e => e.type.includes('operational')).slice(0, 35)],
    ['Hosszu Tavu Memoria', entries.filter(e => e.type.includes('long-term') || e.type.includes('semantic')).slice(0, 50)],
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
  const lines = ['ingest_profile: repo-multilayer-memory', `generated_at: ${now}`, 'kind: knowledge_bundle', 'nodes:']
  for (const e of entries.slice(0, 220)) {
    lines.push(`  - id: ${e.id}`)
    lines.push(`    type: ${yamlEscape(e.type)}`)
    lines.push(`    title: ${yamlEscape(e.title)}`)
    lines.push(`    source_path: ${yamlEscape(e.path)}`)
    lines.push(`    summary: ${yamlEscape(e.summary)}`)
    lines.push(`    tags: [${e.keywords.slice(0, 10).map(yamlEscape).join(', ')}]`)
  }
  lines.push('edges:')
  for (const e of entries.filter(x => x.type.includes('episodic')).slice(-80)) {
    lines.push(`  - from: ${e.id}`)
    lines.push('    to: repo_project_state')
    lines.push('    relation: informs')
  }
  fs.writeFileSync(path.join(memoryRoot, 'cognee', 'knowledge-bundle.yaml'), lines.join('\n') + '\n', 'utf8')
}

function writeVector(entries) {
  const out = entries.map(e => JSON.stringify({
    id: e.id,
    path: e.path,
    title: e.title,
    type: e.type,
    sha256: e.sha256,
    embedding_model: 'local-keyword-hash-v1',
    vector: e.keywords.slice(0, 64).map(t => Number.parseInt(sha(t).slice(0, 8), 16) / 0xffffffff),
    keywords: e.keywords,
    text: `${e.title}\n${e.summary}`,
  })).join('\n') + '\n'
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
  for (const e of entries.slice(0, 180)) lines.push(`- [[${e.title}]] — \`${e.path}\` (${e.type})`)
  fs.writeFileSync(path.join(memoryRoot, 'obsidian', 'repo-memory-mirror.md'), lines.join('\n') + '\n', 'utf8')
}

function copyObsidianMirrorToVault(obsMirror) {
  const repoVault = path.join(root, 'vault')
  const vaultRoot = process.env.VALUTA_VAULT_PATH || repoVault
  if (!exists(vaultRoot)) {
    return { synced: false, reason: 'vault path missing', vaultRoot }
  }
  const targetDir = path.join(vaultRoot, 'references', 'repo-memory')
  ensureDir(targetDir)
  const target = path.join(targetDir, 'repo-memory-mirror.md')
  fs.copyFileSync(obsMirror, target)
  return { synced: true, mode: 'filesystem', path: target.replaceAll('\\', '/') }
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
    form.append('data', new Blob([bytes], { type: 'application/x-yaml' }), path.basename(cogneeBundle))
    form.append('datasetName', 'valutavalto-repo-memory')
    form.append('node_set', 'repo-memory')
    const add = await fetch(`${base}/api/v1/add`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
      body: form,
    })
    if (!add.ok) {
      return { reachable: true, uploaded: false, status: add.status, body: await add.text(), bundle: rel(cogneeBundle) }
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
  report.checks.push({ name: 'memoryRoot', ok: exists(memoryRoot), path: memoryRoot })
  for (const layer of layers) report.checks.push({ name: layer, ok: exists(path.join(memoryRoot, layer)) })
  try {
    const res = await fetch('http://localhost:8098/health')
    report.checks.push({ name: 'cognee', ok: res.ok, status: res.status, detail: await res.text() })
  } catch (err) { report.checks.push({ name: 'cognee', ok: false, error: err.message }) }
  for (const url of ['https://127.0.0.1:27124/', 'http://127.0.0.1:27123/']) {
    try {
      const obsidianToken = process.env.OBSIDIAN_API_KEY || process.env.OBSIDIAN_SYNC_TOKEN
      const res = await fetch(url, { headers: obsidianToken ? { Authorization: `Bearer ${obsidianToken}` } : {} })
      report.checks.push({ name: `obsidian:${url}`, ok: res.ok || res.status === 401, status: res.status })
      break
    } catch (err) {
      report.checks.push({ name: `obsidian:${url}`, ok: false, error: err.message })
    }
  }
  fs.writeFileSync(path.join(memoryRoot, 'reports', 'status.json'), JSON.stringify(report, null, 2) + '\n', 'utf8')
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
  fs.writeFileSync(path.join(memoryRoot, 'reports', 'manifest.json'), JSON.stringify({ generated_at: now, source_count: entries.length, layers }, null, 2) + '\n', 'utf8')
  console.log(`repo-memory build complete: ${entries.length} sources`)
}

async function sync() {
  build()
  const cogneeBundle = path.join(memoryRoot, 'cognee', 'knowledge-bundle.yaml')
  const obsMirror = path.join(memoryRoot, 'obsidian', 'repo-memory-mirror.md')
  const result = { generated_at: now, cognee: null, obsidian: null }
  result.cognee = await syncCogneeBundle(cogneeBundle)
  result.obsidian_filesystem = copyObsidianMirrorToVault(obsMirror)
  const obsKey = process.env.OBSIDIAN_API_KEY || process.env.OBSIDIAN_SYNC_TOKEN
  if (!obsKey) {
    result.obsidian = { synced: false, reason: 'OBSIDIAN_API_KEY missing', mirror: rel(obsMirror) }
  } else {
    let synced = false
    for (const base of ['https://127.0.0.1:27124', 'http://127.0.0.1:27123']) {
      try {
        const res = await fetch(`${base}/vault/Repo%20Memory/repo-memory-mirror.md`, {
          method: 'PUT',
          headers: { Authorization: `Bearer ${obsKey}`, 'Content-Type': 'text/markdown; charset=utf-8' },
          body: fs.readFileSync(obsMirror),
        })
        if (res.ok) { result.obsidian = { synced: true, status: res.status, url: base }; synced = true; break }
        result.obsidian = { synced: false, status: res.status, url: base, body: await res.text() }
      } catch (err) { result.obsidian = { synced: false, url: base, error: err.message } }
    }
    if (!synced && !result.obsidian) result.obsidian = { synced: false, reason: 'Obsidian REST not reachable', mirror: rel(obsMirror) }
  }
  fs.writeFileSync(path.join(memoryRoot, 'reports', 'sync.json'), JSON.stringify(result, null, 2) + '\n', 'utf8')
  console.log(JSON.stringify(result, null, 2))
}

const cmd = process.argv[2] || 'status'
if (cmd === 'build') build()
else if (cmd === 'status') await status()
else if (cmd === 'sync') await sync()
else {
  console.error('Usage: node scripts/repo-memory.mjs <build|status|sync>')
  process.exit(2)
}
