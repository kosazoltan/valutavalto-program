import { describe, it, expect } from 'vitest'
import { render, screen, fireEvent, within } from '@testing-library/react'
import { useState } from 'react'
import {
  TILE_PALETTE,
  DEFAULT_TILE,
  tileClasses,
  WorkgroupEditor,
  ConfirmDialog,
} from './workgroupMaintenance'
import type { RateWorkgroupSaveDTO } from '../../services/api/index'

describe('workgroupMaintenance — paletta', () => {
  it('10 színt kínál és a DEFAULT_TILE az első (slate)', () => {
    expect(TILE_PALETTE).toHaveLength(10)
    expect(DEFAULT_TILE.key).toBe('slate')
  })

  it('tileClasses ismert kulcsra a megfelelő osztályt adja', () => {
    expect(tileClasses('amber')).toContain('bg-amber-100')
    expect(tileClasses('sky')).toContain('bg-sky-100')
  })

  it('tileClasses null/ismeretlen kulcsra az alapértelmezettre esik vissza', () => {
    expect(tileClasses(null)).toBe(DEFAULT_TILE.tile)
    expect(tileClasses(undefined)).toBe(DEFAULT_TILE.tile)
    expect(tileClasses('nincs-ilyen')).toBe(DEFAULT_TILE.tile)
  })
})

describe('workgroupMaintenance — WorkgroupEditor', () => {
  function Harness({ mode }: { mode: 'create' | 'rename' }) {
    const [draft, setDraft] = useState<RateWorkgroupSaveDTO>({ name: '', code: '', active: true, tileColor: DEFAULT_TILE.key })
    return <WorkgroupEditor mode={mode} draft={draft} setDraft={setDraft} onSave={() => {}} onCancel={() => {}} />
  }

  it('create módban szerkeszthető a kód, rename módban zárolt', () => {
    const { rerender } = render(<Harness mode="create" />)
    expect(screen.getByPlaceholderText('pl. WG01')).not.toBeDisabled()
    rerender(<Harness mode="rename" />)
    expect(screen.getByPlaceholderText('pl. WG01')).toBeDisabled()
  })

  it('a szín-paletta választása frissíti a draftot (ring a kiválasztotton)', () => {
    render(<Harness mode="create" />)
    const amber = screen.getByTitle('Borostyán')
    fireEvent.click(amber)
    expect(amber.className).toContain('ring-gray-800')
  })
})

describe('workgroupMaintenance — ConfirmDialog', () => {
  it('a megerősítő gomb meghívja az onConfirm-ot, danger esetén piros', () => {
    let confirmed = false
    render(
      <ConfirmDialog
        state={{ title: 'Törlés', message: 'Biztos?', confirmLabel: 'Törlés', danger: true, onConfirm: () => { confirmed = true } }}
        onCancel={() => {}}
      />,
    )
    const btn = screen.getByText('Törlés', { selector: 'button' })
    expect(btn.className).toContain('bg-red-600')
    fireEvent.click(btn)
    expect(confirmed).toBe(true)
  })

  it('Mégse nem hívja az onConfirm-ot, hívja az onCancel-t', () => {
    let confirmed = false
    let cancelled = false
    render(
      <ConfirmDialog
        state={{ title: 'X', message: 'Y', confirmLabel: 'OK', onConfirm: () => { confirmed = true } }}
        onCancel={() => { cancelled = true }}
      />,
    )
    fireEvent.click(within(screen.getByText('X').closest('div') as HTMLElement).getByText('Mégse'))
    expect(confirmed).toBe(false)
    expect(cancelled).toBe(true)
  })
})
