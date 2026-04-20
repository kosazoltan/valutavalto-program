#!/usr/bin/env node
// Cross-platform + idempotent postgres starter
import { spawn, execSync } from 'node:child_process'
import { platform } from 'node:os'

const isWin = platform() === 'win32'

function dockerInspect(name) {
  try {
    execSync(`docker inspect --format "{{.State.Running}}" ${name}`, { stdio: 'pipe' })
    const out = execSync(`docker inspect --format "{{.State.Running}}" ${name}`).toString().trim()
    return out === 'true'
  } catch { return null }
}

async function main() {
  const name = 'valuta-postgres'
  const state = dockerInspect(name)
  if (state === true) {
    console.log(`[dev-db] ${name} already running - no-op`)
    return
  }
  if (state === false) {
    console.log(`[dev-db] ${name} exists but stopped - starting...`)
    const r = spawn('docker', ['start', name], { stdio: 'inherit', shell: isWin })
    r.on('exit', code => process.exit(code ?? 0))
    return
  }
  console.log(`[dev-db] ${name} not found - creating via docker-compose...`)
  const r = spawn('docker', ['compose', 'up', '-d', 'postgres'], { stdio: 'inherit', shell: isWin })
  r.on('exit', code => process.exit(code ?? 0))
}
main()
