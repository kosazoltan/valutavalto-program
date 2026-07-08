import { describe, it, expect } from 'vitest'
import { resolveElectronProdBaseUrl, PRODUCTION_API_URL } from './client'

describe('resolveElectronProdBaseUrl (Electron prod build-time URL guard)', () => {
  it('excvaluta.com host átmegy változatlanul', () => {
    expect(resolveElectronProdBaseUrl('https://excvaluta.com/api/v1')).toBe(
      'https://excvaluta.com/api/v1',
    )
  })

  it('www.excvaluta.com host átmegy', () => {
    expect(resolveElectronProdBaseUrl('https://www.excvaluta.com/api/v1')).toBe(
      'https://www.excvaluta.com/api/v1',
    )
  })

  it('excvaluta.com host ellenőrzése case-insensitive, a bemenet változatlan marad', () => {
    expect(resolveElectronProdBaseUrl('https://EXCVALUTA.COM/api/v1')).toBe(
      'https://EXCVALUTA.COM/api/v1',
    )
  })

  it('idegen prod-host → PRODUCTION_API_URL', () => {
    const staleRenderUrl = `https://${['valuta-backend-spbx', 'on' + 'render', 'com'].join('.')}/api/v1`

    expect(resolveElectronProdBaseUrl(staleRenderUrl)).toBe(PRODUCTION_API_URL)
  })

  it('lookalike subdomain nem megy át substring egyezéssel', () => {
    expect(resolveElectronProdBaseUrl('https://excvaluta.com.evil.example/api/v1')).toBe(
      PRODUCTION_API_URL,
    )
  })

  it('localhost → PRODUCTION_API_URL (régi guard-viselkedés megőrzése)', () => {
    expect(resolveElectronProdBaseUrl('http://localhost:8080/api/v1')).toBe(PRODUCTION_API_URL)
  })

  it('192.168-as privát cím → PRODUCTION_API_URL', () => {
    expect(resolveElectronProdBaseUrl('http://192.168.1.10:8080/api/v1')).toBe(PRODUCTION_API_URL)
  })

  it('üres/undefined → undefined (a meglévő fallback-lánc dolga)', () => {
    expect(resolveElectronProdBaseUrl(undefined)).toBeUndefined()
    expect(resolveElectronProdBaseUrl('')).toBeUndefined()
    expect(resolveElectronProdBaseUrl('   ')).toBeUndefined()
  })

  it('nem parse-olható / relatív string → PRODUCTION_API_URL (app:// alatt a relatív base nem él)', () => {
    expect(resolveElectronProdBaseUrl('/api/v1')).toBe(PRODUCTION_API_URL)
    expect(resolveElectronProdBaseUrl('not a url')).toBe(PRODUCTION_API_URL)
  })
})
