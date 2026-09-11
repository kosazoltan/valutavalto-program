import { describe, it, expect } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { menuGroups } from './menuGroups'
import {
  isMenuGroupVisible,
  isMenuItemVisible,
  resolveVisibleMenuGroups,
  type MenuVisibilityContext,
} from './menuVisibility'
import type { AppMode } from '../types/appMode'

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
  // #1744: this used to regex-match the SOURCE TEXT of MainLayout.tsx
  // (`.filter((group) => isMenuGroupVisible(group, menuVisibilityCtx))`). When the
  // kanban #8 zero-visible fallback moved filtering into `resolveVisibleMenuGroups`,
  // the regex broke WHILE the guarded guarantee stayed intact - the test was pinning
  // the shape of the implementation, not its behaviour. The cases below assert the
  // actual RBAC outcome, so they survive the next refactor too.
  const ctxFor = (canonicalRoles: string[], appMode: AppMode = 'full'): MenuVisibilityContext => ({
    appMode,
    hasCanonicalRole: (role: string) => canonicalRoles.includes(role),
    hasRole: () => true,
    featureFlags: {},
  })

  /** Item paths the layout would actually render for this context. */
  const renderedPaths = (ctx: MenuVisibilityContext): string[] => {
    const { groups, fallbackApplied } = resolveVisibleMenuGroups(menuGroups, ctx)
    return groups.flatMap((group) =>
      group.items
        .filter((item) => (fallbackApplied ? true : isMenuItemVisible(item, group, ctx)))
        .map((item) => item.path),
    )
  }

  it('a csoport-szűrés a menuVisibility szabályait érvényesíti (jogosulatlan szerep → nincs csoport)', () => {
    const { groups, fallbackApplied } = resolveVisibleMenuGroups(menuGroups, ctxFor([]))

    // In `full` mode there is no fallback (FALLBACK_GROUP_LABEL_BY_MODE omits it on
    // purpose), so a user without roles sees no group at all.
    expect(fallbackApplied).toBe(false)
    expect(groups).toEqual([])
  })

  it('minden visszaadott csoport és item átmegy az isMenuGroupVisible / isMenuItemVisible szűrőn', () => {
    const ctx = ctxFor(['foertektar'])
    const { groups, fallbackApplied } = resolveVisibleMenuGroups(menuGroups, ctx)

    expect(fallbackApplied).toBe(false)
    expect(groups.length).toBeGreaterThan(0)
    for (const group of groups) {
      expect(isMenuGroupVisible(group, ctx)).toBe(true)
      // MainLayout filters items with this very predicate when fallbackApplied === false.
      const visibleItems = group.items.filter((item) => isMenuItemVisible(item, group, ctx))
      expect(visibleItems.length).toBeGreaterThan(0)
    }
  })

  it('a szűkebb szerep szigorúan kevesebb csoportot lát, mint a felügyeleti (least-privilege)', () => {
    const supervisory = resolveVisibleMenuGroups(menuGroups, ctxFor(['foertektar'])).groups
    const narrow = resolveVisibleMenuGroups(menuGroups, ctxFor(['arfolyam_nezo'])).groups

    expect(narrow.length).toBeLessThan(supervisory.length)
  })

  it('a rejtett (hidden) bejegyzés nem jelenik meg a központi felület navigációjában', () => {
    // Fixture guard: without at least one `hidden` entry this would be vacuously true.
    const hiddenEntries = menuGroups.flatMap((group) =>
      group.items.filter((item) => item.hidden).map((item) => ({ group, item })),
    )
    expect(hiddenEntries.length).toBeGreaterThan(0)

    const paths = renderedPaths(ctxFor(['foertektar']))
    expect(paths.length).toBeGreaterThan(0)
    for (const { item } of hiddenEntries) {
      expect(paths).not.toContain(item.path)
    }
  })

  it('a hidden flag lokál módban is elrejt: szerepkör-alapú (nem felügyeleti) user nem látja', () => {
    // The `full`-mode case above cannot isolate the `hidden` rule, because every hidden
    // entry currently lives in a penztar/ertektar-scoped group that `full` excludes by
    // mode anyway. Here mode and roles both PERMIT the entry, so visibility is decided by
    // `hidden` alone - the assertion fails if that rule is dropped.
    const localCtx: MenuVisibilityContext = {
      appMode: 'ertektar',
      hasCanonicalRole: (role: string) => role === 'ertektar',
      hasRole: () => true,
      featureFlags: {},
    }
    const hiddenInMode = menuGroups
      .filter((group) => !group.modes || group.modes.includes('ertektar'))
      .flatMap((group) =>
        group.items.filter((item) => item.hidden).map((item) => ({ group, item })),
      )
    expect(hiddenInMode.length).toBeGreaterThan(0)

    for (const { group, item } of hiddenInMode) {
      expect({ path: item.path, visible: isMenuItemVisible(item, group, localCtx) }).toEqual({
        path: item.path,
        visible: false,
      })
    }
  })

  it('lokál módban a felügyeleti bypass MEGMUTATJA a rejtett bejegyzést (a fenti teszt nem vacuous)', () => {
    // Counter-case proving the previous test measures the `hidden` rule and not some
    // unrelated exclusion: with a supervisory role the very same entries become visible.
    const supervisoryCtx = ctxFor(['foertektar'], 'ertektar')
    const hiddenInMode = menuGroups
      .filter((group) => !group.modes || group.modes.includes('ertektar'))
      .flatMap((group) =>
        group.items.filter((item) => item.hidden).map((item) => ({ group, item })),
      )

    const visibleUnderBypass = hiddenInMode.filter(({ group, item }) =>
      isMenuItemVisible(item, group, supervisoryCtx),
    )
    expect(visibleUnderBypass.length).toBe(hiddenInMode.length)
  })

  it('a MainLayout a szűrt csoportokat rendereli, nem a nyers menuGroups-t', () => {
    // Contract anchor: the layout must ITERATE the resolved list. A weaker "the
    // identifier appears somewhere" check would still pass if the map switched back to
    // menuGroups, so the call site itself is pinned.
    expect(src).toMatch(/resolveVisibleMenuGroups\(/)
    expect(src).toMatch(/resolvedGroups\.map\(/)
    expect(src).not.toMatch(/menuGroups\.map\(\(group\)/)
    expect(src).toMatch(/isMenuItemVisible\(item, group, menuVisibilityCtx\)/)
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
