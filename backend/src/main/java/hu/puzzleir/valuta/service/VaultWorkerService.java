package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.VaultWorkerCreateRequestDto;
import hu.puzzleir.valuta.dto.auth.VaultWorkerOptionDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * FK-ÉRTÉKTÁR (V285, 2026-06-02): értéktári (személyes) dolgozók kezelése a kétlépcsős belépéshez.
 *
 * <p>A bejelentkezett értéktáros felvehet új személyes munkatársat (név + jelszó). A company és a
 * branch KIZÁRÓLAG a SecurityContextből jön — a kliens nem választhat tetszőleges céget/irodát
 * (audit P1). Az új worker:
 * <ul>
 *   <li>aktív, a felvevő SAJÁT branch-e alá kerül,</li>
 *   <li>bcrypt jelszó-hash (soha nem plain text),</li>
 *   <li>{@code ertektar} canonical role assignment,</li>
 *   <li>NEM kap googleLoginEnabled-et (a személyes azonosítás jelszavas 2. lépcső),</li>
 *   <li>NEM intézményi (shared_account = false).</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class VaultWorkerService {

    private final WorkerRepository workerRepository;
    private final BranchRepository branchRepository;
    private final CompanyRepository companyRepository;
    private final WorkerRoleService workerRoleService;
    private final PasswordEncoder passwordEncoder;

    /**
     * Új személyes értéktári worker felvétele a bejelentkezett értéktáros SAJÁT értéktárába.
     */
    public VaultWorkerOptionDto createVaultWorker(VaultWorkerCreateRequestDto dto) {
        if (!dto.getPassword().equals(dto.getPasswordConfirm())) {
            throw new ValidationException("A két jelszó nem egyezik!");
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (branchId == null) {
            throw new ValidationException("Nem határozható meg az értéktár (iroda) — nem hozható létre dolgozó.");
        }

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található."));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található."));
        if (!branch.getCompany().getId().equals(companyId)) {
            // Defenzív: a JWT branch+company konzisztens kell legyen.
            throw new ValidationException("Az iroda nem tartozik ehhez a céghez!");
        }

        String hashedPassword = passwordEncoder.encode(dto.getPassword());
        String name = dto.getName().trim();

        // Copilot: a kód-generálás + save NEM atomi → párhuzamos felvételnél a (company_id, code)
        // unique constraint ütközhet. DataIntegrityViolationException esetén új kóddal újrapróbáljuk.
        Worker saved = null;
        org.springframework.dao.DataIntegrityViolationException lastError = null;
        for (int attempt = 0; attempt < 5 && saved == null; attempt++) {
            String code = generateUniqueCode(companyId);
            Worker worker = Worker.builder()
                    .company(company)
                    .code(code)
                    .name(name)
                    .passwordHash(hashedPassword)
                    .role(WorkerRole.CASHIER) // legacy enum; a tényleges jogosultság a canonical ertektar role
                    .branch(branch)
                    .active(true)
                    .googleLoginEnabled(false)
                    .sharedAccount(false)
                    .passwordChangedAt(LocalDateTime.now())
                    .build();
            try {
                saved = workerRepository.saveAndFlush(worker);
            } catch (org.springframework.dao.DataIntegrityViolationException ex) {
                lastError = ex;
                log.warn("VAULT_WORKER_CODE_COLLISION code={} attempt={} — újrapróbálkozás", code, attempt + 1);
            }
        }
        if (saved == null) {
            log.error("VAULT_WORKER_CREATE_FAILED 5 kód-ütközés után", lastError);
            throw new ValidationException("Nem sikerült a munkatárs felvétele (kód-ütközés). Próbáld újra.");
        }

        workerRoleService.assignRole(saved.getId(), "ertektar");

        log.info("VAULT_WORKER_CREATED code={} branchId={} byWorkerId={}",
                saved.getCode(), branchId, SecurityUtils.getCurrentWorkerId());

        return VaultWorkerOptionDto.builder().id(saved.getId()).name(saved.getName()).build();
    }

    /**
     * A bejelentkezett értéktáros SAJÁT értéktárának személyes (ertektar) workerei — a felvételi
     * képernyő listájához. Cross-tenant védelem: company + branch a SecurityContextből.
     */
    @Transactional(readOnly = true)
    public List<VaultWorkerOptionDto> listVaultWorkers() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        UUID branchId = SecurityUtils.getCurrentBranchIdOrNull();
        if (branchId == null) {
            return List.of();
        }
        return workerRepository.findSelectableVaultWorkers(companyId, branchId).stream()
                .filter(w -> workerRoleService.getRoleCodesForWorker(w.getId()).contains("ertektar"))
                .map(w -> VaultWorkerOptionDto.builder().id(w.getId()).name(w.getName()).build())
                .toList();
    }

    /**
     * Egyedi worker-kód generálása a cégen belül: "VW" + 4 jegyű sorszám.
     */
    private String generateUniqueCode(UUID companyId) {
        for (int i = 1; i <= 9999; i++) {
            String candidate = String.format("VW%04d", i);
            if (!workerRepository.existsByCompanyIdAndCode(companyId, candidate)) {
                return candidate;
            }
        }
        throw new ValidationException("Nem generálható egyedi dolgozó-kód (a VW-kódok elfogytak).");
    }
}
