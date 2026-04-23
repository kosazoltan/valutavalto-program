package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.DistributionItemDto;
import hu.puzzleir.valuta.dto.ertektar.DistributionLineDto;
import hu.puzzleir.valuta.dto.ertektar.DistributionRequestDto;
import hu.puzzleir.valuta.dto.ertektar.DistributionResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.VaultDistribution;
import hu.puzzleir.valuta.entity.VaultDistributionLine;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.VaultDistributionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class VaultDistributionService {

    private final VaultDistributionRepository vaultDistributionRepository;
    private final BranchRepository branchRepository;
    private final VaultStockFlowService vaultStockFlowService;  // v2.2.2 hotfix

    @Transactional(readOnly = true)
    public List<DistributionResponseDto> getDistributions() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return vaultDistributionRepository.findByCompanyIdOrderByCreatedAtDesc(companyId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(rollbackFor = Exception.class)
    public DistributionResponseDto createDistribution(DistributionRequestDto request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Long workerId = SecurityUtils.getCurrentWorkerId();

        VaultDistribution distribution = VaultDistribution.builder()
                .companyId(companyId)
                .status(VaultOperationStatus.REQUESTED)
                .note(request.getNote())
                .createdAt(LocalDateTime.now())
                .createdBy(workerId)
                .build();

        for (DistributionItemDto item : request.getItems()) {
            String branchName = branchRepository.findByCompanyIdAndCode(companyId, item.getTargetBranchCode())
                    .map(Branch::getName)
                    .orElse(item.getTargetBranchCode());

            VaultDistributionLine line = VaultDistributionLine.builder()
                    .distribution(distribution)
                    .targetBranchCode(item.getTargetBranchCode())
                    .targetBranchName(branchName)
                    .currencyCode(item.getCurrencyCode())
                    .amount(item.getAmount())
                    .build();

            distribution.getLines().add(line);
        }

        VaultDistribution saved = vaultDistributionRepository.save(distribution);
        log.info("Szétosztás létrehozva: {} tétel, company={}", request.getItems().size(), companyId);

        return toDto(saved);
    }

    @Transactional(rollbackFor = Exception.class)
    public DistributionResponseDto updateStatus(Long id, VaultOperationStatus newStatus) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        VaultDistribution distribution = vaultDistributionRepository.findById(id)
                .filter(d -> d.getCompanyId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Szétosztás nem található: " + id));

        VaultOperationStatus oldStatus = distribution.getStatus();
        distribution.setStatus(newStatus);
        if (newStatus == VaultOperationStatus.COMPLETED) {
            distribution.setCompletedAt(LocalDateTime.now());

            // v2.2.2 hotfix: COMPLETED statuszra valtaskor a kenyleges
            // keszletmozgas bejegyzese per line (vault CurrencyStock -= amount,
            // target branch cash_balance += amount). Idempotent: csak ha
            // valtott COMPLETED-re.
            if (oldStatus != VaultOperationStatus.COMPLETED) {
                for (VaultDistributionLine line : distribution.getLines()) {
                    vaultStockFlowService.applyDistributionLine(
                            companyId,
                            line.getTargetBranchCode(),
                            line.getCurrencyCode(),
                            line.getAmount()
                    );
                }
            }
        }

        return toDto(vaultDistributionRepository.save(distribution));
    }

    private DistributionResponseDto toDto(VaultDistribution entity) {
        List<DistributionLineDto> lineDtos = entity.getLines().stream()
                .map(line -> DistributionLineDto.builder()
                        .targetBranchCode(line.getTargetBranchCode())
                        .targetBranchName(line.getTargetBranchName())
                        .currencyCode(line.getCurrencyCode())
                        .amount(line.getAmount())
                        .build())
                .collect(Collectors.toList());

        return DistributionResponseDto.builder()
                .id(entity.getId())
                .status(entity.getStatus().name())
                .note(entity.getNote())
                .createdAt(entity.getCreatedAt())
                .completedAt(entity.getCompletedAt())
                .lines(lineDtos)
                .build();
    }
}
