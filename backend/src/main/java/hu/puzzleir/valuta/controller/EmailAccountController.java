package hu.puzzleir.valuta.controller;

import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.dto.email.EmailAccountDto;
import hu.puzzleir.valuta.entity.EmailAccount;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.EmailAccountService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.*;

/**
 * Email fiók kezelés controller — CRUD + OAuth2 flow.
 */
@RestController
@RequestMapping("/api/v1/email/accounts")
@RequiredArgsConstructor
public class EmailAccountController {

    private final EmailAccountService emailAccountService;

    /**
     * Saját email fiókok + beállíthatók listázása.
     */
    @GetMapping
    public ResponseEntity<Map<String, List<EmailAccount>>> list(Authentication auth) {
        WorkerAuthenticationDetails details = getAuthDetails(auth);
        List<EmailAccount> myAccounts = emailAccountService.getAccountsForWorker(
                details.getWorkerId(), details.getActiveRole(), details.getBranchId());
        List<EmailAccount> configurable = emailAccountService.getConfigurableAccounts(
                details.getWorkerId(), details.getActiveRole(), details.getCompanyId(), details.getBranchId());

        Map<String, List<EmailAccount>> result = new HashMap<>();
        result.put("accounts", myAccounts);
        result.put("configurable", configurable);
        return ResponseEntity.ok(result);
    }

    /**
     * Email fiók létrehozása.
     */
    @PostMapping
    public ResponseEntity<EmailAccount> create(@RequestBody EmailAccountDto dto, Authentication auth) {
        WorkerAuthenticationDetails details = getAuthDetails(auth);
        EmailAccount account = emailAccountService.createOrUpdateAccount(dto, details.getWorkerId());
        return ResponseEntity.status(HttpStatus.CREATED).body(account);
    }

    /**
     * Email fiók módosítása.
     */
    @PutMapping("/{id}")
    public ResponseEntity<EmailAccount> update(@PathVariable UUID id,
                                                @RequestBody EmailAccountDto dto,
                                                Authentication auth) {
        WorkerAuthenticationDetails details = getAuthDetails(auth);
        dto.setId(id);
        EmailAccount account = emailAccountService.createOrUpdateAccount(dto, details.getWorkerId());
        return ResponseEntity.ok(account);
    }

    /**
     * Email fiók törlése.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        emailAccountService.deleteAccount(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * OAuth2 flow indítása — redirect URL generálás.
     */
    @GetMapping("/{id}/auth")
    public ResponseEntity<Map<String, String>> startAuth(@PathVariable UUID id) {
        String authUrl = emailAccountService.startOAuthFlow(id);
        return ResponseEntity.ok(Map.of("authUrl", authUrl));
    }

    /**
     * OAuth2 callback — Google visszaírányít ide az authorization code-dal.
     */
    @GetMapping("/callback")
    public ResponseEntity<EmailAccount> oauthCallback(@RequestParam String code,
                                                       @RequestParam String state) {
        EmailAccount account = emailAccountService.handleOAuthCallback(code, state);
        return ResponseEntity.ok(account);
    }

    private WorkerAuthenticationDetails getAuthDetails(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details;
        }
        throw new ValidationException("Hitelesítés szükséges!");
    }
}
