package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.Permission;
import hu.puzzleir.valuta.entity.WorkerRoleAssignment;
import hu.puzzleir.valuta.entity.WorkerRoleDefinition;
import hu.puzzleir.valuta.entity.WorkerRolePermission;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.WorkerRoleAssignmentRepository;
import hu.puzzleir.valuta.repository.WorkerRoleDefinitionRepository;
import hu.puzzleir.valuta.repository.WorkerRolePermissionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Operatív szerepkör kezelés service.
 * 
 * A Worker domain-specifikus szerepköreinek (CASHIER, COURIER, VAULT_KEEPER stb.)
 * kezelése, permission lekérdezés, role assignment.
 */
@Service
@RequiredArgsConstructor
public class WorkerRoleService {

    private final WorkerRoleDefinitionRepository roleDefRepository;
    private final WorkerRoleAssignmentRepository assignmentRepository;
    private final WorkerRolePermissionRepository rolePermRepository;
    private final WorkerRepository workerRepository;

    // --- Role lekérdezések ---

    /**
     * Worker összes operatív szerepköre
     */
    @Transactional(readOnly = true)
    public List<WorkerRoleDefinition> getRolesForWorker(Long workerId) {
        return assignmentRepository.findByWorkerId(workerId).stream()
                .map(WorkerRoleAssignment::getRoleDef)
                .collect(Collectors.toList());
    }

    /**
     * Worker operatív role kódjai (String lista)
     */
    @Transactional(readOnly = true)
    public List<String> getRoleCodesForWorker(Long workerId) {
        return getRolesForWorker(workerId).stream()
                .map(WorkerRoleDefinition::getCode)
                .collect(Collectors.toList());
    }

    /**
     * Adott role-hoz tartozó permission kódok
     */
    @Transactional(readOnly = true)
    public List<String> getPermissionCodesForRole(String roleCode) {
        WorkerRoleDefinition roleDef = roleDefRepository.findByCode(roleCode)
                .orElseThrow(() -> new ResourceNotFoundException("Szerepkör nem található: " + roleCode));

        return rolePermRepository.findByRoleDefIdWithPermission(roleDef.getId()).stream()
                .map(wrp -> wrp.getPermission().getCode())
                .collect(Collectors.toList());
    }

    /**
     * Adott role-hoz tartozó Permission entity lista
     */
    @Transactional(readOnly = true)
    public List<Permission> getPermissionsForRole(String roleCode) {
        WorkerRoleDefinition roleDef = roleDefRepository.findByCode(roleCode)
                .orElseThrow(() -> new ResourceNotFoundException("Szerepkör nem található: " + roleCode));

        return rolePermRepository.findByRoleDefIdWithPermission(roleDef.getId()).stream()
                .map(WorkerRolePermission::getPermission)
                .collect(Collectors.toList());
    }

    /**
     * Van-e a worker-nek (adott role-on keresztül) adott permission-je?
     */
    @Transactional(readOnly = true)
    public boolean hasPermission(Long workerId, String roleCode, String permissionCode) {
        WorkerRoleDefinition roleDef = roleDefRepository.findByCode(roleCode).orElse(null);
        if (roleDef == null) return false;

        // Ellenőrizzük, hogy a worker-nek van-e ez a role-ja
        if (!assignmentRepository.existsByWorkerIdAndRoleDefCode(workerId, roleCode)) {
            return false;
        }

        return rolePermRepository.existsByRoleDefIdAndPermissionCode(roleDef.getId(), permissionCode);
    }

    // --- Role assignment ---

    /**
     * Role hozzárendelés worker-hez
     */
    @Transactional(rollbackFor = Exception.class)
    public void assignRole(Long workerId, String roleCode) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Worker nem található: " + workerId));

        WorkerRoleDefinition roleDef = roleDefRepository.findByCode(roleCode)
                .orElseThrow(() -> new ResourceNotFoundException("Szerepkör nem található: " + roleCode));

        if (assignmentRepository.existsByWorkerIdAndRoleDefCode(workerId, roleCode)) {
            throw new ValidationException("A worker már rendelkezik ezzel a szerepkörrel: " + roleCode);
        }

        // Ha ez az első role, legyen primary
        boolean isFirst = assignmentRepository.countByWorkerId(workerId) == 0;

        WorkerRoleAssignment assignment = WorkerRoleAssignment.builder()
                .worker(worker)
                .roleDef(roleDef)
                .isPrimary(isFirst)
                .build();

        assignmentRepository.save(assignment);
    }

    /**
     * Role eltávolítás worker-ről
     */
    @Transactional(rollbackFor = Exception.class)
    public void removeRole(Long workerId, String roleCode) {
        if (!assignmentRepository.existsByWorkerIdAndRoleDefCode(workerId, roleCode)) {
            throw new ResourceNotFoundException("A worker nem rendelkezik ezzel a szerepkörrel: " + roleCode);
        }

        assignmentRepository.deleteByWorkerIdAndRoleDefCode(workerId, roleCode);
    }

    /**
     * Összes operatív szerepkör definíció lekérése
     */
    @Transactional(readOnly = true)
    public List<WorkerRoleDefinition> getAllRoleDefinitions() {
        return roleDefRepository.findAll();
    }
}
