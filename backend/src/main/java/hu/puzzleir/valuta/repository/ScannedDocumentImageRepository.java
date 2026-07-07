package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DocumentSide;
import hu.puzzleir.valuta.entity.ScannedDocumentImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface ScannedDocumentImageRepository extends JpaRepository<ScannedDocumentImage, UUID> {

    Optional<ScannedDocumentImage> findByScannedDocumentIdAndSide(UUID scannedDocumentId, DocumentSide side);

    /** Listanézethez: melyik dokumentumnak melyik oldala van meg — BÁJTOK NÉLKÜL (PII+méret). */
    @Query("SELECT i.scannedDocumentId AS documentId, i.side AS side FROM ScannedDocumentImage i "
            + "WHERE i.scannedDocumentId IN :documentIds")
    List<DocumentSideView> findSidesByDocumentIds(@Param("documentIds") List<UUID> documentIds);

    interface DocumentSideView {
        UUID getDocumentId();
        DocumentSide getSide();
    }
}
