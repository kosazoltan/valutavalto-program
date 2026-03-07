package hu.puzzleir.valuta.controller;

import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.dto.email.ComposeEmailDto;
import hu.puzzleir.valuta.dto.email.EmailDetailDto;
import hu.puzzleir.valuta.dto.email.EmailListDto;
import hu.puzzleir.valuta.entity.EmailAccount;
import hu.puzzleir.valuta.entity.EmailCache;
import hu.puzzleir.valuta.repository.EmailCacheRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.EmailAccountService;
import hu.puzzleir.valuta.service.GmailApiService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Email levelezés controller — levél olvasás, küldés, válasz, továbbítás, törlés.
 * A bejelentkezett worker aktív email fiókján keresztül.
 */
@RestController
@RequestMapping("/api/v1/email")
@RequiredArgsConstructor
@Slf4j
public class EmailController {

    private final EmailAccountService emailAccountService;
    private final GmailApiService gmailApiService;
    private final EmailCacheRepository emailCacheRepository;

    /**
     * Levelek listázása.
     * Ha accountId adott → azt használja (verifyAccountAccess után).
     * Ha nem → az első elérhető aktív fiókot.
     * Gmail API hiba esetén → fallback: EmailCache-ből.
     */
    @GetMapping("/messages")
    public ResponseEntity<Map<String, Object>> listMessages(
            @RequestParam(required = false) UUID accountId,
            @RequestParam(defaultValue = "INBOX") String folder,
            @RequestParam(defaultValue = "50") int maxResults,
            Authentication auth) {
        EmailAccount account;
        if (accountId != null) {
            verifyAccountAccess(accountId, auth);
            account = getAccountById(accountId);
        } else {
            account = getActiveAccount(auth);
        }

        try {
            EmailListDto result = gmailApiService.listMessages(account, folder, maxResults);
            Map<String, Object> response = new HashMap<>();
            response.put("messages", result.getMessages());
            response.put("nextPageToken", result.getNextPageToken());
            response.put("resultSizeEstimate", result.getResultSizeEstimate());
            response.put("source", "gmail");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.warn("Gmail API hiba, fallback cache-re: account={}, error={}", account.getGmailAddress(), e.getMessage());
            // Fallback: EmailCache-ből
            List<EmailCache> cached = emailCacheRepository
                    .findByEmailAccountIdAndLabelIdsContainingOrderByReceivedAtDesc(account.getId(), folder.toUpperCase());

            List<EmailListDto.EmailSummaryDto> summaries = cached.stream()
                    .limit(maxResults)
                    .map(c -> EmailListDto.EmailSummaryDto.builder()
                            .id(c.getGmailMessageId())
                            .threadId(c.getThreadId())
                            .subject(c.getSubject())
                            .from(c.getSenderAddress())
                            .snippet(c.getSnippet())
                            .isRead(c.getIsRead())
                            .hasAttachments(c.getHasAttachments())
                            .receivedAt(c.getReceivedAt() != null
                                    ? c.getReceivedAt().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli()
                                    : 0L)
                            .build())
                    .collect(Collectors.toList());

            Map<String, Object> response = new HashMap<>();
            response.put("messages", summaries);
            response.put("nextPageToken", null);
            response.put("resultSizeEstimate", summaries.size());
            response.put("source", "cache");
            return ResponseEntity.ok(response);
        }
    }

    /**
     * Keresés levelek között Gmail search query szintaxissal.
     * Ha accountId adott → abban a fiókban keres.
     * Ha nincs → az összes elérhető fiókban keres.
     */
    @GetMapping("/search")
    public ResponseEntity<List<EmailListDto.EmailSummaryDto>> searchMessages(
            @RequestParam String query,
            @RequestParam(required = false) UUID accountId,
            @RequestParam(defaultValue = "20") int maxResults,
            Authentication auth) {
        maxResults = Math.min(maxResults, 100);
        if (accountId != null) {
            verifyAccountAccess(accountId, auth);
            EmailAccount account = getAccountById(accountId);
            List<EmailListDto.EmailSummaryDto> results = gmailApiService.searchMessages(account, query, maxResults);
            return ResponseEntity.ok(results);
        }

        // Nincs accountId → összes elérhető fiókban keresünk
        WorkerAuthenticationDetails details = getAuthDetails(auth);
        List<EmailAccount> accounts = emailAccountService.getAccountsForWorker(
                details.getWorkerId(), details.getActiveRole(), details.getBranchId());

        List<EmailListDto.EmailSummaryDto> allResults = new ArrayList<>();
        for (EmailAccount account : accounts) {
            try {
                List<EmailListDto.EmailSummaryDto> results = gmailApiService.searchMessages(account, query, maxResults);
                allResults.addAll(results);
            } catch (Exception e) {
                log.warn("Keresés hiba fiókban: {}, error={}", account.getGmailAddress(), e.getMessage());
            }
        }

        // Rendezés dátum szerint (legújabb elöl), limit
        allResults.sort((a, b) -> Long.compare(b.getReceivedAt(), a.getReceivedAt()));
        if (allResults.size() > maxResults) {
            allResults = allResults.subList(0, maxResults);
        }

        return ResponseEntity.ok(allResults);
    }

    /**
     * Levél részletek.
     */
    @GetMapping("/messages/{messageId}")
    public ResponseEntity<EmailDetailDto> getMessage(@PathVariable String messageId,
                                                      @RequestParam(required = false) UUID accountId,
                                                      Authentication auth) {
        EmailAccount account;
        if (accountId != null) {
            verifyAccountAccess(accountId, auth);
            account = getAccountById(accountId);
        } else {
            account = getActiveAccount(auth);
        }
        EmailDetailDto result = gmailApiService.getMessage(account, messageId);
        return ResponseEntity.ok(result);
    }

    /**
     * Email küldése.
     */
    @PostMapping("/messages")
    public ResponseEntity<Map<String, String>> sendMessage(@Valid @RequestBody ComposeEmailDto dto,
                                                            @RequestParam(required = false) UUID accountId,
                                                            Authentication auth) {
        EmailAccount account;
        if (accountId != null) {
            verifyAccountAccess(accountId, auth);
            account = getAccountById(accountId);
        } else {
            account = getActiveAccount(auth);
        }
        var sent = gmailApiService.sendMessage(account, dto.getTo(), dto.getSubject(), dto.getBody(), dto.getHtmlBody());
        return ResponseEntity.ok(Map.of("messageId", sent.getId()));
    }

    /**
     * Válasz levélre.
     */
    @PostMapping("/messages/{messageId}/reply")
    public ResponseEntity<Map<String, String>> replyToMessage(@PathVariable String messageId,
                                                               @RequestBody Map<String, String> body,
                                                               @RequestParam(required = false) UUID accountId,
                                                               Authentication auth) {
        EmailAccount account;
        if (accountId != null) {
            verifyAccountAccess(accountId, auth);
            account = getAccountById(accountId);
        } else {
            account = getActiveAccount(auth);
        }
        var sent = gmailApiService.replyToMessage(account, messageId, body.get("body"));
        return ResponseEntity.ok(Map.of("messageId", sent.getId()));
    }

    /**
     * Levél továbbítása.
     */
    @PostMapping("/messages/{messageId}/forward")
    public ResponseEntity<Map<String, String>> forwardMessage(@PathVariable String messageId,
                                                               @RequestParam String to,
                                                               @RequestParam(required = false) UUID accountId,
                                                               Authentication auth) {
        EmailAccount account;
        if (accountId != null) {
            verifyAccountAccess(accountId, auth);
            account = getAccountById(accountId);
        } else {
            account = getActiveAccount(auth);
        }
        var sent = gmailApiService.forwardMessage(account, messageId, to);
        return ResponseEntity.ok(Map.of("messageId", sent.getId()));
    }

    /**
     * Levél lomtárba helyezése.
     */
    @DeleteMapping("/messages/{messageId}")
    public ResponseEntity<Void> deleteMessage(@PathVariable String messageId,
                                               @RequestParam(required = false) UUID accountId,
                                               Authentication auth) {
        EmailAccount account;
        if (accountId != null) {
            verifyAccountAccess(accountId, auth);
            account = getAccountById(accountId);
        } else {
            account = getActiveAccount(auth);
        }
        gmailApiService.deleteMessage(account, messageId);
        return ResponseEntity.noContent().build();
    }

    /**
     * Levél olvasottnak jelölése.
     */
    @PostMapping("/messages/{messageId}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable String messageId,
                                            @RequestParam(required = false) UUID accountId,
                                            Authentication auth) {
        EmailAccount account;
        if (accountId != null) {
            verifyAccountAccess(accountId, auth);
            account = getAccountById(accountId);
        } else {
            account = getActiveAccount(auth);
        }
        gmailApiService.markAsRead(account, messageId);
        return ResponseEntity.noContent().build();
    }

    /**
     * Csatolmány letöltése.
     */
    @GetMapping("/attachments/{messageId}/{attachmentId}")
    public ResponseEntity<byte[]> getAttachment(@PathVariable String messageId,
                                                 @PathVariable String attachmentId,
                                                 @RequestParam(required = false) UUID accountId,
                                                 Authentication auth) {
        EmailAccount account;
        if (accountId != null) {
            verifyAccountAccess(accountId, auth);
            account = getAccountById(accountId);
        } else {
            account = getActiveAccount(auth);
        }
        byte[] data = gmailApiService.getAttachment(account, messageId, attachmentId);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment")
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(data);
    }

    /**
     * Olvasatlan levelek összesített száma az összes elérhető fiókból.
     * Hibás fiókok jelzése a válaszban (silent degradation).
     */
    @GetMapping("/unread-count")
    public ResponseEntity<Map<String, Object>> getUnreadCount(Authentication auth) {
        WorkerAuthenticationDetails details = getAuthDetails(auth);
        List<EmailAccount> accounts = emailAccountService.getAccountsForWorker(
                details.getWorkerId(), details.getActiveRole(), details.getBranchId());
        int totalUnread = 0;
        List<String> errors = new java.util.ArrayList<>();
        for (EmailAccount account : accounts) {
            try {
                totalUnread += gmailApiService.getUnreadCount(account);
            } catch (Exception e) {
                errors.add(account.getGmailAddress() + ": " + e.getMessage());
            }
        }
        Map<String, Object> result = new java.util.HashMap<>();
        result.put("unreadCount", totalUnread);
        if (!errors.isEmpty()) {
            result.put("errors", errors);
        }
        return ResponseEntity.ok(result);
    }

    /**
     * Ellenőrzi, hogy a bejelentkezett worker hozzáfér-e az adott email fiókhoz.
     */
    private void verifyAccountAccess(UUID accountId, Authentication auth) {
        WorkerAuthenticationDetails details = getAuthDetails(auth);
        List<EmailAccount> myAccounts = emailAccountService.getAccountsForWorker(
                details.getWorkerId(), details.getActiveRole(), details.getBranchId());
        boolean hasAccess = myAccounts.stream().anyMatch(a -> a.getId().equals(accountId));
        if (!hasAccess) {
            throw new ValidationException("Nincs hozzáférése ehhez az email fiókhoz!");
        }
    }

    /**
     * Email fiók lekérdezése ID alapján.
     */
    private EmailAccount getAccountById(UUID accountId) {
        return emailAccountService.getAccountById(accountId);
    }

    /**
     * Az aktuális worker első aktív email fiókjának lekérdezése.
     */
    private EmailAccount getActiveAccount(Authentication auth) {
        WorkerAuthenticationDetails details = getAuthDetails(auth);
        List<EmailAccount> accounts = emailAccountService.getAccountsForWorker(
                details.getWorkerId(), details.getActiveRole(), details.getBranchId());

        return accounts.stream()
                .filter(EmailAccount::getIsActive)
                .findFirst()
                .orElseThrow(() -> new ValidationException("Nincs aktív email fiók ehhez a felhasználóhoz!"));
    }

    private WorkerAuthenticationDetails getAuthDetails(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details;
        }
        throw new ValidationException("Hitelesítés szükséges!");
    }
}
