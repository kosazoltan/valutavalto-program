import { expect, test, type Page } from '@playwright/test'

function createJwt(payload: Record<string, unknown>) {
  const encode = (value: Record<string, unknown>) =>
    Buffer.from(JSON.stringify(value)).toString('base64url')
  return `${encode({ alg: 'HS256', typ: 'JWT' })}.${encode(payload)}.signature`
}

const worker = {
  id: 77,
  workerCode: 'ADMIN',
  firstName: 'Admin',
  lastName: 'Teszt',
  fullName: 'Admin Teszt',
  role: 'ADMIN',
  branchId: '11111111-1111-1111-1111-111111111111',
  branchCode: 'BUD01',
  branchName: 'Budapest 01',
  companyId: 'company-1',
  companyCode: 'EBC',
  companyName: 'Exclusive Best Change',
}

async function mockApis(page: Page) {
  const token = createJwt({
    exp: Math.floor(Date.now() / 1000) + 3600,
    activeRole: 'ADMIN',
    permissions: ['RATE_READ', 'RATE_WRITE'],
    roles: ['ADMIN'],
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
          activeRole: 'ADMIN',
          permissions: ['RATE_READ', 'RATE_WRITE'],
          roles: ['ADMIN'],
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

    if (path.endsWith('/rate-management/workgroups') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'workgroup-1',
            name: 'Belvárosi csoport',
            code: 'BEL',
            legacyGroupNumber: 1,
            active: true,
          },
        ]),
      })
    }

    if (path.endsWith('/currencies') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 1, code: 'EUR', name: 'Euró' }]),
      })
    }

    if (path.endsWith('/rate-management/templates') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: 'template-1',
            currencyId: 1,
            workgroupId: 'workgroup-1',
            baseBuyRate: '390.00',
            baseSellRate: '399.00',
            buySpread: '1.00',
            sellSpread: '1.00',
            officialRate: '394.00',
            limit1Amount: '100000',
            limit1BuyRate: '391.00',
            limit1SellRate: '400.00',
            limit2Amount: '500000',
            limit2BuyRate: '392.00',
            limit2SellRate: '401.00',
            limit3Amount: '1000000',
            limit3BuyRate: '393.00',
            limit3SellRate: '402.00',
            roundingRule: 5,
            status: 'DRAFT',
          },
        ]),
      })
    }

    if (path.endsWith('/rate-management/publish') && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'publication-1',
          workgroupId: 'workgroup-1',
          affectedBranches: 1,
        }),
      })
    }

    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) })
  })
}

async function login(page: Page) {
  await page.goto('/login')
  const textboxes = page.getByRole('textbox')
  await textboxes.nth(0).fill('EBC')
  await textboxes.nth(1).fill('ADMIN')
  await page.locator('input[type="password"]').fill('1234')
  await page.getByRole('button', { name: /Bejelentkezés/i }).click()
  await expect(page).toHaveURL(/\/central-workstation$/)
}

test('rate-management sablonok tab batch publish backend szerződésre köt mobil viewporton', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/rate-management', { waitUntil: 'domcontentloaded' })
  await page.getByRole('button', { name: 'Sablonok' }).click()
  await expect(page.getByText(/Vétel: 390\.00/)).toBeVisible()
  await page.getByLabel('Publikálási megjegyzés').fill('Mobil batch publikálás')

  const publishRequest = page.waitForRequest(
    (request) => request.method() === 'POST' && request.url().includes('/rate-management/publish'),
  )
  await page.getByTestId('rate-management-publish-batch').click()
  await publishRequest

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})

test('/rates/groups a valós rate-management munkacsoport UI-t rendereli mobil viewporton', async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 })
  await mockApis(page)
  await login(page)

  await page.goto('/rates/groups', { waitUntil: 'domcontentloaded' })
  await expect(page.getByRole('button', { name: 'Munkacsoportok' })).toBeVisible()
  await expect(page.getByText('Belvárosi csoport')).toBeVisible()
  await expect(page.getByText(/nincs azonos szerződésű backend/i)).toHaveCount(0)

  const horizontalOverflow = await page.evaluate(
    () => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
  )
  expect(horizontalOverflow).toBe(false)
})
