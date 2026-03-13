package hu.puzzleir.valuta.controller;

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
import java.util.Map;

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
    public ResponseEntity<UserDetailDto> create(@Valid @RequestBody Map<String, String> body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(userService.createUser(
                body.get("username"), body.get("fullName"), body.get("email"),
                body.get("password"), body.get("roleId"), body.get("branchId")));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<UserDetailDto> update(@PathVariable Long id, @Valid @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(userService.updateUser(id,
                (String) body.get("email"), (String) body.get("fullName"),
                (String) body.get("roleId"),
                body.containsKey("active") ? (Boolean) body.get("active") : null));
    }

    @PostMapping("/{id}/change-password")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> changePassword(@PathVariable Long id, @Valid @RequestBody Map<String, String> body) {
        userService.changePassword(id, body.get("newPassword"));
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/me/password")
    public ResponseEntity<Void> updateMyPassword(Authentication auth, @Valid @RequestBody Map<String, String> body) {
        Long workerId = getWorkerId(auth);
        userService.updateMyPassword(workerId, body.get("oldPassword"), body.get("newPassword"));
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
