package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CurrencyAuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * V238 (2026-05-19) — CurrencyAuditLog repository.
 */
@Repository
public interface CurrencyAuditLogRepository extends JpaRepository<CurrencyAuditLog, Long> {

    /** Egy adott valuta osszes audit-bejegyzese, friss-elso sorrendben. */
    List<CurrencyAuditLog> findByCurrencyIdOrderByCreatedAtDesc(Long currencyId);

    /** Egy worker (foertekitaros) osszes modositasa, friss-elso sorrendben. */
    List<CurrencyAuditLog> findByWorkerIdOrderByCreatedAtDesc(Long workerId);
}
