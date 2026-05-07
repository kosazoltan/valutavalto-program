package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.worker.ChangePasswordDto;
import hu.puzzleir.valuta.dto.worker.CreateWorkerDto;
import hu.puzzleir.valuta.dto.worker.UpdateWorkerDto;
import hu.puzzleir.valuta.dto.worker.WorkerDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.AuthenticationException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.repository.WorkerRoleAssignmentRepository;
import hu.puzzleir.valuta.repository.WorkerRoleDefinitionRepository;
import hu.puzzleir.valuta.repository.WorkerRolePermissionRepository;
import hu.puzzleir.valuta.repository.WorkerSessionRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.AppModeRoleConstants;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.Normalizer;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * Worker service - business logic multi-tenant supporttal.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
public class WorkerService {

    private final WorkerRepository workerRepository;
    private final WorkerSessionRepository sessionRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final WorkerRoleAssignmentRepository roleAssignmentRepository;
    private final WorkerRolePermissionRepository rolePermissionRepository;
    private final TokenBlacklistService tokenBlacklistService;
    // v2.4.5 (B6): branchId override engedélyezésének ellenőrzéséhez.
    private final WorkerBranchAccessService workerBranchAccessService;

    // HIGH FIX #16: Brute force védelem — max 5 sikertelen próba, utána 15 perc lock
    private static final int MAX_FAILED_ATTEMPTS = 5;
    private static final long LOCK_DURATION_MS = 15 * 60 * 1000L; // 15 perc
    // Dummy BCrypt hash for constant-time comparison when worker not found (timing side-channel prevention)
    private static final String DUMMY_BCRYPT_HASH = "$2b$10$dEHXvZQsnLDxcoSwKmiQ9.P38TXsoTTvQwX6arN1wh076V1dEt0ie";

    /**
     * Brute force state: key = "companyCode:workerCode", value = [failedCount, lockUntilMs]
     */
    private static final Map<String, long[]> loginAttempts = new ConcurrentHashMap<>();
    
    /**
     * Worker létrehozás
     */
    public WorkerDto createWorker(CreateWorkerDto dto) {
        // Company validation
        Company company = companyRepository.findById(dto.getCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található: " + dto.getCompanyId()));
        
        // Branch validation (ugyanazon company-hoz tartozik?)
        Branch branch = branchRepository.findById(dto.getBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + dto.getBranchId()));
        
        if (!branch.getCompany().getId().equals(dto.getCompanyId())) {
            throw new ValidationException("Áz iroda nem tartozik ehhez a céghez!");
        }
        
        // Code uniqueness (company-n belül)
        if (workerRepository.existsByCompanyIdAndCode(dto.getCompanyId(), dto.getCode())) {
            throw new ValidationException("Ez a pénztáros kód már létezik ebben a cégben: " + dto.getCode());
        }
        
        // Worker entity build
        Worker worker = Worker.builder()
                .company(company)
                .code(dto.getCode())
                .name(dto.getName())
                .passwordHash(passwordEncoder.encode(dto.getPassword()))
                .role(dto.getRole())
                .branch(branch)
                .active(true)
                .phone(dto.getPhone())
                .email(dto.getEmail())
                .otpUserId(dto.getOtpUserId())
                .otpEnabled(dto.getOtpEnabled() != null ? dto.getOtpEnabled() : false)
                .passwordChangedAt(LocalDateTime.now())
                .build();
        
        Worker saved = workerRepository.save(worker);
        return WorkerDto.from(saved);
    }
    
    /**
     * Worker módosítás
     */
    public WorkerDto updateWorker(Long id, UpdateWorkerDto dto) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        
        Worker worker = workerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + id));
        
        // Multi-tenant check
        if (!worker.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }
        
        // Update fields (csak a nem-null értékek)
        if (dto.getName() != null) {
            worker.setName(dto.getName());
        }
        if (dto.getRole() != null) {
            // Csak ADMIN vagy MANAGER változtathat role-t
            if (!SecurityUtils.isAdmin() && !SecurityUtils.getCurrentRole().equals("MANAGER")) {
                throw new ValidationException("Nincs jogosultsága szerepkör módosításhoz!");
            }
            worker.setRole(dto.getRole());
        }
        if (dto.getBranchId() != null) {
            Branch branch = branchRepository.findById(dto.getBranchId())
                    .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + dto.getBranchId()));
            
            if (!branch.getCompany().getId().equals(companyId)) {
                throw new ValidationException("Az iroda nem tartozik ehhez a céghez!");
            }
            worker.setBranch(branch);
        }
        if (dto.getPhone() != null) {
            worker.setPhone(dto.getPhone());
        }
        if (dto.getEmail() != null) {
            worker.setEmail(dto.getEmail());
        }
        if (dto.getActive() != null) {
            worker.setActive(dto.getActive());
        }
        if (dto.getOtpUserId() != null) {
            worker.setOtpUserId(dto.getOtpUserId());
        }
        if (dto.getOtpEnabled() != null) {
            worker.setOtpEnabled(dto.getOtpEnabled());
        }
        
        Worker updated = workerRepository.save(worker);
        return WorkerDto.from(updated);
    }
    
    /**
     * Jelszóváltoztatás
     */
    public void changePassword(Long workerId, ChangePasswordDto dto) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + workerId));
        
        // Multi-tenant check
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (!worker.getCompany().getId().equals(currentCompanyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }
        
        // Régi jelszó ellenőrzés
        if (!passwordEncoder.matches(dto.getOldPassword(), worker.getPasswordHash())) {
            throw new ValidationException("Hibás régi jelszó!");
        }
        
        // Új jelszó beállítás
        worker.setPasswordHash(passwordEncoder.encode(dto.getNewPassword()));
        worker.setPasswordChangedAt(LocalDateTime.now());
        
        workerRepository.save(worker);
    }
    
    /**
     * Worker inaktiválás
     */
    public void deactivateWorker(Long id) {
        Worker worker = workerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + id));
        
        // Multi-tenant check
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!worker.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }
        
        worker.setActive(false);
        workerRepository.save(worker);
    }
    
    /**
     * Worker aktiválás
     */
    public void activateWorker(Long id) {
        Worker worker = workerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + id));
        
        // Multi-tenant check
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!worker.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }
        
        worker.setActive(true);
        workerRepository.save(worker);
    }
    
    /**
     * Worker keresés ID alapján
     */
    @Transactional(readOnly = true)
    public WorkerDto findById(Long id) {
        Worker worker = workerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + id));

        // Multi-tenant check
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!worker.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }

        return WorkerDto.from(worker);
    }

    /**
     * Worker entity lekérése az aktuális felhasználóhoz
     */
    @Transactional(readOnly = true)
    public Worker getCurrentWorker() {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        if (workerId == null) {
            throw new ValidationException("Nincs bejelentkezett felhasználó!");
        }
        return workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + workerId));
    }

    /**
     * Worker entity lekérése ID alapján
     */
    @Transactional(readOnly = true)
    public Worker getWorkerEntity(Long id) {
        Worker worker = workerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + id));

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!worker.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }

        return worker;
    }
    
    /**
     * Company összes dolgozója
     */
    @Transactional(readOnly = true)
    public List<WorkerDto> findAllByCompany() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return workerRepository.findByCompanyId(companyId).stream()
                .map(WorkerDto::from)
                .collect(Collectors.toList());
    }
    
    /**
     * Aktív dolgozók
     */
    @Transactional(readOnly = true)
    public List<WorkerDto> findActiveWorkers() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return workerRepository.findByCompanyIdAndActiveTrue(companyId).stream()
                .map(WorkerDto::from)
                .collect(Collectors.toList());
    }
    
    /**
     * Dolgozók egy irodában
     */
    @Transactional(readOnly = true)
    public List<WorkerDto> findByBranch(UUID branchId) {
        // Branch létezés + multi-tenant check
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!branch.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez az irodához!");
        }
        
        return workerRepository.findActiveWorkersByBranch(branchId).stream()
                .map(WorkerDto::from)
                .collect(Collectors.toList());
    }
    
    /**
     * Login — HIGH FIX #16: Brute force védelemmel (max 5 sikertelen, 15 perc lock).
     */
    public LoginResponseDto login(LoginRequestDto dto, String ipAddress, String userAgent) {
        String normalizedCompanyCode = normalizeCode(dto.getCompanyCode());
        String normalizedWorkerCode = normalizeCode(dto.getWorkerCode());

        // HIGH FIX #16: Brute force ellenőrzés ELŐSZÖR
        String loginKey = normalizedCompanyCode + ":" + normalizedWorkerCode;
        checkBruteForceLock(loginKey);

        // Company keresés
        Company company = resolveCompanyForLogin(normalizedCompanyCode)
                .orElseThrow(() -> new AuthenticationException("Hibás cégkód!"));
        
        // Worker keresés (timing-safe: dummy BCrypt match ha nem létezik → konstans válaszidő)
        Optional<Worker> workerOpt = resolveWorkerForLogin(company, normalizedWorkerCode);
        if (workerOpt.isEmpty()) {
            // Dummy BCrypt match a timing side-channel ellen (F-04 security fix)
            passwordEncoder.matches(dto.getPassword(), DUMMY_BCRYPT_HASH);
            recordFailedAttempt(loginKey);
            throw new AuthenticationException("Hibás pénztáros kód vagy jelszó!");
        }
        Worker worker = workerOpt.get();
        
        // Aktív check (Boolean.TRUE.equals to prevent NPE on null active)
        if (!Boolean.TRUE.equals(worker.getActive())) {
            throw new AuthenticationException("Ez a pénztáros inaktív!");
        }
        
        // Jelszó check
        if (!passwordEncoder.matches(dto.getPassword(), worker.getPasswordHash())) {
            recordFailedAttempt(loginKey);
            throw new AuthenticationException("Hibás pénztáros kód vagy jelszó!");
        }

        // Sikeres login → reset counter
        loginAttempts.remove(loginKey);
        
        // Branch check (ha megadva)
        // v2.4.6 (B6 — Codex P1 #331 privilege-escalation fix):
        // A SetupWizard branch-választás esetén SZIGORÚAN ellenőrizzük a hozzáférést.
        // Két érvényes út a kért branch-hez:
        //  (1) worker_branch_access tartalmaz egy explicit (workerId, branchId) párt → OK
        //  (2) a kért branchId == worker.branchId (default branch, legacy 1:1) → OK
        // Egyéb esetben AuthenticationException (privilege escalation prevention).
        // A v2.4.5 backward-compat fallback HIBÁS volt: ha listBranches() üres, akkor
        // ANY branchId-t engedte a workernek a saját cégen belül — Codex P1 #331.
        if (dto.getBranchId() != null) {
            Branch branch = branchRepository.findById(dto.getBranchId())
                    .orElseThrow(() -> new ValidationException("Hibás iroda ID!"));

            if (!branch.getCompany().getId().equals(company.getId())) {
                throw new ValidationException("Az iroda nem tartozik ehhez a céghez!");
            }

            UUID requestedBranchId = branch.getId();
            UUID defaultBranchId = worker.getBranch() != null ? worker.getBranch().getId() : null;
            boolean isDefaultBranch = defaultBranchId != null && defaultBranchId.equals(requestedBranchId);
            boolean hasExplicitAccess = workerBranchAccessService.hasAccess(worker.getId(), requestedBranchId);

            if (!isDefaultBranch && !hasExplicitAccess) {
                throw new AuthenticationException(
                        "Nincs jogosultsága ehhez az irodához (worker_branch_access).");
            }

            worker.setBranch(branch);
        }
        
        // V57: Operatív szerepkör keresés
        List<WorkerRoleAssignment> roleAssignments = roleAssignmentRepository.findByWorkerId(worker.getId());
        List<String> roleCodes = roleAssignments.stream()
                .map(ra -> ra.getRoleDef().getCode())
                .collect(Collectors.toList());

        // Ha 0 vagy 1 role van → automatikus belépés azzal
        String activeRole = null;
        List<String> permissions = List.of();
        boolean roleSelectionRequired = false;

        if (roleCodes.size() == 1) {
            activeRole = roleCodes.get(0);
            WorkerRoleDefinition roleDef = roleAssignments.get(0).getRoleDef();
            permissions = rolePermissionRepository.findByRoleDefIdWithPermission(roleDef.getId()).stream()
                    .map(wrp -> wrp.getPermission().getCode())
                    .collect(Collectors.toList());
        } else if (roleCodes.size() > 1) {
            // Több role → a frontend-nek kell választania
            roleSelectionRequired = true;
        }
        // Ha 0 role → legacy mode, nincs operatív role (backward compat)

        if (roleSelectionRequired
                && !AppModeRoleConstants.hasAnySelectableRoleForAppMode(roleCodes, dto.getAppMode())) {
            throw new AuthenticationException("Nincs ebben a programban használható szerepköre.");
        }
        if (activeRole != null
                && !AppModeRoleConstants.isRoleSelectableForAppMode(activeRole, dto.getAppMode())) {
            throw new AuthenticationException("Ez a szerepkör nem használható ebben a programban: " + activeRole);
        }

        // JWT token generálás
        String token = jwtTokenProvider.generateToken(worker, activeRole, permissions);
        String tokenId = jwtTokenProvider.getTokenIdFromToken(token);
        
        // Session tracking
        // BUGFIX: worker.getBranch() may be null → use company's first active branch as fallback
        Branch sessionBranch = worker.getBranch();
        if (sessionBranch == null) {
            sessionBranch = branchRepository.findByCompanyIdAndIsActiveTrue(company.getId()).stream()
                    .findFirst()
                    .orElseGet(() -> branchRepository.findByCompanyId(company.getId()).stream().findFirst().orElse(null));
            
            if (sessionBranch == null) {
                throw new ValidationException("Nincs elérhető iroda a bejelentkezéshez!");
            }
        }
        
        WorkerSession session = WorkerSession.builder()
                .company(company)
                .worker(worker)
                .branch(sessionBranch)
                .loginAt(LocalDateTime.now())
                .ipAddress(ipAddress)
                .userAgent(userAgent)
                .tokenId(tokenId)
                .build();
        
        sessionRepository.save(session);
        
        // Last login frissítés
        worker.setLastLoginAt(LocalDateTime.now());
        workerRepository.save(worker);
        
        // Calculate expiration time
        long expiresInMs = 86400000L; // 24 óra millisec
        LocalDateTime expiresAt = LocalDateTime.now().plusSeconds(expiresInMs / 1000);

        // v2.1.4 + V181: kozos AppModeRoleConstants util — "kamera" appMode is benne
        // (teruleti_vezeto + biztonsagi_vezeto -> kamera, NEM full)
        List<String> validAppModes = AppModeRoleConstants.computeValidAppModes(roleCodes, worker.getRole());

        return LoginResponseDto.builder()
                .token(token)
                .worker(WorkerDto.from(worker))
                .expiresIn(expiresInMs)
                .expiresAt(expiresAt.toString()) // ISO format for frontend
                .roles(roleCodes)
                .activeRole(activeRole)
                .permissions(permissions)
                .roleSelectionRequired(roleSelectionRequired)
                .passwordChangeRequired(worker.getPasswordChangedAt() == null)
                .validAppModes(validAppModes)
                .build();
    }
    
    /**
     * Logout — session bezárás + token blacklisting.
     *
     * @param jwtToken  Az aktuális JWT token (ha elérhető) — blacklisting-hez
     */
    public void logout(String jwtToken) {
        // 🔴 NPE védelem: ha a SecurityContext üres (blacklisted token),
        // a workerId-t a JWT-ből nyerjük ki
        Long workerId;
        try {
            workerId = SecurityUtils.getCurrentWorkerId();
        } catch (Exception e) {
            // SecurityContext üres → workerId kinyerése tokenből
            workerId = jwtToken != null ? jwtTokenProvider.getWorkerIdFromToken(jwtToken) : null;
        }

        // Aktív session bezárás
        if (workerId != null) {
            final Long wId = workerId;
            sessionRepository.findByWorkerIdAndLogoutAtIsNull(wId)
                    .ifPresent(session -> {
                        session.setLogoutAt(LocalDateTime.now());
                        sessionRepository.save(session);
                    });
        }

        // 🔴 Token blacklisting — a JWT tokenId-t visszavonjuk
        if (jwtToken != null) {
            try {
                String tokenId = jwtTokenProvider.getTokenIdFromToken(jwtToken);
                LocalDateTime expiresAt = LocalDateTime.now().plusHours(24);
                tokenBlacklistService.blacklistToken(tokenId, workerId, "LOGOUT", expiresAt);
            } catch (Exception e) {
                // Ha a token parse sikertelen, nem gond — a session már lezárva
            }
        }
    }

    /**
     * Logout — backwards compatible (token nélkül).
     */
    public void logout() {
        logout(null);
    }

    // ============ HIGH FIX #16: BRUTE FORCE HELPER METHODS ============

    /**
     * Ellenőrzi, hogy a login kulcs lockolt-e.
     */
    private void checkBruteForceLock(String loginKey) {
        long[] state = loginAttempts.get(loginKey);
        if (state != null && state[0] >= MAX_FAILED_ATTEMPTS) {
            long lockUntil = state[1];
            if (System.currentTimeMillis() < lockUntil) {
                long remainingMinutes = (lockUntil - System.currentTimeMillis()) / 60000 + 1;
                throw new AuthenticationException(String.format(
                    "Túl sok sikertelen bejelentkezési kísérlet! Próbálja újra %d perc múlva.", remainingMinutes));
            }
            // Lock lejárt → reset
            loginAttempts.remove(loginKey);
        }
    }

    /**
     * Rögzíti a sikertelen bejelentkezési kísérletet.
     */
    private void recordFailedAttempt(String loginKey) {
        loginAttempts.compute(loginKey, (key, state) -> {
            if (state == null) {
                return new long[]{1, 0};
            }
            state[0]++;
            if (state[0] >= MAX_FAILED_ATTEMPTS) {
                state[1] = System.currentTimeMillis() + LOCK_DURATION_MS;
            }
            return state;
        });
    }

    /**
     * v2.5.4 (D opció): admin manuális unlock egy worker login-lockoutjára.
     * Eltávolítja a worker-t a {@code loginAttempts} ConcurrentHashMap-ból,
     * így a következő bejelentkezési próbálkozás 0 számolóval indul.
     *
     * @param workerId a unlock-olandó worker ID-je (Long)
     * @return ha volt aktív lockout: az eltelt másodpercek a lock vége előtt; egyébként 0
     * @throws ResourceNotFoundException ha a worker nem létezik
     */
    @Transactional(readOnly = true)
    public long unlockLogin(Long workerId) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker not found: " + workerId));

        String companyCode = worker.getCompany() != null ? worker.getCompany().getCode() : "";
        String workerCode = worker.getCode();
        String loginKey = normalizeCode(companyCode) + ":" + normalizeLoginCode(workerCode);

        long[] state = loginAttempts.remove(loginKey);
        if (state == null) {
            return 0L;
        }
        long lockUntil = state[1];
        long remainingMs = lockUntil > 0 ? Math.max(0L, lockUntil - System.currentTimeMillis()) : 0L;
        return remainingMs / 1000L;
    }

    private String normalizeCode(String value) {
        return value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
    }

    private String normalizeLoginCode(String value) {
        String base = normalizeCode(value);
        String ascii = Normalizer.normalize(base, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
        return ascii.replaceAll("[^A-Z0-9]", "");
    }

    private Optional<Company> resolveCompanyForLogin(String normalizedCompanyCode) {
        // Strict company code match — no single-tenant fallback (security: T07 fix)
        return companyRepository.findByCode(normalizedCompanyCode)
                .or(() -> companyRepository.findByCodeIgnoreCase(normalizedCompanyCode));
    }

    private Optional<Worker> resolveWorkerForLogin(Company company, String normalizedWorkerCode) {
        String normalizedInput = normalizeLoginCode(normalizedWorkerCode);

        Optional<Worker> directMatch = workerRepository.findByCompanyIdAndCode(company.getId(), normalizedWorkerCode)
                .or(() -> workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), normalizedWorkerCode));
        if (directMatch.isPresent()) {
            return directMatch;
        }

        List<Worker> companyWorkers = workerRepository.findByCompanyId(company.getId());
        Worker nameMatch = null;
        for (Worker worker : companyWorkers) {
            if (normalizeLoginCode(worker.getCode()).equals(normalizedInput)) {
                return Optional.of(worker);
            }
            if (nameMatch == null && normalizeLoginCode(worker.getName()).equals(normalizedInput)) {
                nameMatch = worker;
            }
        }
        return Optional.ofNullable(nameMatch);
    }
}
