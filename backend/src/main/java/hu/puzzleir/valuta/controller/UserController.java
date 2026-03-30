package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.user.CreateUserRequest;
import hu.puzzleir.valuta.dto.user.UpdateUserRequest;
import hu.puzzleir.valuta.dto.user.ChangePasswordRequest;
import hu.puzzleir.valuta.dto.user.UpdateMyPasswordRequest;
import hu.puzzleir.valuta.dto.user.UserDetailDto;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<List<UserDetailDto>> list() {
        return ResponseEntity.ok(userService.listUsers());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<UserDetailDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(userService.getUserById(id));
    }

    @GetMapping("/me")
    public ResponseEntity<UserDetailDto> getCurrentUser(Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(userService.getCurrentUser(workerId));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<UserDetailDto> create(@Valid @RequestBody CreateUserRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(userService.createUser(
                request.getUsername(), request.getFullName(), request.getEmail(),
                request.getPassword(), request.getRoleId(), request.getBranchId()));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<UserDetailDto> update(@PathVariable Long id, @Valid @RequestBody UpdateUserRequest request) {
        return ResponseEntity.ok(userService.updateUser(id,
                request.getEmail(), request.getFullName(),
                request.getRoleId(), request.getActive()));
    }

    @PostMapping("/{id}/change-password")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> changePassword(@PathVariable Long id, @Valid @RequestBody ChangePasswordRequest request) {
        userService.changePassword(id, request.getNewPassword());
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/me/password")
    public ResponseEntity<Void> updateMyPassword(Authentication auth, @Valid @RequestBody UpdateMyPasswordRequest request) {
        Long workerId = getWorkerId(auth);
        userService.updateMyPassword(workerId, request.getOldPassword(), request.getNewPassword());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/toggle-active")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<UserDetailDto> toggleActive(@PathVariable Long id) {
        return ResponseEntity.ok(userService.toggleActive(id));
    }

    @PostMapping("/{id}/archive")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> archive(@PathVariable Long id) {
        userService.toggleActive(id); // archive = deactivate
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        userService.deleteUser(id);
        return ResponseEntity.noContent().build();
    }

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new hu.puzzleir.valuta.exception.ValidationException("Hitelesítés szükséges!");
    }
}
