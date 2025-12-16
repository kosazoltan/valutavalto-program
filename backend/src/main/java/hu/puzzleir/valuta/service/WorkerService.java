package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.auth.LoginRequestDto;
import hu.puzzleir.valuta.dto.auth.LoginResponseDto;
import hu.puzzleir.valuta.dto.worker.ChangePasswordDto;
import hu.puzzleir.valuta.dto.worker.CreateWorkerDto;
import hu.puzzleir.valuta.dto.worker.UpdateWorkerDto;
import hu.puzzleir.valuta.dto.worker.WorkerDto;
import hu.puzzleir.valuta.entity.*;
import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.JwtTokenProvider;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Worker service - business logic multi-tenant supporttal.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class WorkerService {
    
    private final WorkerRepository workerRepository;
    private final WorkerSessionRepository sessionRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    
    /**
     * Worker létrehozás
     */
    public WorkerDto createWorker(CreateWorkerDto dto) {
        // Company validation
        Company company = companyRepository.findById(dto.getCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található: " + dto.getCompanyId()));
        
        // Branch validation (ugyanazon company-hoz tartozik?)
        Branch branch = branchRepository.findById(dto.getBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + dto.getBranchId()));
        
        if (!branch.getCompany().getId().equals(dto.getCompanyId())) {
            throw new ValidationException("Áz iroda nem tartozik ehhez a céghez!");
        }
        
        // Code uniqueness (company-n belül)
        if (workerRepository.existsByCompanyIdAndCode(dto.getCompanyId(), dto.getCode())) {
            throw new ValidationException("Ez a pénztáros kód már létezik ebben a cégben: " + dto.getCode());
        }
        
        // Worker entity build
        Worker worker = Worker.builder()
                .company(company)
                .code(dto.getCode())
                .name(dto.getName())
                .passwordHash(passwordEncoder.encode(dto.getPassword()))
                .role(dto.getRole())
                .branch(branch)
                .active(true)
                .phone(dto.getPhone())
                .email(dto.getEmail())
                .otpUserId(dto.getOtpUserId())
                .otpEnabled(dto.getOtpEnabled() != null ? dto.getOtpEnabled() : false)
                .passwordChangedAt(LocalDateTime.now())
                .build();
        
        Worker saved = workerRepository.save(worker);
        return WorkerDto.from(saved);
    }
    
    /**
     * Worker módosítás
     */
    public WorkerDto updateWorker(Long id, UpdateWorkerDto dto) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        
        Worker worker = workerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + id));
        
        // Multi-tenant check
        if (!worker.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }
        
        // Update fields (csak a nem-null értékek)
        if (dto.getName() != null) {
            worker.setName(dto.getName());
        }
        if (dto.getRole() != null) {
            // Csak ADMIN vagy MANAGER változtathat role-t
            if (!SecurityUtils.isAdmin() && !SecurityUtils.getCurrentRole().equals("MANAGER")) {
                throw new ValidationException("Nincs jogosultsága szerepkör módosításhoz!");
            }
            worker.setRole(dto.getRole());
        }
        if (dto.getBranchId() != null) {
            Branch branch = branchRepository.findById(dto.getBranchId())
                    .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + dto.getBranchId()));
            
            if (!branch.getCompany().getId().equals(companyId)) {
                throw new ValidationException("Az iroda nem tartozik ehhez a céghez!");
            }
            worker.setBranch(branch);
        }
        if (dto.getPhone() != null) {
            worker.setPhone(dto.getPhone());
        }
        if (dto.getEmail() != null) {
            worker.setEmail(dto.getEmail());
        }
        if (dto.getActive() != null) {
            worker.setActive(dto.getActive());
        }
        if (dto.getOtpUserId() != null) {
            worker.setOtpUserId(dto.getOtpUserId());
        }
        if (dto.getOtpEnabled() != null) {
            worker.setOtpEnabled(dto.getOtpEnabled());
        }
        
        Worker updated = workerRepository.save(worker);
        return WorkerDto.from(updated);
    }
    
    /**
     * Jelszóváltoztatás
     */
    public void changePassword(Long workerId, ChangePasswordDto dto) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + workerId));
        
        // Multi-tenant check
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (!worker.getCompany().getId().equals(currentCompanyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }
        
        // Régi jelszó ellenőrzés
        if (!passwordEncoder.matches(dto.getOldPassword(), worker.getPasswordHash())) {
            throw new ValidationException("Hibás régi jelszó!");
        }
        
        // Új jelszó beállítás
        worker.setPasswordHash(passwordEncoder.encode(dto.getNewPassword()));
        worker.setPasswordChangedAt(LocalDateTime.now());
        
        workerRepository.save(worker);
    }
    
    /**
     * Worker inaktiválás
     */
    public void deactivateWorker(Long id) {
        Worker worker = workerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + id));
        
        // Multi-tenant check
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!worker.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }
        
        worker.setActive(false);
        workerRepository.save(worker);
    }
    
    /**
     * Worker aktiválás
     */
    public void activateWorker(Long id) {
        Worker worker = workerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + id));
        
        // Multi-tenant check
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!worker.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }
        
        worker.setActive(true);
        workerRepository.save(worker);
    }
    
    /**
     * Worker keresés ID alapján
     */
    @Transactional(readOnly = true)
    public WorkerDto findById(Long id) {
        Worker worker = workerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + id));
        
        // Multi-tenant check
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!worker.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez a dolgozóhoz!");
        }
        
        return WorkerDto.from(worker);
    }
    
    /**
     * Company összes dolgozója
     */
    @Transactional(readOnly = true)
    public List<WorkerDto> findAllByCompany() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return workerRepository.findByCompanyId(companyId).stream()
                .map(WorkerDto::from)
                .collect(Collectors.toList());
    }
    
    /**
     * Aktív dolgozók
     */
    @Transactional(readOnly = true)
    public List<WorkerDto> findActiveWorkers() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return workerRepository.findByCompanyIdAndActiveTrue(companyId).stream()
                .map(WorkerDto::from)
                .collect(Collectors.toList());
    }
    
    /**
     * Dolgozók egy irodában
     */
    @Transactional(readOnly = true)
    public List<WorkerDto> findByBranch(UUID branchId) {
        // Branch létezés + multi-tenant check
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
        
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (!branch.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Nincs jogosultsága ehhez az irodához!");
        }
        
        return workerRepository.findActiveWorkersByBranch(branchId).stream()
                .map(WorkerDto::from)
                .collect(Collectors.toList());
    }
    
    /**
     * Login
     */
    public LoginResponseDto login(LoginRequestDto dto, String ipAddress, String userAgent) {
        // Company keresés
        Company company = companyRepository.findByCode(dto.getCompanyCode())
                .orElseThrow(() -> new ValidationException("Hibás cégkód!"));
        
        // Worker keresés
        Worker worker = workerRepository.findByCompanyIdAndCode(company.getId(), dto.getWorkerCode())
                .orElseThrow(() -> new ValidationException("Hibás pénztáros kód vagy jelszó!"));
        
        // Aktív check
        if (!worker.getActive()) {
            throw new ValidationException("Ez a pénztáros inaktív!");
        }
        
        // Jelszó check
        if (!passwordEncoder.matches(dto.getPassword(), worker.getPasswordHash())) {
            throw new ValidationException("Hibás pénztáros kód vagy jelszó!");
        }
        
        // Branch check (ha megadva)
        if (dto.getBranchId() != null) {
            Branch branch = branchRepository.findById(dto.getBranchId())
                    .orElseThrow(() -> new ValidationException("Hibás iroda ID!"));
            
            if (!branch.getCompany().getId().equals(company.getId())) {
                throw new ValidationException("Az iroda nem tartozik ehhez a céghez!");
            }
            
            worker.setBranch(branch);
        }
        
        // JWT token generálás
        String token = jwtTokenProvider.generateToken(worker);
        String tokenId = jwtTokenProvider.getTokenIdFromToken(token);
        
        // Session tracking
        WorkerSession session = WorkerSession.builder()
                .company(company)
                .worker(worker)
                .branch(worker.getBranch())
                .loginAt(LocalDateTime.now())
                .ipAddress(ipAddress)
                .userAgent(userAgent)
                .tokenId(tokenId)
                .build();
        
        sessionRepository.save(session);
        
        // Last login frissítés
        worker.setLastLoginAt(LocalDateTime.now());
        workerRepository.save(worker);
        
        return LoginResponseDto.builder()
                .token(token)
                .worker(WorkerDto.from(worker))
                .expiresIn(86400000L) // 24 óra millisec
                .build();
    }
    
    /**
     * Logout
     */
    public void logout() {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        
        // Aktív session bezárás
        sessionRepository.findByWorkerIdAndLogoutAtIsNull(workerId)
                .ifPresent(session -> {
                    session.setLogoutAt(LocalDateTime.now());
                    sessionRepository.save(session);
                });
    }
}
