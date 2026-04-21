package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.PublicBranchDto;
import hu.puzzleir.valuta.dto.PublicWorkerDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * Publikus (non-authenticated) iroda-lista endpoint a pénztáros kliens
 * First-Run Setup Wizardja számára.
 *
 * <p><strong>Miért publikus?</strong> A wizard még nem rendelkezik JWT-vel,
 * ekkor választja ki a felhasználó az iroda kódját. Ha authentikált
 * endpoint-ot használnánk, körkörös függőség lenne.</p>
 *
 * <p><strong>Adatszivárgási védelem:</strong> csak a {@link PublicBranchDto}
 * mezői (kód, név, város, cím) mennek a válaszba. Semmilyen belső ID,
 * létrehozási idő, bank-kód vagy értéktári adat nem látszik.</p>
 *
 * <p><strong>Rate limit:</strong> a {@code /api/v1/public/**} útvonal
 * a global rate limiter hatálya alatt van (CORS + brute-force filter).</p>
 */
@RestController
@RequestMapping("/api/v1/public")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("permitAll()")
public class PublicBranchController {

    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;

    /**
     * GET /api/v1/public/branches?companyCode=EBC
     *
     * <p>Visszaadja a megadott cégkódhoz tartozó összes aktív branch-et.
     * Ha a cégkód nem található, üres listát ad (nem 404) — így a wizard
     * offline fallback-je tud érvényesülni.</p>
     *
     * @param companyCode opcionális; ha üres, üres lista a válasz
     * @return aktív, publikus branch-ek kód szerint rendezve
     */
    @GetMapping("/branches")
    public ResponseEntity<List<PublicBranchDto>> getPublicBranches(
            @RequestParam(required = false) String companyCode) {

        if (companyCode == null || companyCode.isBlank()) {
            log.debug("Public branches kérés üres companyCode-dal");
            return ResponseEntity.ok(Collections.emptyList());
        }

        String normalized = companyCode.trim().toUpperCase();
        Optional<Company> companyOpt = companyRepository.findByCode(normalized)
                .or(() -> companyRepository.findByCodeIgnoreCase(normalized));

        if (companyOpt.isEmpty()) {
            log.info("Public branches: nem talált cégkód: {}", normalized);
            return ResponseEntity.ok(Collections.emptyList());
        }

        Company company = companyOpt.get();
        List<Branch> branches = branchRepository.findByCompanyIdAndIsActiveTrue(company.getId());

        List<PublicBranchDto> dtos = branches.stream()
                .sorted(Comparator.comparing(Branch::getCode, Comparator.nullsLast(String::compareToIgnoreCase)))
                .map(b -> PublicBranchDto.builder()
                        .code(b.getCode())
                        .name(b.getName())
                        .city(b.getCity())
                        .address(b.getAddress())
                        .build())
                .collect(Collectors.toList());

        log.info("Public branches válasz: companyCode={}, count={}", normalized, dtos.size());
        return ResponseEntity.ok(dtos);
    }

    /**
     * GET /api/v1/public/workers?branchCode=BR039
     *
     * Visszaadja az adott penztar regioja szerint az osszes aktiv dolgozot,
     * csak a publikus mezokkel (code, name, region) - no email, no phone.
     *
     * Login-elotti wizard es LoginPage kapja meg a dropdown listat,
     * mindig friss a szerverrol (no cache).
     */
    @GetMapping("/workers")
    @SuppressWarnings("deprecation") // Szandekos: pre-login wizard, nincs SecurityContext. A branch code globalis unique.
    public ResponseEntity<List<PublicWorkerDto>> getPublicWorkersByBranch(
            @RequestParam(required = false) String branchCode) {
        if (branchCode == null || branchCode.isBlank()) {
            return ResponseEntity.ok(Collections.emptyList());
        }
        String normalized = branchCode.trim().toUpperCase();
        Optional<Branch> branchOpt = branchRepository.findByCode(normalized);
        if (branchOpt.isEmpty()) {
            log.info("Public workers: unknown branchCode: {}", normalized);
            return ResponseEntity.ok(Collections.emptyList());
        }
        Branch branch = branchOpt.get();
        String region = branch.getRegion();
        if (region == null || region.isBlank()) {
            log.warn("Public workers: branch {} has no region assigned", normalized);
            return ResponseEntity.ok(Collections.emptyList());
        }
        List<Worker> workers = workerRepository
                .findByCompanyIdAndRegionAndActiveTrue(branch.getCompany().getId(), region);
        List<PublicWorkerDto> dtos = workers.stream()
                .sorted(Comparator.comparing(Worker::getName, Comparator.nullsLast(String::compareToIgnoreCase)))
                .map(w -> PublicWorkerDto.builder()
                        .code(w.getCode())
                        .name(w.getName())
                        .region(w.getRegion())
                        .build())
                .collect(Collectors.toList());
        log.info("Public workers: branch={}, region={}, count={}", normalized, region, dtos.size());
        return ResponseEntity.ok(dtos);
    }

}
