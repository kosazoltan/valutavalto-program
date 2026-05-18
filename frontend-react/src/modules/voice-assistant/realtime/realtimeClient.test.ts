import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { openRealtimeSession } from './realtimeClient'

/**
 * EBC Hangsegéd realtimeClient egységtesztek (Copilot finding #660 lefedés).
 *
 * <p>Mock: navigator.mediaDevices.getUserMedia + RTCPeerConnection + fetch +
 * apiClient.post — a valós OpenAI hívást nem teszteljük.
 */

vi.mock('../../../services/api/client', () => ({
  api: {
    post: vi.fn(async () => ({
      data: {
        client_secret: { value: 'sk-ephemeral-test', expires_at: null },
        model: 'gpt-realtime-2',
        mode: 'test',
      },
    })),
  },
}))

// In-memory mocks for browser APIs
class MockMediaStream {
  private tracks: { stop: () => void }[]
  constructor() {
    this.tracks = [{ stop: vi.fn() }]
  }
  getTracks() {
    return this.tracks
  }
}

class MockRTCPeerConnection {
  ontrack: ((event: { streams: MockMediaStream[] }) => void) | null = null
  addTrack = vi.fn()
  createDataChannel = vi.fn(() => ({ close: vi.fn(), onmessage: null }))
  createOffer = vi.fn(async () => ({ type: 'offer', sdp: 'v=0\nfake-offer' }))
  setLocalDescription = vi.fn(async () => undefined)
  setRemoteDescription = vi.fn(async () => undefined)
  close = vi.fn()
}

describe('openRealtimeSession', () => {
  const originalNav = globalThis.navigator
  const originalRTC = globalThis.RTCPeerConnection
  const originalFetch = globalThis.fetch

  let mockStreams: MockMediaStream[]
  let mockPcs: MockRTCPeerConnection[]

  beforeEach(() => {
    mockStreams = []
    mockPcs = []
    Object.defineProperty(globalThis, 'navigator', {
      value: {
        mediaDevices: {
          getUserMedia: vi.fn(async () => {
            const s = new MockMediaStream()
            mockStreams.push(s)
            return s as unknown as MediaStream
          }),
        },
      },
      configurable: true,
    })
    globalThis.RTCPeerConnection = function () {
      const pc = new MockRTCPeerConnection()
      mockPcs.push(pc)
      return pc
    } as unknown as typeof RTCPeerConnection
    globalThis.fetch = vi.fn(async () => ({
      ok: true,
      status: 200,
      text: async () => 'v=0\nfake-answer',
    } as Response))
  })

  afterEach(() => {
    Object.defineProperty(globalThis, 'navigator', { value: originalNav, configurable: true })
    globalThis.RTCPeerConnection = originalRTC
    globalThis.fetch = originalFetch
  })

  it('success: mikrofon + token + SDP cseren mind sikeresen lefut, session.close() takarit', async () => {
    const session = await openRealtimeSession('test', vi.fn())
    expect(session.pc).toBeDefined()
    expect(session.micStream).toBeDefined()
    session.close()
    const stoppedTracks = mockStreams[0]?.getTracks().filter((t) => (t.stop as ReturnType<typeof vi.fn>).mock.calls.length > 0)
    expect(stoppedTracks?.length).toBeGreaterThan(0)
    expect(mockPcs[0]?.close).toHaveBeenCalled()
  })

  it('failure: SDP HTTP 500 eseten a mikrofon track stop()-olva van (cleanup-on-error)', async () => {
    globalThis.fetch = vi.fn(async () => ({
      ok: false,
      status: 500,
      text: async () => 'error',
    } as Response))

    await expect(openRealtimeSession('test', vi.fn())).rejects.toThrow(/HTTP 500/)
    const stops = mockStreams[0]?.getTracks().map((t) => (t.stop as ReturnType<typeof vi.fn>).mock.calls.length) ?? []
    expect(stops.some((n) => n > 0)).toBe(true)
    expect(mockPcs[0]?.close).toHaveBeenCalled()
  })

  it('failure: getUserMedia rejected → nincs leak (semmi nem nyitva)', async () => {
    Object.defineProperty(globalThis, 'navigator', {
      value: {
        mediaDevices: {
          getUserMedia: vi.fn(async () => {
            throw new DOMException('Permission denied', 'NotAllowedError')
          }),
        },
      },
      configurable: true,
    })
    await expect(openRealtimeSession('test', vi.fn())).rejects.toThrow()
    expect(mockStreams).toHaveLength(0)
    expect(mockPcs).toHaveLength(0)
  })

  it('AbortSignal: hivo szignallal lemondhato', async () => {
    const ctrl = new AbortController()
    ctrl.abort()
    await expect(
      openRealtimeSession('test', vi.fn(), { signal: ctrl.signal })
    ).rejects.toThrow()
  })
})
