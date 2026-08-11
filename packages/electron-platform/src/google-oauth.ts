/**
 * Google OAuth (RFC 8252 + PKCE, Desktop flow) — PLATFORM re-export.
 *
 * === MIERT RE-EXPORT ES NEM ATMOZGATOTT KOD ===
 * A production-tesztelt implementacio a `penztar-client/electron/google-oauth.ts`
 * fajlban el (~695 sor: loopback redirect szerver, PKCE, allamvizsgalat,
 * backend-login csereberelés). A `kozponti-client` es az `arfolyam-keszito-client`
 * eddig KOZVETLENUL a testver-kliensbe importalt:
 *
 *   kozponti-client/electron/google-oauth.ts  -> '../../penztar-client/electron/google-oauth'
 *   arfolyam-keszito-client/.../google-oauth.ts -> ugyanoda
 *
 * Ez cross-client csatolas: a `.github/workflows/security.yml:288-294` emiatt
 * kenyszerul MINDHAROM klienst egyetlen typecheck-jobban telepiteni, es a
 * workflow sajat kommentje kertea kiemelest:
 *
 *   "(Follow-up: a kozos electron-modulok (api-proxy, google-oauth) kiemelese
 *    egy megosztott csomagba megszuntetne a cross-client csatolast — kulon refaktor.)"
 *
 * Ez a modul azt a follow-upot valositja meg a FORRAS ATMOZGATASA NELKUL:
 * a kliensek mostantol a PLATFORM-ra hivatkoznak, nem egymasra. A tenyleges
 * fajl athelyezese kulon, viselkedes-semleges lepes lehet - de a csatolas
 * iranya mar most helyes (kliens -> platform, soha nem kliens -> kliens).
 *
 * FONTOS: az arfolyam-keszito-client modulja a repo-szabaly szerint "kemeny
 * hatar" (a felelose tulajdonolja); ez a re-export NEM modositja a viselkedest,
 * csak az import-utvonalat egysegesiti.
 */

export {
  GoogleOAuthFailedException,
  performGoogleOAuthFlow,
  performGoogleOAuthFlowWithBackendLogin,
  performPasswordLoginMainProcess,
} from '../../../penztar-client/electron/google-oauth'

export type { GoogleOAuthResult, GoogleOAuthError } from '../../../penztar-client/electron/google-oauth'
