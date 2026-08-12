package hu.puzzleir.valuta.service;

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
 * <p>FK-083: a súlyozott átlag a nettó HUF-ból számít: nettó = SUM(huf_amount) ± SUM(handling_fee)
 * − SUM(rounding_amount), ahol BUY HOZZÁADJA a díjat (a hufAmount-ból a díj már le volt vonva),
 * SELL pedig LEVONJA (a hufAmount-hoz a díj hozzá volt adva); a kerekítés mindkét irányban levonandó
 * (előjel-bizonyíték: Transaction.java:574-585). rate = nettó / SUM(currency_amount), 4 tizedes,
 * HALF_UP, osztás csak signum() &gt; 0 esetén. Nem aritmetikus átlag a tranzakciós
 * exchange_rate-eken (az torz lenne, mert kis és nagy tranzakciók ugyanúgy számítanának);
 * a HUF-súlyozott nettó átlag a valódi pénzügyi átlagárfolyam. Az Excel-export ugyanazt a
 * generatePivot()-ot hívja, így a javítást örökli (AverageRateReportExcelService).</p>
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


    /** A 8 terület összesítő oszlopcsoport kódja + a legacy cégnév. */
    private static final String TOTAL_GROUP_CODE = "total";
    private static final String TOTAL_GROUP_NAME = "EXCLUSIVE BEST CHANGE ZRT";

    /**
     * FK-027: pivot átlag árfolyam riport — sorok = valuták (mind a 22), oszlopcsoportok =
     * terület (8) + összesítő, vagy 1 fiók. Vétel és Eladás MINDIG párhuzamosan.
     *
     * <p>Csak {@code is_vault=FALSE} pénztárak, csak COMPLETED + financialEffective BUY/SELL
     * tételek — a sztornózott (REVERSED) tételek és a parent CONVERSION sorok automatikusan
     * kimaradnak (FR-10). FK-083: súlyozott átlag = nettó HUF / SUM(currency), ahol a nettó
     * díj- és kerekítés-korrigált (lásd a class javadoc-ot).</p>
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
                    // FK-030: a VAULT_COUNTERPARTY (virtuális partner) branch-eket kizárjuk, hogy a
                    // tévesen 'ORSZAGOS' region-ű partnerek ne hozzanak létre üres "ORSZAGOS" oszlopot.
                    // Defenzív LEFT JOIN: a V330 migráció után region=NULL miatt eleve kimaradnak
                    // (region IS NOT NULL), de a branch_type-szűrés a migrációtól függetlenül is garantál.
                    "SELECT DISTINCT b.region FROM Branch b LEFT JOIN b.branchType bt "
                    + "WHERE b.company.id = :companyId "
                    + "AND b.isVault = FALSE AND b.region IS NOT NULL "
                    + "AND (bt IS NULL OR bt.code <> 'VAULT_COUNTERPARTY') "
                    + "ORDER BY b.region")
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
                .append(", t.currency.code, t.transactionType, SUM(t.currencyAmount), SUM(t.hufAmount)")
                .append(", SUM(COALESCE(t.handlingFee, 0)), SUM(COALESCE(t.roundingAmount, 0)) ")
                .append("FROM Transaction t ")
                .append("WHERE t.company.id = :companyId ")
                .append("AND t.transactionDate BETWEEN :from AND :to ")
                .append("AND t.status = hu.puzzleir.valuta.entity.TransactionStatus.COMPLETED ")
                .append("AND t.financialEffective = TRUE ")
                .append("AND t.branch.isVault = FALSE ")
                // FK-030 (defense-in-depth): a VAULT_COUNTERPARTY partnerek esetleges BUY/SELL
                // tranzakciói se kerüljenek be a TOTAL ("EXCLUSIVE BEST CHANGE ZRT") aggregátumba.
                .append("AND (t.branch.branchType IS NULL OR t.branch.branchType.code <> 'VAULT_COUNTERPARTY') ")
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

        // groupCode -> currencyCode -> Agg (BUY/SELL: currency, HUF, díj, kerekítés összegek).
        Map<String, Map<String, Agg>> acc = new HashMap<>();
        for (Object[] row : rows) {
            String groupKey = (String) row[0];
            if (groupKey == null) {
                continue;
            }
            String currCode = (String) row[1];
            TransactionType type = (TransactionType) row[2];
            BigDecimal sumCur = (BigDecimal) row[3];
            BigDecimal sumHuf = (BigDecimal) row[4];
            BigDecimal sumFee = (BigDecimal) row[5];
            BigDecimal sumRound = (BigDecimal) row[6];
            accumulate(acc, groupKey, currCode, type, sumCur, sumHuf, sumFee, sumRound);
            if (!singleBranch) {
                accumulate(acc, TOTAL_GROUP_CODE, currCode, type, sumCur, sumHuf, sumFee, sumRound);
            }
        }

        // Sorok: mind a 22 aktív valuta (HUF is aktív), display_order szerint.
        List<Currency> currencies = currencyRepository.findByActiveTrueOrderByDisplayOrderAsc();
        List<CurrencyRow> currencyRows = new ArrayList<>();
        for (Currency c : currencies) {
            Map<String, ColumnValues> values = new LinkedHashMap<>();
            for (ColumnGroup g : groups) {
                Map<String, Agg> byCurrency = acc.get(g.getGroupCode());
                Agg agg = byCurrency != null ? byCurrency.get(c.getCode()) : null;
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

    /** Per (group, currency) aggregate: BUY and SELL sums of currency, HUF, handling fee and rounding. */
    private static final class Agg {
        BigDecimal buyCur = BigDecimal.ZERO, buyHuf = BigDecimal.ZERO,
                   buyFee = BigDecimal.ZERO, buyRound = BigDecimal.ZERO;
        BigDecimal sellCur = BigDecimal.ZERO, sellHuf = BigDecimal.ZERO,
                   sellFee = BigDecimal.ZERO, sellRound = BigDecimal.ZERO;
    }

    private static void accumulate(Map<String, Map<String, Agg>> acc, String groupKey,
                                   String currCode, TransactionType type,
                                   BigDecimal sumCur, BigDecimal sumHuf,
                                   BigDecimal sumFee, BigDecimal sumRound) {
        Agg agg = acc.computeIfAbsent(groupKey, k -> new HashMap<>())
                .computeIfAbsent(currCode, k -> new Agg());
        BigDecimal cur = sumCur != null ? sumCur : BigDecimal.ZERO;
        BigDecimal huf = sumHuf != null ? sumHuf : BigDecimal.ZERO;
        BigDecimal fee = sumFee != null ? sumFee : BigDecimal.ZERO;
        BigDecimal round = sumRound != null ? sumRound : BigDecimal.ZERO;
        if (type == TransactionType.BUY) {
            agg.buyCur = agg.buyCur.add(cur);
            agg.buyHuf = agg.buyHuf.add(huf);
            agg.buyFee = agg.buyFee.add(fee);
            agg.buyRound = agg.buyRound.add(round);
        } else if (type == TransactionType.SELL) {
            agg.sellCur = agg.sellCur.add(cur);
            agg.sellHuf = agg.sellHuf.add(huf);
            agg.sellFee = agg.sellFee.add(fee);
            agg.sellRound = agg.sellRound.add(round);
        }
    }

    /**
     * FK-083: nettó HUF-ból számított súlyozott átlag (üres cella = 0, nem null/hiányzó).
     *
     * <p>Előjel-bizonyíték: Transaction.java:574-585 — BUY esetén
     * {@code hufAmount = calcHuf − fee + rounding}, ezért a díjat VISSZAADJUK
     * ({@code net = huf + fee − rounding}); SELL esetén {@code hufAmount = calcHuf + fee + rounding},
     * ezért a díjat és a kerekítést is LEVONJUK ({@code net = huf − fee − rounding}).
     * A negatív aggregált kerekítési összeg legitim és változatlanul folyik át.</p>
     */
    private static ColumnValues toColumnValues(Agg agg) {
        if (agg == null) {
            return ColumnValues.builder()
                    .buyAvgRate(BigDecimal.ZERO).buySumAmount(BigDecimal.ZERO)
                    .sellAvgRate(BigDecimal.ZERO).sellSumAmount(BigDecimal.ZERO).build();
        }
        BigDecimal buyNet = agg.buyHuf.add(agg.buyFee).subtract(agg.buyRound);        // BUY:  huf + fee - rounding
        BigDecimal sellNet = agg.sellHuf.subtract(agg.sellFee).subtract(agg.sellRound); // SELL: huf - fee - rounding
        BigDecimal buyAvg = agg.buyCur.signum() > 0
                ? buyNet.divide(agg.buyCur, 4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
        BigDecimal sellAvg = agg.sellCur.signum() > 0
                ? sellNet.divide(agg.sellCur, 4, RoundingMode.HALF_UP) : BigDecimal.ZERO;
        return ColumnValues.builder()
                .buyAvgRate(buyAvg).buySumAmount(agg.buyCur)
                .sellAvgRate(sellAvg).sellSumAmount(agg.sellCur).build();
    }
}
