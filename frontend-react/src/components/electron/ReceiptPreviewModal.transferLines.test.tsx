import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'
import ReceiptPreviewModal from './ReceiptPreviewModal'
import type { PrintReceiptData } from '../../types/receipt'

/**
 * Penztar-batch A.1 (2026-06-12): több-valutás átadólap bizonylat-előnézete —
 * MINDEN valuta-sor megjelenik (eddig csak a fejléc = első valuta látszott).
 */
const base: PrintReceiptData = {
  type: 'transfer',
  companyType: 'BEST_CHANGE',
  receiptNumber: 'AT076000001',
  branchCode: 'BR076 - Békéscsaba Belváros',
  cashierName: 'Fabulya Zsuzsanna',
  date: '2026-06-12',
  time: '10:00:00',
  currencyCode: 'EUR',
  foreignAmount: 100,
  transferTarget: 'BR075 - Békéscsaba Értéktár',
  transferDocType: 'handover',
}

describe('ReceiptPreviewModal — több-valutás átadólap sorok', () => {
  it('transferLines jelenlétekor minden sor megjelenik (a fejléc-mezős egysoros nézet helyett)', () => {
    render(
      <ReceiptPreviewModal
        isOpen
        onClose={() => {}}
        onPrint={async () => {}}
        qrCodeDataUrl={null}
        receiptData={{
          ...base,
          transferLines: [
            { currencyCode: 'EUR', amount: 100 },
            { currencyCode: 'USD', amount: 10 },
          ],
        }}
      />,
    )
    expect(screen.getByText('Valuták és összegek:')).toBeInTheDocument()
    expect(screen.getByText(/EUR: 100/)).toBeInTheDocument()
    expect(screen.getByText(/USD: 10/)).toBeInTheDocument()
  })

  it('transferLines nélkül a korábbi egysoros megjelenítés változatlan', () => {
    render(
      <ReceiptPreviewModal
        isOpen
        onClose={() => {}}
        onPrint={async () => {}}
        qrCodeDataUrl={null}
        receiptData={base}
      />,
    )
    expect(screen.queryByText('Valuták és összegek:')).toBeNull()
    expect(screen.getByText('Valuta:')).toBeInTheDocument()
    expect(screen.getByText('EUR')).toBeInTheDocument()
  })
})
