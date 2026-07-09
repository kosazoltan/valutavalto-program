#!/usr/bin/env node
// OpenAPI -> TypeScript tipus-generator
// Single source of truth: Spring Boot (springdoc-openapi) /api-docs
// Output: packages/shared-api/src/openapi.d.ts (frontend-react + penztar-client ebbol importal)
//
// A /api-docs JWT-vedett (production hardening), ezert a script:
//   1. Lekerdezi a bootstrap-status-t
//   2. Ha kell, bootstrap admin: EBC/ADMIN/Admin1234!
//   3. Login -> JWT token
//   4. GET /api-docs Bearer tokennel
//   5. openapi-typescript futtatas

import { spawn } from 'node:child_process'
import { writeFile, mkdir } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(__dirname, '..')
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080'
const SPEC_URL = `${BACKEND_URL}/api-docs`
const OUTPUT_DIR = resolve(ROOT, 'packages/shared-api/src')
const OUTPUT_FILE = resolve(OUTPUT_DIR, 'openapi.d.ts')

const ADMIN_CREDS = {
  companyCode: process.env.ADMIN_COMPANY || 'EBC',
  workerCode: process.env.ADMIN_USER || 'ADMIN',
  password: process.env.ADMIN_PASS || 'Admin1234!',
}

async function http(url, init = {}) {
  const resp = await fetch(url, init)
  const text = await resp.text()
  let body
  try {
    body = JSON.parse(text)
  } catch {
    body = text
  }
  return { ok: resp.ok, status: resp.status, body }
}

async function ensureAdmin() {
  const status = await http(`${BACKEND_URL}/api/v1/auth/bootstrap-status`)
  if (!status.ok) throw new Error(`bootstrap-status failed: HTTP ${status.status}`)
  if (!status.body.completed) {
    console.log('[typegen] bootstrap admin letrehozasa...')
    await http(`${BACKEND_URL}/api/v1/auth/bootstrap-admin`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        companyCode: ADMIN_CREDS.companyCode,
        workerCode: ADMIN_CREDS.workerCode,
        workerName: 'Rendszer Admin',
        email: '',
        newPassword: ADMIN_CREDS.password,
      }),
    })
  }
}

async function login() {
  const resp = await http(`${BACKEND_URL}/api/v1/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(ADMIN_CREDS),
  })
  if (!resp.ok || !resp.body.token) {
    throw new Error(`login failed: HTTP ${resp.status} ${JSON.stringify(resp.body).slice(0, 200)}`)
  }
  return resp.body.token
}

async function fetchSpec(token) {
  const resp = await http(SPEC_URL, { headers: { Authorization: `Bearer ${token}` } })
  if (!resp.ok) throw new Error(`spec fetch HTTP ${resp.status}`)
  return resp.body
}

async function generate() {
  console.log(`[typegen] ${SPEC_URL}`)
  await ensureAdmin()
  const token = await login()
  console.log(`[typegen] JWT token: ${token.length} char`)
  const spec = await fetchSpec(token)
  console.log(
    `[typegen] spec OK: ${Object.keys(spec.paths || {}).length} path, ${Object.keys(spec.components?.schemas || {}).length} schema`,
  )

  if (!existsSync(OUTPUT_DIR)) await mkdir(OUTPUT_DIR, { recursive: true })
  const specFile = resolve(OUTPUT_DIR, 'openapi.json')
  await writeFile(specFile, JSON.stringify(spec, null, 2), 'utf-8')

  const child = spawn('npx', ['-y', 'openapi-typescript@^7', specFile, '-o', OUTPUT_FILE], {
    stdio: 'inherit',
    shell: true,
    cwd: ROOT,
  })
  await new Promise((done, fail) => {
    child.on('exit', (code) =>
      code === 0 ? done() : fail(new Error(`openapi-typescript exit ${code}`)),
    )
    child.on('error', fail)
  })

  const prettier = spawn('npx', ['prettier', '--write', OUTPUT_FILE, specFile], {
    stdio: 'inherit',
    shell: true,
    cwd: ROOT,
  })
  await new Promise((done, fail) => {
    prettier.on('exit', (code) =>
      code === 0 ? done() : fail(new Error(`prettier exit ${code}`)),
    )
    prettier.on('error', fail)
  })
  console.log(`[typegen] OK: ${OUTPUT_FILE}`)
}

generate().catch((err) => {
  console.error('[typegen] HIBA:', err.message)
  process.exit(1)
})
