/**
 * EBC Hangsegéd modul publikus API-ja.
 *
 * <p>Importáld a host-applikációból:
 * <pre>
 *   import { VoiceAssistantProvider, VoiceAssistantPanel } from '@/modules/voice-assistant'
 * </pre>
 */
export { VoiceAssistantProvider, useVoiceAssistant } from './context/VoiceAssistantProvider'
export type { VoiceAssistantContextValue } from './context/VoiceAssistantProvider'
export { VoiceAssistantPanel } from './components/VoiceAssistantPanel'
export { useVoiceMode } from './hooks/useVoiceMode'
export type { VoiceMode, UseVoiceModeResult } from './hooks/useVoiceMode'
export { openRealtimeSession, requestEphemeralToken } from './realtime/realtimeClient'
export type { EphemeralTokenResponse, RealtimeSession } from './realtime/realtimeClient'
