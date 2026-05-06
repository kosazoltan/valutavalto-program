import { test, expect } from '@playwright/test'

/**
 * P2-4 Visual regression test — bizonylat (receipt) megjelenítés.
 *
 * Cél: PR-ek között a bizonylat-render NE változzon véletlen módosításoktól.
 *
 * NOTE: Ez egy SKELETON. A teljes futtatáshoz egy működő bizonylat-preview route
 * kell ami DETERMINISZTIKUS adatot mutat (pl. fix dátum, fix számok). Az éles
 * `/receipts/:id` route nem alkalmas snapshot-tesztre, mert random ID + idő.
 *
 * TODO (külön sprint): dedikált `/dev/receipt-fixture/:type` route ami egy fix
 * mock tranzakciót renderel. Most csak a snapshot-infrastruktúrát rakjuk le.
 */

const FIXTURE_TRANSACTIONS = [
  { type: 'BUY', currency: 'EUR', amount: 100, hufRate: 393, expected: 39300 },
  { type: 'SELL', currency: 'USD', amount: 200, hufRate: 370, expected: 74000 },
  { type: 'STORNO', currency: 'EUR', amount: 100, hufRate: 393, expected: -39300 },
]

test.describe('Receipt visual regression (P2-4 skeleton)', () => {
  test.skip(!process.env.PLAYWRIGHT_VISUAL_REGRESSION,
    'Set PLAYWRIGHT_VISUAL_REGRESSION=1 to run visual snapshot tests')

  for (const fixture of FIXTURE_TRANSACTIONS) {
    test(`receipt ${fixture.type} ${fixture.currency} ${fixture.amount}`, async ({ page }) => {
      // TODO: navigate to receipt preview with fixture
      // await page.goto(`/dev/receipt-fixture/${fixture.type}?currency=${fixture.currency}&amount=${fixture.amount}`)
      // await expect(page).toHaveScreenshot(`receipt-${fixture.type}-${fixture.currency}.png`, {
      //   maxDiffPixels: 100,
      // })
      test.info().annotations.push({
        type: 'todo',
        description: 'Implement /dev/receipt-fixture route + snapshot baseline',
      })
    })
  }

  test('idempotency check — same fixture renders identically', async ({ page }) => {
    test.skip(true, 'Pending /dev/receipt-fixture route')
  })
})
