package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CurrencyDenominationImage;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.entity.DocumentSide;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CurrencyDenominationImageRepository extends JpaRepository<CurrencyDenominationImage, UUID> {

    /** Cég-scope-olt egyedi lekérés — cross-tenant IDOR tilos (invariáns #1). */
    Optional<CurrencyDenominationImage> findByIdAndCompanyId(UUID id, UUID companyId);

    /** Upsert-kulcs lekérés. */
    Optional<CurrencyDenominationImage> findByCompanyIdAndCurrencyIdAndFaceValueAndDenominationTypeAndSide(
            UUID companyId,
            Long currencyId,
            BigDecimal faceValue,
            DenominationType denominationType,
            DocumentSide side);

    /** Meta-lista BÁJTOK NÉLKÜL (interface-projekció — DocumentSideView-precedens). */
    List<MetaView> findByCompanyIdOrderByCurrencyIdAscFaceValueDescSideAsc(UUID companyId);

    List<MetaView> findByCompanyIdAndCurrencyIdOrderByFaceValueDescSideAsc(UUID companyId, Long currencyId);

    interface MetaView {
        UUID getId();

        Long getCurrencyId();

        BigDecimal getFaceValue();

        DenominationType getDenominationType();

        DocumentSide getSide();

        String getMimeType();

        Long getFileSizeBytes();

        Boolean getActive();

        LocalDateTime getCreatedAt();

        LocalDateTime getUpdatedAt();
    }
}
