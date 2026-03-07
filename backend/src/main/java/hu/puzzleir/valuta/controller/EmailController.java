package hu.puzzleir.valuta.controller;

import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.dto.email.ComposeEmailDto;
import hu.puzzleir.valuta.dto.email.EmailDetailDto;
import hu.puzzleir.valuta.dto.email.EmailListDto;
import hu.puzzleir.valuta.entity.EmailAccount;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.EmailAccountService;
import hu.puzzleir.valuta.service.GmailApiService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Email levelezés controller — levél olvasás, küldés, válasz, továbbítás, törlés.
 * A bejelentkezett worker aktív email fiókján keresztül.
 */
@RestController
@RequestMapping("/api/v1/email")
@RequiredArgsConstructor
public class EmailController {

    private final EmailAccountService emailAccountService;
    private final GmailApiService gmailApiService;

    /**
     * Levelek listázása.
     * Ha accountId adott → azt használja (verifyAccountAccess után).
     * Ha nem → az első elérhető aktív fiókot.
     */
    @GetMapping("/messages")
    public ResponseEntity<EmailListDto> listMessages(
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
        EmailListDto result = gmailApiService.listMessages(account, folder, maxResults);
        return ResponseEntity.ok(result);
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
