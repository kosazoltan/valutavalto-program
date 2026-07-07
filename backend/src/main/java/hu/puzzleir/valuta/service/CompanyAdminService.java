package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DataChangeSource;
import hu.puzzleir.valuta.entity.ReviewStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.dto.admin.*;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.repository.SyncLogRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Cég és fiók adminisztráció szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class CompanyAdminService {

    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final WorkerRepository workerRepository;
    private final SyncLogRepository syncLogRepository;
    private final CompanyVersionService companyVersionService;

    /**
     * Cég részletes adatainak lekérése.
     */
    @Transactional(readOnly = true)
    public CompanyDetailsDto getCompanyDetails(UUID companyId) {
        Company company = companyRepository.findById(companyId)
            .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));

        List<Branch> branches = branchRepository.findByCompanyId(companyId);
        long activeBranches = branches.stream().filter(b -> Boolean.TRUE.equals(b.getIsActive())).count();
        long totalWorkers = workerRepository.countActiveWorkersByCompany(companyId);

        List<CompanyDetailsDto.BranchSummaryDto> branchSummaries = branches.stream()
            .map(b -> CompanyDetailsDto.BranchSummaryDto.builder()
                .id(b.getId().toString())
                .code(b.getCode())
                .name(b.getName())
                .city(b.getCity())
                .active(Boolean.TRUE.equals(b.getIsActive()))
                .build())
            .toList();

        return CompanyDetailsDto.builder()
            .id(company.getId().toString())
            .code(company.getCode())
            .name(company.getName())
            .taxNumber(company.getTaxNumber())
            .registrationNumber(company.getRegistrationNumber())
            .address(company.getAddress())
            .phone(company.getPhone())
            .email(company.getEmail())
            .active(Boolean.TRUE.equals(company.getIsActive()))
            .activeBranchCount((int) activeBranches)
            .totalWorkerCount((int) totalWorkers)
            .dailyTurnoverHuf(BigDecimal.ZERO) // számítás a tranzakciókból szükség esetén
            .branches(branchSummaries)
            .build();
    }

    /**
     * Cég adatainak frissítése.
     */
    public Company updateCompany(UUID companyId, CompanyUpdateDto dto) {
        Company company = companyRepository.findById(companyId)
            .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + companyId));

        if (dto.getName() != null) company.setName(dto.getName());
        if (dto.getTaxNumber() != null) company.setTaxNumber(dto.getTaxNumber());
        if (dto.getRegistrationNumber() != null) company.setRegistrationNumber(dto.getRegistrationNumber());
        if (dto.getAddress() != null) company.setAddress(dto.getAddress());
        if (dto.getPhone() != null) company.setPhone(dto.getPhone());
        if (dto.getEmail() != null) company.setEmail(dto.getEmail());

        boolean changed = companyVersionService.hasDataChanged(company);
        if (changed) {
            company.setReviewStatus(ReviewStatus.REVIEWED);
            company.setReviewedBy(SecurityUtils.getCurrentWorkerCode());
            company.setReviewedAt(LocalDateTime.now());
        }
        Company saved = companyRepository.save(company);
        if (changed) {
            companyVersionService.recordVersion(saved,
                    SecurityUtils.isComplianceSide() ? DataChangeSource.COMPLIANCE : DataChangeSource.CASHIER);
        }
        log.info("Cég adatok frissítve: id={}, name={}", companyId, company.getName());
        return saved;
    }

    /**
     * Fiók részletes adatainak lekérése.
     */
    @Transactional(readOnly = true)
    public BranchDetailsDto getBranchDetails(UUID branchId) {
        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + branchId));

        long workerCount = workerRepository.countActiveWorkersByBranch(branchId);

        // Utolsó sync lekérése
        List<hu.puzzleir.valuta.entity.SyncLog> lastSyncs = syncLogRepository.findLastCompletedByBranch(branchId);
        String lastSync = lastSyncs.isEmpty() ? null : lastSyncs.get(0).getCompletedAt() != null
            ? lastSyncs.get(0).getCompletedAt().toString() : null;

        return BranchDetailsDto.builder()
            .id(branch.getId().toString())
            .code(branch.getCode())
            .name(branch.getName())
            .address(branch.getAddress())
            .city(branch.getCity())
            .zipCode(branch.getZipCode())
            .phone(branch.getPhone())
            .email(branch.getEmail())
            .active(Boolean.TRUE.equals(branch.getIsActive()))
            .companyId(branch.getCompany().getId().toString())
            .companyName(branch.getCompany().getName())
            .workerCount((int) workerCount)
            .totalInventoryHuf(BigDecimal.ZERO) // bővíthető a CashBalance-ból
            .lastSyncAt(lastSync)
            .openingHours("H-P: 08:00-18:00") // default, bővíthető
            .build();
    }

    /**
     * Fiók adatainak frissítése.
     */
    public Branch updateBranch(UUID branchId, BranchUpdateDto dto) {
        Branch branch = branchRepository.findById(branchId)
            .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + branchId));

        if (dto.getName() != null) branch.setName(dto.getName());
        if (dto.getAddress() != null) branch.setAddress(dto.getAddress());
        if (dto.getCity() != null) branch.setCity(dto.getCity());
        if (dto.getZipCode() != null) branch.setZipCode(dto.getZipCode());
        if (dto.getPhone() != null) branch.setPhone(dto.getPhone());
        if (dto.getEmail() != null) branch.setEmail(dto.getEmail());

        log.info("Fiók adatok frissítve: id={}, name={}", branchId, branch.getName());
        return branchRepository.save(branch);
    }

    /**
     * Összes fiók statisztikákkal.
     */
    @Transactional(readOnly = true)
    public List<BranchWithStatsDto> getAllBranchesWithStats() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return branchRepository.findByCompanyId(companyId).stream()
            .map(branch -> {
                long workerCount = workerRepository.countActiveWorkersByBranch(branch.getId());

                List<hu.puzzleir.valuta.entity.SyncLog> branchSyncs = syncLogRepository.findLastCompletedByBranch(branch.getId());
                String lastSync = branchSyncs.isEmpty() ? null : branchSyncs.get(0).getCompletedAt() != null
                    ? branchSyncs.get(0).getCompletedAt().toString() : null;

                String syncStatus = lastSync != null ? "SYNCED" : "NEVER";

                return BranchWithStatsDto.builder()
                    .id(branch.getId().toString())
                    .code(branch.getCode())
                    .name(branch.getName())
                    .city(branch.getCity())
                    .companyName(branch.getCompany().getName())
                    .active(Boolean.TRUE.equals(branch.getIsActive()))
                    .workerCount((int) workerCount)
                    .dailyTurnoverHuf(BigDecimal.ZERO)
                    .lastSyncAt(lastSync)
                    .syncStatus(syncStatus)
                    .build();
            })
            .toList();
    }
}
