package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.AverageRateReportDto;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.ColumnGroup;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.ColumnValues;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.CurrencyRow;
import hu.puzzleir.valuta.dto.report.AverageRateReportResponse.GroupType;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
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
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
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
 *
 * <p>FONTOS: a query KIZÁRJA a parent CONVERSION sorokat (`financial_effective = FALSE`),
 * mert azok metadata-csak rekordok és duplikálnák a child convBuy/convSell sorok forgalmát.
 * Lásd Transaction.financialEffective JavaDoc + Copilot P0 #703 finding.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class AverageRateReportService {

    @PersistenceContext
    private EntityManager entityManager;

    private final CurrencyRepository currencyRepository;
    private final BranchRepository branchRepository;

    /**
     * Súlyozott átlag árfolyam riport.
     *
     * @param companyId       cég (kötelező — multi-tenant)
     * @param from            időszak kezdete
     * @param to              időszak vége (inclusive)
     * @param branchId        opcionális iroda-szűrő (null = irodák között aggregálva)
     * @param currencyId      opcionális valuta-szűrő (null = minden valuta külön sorban)
     * @param transactionType "BUY" / "SELL" / "CONVERSION" / null = minden típus
     * @return riport sorok valuta szerint (egy sor per valuta; ha branchId NEM null,
     *         az ehhez az irodához tartozó tranzakciók, egyébként az összes irodáé aggregálva)
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

        // JPQL aggregálás GROUP BY currency-vel (és opcionálisan transactionType-pal).
        // Copilot P0 #703: financialEffective = TRUE — parent CONVERSION kizárás (NEM duplikál).
        StringBuilder jpql = new StringBuilder();
        jpql.append("SELECT t.currency.id, t.currency.code, ")
            .append("COUNT(t), ")
            .append("SUM(t.currencyAmount), ")
            .append("SUM(t.hufAmount) ")
            .append("FROM Transaction t ")
            .append("WHERE t.company.id = :companyId ")
            .append("AND t.transactionDate BETWEEN :from AND :to ")
            .append("AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED ")
            .append("AND t.financialEffective = TRUE ");

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
        // Sanitize transactionType BEFORE try-block, hogy a parse + log-szövegben is jó legyen
        String safeTransactionType = sanitizeForLog(transactionType);
        if (transactionType != null && !transactionType.isBlank()) {
            try {
                query.setParameter("transactionType",
                        hu.puzzleir.valuta.entity.TransactionType.valueOf(transactionType.toUpperCase()));
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Érvénytelen transactionType: " + safeTransactionType
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

        // CodeQL log-injection #703 fix: transactionType user-controlled String, sanitize előbb
        log.debug("AverageRateReport: company={}, period={}..{}, branch={}, currency={}, type={} → {} sor",
                companyId, from, to, branchId, currencyId, safeTransactionType, result.size());

        return result;
    }

    /** A 8 terület összesítő oszlopcsoport kódja + a legacy cégnév. */
    private static final String TOTAL_GROUP_CODE = "total";
    private static final String TOTAL_GROUP_NAME = "EXCLUSIVE BEST CHANGE ZRT";

    /**
     * FK-027: pivot átlag árfolyam riport — sorok = valuták (mind a 22), oszlopcsoportok =
     * terület (8) + összesítő, vagy 1 fiók. Vétel és Eladás MINDIG párhuzamosan.
     *
     * <p>Csak {@code is_vault=FALSE} pénztárak, csak COMPLETED + financialEffective BUY/SELL
     * tételek — a sztornózott (REVERSED) tételek és a parent CONVERSION sorok automatikusan
     * kimaradnak (FR-10). Súlyozott átlag = SUM(huf)/SUM(currency).</p>
     *
     * @param branchId null = "Összes iroda" (8 terület + összesítő); egyébként 1 fiók-oszlopcsoport
     */
    public AverageRateReportResponse generatePivot(UUID companyId, LocalDate from, LocalDate to,
                                                    UUID branchId) {
        if (companyId == null) {
            throw new IllegalArgumentException("companyId kötelező (multi-tenant védelem)");
        }
        if (from == null || to == null) {
            throw new IllegalArgumentException("from és to dátum kötelező");
        }
        if (from.isAfter(to)) {
            throw new IllegalArgumentException("from > to érvénytelen időszak");
        }

        boolean singleBranch = branchId != null;
        List<ColumnGroup> groups = new ArrayList<>();

        if (singleBranch) {
            Branch b = branchRepository.findById(branchId)
                    .orElseThrow(() -> new IllegalArgumentException("Iroda nem található: " + branchId));
            if (b.getCompany() == null || !companyId.equals(b.getCompany().getId())) {
                throw new IllegalArgumentException("Az iroda nem ehhez a céghez tartozik");
            }
            // is_vault=TRUE fiók nem ad eredményt (a query is_vault=FALSE-ra szűr) — 1 üres oszlopcsoport.
            groups.add(ColumnGroup.builder()
                    .groupCode(b.getCode()).groupName(b.getName())
                    .groupType(GroupType.BRANCH).build());
        } else {
            @SuppressWarnings("unchecked")
            List<String> regions = entityManager.createQuery(
                    "SELECT DISTINCT b.region FROM Branch b WHERE b.company.id = :companyId "
                    + "AND b.isVault = FALSE AND b.region IS NOT NULL ORDER BY b.region")
                    .setParameter("companyId", companyId)
                    .getResultList();
            for (String r : regions) {
                groups.add(ColumnGroup.builder()
                        .groupCode(r).groupName(r).groupType(GroupType.REGION).build());
            }
            groups.add(ColumnGroup.builder()
                    .groupCode(TOTAL_GROUP_CODE).groupName(TOTAL_GROUP_NAME)
                    .groupType(GroupType.TOTAL).build());
        }

        // Aggregáció: oszlopkulcs = region (összes iroda) vagy branch.code (egy fiók).
        String keyExpr = singleBranch ? "t.branch.code" : "t.branch.region";
        StringBuilder jpql = new StringBuilder()
                .append("SELECT ").append(keyExpr)
                .append(", t.currency.code, t.transactionType, SUM(t.currencyAmount), SUM(t.hufAmount) ")
                .append("FROM Transaction t ")
                .append("WHERE t.company.id = :companyId ")
                .append("AND t.transactionDate BETWEEN :from AND :to ")
                .append("AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED ")
                .append("AND t.financialEffective = TRUE ")
                .append("AND t.branch.isVault = FALSE ")
                .append("AND t.transactionType IN ("
                        + "hu.puzzleir.valuta.entity.TransactionType.BUY, "
                        + "hu.puzzleir.valuta.entity.TransactionType.SELL) ");
        if (singleBranch) {
            jpql.append("AND t.branch.id = :branchId ");
        }
        jpql.append("GROUP BY ").append(keyExpr).append(", t.currency.code, t.transactionType");

        var query = entityManager.createQuery(jpql.toString());
        query.setParameter("companyId", companyId);
        query.setParameter("from", from);
        query.setParameter("to", to);
        if (singleBranch) {
            query.setParameter("branchId", branchId);
        }
        @SuppressWarnings("unchecked")
        List<Object[]> rows = query.getResultList();

        // groupCode -> currencyCode -> [buySumCur, buySumHuf, sellSumCur, sellSumHuf]
        Map<String, Map<String, BigDecimal[]>> acc = new HashMap<>();
        for (Object[] row : rows) {
            String groupKey = (String) row[0];
            if (groupKey == null) {
                continue;
            }
            String currCode = (String) row[1];
            TransactionType type = (TransactionType) row[2];
            BigDecimal sumCur = (BigDecimal) row[3];
            BigDecimal sumHuf = (BigDecimal) row[4];
            accumulate(acc, groupKey, currCode, type, sumCur, sumHuf);
            if (!singleBranch) {
                accumulate(acc, TOTAL_GROUP_CODE, currCode, type, sumCur, sumHuf);
            }
        }

        // Sorok: mind a 22 aktív valuta (HUF is aktív), display_order szerint.
        List<Currency> currencies = currencyRepository.findByActiveTrueOrderByDisplayOrderAsc();
        List<CurrencyRow> currencyRows = new ArrayList<>();
        for (Currency c : currencies) {
            Map<String, ColumnValues> values = new LinkedHashMap<>();
            for (ColumnGroup g : groups) {
                Map<String, BigDecimal[]> byCurrency = acc.get(g.getGroupCode());
                BigDecimal[] agg = byCurrency != null ? byCurrency.get(c.getCode()) : null;
                values.put(g.getGroupCode(), toColumnValues(agg));
            }
            currencyRows.add(CurrencyRow.builder().currencyCode(c.getCode()).values(values).build());
        }

        log.debug("AverageRateReport pivot: company={}, period={}..{}, branch={} → {} csoport × {} valuta",
                companyId, from, to, branchId, groups.size(), currencyRows.size());

        return AverageRateReportResponse.builder()
                .periodStart(from).periodEnd(to)
                .columnGroups(groups).currencyRows(currencyRows)
                .build();
    }

    private static void accumulate(Map<String, Map<String, BigDecimal[]>> acc, String groupKey,
                                   String currCode, TransactionType type,
                                   BigDecimal sumCur, BigDecimal sumHuf) {
        BigDecimal[] agg = acc.computeIfAbsent(groupKey, k -> new HashMap<>())
                .computeIfAbsent(currCode, k -> new BigDecimal[]{
                        BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO});
        BigDecimal cur = sumCur != null ? sumCur : BigDecimal.ZERO;
        BigDecimal huf = sumHuf != null ? sumHuf : BigDecimal.ZERO;
        if (type == TransactionType.BUY) {
            agg[0] = agg[0].add(cur);
            agg[1] = agg[1].add(huf);
        } else if (type == TransactionType.SELL) {
            agg[2] = agg[2].add(cur);
            agg[3] = agg[3].add(huf);
        }
    }

    /** [buyCur, buyHuf, sellCur, sellHuf] → ColumnValues (üres cella = 0, nem null/hiányzó). */
    private static ColumnValues toColumnValues(BigDecimal[] agg) {
        if (agg == null) {
            return ColumnValues.builder()
                    .buyAvgRate(BigDecimal.ZERO).buySumAmount(BigDecimal.ZERO)
                    .sellAvgRate(BigDecimal.ZERO).sellSumAmount(BigDecimal.ZERO).build();
        }
        BigDecimal buyAvg = agg[0].signum() > 0
                ? agg[1].divide(agg[0], 4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
        BigDecimal sellAvg = agg[2].signum() > 0
                ? agg[3].divide(agg[2], 4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
        return ColumnValues.builder()
                .buyAvgRate(buyAvg).buySumAmount(agg[0])
                .sellAvgRate(sellAvg).sellSumAmount(agg[2]).build();
    }

    /**
     * CRLF + control karakter strip a log-injection elleni védelemhez.
     */
    private static String sanitizeForLog(String input) {
        if (input == null) return null;
        return input.replaceAll("[\\r\\n\\t]", "_").replaceAll("[\\p{Cntrl}]", "?");
    }
}
