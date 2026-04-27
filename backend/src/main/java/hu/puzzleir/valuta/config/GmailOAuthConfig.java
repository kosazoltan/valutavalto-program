package hu.puzzleir.valuta.config;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.auth.oauth2.TokenResponse;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeTokenRequest;
import com.google.api.client.googleapis.auth.oauth2.GoogleRefreshTokenRequest;
import com.google.api.client.googleapis.javanet.GoogleNetHttpTransport;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.JsonFactory;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.client.util.store.MemoryDataStoreFactory;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.List;

/**
 * Gmail OAuth2 konfiguráció.
 * Google Workspace (exclusivebestchange.com) Internal app.
 */
@Configuration
@Slf4j
@Getter
public class GmailOAuthConfig {

    @Value("${google.client.id}")
    private String clientId;

    @Value("${google.client.secret}")
    private String clientSecret;

    @Value("${google.redirect.uri}")
    private String redirectUri;

    @Value("${google.gmail.scopes}")
    private String scopes;

    private static final JsonFactory JSON_FACTORY = GsonFactory.getDefaultInstance();

    @Bean
    public HttpTransport googleHttpTransport() throws GeneralSecurityException, IOException {
        return GoogleNetHttpTransport.newTrustedTransport();
    }

    @Bean
    @SuppressWarnings("deprecation") // setApprovalPrompt(String): a Google API client 2.0+-ban
    // deprecated, viszont a Builder.set("prompt", ...) NEM publikus a current API-ban.
    // A Google ajanlott migracio: a frontend kuldjon prompt=consent param-ot az URL-ben.
    // Most a backend force-olja minden auth-flow-nal (refresh_token issuance miatt).
    public GoogleAuthorizationCodeFlow googleAuthorizationCodeFlow(HttpTransport httpTransport)
            throws IOException {
        return new GoogleAuthorizationCodeFlow.Builder(
                httpTransport,
                JSON_FACTORY,
                clientId,
                clientSecret,
                List.of(scopes.split(",")))
                .setDataStoreFactory(MemoryDataStoreFactory.getDefaultInstance())
                .setAccessType("offline")
                .setApprovalPrompt("force")
                .build();
    }

    /**
     * Consent URL generálás OAuth2 flow indításhoz.
     * @param state Egyedi állapot paraméter (pl. emailAccountId) CSRF védelem + callback routing
     */
    public String buildAuthorizationUrl(GoogleAuthorizationCodeFlow flow, String state) {
        return flow.newAuthorizationUrl()
                .setRedirectUri(redirectUri)
                .setState(state)
                .build();
    }

    /**
     * Authorization code cseréje access + refresh token-re.
     */
    public TokenResponse exchangeCode(HttpTransport httpTransport, String code) throws IOException {
        return new GoogleAuthorizationCodeTokenRequest(
                httpTransport,
                JSON_FACTORY,
                clientId,
                clientSecret,
                code,
                redirectUri)
                .execute();
    }

    /**
     * Credential építése meglévő token-ekből (Gmail API híváshoz).
     */
    public Credential getCredential(GoogleAuthorizationCodeFlow flow, String accessToken, String refreshToken) throws IOException {
        TokenResponse tokenResponse = new TokenResponse()
                .setAccessToken(accessToken)
                .setRefreshToken(refreshToken);
        // Unique userId a flow-hoz — a refreshToken hash-e
        String userId = String.valueOf(refreshToken.hashCode());
        return flow.createAndStoreCredential(tokenResponse, userId);
    }

    /**
     * Access token frissítése refresh token segítségével.
     * @return Frissített TokenResponse (új access token + expiry)
     */
    public TokenResponse refreshAccessToken(HttpTransport httpTransport, String refreshToken) throws IOException {
        log.debug("Gmail access token frissítés refresh token-nel");
        return new GoogleRefreshTokenRequest(
                httpTransport,
                JSON_FACTORY,
                refreshToken,
                clientId,
                clientSecret)
                .execute();
    }
}
