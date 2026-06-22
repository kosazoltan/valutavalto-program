import { describe, it, expect, afterEach } from 'vitest'
import { api, getPublicWebUrl } from './client'

// FK-041/II: a getPublicWebUrl a PWA-megosztáshoz (árfolyam néző QR) a PUBLIKUS web-origint adja.
describe('getPublicWebUrl (FK-041/II)', () => {
  const original = api.defaults.baseURL

  afterEach(() => {
    api.defaults.baseURL = original
  })

  it('Electron abszolút API URL-ből a web-origint adja (/api/v1 levágva)', () => {
    api.defaults.baseURL = 'https://excvaluta.com/api/v1'
    expect(getPublicWebUrl()).toBe('https://excvaluta.com')
  })

  it('aldomain/port is megmarad az origin-ben', () => {
    api.defaults.baseURL = 'https://teszt.excvaluta.com:8443/api/v1'
    expect(getPublicWebUrl()).toBe('https://teszt.excvaluta.com:8443')
  })

  it('relatív /api/v1 (webes proxy) esetén a böngésző origin-jét adja vissza', () => {
    api.defaults.baseURL = '/api/v1'
    expect(getPublicWebUrl()).toBe(window.location.origin)
  })
})
