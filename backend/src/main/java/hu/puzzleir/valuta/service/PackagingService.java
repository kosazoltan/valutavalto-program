package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.packaging.CreatePackagingRecordDto;
import hu.puzzleir.valuta.dto.packaging.PackagingRecordDto;
import hu.puzzleir.valuta.entity.PackagingRecord;
import hu.puzzleir.valuta.repository.PackagingRecordRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Göngyöleg (bankjegy csomagolás) kezelési szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class PackagingService {

    private final PackagingRecordRepository repository;
    private final BranchRepository branchRepository;

    @Transactional
    public PackagingRecordDto create(CreatePackagingRecordDto dto) {
        Branch branch = branchRepository.findById(dto.getBranchId())
            .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + dto.getBranchId()));

        PackagingRecord record = PackagingRecord.builder()
            .branch(branch)
            .currencyCode(dto.getCurrencyCode())
            .packagingDate(dto.getPackagingDate())
            .bundleCount(dto.getBundleCount())
            .denomination(dto.getDenomination())
            .bundleSize(dto.getBundleSize() != null ? dto.getBundleSize() : 100)
            .notes(dto.getNotes())
            .build();

        record = repository.save(record);
        log.info("Göngyöleg rekord létrehozva: branch={}, currency={}, bundles={}",
            dto.getBranchId(), dto.getCurrencyCode(), dto.getBundleCount());

        return toDto(record);
    }

    @Transactional(readOnly = true)
    public List<PackagingRecordDto> getByBranch(UUID branchId, LocalDate from, LocalDate to) {
        if (from != null && to != null) {
            return repository.findByBranchIdAndPackagingDateBetweenOrderByPackagingDateDesc(branchId, from, to)
                .stream().map(this::toDto).toList();
        }
        return repository.findByBranchIdOrderByPackagingDateDesc(branchId)
            .stream().map(this::toDto).toList();
    }

    @Transactional
    public void delete(UUID id) {
        if (!repository.existsById(id)) {
            throw new ResourceNotFoundException("Göngyöleg rekord nem található: " + id);
        }
        repository.deleteById(id);
        log.info("Göngyöleg rekord törölve: id={}", id);
    }

    private PackagingRecordDto toDto(PackagingRecord entity) {
        return PackagingRecordDto.builder()
            .id(entity.getId())
            .branchId(entity.getBranch().getId())
            .currencyCode(entity.getCurrencyCode())
            .packagingDate(entity.getPackagingDate())
            .bundleCount(entity.getBundleCount())
            .denomination(entity.getDenomination())
            .bundleSize(entity.getBundleSize())
            .notes(entity.getNotes())
            .createdAt(entity.getCreatedAt())
            .build();
    }
}
