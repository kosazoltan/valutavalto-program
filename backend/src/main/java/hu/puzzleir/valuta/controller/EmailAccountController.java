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
import jakarta.validation.Valid;

import java.util.*;

/**
 * Email fiók kezelés controller — CRUD + OAuth2 flow.
 * Fiók létrehozás/módosítás/törlés/OAuth: CHIEF_VAULT, REGIONAL_MGR, DIRECTOR role szükséges.
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

    private static final Set<String> ADMIN_ROLES = Set.of("CHIEF_VAULT", "REGIONAL_MGR", "DIRECTOR");

    /**
     * Email fiók létrehozása. Csak CHIEF_VAULT/REGIONAL_MGR/DIRECTOR.
     */
    @PostMapping
    public ResponseEntity<EmailAccount> create(@Valid @RequestBody EmailAccountDto dto, Authentication auth) {
        WorkerAuthenticationDetails details = getAuthDetails(auth);
        requireAdminRole(details);
        EmailAccount account = emailAccountService.createOrUpdateAccount(dto, details.getWorkerId());
        return ResponseEntity.status(HttpStatus.CREATED).body(account);
    }

    /**
     * Email fiók módosítása. Csak CHIEF_VAULT/REGIONAL_MGR/DIRECTOR.
     */
    @PutMapping("/{id}")
    public ResponseEntity<EmailAccount> update(@PathVariable UUID id,
                                                @Valid @RequestBody EmailAccountDto dto,
                                                Authentication auth) {
        WorkerAuthenticationDetails details = getAuthDetails(auth);
        requireAdminRole(details);
        dto.setId(id);
        EmailAccount account = emailAccountService.createOrUpdateAccount(dto, details.getWorkerId());
        return ResponseEntity.ok(account);
    }

    /**
     * Email fiók törlése. Csak CHIEF_VAULT/REGIONAL_MGR/DIRECTOR.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id, Authentication auth) {
        requireAdminRole(getAuthDetails(auth));
        emailAccountService.deleteAccount(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * OAuth2 flow indítása. Csak CHIEF_VAULT/REGIONAL_MGR/DIRECTOR.
     */
    @GetMapping("/{id}/auth")
    public ResponseEntity<Map<String, String>> startAuth(@PathVariable UUID id, Authentication auth) {
        requireAdminRole(getAuthDetails(auth));
        String authUrl = emailAccountService.startOAuthFlow(id);
        return ResponseEntity.ok(Map.of("authUrl", authUrl));
    }

    /**
     * OAuth2 callback — Google visszaírányít ide az authorization code-dal.
     * Sikeres token exchange után redirect a frontend email settings oldalra.
     */
    @GetMapping("/callback")
    public ResponseEntity<Void> oauthCallback(@RequestParam String code,
                                               @RequestParam String state) {
        try {
            emailAccountService.handleOAuthCallback(code, state);
            // Redirect a frontend email settings oldalra
            return ResponseEntity.status(302)
                    .header("Location", "/email/settings?oauth=success")
                    .build();
        } catch (Exception e) {
            return ResponseEntity.status(302)
                    .header("Location", "/email/settings?oauth=error&message=" +
                            java.net.URLEncoder.encode(e.getMessage(), java.nio.charset.StandardCharsets.UTF_8))
                    .build();
        }
    }

    private WorkerAuthenticationDetails getAuthDetails(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details;
        }
        throw new ValidationException("Hitelesítés szükséges!");
    }

    private void requireAdminRole(WorkerAuthenticationDetails details) {
        if (!ADMIN_ROLES.contains(details.getActiveRole())) {
            throw new ValidationException("Email fiók kezelés csak CHIEF_VAULT, REGIONAL_MGR vagy DIRECTOR jogosultsággal lehetséges!");
        }
    }
}
