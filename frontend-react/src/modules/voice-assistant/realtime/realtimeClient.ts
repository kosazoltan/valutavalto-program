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
 *   <li>RTCPeerConnection + getUserMedia (mikrofon)</li>
 *   <li>SDP offer küldése `https://api.openai.com/v1/realtime?model=...`</li>
 *   <li>remote audio track playback + datachannel "oai-events"</li>
 * </ol>
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

export async function requestEphemeralToken(
  mode: 'install' | 'test' | 'support'
): Promise<EphemeralTokenResponse> {
  const { data } = await api.post<EphemeralTokenResponse>(
    '/voice/token',
    { mode }
  )
  return data
}

export async function openRealtimeSession(
  mode: 'install' | 'test' | 'support',
  onEvent: (event: unknown) => void
): Promise<RealtimeSession> {
  const token = await requestEphemeralToken(mode)
  logger.info('VoiceAssistant', 'ephemeral token kapva, model=' + token.model)

  const pc = new RTCPeerConnection()

  const remoteAudio = document.createElement('audio')
  remoteAudio.autoplay = true
  pc.ontrack = (event) => {
    const stream = event.streams[0]
    if (stream) {
      remoteAudio.srcObject = stream
    }
  }

  const micStream = await navigator.mediaDevices.getUserMedia({ audio: true })
  micStream.getTracks().forEach((track) => pc.addTrack(track, micStream))

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

  const resp = await fetch(`${OPENAI_REALTIME_URL}?model=${token.model}`, {
    method: 'POST',
    body: offer.sdp,
    headers: {
      Authorization: `Bearer ${token.client_secret.value}`,
      'Content-Type': 'application/sdp',
    },
  })
  if (!resp.ok) {
    throw new Error(`OpenAI Realtime SDP exchange failed: HTTP ${resp.status}`)
  }
  const answerSdp = await resp.text()
  await pc.setRemoteDescription({ type: 'answer', sdp: answerSdp })

  return {
    pc,
    dc,
    micStream,
    remoteAudio,
    close: () => {
      try {
        dc.close()
      } catch { /* ignore */ }
      micStream.getTracks().forEach((t) => t.stop())
      pc.close()
      remoteAudio.remove()
    },
  }
}
