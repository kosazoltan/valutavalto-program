package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class HufDaybookSequenceService {

    @PersistenceContext
    private EntityManager entityManager;

    @Transactional(propagation = Propagation.MANDATORY)
    public int next(UUID companyId, int sequenceYear) {
        if (companyId == null) {
            throw new ValidationException("A cegazonosito kotelezo a HUF naplosorszamhoz.");
        }
        if (sequenceYear < 2000 || sequenceYear > 3000) {
            throw new ValidationException("Ervenytelen HUF naploszam ev: " + sequenceYear);
        }

        Object result = entityManager.createNativeQuery("""
                INSERT INTO huf_daybook_sequence (company_id, sequence_year, last_value)
                VALUES (:companyId, :sequenceYear, 1)
                ON CONFLICT (company_id, sequence_year)
                DO UPDATE SET last_value = huf_daybook_sequence.last_value + 1
                RETURNING last_value
                """)
                .setParameter("companyId", companyId)
                .setParameter("sequenceYear", sequenceYear)
                .getSingleResult();

        return ((Number) result).intValue();
    }
}
