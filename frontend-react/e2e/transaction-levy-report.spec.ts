import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 77,
  workerCode: 'FOERTEKTAR',
  firstName: 'Főértéktáros',
  lastName: 'Teszt',
  fullName: 'Főértéktáros Teszt',
  role: 'FOERTEKTAR',
  branchId: 'branch-123',
  branchCode: 'SZEGED',
  branchName: 'Szeged Iroda',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

const zeroGroup = {
  normalBaseLevy: 0,
  normalSupplementLevy: 0,
  aboveThresholdCount: 0,
  aboveThresholdBaseLevy: 0,
  aboveThresholdSupplementLevy: 0,
}

// One non-empty report row is REQUIRED: the monthly panel only renders when
// report.rows.length > 0 (TransactionLevyReportPage.tsx :172). The 10-digit
// HUF values make the numeric columns as wide as the widest real-world cell.
function buildLevyReport() {
  return {
    from: '2026-08-01',
    to: '2026-08-31',
    appliedRates: [],
    rows: [
      {
        date: '2026-08-03',
        branchId: 'b1',
        branchCode: '001',
        branchName: 'Fő utca',
        buy: { ...zeroGroup, normalBaseLevy: 13500, normalSupplementLevy: 13500 },
        sell: { ...zeroGroup },
        conversion: { ...zeroGroup },
        largeBaseHuf: 0,
        levyTotal: 27000,
      },
    ],
    totals: {
      date: null,
      branchId: null,
      branchCode: null,
      branchName: null,
      buy: { ...zeroGroup, normalBaseLevy: 13500, normalSupplementLevy: 13500 },
      sell: { ...zeroGroup },
      conversion: { ...zeroGroup },
      largeBaseHuf: 0,
      levyTotal: 27000,
    },
    monthlySummary: {
      buyCount: 12345,
      sellCount: 6789,
      customerCount: 9876,
      belowThresholdBuyHuf: 1234567890,
      belowThresholdSellHuf: 1234567890,
      aboveThresholdBuyHuf: 1234567890,
      aboveThresholdSellHuf: 1234567890,
      belowThresholdTotalHuf: 1234567890,
      aboveThresholdTotalHuf: 1234567890,
      totalCount: 19134,
    },
  }
}

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'FOERTEKTAR',
    permissions: ['READ'],
    roles: ['FOERTEKTAR'],
  })

  await page.route('**/api/v1/**', async (route) => {
    const url = new URL(route.request().url())
    const path = url.pathname
    const method = route.request().method()

    if (path.endsWith('/auth/login') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          token,
          tokenType: 'Bearer',
          expiresAt: new Date(Date.now() + 3600_000).toISOString(),
          worker,
          activeRole: 'FOERTEKTAR',
          permissions: ['READ'],
          roles: ['FOERTEKTAR'],
          roleSelectionRequired: false,
        }),
      })
    }

    if (path.endsWith('/auth/refresh-cookie') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ token }),
      })
    }

    if (path.endsWith('/workers/me') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(worker),
      })
    }

    if (
      path.endsWith('/branches') &&
      method === 'GET' &&
      url.searchParams.get('activeOnly') === 'true'
    ) {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'branch-123', code: 'SZEGED', name: 'Szeged Iroda', active: true, isVault: false },
        ]),
      })
    }

    if (path.endsWith('/dictionaries/REGION') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          { id: 'd1', category: 'REGION', code: 'SZEGED', name: 'Szeged', nameHu: 'Szeged', sortOrder: 1 },
        ]),
      })
    }

    if (path.endsWith('/reports/transaction-levy') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(buildLevyReport()),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) })
  })
}

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('FOERTEKTAR')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await expect(page).toHaveURL(/\/central-workstation$/)
}

test('FK-103/FK-104: a havi 3x3 panel 375px-nél vízszintesen görgethető, cellatörés nélkül', async ({
  page,
}) => {
  await page.setViewportSize({ width: 375, height: 800 })
  await mockApis(page)
  await login(page)

  await page.goto('/reports/transaction-levy', { waitUntil: 'domcontentloaded' })
  await expect(page.getByText('Havi összesítő')).toBeVisible()

  // E1 (FK-103 FR-1): the LAST overflow-x-auto wrapper inside the page
  // sections is the monthly panel's own scroll container; it must overflow
  // horizontally at a 375px viewport (scrollWidth > clientWidth).
  const { sw, cw } = await page.evaluate(() => {
    const w = [...document.querySelectorAll('section .overflow-x-auto')].at(-1)!
    return { sw: w.scrollWidth, cw: w.clientWidth }
  })
  expect(sw, `monthly wrapper scrollWidth ${sw} vs clientWidth ${cw}`).toBeGreaterThan(cw)

  // E2 (FK-103 FR-2): no cell of the monthly table wraps — a cell is
  // single-line iff offsetHeight <= lineHeight + paddings + borders + 1.
  const cells = await page.evaluate(() => {
    const panel = [...document.querySelectorAll('section')].find((s) =>
      s.textContent?.includes('Havi összesítő'),
    )!
    const table = panel.querySelector('table')!
    return [...table.querySelectorAll('th, td')].map((cell) => {
      const style = getComputedStyle(cell)
      const slack =
        cell.offsetHeight -
        (parseFloat(style.lineHeight) +
          parseFloat(style.paddingTop) +
          parseFloat(style.paddingBottom) +
          parseFloat(style.borderTopWidth) +
          parseFloat(style.borderBottomWidth))
      return { tag: cell.tagName, text: (cell.textContent ?? '').trim(), slack }
    })
  })
  for (const cell of cells) {
    expect(
      cell.slack,
      `cell wrapped: <${cell.tag}> "${cell.text}" slack=${cell.slack}`,
    ).toBeLessThanOrEqual(1)
  }

  // E3: the overflow stays inside the container — no page-level horizontal
  // scroll (same guard as average-rate-sticky.spec.ts).
  const pageOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(pageOverflow).toBe(false)
})
