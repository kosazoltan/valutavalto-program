// The cashier client already contains the production-tested RFC 8252 + PKCE
// Desktop OAuth implementation.
//
// PLATFORM-REFAKTOR (2026-08-10): ez a wrapper korabban KOZVETLENUL a
// penztar-client-be importalt; a sajat kommentje elore is jelezte a szandekot
// ("can be extracted cleanly into a shared package later without changing
// callers"). Az import mostantol a kozos platform-retegen megy keresztul
// (`packages/electron-platform`), igy megszunt a cross-client csatolas.
// A hivok es a viselkedes VALTOZATLAN.
export {
  GoogleOAuthFailedException,
  performGoogleOAuthFlow,
  performGoogleOAuthFlowWithBackendLogin,
} from '../../packages/electron-platform/src'
