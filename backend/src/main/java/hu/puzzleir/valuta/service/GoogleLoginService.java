package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
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
        return loginWithGoogle(idToken, httpRequest, null);
    }

    public LoginResponseDto loginWithGoogle(String idToken, HttpServletRequest httpRequest, String appMode) {
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

        // 5. Operativ szerepkor (V57) — egyezo logika a WorkerService.login-nal
        List<String> roleCodes = workerRoleService.getRoleCodesForWorker(worker.getId());
        String activeRole = null;
        List<String> permissions = List.of();
        boolean roleSelectionRequired = false;

        if (roleCodes.size() == 1) {
            activeRole = roleCodes.get(0);
            permissions = workerRoleService.getPermissionCodesForRole(activeRole);
        } else if (roleCodes.size() > 1) {
            roleSelectionRequired = true;
        }

        if (roleSelectionRequired
                && !AppModeRoleConstants.hasAnySelectableRoleForAppMode(roleCodes, appMode)) {
            throw new AuthenticationException("Nincs ebben a programban használható szerepköre.");
        }
        if (activeRole != null
                && !AppModeRoleConstants.isRoleSelectableForAppMode(activeRole, appMode)) {
            throw new AuthenticationException("Ez a szerepkör nem használható ebben a programban: " + activeRole);
        }

        // 6. JWT + Session
        String token = jwtTokenProvider.generateToken(worker, activeRole, permissions);
        String tokenId = jwtTokenProvider.getTokenIdFromToken(token);
        String clientIp = clientIpResolver.resolveClientIp(httpRequest);

        // Codex P1 PR #361 follow-up: legacy worker eseten `worker.getBranch()` lehet null,
        // de a `worker_session.branch_id` non-nullable. Ugyanaz a fallback minta mint
        // a `WorkerService.login` 435-444. soraban — ceg-szintu elso aktiv branch.
        Branch sessionBranch = worker.getBranch();
        if (sessionBranch == null) {
            sessionBranch = branchRepository.findByCompanyIdAndIsActiveTrue(worker.getCompany().getId())
                    .stream()
                    .findFirst()
                    .orElseGet(() -> branchRepository.findByCompanyId(worker.getCompany().getId())
                            .stream().findFirst().orElse(null));
            if (sessionBranch == null) {
                log.error("GOOGLE_LOGIN_NO_AVAILABLE_BRANCH workerCode={} companyId={}",
                        worker.getCode(), worker.getCompany().getId());
                throw new AuthenticationException("Nincs elerheto iroda a bejelentkezeshez!");
            }
        }

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
        worker.setGoogleLastLoginAt(LocalDateTime.now());
        workerRepository.save(worker);

        log.info("GOOGLE_LOGIN_SUCCESS workerCode={} subjectHash={} ip={}",
                worker.getCode(),
                safeLogHash(googleSubject),
                clientIp);

        // 7. validAppModes szamitas — egyezo logika a WorkerService.login-nal
        long expiresInMs = 86400000L;
        LocalDateTime expiresAt = LocalDateTime.now().plusSeconds(expiresInMs / 1000);

        // V181 + Sourcery+Copilot PR #361 follow-up: kozos AppModeRoleConstants util.
        // A "kamera" appMode logika is itt — a teruleti_vezeto + biztonsagi_vezeto canonical
        // role-ok "kamera" appMode-ot kapnak (NEM "full") — NEM ferhetnek a szerver-adminhoz.
        List<String> validAppModes = AppModeRoleConstants.computeValidAppModes(roleCodes, worker.getRole());

        return LoginResponseDto.builder()
                .token(token)
                .worker(WorkerDto.from(worker))
                .expiresIn(expiresInMs)
                .expiresAt(expiresAt.toString())
                .roles(roleCodes)
                .activeRole(activeRole)
                .permissions(permissions)
                .roleSelectionRequired(roleSelectionRequired)
                .passwordChangeRequired(false)  // Google loginban nincs jelszo-policy
                .validAppModes(validAppModes)
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
