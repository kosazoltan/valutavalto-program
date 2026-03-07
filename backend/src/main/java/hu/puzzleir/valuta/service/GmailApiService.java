package hu.puzzleir.valuta.service;

import com.google.api.client.auth.oauth2.Credential;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.http.HttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.gmail.Gmail;
import com.google.api.services.gmail.model.*;
import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.config.GmailOAuthConfig;
import hu.puzzleir.valuta.dto.email.EmailDetailDto;
import hu.puzzleir.valuta.dto.email.EmailListDto;
import hu.puzzleir.valuta.entity.EmailAccount;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.Session;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.*;

/**
 * Gmail API szolgáltatás — levelezés kezelése OAuth2 token-nel.
 * Minden metódus ELŐTT token frissítés ellenőrzés!
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class GmailApiService {

    private final GmailOAuthConfig gmailOAuthConfig;
    private final GoogleAuthorizationCodeFlow googleAuthorizationCodeFlow;
    private final HttpTransport googleHttpTransport;
    private final EmailAccountService emailAccountService;

    private static final String USER_ME = "me";
    private static final String APP_NAME = "Valutavalto-ERP";

    /**
     * Levelek listázása mappából.
     */
    public EmailListDto listMessages(EmailAccount account, String folder, int maxResults) {
        Gmail gmail = getGmailService(account);
        try {
            String query = folder != null ? "in:" + folder : "in:INBOX";
            ListMessagesResponse response = gmail.users().messages().list(USER_ME)
                    .setQ(query)
                    .setMaxResults((long) maxResults)
                    .execute();

            List<EmailListDto.EmailSummaryDto> summaries = new ArrayList<>();
            if (response.getMessages() != null) {
                for (Message msgRef : response.getMessages()) {
                    Message msg = gmail.users().messages().get(USER_ME, msgRef.getId())
                            .setFormat("metadata")
                            .setMetadataHeaders(List.of("Subject", "From", "Date"))
                            .execute();

                    summaries.add(EmailListDto.EmailSummaryDto.builder()
                            .id(msg.getId())
                            .threadId(msg.getThreadId())
                            .subject(getHeader(msg, "Subject"))
                            .from(getHeader(msg, "From"))
                            .snippet(msg.getSnippet())
                            .isRead(!msg.getLabelIds().contains("UNREAD"))
                            .hasAttachments(hasAttachments(msg))
                            .receivedAt(msg.getInternalDate())
                            .build());
                }
            }

            return EmailListDto.builder()
                    .messages(summaries)
                    .nextPageToken(response.getNextPageToken())
                    .resultSizeEstimate(response.getResultSizeEstimate() != null
                            ? response.getResultSizeEstimate().intValue() : 0)
                    .build();

        } catch (IOException e) {
            log.error("Gmail listMessages hiba: account={}", account.getGmailAddress(), e);
            throw new ValidationException("Gmail hiba: " + e.getMessage());
        }
    }

    /**
     * Teljes levél lekérdezése.
     */
    public EmailDetailDto getMessage(EmailAccount account, String messageId) {
        Gmail gmail = getGmailService(account);
        try {
            Message msg = gmail.users().messages().get(USER_ME, messageId)
                    .setFormat("full")
                    .execute();

            String body = "";
            String htmlBody = "";
            List<EmailDetailDto.AttachmentDto> attachments = new ArrayList<>();

            if (msg.getPayload() != null) {
                body = extractBody(msg.getPayload(), "text/plain");
                htmlBody = extractBody(msg.getPayload(), "text/html");
                attachments = extractAttachments(msg.getPayload());
            }

            return EmailDetailDto.builder()
                    .id(msg.getId())
                    .threadId(msg.getThreadId())
                    .subject(getHeader(msg, "Subject"))
                    .from(getHeader(msg, "From"))
                    .to(parseAddressList(getHeader(msg, "To")))
                    .cc(parseAddressList(getHeader(msg, "Cc")))
                    .body(body)
                    .htmlBody(htmlBody)
                    .receivedAt(msg.getInternalDate())
                    .attachments(attachments)
                    .build();

        } catch (IOException e) {
            log.error("Gmail getMessage hiba: messageId={}", messageId, e);
            throw new ValidationException("Gmail hiba: " + e.getMessage());
        }
    }

    /**
     * Email küldése.
     */
    public Message sendMessage(EmailAccount account, String to, String subject, String body, String htmlBody) {
        Gmail gmail = getGmailService(account);
        try {
            MimeMessage mimeMessage = createMimeMessage(account.getGmailAddress(), to, subject,
                    htmlBody != null ? htmlBody : body, htmlBody != null);

            Message message = createGmailMessage(mimeMessage);
            return gmail.users().messages().send(USER_ME, message).execute();

        } catch (Exception e) {
            log.error("Gmail sendMessage hiba: to={}", to, e);
            throw new ValidationException("Email küldés hiba: " + e.getMessage());
        }
    }

    /**
     * Válasz egy levélre.
     */
    public Message replyToMessage(EmailAccount account, String messageId, String body) {
        Gmail gmail = getGmailService(account);
        try {
            Message original = gmail.users().messages().get(USER_ME, messageId)
                    .setFormat("metadata")
                    .setMetadataHeaders(List.of("Subject", "From", "Message-ID"))
                    .execute();

            String subject = getHeader(original, "Subject");
            if (!subject.toLowerCase().startsWith("re:")) {
                subject = "Re: " + subject;
            }
            String replyTo = getHeader(original, "From");
            String originalMessageId = getHeader(original, "Message-ID");

            MimeMessage mimeMessage = createMimeMessage(account.getGmailAddress(), replyTo, subject, body, false);
            if (originalMessageId != null) {
                mimeMessage.setHeader("In-Reply-To", originalMessageId);
                mimeMessage.setHeader("References", originalMessageId);
            }

            Message message = createGmailMessage(mimeMessage);
            message.setThreadId(original.getThreadId());
            return gmail.users().messages().send(USER_ME, message).execute();

        } catch (Exception e) {
            log.error("Gmail replyToMessage hiba: messageId={}", messageId, e);
            throw new ValidationException("Válasz küldés hiba: " + e.getMessage());
        }
    }

    /**
     * Levél továbbítása.
     */
    public Message forwardMessage(EmailAccount account, String messageId, String to) {
        Gmail gmail = getGmailService(account);
        try {
            Message original = gmail.users().messages().get(USER_ME, messageId)
                    .setFormat("full")
                    .execute();

            String subject = getHeader(original, "Subject");
            if (!subject.toLowerCase().startsWith("fwd:")) {
                subject = "Fwd: " + subject;
            }

            String originalBody = extractBody(original.getPayload(), "text/plain");
            String forwardBody = "\n\n---------- Forwarded message ----------\n"
                    + "From: " + getHeader(original, "From") + "\n"
                    + "Subject: " + getHeader(original, "Subject") + "\n\n"
                    + originalBody;

            MimeMessage mimeMessage = createMimeMessage(account.getGmailAddress(), to, subject, forwardBody, false);
            Message message = createGmailMessage(mimeMessage);
            return gmail.users().messages().send(USER_ME, message).execute();

        } catch (Exception e) {
            log.error("Gmail forwardMessage hiba: messageId={}, to={}", messageId, to, e);
            throw new ValidationException("Továbbítás hiba: " + e.getMessage());
        }
    }

    /**
     * Levél lomtárba helyezése (NEM végleges törlés!).
     */
    public void deleteMessage(EmailAccount account, String messageId) {
        Gmail gmail = getGmailService(account);
        try {
            gmail.users().messages().trash(USER_ME, messageId).execute();
            log.info("Levél lomtárba helyezve: messageId={}", messageId);
        } catch (IOException e) {
            log.error("Gmail deleteMessage hiba: messageId={}", messageId, e);
            throw new ValidationException("Törlés hiba: " + e.getMessage());
        }
    }

    /**
     * Levél olvasottnak jelölése.
     */
    public void markAsRead(EmailAccount account, String messageId) {
        Gmail gmail = getGmailService(account);
        try {
            ModifyMessageRequest modifyRequest = new ModifyMessageRequest()
                    .setRemoveLabelIds(List.of("UNREAD"));
            gmail.users().messages().modify(USER_ME, messageId, modifyRequest).execute();
        } catch (IOException e) {
            log.error("Gmail markAsRead hiba: messageId={}", messageId, e);
            throw new ValidationException("Olvasottnak jelölés hiba: " + e.getMessage());
        }
    }

    /**
     * Olvasatlan levelek száma a fiókban.
     * Ha nincs token → return 0 (silent fail).
     */
    public int getUnreadCount(EmailAccount account) {
        if (account.getOauthAccessToken() == null && account.getOauthRefreshToken() == null) {
            return 0;
        }
        try {
            Gmail gmail = getGmailService(account);
            ListMessagesResponse response = gmail.users().messages().list(USER_ME)
                    .setQ("is:unread in:INBOX")
                    .setMaxResults(1L)
                    .execute();
            return response.getResultSizeEstimate() != null
                    ? response.getResultSizeEstimate().intValue() : 0;
        } catch (Exception e) {
            log.warn("getUnreadCount hiba: account={}, error={}", account.getGmailAddress(), e.getMessage());
            return 0;
        }
    }

    /**
     * Csatolmány letöltése.
     */
    public byte[] getAttachment(EmailAccount account, String messageId, String attachmentId) {
        Gmail gmail = getGmailService(account);
        try {
            MessagePartBody body = gmail.users().messages().attachments()
                    .get(USER_ME, messageId, attachmentId).execute();
            return Base64.getUrlDecoder().decode(body.getData());
        } catch (IOException e) {
            log.error("Gmail getAttachment hiba: messageId={}, attachmentId={}", messageId, attachmentId, e);
            throw new ValidationException("Csatolmány letöltés hiba: " + e.getMessage());
        }
    }

    // ========== PRIVATE HELPERS ==========

    /**
     * Gmail service felépítése — MINDIG token frissítéssel!
     */
    private Gmail getGmailService(EmailAccount account) {
        // Token frissítés ha szükséges
        EmailAccount refreshed = emailAccountService.refreshTokenIfNeeded(account);

        try {
            Credential credential = gmailOAuthConfig.getCredential(
                    googleAuthorizationCodeFlow,
                    refreshed.getOauthAccessToken(),
                    refreshed.getOauthRefreshToken());

            return new Gmail.Builder(googleHttpTransport, GsonFactory.getDefaultInstance(), credential)
                    .setApplicationName(APP_NAME)
                    .build();

        } catch (IOException e) {
            log.error("Gmail service létrehozás hiba: account={}", account.getGmailAddress(), e);
            throw new ValidationException("Gmail kapcsolódási hiba: " + e.getMessage());
        }
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

    private boolean hasAttachments(Message msg) {
        if (msg.getPayload() != null && msg.getPayload().getParts() != null) {
            return msg.getPayload().getParts().stream()
                    .anyMatch(p -> p.getFilename() != null && !p.getFilename().isEmpty());
        }
        return false;
    }

    private String extractBody(MessagePart payload, String mimeType) {
        if (payload.getMimeType().equals(mimeType) && payload.getBody() != null && payload.getBody().getData() != null) {
            return new String(Base64.getUrlDecoder().decode(payload.getBody().getData()));
        }
        if (payload.getParts() != null) {
            for (MessagePart part : payload.getParts()) {
                String result = extractBody(part, mimeType);
                if (!result.isEmpty()) return result;
            }
        }
        return "";
    }

    private List<EmailDetailDto.AttachmentDto> extractAttachments(MessagePart payload) {
        List<EmailDetailDto.AttachmentDto> attachments = new ArrayList<>();
        if (payload.getParts() != null) {
            for (MessagePart part : payload.getParts()) {
                if (part.getFilename() != null && !part.getFilename().isEmpty()) {
                    attachments.add(EmailDetailDto.AttachmentDto.builder()
                            .attachmentId(part.getBody().getAttachmentId())
                            .filename(part.getFilename())
                            .mimeType(part.getMimeType())
                            .size(part.getBody().getSize() != null ? part.getBody().getSize() : 0)
                            .build());
                }
                // Rekurzív keresés beágyazott részekhez
                attachments.addAll(extractAttachments(part));
            }
        }
        return attachments;
    }

    private List<String> parseAddressList(String addresses) {
        if (addresses == null || addresses.isBlank()) return List.of();
        return Arrays.stream(addresses.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();
    }

    private MimeMessage createMimeMessage(String from, String to, String subject, String body, boolean isHtml)
            throws MessagingException {
        Properties props = new Properties();
        Session session = Session.getDefaultInstance(props, null);
        MimeMessage email = new MimeMessage(session);
        email.setFrom(new InternetAddress(from));
        email.addRecipient(jakarta.mail.Message.RecipientType.TO, new InternetAddress(to));
        email.setSubject(subject, "UTF-8");
        if (isHtml) {
            email.setContent(body, "text/html; charset=UTF-8");
        } else {
            email.setText(body, "UTF-8");
        }
        return email;
    }

    private Message createGmailMessage(MimeMessage mimeMessage) throws MessagingException, IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        mimeMessage.writeTo(buffer);
        String encodedEmail = Base64.getUrlEncoder().withoutPadding().encodeToString(buffer.toByteArray());
        Message message = new Message();
        message.setRaw(encodedEmail);
        return message;
    }
}
