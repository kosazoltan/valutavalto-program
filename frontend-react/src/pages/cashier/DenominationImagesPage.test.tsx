import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor, act } from '@testing-library/react'

vi.mock('../../services/api/exchange-rates', () => ({
  currencyApi: { getAll: vi.fn() },
  currencyDenominationImageApi: {
    list: vi.fn(),
    getImage: vi.fn(),
    getThumbnail: vi.fn(),
  },
}))

vi.mock('../../components/ui/toaster', () => ({
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn() },
}))

vi.mock('../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

import DenominationImagesPage from './DenominationImagesPage'
import { currencyApi, currencyDenominationImageApi } from '../../services/api/exchange-rates'
import { toast } from '../../components/ui/toaster'
import { logger } from '../../utils/logger'
import type { Currency, CurrencyDenominationImageDto } from '../../services/api/exchange-rates'

const eur: Currency = {
  id: 7,
  code: 'EUR',
  name: 'Euro',
  decimals: 2,
  displayOrder: 1,
  active: true,
}

function makeDto(overrides: Partial<CurrencyDenominationImageDto>): CurrencyDenominationImageDto {
  return {
    id: '11111111-2222-3333-4444-555555555555',
    currencyId: 7,
    faceValue: 500,
    denominationType: 'BANKNOTE',
    side: 'FRONT',
    mimeType: 'image/jpeg',
    fileSizeBytes: 12345,
    active: true,
    createdAt: '2026-07-07T10:00:00Z',
    updatedAt: '2026-07-07T10:00:00Z',
    ...overrides,
  }
}

let objectUrlCounter = 0

beforeEach(() => {
  vi.clearAllMocks()
  objectUrlCounter = 0
  vi.spyOn(URL, 'createObjectURL').mockImplementation(
    () => `blob:http://test/${++objectUrlCounter}`,
  )
  vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => undefined)
  vi.mocked(currencyApi.getAll).mockResolvedValue([eur])
  vi.mocked(currencyDenominationImageApi.list).mockResolvedValue([])
  vi.mocked(currencyDenominationImageApi.getImage).mockResolvedValue(
    new Blob(['img'], { type: 'image/jpeg' }),
  )
})

afterEach(() => {
  vi.restoreAllMocks()
})

async function selectEur() {
  await waitFor(() => expect(currencyApi.getAll).toHaveBeenCalled())
  await act(async () => {
    fireEvent.change(screen.getByTestId('denomination-viewer-currency'), { target: { value: '7' } })
  })
}

describe('DenominationImagesPage', () => {
  it('no_selection_shows_helper_and_does_not_call_list', async () => {
    render(<DenominationImagesPage />)
    await waitFor(() => expect(currencyApi.getAll).toHaveBeenCalled())
    expect(screen.getByTestId('denomination-viewer-empty')).toHaveTextContent(
      'Válassz valutát a címletképek megtekintéséhez',
    )
    expect(currencyDenominationImageApi.list).not.toHaveBeenCalled()
  })

  it('selecting_currency_lists_and_renders_full_image_with_caption', async () => {
    const dto = makeDto({})
    vi.mocked(currencyDenominationImageApi.list).mockResolvedValue([dto])
    render(<DenominationImagesPage />)
    await selectEur()
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalledWith(7))
    await waitFor(() => expect(currencyDenominationImageApi.getImage).toHaveBeenCalledWith(dto.id))
    await waitFor(() =>
      expect(screen.getByTestId(`denomination-viewer-image-${dto.id}`)).toHaveTextContent(
        '500 EUR — Bankjegy / Előlap',
      ),
    )
    const img = await screen.findByAltText('EUR 500 Előlap')
    expect(img.getAttribute('src')).toMatch(/^blob:http:\/\/test\//)
  })

  it('images_sorted_by_faceValue_asc_then_front_first', async () => {
    vi.mocked(currencyDenominationImageApi.list).mockResolvedValue([
      makeDto({ id: 'id-500-back', faceValue: 500, side: 'BACK' }),
      makeDto({ id: 'id-500-front', faceValue: 500, side: 'FRONT' }),
      makeDto({ id: 'id-100-front', faceValue: 100, side: 'FRONT' }),
    ])
    render(<DenominationImagesPage />)
    await selectEur()
    await waitFor(() =>
      expect(screen.getAllByTestId(/^denomination-viewer-image-/)).toHaveLength(3),
    )
    const ids = screen
      .getAllByTestId(/^denomination-viewer-image-/)
      .map((el) => el.getAttribute('data-testid'))
    expect(ids).toEqual([
      'denomination-viewer-image-id-100-front',
      'denomination-viewer-image-id-500-front',
      'denomination-viewer-image-id-500-back',
    ])
  })

  it('list_error_logs_message_string_and_toasts', async () => {
    vi.mocked(currencyDenominationImageApi.list).mockRejectedValue(new Error('szerverhiba'))
    render(<DenominationImagesPage />)
    await selectEur()
    await waitFor(() => expect(toast.error).toHaveBeenCalled())
    expect(logger.error).toHaveBeenCalledWith(
      'DenominationImagesPage',
      expect.any(String),
      'szerverhiba',
    )
  })

  it('unmount_revokes_all_created_object_urls', async () => {
    const dto = makeDto({})
    vi.mocked(currencyDenominationImageApi.list).mockResolvedValue([dto])
    const { unmount } = render(<DenominationImagesPage />)
    await selectEur()
    await waitFor(() => expect(URL.createObjectURL).toHaveBeenCalled())
    unmount()
    expect(URL.revokeObjectURL).toHaveBeenCalledWith('blob:http://test/1')
  })
})
