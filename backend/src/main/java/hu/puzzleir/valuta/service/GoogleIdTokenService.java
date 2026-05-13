package hu.puzzleir.valuta.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.json.webtoken.JsonWebSignature;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.GeneralSecurityException;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * Google ID token validacio service (V178/V179, 2026-05-03).
 *
 * <p>Hivatalos Google iranyelv (https://developers.google.com/identity/gsi/web/guides/verify-google-id-token)
 * szerint a backend-en MINDIG validalni kell a token signature-jet, audience-jet,
 * issuer-jet, expiry-jet, NEM csak az `email` payload alapjan.</p>
 *
 * <p>A `GoogleIdTokenVerifier` az audience listat, a Google JWK signature-t es az
 * `exp` mezot automatikusan ellenorzi. Ezen felul itt:
 *   - `email_verified == true`
 *   - opcionalis `google.login.allowed-domains` Workspace `hd` claim filter
 *   - `email`/`subject` not blank
 * </p>
 *
 * <p>Production loginban TILOS a `https://oauth2.googleapis.com/tokeninfo` HTTP endpointot
 * hivni — DoS-kockazat es Google API rate limit. Ez a service kizarolag a Google client
 * library `verify(idToken)` hivasat hasznalja, ami JWK-cache-elt validacio.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GoogleIdTokenService {

    private final GoogleIdTokenVerifier verifier;

    /**
     * Workspace hosted-domain whitelist (vesszovel elvalasztva, pl. "puzzleir.hu,excvaluta.com").
     * Ures = nincs hd-restrikcio, csak az exact email whitelist (V179 worker.email mezo) szamit.
     */
    @Value("${google.login.allowed-domains:}")
    private String allowedHostedDomainsProperty;

    /**
     * Validalt Google identitas — a token verify utan a payload normalizalt formaja.
     *
     * @param subject       a Google `sub` claim — stabil account azonosito
     * @param email         a Google `email` claim canonical (LOWERCASE + TRIM) formaja
     * @param emailVerified Google `email_verified` claim
     * @param hostedDomain  Workspace `hd` claim (NULL ha personal Gmail)
     * @param audience      a token `aud` claim — biztosan == sajat client ID
     * @param issuer        Google issuer (accounts.google.com vagy https://accounts.google.com)
     * @param name          Google profile display name, ha a token tartalmazza
     * @param picture       Google profile picture URL, ha a token tartalmazza
     */
    public record VerifiedGoogleIdentity(
            String subject,
            String email,
            boolean emailVerified,
            String hostedDomain,
            String audience,
            String issuer,
            String name,
            String picture
    ) {
    }

    /**
     * ID token validalas + payload normalizalas.
     *
     * @param idToken a Google CredentialResponse.credential ertekje (raw JWT)
     * @return validalt identitas, ha a token minden szempontbol jo
     * @throws GoogleTokenInvalidException barmely validacios szempont eseten
     */
    public VerifiedGoogleIdentity verify(String idToken) throws GoogleTokenInvalidException {
        if (idToken == null || idToken.isBlank()) {
            throw new GoogleTokenInvalidException("BLANK_TOKEN", "Google ID token hianyzik vagy ures.");
        }

        // Codex P1 PR #363 follow-up: a `GoogleIdTokenVerifier` ures audience-szel boot-olhat
        // dev/test profilban (lasd GoogleLoginConfig). Ekkor a `verify()` audience-validacio
        // NELKUL fogadna el a tokent — ami security-szempontbol invalid kornyezetben futhato
        // login flow. Itt explicit fail-fast: ha a verifier audiences ures, MINDEN tokent
        // utasitsunk el "MISCONFIGURED" code-dal.
        var verifierAudiences = verifier.getAudience();
        if (verifierAudiences == null || verifierAudiences.isEmpty()) {
            throw new GoogleTokenInvalidException("MISCONFIGURED",
                    "Google login NINCS konfiguralva (google.client.id hianyzik). "
                            + "Tokenvalidacio audience nelkul nem fogadhato el.");
        }

        GoogleIdToken googleIdToken;
        try {
            googleIdToken = verifier.verify(idToken);
        } catch (GeneralSecurityException | java.io.IOException ex) {
            log.warn("Google ID token verify exception: {}", ex.getClass().getSimpleName());
            throw new GoogleTokenInvalidException("VERIFY_EXCEPTION", "Google ID token validacio kivetel.");
        }

        if (googleIdToken == null) {
            // verify() null-t ad ha signature/audience/issuer/expiry hibas
            throw new GoogleTokenInvalidException("INVALID_SIGNATURE_OR_CLAIMS",
                    "Google ID token signature/audience/issuer/expiry hibas.");
        }

        GoogleIdToken.Payload payload = googleIdToken.getPayload();
        String subject = payload.getSubject();
        String email = payload.getEmail();
        Boolean emailVerifiedClaim = payload.getEmailVerified();
        String hostedDomain = payload.getHostedDomain();
        String audience = audienceAsString(payload.getAudience());
        String name = optionalClaimAsString(payload, "name");
        String picture = optionalClaimAsString(payload, "picture");
        JsonWebSignature.Header header = googleIdToken.getHeader();
        String issuer = String.valueOf(payload.getIssuer());

        if (subject == null || subject.isBlank()) {
            throw new GoogleTokenInvalidException("BLANK_SUBJECT",
                    "Google ID token `sub` claim ures.");
        }
        if (email == null || email.isBlank()) {
            throw new GoogleTokenInvalidException("BLANK_EMAIL",
                    "Google ID token `email` claim ures.");
        }
        if (!Boolean.TRUE.equals(emailVerifiedClaim)) {
            throw new GoogleTokenInvalidException("EMAIL_NOT_VERIFIED",
                    "Google ID token `email_verified` claim NEM true.");
        }

        // Workspace hd-domain whitelist (opcionalis, csak ha a property be van allitva)
        List<String> allowedHostedDomains = parseAllowedHostedDomains();
        if (!allowedHostedDomains.isEmpty()) {
            if (hostedDomain == null || !allowedHostedDomains.contains(hostedDomain.toLowerCase(Locale.ROOT))) {
                throw new GoogleTokenInvalidException("HD_NOT_WHITELISTED",
                        "Google Workspace hosted domain nincs a whitelisten.");
            }
        }

        log.debug("Google ID token verify OK — subjectHash={}, hd={}, kid={}",
                GoogleLoginService.safeLogHash(subject),
                hostedDomain == null ? "(none)" : hostedDomain,
                header == null ? "(none)" : header.getKeyId());

        return new VerifiedGoogleIdentity(
                subject,
                email.trim().toLowerCase(Locale.ROOT),
                true,
                hostedDomain,
                audience,
                issuer,
                name,
                picture
        );
    }

    private String optionalClaimAsString(GoogleIdToken.Payload payload, String claimName) {
        Object raw = payload.get(claimName);
        if (raw == null) return null;
        String value = String.valueOf(raw).trim();
        return value.isEmpty() ? null : value;
    }

    /**
     * Optional verify — wraplja a checked exceptiont, hogy a hivok stream/optional formaban
     * dolgozhassanak.
     */
    public Optional<VerifiedGoogleIdentity> verifyQuietly(String idToken) {
        try {
            return Optional.of(verify(idToken));
        } catch (GoogleTokenInvalidException ex) {
            log.warn("Google ID token verify failed: code={}", ex.getCode());
            return Optional.empty();
        }
    }

    private List<String> parseAllowedHostedDomains() {
        if (allowedHostedDomainsProperty == null || allowedHostedDomainsProperty.isBlank()) {
            return List.of();
        }
        return Arrays.stream(allowedHostedDomainsProperty.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(s -> s.toLowerCase(Locale.ROOT))
                .toList();
    }

    /** A `aud` claim lehet String vagy List — egy konzisztens String-re hozzuk. */
    @SuppressWarnings("unchecked")
    private String audienceAsString(Object audClaim) {
        if (audClaim == null) return null;
        if (audClaim instanceof String s) return s;
        if (audClaim instanceof List<?> list && !list.isEmpty()) {
            return String.valueOf(list.get(0));
        }
        return audClaim.toString();
    }

    /**
     * Google ID token validacios hibak — NEM `RuntimeException`, mert a hivok
     * (controller/service) explicit kezeljek (401 mapping).
     */
    public static class GoogleTokenInvalidException extends Exception {
        private final String code;

        public GoogleTokenInvalidException(String code, String message) {
            super(message);
            this.code = code;
        }

        public String getCode() {
            return code;
        }
    }
}
