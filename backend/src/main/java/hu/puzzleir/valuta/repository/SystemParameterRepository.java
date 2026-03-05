package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.SystemParameter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface SystemParameterRepository extends JpaRepository<SystemParameter, UUID> {
    Optional<SystemParameter> findByParameterKey(String key);
    List<SystemParameter> findByIsActiveTrue();
    List<SystemParameter> findByCategory(String category);
}
