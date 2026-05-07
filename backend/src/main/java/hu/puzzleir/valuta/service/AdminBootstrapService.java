package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.BootstrapAdminRequestDto;
import hu.puzzleir.valuta.dto.auth.BootstrapAdminResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * First-run setup wizard admin bootstrap service.
 *
 * <p><strong>Feladat:</strong> a telepítő wizard 4. lépésében megadott
 * admin hitelesítő adatokat beírja az adatbázisba — létrehozza vagy
 * frissíti az ADMIN role-ú workert.</p>
 *
 * <p><strong>Idempotencia + biztonság:</strong> a műveletet csak egyszer
 * engedjük végrehajtani — a {@code system_parameter.auth.bootstrap-completed}
 * flag kapcsolja ki. Másodszori hívás {@link ValidationException}-t dob
 * (HTTP 400), így egy támadó nem tud más admint bootstrappolni a
 * felhasználó utáni újrafuttatással.</p>
 *
 * <p><strong>Race feltétel:</strong> a teljes művelet egyetlen
 * tranzakció, a flag beírása a worker update után történik.</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class AdminBootstrapService {

    public static final String BOOTSTRAP_FLAG_KEY = "auth.bootstrap-completed";
    private static final String BOOTSTRAP_FLAG_CATEGORY = "AUTH";
    private static final String BOOTSTRAP_FLAG_TYPE = "BOOLEAN";

    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final SystemParameterRepository systemParameterRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(rollbackFor = Exception.class)
    public BootstrapAdminResponseDto bootstrapAdmin(BootstrapAdminRequestDto dto) {
        boolean alreadyCompleted = isBootstrapAlreadyCompleted();

        String normalizedCompanyCode = normalize(dto.getCompanyCode());
        String normalizedWorkerCode = normalize(dto.getWorkerCode());

        if (alreadyCompleted) {
            log.debug("Admin bootstrap elutasítva, mert már lezárult: companyCode={}, workerCode={}",
                    normalizedCompanyCode, normalizedWorkerCode);
            throw new ValidationException(
                    "A bootstrap már lezajlott; jelszó frissítéshez használd a hitelesített "
                            + "dolgozói jelszócsere vagy reset folyamatot."
            );
        }

        Company company = companyRepository.findByCode(normalizedCompanyCode)
                .or(() -> companyRepository.findByCodeIgnoreCase(normalizedCompanyCode))
                .orElseThrow(() -> new ValidationException(
                        "Ismeretlen cégkód: " + normalizedCompanyCode
                        + ". Ellenőrizd az adatbázisban, hogy létrejött-e a cég."
                ));

        Worker worker = workerRepository.findByCompanyIdAndCodeIgnoreCase(company.getId(), normalizedWorkerCode)
                .orElseGet(() -> createWorkerShell(company, normalizedWorkerCode, dto.getWorkerName()));

        worker.setName(defaultIfBlank(dto.getWorkerName(), worker.getName()));
        if (dto.getEmail() != null && !dto.getEmail().isBlank()) {
            worker.setEmail(dto.getEmail().trim());
        }
        worker.setRole(WorkerRole.ADMIN);
        worker.setActive(true);
        worker.setPasswordHash(passwordEncoder.encode(dto.getNewPassword()));
        worker.setPasswordChangedAt(LocalDateTime.now());

        Worker saved = workerRepository.save(worker);
        log.info("Admin bootstrap — worker mentve: id={}, companyCode={}, workerCode={}, role=ADMIN",
                saved.getId(), company.getCode(), saved.getCode());

        setBootstrapCompletedFlag();

        return BootstrapAdminResponseDto.builder()
                .success(true)
                .message("Admin hitelesítő adatok sikeresen beállítva. Most már bejelentkezhetsz.")
                .workerId(saved.getId())
                .companyCode(company.getCode())
                .workerCode(saved.getCode())
                .build();
    }

    /**
     * Publikus read-only query, hogy a wizard ellenőrizni tudja, meg kell-e
     * hívnia a bootstrap-admin endpointot (pl. egy sikertelen hívás után).
     */
    @Transactional(readOnly = true)
    public boolean isBootstrapAlreadyCompleted() {
        return systemParameterRepository.findByParameterKey(BOOTSTRAP_FLAG_KEY)
                .map(sp -> "true".equalsIgnoreCase(sp.getParameterValue())
                        && Boolean.TRUE.equals(sp.getIsActive()))
                .orElse(false);
    }

    // ---------------------------------------------------------------
    // Internal helpers
    // ---------------------------------------------------------------

    private Worker createWorkerShell(Company company, String workerCode, String workerName) {
        List<Branch> branches = branchRepository.findByCompanyIdAndIsActiveTrue(company.getId());
        if (branches.isEmpty()) {
            branches = branchRepository.findByCompanyId(company.getId());
        }
        if (branches.isEmpty()) {
            throw new ValidationException(
                    "A '" + company.getCode() + "' céghez nincs egyetlen branch sem az adatbázisban. "
                    + "A telepítő V69 Flyway migrációjának le kellett volna futnia."
            );
        }

        Branch firstBranch = branches.get(0);
        Worker worker = new Worker();
        worker.setCompany(company);
        worker.setBranch(firstBranch);
        worker.setCode(workerCode);
        worker.setName(defaultIfBlank(workerName, workerCode));
        worker.setRole(WorkerRole.ADMIN);
        worker.setActive(true);
        return worker;
    }

    private void setBootstrapCompletedFlag() {
        Optional<SystemParameter> existing = systemParameterRepository.findByParameterKey(BOOTSTRAP_FLAG_KEY);
        SystemParameter flag = existing.orElseGet(() -> SystemParameter.builder()
                .parameterKey(BOOTSTRAP_FLAG_KEY)
                .parameterType(BOOTSTRAP_FLAG_TYPE)
                .category(BOOTSTRAP_FLAG_CATEGORY)
                .description("First-run admin bootstrap végrehajtva. Ne töröld, új bootstrap-ot tilt.")
                .isActive(true)
                .build());
        flag.setParameterValue("true");
        flag.setIsActive(true);
        systemParameterRepository.save(flag);
        log.info("Admin bootstrap flag beállítva: {}=true", BOOTSTRAP_FLAG_KEY);
    }

    private static String normalize(String value) {
        return value == null ? "" : value.trim().toUpperCase();
    }

    private static String defaultIfBlank(String primary, String fallback) {
        if (primary == null || primary.isBlank()) {
            return fallback;
        }
        return primary.trim();
    }
}
