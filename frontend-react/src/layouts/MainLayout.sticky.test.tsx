import { describe, it, expect } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

/**
 * FK-033 strukturális kontraktus-teszt a MainLayout flex-lánc görgető kontextusára.
 *
 * Gyökérok (2026-06-16, preview-ban reprodukálva): a flex-item alapértelmezett `min-width: auto`
 * miatt a <main> a széles tartalom (Átlag árfolyam riport táblázata) szélességére TÁGUL, és a body
 * görget vízszintesen a `.app-print-content` helyett → a sticky VALUTA oszlop elcsúszik (a #1197
 * 177-es overflow-eltávolítás önmagában nem volt elég). A `min-w-0` a flex-láncon teszi a
 * `.app-print-content` (overflow-auto) elemet az EGYETLEN vízszintes+függőleges scroll-containerré.
 *
 * Ez a teszt a forrást olvassa (a teljes MainLayout renderelése session-API-t igényel, lásd
 * MainLayout.menu.test.tsx), és rögzíti a két kötelező osztályt, hogy a regresszió ne térhessen vissza.
 */
const src = readFileSync(resolve(process.cwd(), 'src/layouts/MainLayout.tsx'), 'utf-8')

describe('MainLayout — FK-033 sticky scroll-container (flex min-w-0)', () => {
  it('a <main> flex-item min-w-0-t kap (különben a széles táblázat a body-t görgetné, a sticky elcsúszna)', () => {
    expect(src).toMatch(/<main className="flex-1 flex flex-col min-w-0"/)
  })

  it('a .app-print-content (az egyetlen görgető kontextus) overflow-auto + min-h-0 + min-w-0', () => {
    const m = src.match(/className="(app-print-content[^"]*)"/)
    expect(m).toBeTruthy()
    const cls = m![1]
    expect(cls).toContain('overflow-auto')
    expect(cls).toContain('min-h-0')
    expect(cls).toContain('min-w-0')
  })
})
