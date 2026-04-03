/**
 * TELJES E2E Playwright teszt — minden funkció, valódi interakció
 * Target: http://127.0.0.1:3000 (Electron DEV mód)
 * Backend: https://excvaluta.com/api/v1 (Vite proxy)
 */

import { test, expect, Page } from '@playwright/test'
import path from 'path'
import fs from 'fs'

const BASE_URL = 'http://127.0.0.1:3000'
const SCREENSHOTS_DIR = path.join(__dirname, '..', 'playwright-artifacts', 'full-e2e')

// Ensure screenshots dir exists
if (!fs.existsSync(SCREENSHOTS_DIR)) {
  fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true })
}

async function ss(page: Page, name: string) {
  const filePath = path.join(SCREENSHOTS_DIR, name)
  await page.screenshot({ path: filePath, fullPage: true })
  console.log(`[SCREENSHOT] ${name}`)
  return filePath
}

async function waitNoSpinner(page: Page) {
  await page.waitForSelector('[data-testid="loading"]', { state: 'hidden', timeout: 10000 }).catch(() => {})
  await page.waitForLoadState('networkidle', { timeout: 10000 }).catch(() => {})
}

async function login(page: Page) {
  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded', timeout: 30000 })
  await page.waitForTimeout(1500)

  // Use data-testid if available, fallback to nth
  const companyField = page.locator('[data-testid="login-company-code"]')
  if (await companyField.isVisible({ timeout: 3000 }).catch(() => false)) {
    await companyField.fill('EBC')
    await page.locator('[data-testid="login-worker-code"]').fill('KOSA')
    await page.locator('[data-testid="login-password"]').fill('1234')
    await page.locator('[data-testid="login-submit"]').click()
  } else {
    // fallback
    await page.locator('input').nth(0).fill('EBC')
    await page.locator('input').nth(1).fill('KOSA')
    await page.locator('input[type="password"]').first().fill('1234')
    await page.locator('button[type="submit"]').click()
  }

  await page.waitForURL('**/dashboard**', { timeout: 20000 })
  await waitNoSpinner(page)
}

// ─────────────────────────────────────────────────────────────
// TEST 1: Login + Dashboard
// ─────────────────────────────────────────────────────────────
test('01 — Login + Dashboard', async ({ page }) => {
  console.log('\n=== TEST 01: LOGIN + DASHBOARD ===')

  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded', timeout: 30000 })
  await page.waitForTimeout(1500)
  await ss(page, '01-login-page.png')

  // Fill login form
  const companyField = page.locator('[data-testid="login-company-code"]')
  if (await companyField.isVisible({ timeout: 5000 }).catch(() => false)) {
    console.log('[LOGIN] data-testid input-ok találva')
    await companyField.fill('EBC')
    await page.locator('[data-testid="login-worker-code"]').fill('KOSA')
    await page.locator('[data-testid="login-password"]').fill('1234')
    await ss(page, '01-login-filled.png')
    await page.locator('[data-testid="login-submit"]').click()
  } else {
    console.log('[LOGIN] data-testid nem található, fallback nth selectorok')
    const inputs = page.locator('input')
    const count = await inputs.count()
    console.log(`[LOGIN] Input mezők száma: ${count}`)
    await inputs.nth(0).fill('EBC')
    await inputs.nth(1).fill('KOSA')
    await page.locator('input[type="password"]').first().fill('1234')
    await ss(page, '01-login-filled.png')
    const submitBtn = page.locator('button[type="submit"]')
    await submitBtn.click()
  }

  console.log('[LOGIN] Gombra kattintottam, várok dashboard URL-re...')
  await page.waitForURL('**/dashboard**', { timeout: 20000 })
  await waitNoSpinner(page)
  await ss(page, '01-dashboard.png')

  const url = page.url()
  console.log(`[LOGIN] Aktuális URL: ${url}`)
  expect(url).toContain('/dashboard')
  console.log('[LOGIN] PASS — Dashboard betöltve')
})

// ─────────────────────────────────────────────────────────────
// TEST 2: EUR VÉTEL tranzakció
// ─────────────────────────────────────────────────────────────
test('02 — EUR VÉTEL tranzakció', async ({ page }) => {
  console.log('\n=== TEST 02: EUR VÉTEL TRANZAKCIÓ ===')

  await login(page)

  // Navigálj /transactions/new
  await page.goto(BASE_URL + '/transactions/new', { waitUntil: 'domcontentloaded', timeout: 20000 })
  await waitNoSpinner(page)
  await page.waitForTimeout(1500)
  await ss(page, '02-tx-new-loaded.png')

  const url = page.url()
  console.log(`[VÉTEL] URL: ${url}`)

  // EUR deviza kiválasztó gomb
  const eurBtn = page.locator('[data-testid="currency-EUR"]')
  const eurBtnVisible = await eurBtn.isVisible({ timeout: 5000 }).catch(() => false)
  console.log(`[VÉTEL] EUR gomb látható: ${eurBtnVisible}`)

  if (eurBtnVisible) {
    await eurBtn.click()
    console.log('[VÉTEL] EUR gombra kattintottam')
    await page.waitForTimeout(500)
  } else {
    console.log('[VÉTEL] EUR gomb NEM látható, keresem alternatív selectorral...')
    const anyEur = page.locator('button:has-text("EUR")').first()
    if (await anyEur.isVisible({ timeout: 3000 }).catch(() => false)) {
      await anyEur.click()
      console.log('[VÉTEL] EUR gomb (text) megtalálva és kattintva')
    } else {
      console.log('[VÉTEL] WARN: EUR gomb nem található semmilyen formában')
    }
  }

  // VÉTEL gomb
  const buyBtn = page.locator('[data-testid="tx-type-buy"]')
  const buyBtnVisible = await buyBtn.isVisible({ timeout: 3000 }).catch(() => false)
  console.log(`[VÉTEL] VÉTEL gomb látható: ${buyBtnVisible}`)

  if (buyBtnVisible) {
    await buyBtn.click()
    console.log('[VÉTEL] VÉTEL gombra kattintottam')
    await page.waitForTimeout(500)
  } else {
    console.log('[VÉTEL] WARN: VÉTEL gomb (tx-type-buy) nem látható')
    const buyAlt = page.locator('button:has-text("VÉTEL"), button:has-text("Vétel"), button:has-text("BUY")').first()
    if (await buyAlt.isVisible({ timeout: 3000 }).catch(() => false)) {
      await buyAlt.click()
      console.log('[VÉTEL] VÉTEL gomb (text) megtalálva és kattintva')
    }
  }

  // Deviza összeg mező
  const foreignAmountField = page.locator('[data-testid="tx-foreign-amount"]')
  const foreignVisible = await foreignAmountField.isVisible({ timeout: 3000 }).catch(() => false)
  console.log(`[VÉTEL] Deviza összeg mező látható: ${foreignVisible}`)

  if (foreignVisible) {
    await foreignAmountField.click()
    await foreignAmountField.fill('100')
    console.log('[VÉTEL] 100 beírva a deviza összeg mezőbe')
    await page.waitForTimeout(1000) // kalkuláció
  } else {
    console.log('[VÉTEL] WARN: tx-foreign-amount mező nem látható')
    // try generic number input
    const numInput = page.locator('input[type="number"], input[inputmode="numeric"]').first()
    if (await numInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      await numInput.fill('100')
      console.log('[VÉTEL] Fallback number input kitöltve')
      await page.waitForTimeout(1000)
    }
  }

  // HUF összeg ellenőrzés
  const hufField = page.locator('[data-testid="tx-huf-amount"]')
  const hufVal = await hufField.inputValue().catch(() => '')
  console.log(`[VÉTEL] HUF összeg (kalkulált): "${hufVal}"`)

  await ss(page, '02-tx-buy-before-save.png')

  // Mentés gomb
  const saveBtn = page.locator('[data-testid="tx-save-print"]')
  const saveBtnVisible = await saveBtn.isVisible({ timeout: 3000 }).catch(() => false)
  console.log(`[VÉTEL] Mentés gomb látható: ${saveBtnVisible}`)

  if (saveBtnVisible) {
    await saveBtn.click()
    console.log('[VÉTEL] Mentés gombra kattintottam')
  } else {
    console.log('[VÉTEL] WARN: tx-save-print gomb nem látható')
    const saveAlt = page.locator('button:has-text("Mentés"), button:has-text("Mentés és nyomtatás"), button:has-text("Kaydet")').first()
    if (await saveAlt.isVisible({ timeout: 3000 }).catch(() => false)) {
      await saveAlt.click()
      console.log('[VÉTEL] Fallback mentés gomb kattintva')
    }
  }

  // Toast / eredmény várakozás
  await page.waitForTimeout(2500)
  await ss(page, '02-tx-buy-after-save.png')

  // Toast szöveg keresés
  const toastEl = page.locator('[role="alert"], .toast, .Toastify, [class*="toast"], [class*="notification"]').first()
  const toastVisible = await toastEl.isVisible({ timeout: 3000 }).catch(() => false)
  if (toastVisible) {
    const toastText = await toastEl.textContent().catch(() => '')
    console.log(`[VÉTEL] Toast szöveg: "${toastText}"`)
  } else {
    console.log('[VÉTEL] Toast nem látható a mentés után')
  }

  // Ellenőrzés: hiba megjelent-e
  const errorEl = page.locator('[class*="error"], [class*="Error"], [data-testid*="error"]').first()
  const errorVisible = await errorEl.isVisible({ timeout: 2000 }).catch(() => false)
  if (errorVisible) {
    const errorText = await errorEl.textContent().catch(() => '')
    console.log(`[VÉTEL] HIBAÜZENET: "${errorText}"`)
  }
})

// ─────────────────────────────────────────────────────────────
// TEST 3: EUR ELADÁS tranzakció
// ─────────────────────────────────────────────────────────────
test('03 — EUR ELADÁS tranzakció', async ({ page }) => {
  console.log('\n=== TEST 03: EUR ELADÁS TRANZAKCIÓ ===')

  await login(page)

  await page.goto(BASE_URL + '/transactions/new', { waitUntil: 'domcontentloaded', timeout: 20000 })
  await waitNoSpinner(page)
  await page.waitForTimeout(1500)

  // EUR kiválasztás
  const eurBtn = page.locator('[data-testid="currency-EUR"]')
  if (await eurBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
    await eurBtn.click()
    console.log('[ELADÁS] EUR kattintva')
    await page.waitForTimeout(500)
  } else {
    const anyEur = page.locator('button:has-text("EUR")').first()
    if (await anyEur.isVisible({ timeout: 3000 }).catch(() => false)) {
      await anyEur.click()
    }
  }

  // ELADÁS gomb
  const sellBtn = page.locator('[data-testid="tx-type-sell"]')
  if (await sellBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
    await sellBtn.click()
    console.log('[ELADÁS] ELADÁS gombra kattintottam')
    await page.waitForTimeout(500)
  } else {
    console.log('[ELADÁS] WARN: tx-type-sell nem látható')
    const sellAlt = page.locator('button:has-text("ELADÁS"), button:has-text("Eladás"), button:has-text("SELL")').first()
    if (await sellAlt.isVisible({ timeout: 3000 }).catch(() => false)) {
      await sellAlt.click()
    }
  }

  // Deviza összeg
  const foreignAmountField = page.locator('[data-testid="tx-foreign-amount"]')
  if (await foreignAmountField.isVisible({ timeout: 3000 }).catch(() => false)) {
    await foreignAmountField.click()
    await foreignAmountField.fill('100')
    console.log('[ELADÁS] 100 beírva')
    await page.waitForTimeout(1000)
  } else {
    const numInput = page.locator('input[type="number"], input[inputmode="numeric"]').first()
    if (await numInput.isVisible({ timeout: 3000 }).catch(() => false)) {
      await numInput.fill('100')
      await page.waitForTimeout(1000)
    }
  }

  const hufField = page.locator('[data-testid="tx-huf-amount"]')
  const hufVal = await hufField.inputValue().catch(() => '')
  console.log(`[ELADÁS] HUF összeg: "${hufVal}"`)

  await ss(page, '03-tx-sell-before-save.png')

  const saveBtn = page.locator('[data-testid="tx-save-print"]')
  if (await saveBtn.isVisible({ timeout: 3000 }).catch(() => false)) {
    await saveBtn.click()
    console.log('[ELADÁS] Mentés gombra kattintottam')
  } else {
    const saveAlt = page.locator('button:has-text("Mentés"), button:has-text("Mentés és nyomtatás")').first()
    if (await saveAlt.isVisible({ timeout: 3000 }).catch(() => false)) {
      await saveAlt.click()
    }
  }

  await page.waitForTimeout(2500)
  await ss(page, '03-tx-sell-after-save.png')

  const toastEl = page.locator('[role="alert"], .toast, .Toastify, [class*="toast"]').first()
  const toastVisible = await toastEl.isVisible({ timeout: 3000 }).catch(() => false)
  if (toastVisible) {
    const toastText = await toastEl.textContent().catch(() => '')
    console.log(`[ELADÁS] Toast szöveg: "${toastText}"`)
  }

  const errorEl = page.locator('[class*="error"], [class*="Error"]').first()
  const errorVisible = await errorEl.isVisible({ timeout: 2000 }).catch(() => false)
  if (errorVisible) {
    const errorText = await errorEl.textContent().catch(() => '')
    console.log(`[ELADÁS] HIBAÜZENET: "${errorText}"`)
  }
})

// ─────────────────────────────────────────────────────────────
// TEST 4: Tranzakciólista
// ─────────────────────────────────────────────────────────────
test('04 — Tranzakciólista', async ({ page }) => {
  console.log('\n=== TEST 04: TRANZAKCIÓLISTA ===')

  await login(page)

  await page.goto(BASE_URL + '/transactions', { waitUntil: 'domcontentloaded', timeout: 20000 })
  await waitNoSpinner(page)
  await page.waitForTimeout(2000)

  const url = page.url()
  console.log(`[LISTA] URL: ${url}`)

  await ss(page, '04-transaction-list.png')

  // Sorok ellenőrzése
  const rows = page.locator('table tbody tr, [class*="transaction-row"], [class*="TransactionRow"]')
  const rowCount = await rows.count().catch(() => 0)
  console.log(`[LISTA] Tranzakciós sorok száma: ${rowCount}`)

  // Általánosabb lista elem keresés
  if (rowCount === 0) {
    const listItems = page.locator('[class*="list"] li, [class*="List"] li, .list-item')
    const liCount = await listItems.count().catch(() => 0)
    console.log(`[LISTA] Lista elemek (li): ${liCount}`)
  }

  // EUR keresés az oldalon
  const eurText = page.locator('text=EUR').first()
  const eurVisible = await eurText.isVisible({ timeout: 3000 }).catch(() => false)
  console.log(`[LISTA] EUR szöveg látható: ${eurVisible}`)
})

// ─────────────────────────────────────────────────────────────
// TEST 5: Átadás-átvétel (Transfers)
// ─────────────────────────────────────────────────────────────
test('05 — Átadás-átvétel (Transfers)', async ({ page }) => {
  console.log('\n=== TEST 05: ÁTADÁS-ÁTVÉTEL ===')

  await login(page)

  await page.goto(BASE_URL + '/transfers', { waitUntil: 'domcontentloaded', timeout: 20000 })
  await waitNoSpinner(page)
  await page.waitForTimeout(2000)

  const url = page.url()
  console.log(`[TRANSFERS] URL: ${url}`)

  await ss(page, '05-transfers-page.png')

  // Tab-ok keresése
  const tabs = page.locator('[role="tab"], button:has-text("Kimenő"), button:has-text("Bejövő"), button:has-text("Függőben")')
  const tabCount = await tabs.count()
  console.log(`[TRANSFERS] Tabok száma: ${tabCount}`)

  for (let i = 0; i < Math.min(tabCount, 3); i++) {
    const tabText = await tabs.nth(i).textContent().catch(() => '')
    console.log(`[TRANSFERS] Tab ${i}: "${tabText}"`)
  }

  // "Új átadás" gomb keresése
  const newTransferBtn = page.locator('button:has-text("Új átadás"), button:has-text("Átadás"), [data-testid*="new-transfer"]').first()
  const newTransferVisible = await newTransferBtn.isVisible({ timeout: 3000 }).catch(() => false)
  console.log(`[TRANSFERS] "Új átadás" gomb látható: ${newTransferVisible}`)

  if (newTransferVisible) {
    await newTransferBtn.click()
    console.log('[TRANSFERS] "Új átadás" gombra kattintottam')
    await page.waitForTimeout(1000)
    await ss(page, '05-transfers-new-form.png')

    // Form megjelent-e
    const formVisible = await page.locator('form, [class*="form"], [class*="Form"]').first().isVisible({ timeout: 3000 }).catch(() => false)
    console.log(`[TRANSFERS] Form látható kattintás után: ${formVisible}`)
  } else {
    console.log('[TRANSFERS] WARN: "Új átadás" gomb nem látható')
    await ss(page, '05-transfers-no-new-btn.png')
  }
})

// ─────────────────────────────────────────────────────────────
// TEST 6: Sidebar menüpontok bejárása
// ─────────────────────────────────────────────────────────────
test('06 — Sidebar menüpontok bejárása', async ({ page }) => {
  console.log('\n=== TEST 06: SIDEBAR MENÜPONTOK ===')

  await login(page)

  const routes = [
    { path: '/dashboard', name: 'Irányítópult', file: '06-dashboard.png' },
    { path: '/transactions', name: 'Tranzakciólista', file: '06-transactions.png' },
    { path: '/customers', name: 'Ügyfelek', file: '06-customers.png' },
    { path: '/rates', name: 'Árfolyamok', file: '06-rates.png' },
    { path: '/cashdesk', name: 'Pénztár', file: '06-cashdesk.png' },
    { path: '/reports', name: 'Riportok', file: '06-reports.png' },
    { path: '/treasury', name: 'Értéktár', file: '06-treasury.png' },
    { path: '/transfers', name: 'Átadás-átvétel', file: '06-transfers.png' },
    { path: '/audit-log', name: 'Audit Log', file: '06-audit-log.png' },
    { path: '/settings', name: 'Beállítások', file: '06-settings.png' },
  ]

  for (const route of routes) {
    console.log(`[SIDEBAR] Navigálok: ${route.path} — ${route.name}`)
    try {
      await page.goto(BASE_URL + route.path, { waitUntil: 'domcontentloaded', timeout: 15000 })
      await waitNoSpinner(page)
      await page.waitForTimeout(1200)

      const currentUrl = page.url()
      const is404 = await page.locator('text=404, text=Nem található, text=Not Found').first().isVisible({ timeout: 2000 }).catch(() => false)

      console.log(`[SIDEBAR]   URL: ${currentUrl} | 404: ${is404}`)
      await ss(page, route.file)
    } catch (e: unknown) {
      const errMsg = e instanceof Error ? e.message : String(e)
      console.log(`[SIDEBAR]   ERROR navigáláskor: ${errMsg}`)
      await ss(page, route.file).catch(() => {})
    }
  }
})

// ─────────────────────────────────────────────────────────────
// TEST 7: Árfolyamok oldal
// ─────────────────────────────────────────────────────────────
test('07 — Árfolyamok oldal', async ({ page }) => {
  console.log('\n=== TEST 07: ÁRFOLYAMOK ===')

  await login(page)

  await page.goto(BASE_URL + '/rates', { waitUntil: 'domcontentloaded', timeout: 20000 })
  await waitNoSpinner(page)
  await page.waitForTimeout(2000)

  const url = page.url()
  console.log(`[RATES] URL: ${url}`)

  await ss(page, '07-rates-page.png')

  // Árfolyam tábla keresés
  const table = page.locator('table')
  const tableVisible = await table.first().isVisible({ timeout: 3000 }).catch(() => false)
  console.log(`[RATES] Tábla látható: ${tableVisible}`)

  if (tableVisible) {
    const rows = page.locator('table tbody tr')
    const rowCount = await rows.count().catch(() => 0)
    console.log(`[RATES] Tábla sorok száma: ${rowCount}`)
  }

  // EUR/USD/GBP keresése az oldalon
  for (const currency of ['EUR', 'USD', 'GBP', 'CHF']) {
    const el = page.locator(`text=${currency}`).first()
    const visible = await el.isVisible({ timeout: 2000 }).catch(() => false)
    console.log(`[RATES] ${currency} látható: ${visible}`)
  }

  // "Aktív" szó, deviza sor
  const activeRow = page.locator('text=aktív, text=Aktív, [class*="active"]').first()
  const activeVisible = await activeRow.isVisible({ timeout: 2000 }).catch(() => false)
  console.log(`[RATES] "Aktív" jelölés látható: ${activeVisible}`)
})
