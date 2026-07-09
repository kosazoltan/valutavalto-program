import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { downloadBlob } from './downloadBlob'

const createObjectURL = vi.fn((_: Blob | MediaSource) => 'blob:mock')
const revokeObjectURL = vi.fn((_: string) => undefined)

beforeEach(() => {
  vi.clearAllMocks()
  Object.defineProperty(URL, 'createObjectURL', {
    configurable: true,
    value: createObjectURL,
  })
  Object.defineProperty(URL, 'revokeObjectURL', {
    configurable: true,
    value: revokeObjectURL,
  })
})

afterEach(() => {
  vi.restoreAllMocks()
})

describe('downloadBlob', () => {
  it('createObjectURL → <a download> click → revokeObjectURL', () => {
    const clickedAnchor: { current: HTMLAnchorElement | null } = { current: null }
    const clickSpy = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function (
      this: HTMLAnchorElement,
    ) {
      clickedAnchor.current = this
    })

    downloadBlob('csv-adat', 'riport.csv', 'text/csv;charset=utf-8')

    expect(createObjectURL).toHaveBeenCalledTimes(1)
    expect(createObjectURL.mock.calls[0]?.[0]).toBeInstanceOf(Blob)
    expect(clickSpy).toHaveBeenCalledTimes(1)
    expect(clickedAnchor.current?.download).toBe('riport.csv')
    expect(clickedAnchor.current?.href).toBe('blob:mock')
    expect(clickedAnchor.current?.isConnected).toBe(false)
    expect(revokeObjectURL).toHaveBeenCalledWith('blob:mock')
  })
})
