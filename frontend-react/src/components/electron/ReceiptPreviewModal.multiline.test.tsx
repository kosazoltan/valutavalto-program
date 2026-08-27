import { render } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import ReceiptPreviewModal from './ReceiptPreviewModal'
import type { PrintReceiptData } from '../../types/receipt'

// A modal csak a header-címhez használ i18n-t; a valuta-tartalom literal magyar szöveg.
vi.mock('react-i18next', () => ({
  initReactI18next: { type: '3rdParty' },
  useTranslation: () => ({ t: (k: string) => k }),
}))

// Több-valutás (multi-line) vétel: EGY bizonylatszám, több valuta-sor.
const multiLine: PrintReceiptData = {
  type: 'buy',
  companyType: 'BEST_CHANGE',
  receiptNumber: 'V001100042',
  branchCode: '001',
  cashierName: 'Teszt Pénztáros',
  date: '2026. 06. 04.',
  time: '11:30:00',
  // A fejléc a TELJES (összegzett, egyszer kerekített) összeget hordozza.
  hufAmount: 805_000,
  roundedHufAmount: 805_000,
  roundingDiff: 0,
  transactionLines: [
    { currencyCode: 'EUR', foreignAmount: 1000, rate: 405, hufAmount: 405_000 },
    { currencyCode: 'USD', foreignAmount: 1000, rate: 400, hufAmount: 400_000 },
  ],
}

// Egysoros vétel: NINCS transactionLines → változatlan (fejléc-mezős) megjelenítés.
const singleLine: PrintReceiptData = {
  type: 'buy',
  companyType: 'BEST_CHANGE',
  receiptNumber: 'V001100043',
  branchCode: '001',
  cashierName: 'Teszt Pénztáros',
  date: '2026. 06. 04.',
  time: '11:31:00',
  currencyCode: 'GBP',
  foreignAmount: 500,
  rate: 470,
  hufAmount: 235_000,
  roundedHufAmount: 235_000,
  roundingDiff: 0,
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

describe('ReceiptPreviewModal — multi-line vétel/eladás nyugta', () => {
  it('EGY bizonylatszám alatt MINDEN valuta-sor megjelenik', () => {
    const { container } = renderModal(multiLine)
    const txt = container.textContent ?? ''
    // Egyetlen valós bizonylatszám (nem P-<timestamp>)
    expect(txt).toContain('V001100042')
    expect(txt).not.toContain('P-')
    // Mindkét valuta-sor + árfolyam + HUF-érték
    expect(txt).toContain('EUR')
    expect(txt).toContain('USD')
    expect(txt).toContain('405')
    expect(txt).toContain('400')
    // A teljes (összegzett) végösszeg a Nettó Ft / SUM TOTAL soron (NBSP-toleráns)
    expect(txt.replace(/\s/g, '')).toContain('805000')
  })

  it('egysoros bizonylat (nincs transactionLines) → a fejléc-valuta jelenik meg, változatlanul', () => {
    const { container } = renderModal(singleLine)
    const txt = container.textContent ?? ''
    expect(txt).toContain('V001100043')
    expect(txt).toContain('GBP')
    expect(txt).toContain('470')
    expect(txt.replace(/\s/g, '')).toContain('235000')
    // Nincs más valuta a bizonylaton
    expect(txt).not.toContain('EUR')
    expect(txt).not.toContain('USD')
  })
})
