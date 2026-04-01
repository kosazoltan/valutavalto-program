import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';

const BASE_URL = 'http://127.0.0.1:3000';
const ROUTES = [
  '/dashboard',
  '/transactions',
  '/rates/creation',
  '/cashdesk',
  '/reports',
];

const artifactsDir = path.resolve('playwright-artifacts');
fs.mkdirSync(artifactsDir, { recursive: true });

const issues = [];
const routeResults = [];

function pushIssue(type, message, extra = {}) {
  issues.push({ type, message, ...extra });
}

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext();
const page = await context.newPage();

page.on('pageerror', (err) => {
  pushIssue('pageerror', err.message);
});

page.on('console', (msg) => {
  if (msg.type() === 'error') {
    pushIssue('console-error', msg.text());
  }
});

page.on('response', (res) => {
  const url = res.url();
  if (!url.includes('/api/')) return;
  if (res.status() >= 400) {
    pushIssue('api-error', `${res.status()} ${url}`);
  }
});

await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(800);

const inputs = page.locator('input');
await inputs.nth(0).fill('EBC');
await inputs.nth(1).fill('KOSA');
await inputs.nth(2).fill('1234');
await page.getByRole('button', { name: 'Bejelentkezés' }).click();
await page.waitForTimeout(1800);

const afterLoginUrl = page.url();
if (afterLoginUrl.includes('/login')) {
  pushIssue('login-failed', `Still on login page: ${afterLoginUrl}`);
}

for (const route of ROUTES) {
  const url = `${BASE_URL}${route}`;
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(1000);
  const bodyText = ((await page.textContent('body')) || '').replace(/\s+/g, ' ').trim();
  const screenshotPath = path.join(artifactsDir, `kosa-${route.replaceAll('/', '_') || 'root'}.png`);
  await page.screenshot({ path: screenshotPath, fullPage: true });

  const result = {
    route,
    url: page.url(),
    bodyLen: bodyText.length,
    hasErrorBoundary: bodyText.toLowerCase().includes('hiba'),
  };
  routeResults.push(result);

  if (bodyText.length === 0) {
    pushIssue('blank-page', `Empty body on route ${route}`);
  }
}

await browser.close();

const report = {
  createdAt: new Date().toISOString(),
  baseUrl: BASE_URL,
  routes: routeResults,
  issues,
};

const jsonPath = path.join(artifactsDir, 'kosa-playwright-report.json');
fs.writeFileSync(jsonPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');

console.log(`REPORT_JSON=${jsonPath}`);
console.log(`ISSUE_COUNT=${issues.length}`);
for (const issue of issues) {
  console.log(`[${issue.type}] ${issue.message}`);
}
