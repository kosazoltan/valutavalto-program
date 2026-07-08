import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { AxiosError } from 'axios'

vi.mock('../../../services/api/exchange-rates', () => ({
  currencyDenominationImageApi: {
    list: vi.fn(),
    upload: vi.fn(),
    getThumbnail: vi.fn(),
    setActive: vi.fn(),
  },
}))

vi.mock('../../../components/ui/toaster', () => ({
  toast: { success: vi.fn(), error: vi.fn(), warning: vi.fn() },
}))

vi.mock('../../../utils/logger', () => ({
  logger: { error: vi.fn(), warn: vi.fn(), info: vi.fn() },
}))

import CurrencyDenominationImagesPanel from './CurrencyDenominationImagesPanel'
import { currencyDenominationImageApi } from '../../../services/api/exchange-rates'
import type { Currency, CurrencyDenominationImageDto } from '../../../services/api/exchange-rates'

const eur: Currency = {
  id: 7,
  code: 'EUR',
  name: 'Euro',
  decimals: 2,
  displayOrder: 1,
  active: true,
}

const dto: CurrencyDenominationImageDto = {
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
}

beforeEach(() => {
  vi.clearAllMocks()
  vi.mocked(currencyDenominationImageApi.list).mockResolvedValue([])
  vi.mocked(currencyDenominationImageApi.getThumbnail).mockResolvedValue(
    new Blob(['t'], { type: 'image/jpeg' }),
  )
})

afterEach(() => {
  vi.restoreAllMocks()
})

describe('CurrencyDenominationImagesPanel', () => {
  it('no_currency_shows_helper_text_and_no_upload_form', () => {
    render(<CurrencyDenominationImagesPanel currency={null} />)
    expect(screen.getByTestId('denomination-images-empty')).toHaveTextContent('Válassz valutát')
    expect(screen.queryByTestId('denomination-image-upload-button')).not.toBeInTheDocument()
    expect(currencyDenominationImageApi.list).not.toHaveBeenCalled()
    expect(currencyDenominationImageApi.getThumbnail).not.toHaveBeenCalled()
  })

  it('selected_currency_fetches_list_with_currencyId', async () => {
    render(<CurrencyDenominationImagesPanel currency={eur} />)
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalledWith(7))
  })

  it('upload_disabled_until_all_required_fields_present', async () => {
    render(<CurrencyDenominationImagesPanel currency={eur} />)
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalled())

    const btn = screen.getByTestId('denomination-image-upload-button') as HTMLButtonElement
    expect(btn.disabled).toBe(true)

    fireEvent.change(screen.getByTestId('denomination-face-value'), { target: { value: '500' } })
    expect(btn.disabled).toBe(true)

    const file = new File(['bytes'], '500.jpg', { type: 'image/jpeg' })
    fireEvent.change(screen.getByTestId('denomination-image-file'), { target: { files: [file] } })
    await waitFor(() => expect(btn.disabled).toBe(false))
  })

  it('upload_negative_faceValue_keeps_button_disabled', async () => {
    render(<CurrencyDenominationImagesPanel currency={eur} />)
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalled())

    fireEvent.change(screen.getByTestId('denomination-face-value'), { target: { value: '-5' } })
    const file = new File(['bytes'], '500.jpg', { type: 'image/jpeg' })
    fireEvent.change(screen.getByTestId('denomination-image-file'), { target: { files: [file] } })
    expect(
      (screen.getByTestId('denomination-image-upload-button') as HTMLButtonElement).disabled,
    ).toBe(true)
  })

  it('upload_wrong_mime_keeps_button_disabled', async () => {
    render(<CurrencyDenominationImagesPanel currency={eur} />)
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalled())

    fireEvent.change(screen.getByTestId('denomination-face-value'), { target: { value: '500' } })
    const file = new File(['bytes'], '500.gif', { type: 'image/gif' })
    fireEvent.change(screen.getByTestId('denomination-image-file'), { target: { files: [file] } })
    expect(
      (screen.getByTestId('denomination-image-upload-button') as HTMLButtonElement).disabled,
    ).toBe(true)
  })

  it('upload_success_calls_api_refreshes_list_and_clears_form', async () => {
    vi.mocked(currencyDenominationImageApi.list)
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([dto])
    vi.mocked(currencyDenominationImageApi.upload).mockResolvedValue(dto)
    render(<CurrencyDenominationImagesPanel currency={eur} />)
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalledTimes(1))

    fireEvent.change(screen.getByTestId('denomination-face-value'), { target: { value: '500' } })
    const file = new File(['bytes'], '500.jpg', { type: 'image/jpeg' })
    fireEvent.change(screen.getByTestId('denomination-image-file'), { target: { files: [file] } })
    fireEvent.click(screen.getByTestId('denomination-image-upload-button'))

    await waitFor(() =>
      expect(currencyDenominationImageApi.upload).toHaveBeenCalledWith({
        currencyId: 7,
        faceValue: 500,
        denominationType: 'BANKNOTE',
        side: 'FRONT',
        file,
      }),
    )
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalledTimes(2))
    expect((screen.getByTestId('denomination-face-value') as HTMLInputElement).value).toBe('')
    expect((screen.getByTestId('denomination-image-file') as HTMLInputElement).files?.length).toBe(
      0,
    )
  })

  it('upload_failure_shows_error_toast_and_keeps_form_input', async () => {
    const backendMessage = 'A megjelenitesi sorrend mar foglalt'
    const conflict = new AxiosError('Request failed with status code 400')
    conflict.response = {
      status: 400,
      data: { code: 'VV-VALID-003', message: backendMessage },
    } as AxiosError['response']
    vi.mocked(currencyDenominationImageApi.upload).mockRejectedValue(conflict)
    const { toast } = await import('../../../components/ui/toaster')

    render(<CurrencyDenominationImagesPanel currency={eur} />)
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalled())

    fireEvent.change(screen.getByTestId('denomination-face-value'), { target: { value: '500' } })
    const file = new File(['bytes'], '500.jpg', { type: 'image/jpeg' })
    fireEvent.change(screen.getByTestId('denomination-image-file'), { target: { files: [file] } })
    fireEvent.click(screen.getByTestId('denomination-image-upload-button'))

    await waitFor(() => expect(vi.mocked(toast.error)).toHaveBeenCalledWith('Hiba', backendMessage))
    expect((screen.getByTestId('denomination-face-value') as HTMLInputElement).value).toBe('500')
    expect((screen.getByTestId('denomination-image-file') as HTMLInputElement).files?.[0]).toBe(
      file,
    )
    expect(
      (screen.getByTestId('denomination-image-upload-button') as HTMLButtonElement).disabled,
    ).toBe(false)
  })

  it('active_toggle_calls_setActive_and_refreshes', async () => {
    vi.mocked(currencyDenominationImageApi.list)
      .mockResolvedValueOnce([dto])
      .mockResolvedValueOnce([{ ...dto, active: false }])
    vi.mocked(currencyDenominationImageApi.setActive).mockResolvedValue({ ...dto, active: false })
    render(<CurrencyDenominationImagesPanel currency={eur} />)
    await screen.findByTestId('denomination-image-row-11111111-2222-3333-4444-555555555555')

    fireEvent.click(
      screen.getByTestId('denomination-image-toggle-11111111-2222-3333-4444-555555555555'),
    )
    await waitFor(() =>
      expect(currencyDenominationImageApi.setActive).toHaveBeenCalledWith(
        '11111111-2222-3333-4444-555555555555',
        false,
      ),
    )
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalledTimes(2))
  })

  it('active_toggle_double_click_is_guarded_before_re_render', async () => {
    vi.mocked(currencyDenominationImageApi.list).mockResolvedValue([dto])
    let resolveToggle!: (value: CurrencyDenominationImageDto) => void
    vi.mocked(currencyDenominationImageApi.setActive).mockReturnValue(
      new Promise((resolve) => {
        resolveToggle = resolve
      }),
    )

    render(<CurrencyDenominationImagesPanel currency={eur} />)
    await screen.findByTestId('denomination-image-row-11111111-2222-3333-4444-555555555555')

    const toggle = screen.getByTestId(
      'denomination-image-toggle-11111111-2222-3333-4444-555555555555',
    )
    fireEvent.click(toggle)
    fireEvent.click(toggle)

    expect(currencyDenominationImageApi.setActive).toHaveBeenCalledTimes(1)
    resolveToggle({ ...dto, active: false })
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalledTimes(2))
  })

  it('thumbnail_blob_object_url_is_created_and_revoked_on_unmount', async () => {
    vi.mocked(currencyDenominationImageApi.list).mockResolvedValue([dto])
    const revokeSpy = vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => undefined)
    const createSpy = vi.spyOn(URL, 'createObjectURL').mockReturnValue('blob:http://test/thumb1')
    const { unmount } = render(<CurrencyDenominationImagesPanel currency={eur} />)
    await waitFor(() =>
      expect(currencyDenominationImageApi.getThumbnail).toHaveBeenCalledWith(dto.id),
    )
    await waitFor(() => expect(createSpy).toHaveBeenCalled())
    unmount()
    expect(revokeSpy).toHaveBeenCalledWith('blob:http://test/thumb1')
  })

  it('currency_change_refetches_list_for_new_currencyId', async () => {
    const { rerender } = render(<CurrencyDenominationImagesPanel currency={eur} />)
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalledWith(7))
    const usd: Currency = {
      id: 8,
      code: 'USD',
      name: 'Dollar',
      decimals: 2,
      displayOrder: 2,
      active: true,
    }
    vi.mocked(currencyDenominationImageApi.list).mockClear()
    rerender(<CurrencyDenominationImagesPanel currency={usd} />)
    await waitFor(() => expect(currencyDenominationImageApi.list).toHaveBeenCalledWith(8))
  })

  it('currency switch revokes stale object URLs and re-fetches fresh thumbnails', async () => {
    const usd: Currency = {
      id: 8,
      code: 'USD',
      name: 'Dollar',
      decimals: 2,
      displayOrder: 2,
      active: true,
    }
    const usdDto: CurrencyDenominationImageDto = {
      ...dto,
      id: '22222222-3333-4444-5555-666666666666',
      currencyId: 8,
      faceValue: 100,
    }
    vi.mocked(currencyDenominationImageApi.list).mockImplementation(async (currencyId?: number) =>
      currencyId === 8 ? [usdDto] : [dto],
    )
    const revokeSpy = vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => undefined)
    vi.spyOn(URL, 'createObjectURL')
      .mockReturnValueOnce('blob:http://test/eur-first')
      .mockReturnValueOnce('blob:http://test/usd')
      .mockReturnValueOnce('blob:http://test/eur-second')

    const { rerender } = render(<CurrencyDenominationImagesPanel currency={eur} />)
    await waitFor(() =>
      expect(screen.getByAltText('EUR 500 Előlap')).toHaveAttribute(
        'src',
        'blob:http://test/eur-first',
      ),
    )

    rerender(<CurrencyDenominationImagesPanel currency={usd} />)
    await waitFor(() => expect(revokeSpy).toHaveBeenCalledWith('blob:http://test/eur-first'))
    await waitFor(() =>
      expect(screen.getByAltText('USD 100 Előlap')).toHaveAttribute('src', 'blob:http://test/usd'),
    )
    expect(screen.getByAltText('USD 100 Előlap')).not.toHaveAttribute(
      'src',
      'blob:http://test/eur-first',
    )

    rerender(<CurrencyDenominationImagesPanel currency={eur} />)
    await waitFor(() =>
      expect(screen.getByAltText('EUR 500 Előlap')).toHaveAttribute(
        'src',
        'blob:http://test/eur-second',
      ),
    )
    expect(screen.getByAltText('EUR 500 Előlap')).not.toHaveAttribute(
      'src',
      'blob:http://test/eur-first',
    )
  })
})
