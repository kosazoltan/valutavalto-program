package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TransferSerialSequenceService {

    private static final Set<String> ALLOWED_PREFIXES = Set.of("AT", "AV", "FF", "UF", "KK", "AS");

    @PersistenceContext
    private EntityManager entityManager;

    @Transactional(propagation = Propagation.MANDATORY)
    public long next(UUID companyId, String prefix) {
        if (companyId == null) {
            throw new ValidationException("A cegazonosito kotelezo az atadas-atvetel sorszamhoz.");
        }
        if (!ALLOWED_PREFIXES.contains(prefix)) {
            throw new ValidationException("Ervenytelen atadas-atvetel sorszam prefix: " + prefix);
        }

        Object result = entityManager.createNativeQuery("""
                INSERT INTO transfer_serial_sequence (company_id, prefix, last_value)
                VALUES (:companyId, :prefix, 1)
                ON CONFLICT (company_id, prefix)
                DO UPDATE SET last_value = transfer_serial_sequence.last_value + 1
                RETURNING last_value
                """)
                .setParameter("companyId", companyId)
                .setParameter("prefix", prefix)
                .getSingleResult();

        return ((Number) result).longValue();
    }
}
