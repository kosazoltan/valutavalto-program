package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.user.UserDetailDto;
import hu.puzzleir.valuta.entity.Worker;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final WorkerRepository workerRepository;
    private final PasswordEncoder passwordEncoder;

    public List<UserDetailDto> listUsers() {
        return workerRepository.findAll().stream().map(this::toDto).collect(Collectors.toList());
    }

    public UserDetailDto getUserById(Long id) {
        return toDto(findOrThrow(id));
    }

    public UserDetailDto getCurrentUser(Long workerId) {
        return toDto(findOrThrow(workerId));
    }

    @Transactional
    public UserDetailDto createUser(String code, String name, String email, String password, String role, String branchId) {
        Worker worker = Worker.builder()
                .code(code)
                .name(name)
                .email(email)
                .passwordHash(passwordEncoder.encode(password))
                .role(hu.puzzleir.valuta.entity.WorkerRole.valueOf(role != null ? role : "CASHIER"))
                .active(true)
                .build();
        return toDto(workerRepository.save(worker));
    }

    @Transactional
    public UserDetailDto updateUser(Long id, String email, String name, String role, Boolean active) {
        Worker w = findOrThrow(id);
        if (email != null) w.setEmail(email);
        if (name != null) w.setName(name);
        if (role != null) w.setRole(hu.puzzleir.valuta.entity.WorkerRole.valueOf(role));
        if (active != null) w.setActive(active);
        return toDto(workerRepository.save(w));
    }

    @Transactional
    public void changePassword(Long id, String newPassword) {
        Worker w = findOrThrow(id);
        w.setPasswordHash(passwordEncoder.encode(newPassword));
        workerRepository.save(w);
    }

    @Transactional
    public void updateMyPassword(Long workerId, String oldPassword, String newPassword) {
        Worker w = findOrThrow(workerId);
        if (!passwordEncoder.matches(oldPassword, w.getPasswordHash())) {
            throw new ValidationException("A régi jelszó nem megfelelő!");
        }
        w.setPasswordHash(passwordEncoder.encode(newPassword));
        workerRepository.save(w);
    }

    @Transactional
    public UserDetailDto toggleActive(Long id) {
        Worker w = findOrThrow(id);
        w.setActive(!w.getActive());
        return toDto(workerRepository.save(w));
    }

    @Transactional
    public void deleteUser(Long id) {
        workerRepository.deleteById(id);
    }

    private Worker findOrThrow(Long id) {
        return workerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Felhasználó nem található: " + id));
    }

    private UserDetailDto toDto(Worker w) {
        return UserDetailDto.builder()
                .id(String.valueOf(w.getId()))
                .username(w.getCode())
                .name(w.getName())
                .email(w.getEmail())
                .role(w.getRole() != null ? w.getRole().name() : null)
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
