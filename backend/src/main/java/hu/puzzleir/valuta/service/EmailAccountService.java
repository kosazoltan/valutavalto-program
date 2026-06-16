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
import hu.puzzleir.valuta.repository.OwnCompanyRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.OwnCompany;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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
    private final OwnCompanyRepository ownCompanyRepository;
    private final GmailOAuthConfig gmailOAuthConfig;
    private final GoogleAuthorizationCodeFlow googleAuthorizationCodeFlow;
    private final HttpTransport googleHttpTransport;

    /**
     * Email fiók lekérdezése ID alapján.
     */
    public EmailAccount getAccountById(UUID accountId) {
        EmailAccount account = emailAccountRepository.findById(accountId)
                .orElseThrow(() -> new ResourceNotFoundException("Email fiók nem található: " + accountId));
        assertAccountInCallerCompany(account);
        return account;
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
        // Multi-tenant-safe: resolve companyId from security context
        UUID companyId = hu.puzzleir.valuta.security.SecurityUtils.getCurrentCompanyId();

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
                    // Multi-tenant-safe: company-scoped lookup
                    List<Branch> territoryBranches = branchRepository.findByCompanyIdAndVaultTerritoryId(companyId, vaultId);
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
                    // Multi-tenant-safe: company-scoped lookup
                    List<Branch> territoryBranches = branchRepository.findByCompanyIdAndVaultTerritoryId(companyId, vaultId);
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
            // Multi-tenant IDOR-védelem (F-7): a betöltött fiók a hívó cégéhez tartozzon-e
            // (FK branch/vaultTerritory/ownCompany/worker company-ja alapján), MIELŐTT módosítjuk.
            assertAccountInCallerCompany(account);
        } else {
            account = new EmailAccount();
        }

        // FK-k beállítása — mindig tisztítjuk az összeset, aztán a megfelelőt állítjuk
        account.setBranch(null);
        account.setVaultTerritory(null);
        account.setOwnCompany(null);
        account.setWorker(null);

        // Multi-tenant IDOR-védelem (F-7): az ÚJ FK-hozzárendelést is a hívó cégére kell validálni,
        // különben a fiók más cég branch/vaultTerritory/ownCompany/worker-éhez köthető.
        UUID callerCompanyId = SecurityUtils.getCurrentCompanyId();
        if (dto.getBranchId() != null) {
            if (!branchRepository.existsByIdAndCompanyId(dto.getBranchId(), callerCompanyId)) {
                throw new ResourceNotFoundException("Iroda nem található: " + dto.getBranchId());
            }
            hu.puzzleir.valuta.entity.Branch branch = new hu.puzzleir.valuta.entity.Branch();
            branch.setId(dto.getBranchId());
            account.setBranch(branch);
        } else if (dto.getVaultTerritoryId() != null) {
            VaultTerritory vt = vaultTerritoryRepository.findByIdAndCompanyId(dto.getVaultTerritoryId(), callerCompanyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Értéktári terület nem található: " + dto.getVaultTerritoryId()));
            account.setVaultTerritory(vt);
        } else if (dto.getOwnCompanyId() != null) {
            OwnCompany oc = ownCompanyRepository.findById(dto.getOwnCompanyId())
                    .orElseThrow(() -> new ResourceNotFoundException("Saját cég nem található: " + dto.getOwnCompanyId()));
            if (!callerCompanyId.equals(oc.getCompanyId())) {
                throw new ResourceNotFoundException("Saját cég nem található: " + dto.getOwnCompanyId());
            }
            account.setOwnCompany(oc);
        } else if (dto.getWorkerId() != null) {
            Worker worker = workerRepository.findByIdAndCompanyId(dto.getWorkerId(), callerCompanyId)
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
        // Multi-tenant IDOR-védelem (F-7): cross-tenant törlés tiltása.
        assertAccountInCallerCompany(account);
        log.info("Email fiók törlése: id={}, gmail={}", accountId, account.getGmailAddress());
        emailAccountRepository.delete(account);
    }

    /**
     * OAuth2 flow indítása — consent URL generálás.
     * @return Google OAuth consent URL (ide kell redirect-elni a user-t)
     */
    public String startOAuthFlow(UUID accountId) {
        // Ellenőrizzük, hogy létezik a fiók
        EmailAccount account = emailAccountRepository.findById(accountId)
                .orElseThrow(() -> new ResourceNotFoundException("Email fiók nem található: " + accountId));
        // Multi-tenant IDOR-védelem (F-7): cross-tenant OAuth-flow indítás tiltása
        // (más cég fiókjához token-kötés megakadályozása).
        assertAccountInCallerCompany(account);

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
     * Multi-tenant IDOR-védelem (F-7): a betöltött EmailAccount a hívó cégéhez tartozik-e.
     *
     * <p>Az EmailAccount entitásnak nincs direkt companyId-ja; a tenancy a kitöltött FK-n él
     * (branch / vaultTerritory / ownCompany / worker — pontosan 1). A FK company-ját a megfelelő
     * repository-val ellenőrizzük (saját tranzakcióban), így a metódus a nem-tranzakciós belépési
     * pontokban (getAccountById, startOAuthFlow) is biztonságos — csak a FK @Id-ját olvassuk,
     * ami nem triggereli a lazy proxy inicializálását.</p>
     *
     * <p>Cross-tenant fiók -> ResourceNotFoundException (nem leak az erőforrás létezéséről).</p>
     */
    private void assertAccountInCallerCompany(EmailAccount account) {
        UUID callerCompanyId = SecurityUtils.getCurrentCompanyId();
        boolean inCompany = false;

        if (account.getBranch() != null && account.getBranch().getId() != null) {
            inCompany = branchRepository.existsByIdAndCompanyId(account.getBranch().getId(), callerCompanyId);
        } else if (account.getVaultTerritory() != null && account.getVaultTerritory().getId() != null) {
            inCompany = vaultTerritoryRepository
                    .findByIdAndCompanyId(account.getVaultTerritory().getId(), callerCompanyId).isPresent();
        } else if (account.getOwnCompany() != null && account.getOwnCompany().getId() != null) {
            inCompany = ownCompanyRepository.findById(account.getOwnCompany().getId())
                    .map(oc -> callerCompanyId.equals(oc.getCompanyId()))
                    .orElse(false);
        } else if (account.getWorker() != null && account.getWorker().getId() != null) {
            inCompany = workerRepository
                    .findByIdAndCompanyId(account.getWorker().getId(), callerCompanyId).isPresent();
        }

        if (!inCompany) {
            throw new ResourceNotFoundException("Email fiók nem található: " + account.getId());
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
