package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.auth.VaultWorkerOptionDto;
import hu.puzzleir.valuta.dto.worker.WorkerDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerSession;
import hu.puzzleir.valuta.exception.AuthenticationException;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.repository.WorkerSessionRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.util.AppModeRoleConstants;
import hu.puzzleir.valuta.util.CentralModuleManifest;
import hu.puzzleir.valuta.util.ClientIpResolver;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Optional;

/**
 * Google OAuth dolgozoi belepes service (V178/V179, 2026-05-03).
 *
 * <p>Feladat:
 * <ol>
 *   <li>Google ID token validalas {@link GoogleIdTokenService}-szel.</li>
 *   <li>Whitelistes worker lookup {@link WorkerRepository#findGoogleLoginCandidatesByEmail}-szel.</li>
 *   <li>Worker aktiv/company/branch ellenorzes.</li>
 *   <li>Google `sub` binding — elsodleges login: subject mentes, kovetkezo loginok: mismatch tilalom.</li>
 *   <li>Sajat Valutavalto JWT generalas + WorkerSession + last_login_at frissites.</li>
 *   <li>HttpOnly refresh cookie kibocsatasa NEM itt — a controller hivja a {@link RefreshTokenService#issue}-t.</li>
 * </ol>
 *
 * <p>Audit-megfelelt kovetelmenyek (Google OAuth audit doc, 2026-05-03):
 * <ul>
 *   <li>NEM hivunk `https://oauth2.googleapis.com/tokeninfo`-t loginban (DoS-kockazat).</li>
 *   <li>NEM hozunk letre automatikusan workert (whitelist-only).</li>
 *   <li>Email canonicalizalas (lower + trim) a lookup elott.</li>
 *   <li>Subject binding mismatch -> 401 + audit log.</li>
 * </ul>
 *
 * <p>Ugyanazt a `LoginResponseDto`-t adja vissza, mint a {@link WorkerService#login} —
 * a frontend `handleLoginResponse` egyseges agon kezeli a role selection / appMode RBAC
 * / navigacio lepeseket.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class GoogleLoginService {

    private final GoogleIdTokenService googleIdTokenService;
    private final WorkerRepository workerRepository;
    private final WorkerSessionRepository sessionRepository;
    private final WorkerRoleService workerRoleService;
    private final JwtTokenProvider jwtTokenProvider;
    private final BranchRepository branchRepository;
    private final ClientIpResolver clientIpResolver;
    private final TotpService totpService;
    // FK-ÉRTÉKTÁR (V285): a kétlépcsős belépés jelszó-fázisához — lockout-újrahasználat + bcrypt match.
    private final WorkerService workerService;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;
    private final SessionBranchResolver sessionBranchResolver;

    @Value("${google.login.bind-sub-on-first-login:true}")
    private boolean bindSubOnFirstLogin;

    /**
     * Google login flow: validalt ID token -> matched whitelisted worker -> LoginResponseDto.
     *
     * @param idToken      Google CredentialResponse.credential ertekje
     * @param httpRequest  HTTP request (IP/User-Agent audit logoz)
     * @return  ugyanaz a LoginResponseDto, mint a jelszavas login (token, roles, validAppModes, ...)
     * @throws AuthenticationException ha a token invalid vagy a worker nem whitelisted/inaktiv/sub mismatch
     * @throws ConflictException       ha tobb worker is matchel ugyanazon canonical email-en
     *                                  (admin konfiguracios hiba)
     */
    public LoginResponseDto loginWithGoogle(String idToken, HttpServletRequest httpRequest) {
        return loginWithGoogle(idToken, httpRequest, null, false);
    }

    public LoginResponseDto loginWithGoogle(String idToken, HttpServletRequest httpRequest, String appMode) {
        return loginWithGoogle(idToken, httpRequest, appMode, false);
    }

    /**
     * @param supportsVaultWorkerSelection FK-ÉRTÉKTÁR (V285): ha a kliens támogatja a kétlépcsős
     *        értéktári belépést ÉS a Google-fiók intézményi (shared_account) ÉS van kiválasztható
     *        személyes worker → a metódus NEM ad végleges sessiont, hanem dolgozóválasztó-DTO-t
     *        (vaultWorkerSelectionRequired = true). Minden más esetben a korábbi viselkedés
     *        (intézményi worker sessionje) — így a régi kliensek nem törnek el.
     */
    public LoginResponseDto loginWithGoogle(String idToken, HttpServletRequest httpRequest,
                                            String appMode, boolean supportsVaultWorkerSelection) {
        // 1. Google ID token validacio
        GoogleIdTokenService.VerifiedGoogleIdentity identity;
        try {
            identity = googleIdTokenService.verify(idToken);
        } catch (GoogleIdTokenService.GoogleTokenInvalidException ex) {
            log.warn("GOOGLE_LOGIN_DENIED_INVALID_TOKEN code={}", ex.getCode());
            throw new AuthenticationException("Google bejelentkezés sikertelen.");
        }

        // 2. Whitelistes worker lookup canonical email + google_login_enabled-re
        String canonicalEmail = identity.email();  // mar canonicalizalva (lower+trim) a service-ben
        List<Worker> candidates = workerRepository.findGoogleLoginCandidatesByEmail(canonicalEmail);

        if (candidates.isEmpty()) {
            log.warn("GOOGLE_LOGIN_DENIED_NOT_WHITELISTED emailHash={}",
                    safeLogHash(canonicalEmail));
            throw new AuthenticationException("Google fiók nincs engedélyezve ehhez a rendszerhez.");
        }
        if (candidates.size() > 1) {
            // V178-ban a partial unique index per-company-scope (uq_worker_company_google_email_lower).
            // 2+ candidate cross-company eseten lehetne — ezt a controller config error-kent kezeli
            // (a request NEM tartalmaz companyCode-ot, igy nem tudna disambiguate-elni).
            // TODO: ha multi-company login flow keszul, companyCode + scoped lookup lesz.
            log.error("GOOGLE_LOGIN_CONFIG_ERROR multiple_candidates count={} emailHash={}",
                    candidates.size(), safeLogHash(canonicalEmail));
            throw new ConflictException(
                    "Tobb dolgozo van regisztralva ezzel a Google email-lel — admin konfiguracios hiba.");
        }
        Worker worker = candidates.get(0);

        // 3. Worker aktiv ellenorzes
        if (!Boolean.TRUE.equals(worker.getActive())) {
            log.warn("GOOGLE_LOGIN_DENIED_INACTIVE_WORKER workerCode={}", worker.getCode());
            throw new AuthenticationException("Ez a dolgozó inaktív.");
        }

        // 4. Sub-binding
        String googleSubject = identity.subject();
        if (worker.getGoogleSubject() == null) {
            if (!bindSubOnFirstLogin) {
                log.warn("GOOGLE_LOGIN_DENIED_SUB_NOT_BOUND workerCode={}", worker.getCode());
                throw new AuthenticationException(
                        "A Google fiok meg nincs hozzakotve a dolgozohoz. Adminnak elobb engedelyezni kell.");
            }
            // Codex P1 PR #361 follow-up: ellenorizzuk hogy a subject MEG NINCS lefoglalva
            // masik worker-hez (uq_worker_google_subject partial unique index megvedi DB-szinten,
            // de a kontrollalt 401/409 valasz jobb mint egy DataIntegrityViolation 500).
            // Ez akkor fordulhat elo, ha a kovetkezo szekvencia tortenik:
            //   1. Admin kotott egy subject-et az X workerhez,
            //   2. Admin ujra-allitotta az emailt egy Y workerre,
            //   3. Y worker most elsokor lep be -> a subject mar foglal X-re.
            java.util.Optional<Worker> alreadyBound = workerRepository.findByGoogleSubject(googleSubject);
            if (alreadyBound.isPresent() && !alreadyBound.get().getId().equals(worker.getId())) {
                log.warn("GOOGLE_LOGIN_DENIED_SUB_ALREADY_BOUND_TO_OTHER currentWorker={} otherWorker={} subjectHash={}",
                        worker.getCode(), alreadyBound.get().getCode(),
                        safeLogHash(googleSubject));
                throw new AuthenticationException(
                        "Ez a Google fiok mar masik dolgozohoz van kotve. Kerd az admin segitseget.");
            }
            log.info("GOOGLE_LOGIN_FIRST_BIND workerCode={} subjectHash={}",
                    worker.getCode(), safeLogHash(googleSubject));
            worker.setGoogleSubject(googleSubject);
            worker.setGoogleLinkedAt(LocalDateTime.now());
        } else if (!worker.getGoogleSubject().equals(googleSubject)) {
            log.warn("GOOGLE_LOGIN_DENIED_SUB_MISMATCH workerCode={} expectedHash={} gotHash={}",
                    worker.getCode(),
                    safeLogHash(worker.getGoogleSubject()),
                    safeLogHash(googleSubject));
            throw new AuthenticationException(
                    "A Google fiok azonositoja nem egyezik. Lepj be a regi fiokkal vagy kerd az admin segitseget.");
        }

        // FK-ÉRTÉKTÁR (V285): intézményi (közös) Google-fiók → kétlépcsős belépés.
        // Ha a kliens támogatja (capability-flag) ÉS a fiók shared_account ÉS van kiválasztható
        // személyes worker → NEM adunk végleges sessiont, hanem dolgozóválasztót. Egyébként
        // fallback: az intézményi worker sessionje (régi viselkedés — nincs kizárás akkor sem,
        // ha még nincs felvett személyes worker, vagy régi kliens lép be).
        if (supportsVaultWorkerSelection && Boolean.TRUE.equals(worker.getSharedAccount())) {
            LoginResponseDto selection = buildVaultWorkerSelectionOrNull(worker);
            if (selection != null) {
                log.info("GOOGLE_VAULT_SELECTION_REQUIRED institutionalWorker={} candidateCount={}",
                        worker.getCode(), selection.getVaultWorkers().size());
                return selection;
            }
            log.info("GOOGLE_VAULT_NO_PERSONAL_WORKERS_FALLBACK institutionalWorker={}", worker.getCode());
        }

        // Végleges session: nem-intézményi Google login VAGY intézményi fallback.
        return buildSessionResponse(worker, appMode, httpRequest, true);
    }

    /**
     * FK-ÉRTÉKTÁR (V285): ha az intézményi értéktár-fiók alatt van legalább egy kiválasztható
     * SZEMÉLYES (jelszavas, ertektar-szerepkörű) worker → dolgozóválasztó-DTO. Egyébként null
     * (a hívó ilyenkor az intézményi sessionre esik vissza — bootstrap, nincs kizárás).
     */
    private LoginResponseDto buildVaultWorkerSelectionOrNull(Worker institutional) {
        Branch branch = institutional.getBranch();
        if (branch == null) {
            return null;
        }
        List<Worker> candidates = workerRepository.findSelectableVaultWorkers(
                institutional.getCompany().getId(), branch.getId());
        // Csak az ertektar canonical role-lal rendelkező személyes workerek választhatók.
        List<VaultWorkerOptionDto> options = candidates.stream()
                .filter(w -> workerRoleService.getRoleCodesForWorker(w.getId()).contains("ertektar"))
                .map(w -> VaultWorkerOptionDto.builder().id(w.getId()).name(w.getName()).build())
                .toList();
        if (options.isEmpty()) {
            return null;
        }
        return LoginResponseDto.builder()
                .vaultWorkerSelectionRequired(true)
                .vaultWorkers(options)
                .vaultBranchName(branch.getName())
                .roleSelectionRequired(false)
                .build();
    }

    /**
     * FK-ÉRTÉKTÁR (V285): a kétlépcsős értéktári belépés 2. fázisa. A Google ID token újra-
     * verifikálva azonosítja az intézményi fiókot; a kiválasztott személyes worker a fiók
     * branch-e alá kell tartozzon, ertektar role-lal és jelszóval. Helyes jelszó után végleges
     * session a SZEMÉLYES workerrel. Lockout: a WorkerService közös számlálóján (5/15 perc).
     */
    public LoginResponseDto selectVaultWorker(String idToken, Long personalWorkerId,
                                              String password, HttpServletRequest httpRequest,
                                              String appMode) {
        // 1. Google ID token újra-verifikáció → intézményi fiók
        GoogleIdTokenService.VerifiedGoogleIdentity identity;
        try {
            identity = googleIdTokenService.verify(idToken);
        } catch (GoogleIdTokenService.GoogleTokenInvalidException ex) {
            log.warn("GOOGLE_VAULT_SELECT_DENIED_INVALID_TOKEN code={}", ex.getCode());
            throw new AuthenticationException("Google bejelentkezés sikertelen.");
        }

        List<Worker> candidates = workerRepository.findGoogleLoginCandidatesByEmail(identity.email());
        if (candidates.size() != 1) {
            log.warn("GOOGLE_VAULT_SELECT_DENIED_CANDIDATES count={}", candidates.size());
            throw new AuthenticationException("Google fiók nincs engedélyezve ehhez a rendszerhez.");
        }
        Worker institutional = candidates.get(0);
        if (!Boolean.TRUE.equals(institutional.getSharedAccount())) {
            log.warn("GOOGLE_VAULT_SELECT_DENIED_NOT_SHARED workerCode={}", institutional.getCode());
            throw new AuthenticationException("Ez a Google fiók nem értéktári közös fiók.");
        }
        // Sub-binding védelem: a token subject egyezzen az intézményi fiókéval (ha már kötött).
        if (institutional.getGoogleSubject() != null
                && !institutional.getGoogleSubject().equals(identity.subject())) {
            log.warn("GOOGLE_VAULT_SELECT_DENIED_SUB_MISMATCH workerCode={}", institutional.getCode());
            throw new AuthenticationException("A Google fiók azonosítója nem egyezik.");
        }
        Branch institutionalBranch = institutional.getBranch();
        if (institutionalBranch == null) {
            throw new AuthenticationException("Az értéktár fiókhoz nincs iroda rendelve.");
        }

        // 2. Személyes worker betöltése + validáció (generikus hibaüzenet az id-enumeráció ellen).
        Worker personal = workerRepository.findByIdWithCompanyAndBranch(personalWorkerId)
                .orElseThrow(() -> new AuthenticationException("Érvénytelen dolgozó vagy jelszó."));
        boolean validSelection =
                personal.getCompany().getId().equals(institutional.getCompany().getId())
                && personal.getBranch() != null
                && personal.getBranch().getId().equals(institutionalBranch.getId())
                && Boolean.TRUE.equals(personal.getActive())
                && !Boolean.TRUE.equals(personal.getSharedAccount())
                // Copilot: a Google-loginra szánt workereket NE engedjük a jelszavas 2. fázison —
                // egyezzen a findSelectableVaultWorkers query szűrésével (googleLoginEnabled=false).
                && !Boolean.TRUE.equals(personal.getGoogleLoginEnabled())
                && personal.getPasswordHash() != null
                && workerRoleService.getRoleCodesForWorker(personal.getId()).contains("ertektar");
        if (!validSelection) {
            log.warn("GOOGLE_VAULT_SELECT_DENIED_INVALID_WORKER personalId={} institutional={}",
                    personalWorkerId, institutional.getCode());
            throw new AuthenticationException("Érvénytelen dolgozó vagy jelszó.");
        }

        // 3. Lockout + jelszó-ellenőrzés (közös WorkerService számláló — nincs duplikált map).
        String loginKey = institutional.getCompany().getCode() + ":" + personal.getCode();
        workerService.assertVaultLoginNotLocked(loginKey);
        if (!passwordEncoder.matches(password, personal.getPasswordHash())) {
            workerService.recordVaultFailedAttempt(loginKey);
            log.warn("GOOGLE_VAULT_SELECT_BAD_PASSWORD workerCode={}", personal.getCode());
            throw new AuthenticationException("Érvénytelen dolgozó vagy jelszó.");
        }
        workerService.clearVaultLoginAttempts(loginKey);

        log.info("GOOGLE_VAULT_SELECT_SUCCESS personalWorker={} institutional={}",
                personal.getCode(), institutional.getCode());

        // 4. Végleges session a SZEMÉLYES workerrel (a Google last-login NEM frissül rajta,
        //    mert jelszóval lépett be a 2. fázisban).
        return buildSessionResponse(personal, appMode, httpRequest, false);
    }

    /**
     * FK-ÉRTÉKTÁR (V285): a végleges JWT + WorkerSession + LoginResponseDto felépítése egy már
     * azonosított workerhez. Használt: intézményi fallback / nem-intézményi Google login
     * (updateGoogleLastLogin = true), illetve a kétlépcsős személyes belépés
     * (updateGoogleLastLogin = false). Megegyezik a korábbi 5-7. lépéssel.
     */
    private LoginResponseDto buildSessionResponse(Worker worker, String appMode,
                                                  HttpServletRequest httpRequest,
                                                  boolean updateGoogleLastLogin) {
        // 5. Operativ szerepkor (V57)
        List<String> roleCodes = workerRoleService.getRoleCodesForWorker(worker.getId());
        if (AppModeRoleConstants.isLegacyWorkerRoleDeniedForAppMode(
                roleCodes, worker.getRole(), appMode)) {
            throw new AuthenticationException(AppModeRoleConstants.legacyWorkerRoleDeniedMessage(worker.getRole()));
        }

        String activeRole = null;
        List<String> permissions = List.of();
        boolean roleSelectionRequired = false;

        if (roleCodes.size() == 1) {
            activeRole = roleCodes.get(0);
            permissions = workerRoleService.getPermissionCodesForRole(activeRole);
        } else if (roleCodes.size() > 1) {
            roleSelectionRequired = true;
        }

        String appModeValidationError = AppModeRoleConstants.validateLoginRolesForAppMode(
                roleCodes, activeRole, roleSelectionRequired, appMode);
        if (appModeValidationError != null) {
            throw new AuthenticationException(appModeValidationError);
        }
        List<String> responseRoleCodes = roleSelectionRequired
                ? AppModeRoleConstants.selectableRolesForAppMode(roleCodes, appMode)
                : roleCodes;

        Branch sessionBranch = sessionBranchResolver.resolveSessionBranch(worker, activeRole);

        // FK-076: canonical szerepkorok appMode-ra szurve -> ROLE_* authority a JwtAuthenticationFilterben.
        List<String> grantedRoles = AppModeRoleConstants.grantedRolesForAppMode(roleCodes, activeRole, appMode);

        // 6. JWT + Session
        String token = jwtTokenProvider.generateToken(worker, sessionBranch, activeRole, permissions, grantedRoles);
        String tokenId = jwtTokenProvider.getTokenIdFromToken(token);
        String clientIp = clientIpResolver.resolveClientIp(httpRequest);

        WorkerSession session = WorkerSession.builder()
                .company(worker.getCompany())
                .worker(worker)
                .branch(sessionBranch)
                .loginAt(LocalDateTime.now())
                .ipAddress(clientIp)
                .userAgent(httpRequest.getHeader("User-Agent"))
                .tokenId(tokenId)
                .build();
        sessionRepository.save(session);

        worker.setLastLoginAt(LocalDateTime.now());
        if (updateGoogleLastLogin) {
            worker.setGoogleLastLoginAt(LocalDateTime.now());
        }
        workerRepository.save(worker);

        // CodeQL log-injection: a clientIp (X-Forwarded-For fejlécből) user-controlled, ezért NEM
        // logoljuk (a WorkerSession.ipAddress amúgy is rögzíti audit-célból). Csak a DB-forrású
        // workerCode kerül a logba.
        log.info("GOOGLE_SESSION_BUILT workerCode={}", worker.getCode());

        // 7. validAppModes
        long expiresInMs = 86400000L;
        LocalDateTime expiresAt = LocalDateTime.now().plusSeconds(expiresInMs / 1000);
        List<String> validAppModes = AppModeRoleConstants.computeValidAppModes(roleCodes, worker.getRole());
        List<String> centralModules = CentralModuleManifest.allowedModules(roleCodes, activeRole, worker.getRole());

        return LoginResponseDto.builder()
                .token(token)
                .worker(WorkerDto.from(worker, sessionBranch))
                .expiresIn(expiresInMs)
                .expiresAt(expiresAt.toString())
                .roles(responseRoleCodes)
                .activeRole(activeRole)
                .permissions(permissions)
                .roleSelectionRequired(roleSelectionRequired)
                .passwordChangeRequired(false)  // Google loginban nincs jelszo-policy
                .mfaRequired(totpService.isMfaRequired(worker.getId()))
                .validAppModes(validAppModes)
                .centralModules(centralModules)
                .build();
    }

    /**
     * Read-only check: van-e ezzel a canonical email-lel whitelistes, aktiv worker.
     * Test-celokra hasznalando, NEM produkcios login utvonalon.
     */
    @Transactional(readOnly = true)
    public Optional<Worker> findActiveWhitelistedWorker(String email) {
        if (email == null || email.isBlank()) return Optional.empty();
        String canonical = email.trim().toLowerCase(Locale.ROOT);
        List<Worker> candidates = workerRepository.findGoogleLoginCandidatesByEmail(canonical);
        return candidates.stream()
                .filter(w -> Boolean.TRUE.equals(w.getActive()))
                .findFirst();
    }

    /**
     * Copilot PR #361 follow-up #3: PII visszafejt-hetoseg ellen SHA-256 csonkolt hex hash.
     * A {@link String#hashCode()} csak 32-bit, brute-force-olhato tipikus emailekre logokbol.
     * Itt 80-bit (10 byte) SHA-256 prefix elegendo audit-azonosito-szempontbol, NEM rekonstrual-hato.
     */
    static String safeLogHash(String value) {
        if (value == null) return "(null)";
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(value.getBytes(StandardCharsets.UTF_8));
            byte[] prefix = new byte[10];
            System.arraycopy(digest, 0, prefix, 0, 10);
            return HexFormat.of().formatHex(prefix);
        } catch (NoSuchAlgorithmException ex) {
            // SHA-256 minden JDK-ban elerheto — ez nem fog elofordulni
            return "(sha256-unavailable)";
        }
    }
}
