import { describe, it, expect } from 'vitest'

/**
 * Menüszűrés logika tesztek — MainLayout menuGroups és modes property alapján.
 * 
 * A menuGroups definícióból és a szűrő logikából kiemelt, izolált unit tesztek.
 * Nem rendereli a teljes MainLayout-ot (session API stb.), csak a szűrési logikát teszteli.
 */

// --- A menuGroups struktúra reprodukálása a MainLayout-ból ---
interface MenuItem {
  path: string
  label: string
  modes?: readonly string[]
}

interface MenuGroup {
  label: string
  modes?: readonly string[]
  items: MenuItem[]
}

const menuGroups: MenuGroup[] = [
  {
    label: 'Főoldal',
    items: [
      { path: '/dashboard', label: 'Irányítópult' },
      { path: '/cashier', label: 'Pénztáros műveletek', modes: ['penztar', 'ertektar'] },
    ]
  },
  {
    label: 'Tranzakciók',
    modes: ['penztar', 'ertektar'],
    items: [
      { path: '/transactions/new', label: 'Új tranzakció' },
      { path: '/transactions', label: 'Tranzakciólista' },
    ]
  },
  {
    label: 'Ügyfelek & Árfolyamok',
    items: [
      { path: '/customers', label: 'Ügyfelek' },
      { path: '/rates', label: 'Árfolyamok' },
      { path: '/rates/creation', label: 'Árfolyam készítés' },
    ]
  },
  {
    label: 'Pénztár & Riportok',
    modes: ['penztar', 'ertektar'],
    items: [
      { path: '/cashdesk', label: 'Pénztár' },
      { path: '/reports', label: 'Riportok' },
    ]
  },
  {
    label: 'Értéktár',
    items: [
      { path: '/treasury', label: 'Értéktári Dashboard' },
    ]
  },
  {
    label: 'Kamera',
    modes: ['penztar', 'ertektar'],
    items: [
      { path: '/camera/live', label: 'Élő kép' },
      { path: '/camera/playback', label: 'Visszajátszás' },
      { path: '/camera/export', label: 'Export & Custody' },
      { path: '/camera/status', label: 'Állapot' },
    ]
  },
  {
    label: 'Adminisztráció',
    items: [
      { path: '/audit-log', label: 'Audit Log' },
      { path: '/local-queue', label: 'Helyi Queue' },
      { path: '/settings', label: 'Rendszer beállítások' },
    ]
  }
]

// --- A szűrő logika — pontosan a MainLayout-ban használt pattern ---
function filterMenuGroups(groups: MenuGroup[], appMode: string): MenuGroup[] {
  return groups
    .filter((group) => !('modes' in group) || (group.modes as readonly string[]).includes(appMode))
    .map((group) => ({
      ...group,
      items: group.items.filter((item) => !('modes' in item) || (item.modes as readonly string[]).includes(appMode)),
    }))
    .filter((group) => group.items.length > 0)
}

function getVisibleLabels(groups: MenuGroup[], appMode: string): string[] {
  return filterMenuGroups(groups, appMode).flatMap((g) => [g.label, ...g.items.map((i) => i.label)])
}

function getVisibleGroupLabels(groups: MenuGroup[], appMode: string): string[] {
  return filterMenuGroups(groups, appMode).map((g) => g.label)
}

function getVisibleItemLabels(groups: MenuGroup[], appMode: string): string[] {
  return filterMenuGroups(groups, appMode).flatMap((g) => g.items.map((i) => i.label))
}

// ==========================================================
// Full mód (szerver) — korlátozások
// ==========================================================
describe('Menü szűrés — full mód (szerver)', () => {
  const mode = 'full'

  it('Tranzakciók szekció NEM jelenik meg', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).not.toContain('Tranzakciók')
  })

  it('Pénztár & Riportok szekció NEM jelenik meg', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).not.toContain('Pénztár & Riportok')
  })

  it('Kamera szekció NEM jelenik meg', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).not.toContain('Kamera')
  })

  it('Pénztáros műveletek menüpont NEM jelenik meg', () => {
    const items = getVisibleItemLabels(menuGroups, mode)
    expect(items).not.toContain('Pénztáros műveletek')
  })

  it('Irányítópult megjelenik', () => {
    const items = getVisibleItemLabels(menuGroups, mode)
    expect(items).toContain('Irányítópult')
  })

  it('Ügyfelek & Árfolyamok szekció megjelenik', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).toContain('Ügyfelek & Árfolyamok')
  })

  it('Értéktár szekció megjelenik', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).toContain('Értéktár')
  })

  it('Adminisztráció szekció megjelenik', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).toContain('Adminisztráció')
  })

  it('Árfolyam készítés megjelenik full módban', () => {
    const items = getVisibleItemLabels(menuGroups, mode)
    expect(items).toContain('Árfolyam készítés')
  })

  it('Összesen 4 szekció látható full módban', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).toEqual(['Főoldal', 'Ügyfelek & Árfolyamok', 'Értéktár', 'Adminisztráció'])
  })

  it('Összesített rejtett elemek: Tranzakciók, Pénztár & Riportok, Kamera, Pénztáros műveletek', () => {
    const allLabels = getVisibleLabels(menuGroups, mode)
    const shouldBeHidden = [
      'Tranzakciók', 'Új tranzakció', 'Tranzakciólista',
      'Pénztár & Riportok', 'Pénztár', 'Riportok',
      'Kamera', 'Élő kép', 'Visszajátszás', 'Export & Custody', 'Állapot',
      'Pénztáros műveletek',
    ]
    for (const label of shouldBeHidden) {
      expect(allLabels).not.toContain(label)
    }
  })
})

// ==========================================================
// Pénztár mód — minden látható
// ==========================================================
describe('Menü szűrés — penztar mód', () => {
  const mode = 'penztar'

  it('Összes szekció megjelenik', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).toEqual([
      'Főoldal', 'Tranzakciók', 'Ügyfelek & Árfolyamok',
      'Pénztár & Riportok', 'Értéktár', 'Kamera', 'Adminisztráció'
    ])
  })

  it('Pénztáros műveletek menüpont megjelenik', () => {
    const items = getVisibleItemLabels(menuGroups, mode)
    expect(items).toContain('Pénztáros műveletek')
  })

  it('Tranzakciók szekció megjelenik', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).toContain('Tranzakciók')
  })

  it('Kamera szekció megjelenik', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).toContain('Kamera')
  })

  it('Mind a 4 kamera menüpont megjelenik', () => {
    const items = getVisibleItemLabels(menuGroups, mode)
    expect(items).toContain('Élő kép')
    expect(items).toContain('Visszajátszás')
    expect(items).toContain('Export & Custody')
    expect(items).toContain('Állapot')
  })
})

// ==========================================================
// Értéktár mód — minden látható (megegyezik pénztárral)
// ==========================================================
describe('Menü szűrés — ertektar mód', () => {
  const mode = 'ertektar'

  it('Összes szekció megjelenik', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).toEqual([
      'Főoldal', 'Tranzakciók', 'Ügyfelek & Árfolyamok',
      'Pénztár & Riportok', 'Értéktár', 'Kamera', 'Adminisztráció'
    ])
  })

  it('Pénztáros műveletek megjelenik', () => {
    const items = getVisibleItemLabels(menuGroups, mode)
    expect(items).toContain('Pénztáros műveletek')
  })
})

// ==========================================================
// Ismeretlen mód — csak modes nélküli elemek
// ==========================================================
describe('Menü szűrés — ismeretlen mód', () => {
  const mode = 'unknown_mode'

  it('Csak modes nélküli szekciók jelennek meg', () => {
    const groups = getVisibleGroupLabels(menuGroups, mode)
    expect(groups).toEqual(['Főoldal', 'Ügyfelek & Árfolyamok', 'Értéktár', 'Adminisztráció'])
  })

  it('Pénztáros műveletek rejtett', () => {
    const items = getVisibleItemLabels(menuGroups, mode)
    expect(items).not.toContain('Pénztáros műveletek')
  })
})

// ==========================================================
// Szűrési logika edge case-ek
// ==========================================================
describe('Menü szűrés — edge case-ek', () => {
  it('Üres modes tömb → soha nem jelenik meg', () => {
    const testGroups: MenuGroup[] = [
      { label: 'Test', modes: [], items: [{ path: '/test', label: 'Test item' }] }
    ]
    const result = filterMenuGroups(testGroups, 'penztar')
    expect(result).toHaveLength(0)
  })

  it('modes nélküli csoport → mindig megjelenik', () => {
    const testGroups: MenuGroup[] = [
      { label: 'Always', items: [{ path: '/always', label: 'Always item' }] }
    ]
    const result = filterMenuGroups(testGroups, 'full')
    expect(result).toHaveLength(1)
    expect(result[0]!.label).toBe('Always')
  })

  it('Csoport megjelenik de minden item rejtett → csoport is eltűnik', () => {
    const testGroups: MenuGroup[] = [
      { label: 'Empty', items: [
        { path: '/hidden', label: 'Hidden', modes: ['penztar'] },
      ]}
    ]
    const result = filterMenuGroups(testGroups, 'full')
    expect(result).toHaveLength(0)
  })

  it('Csoport rejtett → itemjei nem számítanak', () => {
    const testGroups: MenuGroup[] = [
      { label: 'Hidden Group', modes: ['penztar'], items: [
        { path: '/item1', label: 'Item 1' }, // nincs modes → elméletileg minden módban
      ]}
    ]
    const result = filterMenuGroups(testGroups, 'full')
    expect(result).toHaveLength(0)
  })
})

// ==========================================================
// Route path validálás — modes konzisztencia
// ==========================================================
describe('Menü — route path konzisztencia', () => {
  it('Minden menüpont egyedi path-szal rendelkezik', () => {
    const allPaths = menuGroups.flatMap((g) => g.items.map((i) => i.path))
    const uniquePaths = new Set(allPaths)
    expect(uniquePaths.size).toBe(allPaths.length)
  })

  it('Minden path /-vel kezdődik', () => {
    const allPaths = menuGroups.flatMap((g) => g.items.map((i) => i.path))
    for (const p of allPaths) {
      expect(p.startsWith('/')).toBe(true)
    }
  })

  it('Nincs üres label', () => {
    const allLabels = menuGroups.flatMap((g) => [g.label, ...g.items.map((i) => i.label)])
    for (const label of allLabels) {
      expect(label.trim().length).toBeGreaterThan(0)
    }
  })
})
