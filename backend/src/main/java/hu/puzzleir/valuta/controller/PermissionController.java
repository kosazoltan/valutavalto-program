package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.role.PermissionDto;
import hu.puzzleir.valuta.service.RoleService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/permissions")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class PermissionController {

    private final RoleService roleService;

    @GetMapping
    public ResponseEntity<List<PermissionDto>> list() {
        return ResponseEntity.ok(roleService.listPermissions());
    }

    @GetMapping("/active")
    public ResponseEntity<List<PermissionDto>> listActive() {
        return ResponseEntity.ok(roleService.listActivePermissions());
    }

    @GetMapping("/module/{module}")
    public ResponseEntity<List<PermissionDto>> listByModule(@PathVariable String module) {
        return ResponseEntity.ok(roleService.listPermissionsByModule(module));
    }

    @GetMapping("/{id}")
    public ResponseEntity<PermissionDto> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(roleService.getPermissionById(id));
    }

    @PostMapping
    public ResponseEntity<PermissionDto> create(@RequestBody Map<String, Object> body) {
        return ResponseEntity.status(HttpStatus.CREATED).body(roleService.createPermission(
                (String) body.get("code"), (String) body.get("name"),
                (String) body.get("description"), (String) body.get("module"),
                (Boolean) body.get("isSystemPermission")));
    }

    @PutMapping("/{id}")
    public ResponseEntity<PermissionDto> update(@PathVariable UUID id, @RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(roleService.updatePermission(id,
                (String) body.get("name"), (String) body.get("description"), (String) body.get("module")));
    }

    @PostMapping("/{id}/toggle-active")
    public ResponseEntity<PermissionDto> toggleActive(@PathVariable UUID id) {
        return ResponseEntity.ok(roleService.togglePermissionActive(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        roleService.deletePermission(id);
        return ResponseEntity.noContent().build();
    }
}
