// The cashier client already contains the production-tested RFC 8252 + PKCE
// Desktop OAuth implementation. Keep the wrapper local so the rate-maker shell
// can be extracted cleanly into a shared package later without changing callers.
export {
  GoogleOAuthFailedException,
  performGoogleOAuthFlow,
  performGoogleOAuthFlowWithBackendLogin,
} from '../../penztar-client/electron/google-oauth'
