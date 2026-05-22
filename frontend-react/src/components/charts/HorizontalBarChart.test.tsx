import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import HorizontalBarChart from './HorizontalBarChart'

describe('HorizontalBarChart', () => {
  it('üres adatnál az üres-szöveget mutatja', () => {
    render(<HorizontalBarChart data={[]} emptyText="Nincs adat" />)
    expect(screen.getByText('Nincs adat')).toBeInTheDocument()
  })

  it('minden adatpont feliratát és értékét megjeleníti', () => {
    // Egyéni formázó → locale-független assertion (Copilot #781).
    render(
      <HorizontalBarChart
        data={[
          { label: 'EUR', value: 1000 },
          { label: 'USD', value: 500 },
        ]}
        formatValue={(n) => `#${n}`}
      />,
    )
    expect(screen.getByText('EUR')).toBeInTheDocument()
    expect(screen.getByText('USD')).toBeInTheDocument()
    expect(screen.getByText('#1000')).toBeInTheDocument()
    expect(screen.getByText('#500')).toBeInTheDocument()
  })

  it('az aria-label konfigurálható', () => {
    render(
      <HorizontalBarChart data={[{ label: 'EUR', value: 1 }]} ariaLabel="Profit valutánként" />,
    )
    expect(screen.getByRole('img', { name: 'Profit valutánként' })).toBeInTheDocument()
  })

  it('duplikált label esetén nincs key-ütközés (mindkét sor renderel)', () => {
    const { container } = render(
      <HorizontalBarChart
        data={[
          { label: 'EUR', value: 10 },
          { label: 'EUR', value: 20 },
        ]}
        formatValue={(n) => `#${n}`}
      />,
    )
    expect(container.querySelectorAll('div[style]').length).toBe(2)
    expect(screen.getByText('#10')).toBeInTheDocument()
    expect(screen.getByText('#20')).toBeInTheDocument()
  })

  it('a legnagyobb abszolút értékhez skáláz (100% szélesség)', () => {
    const { container } = render(
      <HorizontalBarChart
        data={[
          { label: 'EUR', value: 200 },
          { label: 'USD', value: 100 },
        ]}
      />,
    )
    const bars = container.querySelectorAll('div[style]')
    // Első bar (200) = 100%, második (100) = 50%
    expect((bars[0] as HTMLElement).style.width).toBe('100%')
    expect((bars[1] as HTMLElement).style.width).toBe('50%')
  })

  it('negatív értéknél a negatív szín-osztályt használja', () => {
    const { container } = render(
      <HorizontalBarChart
        data={[{ label: 'EUR', value: -300 }]}
        negativeBarClassName="bg-red-500"
      />,
    )
    const bar = container.querySelector('div[style]') as HTMLElement
    expect(bar.className).toContain('bg-red-500')
    // abszolút értékhez skáláz → 100%
    expect(bar.style.width).toBe('100%')
  })

  it('egyéni formázót alkalmaz az értékekre', () => {
    render(
      <HorizontalBarChart
        data={[{ label: 'EUR', value: 1234 }]}
        formatValue={(n) => `${n} Ft`}
      />,
    )
    expect(screen.getByText('1234 Ft')).toBeInTheDocument()
  })
})
