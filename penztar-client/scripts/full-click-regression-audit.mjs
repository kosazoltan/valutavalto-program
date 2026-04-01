import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';

const BASE_URL = 'http://127.0.0.1:3000';
const artifactsDir = path.resolve('playwright-artifacts');
fs.mkdirSync(artifactsDir, { recursive: true });

const issues = [];
const visited = [];
const actions = [];
const AUTH_BUTTON_RE = /(kijelentkez|logout|bejelentkez|login)/i;

function issue(type, message, extra = {}) {
  issues.push({ type, message, ...extra });
}

function safeText(v) {
  return (v || '').replace(/\s+/g, ' ').trim();
}

async function closeCommonDialogs(page) {
  const closeTexts = ['Mégse', 'Bezár', 'Cancel', 'Close', 'Rendben', 'OK'];
  for (const text of closeTexts) {
    const loc = page.getByRole('button', { name: text }).first();
    if (await loc.isVisible().catch(() => false)) {
      await loc.click({ timeout: 1200 }).catch(() => {});
      await page.waitForTimeout(150);
    }
  }
  await page.keyboard.press('Escape').catch(() => {});
}

async function clickVisibleButtons(page, route) {
  const handles = await page.$$('main button, main [role="button"]');
  for (let i = 0; i < handles.length; i += 1) {
    const h = handles[i];
    const visible = await h.isVisible().catch(() => false);
    if (!visible) continue;

    const disabled = await h.evaluate((el) => {
      const e = el;
      return e.hasAttribute('disabled') || e.getAttribute('aria-disabled') === 'true';
    }).catch(() => true);
    if (disabled) continue;

    const label = safeText(await h.innerText().catch(() => '')) || `button#${i}`;
    if (AUTH_BUTTON_RE.test(label)) continue;
    actions.push({ route, action: label, ts: new Date().toISOString() });
    await h.click({ timeout: 1500 }).catch(() => {});
    await page.waitForTimeout(250);
    await closeCommonDialogs(page);
  }
}

async function ensureLoggedIn(page) {
  if (!page.url().includes('/login')) return;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    const inputs = page.locator('input');
    await inputs.nth(0).fill('EBC');
    await inputs.nth(1).fill('KOSA');
    await inputs.nth(2).fill('1234');
    const loginBtn = page.getByRole('button', { name: 'Bejelentkezés' });
    const enabled = await loginBtn.isEnabled().catch(() => false);
    if (enabled) {
      await loginBtn.click().catch(() => {});
    } else {
      await inputs.nth(2).press('Enter').catch(() => {});
    }
    await page.waitForTimeout(1600);
    if (!page.url().includes('/login')) return;
    await page.waitForTimeout(1500);
  }
  issue('login-failed', `Could not login, current URL: ${page.url()}`);
}

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext();
const page = await context.newPage();

page.on('pageerror', (err) => issue('pageerror', err.message));
page.on('console', (msg) => {
  if (msg.type() === 'error') issue('console-error', msg.text());
});
page.on('response', (res) => {
  const url = res.url();
  if (!url.includes('/api/')) return;
  const status = res.status();
  if (status >= 400) issue('api-error', `${status} ${url}`, { status, url });
});

await page.goto(BASE_URL, { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(700);
await ensureLoggedIn(page);

const links = await page.$$eval('a[href]', (as) =>
  as
    .map((a) => a.getAttribute('href') || '')
    .filter((href) => href.startsWith('/'))
);
const uniqueRoutes = Array.from(new Set(links))
  .filter((r) => !r.startsWith('/login'))
  .slice(0, 40);

for (const route of uniqueRoutes) {
  await page.goto(`${BASE_URL}${route}`, { waitUntil: 'domcontentloaded' }).catch((err) => {
    issue('navigation-error', `${route}: ${String(err)}`);
  });
  await page.waitForTimeout(700);
  await ensureLoggedIn(page);
  if (page.url().includes('/login')) continue;

  const body = safeText(await page.textContent('body').catch(() => ''));
  if (!body.length) {
    issue('blank-page', route);
  }
  if (body.toLowerCase().includes('request failed')) {
    issue('ui-error', `Request failed visible on ${route}`);
  }

  visited.push({ route, url: page.url(), bodyLen: body.length });
  await clickVisibleButtons(page, route);
  await page.screenshot({
    path: path.join(artifactsDir, `full-audit-${route.replaceAll('/', '_') || 'root'}.png`),
    fullPage: true,
  });
}

await browser.close();

const report = {
  createdAt: new Date().toISOString(),
  baseUrl: BASE_URL,
  visited,
  actionsCount: actions.length,
  issues,
};
const reportPath = path.join(artifactsDir, 'full-click-regression-report.json');
fs.writeFileSync(reportPath, `${JSON.stringify(report, null, 2)}\n`, 'utf8');

console.log(`REPORT_JSON=${reportPath}`);
console.log(`VISITED=${visited.length}`);
console.log(`ACTIONS=${actions.length}`);
console.log(`ISSUES=${issues.length}`);
