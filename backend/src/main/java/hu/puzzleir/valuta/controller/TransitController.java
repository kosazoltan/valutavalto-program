package hu.puzzleir.valuta.controller;
import hu.puzzleir.valuta.dto.transit.TransitItemDto;
import hu.puzzleir.valuta.entity.VaultCollection;
import hu.puzzleir.valuta.entity.VaultDistribution;
import hu.puzzleir.valuta.entity.VaultDistributionLine;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import hu.puzzleir.valuta.repository.VaultCollectionRepository;
import hu.puzzleir.valuta.repository.VaultDistributionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * AUDIT (audit-NO-GO-iter3 P1, 2026-04-27): policy szerint minden controlleren
 * kotelezo @PreAuthorize. A GET listazo endpointokra class-level isAuthenticated(),
 * az acknowledge mutator endpointokra metodus-szinten szigoritott
 * SUPERVISOR/MANAGER/ADMIN szerepkor (vault-operation status valtoztatas).
 */
@RestController
@RequestMapping("/api/v1/transit")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("isAuthenticated()")
public class TransitController {

    private final VaultDistributionRepository distributionRepository;
    private final VaultCollectionRepository collectionRepository;

    private static final List<VaultOperationStatus> PENDING_STATUSES = List.of(
            VaultOperationStatus.REQUESTED, VaultOperationStatus.IN_PROGRESS);

    @GetMapping("/incoming")
    public ResponseEntity<List<TransitItemDto>> getIncoming(
            @RequestParam(required = false) String branchCode) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<TransitItemDto> result = new ArrayList<>();
        for (VaultOperationStatus st : PENDING_STATUSES) {
            List<VaultDistribution> dists = distributionRepository
                    .findByCompanyIdAndStatusOrderByCreatedAtDesc(companyId, st);
            for (VaultDistribution d : dists) {
                for (VaultDistributionLine line : d.getLines()) {
                    if (branchCode == null
                            || branchCode.equalsIgnoreCase(line.getTargetBranchCode())) {
                        result.add(buildDto(d, line));
                    }
                }
            }
        }
        for (VaultOperationStatus st : PENDING_STATUSES) {
            List<VaultCollection> colls = collectionRepository
                    .findByCompanyIdAndStatusOrderByRequestedAtDesc(companyId, st);
            for (VaultCollection c : colls) {
                if (branchCode != null
                        && branchCode.equalsIgnoreCase(c.getSourceBranchCode())) {
                    continue;
                }
                result.add(buildDto(c));
            }
        }
        log.info("Transit incoming branch={} count={}", branchCode, result.size());
        return ResponseEntity.ok(result);
    }

    @GetMapping("/outgoing")
    public ResponseEntity<List<TransitItemDto>> getOutgoing(
            @RequestParam(required = false) String branchCode) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<TransitItemDto> result = new ArrayList<>();
        if (branchCode != null) {
            for (VaultOperationStatus st : PENDING_STATUSES) {
                List<VaultCollection> colls = collectionRepository
                        .findByCompanyIdAndStatusOrderByRequestedAtDesc(companyId, st);
                for (VaultCollection c : colls) {
                    if (branchCode.equalsIgnoreCase(c.getSourceBranchCode())) {
                        result.add(buildDto(c));
                    }
                }
            }
        }
        for (VaultOperationStatus st : PENDING_STATUSES) {
            List<VaultDistribution> dists = distributionRepository
                    .findByCompanyIdAndStatusOrderByCreatedAtDesc(companyId, st);
            for (VaultDistribution d : dists) {
                for (VaultDistributionLine line : d.getLines()) {
                    result.add(buildDto(d, line));
                }
            }
        }
        log.info("Transit outgoing branch={} count={}", branchCode, result.size());
        return ResponseEntity.ok(result);
    }

    @PostMapping("/distribution/{id}/acknowledge")
    @PreAuthorize("hasAnyRole('SUPERVISOR','MANAGER','ADMIN')")
    @Transactional
    public ResponseEntity<TransitItemDto> acknowledgeDistribution(@PathVariable Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        VaultDistribution d = distributionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("VaultDistribution not found: " + id));
        if (!companyId.equals(d.getCompanyId())) {
            throw new RuntimeException("Cross-company access denied");
        }
        if (d.getStatus() != VaultOperationStatus.COMPLETED) {
            d.setStatus(VaultOperationStatus.COMPLETED);
            d.setCompletedAt(LocalDateTime.now());
            distributionRepository.save(d);
            log.info("Distribution {} acknowledged", id);
        }
        return ResponseEntity.ok(TransitItemDto.builder()
                .type("DISTRIBUTION")
                .id(id)
                .distributionId(d.getId())
                .documentNumber("DIST-" + d.getId())
                .status(d.getStatus().name())
                .completedAt(d.getCompletedAt())
                .build());
    }

    @PostMapping("/collection/{id}/acknowledge")
    @PreAuthorize("hasAnyRole('SUPERVISOR','MANAGER','ADMIN')")
    @Transactional
    public ResponseEntity<TransitItemDto> acknowledgeCollection(@PathVariable Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        VaultCollection c = collectionRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("VaultCollection not found: " + id));
        if (!companyId.equals(c.getCompanyId())) {
            throw new RuntimeException("Cross-company access denied");
        }
        if (c.getStatus() != VaultOperationStatus.COMPLETED) {
            c.setStatus(VaultOperationStatus.COMPLETED);
            c.setCompletedAt(LocalDateTime.now());
            collectionRepository.save(c);
            log.info("Collection {} acknowledged", id);
        }
        return ResponseEntity.ok(TransitItemDto.builder()
                .type("COLLECTION")
                .id(id)
                .documentNumber("COLL-" + c.getId())
                .status(c.getStatus().name())
                .completedAt(c.getCompletedAt())
                .build());
    }

    private TransitItemDto buildDto(VaultDistribution d, VaultDistributionLine line) {
        return TransitItemDto.builder()
                .type("DISTRIBUTION")
                .id(line.getId())
                .distributionId(d.getId())
                .documentNumber("DIST-" + d.getId())
                .fromBranchName("Ertektar")
                .toBranchCode(line.getTargetBranchCode())
                .toBranchName(line.getTargetBranchName())
                .currencyCode(line.getCurrencyCode())
                .amount(line.getAmount())
                .status(d.getStatus().name())
                .createdAt(d.getCreatedAt())
                .completedAt(d.getCompletedAt())
                .note(d.getNote())
                .build();
    }

    private TransitItemDto buildDto(VaultCollection c) {
        return TransitItemDto.builder()
                .type("COLLECTION")
                .id(c.getId())
                .documentNumber("COLL-" + c.getId())
                .fromBranchCode(c.getSourceBranchCode())
                .fromBranchName(c.getSourceBranchName())
                .toBranchName("Ertektar")
                .currencyCode(c.getCurrencyCode())
                .amount(c.getAmount())
                .status(c.getStatus().name())
                .createdAt(c.getRequestedAt())
                .completedAt(c.getCompletedAt())
                .note(c.getNote())
                .build();
    }
}
