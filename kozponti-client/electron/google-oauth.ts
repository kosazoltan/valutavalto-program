/**
 * Google OAuth — a KOZPONTI kliens belepesi pontja a platform-retegbe.
 *
 * PLATFORM-REFAKTOR (2026-08-10): korabban ez a shim KOZVETLENUL a testver-
 * kliensbe importalt (`../../penztar-client/electron/google-oauth`), ami
 * cross-client csatolas volt. Mostantol a kozos platform-retegen keresztul
 * megy (`packages/electron-platform`), igy az iranyszabaly teljesul:
 * kliens -> platform, soha nem kliens -> kliens.
 *
 * A viselkedes VALTOZATLAN: a platform ugyanazt a production-tesztelt
 * implementaciot re-exportalja.
 */
export {
  GoogleOAuthFailedException,
  performGoogleOAuthFlow,
  performGoogleOAuthFlowWithBackendLogin,
} from '../../packages/electron-platform/src'
