/**
 * RED/GREEN proof for the EOL-independent source hashing fix.
 *
 * Takes one tracked markdown source, flips its on-disk line endings between the
 * two checkout forms, and re-runs `memory:stale-check` each time. A correct
 * implementation reports ok=true in BOTH forms, because neither is an edit.
 *
 * Usage: node scripts/__tests__/eol-proof.mjs
 */
import { execFileSync } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const root = path.join(here, '..', '..')
const target = path.join(root, 'vault', 'sessions', 'handoff-2026-09-13-fkh070-kezelesi-dij-elvart.md')

const CR = String.fromCharCode(13)
const LF = String.fromCharCode(10)

function toLf(buf) {
  return Buffer.from(buf.toString('utf8').split(CR + LF).join(LF), 'utf8')
}
function toCrlf(buf) {
  return Buffer.from(toLf(buf).toString('utf8').split(LF).join(CR + LF), 'utf8')
}

function staleCheck() {
  try {
    const out = execFileSync(process.execPath, [path.join(root, 'scripts', 'repo-memory.mjs'), 'stale-check'], {
      cwd: root,
      encoding: 'utf8',
    })
    return JSON.parse(out)
  } catch (err) {
    return JSON.parse(err.stdout || '{"ok":false,"reasons":["no output"]}')
  }
}

const original = fs.readFileSync(target)
let failures = 0
try {
  for (const [label, bytes] of [
    ['CRLF checkout (autocrlf=true, Windows)', toCrlf(original)],
    ['LF checkout (autocrlf=false, Linux/CI)', toLf(original)],
  ]) {
    fs.writeFileSync(target, bytes)
    const r = staleCheck()
    const verdict = r.ok ? 'PASS' : `FAIL (changed=${r.changed})`
    if (!r.ok) failures += 1
    console.log(`${verdict}  ${label}  ->  ok=${r.ok} added=${r.added} changed=${r.changed} removed=${r.removed}`)
  }
} finally {
  fs.writeFileSync(target, original)
}
console.log(failures === 0 ? 'RESULT: hashes are EOL-independent' : `RESULT: ${failures} checkout form(s) report false drift`)
process.exit(failures === 0 ? 0 : 1)
