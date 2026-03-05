package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Permission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface PermissionRepository extends JpaRepository<Permission, UUID> {
    Optional<Permission> findByCode(String code);
    List<Permission> findByIsActiveTrue();
    List<Permission> findByModule(String module);
}
