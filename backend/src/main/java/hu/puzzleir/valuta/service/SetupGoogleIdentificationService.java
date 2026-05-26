package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.setup.SetupGoogleIdentifyRequestDto;
import hu.puzzleir.valuta.dto.setup.SetupGoogleIdentifyResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.AuthenticationException;
import hu.puzzleir.valuta.exception.ConflictException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.util.AppModeRoleConstants;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@Slf4j
public class SetupGoogleIdentificationService {

    private final GoogleIdTokenService googleIdTokenService;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final WorkerRoleService workerRoleService;
    private final AdminBootstrapService adminBootstrapService;

    @Transactional
    public SetupGoogleIdentifyResponseDto identify(SetupGoogleIdentifyRequestDto request) {
        // FIX 2026-05-26 (Bali/Szeged értéktár Google-login regresszió + Codex P1 security):
        // A korábbi PP-13 "bootstrap-completed" BLANKET-guard MINDEN setup-identify hívást elutasított
        // bootstrap után — megtörte minden ÚJ kliens-telepítés Google-belépését (az értéktáros/vezető
        // CSAK Google-lel léphet be). DE a publikus (permitAll) endpointon a bootstrap utáni ÁLLAPOT-
        // MUTÁCIÓ (Google-subject kötés / google_login_enable) valós kockázat (Codex P1).
        //
        // MEGOLDÁS — bootstrap után a setup-identify READ-ONLY:
        //   - az AZONOSÍTÁS (worker lookup a whitelistelt email alapján) engedett → a wizard működik,
        //   - de SEMMILYEN mutáció (subject-kötés, google-enable) NEM történik a publikus endpointon;
        //     azt a normál, AUTENTIKÁLT GoogleLoginService első belépése végzi (bind-sub-on-first-login),
        //     a maga subject-match / no-collision védelmével.
        // Bootstrap ELŐTT (első wizard) a kötés a szokásos módon megtörténik.
        boolean bootstrapCompleted = adminBootstrapService.isBootstrapAlreadyCompleted();

        GoogleIdTokenService.VerifiedGoogleIdentity identity = verifyIdentity(request.getIdToken());
        Company company = resolveCompany(request.getCompanyCode());
        String canonicalEmail = identity.email();
        String requestedAppMode = normalizeBlankToNull(request.getAppMode());
        // Bootstrap után a publikus endpoint READ-ONLY → a kötést figyelmen kívül hagyjuk.
        boolean bindGoogleSubject = Boolean.TRUE.equals(request.getBindGoogleSubject()) && !bootstrapCompleted;
        if (Boolean.TRUE.equals(request.getBindGoogleSubject()) && bootstrapCompleted) {
            log.info("SETUP_GOOGLE_BIND_DEFERRED_POST_BOOTSTRAP — a subject-kötés az autentikált "
                    + "GoogleLoginService első belépésén történik (publikus setup-identify read-only).");
        }

        List<Worker> workerMatches = workerRepository
                .findGoogleLoginCandidatesByCompanyIdAndEmail(company.getId(), canonicalEmail)
                .stream()
                .filter(worker -> Boolean.TRUE.equals(worker.getActive()))
                .toList();

        if (workerMatches.size() > 1) {
            log.error("SETUP_GOOGLE_CONFIG_ERROR multiple_worker_matches company={} emailHash={} count={}",
                    company.getCode(), GoogleLoginService.safeLogHash(canonicalEmail), workerMatches.size());
            throw new ConflictException("Tobb aktiv dolgozo van ugyanezzel a Google email cimmel. Javitsd a dolgozoi torzset.");
        }

        if (workerMatches.size() == 1) {
            Worker worker = workerMatches.get(0);
            if (bindGoogleSubject) {
                bindSubjectForUniqueWorker(worker, identity);
            }
            return buildWorkerMatchResponse(identity, worker, requestedAppMode);
        }

        List<Branch> branchMatches = branchRepository
                .findActiveByCompanyIdAndEmailIgnoreCase(company.getId(), canonicalEmail);

        if (branchMatches.size() > 1) {
            log.error("SETUP_GOOGLE_CONFIG_ERROR multiple_branch_matches company={} emailHash={} count={}",
                    company.getCode(), GoogleLoginService.safeLogHash(canonicalEmail), branchMatches.size());
            throw new ConflictException("Tobb aktiv fiok hasznalja ugyanezt a megosztott Google email cimet.");
        }

        if (branchMatches.size() == 1) {
            Branch branch = branchMatches.get(0);
            List<Worker> workerOptions = workerOptionsForBranch(branch);
            String selectedWorkerCode = normalizeBlankToNull(request.getSelectedWorkerCode());
            if (selectedWorkerCode == null) {
                return SetupGoogleIdentifyResponseDto.builder()
                        .matchType("BRANCH_SHARED_EMAIL")
                        .requiresWorkerSelection(true)
                        .message("Megosztott fiok-email: valaszd ki a dolgozot a fiok listajabol.")
                        .googleIdentity(toIdentityDto(identity))
                        .branch(toBranchDto(branch))
                        .workerOptions(workerOptions.stream().map(this::toWorkerDto).toList())
                        .validAppModes(List.of())
                        .requestedAppModeAllowed(false)
                        .build();
            }
            Worker selectedWorker = workerOptions.stream()
                    .filter(worker -> selectedWorkerCode.equalsIgnoreCase(worker.getCode()))
                    .findFirst()
                    .orElseThrow(() -> new ValidationException(
                            "A kivalasztott dolgozo nem tartozik ehhez a megosztott fiok-emailhez."));
            if (bindGoogleSubject) {
                enableSharedEmailGoogleLogin(selectedWorker);
            }
            return buildSharedEmailSelectedResponse(identity, branch, selectedWorker, requestedAppMode);
        }

        throw new AuthenticationException("Ez a Google email nincs engedelyezve a rendszerben.");
    }

    private GoogleIdTokenService.VerifiedGoogleIdentity verifyIdentity(String idToken) {
        try {
            return googleIdTokenService.verify(idToken);
        } catch (GoogleIdTokenService.GoogleTokenInvalidException ex) {
            log.warn("SETUP_GOOGLE_DENIED_INVALID_TOKEN code={}", ex.getCode());
            throw new AuthenticationException("Google bejelentkezes sikertelen.");
        }
    }

    private Company resolveCompany(String companyCode) {
        String normalized = companyCode == null ? "" : companyCode.trim().toUpperCase(Locale.ROOT);
        if (normalized.isBlank()) {
            throw new ValidationException("Hianyzo cegkod.");
        }
        return companyRepository.findByCode(normalized)
                .or(() -> companyRepository.findByCodeIgnoreCase(normalized))
                .orElseThrow(() -> new ValidationException("Ismeretlen cegkod: " + normalized));
    }

    private SetupGoogleIdentifyResponseDto buildWorkerMatchResponse(
            GoogleIdTokenService.VerifiedGoogleIdentity identity,
            Worker worker,
            String requestedAppMode) {
        List<String> roles = workerRoleService.getRoleCodesForWorker(worker.getId());
        List<String> validAppModes = AppModeRoleConstants.computeValidAppModes(roles, worker.getRole());
        boolean requestedAllowed = requestedAppMode == null || validAppModes.contains(requestedAppMode);
        String matchType = validAppModes.contains("full") || validAppModes.contains("rate-maker")
                ? "HQ_EMAIL"
                : "WORKER_EMAIL";
        return SetupGoogleIdentifyResponseDto.builder()
                .matchType(matchType)
                .requiresWorkerSelection(false)
                .message("Google email alapjan azonosított dolgozo.")
                .googleIdentity(toIdentityDto(identity))
                .branch(toBranchDto(worker.getBranch()))
                .worker(toWorkerDto(worker, roles, validAppModes))
                .workerOptions(List.of())
                .validAppModes(validAppModes)
                .requestedAppModeAllowed(requestedAllowed)
                .build();
    }

    private SetupGoogleIdentifyResponseDto buildSharedEmailSelectedResponse(
            GoogleIdTokenService.VerifiedGoogleIdentity identity,
            Branch branch,
            Worker worker,
            String requestedAppMode) {
        List<String> roles = workerRoleService.getRoleCodesForWorker(worker.getId());
        List<String> validAppModes = AppModeRoleConstants.computeValidAppModes(roles, worker.getRole());
        boolean requestedAllowed = requestedAppMode == null || validAppModes.contains(requestedAppMode);
        return SetupGoogleIdentifyResponseDto.builder()
                .matchType("BRANCH_SHARED_EMAIL")
                .requiresWorkerSelection(false)
                .message("Megosztott fiok-email es dolgozoi valasztas alapjan azonosítva.")
                .googleIdentity(toIdentityDto(identity))
                .branch(toBranchDto(branch))
                .worker(toWorkerDto(worker, roles, validAppModes))
                .workerOptions(List.of())
                .validAppModes(validAppModes)
                .requestedAppModeAllowed(requestedAllowed)
                .build();
    }

    private List<Worker> workerOptionsForBranch(Branch branch) {
        List<Worker> workers;
        if (branch.getRegion() != null && !branch.getRegion().isBlank()) {
            workers = workerRepository.findByCompanyIdAndRegionAndActiveTrue(
                    branch.getCompany().getId(), branch.getRegion());
        } else {
            workers = workerRepository.findActiveWorkersByBranch(branch.getId());
        }
        return workers.stream()
                .sorted(Comparator.comparing(Worker::getName, Comparator.nullsLast(String::compareToIgnoreCase)))
                .toList();
    }

    private void bindSubjectForUniqueWorker(Worker worker, GoogleIdTokenService.VerifiedGoogleIdentity identity) {
        String googleSubject = identity.subject();
        if (worker.getGoogleSubject() == null || worker.getGoogleSubject().isBlank()) {
            workerRepository.findByGoogleSubject(googleSubject)
                    .filter(other -> !other.getId().equals(worker.getId()))
                    .ifPresent(other -> {
                        throw new ConflictException("Ez a Google fiok mar masik dolgozohoz van kotve.");
                    });
            worker.setGoogleSubject(googleSubject);
            worker.setGoogleLinkedAt(LocalDateTime.now());
            workerRepository.save(worker);
            log.info("SETUP_GOOGLE_SUB_BOUND workerCode={} subjectHash={}",
                    worker.getCode(), GoogleLoginService.safeLogHash(googleSubject));
            return;
        }
        if (!worker.getGoogleSubject().equals(googleSubject)) {
            throw new AuthenticationException(
                    "A Google fiok azonositoja nem egyezik a dolgozohoz korabban kotott fiokkal.");
        }
    }

    private void enableSharedEmailGoogleLogin(Worker worker) {
        if (!Boolean.TRUE.equals(worker.getGoogleLoginEnabled())) {
            worker.setGoogleLoginEnabled(true);
            workerRepository.save(worker);
        }
    }

    private SetupGoogleIdentifyResponseDto.GoogleIdentityDto toIdentityDto(
            GoogleIdTokenService.VerifiedGoogleIdentity identity) {
        return SetupGoogleIdentifyResponseDto.GoogleIdentityDto.builder()
                .email(identity.email())
                .googleSub(identity.subject())
                .name(identity.name())
                .picture(identity.picture())
                .build();
    }

    private SetupGoogleIdentifyResponseDto.SetupBranchDto toBranchDto(Branch branch) {
        if (branch == null) {
            return null;
        }
        return SetupGoogleIdentifyResponseDto.SetupBranchDto.builder()
                .code(branch.getCode())
                .name(branch.getName())
                .city(branch.getCity())
                .address(branch.getAddress())
                .isVault(branch.getIsVault())
                .build();
    }

    private SetupGoogleIdentifyResponseDto.SetupWorkerDto toWorkerDto(Worker worker) {
        List<String> roles = workerRoleService.getRoleCodesForWorker(worker.getId());
        List<String> validAppModes = AppModeRoleConstants.computeValidAppModes(roles, worker.getRole());
        return toWorkerDto(worker, roles, validAppModes);
    }

    private SetupGoogleIdentifyResponseDto.SetupWorkerDto toWorkerDto(
            Worker worker,
            List<String> roles,
            List<String> validAppModes) {
        return SetupGoogleIdentifyResponseDto.SetupWorkerDto.builder()
                .code(worker.getCode())
                .name(worker.getName())
                .role(worker.getRole() == null ? null : worker.getRole().name())
                .roles(roles)
                .validAppModes(validAppModes)
                .build();
    }

    private String normalizeBlankToNull(String value) {
        if (value == null) return null;
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }
}
