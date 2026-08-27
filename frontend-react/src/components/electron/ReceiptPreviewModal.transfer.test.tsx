import { render } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import ReceiptPreviewModal from './ReceiptPreviewModal'
import type { PrintReceiptData } from '../../types/receipt'

// A modal csak a header-címhez használ i18n-t; a transfer-tartalom literal magyar szöveg.
vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (k: string) => k }),
}))

const base: PrintReceiptData = {
  type: 'transfer',
  companyType: 'BEST_CHANGE',
  receiptNumber: 'SZ-2026-0001',
  branchCode: 'BR050 - Debrecen Értéktár',
  cashierName: 'Bali Henriett',
  date: '2026. 06. 03.',
  time: '10:00:00',
  currencyCode: 'EUR',
  foreignAmount: 1000,
  roundedHufAmount: 405000,
  transferTarget: 'BR060 - Debrecen Tesco',
  deliveryDate: '2026. 06. 05.',
  transferNote: 'Sürgős szállítás',
  carrierName: 'Gyors Futár Kft.',
  sealNumber: 'PL-12345',
}

function renderModal(data: PrintReceiptData) {
  return render(
    <ReceiptPreviewModal
      isOpen
      onClose={() => {}}
      receiptData={data}
      qrCodeDataUrl={null}
      onPrint={async () => {}}
    />,
  )
}

describe('ReceiptPreviewModal — átadási bizonylat (transfer)', () => {
  it('FR-2/FR-3: cégfejléc + összes kötelező átadás-átvétel mező megjelenik', () => {
    const { container } = renderModal(base)
    const txt = container.textContent ?? ''
    // Cégfejléc (a nyugtával azonos logika, BEST_CHANGE)
    expect(txt).toContain('EXCLUSIVE BEST CHANGE ZRT.')
    expect(txt).toContain('32313332-2-02')
    expect(txt).toContain('Átadási bizonylat')
    // Átadó + Átvevő + szállító + plomba + valuta + forint érték + megjegyzés
    expect(txt).toContain('Átadó:')
    expect(txt).toContain('BR050 - Debrecen Értéktár')
    expect(txt).toContain('Átvevő:')
    expect(txt).toContain('BR060 - Debrecen Tesco')
    expect(txt).toContain('Gyors Futár Kft.')
    expect(txt).toContain('PL-12345')
    expect(txt).toContain('EUR')
    expect(txt).toContain('Forint érték:')
    expect(txt).toContain('HUF')
    expect(txt).toContain('Sürgős szállítás')
    // Kiállítási dátum a közös fejlécben + külön kért kézbesítési dátum a törzsben
    expect(txt).toContain('2026. 06. 03.')
    expect(txt).toContain('Kézbesítési dátum:')
    expect(txt).toContain('2026. 06. 05.')
  })

  it('FR-2: az Átadó és Átvevő kötelező mezők hiányzó érték esetén is megjelennek („—")', () => {
    const { container } = renderModal({ ...base, branchCode: '', transferTarget: '' })
    const txt = container.textContent ?? ''
    expect(txt).toContain('Átadó:')
    expect(txt).toContain('Átvevő:')
    expect(txt).toContain('—')
  })

  it('FR-2: tranzakció-specifikus szekciók (ügyfél / jogcím) NEM jelennek meg transfer bizonylaton', () => {
    // Magas HUF-érték is — a transfer-elrejtés a típuson múlik, nem a küszöbön
    const { container } = renderModal({
      ...base,
      hufAmount: 6_000_000,
      roundedHufAmount: 6_000_000,
    })
    const txt = container.textContent ?? ''
    expect(txt).not.toContain('ügyfél adatai')
    expect(txt).not.toContain('JOGCÍM NYILATKOZAT')
    expect(txt).not.toContain('Deviza-státusz')
    // Az átadó/átvevő aláírás-blokk viszont megjelenik
    expect(txt).toContain('Átadó')
    expect(txt).toContain('Átvevő')
  })

  it('üres megjegyzés → nincs „Megjegyzés:" sor (üres sor nélkül)', () => {
    const { container } = renderModal({ ...base, transferNote: undefined })
    expect(container.textContent ?? '').not.toContain('Megjegyzés:')
  })

  it('NFR-3: 0 Ft forintosított érték is megjelenik („0 HUF")', () => {
    const { container } = renderModal({ ...base, roundedHufAmount: 0, hufAmount: 0 })
    expect(container.textContent ?? '').toContain('0 HUF')
  })
})
