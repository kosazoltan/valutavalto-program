const { _electron: electron } = require('playwright')
const path = require('path')
const MAIN_JS = path.join('D:\\repo\\valutavalto-program\\penztar-client\\dist-electron', 'main.js')
;(async () => {
  const app = await electron.launch({
    args: [MAIN_JS, '--force-packaged'],
    env: { ...process.env, ELECTRON_FORCE_PACKAGED: '1', ELECTRON_DEV_USER_DATA: 'D:\\repo\\valutavalto-program\\penztar-client\\.e2e-test7' }
  })
  
  const page = await app.firstWindow()
  page.on('pageerror', err => console.log('[PAGE ERROR]', err.message))
  page.on('requestfailed', req => console.log('[REQ FAIL]', req.url(), req.failure()?.errorText))
  
  await new Promise(r => setTimeout(r, 8000))
  console.log('URL:', page.url())
  const rootHTML = await page.evaluate(() => document.getElementById('root')?.innerHTML?.substring(0, 500) ?? 'NO ROOT')
  console.log('ROOT:', rootHTML)
  await page.screenshot({ path: 'test-production.png' })
  await app.close()
})()