package hu.puzzleir.valuta.service;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.gmail.Gmail;
import com.google.api.services.gmail.model.ListMessagesResponse;
import com.google.api.services.gmail.model.Message;
import com.google.api.services.gmail.model.MessagePartHeader;
import hu.puzzleir.valuta.config.GmailOAuthConfig;
import hu.puzzleir.valuta.entity.EmailAccount;
import hu.puzzleir.valuta.entity.EmailCache;
import hu.puzzleir.valuta.repository.EmailAccountRepository;
import hu.puzzleir.valuta.repository.EmailCacheRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;

/**
 * Háttér szinkronizáció — 5 percenként szinkronizálja az aktív email fiókok
 * üzeneteit az EmailCache táblába (CSAK headerek/metaadatok, nem teljes body).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EmailSyncService {

    private final EmailAccountRepository emailAccountRepository;
    private final EmailCacheRepository emailCacheRepository;
    private final EmailAccountService emailAccountService;
    private final GmailOAuthConfig gmailOAuthConfig;
    private final GoogleAuthorizationCodeFlow googleAuthorizationCodeFlow;
    private final HttpTransport googleHttpTransport;

    private static final String USER_ME = "me";
    private static final String APP_NAME = "Valutavalto-ERP";
    @org.springframework.beans.factory.annotation.Value("${app.email.sync.max-messages:100}")
    private int syncMaxMessages;

    /**
     * 5 percenként szinkronizálja az aktív email fiókok leveleit az EmailCache táblába.
     */
    @Scheduled(fixedDelay = 300000) // 5 perc
    public void syncEmailCache() {
        List<EmailAccount> activeAccounts = emailAccountRepository.findByIsActiveTrue();
        log.debug("Email szinkronizáció indítás: {} aktív fiók", activeAccounts.size());

        for (EmailAccount account : activeAccounts) {
            // Token nélküli fiókokat átugorjuk
            if (account.getOauthRefreshToken() == null) {
                log.debug("Szinkronizáció kihagyva (nincs token): {}", account.getGmailAddress());
                continue;
            }

            try {
                syncAccountMessages(account);
                account.setLastSyncAt(LocalDateTime.now());
                account.setSyncError(null);
                emailAccountRepository.save(account);
                log.debug("Szinkronizáció sikeres: {}", account.getGmailAddress());
            } catch (Exception e) {
                log.error("Email sync hiba: {}", account.getGmailAddress(), e);
                account.setSyncError(e.getMessage());
                emailAccountRepository.save(account);
            }
        }

        // Régi cache bejegyzések törlése (>30 nap)
        try {
            LocalDateTime cutoff = LocalDateTime.now().minusDays(30);
            emailCacheRepository.deleteByReceivedAtBefore(cutoff);
        } catch (Exception e) {
            log.warn("Régi cache törlés hiba", e);
        }
    }

    private void syncAccountMessages(EmailAccount account) throws IOException {
        // Token frissítés
        EmailAccount refreshed = emailAccountService.refreshTokenIfNeeded(account);

        Credential credential = gmailOAuthConfig.getCredential(
                googleAuthorizationCodeFlow,
                refreshed.getOauthAccessToken(),
                refreshed.getOauthRefreshToken());

        Gmail gmail = new Gmail.Builder(googleHttpTransport, GsonFactory.getDefaultInstance(), credential)
                .setApplicationName(APP_NAME)
                .build();

        // INBOX + SENT levelek lekérése
        for (String query : List.of("in:INBOX", "in:SENT")) {
            ListMessagesResponse response = gmail.users().messages().list(USER_ME)
                    .setQ(query)
                    .setMaxResults((long) syncMaxMessages)
                    .execute();

            if (response.getMessages() == null) {
                continue;
            }

            for (Message msgRef : response.getMessages()) {
                try {
                    Message msg = gmail.users().messages().get(USER_ME, msgRef.getId())
                            .setFormat("metadata")
                            .setMetadataHeaders(List.of("Subject", "From", "To", "Date"))
                            .execute();

                    upsertCacheEntry(refreshed, msg);
                } catch (IOException e) {
                    log.warn("Üzenet szinkronizáció hiba: messageId={}, error={}", msgRef.getId(), e.getMessage());
                }
            }
        }
    }

    private void upsertCacheEntry(EmailAccount account, Message msg) {
        String gmailMessageId = msg.getId();

        EmailCache cache = emailCacheRepository
                .findByEmailAccountIdAndGmailMessageId(account.getId(), gmailMessageId)
                .orElse(EmailCache.builder()
                        .emailAccount(account)
                        .gmailMessageId(gmailMessageId)
                        .build());

        cache.setThreadId(msg.getThreadId());
        cache.setSubject(getHeader(msg, "Subject"));
        cache.setSenderAddress(getHeader(msg, "From"));
        cache.setRecipients(getHeader(msg, "To"));
        cache.setSnippet(msg.getSnippet());
        cache.setIsRead(msg.getLabelIds() == null || !msg.getLabelIds().contains("UNREAD"));
        cache.setHasAttachments(msg.getPayload() != null && msg.getPayload().getParts() != null &&
                msg.getPayload().getParts().stream()
                        .anyMatch(p -> p.getFilename() != null && !p.getFilename().isEmpty()));
        cache.setIsStarred(msg.getLabelIds() != null && msg.getLabelIds().contains("STARRED"));
        cache.setLabelIds(msg.getLabelIds() != null ? String.join(",", msg.getLabelIds()) : "");

        if (msg.getInternalDate() != null) {
            cache.setReceivedAt(LocalDateTime.ofInstant(
                    Instant.ofEpochMilli(msg.getInternalDate()),
                    ZoneId.systemDefault()));
        }
        cache.setCachedAt(LocalDateTime.now());

        emailCacheRepository.save(cache);
    }

    private String getHeader(Message msg, String headerName) {
        if (msg.getPayload() != null && msg.getPayload().getHeaders() != null) {
            return msg.getPayload().getHeaders().stream()
                    .filter(h -> headerName.equalsIgnoreCase(h.getName()))
                    .map(MessagePartHeader::getValue)
                    .findFirst()
                    .orElse("");
        }
        return "";
    }
}
