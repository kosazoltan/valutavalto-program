package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.AverageRateReportDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Átlag árfolyam riport service — legacy ATLAGARF (46K, 71f) parity.
 *
 * <p>v2.5.66 Sprint A P2.5: súlyozott átlagárfolyam időszak + iroda + valuta szerint.</p>
 *
 * <p>A súlyozott átlag = SUM(huf_amount) / SUM(currency_amount). Nem aritmetikus átlag
 * a tranzakciós exchange_rate-eken (az torz lenne, mert kis és nagy tranzakciók
 * ugyanúgy számítanának). A HUF-súlyozott a valódi pénzügyi átlagárfolyam.</p>
 *
 * <p>Multi-tenant biztonság: minden lekérdezés `company.id = :companyId`-ra szűr.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class AverageRateReportService {

    private final TransactionRepository transactionRepository;
    private final CurrencyRepository currencyRepository;

    @PersistenceContext
    private EntityManager entityManager;

    /**
     * Súlyozott átlag árfolyam riport.
     *
     * @param companyId       cég (kötelező — multi-tenant)
     * @param from            időszak kezdete
     * @param to              időszak vége (inclusive)
     * @param branchId        iroda (null = összes iroda aggregálva)
     * @param currencyId      valuta (null = összes valuta per row)
     * @param transactionType "BUY" / "SELL" / null=mind
     * @return sorok valuta szerint (és iroda szerint, ha branchId=null nem aggregál csak szűr)
     */
    public List<AverageRateReportDto> generate(UUID companyId, LocalDate from, LocalDate to,
                                                UUID branchId, Long currencyId, String transactionType) {
        if (companyId == null) {
            throw new IllegalArgumentException("companyId kötelező (multi-tenant védelem)");
        }
        if (from == null || to == null) {
            throw new IllegalArgumentException("from és to dátum kötelező");
        }
        if (from.isAfter(to)) {
            throw new IllegalArgumentException("from > to érvénytelen időszak");
        }

        // JPQL aggregálás GROUP BY currency-vel (és opcionálisan transactionType-pal)
        StringBuilder jpql = new StringBuilder();
        jpql.append("SELECT t.currency.id, t.currency.code, ")
            .append("COUNT(t), ")
            .append("SUM(t.currencyAmount), ")
            .append("SUM(t.hufAmount) ")
            .append("FROM Transaction t ")
            .append("WHERE t.company.id = :companyId ")
            .append("AND t.transactionDate BETWEEN :from AND :to ")
            .append("AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED ");

        if (branchId != null) {
            jpql.append("AND t.branch.id = :branchId ");
        }
        if (currencyId != null) {
            jpql.append("AND t.currency.id = :currencyId ");
        }
        if (transactionType != null && !transactionType.isBlank()) {
            jpql.append("AND t.transactionType = :transactionType ");
        }

        jpql.append("GROUP BY t.currency.id, t.currency.code ")
            .append("ORDER BY t.currency.code");

        var query = entityManager.createQuery(jpql.toString());
        query.setParameter("companyId", companyId);
        query.setParameter("from", from);
        query.setParameter("to", to);
        if (branchId != null) {
            query.setParameter("branchId", branchId);
        }
        if (currencyId != null) {
            query.setParameter("currencyId", currencyId);
        }
        if (transactionType != null && !transactionType.isBlank()) {
            try {
                query.setParameter("transactionType",
                        hu.puzzleir.valuta.entity.TransactionType.valueOf(transactionType.toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Érvénytelen transactionType: " + transactionType
                        + " (BUY/SELL/CONVERSION/...)");
            }
        }

        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();

        List<AverageRateReportDto> result = new ArrayList<>();
        for (Object[] row : rows) {
            Long currId = (Long) row[0];
            String currCode = (String) row[1];
            Long count = (Long) row[2];
            BigDecimal totalCurrency = (BigDecimal) row[3];
            BigDecimal totalHuf = (BigDecimal) row[4];

            BigDecimal weightedAvg = BigDecimal.ZERO;
            // NPE-védelem: bár GROUP BY-nál SUM(...) nem szokott NULL-t adni nem-üres csoporton,
            // defenzív null-check a totalHuf-ra (és a totalCurrency-re a signum() előtt).
            if (totalCurrency != null && totalCurrency.signum() > 0 && totalHuf != null) {
                weightedAvg = totalHuf.divide(totalCurrency, 4, RoundingMode.HALF_UP);
            }

            result.add(AverageRateReportDto.builder()
                    .periodStart(from)
                    .periodEnd(to)
                    .branchId(branchId)
                    .currencyId(currId)
                    .currencyCode(currCode)
                    .transactionType(transactionType)
                    .transactionCount(count)
                    .totalCurrencyAmount(totalCurrency)
                    .totalHufAmount(totalHuf)
                    .weightedAverageRate(weightedAvg)
                    .build());
        }

        log.debug("AverageRateReport: company={}, period={}..{}, branch={}, currency={}, type={} → {} sor",
                companyId, from, to, branchId, currencyId, transactionType, result.size());

        return result;
    }
}
