import { describe, it, expect } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { menuGroups } from './menuGroups'

/**
 * FK-069 — Navigációs menü csoportonkénti összecsukása.
 *
 * A teljes MainLayout renderelése session-API-t igényel (lásd MainLayout.menu.test.tsx),
 * ezért a UI-kontraktust — a MainLayout.sticky/vertical-scroll tesztek bevált mintája
 * szerint — forrásból ellenőrizzük, a toggle-szemantikát pedig a BranchGroupPage-ből
 * átvett Set-mintán, izoláltan.
 */
const src = readFileSync(resolve(process.cwd(), 'src/layouts/MainLayout.tsx'), 'utf-8')

/** A MainLayout-ban implementált toggle szemantikájának izolált mása (FR-1). */
function toggle(prev: Set<string>, label: string): Set<string> {
  const next = new Set(prev)
  if (next.has(label)) next.delete(label)
  else next.add(label)
  return next
}

describe('FK-069 FR-4 — alapértelmezett állapot: minden csoport nyitva', () => {
  it('a kezdőérték az összes definiált menücsoport label-je', () => {
    const initial = new Set(menuGroups.map((g) => g.label))
    expect(initial.size).toBe(new Set(menuGroups.map((g) => g.label)).size)
    for (const g of menuGroups) {
      expect(initial.has(g.label)).toBe(true)
    }
  })

  it('a forrás az összes csoport-labellel inicializálja a nyitott halmazt', () => {
    expect(src).toMatch(
      /useState<Set<string>>\(\s*\(\) => new Set\(menuGroups\.map\(\(g\) => g\.label\)\)/,
    )
  })
})

describe('FK-069 FR-1 — fejléc kattintásra állapotot vált', () => {
  it('nyitott → csukott → nyitott', () => {
    const label = menuGroups[0]!.label
    let state = new Set(menuGroups.map((g) => g.label))
    expect(state.has(label)).toBe(true)
    state = toggle(state, label)
    expect(state.has(label)).toBe(false)
    state = toggle(state, label)
    expect(state.has(label)).toBe(true)
  })

  it('egy csoport csukása a többi csoport állapotát nem érinti', () => {
    const [first, second] = menuGroups
    const state = toggle(new Set(menuGroups.map((g) => g.label)), first!.label)
    expect(state.has(first!.label)).toBe(false)
    expect(state.has(second!.label)).toBe(true)
  })

  it('a fejléc kattintható <button>, ami a toggleMenuGroup-ot hívja', () => {
    expect(src).toMatch(/onClick=\{\(\) => toggleMenuGroup\(group\.label\)\}/)
    expect(src).toMatch(/aria-expanded=\{openMenuGroups\.has\(group\.label\)\}/)
  })
})

describe('FK-069 FR-2 — csukott állapotban az itemek nem renderelődnek', () => {
  it('az items-blokk feltételhez kötött', () => {
    expect(src).toMatch(
      /\(!sidebarOpen \|\| openMenuGroups\.has\(group\.label\)\) &&\s*group\.items/,
    )
  })
})

describe('FK-069 FR-3 — chevron mutatja az állapotot', () => {
  it('ChevronRight importálva és rotate-90-nel forgatva nyitott állapotban', () => {
    expect(src).toContain('ChevronRight')
    expect(src).toMatch(/openMenuGroups\.has\(group\.label\) \? 'rotate-90' : ''/)
  })
})

describe('FK-069 FR-5 / NFR-2 — RBAC szűrés és FK-057 kontraktus érintetlen', () => {
  it('a csoport- és item-szűrés változatlanul a menuVisibility helpereket hívja', () => {
    expect(src).toMatch(/\.filter\(\(group\) => isMenuGroupVisible\(group, menuVisibilityCtx\)\)/)
    expect(src).toMatch(
      /\.filter\(\(item\) => isMenuItemVisible\(item, group, menuVisibilityCtx\)\)/,
    )
  })

  it('a <nav> és <main> class-stringje változatlan (FK-057)', () => {
    expect(src).toMatch(
      /<nav\s+className=\{`\$\{sidebarOpen \? 'block' : 'hidden md:block'\} flex-1 min-h-0 py-2 overflow-y-auto`\}/,
    )
    expect(src).toMatch(/<main className="flex-1 flex flex-col min-w-0"/)
  })

  it('nincs perzisztálás (localStorage/sessionStorage) a menü-állapotra (§2 OUT)', () => {
    expect(src).not.toMatch(/(local|session)Storage[^\n]*(openMenuGroups|menuGroup)/i)
  })
})
