package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.role.*;
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
@RequestMapping("/api/v1/roles")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class RoleController {

    private final RoleService roleService;

    @GetMapping
    public ResponseEntity<List<RoleDto>> list() {
        return ResponseEntity.ok(roleService.listRoles());
    }

    @GetMapping("/{id}")
    public ResponseEntity<RoleDto> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(roleService.getRoleById(id));
    }

    @PostMapping
    public ResponseEntity<RoleDto> create(@RequestBody Map<String, Object> body) {
        String code = (String) body.get("code");
        String name = (String) body.get("name");
        String description = (String) body.get("description");
        @SuppressWarnings("unchecked")
        List<String> permissionIds = (List<String>) body.get("permissionIds");
        return ResponseEntity.status(HttpStatus.CREATED).body(roleService.createRole(code, name, description, permissionIds));
    }

    @PutMapping("/{id}")
    public ResponseEntity<RoleDto> update(@PathVariable UUID id, @RequestBody Map<String, Object> body) {
        String name = (String) body.get("name");
        String description = (String) body.get("description");
        Boolean active = body.containsKey("active") ? (Boolean) body.get("active") : null;
        @SuppressWarnings("unchecked")
        List<String> permissionIds = (List<String>) body.get("permissionIds");
        return ResponseEntity.ok(roleService.updateRole(id, name, description, active, permissionIds));
    }

    @PostMapping("/{roleId}/permissions/{permissionId}")
    public ResponseEntity<RoleDto> addPermission(@PathVariable UUID roleId, @PathVariable UUID permissionId) {
        return ResponseEntity.ok(roleService.addPermissionToRole(roleId, permissionId));
    }

    @DeleteMapping("/{roleId}/permissions/{permissionId}")
    public ResponseEntity<Void> removePermission(@PathVariable UUID roleId, @PathVariable UUID permissionId) {
        roleService.removePermissionFromRole(roleId, permissionId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/toggle-active")
    public ResponseEntity<RoleDto> toggleActive(@PathVariable UUID id) {
        return ResponseEntity.ok(roleService.toggleRoleActive(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        roleService.deleteRole(id);
        return ResponseEntity.noContent().build();
    }
}
