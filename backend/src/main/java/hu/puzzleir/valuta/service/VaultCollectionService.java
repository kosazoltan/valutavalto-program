package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.CollectionRequestDto;
import hu.puzzleir.valuta.dto.ertektar.CollectionResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.VaultCollection;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.VaultCollectionRepository;
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
public class VaultCollectionService {

    private final VaultCollectionRepository vaultCollectionRepository;
    private final BranchRepository branchRepository;

    @Transactional(readOnly = true)
    public List<CollectionResponseDto> getCollections() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return vaultCollectionRepository.findByCompanyIdOrderByRequestedAtDesc(companyId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Transactional(rollbackFor = Exception.class)
    public CollectionResponseDto createCollection(CollectionRequestDto request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // Resolve branch name
        String branchName = branchRepository.findByCompanyIdAndCode(companyId, request.getSourceBranchCode())
                .map(Branch::getName)
                .orElse(request.getSourceBranchCode());

        Long workerId = SecurityUtils.getCurrentWorkerId();

        VaultCollection collection = VaultCollection.builder()
                .companyId(companyId)
                .sourceBranchCode(request.getSourceBranchCode())
                .sourceBranchName(branchName)
                .currencyCode(request.getCurrencyCode())
                .amount(request.getAmount())
                .status(VaultOperationStatus.REQUESTED)
                .requestedAt(LocalDateTime.now())
                .note(request.getNote())
                .requestedBy(workerId)
                .build();

        VaultCollection saved = vaultCollectionRepository.save(collection);
        log.info("Begyujtés létrehozva: branch={}, currency={}, amount={}, company={}",
                request.getSourceBranchCode(), request.getCurrencyCode(), request.getAmount(), companyId);

        return toDto(saved);
    }

    @Transactional(rollbackFor = Exception.class)
    public CollectionResponseDto updateStatus(Long id, VaultOperationStatus newStatus) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        VaultCollection collection = vaultCollectionRepository.findById(id)
                .filter(c -> c.getCompanyId().equals(companyId))
                .orElseThrow(() -> new ResourceNotFoundException("Begyujtés nem található: " + id));

        collection.setStatus(newStatus);
        if (newStatus == VaultOperationStatus.COMPLETED) {
            collection.setCompletedAt(LocalDateTime.now());
        }

        return toDto(vaultCollectionRepository.save(collection));
    }

    private CollectionResponseDto toDto(VaultCollection entity) {
        return CollectionResponseDto.builder()
                .id(entity.getId())
                .sourceBranchCode(entity.getSourceBranchCode())
                .sourceBranchName(entity.getSourceBranchName())
                .currencyCode(entity.getCurrencyCode())
                .amount(entity.getAmount())
                .status(entity.getStatus().name())
                .requestedAt(entity.getRequestedAt())
                .completedAt(entity.getCompletedAt())
                .note(entity.getNote())
                .build();
    }
}
