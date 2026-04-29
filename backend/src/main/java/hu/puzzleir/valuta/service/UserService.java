package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.user.UserDetailDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final WorkerRepository workerRepository;
    private final BranchRepository branchRepository;
    private final CompanyRepository companyRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<UserDetailDto> listUsers() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return workerRepository.findByCompanyId(companyId).stream().map(this::toDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public UserDetailDto getUserById(Long id) {
        return toDto(findOrThrowScoped(id));
    }

    @Transactional(readOnly = true)
    public UserDetailDto getCurrentUser(Long workerId) {
        // getCurrentUser az auth-ból jövő workerId-t használja — saját user, nem kell company scope
        return toDto(workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Felhasználó nem található: " + workerId)));
    }

    @Transactional(rollbackFor = Exception.class)
    public UserDetailDto createUser(String code, String name, String email, String password, String role, String branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ValidationException("Cég nem található: " + companyId));

        // Branch feloldás — kötelező
        String resolvedBranchId = (branchId == null || branchId.isBlank())
                ? SecurityUtils.getCurrentBranchId().toString()
                : branchId;
        UUID branchUuid;
        try {
            branchUuid = UUID.fromString(resolvedBranchId);
        } catch (IllegalArgumentException e) {
            throw new ValidationException("Érvénytelen iroda azonosító: " + resolvedBranchId);
        }
        Branch branch = branchRepository.findById(branchUuid)
                .orElseThrow(() -> new ValidationException("Iroda nem található: " + branchId));
        // Ellenőrzés: branch a current company-hoz tartozik
        if (branch.getCompany() != null && !companyId.equals(branch.getCompany().getId())) {
            throw new ValidationException("Az iroda nem tartozik az aktuális céghez!");
        }

        // Code egyediség ellenőrzés
        if (workerRepository.existsByCompanyIdAndCode(companyId, code)) {
            throw new ValidationException("A kód már használatban van: " + code);
        }

        Worker worker = Worker.builder()
                .code(code)
                .name(name)
                .email(email)
                .passwordHash(passwordEncoder.encode(password))
                .role(hu.puzzleir.valuta.entity.WorkerRole.valueOf(role != null ? role : "CASHIER"))
                .company(company)
                .branch(branch)
                .active(true)
                .build();
        return toDto(workerRepository.save(worker));
    }

    @Transactional(rollbackFor = Exception.class)
    public UserDetailDto updateUser(Long id, String email, String name, String role, Boolean active) {
        Worker w = findOrThrowScoped(id);
        if (email != null) w.setEmail(email);
        if (name != null) w.setName(name);
        if (role != null) w.setRole(hu.puzzleir.valuta.entity.WorkerRole.valueOf(role));
        if (active != null) w.setActive(active);
        return toDto(workerRepository.save(w));
    }

    @Transactional(rollbackFor = Exception.class)
    public void changePassword(Long id, String newPassword) {
        Worker w = findOrThrowScoped(id);
        w.setPasswordHash(passwordEncoder.encode(newPassword));
        workerRepository.save(w);
    }

    @Transactional(rollbackFor = Exception.class)
    public void updateMyPassword(Long workerId, String oldPassword, String newPassword) {
        // Saját jelszócsere — workerId az auth-ból jön, nem kell company scope
        Worker w = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Felhasználó nem található: " + workerId));
        if (!passwordEncoder.matches(oldPassword, w.getPasswordHash())) {
            throw new ValidationException("A régi jelszó nem megfelelő!");
        }
        w.setPasswordHash(passwordEncoder.encode(newPassword));
        workerRepository.save(w);
    }

    @Transactional(rollbackFor = Exception.class)
    public UserDetailDto toggleActive(Long id) {
        Worker w = findOrThrowScoped(id);
        w.setActive(!w.getActive());
        return toDto(workerRepository.save(w));
    }

    @Transactional(rollbackFor = Exception.class)
    public void deleteUser(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        // Ellenőrzés: a user a saját céghez tartozik
        findOrThrowScoped(id);
        workerRepository.deleteByIdAndCompanyId(id, companyId);
    }

    /**
     * Multi-tenant scoped lookup — IDOR védelem.
     * Mindig a bejelentkezett cég companyId-jára szűr.
     */
    private Worker findOrThrowScoped(Long id) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return workerRepository.findByIdAndCompanyId(id, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Felhasználó nem található: " + id));
    }

    private UserDetailDto toDto(Worker w) {
        // v2.3.42 (B15 audit fix): a frontend a roles[] (List<String>) tomb-ot
        // rendert badge-ekkent. Korabban ez UserDetailDto-ban NEM volt feltoltve,
        // ezert a UserPage SZEREPKÖRÖK oszlopa "—" szignalt minden user-nel.
        // Most: a Worker.role (single enum) -> List.of(role.name()) mapping.
        String singleRole = w.getRole() != null ? w.getRole().name() : null;
        List<String> rolesList = singleRole != null ? List.of(singleRole) : List.of();

        return UserDetailDto.builder()
                .id(String.valueOf(w.getId()))
                .username(w.getCode())
                .name(w.getName())
                .email(w.getEmail())
                .role(singleRole)
                .roles(rolesList)
                .isActive(w.getActive())
                .lastLoginAt(w.getLastLoginAt() != null ? w.getLastLoginAt().toString() : null)
                .createdAt(w.getCreatedAt() != null ? w.getCreatedAt().toString() : null)
                .workerId(String.valueOf(w.getId()))
                .workerName(w.getName())
                .defaultBranchId(w.getBranch() != null ? w.getBranch().getId().toString() : null)
                .defaultBranchName(w.getBranch() != null ? w.getBranch().getName() : null)
                .build();
    }
}
