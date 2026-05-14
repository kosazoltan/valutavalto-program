package hu.puzzleir.valuta.config;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;

import java.util.List;

/**
 * Google OAuth dolgozoi belepes konfigurale (V178/V179, 2026-05-03).
 *
 * <p>A `GoogleIdTokenVerifier` bean validalja a Google altal kiadott JWT ID tokent
 * (signature + audience + issuer + expiry). A korabbi `GoogleAuthController.fetchTokenInfo`
 * minta `https://oauth2.googleapis.com/tokeninfo` HTTP endpointot hivta minden loginra,
 * ami:
 *   - DoS-kockazat (Google API rate limit + minden login round-trip),
 *   - production-ban NEM ajanlott (Google docs explicit),
 *   - kulso fuggoseg minden login-hoz.
 * </p>
 *
 * <p>A kepers verifier signature-validacio a Google JWK kulcsait letolti es lokalisan cache-eli
 * (alapertelmezett TTL 1 ora).</p>
 *
 * <p>Production profilban a `google.client.id` KOTELEZO — ha hianyzik, a Spring context boot
 * fail-fast `IllegalStateException`-nel. Dev/test profilban ures audience-szel epitjuk a
 * verifier-t (context boot ne torjon meg), de a `GoogleIdTokenService.verify` 401-et fog
 * adni mert nincs a token-en megfelelo aud claim.</p>
 */
@Configuration
@Slf4j
public class GoogleLoginConfig {

    @Value("${google.client.id:}")
    private String googleClientId;

    /**
     * Electron Desktop OAuth client ID — Authorization Code Flow + loopback redirect-hez (RFC 8252).
     * A Web SDK (`<GoogleLogin>`) `app://localhost`-os Electron renderer-en NEM mukodik
     * (a Google `gsi/client` SDK csak `http://`/`https://` origint fogad el — `idpiframe_initialization_failed`).
     * Ezert az Electron a hivatalos Google Desktop apps mintat hasznalja:
     * ephemeral HTTP server `http://127.0.0.1:RANDOM_PORT/callback` + PKCE token exchange.
     * Ez egy MASIK Google Cloud OAuth client ID (Application type: Desktop), igy a backend
     * audience-listanak mind a Web (browser/excvaluta.com) mind a Desktop (Electron) ID-t
     * el kell fogadnia ugyanazon `/api/v1/auth/google-login` endpointon.
     *
     * <p>2026-05-14 enhancement (felhasznalo bejelentes #11/#13/#14 Bali/Fabulya Google login):
     * vesszovel elvalasztva tobb desktop client ID is megadhato — pl. credentials rotacio,
     * regi+uj Electron build egyutt mukodese, multi-tenancy. Ha csak EGY ID van, az is OK.</p>
     */
    @Value("${google.desktop.client.id:}")
    private String googleDesktopClientId;

    private final Environment environment;

    public GoogleLoginConfig(Environment environment) {
        this.environment = environment;
    }

    /**
     * Google ID token verifier — audience-listaval (Web + Electron Desktop client ID-k).
     *
     * <p>Production profile: ha a `google.client.id` (Web) ures, fail-fast a startup-on.
     * A `google.desktop.client.id` (Electron Desktop) opcionalis — ha ures, csak a webes
     * felulet Google login fog mukodni, az Electron-bol jovo token visszautasitva.</p>
     *
     * <p>Reuse-eli a `GmailOAuthConfig.googleHttpTransport()` `HttpTransport` bean-et,
     * NEM hoz letre uj HTTP klienst.</p>
     */
    @Bean
    public GoogleIdTokenVerifier googleIdTokenVerifier(HttpTransport googleHttpTransport) {
        // Hetzner systemd `SPRING_PROFILES_ACTIVE=prod` — historic profile name a deploy
        // pipeline-ban. A `production` is elfogadott legacy / docker-compose deploy-okhoz.
        java.util.List<String> activeProfiles = java.util.Arrays.asList(environment.getActiveProfiles());
        boolean isProduction = activeProfiles.contains("production") || activeProfiles.contains("prod");
        if (googleClientId == null || googleClientId.isBlank()) {
            if (isProduction) {
                throw new IllegalStateException(
                        "FATAL: google.client.id NINCS konfiguralva production-ben! "
                                + "A Google dolgozoi belepes nem mukodhet client ID nelkul.");
            }
            log.warn("Google login config: google.client.id NEM beallitva (dev/test) — Google login NEM aktiv.");
            // Dev/test profile: ures audience-szel epitjuk a verifier-t, hogy a context boot-oljon.
            // A `GoogleIdTokenService.verify` audience-mismatch-csel 401-et ad ha valaki megpro-balja.
            return new GoogleIdTokenVerifier.Builder(googleHttpTransport, GsonFactory.getDefaultInstance())
                    .build();
        }

        // Audience-lista: Web client ID kotelezo, Desktop client ID(k) opcionalis(ak) — vesszovel
        // elvalasztva tobb is megadhato. 2026-05-14: tobb desktop client ID tamogatasa felhasznaloi
        // bejelentes alapjan (Bali/Fabulya Google login fail, regi+uj installer egyutt mukodese).
        java.util.List<String> audiences = new java.util.ArrayList<>();
        audiences.add(googleClientId);
        if (googleDesktopClientId != null && !googleDesktopClientId.isBlank()) {
            java.util.List<String> desktopIds = new java.util.ArrayList<>();
            for (String id : googleDesktopClientId.split(",")) {
                String trimmed = id.trim();
                if (!trimmed.isEmpty()) {
                    desktopIds.add(trimmed);
                    audiences.add(trimmed);
                }
            }
            StringBuilder prefixes = new StringBuilder();
            for (String id : desktopIds) {
                if (prefixes.length() > 0) prefixes.append(", ");
                prefixes.append(id.substring(0, Math.min(8, id.length()))).append("***");
            }
            log.info("Google login config: GoogleIdTokenVerifier aktiv {} audience-szel — Web prefix: {}***, Desktop prefix(ek): {}.",
                    1 + desktopIds.size(),
                    googleClientId.substring(0, Math.min(8, googleClientId.length())),
                    prefixes);
        } else {
            log.info("Google login config: GoogleIdTokenVerifier aktiv csak Web audience-szel (prefix: {}***). Desktop client ID nincs konfiguralva — Electron-bol Google login NEM mukodik.",
                    googleClientId.substring(0, Math.min(8, googleClientId.length())));
        }

        return new GoogleIdTokenVerifier.Builder(googleHttpTransport, GsonFactory.getDefaultInstance())
                .setAudience(audiences)
                .build();
    }
}
