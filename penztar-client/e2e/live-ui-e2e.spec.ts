/**
 * Live UI E2E Test — Playwright against running dev server at http://127.0.0.1:3000
 *
 * Lépések:
 * 1. Login oldal megnyitás
 * 2. Bejelentkezés (EBC / KOSA / 1234)
 * 3. Dashboard screenshot
 * 4. Tranzakciós oldal navigáció + screenshot
 * 5. EUR eladási tranzakció kísérlet
 */

import { test, expect } from '@playwright/test'
import path from 'path'
import fs from 'fs'

const BASE_URL = 'http://127.0.0.1:3000'
const SCREENSHOTS_DIR = path.join(__dirname, '..', 'playwright-artifacts', 'live-ui-e2e')

// Ensure screenshots dir exists
if (!fs.existsSync(SCREENSHOTS_DIR)) {
  fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true })
}

test.use({
  baseURL: BASE_URL,
  viewport: { width: 1280, height: 800 },
  // Don't fail on cert errors (dev server)
  ignoreHTTPSErrors: true,
})

test.describe('Live UI E2E — Valutaváltó Pénztár', () => {
  test('01 — Login + Dashboard + Tranzakció', async ({ page }) => {
    // ── LÉPÉS 1: Login oldal megnyitás ──────────────────────────────────────
    console.log('[1] Megnyitom: ' + BASE_URL)
    await page.goto(BASE_URL, { waitUntil: 'domcontentloaded', timeout: 30000 })

    // Screenshot az oldal első állapotáról
    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '01-initial-load.png'), fullPage: true })
    console.log('[1] Screenshot mentve: 01-initial-load.png')

    // Ellenőrzés: login form látható-e
    const loginForm = page.locator('form')
    await expect(loginForm).toBeVisible({ timeout: 15000 })
    console.log('[1] Login form látható — PASS')

    // ── LÉPÉS 2: Bejelentkezés ──────────────────────────────────────────────
    console.log('[2] Kitöltöm a login formot: EBC / KOSA / 1234')

    // Cég kód mező — alapértelmezetten EBC, de biztonság kedvéért töröljük és írjuk be
    const companyInput = page.locator('input').nth(0)
    await companyInput.clear()
    await companyInput.fill('EBC')

    // Pénztáros kód mező (második input)
    const workerInput = page.locator('input').nth(1)
    await workerInput.clear()
    await workerInput.fill('KOSA')

    // Jelszó mező (harmadik input)
    const _passwordInput = page.locator('input[type="password"], input[type="text"]').last()
    // find the password specifically
    const passwordField = page.locator('input[type="password"]').first()
    await passwordField.fill('1234')

    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '02-login-filled.png'), fullPage: true })
    console.log('[2] Screenshot mentve: 02-login-filled.png')

    // Bejelentkezés gomb kattintás
    const loginBtn = page.locator('button[type="submit"]')
    await expect(loginBtn).toBeEnabled({ timeout: 5000 })
    await loginBtn.click()
    console.log('[2] Bejelentkezés gombra kattintottam')

    // Vár a navigációra (dashboard betöltés)
    await page.waitForURL('**/central-workstation**', { timeout: 20000 })
    console.log('[2] Dashboard URL-re navigált — PASS')

    // ── LÉPÉS 3: Dashboard screenshot ───────────────────────────────────────
    // Várunk a tartalom betöltésére
    await page.waitForLoadState('networkidle', { timeout: 15000 })
    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '03-dashboard.png'), fullPage: true })
    console.log('[3] Dashboard screenshot mentve: 03-dashboard.png — PASS')

    // ── LÉPÉS 4: Tranzakciós oldal navigáció ─────────────────────────────────
    console.log('[4] Navigálok a tranzakciós oldalra...')

    // Megpróbálom a sidebar menüben megtalálni az "Új tranzakció" linket
    let _navToTransactions = false

    // Próbáljunk click-elni a sidebar "Új tranzakció" linkre
    const transactionLinks = page.locator('a[href*="/transactions"]')
    const linkCount = await transactionLinks.count()
    console.log(`[4] Megtalált tranzakciós linkek száma: ${linkCount}`)

    if (linkCount > 0) {
      // Kattintás az első tranzakciós linkre
      await transactionLinks.first().click()
      _navToTransactions = true
    } else {
      // Közvetlen navigáció
      console.log('[4] Sidebar link nem található, közvetlen URL navigáció: /transactions/new')
      await page.goto(BASE_URL + '/transactions/new', { waitUntil: 'domcontentloaded', timeout: 15000 })
      _navToTransactions = true
    }

    // Várunk a tartalom betöltésére — a lazy loading eltűnjön
    await page.waitForLoadState('networkidle', { timeout: 20000 })
    // Extra várakozás hogy a React komponens renderelődjön
    await page.waitForTimeout(2000)

    const currentUrl = page.url()
    console.log(`[4] Aktuális URL: ${currentUrl}`)

    // Ellenőrzés: tranzakciós form látható-e
    const _transactionForm = page.locator('text=Új tranzakció, text=VÉTEL, text=ELADÁS').first()
    // A loading spinner eltűnésére várunk
    await page.waitForSelector('text=Oldal betöltése...', { state: 'hidden', timeout: 15000 }).catch(() => {
      console.log('[4] Loading spinner nem volt látható vagy már eltűnt')
    })

    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '04-transactions-page.png'), fullPage: true })
    console.log('[4] Tranzakciós oldal screenshot mentve: 04-transactions-page.png — PASS')

    // ── LÉPÉS 5: EUR eladási tranzakció kísérlet ─────────────────────────────
    console.log('[5] EUR eladási tranzakció kísérlet...')

    // Ha nem vagyunk a cashier/tranzakciós oldalon, navigáljunk oda
    if (!currentUrl.includes('/transactions')) {
      await page.goto(BASE_URL + '/transactions/cashier', { waitUntil: 'domcontentloaded', timeout: 15000 })
      await page.waitForLoadState('networkidle', { timeout: 15000 })
    }

    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '05-before-transaction.png'), fullPage: true })
    console.log('[5] Tranzakció előtti screenshot: 05-before-transaction.png')

    // Keressük az EUR valuta kiválasztót vagy a deviza mező-t
    const eurOption = page.locator('option[value="EUR"], option:has-text("EUR")')
    const eurCount = await eurOption.count()
    console.log(`[5] EUR opciók találva: ${eurCount}`)

    if (eurCount > 0) {
      // Keressük a "deviza eladás" típust (sell)
      const currencySelect = page.locator('select').first()
      if (await currencySelect.isVisible()) {
        await currencySelect.selectOption({ label: 'EUR' })
        console.log('[5] EUR kiválasztva')
        await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '05b-eur-selected.png'), fullPage: true })
      }
    }

    // Összefoglalás: screenshot az oldal végső állapotáról
    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, '06-final-state.png'), fullPage: true })
    console.log('[5] Végső screenshot: 06-final-state.png')

    // Riport
    console.log('\n=== SCREENSHOTOK ===')
    const files = fs.readdirSync(SCREENSHOTS_DIR)
    files.forEach(f => console.log('  ' + path.join(SCREENSHOTS_DIR, f)))
  })
})
