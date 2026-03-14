package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.Document;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DocumentRepository extends JpaRepository<Document, UUID> {
    List<Document> findByEntityTypeAndEntityId(String entityType, UUID entityId);
    List<Document> findByEntityType(String entityType);

    // Company-scoped queries (IDOR védelem)
    List<Document> findByCompanyId(UUID companyId);
    List<Document> findByCompanyIdAndEntityType(UUID companyId, String entityType);
    List<Document> findByCompanyIdAndEntityTypeAndEntityId(UUID companyId, String entityType, UUID entityId);
    Optional<Document> findByIdAndCompanyId(UUID id, UUID companyId);
}
