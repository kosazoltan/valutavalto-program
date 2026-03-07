package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.WorkerRoleDefinition;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface WorkerRoleDefinitionRepository extends JpaRepository<WorkerRoleDefinition, Integer> {
    Optional<WorkerRoleDefinition> findByCode(String code);
}
