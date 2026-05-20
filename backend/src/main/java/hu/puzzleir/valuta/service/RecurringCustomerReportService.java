package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.RecurringCustomerDto;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Időszakos (visszatérő) ügyfél monitoring report — legacy ugyfelcontrol/idoszakos parity.
 *
 * <p>v2.5.74 Sprint P3.3: AML frequent-customer detection. Azon ügyfeleket listázza,
 * akik egy adott időszakban ≥ minTransactions alkalommal tranzaktáltak. A compliance-tiszt
 * fokozott ügyfél-átvilágítást (Pmt. 16. §) indíthat a gyakori ügyfelekre.</p>
 *
 * <p>Multi-tenant (C.25 + B.3): minden lekérdezés `company.id = :companyId`-ra szűr.
 * financial_effective=TRUE: a parent CONVERSION sorok kizárva (NEM duplikál).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class RecurringCustomerReportService {

    @PersistenceContext
    private EntityManager entityManager;

    /**
     * Visszatérő ügyfelek listája az időszakban, ≥ minTransactions tranzakcióval.
     *
     * @param companyId       cég (kötelező — multi-tenant)
     * @param from            időszak kezdete
     * @param to              időszak vége (inclusive)
     * @param minTransactions minimum tranzakció-szám küszöb (≥ 2)
     * @return ügyfél-sorok csökkenő tranzakció-szám szerint
     */
    public List<RecurringCustomerDto> generate(UUID companyId, LocalDate from, LocalDate to,
                                               int minTransactions) {
        if (companyId == null) {
            throw new IllegalArgumentException("companyId kötelező (multi-tenant védelem)");
        }
        if (from == null || to == null) {
            throw new IllegalArgumentException("from és to dátum kötelező");
        }
        if (from.isAfter(to)) {
            throw new IllegalArgumentException("from > to érvénytelen időszak");
        }
        if (minTransactions < 2) {
            throw new IllegalArgumentException("minTransactions legalább 2 kell legyen (visszatérő = 2+ alkalom)");
        }

        // GROUP BY customerId, HAVING COUNT >= minTransactions.
        // financial_effective=TRUE: parent CONVERSION kizárás (NEM duplikál).
        // customerId IS NOT NULL: anonim (azonosítás nélküli kis összegű) tranzakciók kihagyva.
        // MAX(customerName): lexikografikusan legnagyobb név (NEM idő szerinti utolsó) —
        // az AML-monitoring szempontjából az azonosítható név a lényeg.
        var query = entityManager.createQuery(
                "SELECT t.customerId, MAX(t.customerName), COUNT(t), SUM(t.hufAmount) " +
                        "FROM Transaction t " +
                        "WHERE t.company.id = :companyId " +
                        "AND t.transactionDate BETWEEN :from AND :to " +
                        "AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED " +
                        "AND t.financialEffective = TRUE " +
                        "AND t.customerId IS NOT NULL " +
                        "GROUP BY t.customerId " +
                        "HAVING COUNT(t) >= :minTx " +
                        "ORDER BY COUNT(t) DESC, SUM(t.hufAmount) DESC");
        query.setParameter("companyId", companyId);
        query.setParameter("from", from);
        query.setParameter("to", to);
        query.setParameter("minTx", (long) minTransactions);

        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();

        List<RecurringCustomerDto> result = new ArrayList<>();
        for (Object[] row : rows) {
            String customerId = (String) row[0];
            String customerName = (String) row[1];
            Long count = (Long) row[2];
            BigDecimal totalHuf = row[3] != null ? (BigDecimal) row[3] : BigDecimal.ZERO;

            result.add(RecurringCustomerDto.builder()
                    .customerId(customerId)
                    .customerName(customerName)
                    .transactionCount(count)
                    .totalHufAmount(totalHuf)
                    .periodStart(from)
                    .periodEnd(to)
                    .build());
        }

        log.debug("RecurringCustomerReport: company={}, period={}..{}, minTx={} → {} visszatérő ügyfél",
                companyId, from, to, minTransactions, result.size());

        return result;
    }
}
