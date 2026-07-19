import { describe, expect, it } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

const layoutSource = readFileSync(resolve(process.cwd(), 'src/layouts/MainLayout.tsx'), 'utf-8')
const cssSource = readFileSync(resolve(process.cwd(), 'src/index.css'), 'utf-8')

describe('MainLayout — FK-057 vertical scroll architecture', () => {
  it('viewport-bounded root prevents document scrolling and exposes a dedicated print target', () => {
    const rootMatch = layoutSource.match(/return\s*\(\s*<div className="([^"]+)"/)
    expect(rootMatch).toBeTruthy()

    const rootClassSource = rootMatch?.[1]
    expect(rootClassSource).toBeDefined()
    const rootClasses = rootClassSource!.split(/\s+/)
    expect(rootClasses).toContain('app-layout-root')
    expect(rootClasses).toContain('h-screen')
    expect(rootClasses).toContain('overflow-hidden')
    expect(rootClasses).not.toContain('min-h-screen')
    expect(rootClasses).toContain('flex-col')
    expect(rootClasses).toContain('md:flex-row')
  })

  it('keeps the Sidebar nav as the only shrinking vertical menu scrollport', () => {
    const asideMatch = layoutSource.match(/<aside\s+className=\{`([\s\S]*?)`\}\s*>/)
    expect(asideMatch).toBeTruthy()

    const asideClassSource = asideMatch?.[1]
    expect(asideClassSource).toBeDefined()
    const unconditionalAsideClasses = asideClassSource!
      .replace(/\$\{[\s\S]*?\}/g, '')
      .trim()
      .split(/\s+/)
    expect(unconditionalAsideClasses).toContain('min-h-0')
    expect(unconditionalAsideClasses).toContain('max-h-full')

    const navMatch = layoutSource.match(/<nav\s+className=\{`([^`]+)`\}\s*>/)
    expect(navMatch).toBeTruthy()

    const navClassSource = navMatch?.[1]
    expect(navClassSource).toBeDefined()
    expect(navClassSource).toContain('flex-1')
    expect(navClassSource).toContain('min-h-0')
    expect(navClassSource).toContain('overflow-y-auto')
  })

  it('allows the mobile column main flex item to shrink without losing its width constraint', () => {
    const mainMatch = layoutSource.match(/<main className="([^"]+)" style=\{\{ minHeight: 0 \}\}>/)
    expect(mainMatch).toBeTruthy()

    const mainClassSource = mainMatch?.[1]
    expect(mainClassSource).toBeDefined()
    const mainClasses = mainClassSource!.split(/\s+/)
    expect(mainClasses).toContain('flex-1')
    expect(mainClasses).toContain('flex')
    expect(mainClasses).toContain('flex-col')
    expect(mainClasses).toContain('min-w-0')
  })

  it('resets the dedicated root height and overflow for complete multi-page printing', () => {
    const printBlock = cssSource.match(/@media print\s*\{([\s\S]*)\}\s*$/)
    expect(printBlock).toBeTruthy()

    const printBlockSource = printBlock?.[1]
    expect(printBlockSource).toBeDefined()
    const rootPrintRule = printBlockSource!.match(/\.app-layout-root\s*\{([^}]*)\}/)
    expect(rootPrintRule).toBeTruthy()
    const rootPrintDeclarations = rootPrintRule?.[1]
    expect(rootPrintDeclarations).toBeDefined()
    expect(rootPrintDeclarations).toMatch(/height:\s*auto\s*!important\s*;/)
    expect(rootPrintDeclarations).toMatch(/overflow:\s*visible\s*!important\s*;/)
  })
})
