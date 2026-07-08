import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('./client', () => {
  const mockPost = vi.fn()
  const mockGet = vi.fn()
  const mockPut = vi.fn()
  return {
    api: {
      post: mockPost,
      get: mockGet,
      put: mockPut,
      defaults: { baseURL: '/api/v1' },
    },
  }
})

import { currencyDenominationImageApi } from './exchange-rates'
import { api } from './client'

const mockApi = api as unknown as {
  post: ReturnType<typeof vi.fn>
  get: ReturnType<typeof vi.fn>
  put: ReturnType<typeof vi.fn>
}

const dto = {
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

beforeEach(() => vi.clearAllMocks())

describe('currencyDenominationImageApi', () => {
  it('list_by_currency_calls_get_with_currencyId_param', async () => {
    mockApi.get.mockResolvedValue({ data: [dto] })
    const result = await currencyDenominationImageApi.list(7)
    expect(mockApi.get).toHaveBeenCalledWith('/currency-denomination-images', {
      params: { currencyId: 7 },
    })
    expect(result).toEqual([dto])
  })

  it('list_no_currencyId_omits_param', async () => {
    mockApi.get.mockResolvedValue({ data: [dto] })
    await currencyDenominationImageApi.list()
    expect(mockApi.get).toHaveBeenCalledWith('/currency-denomination-images', { params: {} })
  })

  it('upload_posts_multipart_with_all_fields_and_returns_dto', async () => {
    mockApi.post.mockResolvedValue({ data: dto })
    const file = new File(['bytes'], '500-front.jpg', { type: 'image/jpeg' })
    const result = await currencyDenominationImageApi.upload({
      currencyId: 7,
      faceValue: 500,
      denominationType: 'BANKNOTE',
      side: 'FRONT',
      file,
    })
    expect(mockApi.post).toHaveBeenCalledTimes(1)
    const firstPostCall = mockApi.post.mock.calls[0]
    expect(firstPostCall).toBeDefined()
    const [url, formData, opts] = firstPostCall as [
      string,
      FormData,
      { headers: Record<string, string> },
    ]
    expect(url).toBe('/currency-denomination-images/upload')
    expect(formData).toBeInstanceOf(FormData)
    expect((formData as FormData).get('currencyId')).toBe('7')
    expect((formData as FormData).get('faceValue')).toBe('500')
    expect((formData as FormData).get('denominationType')).toBe('BANKNOTE')
    expect((formData as FormData).get('side')).toBe('FRONT')
    expect((formData as FormData).get('file')).toBe(file)
    expect(opts.headers['Content-Type']).toBe('multipart/form-data')
    expect(result).toEqual(dto)
  })

  it('getThumbnail_returns_blob_via_responseType_blob', async () => {
    const blob = new Blob(['thumb'], { type: 'image/jpeg' })
    mockApi.get.mockResolvedValue({ data: blob })
    const result = await currencyDenominationImageApi.getThumbnail(
      '11111111-2222-3333-4444-555555555555',
    )
    expect(mockApi.get).toHaveBeenCalledWith(
      '/currency-denomination-images/11111111-2222-3333-4444-555555555555/thumbnail',
      { responseType: 'blob' },
    )
    expect(result).toBe(blob)
  })

  it('setActive_puts_id_active_with_boolean_body', async () => {
    mockApi.put.mockResolvedValue({ data: { ...dto, active: false } })
    const result = await currencyDenominationImageApi.setActive(
      '11111111-2222-3333-4444-555555555555',
      false,
    )
    expect(mockApi.put).toHaveBeenCalledWith(
      '/currency-denomination-images/11111111-2222-3333-4444-555555555555/active',
      { active: false },
    )
    expect(result.active).toBe(false)
  })

  it('getImage_returns_blob_via_responseType_blob', async () => {
    const blob = new Blob(['full'], { type: 'image/jpeg' })
    mockApi.get.mockResolvedValue({ data: blob })
    const result = await currencyDenominationImageApi.getImage(
      '11111111-2222-3333-4444-555555555555',
    )
    expect(mockApi.get).toHaveBeenCalledWith(
      '/currency-denomination-images/11111111-2222-3333-4444-555555555555/image',
      { responseType: 'blob' },
    )
    expect(result).toBe(blob)
  })
})
