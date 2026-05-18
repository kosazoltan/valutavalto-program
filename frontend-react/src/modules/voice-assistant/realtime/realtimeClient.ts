import { logger } from '../../../utils/logger'
import { api } from '../../../services/api/client'

/**
 * WebRTC realtime kliens az OpenAI Realtime API-hoz.
 *
 * <p>Forrás: EBC_Hangseged_Claude_Code_Implementacios_Utasitas.md §3.5
 *
 * <p>A flow:
 * <ol>
 *   <li>backend-tól ephemeral client_secret kérése (POST /api/v1/voice/token)</li>
 *   <li>getUserMedia (mikrofon) ELŐSZÖR — Copilot finding: ha a usernek
 *       hosszabb idő kell az engedély megadásához mint a token TTL, az
 *       ephemeral lejár — ezért mikrofon → token → SDP a sorrend</li>
 *   <li>RTCPeerConnection felépítés + audio track add</li>
 *   <li>SDP offer küldése `https://api.openai.com/v1/realtime?model=...`
 *       — AbortController-rel + timeout-tal (Copilot finding)</li>
 *   <li>remote audio track playback + datachannel "oai-events"</li>
 * </ol>
 *
 * <p>Hiba esetén MINDEN félig-megnyitott erőforrás (mic stream, peer
 * connection) zárva van — try/catch wraps the setup.
 */

export interface EphemeralTokenResponse {
  client_secret: { value: string; expires_at: number | null }
  model: string
  mode: string
}

export interface RealtimeSession {
  pc: RTCPeerConnection
  dc: RTCDataChannel
  micStream: MediaStream
  remoteAudio: HTMLAudioElement
  close: () => void
}

const OPENAI_REALTIME_URL = 'https://api.openai.com/v1/realtime'
const DEFAULT_SDP_TIMEOUT_MS = 15_000

export async function requestEphemeralToken(
  mode: 'install' | 'test' | 'support'
): Promise<EphemeralTokenResponse> {
  const { data } = await api.post<EphemeralTokenResponse>(
    '/voice/token',
    { mode }
  )
  return data
}

export interface OpenSessionOptions {
  /** Külső AbortSignal — stop() hívásra cancel-elhető */
  signal?: AbortSignal
  /** SDP exchange timeout (default 15s) */
  sdpTimeoutMs?: number
}

function cleanupPartial(
  micStream: MediaStream | null,
  pc: RTCPeerConnection | null,
  remoteAudio: HTMLAudioElement | null
): void {
  try {
    micStream?.getTracks().forEach((t) => t.stop())
  } catch { /* ignore */ }
  try {
    pc?.close()
  } catch { /* ignore */ }
  try {
    remoteAudio?.remove()
  } catch { /* ignore */ }
}

export async function openRealtimeSession(
  mode: 'install' | 'test' | 'support',
  onEvent: (event: unknown) => void,
  options: OpenSessionOptions = {}
): Promise<RealtimeSession> {
  const { signal, sdpTimeoutMs = DEFAULT_SDP_TIMEOUT_MS } = options

  let micStream: MediaStream | null = null
  let pc: RTCPeerConnection | null = null
  let remoteAudio: HTMLAudioElement | null = null

  try {
    // 1. Mikrofon engedély ELŐSZÖR (Copilot finding) — ha a user lassan
    //    válaszol, ne legyen lejárt ephemeral token a SDP cseréhez.
    micStream = await navigator.mediaDevices.getUserMedia({ audio: true })
    if (signal?.aborted) throw new DOMException('Aborted', 'AbortError')

    // 2. Backend-tól ephemeral token — most már friss, max 60s alatt használjuk
    const token = await requestEphemeralToken(mode)
    if (signal?.aborted) throw new DOMException('Aborted', 'AbortError')
    logger.info('VoiceAssistant', 'ephemeral token kapva, model=' + token.model)

    // 3. RTCPeerConnection + tracks
    pc = new RTCPeerConnection()

    remoteAudio = document.createElement('audio')
    remoteAudio.autoplay = true
    pc.ontrack = (event) => {
      const stream = event.streams[0]
      if (stream && remoteAudio) {
        remoteAudio.srcObject = stream
      }
    }

    micStream.getTracks().forEach((track) => pc!.addTrack(track, micStream!))

    const dc = pc.createDataChannel('oai-events')
    dc.onmessage = (e) => {
      try {
        onEvent(JSON.parse(e.data))
      } catch (err) {
        logger.warn('VoiceAssistant', 'datachannel JSON parse hiba: ' + String(err))
      }
    }

    const offer = await pc.createOffer()
    await pc.setLocalDescription(offer)

    // 4. SDP exchange AbortController + timeout-tal
    const sdpController = new AbortController()
    const externalAbortHandler = () => sdpController.abort()
    if (signal) {
      signal.addEventListener('abort', externalAbortHandler)
    }
    const timeoutId = setTimeout(() => sdpController.abort(), sdpTimeoutMs)

    let resp: Response
    try {
      resp = await fetch(`${OPENAI_REALTIME_URL}?model=${encodeURIComponent(token.model)}`, {
        method: 'POST',
        body: offer.sdp,
        headers: {
          Authorization: `Bearer ${token.client_secret.value}`,
          'Content-Type': 'application/sdp',
        },
        signal: sdpController.signal,
      })
    } finally {
      clearTimeout(timeoutId)
      signal?.removeEventListener('abort', externalAbortHandler)
    }

    if (!resp.ok) {
      throw new Error(`OpenAI Realtime SDP exchange failed: HTTP ${resp.status}`)
    }
    const answerSdp = await resp.text()
    await pc.setRemoteDescription({ type: 'answer', sdp: answerSdp })

    // success — capture refs by VALUE (helyi konstansok), majd nullazzuk
    // a kulso variableket hogy a catch ne probaljon takaritani sikeres path-en
    const finalMic = micStream
    const finalPc = pc
    const finalAudio = remoteAudio
    const finalSession: RealtimeSession = {
      pc: finalPc,
      dc,
      micStream: finalMic,
      remoteAudio: finalAudio,
      close: () => {
        try { dc.close() } catch { /* ignore */ }
        finalMic.getTracks().forEach((t) => t.stop())
        finalPc.close()
        finalAudio.remove()
      },
    }
    micStream = null
    pc = null
    remoteAudio = null
    return finalSession
  } catch (err) {
    // Failure: clean up ALL partial resources (Copilot finding — mic stayed open)
    cleanupPartial(micStream, pc, remoteAudio)
    throw err
  }
}
