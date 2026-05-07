package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto;
import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.util.AppModeRoleConstants;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Worker first-time password setup service.
 *
 * <p>A telepito wizard-ban a kivalasztott dolgozo (BORSI, BALI, KASZA stb.)
 * elso (vagy reset) jelszavanak beallitasa. Ez eltér az
 * {@link AdminBootstrapService}-tol:</p>
 * <ul>
 *   <li>NEM forcolja az ADMIN role-t — a worker eredeti role-ja megmarad</li>
 *   <li>NEM one-shot — minden worker-nek lehet sajat first-time setup-ja</li>
 *   <li>Csak akkor engedelyez jelszovaltast, ha:
 *     <ul>
 *       <li>a workernek nincs meg passwordHash-e es a bootstrap meg nincs lezarva, VAGY</li>
 *       <li>mar letezo hash eseten a currentPassword egyezik a BCrypt hash-sel</li>
 *     </ul>
 *   </li>
 *   <li>Sikeres bealllitas utan JWT token-t ad vissza (auto-login)</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WorkerFirstTimeSetupService {

    private static final String ACTIVE_PASSWORD_REQUIRED_MESSAGE =
            "Ez a dolgozo mar beallitott jelszot — a jelenlegi jelszo is kotelezo a valtashoz.";
    private static final String ACTIVE_PASSWORD_MISMATCH_MESSAGE = "A jelenlegi jelszo nem egyezik.";
    private static final String POST_BOOTSTRAP_SEED_PASSWORD_REQUIRED_MESSAGE =
            "A telepites mar lezarult — a jelenlegi vagy kezdo dolgozoi jelszo kotelezo "
            + "az uj jelszo beallitasahoz.";
    private static final String PRE_BOOTSTRAP_SEED_PASSWORD_REQUIRED_MESSAGE =
            "A dolgozohoz kezdo jelszo tartozik — a jelenlegi vagy kezdo dolgozoi jelszo kotelezo "
            + "az uj jelszo beallitasahoz.";
    private static final String SEED_PASSWORD_MISMATCH_MESSAGE =
            "A megadott jelenlegi (seed) jelszo nem egyezik.";

    private final CompanyRepository companyRepository;
    private final WorkerRepository workerRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AdminBootstrapService adminBootstrapService;
    private final WorkerRoleService workerRoleService;
    private final BranchRepository branchRepository;

    /**
     * Worker elso jelszavanak beallitasa / reset.
     */
    @Transactional(rollbackFor = Exception.class)
    public WorkerFirstTimeSetupResponseDto setupWorkerPassword(WorkerFirstTimeSetupRequestDto dto) {
        String normalizedCompanyCode = normalize(dto.getCompanyCode());
        String normalizedWorkerCode = normalize(dto.getWorkerCode());

        // 1) Ceg resolve
        Company company = companyRepository.findByCode(normalizedCompanyCode)
                .or(() -> companyRepository.findByCodeIgnoreCase(normalizedCompanyCode))
                .orElseThrow(() -> new ValidationException(
                        "Ismeretlen cegkod: " + normalizedCompanyCode
                ));

        // 2) Worker resolve
        Worker worker = workerRepository.findByCompanyIdAndCodeIgnoreCase(
                        company.getId(), normalizedWorkerCode)
                .orElseThrow(() -> new ValidationException(
                        "Ismeretlen dolgozoi azonosito: " + normalizedWorkerCode
                        + " (ceg: " + normalizedCompanyCode + ")"
                ));

        if (Boolean.FALSE.equals(worker.getActive())) {
            throw new ValidationException(
                    "Ez a dolgozoi fiok inaktiv. Vedd fel a kapcsolatot az adminisztratorral."
            );
        }

        // 3) Biztonsagi ellenorzes:
        //    A permitAll setup endpoint az elso telepiteshez kell. Miutan a
        //    bootstrap lezarult, egy letezo worker jelszava csak a jelenlegi
        //    jelszo ismereteben allithato at, kulonben worker kod ismeretevel
        //    publikus fiokatvetel lenne.
        boolean bootstrapCompleted = adminBootstrapService.isBootstrapAlreadyCompleted();

        if (worker.getPasswordChangedAt() != null) {
            // Mar aktiv user-jelszo van -> csak a regi jelszoval engedjuk cserelni
            validateCurrentPassword(
                    worker,
                    dto.getCurrentPassword(),
                    ACTIVE_PASSWORD_REQUIRED_MESSAGE,
                    ACTIVE_PASSWORD_MISMATCH_MESSAGE);
        } else if (hasPasswordHash(worker)) {
            // Seed-jelszo van (pl. V111 = "1234"). Ez is titoknak szamit:
            // public first-time setup endpointen currentPassword nelkul nem adunk uj jelszot.
            validateCurrentPassword(
                    worker,
                    dto.getCurrentPassword(),
                    bootstrapCompleted
                            ? POST_BOOTSTRAP_SEED_PASSWORD_REQUIRED_MESSAGE
                            : PRE_BOOTSTRAP_SEED_PASSWORD_REQUIRED_MESSAGE,
                    SEED_PASSWORD_MISMATCH_MESSAGE);
        } else if (bootstrapCompleted) {
            throw new ValidationException(
                    "A dolgozohoz nincs kezdo jelszo beallitva. Lezart telepites utan "
                    + "csak hitelesitett admin jelszo-reset folyamat hasznalhato."
            );
        }
        // Ha worker.passwordHash == null es bootstrap meg nincs lezarva, friss elso
        // telepiteskent engedjuk az uj jelszo beallitasat.

        List<String> roleCodes = sanitizeRoleCodes(workerRoleService.getRoleCodesForWorker(worker.getId()));
        if (AppModeRoleConstants.isLegacyWorkerRoleDeniedForAppMode(
                roleCodes, worker.getRole(), dto.getAppMode())) {
            throw new ValidationException(AppModeRoleConstants.legacyWorkerRoleDeniedMessage(worker.getRole()));
        }
        String activeRole = resolveActiveRoleForSetup(roleCodes, dto.getAppMode());
        List<String> permissions = activeRole == null
                ? List.of()
                : workerRoleService.getPermissionCodesForRole(activeRole);

        ensureBranchBeforeAutoLogin(worker, company);

        // 4) Uj jelszo beallitasa + BCrypt hash + timestamp
        worker.setPasswordHash(passwordEncoder.encode(dto.getNewPassword()));
        worker.setPasswordChangedAt(LocalDateTime.now());
        Worker saved = workerRepository.save(worker);

        log.info("Worker first-time setup — worker id={}, companyCode={}, workerCode={}, role={}",
                saved.getId(), company.getCode(), saved.getCode(), saved.getRole());

        // 5) JWT token generalasa auto-login-hoz
        String token = activeRole == null
                ? jwtTokenProvider.generateToken(saved)
                : jwtTokenProvider.generateToken(saved, activeRole, permissions);
        long expiresAt = System.currentTimeMillis() + 86400000L; // 24 ora

        return WorkerFirstTimeSetupResponseDto.builder()
                .success(true)
                .message("Jelszo sikeresen beallitva. Most mar bejelentkezhetsz.")
                .workerId(saved.getId())
                .companyCode(company.getCode())
                .companyName(company.getName())
                .workerCode(saved.getCode())
                .workerName(saved.getName())
                .workerRole(saved.getRole() != null ? saved.getRole().name() : null)
                .activeRole(activeRole)
                .roles(roleCodes)
                .branchCode(saved.getBranch() != null ? saved.getBranch().getCode() : null)
                .branchName(saved.getBranch() != null ? saved.getBranch().getName() : null)
                .token(token)
                .expiresAt(expiresAt)
                .build();
    }

    private static String normalize(String value) {
        return value == null ? "" : value.trim().toUpperCase();
    }

    private void ensureBranchBeforeAutoLogin(Worker worker, Company company) {
        if (worker.getBranch() != null) {
            return;
        }

        Branch fallbackBranch = branchRepository.findByCompanyIdAndIsActiveTrue(company.getId()).stream()
                .findFirst()
                .orElseGet(() -> branchRepository.findByCompanyId(company.getId()).stream().findFirst().orElse(null));
        if (fallbackBranch == null) {
            throw new ValidationException("Nincs elérhető iroda a bejelentkezéshez!");
        }
        worker.setBranch(fallbackBranch);
    }

    private static List<String> sanitizeRoleCodes(List<String> roleCodes) {
        if (roleCodes == null || roleCodes.isEmpty()) {
            return List.of();
        }
        return roleCodes.stream()
                .filter(roleCode -> roleCode != null && !roleCode.isBlank())
                .map(String::trim)
                .toList();
    }

    private static String resolveActiveRoleForSetup(List<String> roleCodes, String appMode) {
        if (roleCodes.isEmpty()) {
            return null;
        }
        if (appMode != null && !appMode.isBlank()) {
            String preferredRole = AppModeRoleConstants.preferredSelectableLocalRoleForAppMode(roleCodes, appMode);
            if (preferredRole != null) {
                return preferredRole;
            }

            List<String> selectableRoles = AppModeRoleConstants.selectableRolesForAppMode(roleCodes, appMode);
            if (selectableRoles.isEmpty()) {
                throw new ValidationException("Nincs ebben a programban használható szerepköre.");
            }
            if (selectableRoles.size() == 1) {
                return selectableRoles.get(0);
            }
            throw new ValidationException(
                    "Tobb használható szerepköre van ebben a programban. Valassz konkret szerepkort."
            );
        }
        if (roleCodes.size() == 1) {
            return roleCodes.get(0);
        }
        // Tobbszerepkoros setupnal appMode nelkul nem valasztunk sorrendfuggo aktiv role-t.
        throw new ValidationException("Tobb szerepkor eseten a programtipus megadasa kotelezo.");
    }

    private boolean hasPasswordHash(Worker worker) {
        return worker.getPasswordHash() != null && !worker.getPasswordHash().isBlank();
    }

    private void validateCurrentPassword(
            Worker worker,
            String currentPassword,
            String missingMessage,
            String mismatchMessage) {
        if (currentPassword == null || currentPassword.isBlank()) {
            throw new ValidationException(missingMessage);
        }
        if (!passwordEncoder.matches(currentPassword, worker.getPasswordHash())) {
            throw new ValidationException(mismatchMessage);
        }
    }
}
