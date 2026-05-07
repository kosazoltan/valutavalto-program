package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto;
import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
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
 *       <li>a worker.passwordChangedAt == null (seed default jelszo aktiv), VAGY</li>
 *       <li>currentPassword egyezik a BCrypt hash-sel</li>
 *     </ul>
 *   </li>
 *   <li>Sikeres bealllitas utan JWT token-t ad vissza (auto-login)</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WorkerFirstTimeSetupService {

    private final CompanyRepository companyRepository;
    private final WorkerRepository workerRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final AdminBootstrapService adminBootstrapService;
    private final WorkerRoleService workerRoleService;

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

        List<String> roleCodes = workerRoleService.getRoleCodesForWorker(worker.getId());
        String activeRole = resolveActiveRoleForSetup(roleCodes, dto.getAppMode());
        List<String> permissions = activeRole == null
                ? List.of()
                : workerRoleService.getPermissionCodesForRole(activeRole);

        // 3) Biztonsagi ellenorzes:
        //    A permitAll setup endpoint az elso telepiteshez kell. Miutan a
        //    bootstrap lezarult, egy letezo worker jelszava csak a jelenlegi
        //    jelszo ismereteben allithato at, kulonben worker kod ismeretevel
        //    publikus fiokatvetel lenne.
        boolean bootstrapCompleted = adminBootstrapService.isBootstrapAlreadyCompleted();
        boolean currentPasswordProvided = dto.getCurrentPassword() != null
                && !dto.getCurrentPassword().isBlank();

        if (worker.getPasswordChangedAt() != null) {
            // Mar aktiv user-jelszo van -> csak a regi jelszoval engedjuk cserelni
            if (!currentPasswordProvided) {
                throw new ValidationException(
                        "Ez a dolgozo mar beallitott jelszot — a jelenlegi jelszo is kotelezo "
                        + "a valtashoz."
                );
            }
            if (!passwordEncoder.matches(dto.getCurrentPassword(), worker.getPasswordHash())) {
                throw new ValidationException("A jelenlegi jelszo nem egyezik.");
            }
        } else if (worker.getPasswordHash() != null && !worker.getPasswordHash().isBlank()) {
            // Seed-jelszo van (pl. V111 = "1234"). Ez is titoknak szamit:
            // public first-time setup endpointen currentPassword nelkul nem adunk uj jelszot.
            if (!currentPasswordProvided) {
                String setupState = bootstrapCompleted ? "A telepites mar lezarult" : "A dolgozohoz kezdo jelszo tartozik";
                throw new ValidationException(
                        setupState + " — a jelenlegi vagy kezdo dolgozoi jelszo "
                        + "kotelezo az uj jelszo beallitasahoz."
                );
            }
            if (currentPasswordProvided) {
                if (!passwordEncoder.matches(dto.getCurrentPassword(), worker.getPasswordHash())) {
                    throw new ValidationException(
                            "A megadott jelenlegi (seed) jelszo nem egyezik."
                    );
                }
            }
        } else if (bootstrapCompleted) {
            throw new ValidationException(
                    "A dolgozohoz nincs kezdo jelszo beallitva. Lezart telepites utan "
                    + "csak hitelesitett admin jelszo-reset folyamat hasznalhato."
            );
        }
        // Ha worker.passwordHash == null es bootstrap meg nincs lezarva, friss elso
        // telepiteskent engedjuk az uj jelszo beallitasat.

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

    private static String resolveActiveRoleForSetup(List<String> roleCodes, String appMode) {
        if (roleCodes == null || roleCodes.isEmpty()) {
            return null;
        }
        if (appMode != null && !appMode.isBlank()) {
            String preferredRole = switch (appMode.trim().toLowerCase()) {
                case "ertektar" -> "ertektar";
                case "ertekszallito" -> "ertekszallito";
                case "penztar" -> "penztar";
                default -> null;
            };
            if (preferredRole != null) {
                String exact = roleCodes.stream()
                        .filter(roleCode -> roleCode != null
                                && preferredRole.equals(roleCode.trim().toLowerCase()))
                        .findFirst()
                        .orElse(null);
                if (exact != null) {
                    return exact;
                }
            }
            return roleCodes.stream()
                    .filter(roleCode -> AppModeRoleConstants.isRoleSelectableForAppMode(roleCode, appMode))
                    .findFirst()
                    .orElseThrow(() -> new ValidationException(
                            "Nincs ebben a programban használható szerepköre."));
        }
        return roleCodes.size() == 1 ? roleCodes.get(0) : null;
    }
}
