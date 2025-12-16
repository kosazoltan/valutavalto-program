package com.puzzleir.backend.service;

import com.puzzleir.backend.dto.BranchDto;
import com.puzzleir.backend.dto.CreateBranchDto;
import com.puzzleir.backend.dto.UpdateBranchDto;
import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.entity.Dictionary;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.mapper.BranchMapper;
import com.puzzleir.backend.repository.BranchRepository;
import com.puzzleir.backend.repository.CompanyRepository;
import com.puzzleir.backend.repository.DictionaryRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class BranchService {

    private final BranchRepository branchRepository;
    private final CompanyRepository companyRepository;
    private final DictionaryRepository dictionaryRepository;
    private final BranchMapper branchMapper;

    /**
     * Összes fiók lekérése
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findAll() {
        log.debug("Finding all branches");
        List<Branch> branches = branchRepository.findAll();
        return branchMapper.toDtoList(branches);
    }

    /**
     * Aktív fiókok lekérése
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findAllActive() {
        log.debug("Finding all active branches");
        List<Branch> branches = branchRepository.findByIsActiveTrue();
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
        Branch branch = branchRepository.findByCode(code)
                .orElseThrow(() -> new ResourceNotFoundException("Fiók nem található kóddal: " + code));
        return branchMapper.toDto(branch);
    }

    /**
     * Keresés név vagy kód szerint
     */
    @Transactional(readOnly = true)
    public List<BranchDto> search(String searchTerm) {
        log.debug("Searching branches with term: {}", searchTerm);
        List<Branch> branches = branchRepository.searchByNameOrCode(searchTerm);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Fiókok típus szerint
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findByType(String branchTypeCode) {
        log.debug("Finding branches by type: {}", branchTypeCode);
        List<Branch> branches = branchRepository.findByBranchTypeCode(branchTypeCode);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Fiókok státusz szerint
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findByStatus(String statusCode) {
        log.debug("Finding branches by status: {}", statusCode);
        List<Branch> branches = branchRepository.findByBranchStatusCode(statusCode);
        return branchMapper.toDtoList(branches);
    }

    /**
     * Gyökér fiókok (nincs szülő)
     */
    @Transactional(readOnly = true)
    public List<BranchDto> findRootBranches() {
        log.debug("Finding root branches");
        List<Branch> branches = branchRepository.findRootBranches();
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
        if (branchRepository.existsByCode(code)) {
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
