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
 * <p>Ha `google.client.id` ures vagy hianyzik production profilban, a Google login
 * NEM lesz aktiv: a controller a `googleClientId` blank check-jen 401-et ad.</p>
 */
@Configuration
@Slf4j
public class GoogleLoginConfig {

    @Value("${google.client.id:}")
    private String googleClientId;

    private final Environment environment;

    public GoogleLoginConfig(Environment environment) {
        this.environment = environment;
    }

    /**
     * Google ID token verifier — audience-szel scope-olva a sajat web client ID-re.
     *
     * <p>Production profile: ha a `google.client.id` ures, fail-fast a startup-on
     * (nem hagyhatjuk hogy a Google login csendesen torott legyen).</p>
     *
     * <p>Reuse-eli a `GmailOAuthConfig.googleHttpTransport()` `HttpTransport` bean-et,
     * NEM hoz letre uj HTTP klienst.</p>
     */
    @Bean
    public GoogleIdTokenVerifier googleIdTokenVerifier(HttpTransport googleHttpTransport) {
        boolean isProduction = java.util.Arrays.asList(environment.getActiveProfiles())
                .contains("production");
        if (googleClientId == null || googleClientId.isBlank()) {
            if (isProduction) {
                throw new IllegalStateException(
                        "FATAL: google.client.id NINCS konfiguralva production-ben! "
                                + "A Google dolgozoi belepes nem mukodhet client ID nelkul.");
            }
            log.warn("Google login config: google.client.id NEM beallitva (dev/test) — Google login NEM aktiv.");
            // Dev/test profile: ures audience-szel epitjuk a verifier-t, hogy a context boot-oljon.
            // A controller blank-check megelozi a tenyleges hivasokat.
            return new GoogleIdTokenVerifier.Builder(googleHttpTransport, GsonFactory.getDefaultInstance())
                    .build();
        }

        log.info("Google login config: GoogleIdTokenVerifier aktiv (audience prefix: {}***).",
                googleClientId.substring(0, Math.min(8, googleClientId.length())));

        return new GoogleIdTokenVerifier.Builder(googleHttpTransport, GsonFactory.getDefaultInstance())
                .setAudience(List.of(googleClientId))
                .build();
    }
}
