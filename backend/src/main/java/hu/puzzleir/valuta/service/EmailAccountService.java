package hu.puzzleir.valuta.service;

import com.google.api.client.auth.oauth2.TokenResponse;
import com.google.api.client.googleapis.auth.oauth2.GoogleAuthorizationCodeFlow;
import com.google.api.client.http.HttpTransport;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.config.GmailOAuthConfig;
import hu.puzzleir.valuta.dto.email.EmailAccountDto;
import hu.puzzleir.valuta.entity.EmailAccount;
import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.EmailAccountRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Email fiók kezelés — CRUD + OAuth flow.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EmailAccountService {

    private final EmailAccountRepository emailAccountRepository;
    private final WorkerRepository workerRepository;
    private final VaultTerritoryRepository vaultTerritoryRepository;
    private final BranchRepository branchRepository;
    private final GmailOAuthConfig gmailOAuthConfig;
    private final GoogleAuthorizationCodeFlow googleAuthorizationCodeFlow;
    private final HttpTransport googleHttpTransport;

    /**
     * Email fiók lekérdezése ID alapján.
     */
    public EmailAccount getAccountById(UUID accountId) {
        return emailAccountRepository.findById(accountId)
                .orElseThrow(() -> new ResourceNotFoundException("Email fiók nem található: " + accountId));
    }

    /**
     * A bejelentkezett worker számára elérhető email fiókok lekérdezése.
     * Az activeRole határozza meg, melyik szervezeti egység emailjét látja.
     *
     * @param workerId Bejelentkezett worker ID (Long!)
     * @param activeRole Operatív szerepkör (CASHIER, VAULT_KEEPER, CHIEF_VAULT, REGIONAL_MGR, DIRECTOR)
     * @param branchId Worker branch-je
     */
    public List<EmailAccount> getAccountsForWorker(Long workerId, String activeRole, UUID branchId) {
        if (activeRole == null) {
            return List.of();
        }

        return switch (activeRole) {
            case "CASHIER" -> {
                // Pénztáros: a branch emailje
                yield emailAccountRepository.findByBranchIdAndIsActiveTrue(branchId);
            }
            case "VAULT_KEEPER" -> {
                // Értéktáros: CSAK a saját branch-éhez tartozó vault territory emailje
                Branch myBranch = branchRepository.findById(branchId).orElse(null);
                if (myBranch == null || myBranch.getVaultTerritoryId() == null) yield List.of();
                yield emailAccountRepository.findByVaultTerritoryId(myBranch.getVaultTerritoryId()).stream()
                        .filter(EmailAccount::getIsActive).toList();
            }
            case "REGIONAL_MGR" -> {
                // Területi vezető: saját worker email + terület összes branch-e + értéktár emailje
                List<EmailAccount> accounts = new ArrayList<>();
                accounts.addAll(emailAccountRepository.findByWorkerId(workerId));
                Branch myBranch = branchRepository.findById(branchId).orElse(null);
                if (myBranch != null && myBranch.getVaultTerritoryId() != null) {
                    Integer vaultId = myBranch.getVaultTerritoryId();
                    List<Branch> territoryBranches = branchRepository.findByVaultTerritoryId(vaultId);
                    for (Branch b : territoryBranches) {
                        accounts.addAll(emailAccountRepository.findByBranchId(b.getId()));
                    }
                    accounts.addAll(emailAccountRepository.findByVaultTerritoryId(vaultId));
                }
                yield accounts.stream().filter(EmailAccount::getIsActive).toList();
            }
            case "CHIEF_VAULT", "DIRECTOR" -> {
                // Saját worker emailje
                yield emailAccountRepository.findByWorkerId(workerId).stream()
                        .filter(EmailAccount::getIsActive)
                        .toList();
            }
            default -> List.of();
        };
    }

    /**
     * A worker által konfigurálható fiókok lekérdezése.
     */
    public List<EmailAccount> getConfigurableAccounts(Long workerId, String activeRole, UUID companyId, UUID branchId) {
        if (activeRole == null) {
            return List.of();
        }

        return switch (activeRole) {
            case "REGIONAL_MGR" -> {
                // Területi vezető: saját worker + terület összes branch-e + értéktár emailjei
                List<EmailAccount> accounts = new ArrayList<>();
                accounts.addAll(emailAccountRepository.findByWorkerId(workerId));
                Branch myBranch = branchRepository.findById(branchId).orElse(null);
                if (myBranch != null && myBranch.getVaultTerritoryId() != null) {
                    Integer vaultId = myBranch.getVaultTerritoryId();
                    List<Branch> territoryBranches = branchRepository.findByVaultTerritoryId(vaultId);
                    for (Branch b : territoryBranches) {
                        accounts.addAll(emailAccountRepository.findByBranchId(b.getId()));
                    }
                    accounts.addAll(emailAccountRepository.findByVaultTerritoryId(vaultId));
                }
                yield accounts.stream().filter(EmailAccount::getIsActive).toList();
            }
            case "CHIEF_VAULT" -> {
                // Főértéktáros: saját emailje
                yield emailAccountRepository.findByWorkerId(workerId);
            }
            case "DIRECTOR" -> {
                // Igazgató: saját emailje
                yield emailAccountRepository.findByWorkerId(workerId);
            }
            default -> List.of();
        };
    }

    /**
     * Email fiók létrehozása vagy frissítése.
     * Validáció: pontosan 1 FK (branch/vaultTerritory/ownCompany/worker) kitöltve!
     */
    @Transactional(rollbackFor = Exception.class)
    public EmailAccount createOrUpdateAccount(EmailAccountDto dto, Long configuredByWorkerId) {
        validateExactlyOneFk(dto);

        EmailAccount account;
        if (dto.getId() != null) {
            account = emailAccountRepository.findById(dto.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Email fiók nem található: " + dto.getId()));
        } else {
            account = new EmailAccount();
        }

        // FK-k beállítása — mindig tisztítjuk az összeset, aztán a megfelelőt állítjuk
        account.setBranch(null);
        account.setVaultTerritory(null);
        account.setOwnCompany(null);
        account.setWorker(null);

        if (dto.getBranchId() != null) {
            hu.puzzleir.valuta.entity.Branch branch = new hu.puzzleir.valuta.entity.Branch();
            branch.setId(dto.getBranchId());
            account.setBranch(branch);
        } else if (dto.getVaultTerritoryId() != null) {
            VaultTerritory vt = vaultTerritoryRepository.findById(dto.getVaultTerritoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Értéktári terület nem található: " + dto.getVaultTerritoryId()));
            account.setVaultTerritory(vt);
        } else if (dto.getOwnCompanyId() != null) {
            hu.puzzleir.valuta.entity.OwnCompany oc = new hu.puzzleir.valuta.entity.OwnCompany();
            oc.setId(dto.getOwnCompanyId());
            account.setOwnCompany(oc);
        } else if (dto.getWorkerId() != null) {
            Worker worker = workerRepository.findById(dto.getWorkerId())
                    .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + dto.getWorkerId()));
            account.setWorker(worker);
        }

        account.setGmailAddress(dto.getGmailAddress());
        account.setDisplayName(dto.getDisplayName());
        account.setIsActive(dto.getIsActive() != null ? dto.getIsActive() : true);

        // Konfiguráló worker beállítása
        Worker configuredBy = workerRepository.findById(configuredByWorkerId)
                .orElseThrow(() -> new ResourceNotFoundException("Konfiguráló worker nem található: " + configuredByWorkerId));
        account.setConfiguredByWorker(configuredBy);

        log.info("Email fiók mentése: gmail={}, configuredBy={}", dto.getGmailAddress(), configuredByWorkerId);
        return emailAccountRepository.save(account);
    }

    /**
     * Email fiók törlése.
     */
    @Transactional(rollbackFor = Exception.class)
    public void deleteAccount(UUID accountId) {
        EmailAccount account = emailAccountRepository.findById(accountId)
                .orElseThrow(() -> new ResourceNotFoundException("Email fiók nem található: " + accountId));
        log.info("Email fiók törlése: id={}, gmail={}", accountId, account.getGmailAddress());
        emailAccountRepository.delete(account);
    }

    /**
     * OAuth2 flow indítása — consent URL generálás.
     * @return Google OAuth consent URL (ide kell redirect-elni a user-t)
     */
    public String startOAuthFlow(UUID accountId) {
        // Ellenőrizzük, hogy létezik a fiók
        emailAccountRepository.findById(accountId)
                .orElseThrow(() -> new ResourceNotFoundException("Email fiók nem található: " + accountId));

        // State = accountId (callback-ban használjuk)
        String state = accountId.toString();
        String authUrl = gmailOAuthConfig.buildAuthorizationUrl(googleAuthorizationCodeFlow, state);
        log.info("OAuth flow indítás: accountId={}", accountId);
        return authUrl;
    }

    /**
     * OAuth2 callback kezelése — authorization code cseréje token-ekre.
     */
    @Transactional(rollbackFor = Exception.class)
    public EmailAccount handleOAuthCallback(String code, String state) {
        UUID accountId;
        try {
            accountId = UUID.fromString(state);
        } catch (IllegalArgumentException e) {
            throw new ValidationException("Érvénytelen state paraméter: " + state);
        }

        EmailAccount account = emailAccountRepository.findById(accountId)
                .orElseThrow(() -> new ResourceNotFoundException("Email fiók nem található: " + accountId));

        try {
            TokenResponse tokenResponse = gmailOAuthConfig.exchangeCode(googleHttpTransport, code);

            account.setOauthAccessToken(tokenResponse.getAccessToken());
            account.setOauthRefreshToken(tokenResponse.getRefreshToken());

            // Token lejárat beállítása (másodpercben jön, LocalDateTime-re konvertáljuk)
            if (tokenResponse.getExpiresInSeconds() != null) {
                account.setOauthTokenExpiry(
                        LocalDateTime.now().plusSeconds(tokenResponse.getExpiresInSeconds()));
            }
            account.setSyncError(null);

            log.info("OAuth callback sikeres: accountId={}, gmail={}", accountId, account.getGmailAddress());
            return emailAccountRepository.save(account);

        } catch (IOException e) {
            log.error("OAuth token exchange hiba: accountId={}", accountId, e);
            account.setSyncError("OAuth hiba: " + e.getMessage());
            emailAccountRepository.save(account);
            throw new ValidationException("OAuth token exchange hiba: " + e.getMessage());
        }
    }

    /**
     * Access token frissítése, ha lejárt.
     * @return Frissített EmailAccount
     */
    @Transactional(rollbackFor = Exception.class)
    public EmailAccount refreshTokenIfNeeded(EmailAccount account) {
        if (account.getOauthRefreshToken() == null) {
            throw new ValidationException("Nincs refresh token a fiókhoz: " + account.getId());
        }

        // Ha a token még érvényes (> 5 perc hátra), nem frissítünk
        if (account.getOauthTokenExpiry() != null
                && account.getOauthTokenExpiry().isAfter(LocalDateTime.now().plusMinutes(5))) {
            return account;
        }

        try {
            TokenResponse tokenResponse = gmailOAuthConfig.refreshAccessToken(
                    googleHttpTransport, account.getOauthRefreshToken());

            account.setOauthAccessToken(tokenResponse.getAccessToken());
            if (tokenResponse.getExpiresInSeconds() != null) {
                account.setOauthTokenExpiry(
                        LocalDateTime.now().plusSeconds(tokenResponse.getExpiresInSeconds()));
            }
            account.setSyncError(null);

            log.debug("Token frissítve: accountId={}", account.getId());
            return emailAccountRepository.save(account);

        } catch (IOException e) {
            log.error("Token frissítés hiba: accountId={}", account.getId(), e);
            account.setSyncError("Token frissítés hiba: " + e.getMessage());
            emailAccountRepository.save(account);
            throw new ValidationException("Token frissítés hiba: " + e.getMessage());
        }
    }

    /**
     * Validáció: pontosan 1 FK kitöltve a 4-ből.
     */
    private void validateExactlyOneFk(EmailAccountDto dto) {
        int count = 0;
        if (dto.getBranchId() != null) count++;
        if (dto.getVaultTerritoryId() != null) count++;
        if (dto.getOwnCompanyId() != null) count++;
        if (dto.getWorkerId() != null) count++;

        if (count != 1) {
            throw new ValidationException(
                    "Pontosan egy hozzárendelés (branch/vaultTerritory/ownCompany/worker) szükséges! Jelenlegi: " + count);
        }
    }
}
