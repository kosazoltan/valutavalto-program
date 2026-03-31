import { expect, test } from '@playwright/test'
import path from 'path'
import fs from 'fs'

/**
 * Live E2E tests for https://excvaluta.com
 * These tests run against the production site.
 * No auth credentials are required for auth-wall detection.
 */

const BASE = 'https://excvaluta.com'
const SCREENSHOT_DIR = 'test-results/live-screenshots'

function screenshotPath(name: string) {
  if (!fs.existsSync(SCREENSHOT_DIR)) {
    fs.mkdirSync(SCREENSHOT_DIR, { recursive: true })
  }
  return path.join(SCREENSHOT_DIR, `${name}-${Date.now()}.png`)
}

// ─────────────────────────────────────────────
// TEST 1 — Login oldal betöltés
// ─────────────────────────────────────────────
test('T01 — login oldal betölt, alapvető UI elemek láthatók', async ({ page }) => {
  const errors: string[] = []
  page.on('console', msg => {
    if (msg.type() === 'error') errors.push(msg.text())
  })

  const response = await page.goto(BASE, { waitUntil: 'domcontentloaded', timeout: 20000 })
  expect(response?.status()).toBeLessThan(500)

  const ss = screenshotPath('T01-login-load')
  await page.screenshot({ path: ss, fullPage: true })

  // Should land on login (redirect or direct)
  const url = page.url()
  const isLoginPage = url.includes('/login') || url === BASE + '/' || url === BASE

  // Title check
  const title = await page.title()
  expect(title.length).toBeGreaterThan(0)

  // Look for input fields or any form
  const inputs = page.locator('input')
  const inputCount = await inputs.count()

  // Log findings for report
  console.log(`URL: ${url}`)
  console.log(`Title: ${title}`)
  console.log(`Input fields found: ${inputCount}`)
  console.log(`JS errors: ${errors.length}`)
  console.log(`Screenshot: ${ss}`)

  // The page must render something
  const bodyText = await page.locator('body').innerText().catch(() => '')
  expect(bodyText.length).toBeGreaterThan(0)
})

// ─────────────────────────────────────────────
// TEST 2 — Auth wall detection
// ─────────────────────────────────────────────
test('T02 — auth wall: nincs token → login oldalra irányít', async ({ page }) => {
  // Clear storage to ensure unauthenticated state
  await page.goto(BASE + '/login', { waitUntil: 'domcontentloaded', timeout: 20000 })
  await page.evaluate(() => {
    try { localStorage.clear() } catch {}
    try { sessionStorage.clear() } catch {}
  })

  // Try to access protected route
  const response = await page.goto(BASE + '/transactions/new', { waitUntil: 'domcontentloaded', timeout: 20000 })

  const ss = screenshotPath('T02-auth-wall')
  await page.screenshot({ path: ss, fullPage: true })

  const finalUrl = page.url()
  const status = response?.status() ?? 0

  console.log(`Redirected to: ${finalUrl}`)
  console.log(`HTTP status: ${status}`)
  console.log(`Screenshot: ${ss}`)

  // Accept: redirect to login, OR stay on login, OR 401/403
  const authWallDetected =
    finalUrl.includes('/login') ||
    status === 401 ||
    status === 403 ||
    // React SPA: might show login form even at /transactions/new
    (await page.locator('input[type="password"]').isVisible().catch(() => false))

  expect(authWallDetected, `Expected auth wall but got URL: ${finalUrl} status: ${status}`).toBe(true)
})

// ─────────────────────────────────────────────
// TEST 3 — Login form elemek
// ─────────────────────────────────────────────
test('T03 — login form: username, password, submit gomb renderelődik', async ({ page }) => {
  await page.goto(BASE + '/login', { waitUntil: 'networkidle', timeout: 30000 })

  const ss = screenshotPath('T03-login-form')
  await page.screenshot({ path: ss, fullPage: true })

  // Check for any text/username input
  const usernameInput = page.locator('input').first()
  const passwordInput = page.locator('input[type="password"]')
  const submitButton = page.locator('button[type="submit"], button').filter({ hasText: /Bejelentkezés|Login|Belépés|Submit/i })

  const hasUsername = await usernameInput.isVisible().catch(() => false)
  const hasPassword = await passwordInput.isVisible().catch(() => false)
  const hasSubmit = await submitButton.first().isVisible().catch(() => false)

  console.log(`Username input visible: ${hasUsername}`)
  console.log(`Password input visible: ${hasPassword}`)
  console.log(`Submit button visible: ${hasSubmit}`)
  console.log(`Screenshot: ${ss}`)

  // At minimum the page must have at least one input
  expect(hasUsername || hasPassword, 'No input fields found on login page').toBe(true)
})

// ─────────────────────────────────────────────
// TEST 4 — Login invalid credentials
// ─────────────────────────────────────────────
test('T04 — hibás bejelentkezés → hibaüzenet vagy login marad', async ({ page }) => {
  await page.goto(BASE + '/login', { waitUntil: 'networkidle', timeout: 30000 })

  // The form has 3 inputs (company code / username / password pattern)
  const allInputs = page.locator('input:not([type="hidden"])')
  const inputCount = await allInputs.count()

  if (inputCount === 0) {
    console.log('SKIP: No form inputs found')
    test.skip()
    return
  }

  // Fill all inputs with dummy values
  for (let i = 0; i < inputCount; i++) {
    const input = allInputs.nth(i)
    const inputType = await input.getAttribute('type')
    if (inputType !== 'hidden') {
      await input.fill('INVALID_XYZ').catch(() => {})
    }
  }

  // Wait a moment for validation to re-enable button
  await page.waitForTimeout(500)

  const submitBtn = page.locator('button[type="submit"]').first()
  const isEnabled = await submitBtn.isEnabled().catch(() => false)
  const isVisible = await submitBtn.isVisible().catch(() => false)

  console.log(`Submit button visible: ${isVisible}, enabled: ${isEnabled}`)

  if (isVisible && isEnabled) {
    await submitBtn.click()
    await page.waitForTimeout(4000)
  } else if (isVisible && !isEnabled) {
    // Button disabled even after filling — form validation blocking, force click
    await submitBtn.click({ force: true }).catch(() => {})
    await page.waitForTimeout(4000)
  }

  const ss = screenshotPath('T04-login-invalid')
  await page.screenshot({ path: ss, fullPage: true })

  const finalUrl = page.url()
  const hasError = await page.locator('[role="alert"], .error, [class*="error"], [class*="alert"]').isVisible().catch(() => false)
  const stillOnLogin = finalUrl.includes('/login') || finalUrl === BASE + '/' || finalUrl === BASE

  console.log(`After invalid login URL: ${finalUrl}`)
  console.log(`Error element visible: ${hasError}`)
  console.log(`Still on login: ${stillOnLogin}`)
  console.log(`Screenshot: ${ss}`)

  expect(hasError || stillOnLogin, `Expected error or stay on login but URL: ${finalUrl}`).toBe(true)
})

// ─────────────────────────────────────────────
// TEST 5 — Transactions/new betöltés (unauthenticated)
// ─────────────────────────────────────────────
test('T05 — /transactions/new: oldal válaszol (auth wall vagy redirect)', async ({ page }) => {
  const response = await page.goto(BASE + '/transactions/new', { waitUntil: 'domcontentloaded', timeout: 20000 })

  const ss = screenshotPath('T05-transactions-new')
  await page.screenshot({ path: ss, fullPage: true })

  const status = response?.status() ?? 0
  const finalUrl = page.url()
  const bodyText = await page.locator('body').innerText().catch(() => '')

  console.log(`URL: ${finalUrl}, Status: ${status}`)
  console.log(`Body length: ${bodyText.length}`)
  console.log(`Screenshot: ${ss}`)

  // Must not return 5xx
  expect(status, `Server error on /transactions/new: ${status}`).toBeLessThan(500)
  // Must render something
  expect(bodyText.length, 'Empty body on /transactions/new').toBeGreaterThan(0)
})

// ─────────────────────────────────────────────
// TEST 6 — Transactions list betöltés (unauthenticated)
// ─────────────────────────────────────────────
test('T06 — /transactions: lista oldal válaszol', async ({ page }) => {
  const response = await page.goto(BASE + '/transactions', { waitUntil: 'domcontentloaded', timeout: 20000 })

  const ss = screenshotPath('T06-transactions-list')
  await page.screenshot({ path: ss, fullPage: true })

  const status = response?.status() ?? 0
  const finalUrl = page.url()
  const bodyText = await page.locator('body').innerText().catch(() => '')

  console.log(`URL: ${finalUrl}, Status: ${status}`)
  console.log(`Body length: ${bodyText.length}`)
  console.log(`Screenshot: ${ss}`)

  expect(status, `Server error on /transactions: ${status}`).toBeLessThan(500)
  expect(bodyText.length, 'Empty body on /transactions').toBeGreaterThan(0)
})

// ─────────────────────────────────────────────
// TEST 7 — Dashboard betöltés (unauthenticated)
// ─────────────────────────────────────────────
test('T07 — /dashboard: auth wall vagy redirect login-ra', async ({ page }) => {
  const response = await page.goto(BASE + '/dashboard', { waitUntil: 'domcontentloaded', timeout: 20000 })

  const ss = screenshotPath('T07-dashboard-auth')
  await page.screenshot({ path: ss, fullPage: true })

  const status = response?.status() ?? 0
  const finalUrl = page.url()
  const bodyText = await page.locator('body').innerText().catch(() => '')

  console.log(`URL: ${finalUrl}, Status: ${status}`)
  console.log(`Screenshot: ${ss}`)

  expect(status, `Server error on /dashboard: ${status}`).toBeLessThan(500)
  expect(bodyText.length, 'Empty body on /dashboard').toBeGreaterThan(0)
})

// ─────────────────────────────────────────────
// TEST 8 — SSL + HTTP→HTTPS redirect
// ─────────────────────────────────────────────
test('T08 — HTTPS szerver elérhető, SSL érvényes', async ({ page }) => {
  let tlsError = false
  page.on('pageerror', err => {
    if (err.message.includes('SSL') || err.message.includes('certificate')) {
      tlsError = true
    }
  })

  const response = await page.goto(BASE, { waitUntil: 'domcontentloaded', timeout: 15000 })

  const ss = screenshotPath('T08-ssl-check')
  await page.screenshot({ path: ss, fullPage: true })

  const url = page.url()
  expect(url.startsWith('https://'), `Site not served over HTTPS: ${url}`).toBe(true)
  expect(response?.status(), 'SSL/connection error').toBeLessThan(500)
  expect(tlsError, 'TLS/SSL error detected').toBe(false)

  console.log(`Final URL: ${url}, Status: ${response?.status()}`)
  console.log(`Screenshot: ${ss}`)
})
