import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import TextReasonModal from './TextReasonModal'

// RED (btn-primary/btn-secondary CSS-hiány): a TextReasonModal OK/Mégse gombja a
// `btn-primary` / `btn-secondary` osztályt kapja, amelyek SEHOL nincsenek definiálva
// a projekt CSS-ében (`grep -r '\.btn-primary' --include=*.css` → 0 találat), ezért
// a Tailwind preflight után a gombok stílus nélküli sima szövegként jelennek meg.
// A projekt bevett gomb-osztálypárja: `form-button-primary` / `form-button-secondary`
// (src/index.css @layer components).
//
// Ez a jsdom-os teszt a NÉVSZERZŐDÉST rögzíti (osztálynév + "létezik-e a CSS-ben"),
// a tényleges vizuális megjelenést a valós böngészős
// e2e/text-reason-modal-button-style.spec.ts ellenőrzi computed style-lal.

const CSS_SOURCES = ['../index.css', '../styles/design-tokens.css']

/** A projekt CSS-eiben ténylegesen definiált (egyszerű) osztályszelektorok halmaza. */
function definedCssClasses(): Set<string> {
  const defined = new Set<string>()
  for (const relative of CSS_SOURCES) {
    const css = readFileSync(fileURLToPath(new URL(relative, import.meta.url)), 'utf8')
    for (const [, className] of css.matchAll(/\.([A-Za-z][\w-]*)\s*(?=[,{])/g)) {
      if (className) defined.add(className)
    }
  }
  return defined
}

/**
 * Projekt-saját komponens-osztály namespace-ek. A Tailwind utility osztályok
 * (text-sm, flex, ...) generáltak, ezért nem szerepelhetnek a CSS-forrásban —
 * csak ezt a két, kézzel definiált névteret ellenőrizzük.
 */
const PROJECT_CLASS_NAMESPACES = /^(form-|btn-)/

function renderModal() {
  render(<TextReasonModal open title="Elutasítás indoka" onClose={vi.fn()} />)
  return {
    ok: screen.getByRole('button', { name: 'OK' }),
    cancel: screen.getByRole('button', { name: 'Mégse' }),
  }
}

describe('TextReasonModal — gomb-stílus osztályok (btn-primary/btn-secondary hiány)', () => {
  it('az OK gomb a projektben létező elsődleges gomb-osztályt kapja', () => {
    const { ok } = renderModal()
    expect(Array.from(ok.classList)).toContain('form-button-primary')
  })

  it('a Mégse gomb a projektben létező másodlagos gomb-osztályt kapja', () => {
    const { cancel } = renderModal()
    expect(Array.from(cancel.classList)).toContain('form-button-secondary')
  })

  it('a gombokon egyetlen olyan projekt-osztály sincs, ami hiányzik a CSS-ből', () => {
    const { ok, cancel } = renderModal()
    const defined = definedCssClasses()

    // Önellenőrzés: a CSS-parser tényleg megtalálja a bevett osztálypárt
    expect(defined.has('form-button-primary')).toBe(true)
    expect(defined.has('form-button-secondary')).toBe(true)

    const undefinedClasses = [ok, cancel].flatMap((button) =>
      Array.from(button.classList)
        .filter((name) => PROJECT_CLASS_NAMESPACES.test(name))
        .filter((name) => !defined.has(name))
        .map((name) => `${button.textContent}: .${name}`),
    )
    expect(undefinedClasses).toEqual([])
  })
})
