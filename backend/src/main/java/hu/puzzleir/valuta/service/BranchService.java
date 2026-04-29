package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.BranchDto;
import hu.puzzleir.valuta.dto.CreateBranchDto;
import hu.puzzleir.valuta.dto.UpdateBranchDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.mapper.BranchMapper;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@Slf4j
@Transactional(rollbackFor = Exception.class)
public class BranchService {

    private final BranchRepository branchRepository;
    private final CompanyRepository companyRepository;
    private final DictionaryRepository dictionaryRepository;
    private final BranchMapper branchMapper;
    // Issue #110: kassza egyenleg auto-init új branch-nél. @Lazy a potenciális circular
    // dependency elkerülésére (CashBalanceService branchRepository-t is használ).
    private final CashBalanceService cashBalanceService;
    // 2026-04-29 v2.3.27 (B3 P0 fix): denomination auto-init új branch-nél.
    // A `DenominationService.HUF_DENOMINATIONS` 14 hivatalos magyar címlet-et tartalmaz
    // (1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000), de
    // az `initializeBranchDenominations(branchId)` metódust EDDIG SOHA NEM hívta senki —
    // ezért új branch létrehozásakor üres marad a denomination tábla.
    private final DenominationService denominationService;

    @Autowired
    public BranchService(BranchRepository branchRepository,
                         CompanyRepository companyRepository,
                         DictionaryRepository dictionaryRepository,
                         BranchMapper branchMapper,
                         @Lazy CashBalanceService cashBalanceService,
                         @Lazy DenominationService denominationService) {
        this.branchRepository = branchRepository;
        this.companyRepository = companyRepository;
        this.dictionaryRepository = dictionaryRepository;
        this.branchMapper = branchMapper;
        this.cashBalanceService = cashBalanceService;
        this.denominationService = denominationService;
    }

    /**
     * Összes fiók lekérése
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findAll() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        log.debug("Finding all branches for company: {}", companyId);
        List<Branch> branches = branchRepository.findByCompanyId(companyId);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Aktív fiókok lekérése
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findAllActive() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        log.debug("Finding all active branches for company: {}", companyId);
        // Multi-tenant-safe: company-scoped query + no post-filter stream
        List<Branch> branches = branchRepository.findByCompanyIdAndIsActiveTrue(companyId);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Fiók keresése ID alapján
     */
    @Transactional(readOnly = true)
    public BranchDto findById(UUID id) {
        log.debug("Finding branch by id: {}", id);
        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

        // IDOR védelem: csak saját cég fiókai érhetők el
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branch.getCompany() != null && !branch.getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Fiók nem található: " + id);
        }

        BranchDto dto = branchMapper.toDto(branch);
        
        // Load children IDs
        List<Branch> children = branchRepository.findByParentBranchId(id);
        dto.setChildBranchIds(children.stream()
                .map(Branch::getId)
                .collect(Collectors.toList()));
        
        return dto;
    }

    /**
     * Fiók keresése kód alapján
     */
    @Transactional(readOnly = true)
    public BranchDto findByCode(String code) {
        log.debug("Finding branch by code: {}", code);
        // Multi-tenant-safe: ceg-scoped lookup (cross-tenant leak elkerulese)
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Branch branch = branchRepository.findByCompanyIdAndCode(companyId, code)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található kóddal: " + code));
        // (korabbi IDOR redundans ellenorzes megszunt, mert a query eleve szur)

        return branchMapper.toDto(branch);
    }

    /**
     * Keresés név vagy kód szerint
     */
    @Transactional(readOnly = true)
    public List<BranchDto> search(String searchTerm) {
        log.debug("Searching branches with term: {}", searchTerm);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.searchByCompanyIdAndNameOrCode(companyId, searchTerm);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Fiókok típus szerint
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findByType(String branchTypeCode) {
        log.debug("Finding branches by type: {}", branchTypeCode);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.findByCompanyIdAndBranchTypeCode(companyId, branchTypeCode);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Fiókok státusz szerint
     */
    @Transactional(readOnly = true)
    @SuppressWarnings("deprecation") // Multi-tenant audit: ritkan hasznalt, branch_status kod egyedi cegenkent is — kicsi risk
    public List<BranchDto> findByStatus(String statusCode) {
        log.debug("Finding branches by status: {}", statusCode);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // Post-filter stream-mel company-id szures
        List<Branch> branches = branchRepository.findByBranchStatusCode(statusCode).stream()
                .filter(b -> b.getCompany() != null && b.getCompany().getId().equals(companyId))
                .collect(Collectors.toList());
        return branchMapper.toDtoList(branches);
    }

    /**
     * Gyökér fiókok (nincs szülő)
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findRootBranches() {
        log.debug("Finding root branches");
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.findRootBranchesByCompanyId(companyId);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Szülő alatti közvetlen gyermekek
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findChildren(UUID parentId) {
        log.debug("Finding children of branch: {}", parentId);
        List<Branch> branches = branchRepository.findByParentBranchId(parentId);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Útvonal a gyökérig (breadcrumb)
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findPathToRoot(UUID branchId) {
        log.debug("Finding path to root for branch: {}", branchId);
        List<Branch> path = branchRepository.findPathToRoot(branchId);
        return branchMapper.toDtoList(path);
    }

    /**
     * Új fiók létrehozása
     */
    public BranchDto create(CreateBranchDto dto) {
        log.info("Creating new branch with code: {}", dto.getCode());

        // Validációk
        validateBranchCode(dto.getCode());
        validateBranchHierarchy(dto.getBranchTypeId(), dto.getParentBranchId());

        // Entitások betöltése
        Company company = companyRepository.findById(dto.getCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Cég nem található: " + dto.getCompanyId()));

        Dictionary branchType = dictionaryRepository.findById(dto.getBranchTypeId())
                .orElseThrow(() -> new ResourceNotFoundException("Fiók típus nem található: " + dto.getBranchTypeId()));

        Dictionary country = dictionaryRepository.findById(dto.getCountryId())
                .orElseThrow(() -> new ResourceNotFoundException("Ország nem található: " + dto.getCountryId()));

        Dictionary branchStatus = dictionaryRepository.findById(dto.getBranchStatusId())
                .orElseThrow(() -> new ResourceNotFoundException("Státusz nem található: " + dto.getBranchStatusId()));

        Branch parentBranch = null;
        if (dto.getParentBranchId() != null) {
            parentBranch = branchRepository.findById(dto.getParentBranchId())
                    .orElseThrow(() -> new ResourceNotFoundException("Szülő fiók nem található: " + dto.getParentBranchId()));
        }

        // Entity létrehozása
        Branch branch = Branch.builder()
                .code(dto.getCode())
                .company(company)
                .bankCode(dto.getBankCode())
                .branchType(branchType)
                .parentBranch(parentBranch)
                .name(dto.getName())
                .address(dto.getAddress())
                .city(dto.getCity())
                .zipCode(dto.getZipCode())
                .country(country)
                .phone(dto.getPhone())
                .email(dto.getEmail())
                .branchStatus(branchStatus)
                .openingDate(dto.getOpeningDate())
                .denominationRuleId(dto.getDenominationRuleId())
                .isActive(true)
                .build();

        Branch saved = branchRepository.save(branch);
        log.info("Branch created successfully: {}", saved.getId());

        // Issue #110: automatikus kassza egyenleg inicializálás.
        // Idempotens — ha bármi okból már létezne, skip. Nem dob hibát.
        // Sourcery PR #112: narrow catch + full stack trace.
        // 2026-04-29 v2.3.29 (Sourcery P2 #292 follow-up):
        // A catch továbbra is RuntimeException-t fog (Spring DataAccessException +
        // egyéb tx-runtime-bug-okat is el akarjuk fogni), DE a log message
        // EXPLICIT TARTALMAZZA a root-cause exception-osztályt (`e.getClass()`),
        // hogy az unexpected programming error-ok detektálhatók legyenek a log-ban.
        // A Codex P1 #292 fix: a `cashBalanceService.initializeBranchBalances` és
        // `denominationService.initializeBranchDenominations` `Propagation.REQUIRES_NEW`-t
        // használ — független tx, NEM rolls back parent.
        try {
            int created = cashBalanceService.initializeBranchBalances(saved.getId());
            log.info("Branch {} cash_balance auto-init: {} új rekord", saved.getId(), created);
        } catch (RuntimeException e) {
            log.error("Branch {} cash_balance auto-init FAILED [{}: {}] (admin kézi init szükséges)",
                    saved.getId(), e.getClass().getSimpleName(), e.getMessage(), e);
        }

        // 2026-04-29 v2.3.27 (B3 P0 fix): denomination auto-init új branch-nél.
        try {
            denominationService.initializeBranchDenominations(saved.getId());
            log.info("Branch {} denomination auto-init: 14 HUF + külföldi címlet beállítva",
                    saved.getId());
        } catch (RuntimeException e) {
            log.error("Branch {} denomination auto-init FAILED [{}: {}] (admin kézi init szükséges)",
                    saved.getId(), e.getClass().getSimpleName(), e.getMessage(), e);
        }

        return branchMapper.toDto(saved);
    }

    /**
     * Fiók frissítése
     */
    public BranchDto update(UUID id, UpdateBranchDto dto) {
        log.info("Updating branch: {}", id);

        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

        // Frissíthető mezők
        if (dto.getName() != null) {
            branch.setName(dto.getName());
        }
        if (dto.getAddress() != null) {
            branch.setAddress(dto.getAddress());
        }
        if (dto.getCity() != null) {
            branch.setCity(dto.getCity());
        }
        if (dto.getZipCode() != null) {
            branch.setZipCode(dto.getZipCode());
        }
        if (dto.getCountryId() != null) {
            Dictionary country = dictionaryRepository.findById(dto.getCountryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Ország nem található: " + dto.getCountryId()));
            branch.setCountry(country);
        }
        if (dto.getPhone() != null) {
            branch.setPhone(dto.getPhone());
        }
        if (dto.getEmail() != null) {
            branch.setEmail(dto.getEmail());
        }
        if (dto.getBankCode() != null) {
            branch.setBankCode(dto.getBankCode());
        }
        if (dto.getBranchStatusId() != null) {
            Dictionary status = dictionaryRepository.findById(dto.getBranchStatusId())
                    .orElseThrow(() -> new ResourceNotFoundException("Státusz nem található: " + dto.getBranchStatusId()));
            branch.setBranchStatus(status);
        }
        if (dto.getOpeningDate() != null) {
            branch.setOpeningDate(dto.getOpeningDate());
        }
        if (dto.getDenominationRuleId() != null) {
            branch.setDenominationRuleId(dto.getDenominationRuleId());
        }
        if (dto.getIsActive() != null) {
            branch.setIsActive(dto.getIsActive());
        }

        Branch updated = branchRepository.save(branch);
        log.info("Branch updated successfully: {}", id);

        return branchMapper.toDto(updated);
    }

    /**
     * Fiók törlése (soft delete)
     */
    public void delete(UUID id) {
        log.info("Deleting branch: {}", id);

        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található: " + id));

        // Ellenőrzés: van-e gyermeke
        List<Branch> children = branchRepository.findByParentBranchId(id);
        if (!children.isEmpty()) {
            throw new ValidationException("Nem törölhető fiók, aminek vannak alá rendelt fiókok");
        }

        // Soft delete
        branch.setIsActive(false);
        branchRepository.save(branch);

        log.info("Branch deleted successfully: {}", id);
    }

    // ===== Private Helper Methods =====

    private void validateBranchCode(String code) {
        // Multi-tenant-safe: csak a sajat cegben ellenorizni
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branchRepository.existsByCompanyIdAndCode(companyId, code)) {
            throw new ValidationException("Már létezik fiók ezzel a kóddal: " + code);
        }
    }

    private void validateBranchHierarchy(UUID branchTypeId, UUID parentBranchId) {
        Dictionary branchType = dictionaryRepository.findById(branchTypeId)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók típus nem található: " + branchTypeId));

        String typeCode = branchType.getCode();

        // KÖZPONT: nincs szülő
        if ("KOZPONT".equals(typeCode) && parentBranchId != null) {
            throw new ValidationException("Központ nem lehet más alá rendelve");
        }

        // FŐÉRTÉKTÁR: szülő kötelező és csak KÖZPONT lehet
        if ("FOERTEKTAR".equals(typeCode)) {
            if (parentBranchId == null) {
                throw new ValidationException("Főértéktárnak kötelező szülő");
            }
            Branch parent = branchRepository.findById(parentBranchId)
                    .orElseThrow(() -> new ResourceNotFoundException("Szülő fiók nem található"));
            if (!"KOZPONT".equals(parent.getBranchType().getCode())) {
                throw new ValidationException("Főértéktár csak központ alá helyezhető");
            }
        }

        // ÉRTÉKTÁR: szülő kötelező és KÖZPONT vagy FŐÉRTÉKTÁR lehet
        if ("ERTEKTAR".equals(typeCode)) {
            if (parentBranchId == null) {
                throw new ValidationException("Értéktárnak kötelező szülő");
            }
            Branch parent = branchRepository.findById(parentBranchId)
                    .orElseThrow(() -> new ResourceNotFoundException("Szülő fiók nem található"));
            String parentCode = parent.getBranchType().getCode();
            if (!"KOZPONT".equals(parentCode) && !"FOERTEKTAR".equals(parentCode)) {
                throw new ValidationException("Értéktár csak központ vagy főértéktár alá helyezhető");
            }
        }

        // PÉNZTÁR: szülő kötelező és csak ÉRTÉKTÁR lehet
        if ("PENZTAR".equals(typeCode)) {
            if (parentBranchId == null) {
                throw new ValidationException("Pénztárnak kötelező szülő");
            }
            Branch parent = branchRepository.findById(parentBranchId)
                    .orElseThrow(() -> new ResourceNotFoundException("Szülő fiók nem található"));
            if (!"ERTEKTAR".equals(parent.getBranchType().getCode())) {
                throw new ValidationException("Pénztár csak értéktár alá helyezhető");
            }
        }
    }
}
