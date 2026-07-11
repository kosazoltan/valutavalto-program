import { describe, expect, it } from 'vitest'
import { filenameFromContentDisposition } from './contentDisposition'

describe('filenameFromContentDisposition', () => {
  it('kinyeri az idézőjeles filename értékét', () => {
    expect(filenameFromContentDisposition('attachment; filename="raiffeisen_import.imp"')).toBe(
      'raiffeisen_import.imp',
    )
  })

  it('a UTF-8 filename* értékét részesíti előnyben', () => {
    expect(
      filenameFromContentDisposition(
        "attachment; filename=legacy.imp; filename*=UTF-8''raiffeisen_%C3%A9rt%C3%A9knap.imp",
      ),
    ).toBe('raiffeisen_értéknap.imp')
  })

  it('hiányzó header esetén null értéket ad', () => {
    expect(filenameFromContentDisposition()).toBeNull()
  })
})
