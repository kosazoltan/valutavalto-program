package hu.puzzleir.valuta.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.json.webtoken.JsonWebSignature;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.test.util.ReflectionTestUtils;

import java.security.GeneralSecurityException;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

/**
 * V178/V179 Google OAuth audit (2026-05-03) regressziovedelem.
 *
 * <p>Bizonyitja, hogy a {@link GoogleIdTokenService}:
 * <ul>
 *   <li>NEM hivja a `https://oauth2.googleapis.com/tokeninfo` HTTP endpointot
 *       (kizarolag a {@link GoogleIdTokenVerifier#verify(String)} mock-jara tamaszkodik)</li>
 *   <li>blank/null tokent reject-el</li>
 *   <li>verifier null returnt (signature/audience/issuer/expiry hibas) reject-el</li>
 *   <li>email_verified == false reject-el</li>
 *   <li>blank email/subject reject-el</li>
 *   <li>email-t canonicalizalja (lower + trim)</li>
 *   <li>opcionalis hd-domain whitelist applyolja</li>
 * </ul>
 */
class GoogleIdTokenServiceTest {

    private GoogleIdTokenVerifier verifier;
    private GoogleIdTokenService service;

    @BeforeEach
    void setUp() {
        verifier = Mockito.mock(GoogleIdTokenVerifier.class);
        // Codex P1 PR #363 follow-up: a service most ellenorzi hogy a verifier audience-listaja
        // NEM ures (lasd MISCONFIGURED check). A test default-ban konfiguralt audience-szel mock-ol.
        when(verifier.getAudience()).thenReturn(List.of("test-client-id.apps.googleusercontent.com"));
        service = new GoogleIdTokenService(verifier);
        ReflectionTestUtils.setField(service, "allowedHostedDomainsProperty", "");
    }

    @Test
    @DisplayName("MISCONFIGURED — ures verifier audience -> reject (Codex P1 PR #363)")
    void misconfiguredVerifier_throwsBeforeVerify() {
        when(verifier.getAudience()).thenReturn(List.of());
        assertThatThrownBy(() -> service.verify("any-token"))
                .isInstanceOf(GoogleIdTokenService.GoogleTokenInvalidException.class)
                .hasMessageContaining("NINCS konfiguralva");
    }

    /**
     * Real `GoogleIdToken` instance — a Mockito NEM mockol final osztalyokat.
     * A `GoogleIdToken` constructor `(header, payload, signatureBytes, signedContentBytes)`.
     * Tesztben dummy signature/content byte[]-okkal hozzuk letre.
     */
    private GoogleIdToken buildRealIdToken(String subject, String email, Boolean emailVerified, String hd) {
        JsonWebSignature.Header header = new JsonWebSignature.Header();
        header.setAlgorithm("RS256");
        header.setKeyId("test-kid");
        GoogleIdToken.Payload payload = new GoogleIdToken.Payload();
        payload.setSubject(subject);
        payload.setEmail(email);
        payload.setEmailVerified(emailVerified);
        payload.setHostedDomain(hd);
        payload.setAudience("test-client-id.apps.googleusercontent.com");
        payload.setIssuer("https://accounts.google.com");
        return new GoogleIdToken(header, payload, new byte[0], new byte[0]);
    }

    @Test
    @DisplayName("blank token -> BLANK_TOKEN exception")
    void blankToken_throws() {
        assertThatThrownBy(() -> service.verify(""))
                .isInstanceOf(GoogleIdTokenService.GoogleTokenInvalidException.class)
                .hasMessageContaining("hianyzik");
        assertThatThrownBy(() -> service.verify(null))
                .isInstanceOf(GoogleIdTokenService.GoogleTokenInvalidException.class);
    }

    @Test
    @DisplayName("verifier null return -> INVALID_SIGNATURE_OR_CLAIMS exception")
    void verifierReturnsNull_throws() throws GeneralSecurityException, java.io.IOException {
        when(verifier.verify("bad-token")).thenReturn(null);
        assertThatThrownBy(() -> service.verify("bad-token"))
                .isInstanceOf(GoogleIdTokenService.GoogleTokenInvalidException.class)
                .hasMessageContaining("signature");
    }

    @Test
    @DisplayName("email_verified == false -> EMAIL_NOT_VERIFIED exception")
    void emailNotVerified_throws() throws GeneralSecurityException, java.io.IOException {
        when(verifier.verify("ok-token"))
                .thenReturn(buildRealIdToken("g-sub-1", "user@gmail.com", false, null));
        assertThatThrownBy(() -> service.verify("ok-token"))
                .isInstanceOf(GoogleIdTokenService.GoogleTokenInvalidException.class)
                .hasMessageContaining("email_verified");
    }

    @Test
    @DisplayName("blank subject -> BLANK_SUBJECT exception")
    void blankSubject_throws() throws GeneralSecurityException, java.io.IOException {
        when(verifier.verify("t1"))
                .thenReturn(buildRealIdToken("", "user@gmail.com", true, null));
        assertThatThrownBy(() -> service.verify("t1"))
                .isInstanceOf(GoogleIdTokenService.GoogleTokenInvalidException.class)
                .hasMessageContaining("sub");
    }

    @Test
    @DisplayName("blank email -> BLANK_EMAIL exception")
    void blankEmail_throws() throws GeneralSecurityException, java.io.IOException {
        when(verifier.verify("t2"))
                .thenReturn(buildRealIdToken("g-sub-1", "", true, null));
        assertThatThrownBy(() -> service.verify("t2"))
                .isInstanceOf(GoogleIdTokenService.GoogleTokenInvalidException.class)
                .hasMessageContaining("email");
    }

    @Test
    @DisplayName("happy path -> canonicalizalt email + helyes payload")
    void happyPath_returnsCanonicalizedIdentity() throws Exception {
        when(verifier.verify("good-token"))
                .thenReturn(buildRealIdToken("g-sub-42", "  USER@Example.COM  ", true, null));

        GoogleIdTokenService.VerifiedGoogleIdentity identity = service.verify("good-token");

        assertThat(identity.subject()).isEqualTo("g-sub-42");
        assertThat(identity.email()).isEqualTo("user@example.com");
        assertThat(identity.emailVerified()).isTrue();
        assertThat(identity.hostedDomain()).isNull();
        assertThat(identity.audience()).isEqualTo("test-client-id.apps.googleusercontent.com");
        assertThat(identity.issuer()).isEqualTo("https://accounts.google.com");
    }

    @Test
    @DisplayName("hd whitelist filter — engedelyezett domain atengedi")
    void hdWhitelist_allowedDomain_passes() throws Exception {
        ReflectionTestUtils.setField(service, "allowedHostedDomainsProperty", "puzzleir.hu,excvaluta.com");
        when(verifier.verify("ws-token"))
                .thenReturn(buildRealIdToken("g-sub-ws", "user@puzzleir.hu", true, "puzzleir.hu"));

        GoogleIdTokenService.VerifiedGoogleIdentity identity = service.verify("ws-token");

        assertThat(identity.hostedDomain()).isEqualTo("puzzleir.hu");
    }

    @Test
    @DisplayName("hd whitelist filter — NEM engedelyezett domain reject")
    void hdWhitelist_disallowedDomain_throws() throws Exception {
        ReflectionTestUtils.setField(service, "allowedHostedDomainsProperty", "puzzleir.hu");
        when(verifier.verify("ws-token-bad"))
                .thenReturn(buildRealIdToken("g-sub-ws-bad", "user@evil.com", true, "evil.com"));

        assertThatThrownBy(() -> service.verify("ws-token-bad"))
                .isInstanceOf(GoogleIdTokenService.GoogleTokenInvalidException.class)
                .hasMessageContaining("hosted domain");
    }

    @Test
    @DisplayName("hd whitelist filter — NULL hd nem-Workspace fioknal reject ha hd-restriction aktiv")
    void hdWhitelist_nullHostedDomain_throwsWhenRestricted() throws Exception {
        ReflectionTestUtils.setField(service, "allowedHostedDomainsProperty", "puzzleir.hu");
        when(verifier.verify("personal-gmail"))
                .thenReturn(buildRealIdToken("g-sub-gmail", "user@gmail.com", true, null));

        assertThatThrownBy(() -> service.verify("personal-gmail"))
                .isInstanceOf(GoogleIdTokenService.GoogleTokenInvalidException.class);
    }

    @Test
    @DisplayName("verifyQuietly Optional.empty-t ad invalid token-re NEM throw-ol")
    void verifyQuietly_returnsEmptyOnInvalid() {
        java.util.Optional<GoogleIdTokenService.VerifiedGoogleIdentity> result = service.verifyQuietly("");
        assertThat(result).isEmpty();
    }
}
