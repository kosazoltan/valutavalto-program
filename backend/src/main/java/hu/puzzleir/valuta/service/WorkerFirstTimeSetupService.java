package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupRequestDto;
import hu.puzzleir.valuta.dto.auth.WorkerFirstTimeSetupResponseDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

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
        //    Ha a worker-nek mar volt jelszo-valtasa (passwordChangedAt != null),
        //    akkor a currentPassword megegyezes kotelezo.
        //    Ha soha nem volt (seed worker V111), akkor a seed default jelszo
        //    vagy ures currentPassword is elfogadhato.
        if (worker.getPasswordChangedAt() != null) {
            // Mar aktiv user-jelszo van -> csak a regi jelszoval engedjuk cserelni
            if (dto.getCurrentPassword() == null || dto.getCurrentPassword().isBlank()) {
                throw new ValidationException(
                        "Ez a dolgozo mar beallitott jelszot — a jelenlegi jelszo is kotelezo "
                        + "a valtashoz."
                );
            }
            if (!passwordEncoder.matches(dto.getCurrentPassword(), worker.getPasswordHash())) {
                throw new ValidationException("A jelenlegi jelszo nem egyezik.");
            }
        } else if (worker.getPasswordHash() != null && !worker.getPasswordHash().isBlank()) {
            // Seed-jelszo van (V111 = "1234") — a user opciosan beirhatja a seed-et
            // csak akkor, ha megadott currentPassword van a request-ben.
            if (dto.getCurrentPassword() != null && !dto.getCurrentPassword().isBlank()) {
                if (!passwordEncoder.matches(dto.getCurrentPassword(), worker.getPasswordHash())) {
                    throw new ValidationException(
                            "A megadott jelenlegi (seed) jelszo nem egyezik."
                    );
                }
            }
            // Ha nincs currentPassword megadva, akkor is engedelyezzuk — ez az
            // intended first-time setup path a seed-telepitet workerekre.
        }
        // Ha worker.passwordHash == null (soha nem volt seed sem), szinten engedjuk

        // 4) Uj jelszo beallitasa + BCrypt hash + timestamp
        worker.setPasswordHash(passwordEncoder.encode(dto.getNewPassword()));
        worker.setPasswordChangedAt(LocalDateTime.now());
        Worker saved = workerRepository.save(worker);

        log.info("Worker first-time setup — worker id={}, companyCode={}, workerCode={}, role={}",
                saved.getId(), company.getCode(), saved.getCode(), saved.getRole());

        // 5) JWT token generalasa auto-login-hoz
        String token = jwtTokenProvider.generateToken(saved);
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
                .branchCode(saved.getBranch() != null ? saved.getBranch().getCode() : null)
                .branchName(saved.getBranch() != null ? saved.getBranch().getName() : null)
                .token(token)
                .expiresAt(expiresAt)
                .build();
    }

    private static String normalize(String value) {
        return value == null ? "" : value.trim().toUpperCase();
    }
}