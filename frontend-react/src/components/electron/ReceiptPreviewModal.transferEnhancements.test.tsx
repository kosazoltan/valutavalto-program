import { render } from '@testing-library/react'
import { describe, it, expect, vi } from 'vitest'
import ReceiptPreviewModal from './ReceiptPreviewModal'
import type { PrintReceiptData } from '../../types/receipt'

vi.mock('react-i18next', () => ({
  useTranslation: () => ({ t: (k: string) => k }),
}))

const base: PrintReceiptData = {
  type: 'transfer',
  companyType: 'BEST_CHANGE',
  receiptNumber: 'AT-000042',
  branchCode: 'Szeged Értéktár',
  cashierName: 'Bali Henriett',
  date: '2026. 06. 07.',
  time: '10:00:00',
  currencyCode: 'EUR',
  foreignAmount: 1000,
  roundedHufAmount: 405000,
  transferTarget: 'BR060 - Szeged Tesco',
  carrierName: 'Gyors Futár Kft.',
  sealNumber: 'PL-12345',
}

function renderModal(data: PrintReceiptData) {
  return render(
    <ReceiptPreviewModal isOpen onClose={() => {}} receiptData={data} qrCodeDataUrl={null} onPrint={async () => {}} />,
  )
}

describe('ReceiptPreviewModal — átadás-átvétel bővítések (FK02-E transfer)', () => {
  it('FR-1: a fejlécben a cégnév marad, de az értéktár SAJÁT címe jelenik meg (nem a székhely)', () => {
    const { container } = renderModal({ ...base, vaultAddress: 'Szeged, Hajnóczy u. 57., 6722' })
    const txt = container.textContent ?? ''
    expect(txt).toContain('EXCLUSIVE BEST CHANGE ZRT.')
    expect(txt).toContain('Szeged, Hajnóczy u. 57., 6722')
    // NEM a BEST_CHANGE hardcode székhelycím (Pécs)
    expect(txt).not.toContain('Citrom utca')
  })

  it('FR-2: transferDocType=receipt → „Átvételi bizonylat" cím', () => {
    const { container } = renderModal({ ...base, transferDocType: 'receipt' })
    expect(container.textContent ?? '').toContain('Átvételi bizonylat')
  })

  it('FR-2: transferDocType=handover (alapért.) → „Átadási bizonylat" cím', () => {
    const { container } = renderModal({ ...base, transferDocType: 'handover' })
    expect(container.textContent ?? '').toContain('Átadási bizonylat')
  })

  it('FR-13/FR-15: sztornó bizonylat fejléce „SZTORNÓ BIZONYLAT" + tartalmazza az indoklást', () => {
    const { container } = renderModal({
      ...base,
      receiptNumber: 'AT-000042-SZ',
      isStorno: true,
      stornoReason: 'Téves rögzítés',
    })
    const txt = container.textContent ?? ''
    expect(txt).toContain('SZTORNÓ BIZONYLAT')
    expect(txt).toContain('Sztornó indoklása:')
    expect(txt).toContain('Téves rögzítés')
    expect(txt).toContain('AT-000042-SZ')
  })

  it('FR-17/FR-18: ha van címletezés, a táblázat minden sora megjelenik', () => {
    const { container } = renderModal({
      ...base,
      denominations: [
        { quantity: 5, faceValue: 100, currencyCode: 'EUR', lineTotal: 500 },
        { quantity: 10, faceValue: 50, currencyCode: 'EUR', lineTotal: 500 },
      ],
    })
    const txt = container.textContent ?? ''
    expect(txt).toContain('Címletezés')
    expect(txt).toContain('5')
    expect(txt).toContain('10')
  })

  it('FR-19: ha nincs címletezés, a „Címletezés" szekció NEM jelenik meg', () => {
    const { container } = renderModal({ ...base, denominations: [] })
    expect(container.textContent ?? '').not.toContain('Címletezés')
  })
})
