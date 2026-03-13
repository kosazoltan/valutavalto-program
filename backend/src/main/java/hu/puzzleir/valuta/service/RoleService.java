package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.role.*;
import hu.puzzleir.valuta.entity.Permission;
import hu.puzzleir.valuta.entity.Role;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.PermissionRepository;
import hu.puzzleir.valuta.repository.RoleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoleService {

    private final RoleRepository roleRepository;
    private final PermissionRepository permissionRepository;

    // --- ROLE ---

    public List<RoleDto> listRoles() {
        return roleRepository.findAll().stream().map(this::toRoleDto).collect(Collectors.toList());
    }

    public RoleDto getRoleById(UUID id) {
        return toRoleDto(findRoleOrThrow(id));
    }

    @Transactional
    public RoleDto createRole(String code, String name, String description, List<String> permissionIds) {
        Role role = Role.builder()
                .code(code).name(name).description(description)
                .isActive(true).isSystemRole(false).build();
        if (permissionIds != null) {
            permissionIds.forEach(pid -> {
                Permission p = permissionRepository.findById(UUID.fromString(pid))
                        .orElseThrow(() -> new ResourceNotFoundException("Jogosultság nem található: " + pid));
                role.getPermissions().add(p);
            });
        }
        return toRoleDto(roleRepository.save(role));
    }

    @Transactional
    public RoleDto updateRole(UUID id, String name, String description, Boolean active, List<String> permissionIds) {
        Role role = findRoleOrThrow(id);
        if (name != null) role.setName(name);
        if (description != null) role.setDescription(description);
        if (active != null) role.setIsActive(active);
        if (permissionIds != null) {
            role.getPermissions().clear();
            permissionIds.forEach(pid -> {
                Permission p = permissionRepository.findById(UUID.fromString(pid))
                        .orElseThrow(() -> new ResourceNotFoundException("Jogosultság nem található: " + pid));
                role.getPermissions().add(p);
            });
        }
        return toRoleDto(roleRepository.save(role));
    }

    @Transactional
    public RoleDto addPermissionToRole(UUID roleId, UUID permissionId) {
        Role role = findRoleOrThrow(roleId);
        Permission p = permissionRepository.findById(permissionId)
                .orElseThrow(() -> new ResourceNotFoundException("Jogosultság nem található: " + permissionId));
        role.getPermissions().add(p);
        return toRoleDto(roleRepository.save(role));
    }

    @Transactional
    public void removePermissionFromRole(UUID roleId, UUID permissionId) {
        Role role = findRoleOrThrow(roleId);
        role.getPermissions().removeIf(p -> p.getId().equals(permissionId));
        roleRepository.save(role);
    }

    @Transactional
    public RoleDto toggleRoleActive(UUID id) {
        Role role = findRoleOrThrow(id);
        role.setIsActive(!role.getIsActive());
        return toRoleDto(roleRepository.save(role));
    }

    @Transactional
    public void deleteRole(UUID id) {
        roleRepository.deleteById(id);
    }

    // --- PERMISSION ---

    public List<PermissionDto> listPermissions() {
        return permissionRepository.findAll().stream().map(this::toPermissionDto).collect(Collectors.toList());
    }

    public List<PermissionDto> listActivePermissions() {
        return permissionRepository.findByIsActiveTrue().stream().map(this::toPermissionDto).collect(Collectors.toList());
    }

    public List<PermissionDto> listPermissionsByModule(String module) {
        return permissionRepository.findByModule(module).stream().map(this::toPermissionDto).collect(Collectors.toList());
    }

    public PermissionDto getPermissionById(UUID id) {
        return toPermissionDto(findPermissionOrThrow(id));
    }

    @Transactional
    public PermissionDto createPermission(String code, String name, String description, String module, Boolean isSystem) {
        Permission p = Permission.builder()
                .code(code).name(name).description(description).module(module)
                .isSystemPermission(isSystem != null ? isSystem : false).isActive(true).build();
        return toPermissionDto(permissionRepository.save(p));
    }

    @Transactional
    public PermissionDto updatePermission(UUID id, String name, String description, String module) {
        Permission p = findPermissionOrThrow(id);
        if (name != null) p.setName(name);
        if (description != null) p.setDescription(description);
        if (module != null) p.setModule(module);
        return toPermissionDto(permissionRepository.save(p));
    }

    @Transactional
    public PermissionDto togglePermissionActive(UUID id) {
        Permission p = findPermissionOrThrow(id);
        p.setIsActive(!p.getIsActive());
        return toPermissionDto(permissionRepository.save(p));
    }

    @Transactional
    public void deletePermission(UUID id) {
        permissionRepository.deleteById(id);
    }

    // --- Helpers ---

    private Role findRoleOrThrow(UUID id) {
        return roleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Szerepkör nem található: " + id));
    }

    private Permission findPermissionOrThrow(UUID id) {
        return permissionRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Jogosultság nem található: " + id));
    }

    private RoleDto toRoleDto(Role r) {
        return RoleDto.builder()
                .id(r.getId().toString())
                .code(r.getCode()).name(r.getName()).description(r.getDescription())
                .roleType(r.getRoleType()).hierarchyLevel(r.getHierarchyLevel())
                .isSystemRole(r.getIsSystemRole()).isActive(r.getIsActive())
                .permissions(r.getPermissions().stream().map(Permission::getName).collect(Collectors.toList()))
                .build();
    }

    private PermissionDto toPermissionDto(Permission p) {
        return PermissionDto.builder()
                .id(p.getId().toString())
                .code(p.getCode()).name(p.getName()).description(p.getDescription())
                .module(p.getModule()).isSystemPermission(p.getIsSystemPermission())
                .isActive(p.getIsActive())
                .createdAt(p.getCreatedAt() != null ? p.getCreatedAt().toString() : null)
                .build();
    }
}
