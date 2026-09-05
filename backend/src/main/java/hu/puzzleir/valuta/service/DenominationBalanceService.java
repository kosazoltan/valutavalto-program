package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.denomination.DenominationBalanceDto;
import hu.puzzleir.valuta.dto.denomination.DenominationQuantityUpdateRequestDto;
import hu.puzzleir.valuta.dto.denomination.DenominationSelfCheckDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.VatSupplyStock;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CashRegisterDeviceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.repository.VatSupplyStockRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.HungarianRounding;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Pénztárgép címlet egyenleg szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class DenominationBalanceService {

    private final DenominationBalanceRepository denominationBalanceRepository;
    private final DenominationRepository denominationRepository;
    private final CashRegisterDeviceRepository cashRegisterDeviceRepository;
    private final BranchRepository branchRepository;
    private final CashBalanceRepository cashBalanceRepository;
    // FK-080 (FR-5): az engedelyezett cimlet-katalogus — a mentes-ut gatja.
    private final DenominationAllowedRepository denominationAllowedRepository;
    private final ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    private final CurrencyRepository currencyRepository;
    private final VatSupplyStockRepository vatSupplyStockRepository;
    // FKH-046: the vault-arm self-check "expected" value comes from this repository
    // (entity_type=VAULT, entity_id=vault_territory_id), not from the
    // cashier-pattern cash_balance table.
    private final CurrencyStockRepository currencyStockRepository;

    /**
     * FK-080 (FR-5): a mentes elott a hivatkozott denomination sort ELLENORIZZUK.
     *
     * <p>Ket, szandekosan KULONBOZO elutasitas:
     * <ul>
     *   <li>(a) mas ceg sora vagy nem letezo id → {@link ResourceNotFoundException} (404).
     *       Ugyanaz a szerzodes, mint a {@link #requireOwnCashDesk(UUID)}-nal: masik tenant
     *       azonositojanak a LETEZESE se szivarogjon ki. Ez egy valos IDOR-t zar be: korabban
     *       barmelyik ceg denominationId-jara lehetett menteni, ha volt hozza balance-sor.</li>
     *   <li>(b) inaktiv sor, vagy a (deviza, nevertek, tipus) harmas nincs a hivo cege AKTIV
     *       katalogusaban → {@link ValidationException} VV-VALID-007 (400). Uzleti
     *       szabalysertes egy olyan soron, ami legitimen a hivoe.</li>
     * </ul>
     *
     * <p>A sorrend kotott: eloszb a tenant-ellenorzes (404), utana az uzleti gat (400).
     *
     * <p>A gat a 4-argumentumu updateQuantity-ben ul, amelyen MINDEN nyilvanos belepesi pont
     * atmegy (a 3-argumentumu updateQuantity es mindket batchUpdate is ide delegal), igy egy
     * helyen zarja az osszes iro utat.
     *
     * <p>A tipus-egyezes is szamit: egy COIN-kent tarolt sor, amit a katalogus BANKNOTE-kent
     * engedelyez, elutasitasra kerul — a teljes harmasra validalunk, nem csak a nevertekre.
     *
     * <p>OSIV ki van kapcsolva, ezert a lazy asszociaciok ({@code getCompany()},
     * {@code getCurrency()}) olvasasa ITT, a service-tranzakcion belul tortenik.
     */
    private Denomination requireAllowedDenomination(Long denominationId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Denomination denom = denominationRepository.findById(denominationId)
                .orElseThrow(() -> new ResourceNotFoundException("Címlet nem található: " + denominationId));

        // (a) tenant-gat: azonos uzenet a nem letezo es az idegen sorra (nincs informacio-szivargas).
        if (denom.getCompany() == null || !companyId.equals(denom.getCompany().getId())) {
            throw new ResourceNotFoundException("Címlet nem található: " + denominationId);
        }

        // (b) inaktiv sor: a V380 altal inaktivalt tiltott ermekre sem menthető uj darabszam.
        if (!Boolean.TRUE.equals(denom.getActive())) {
            throw new ValidationException(notAllowedMessage(denom));
        }

        DenominationAllowed allowed = denominationAllowedRepository
                .findActiveAllowed(companyId, denom.getCurrency().getId(), denom.getFaceValue())
                .orElse(null);
        if (allowed == null || allowed.getDenominationType() != denom.getDenominationType()) {
            throw new ValidationException(notAllowedMessage(denom));
        }
        return denom;
    }

    /** NFR-2: magyar nyelvu elutasito uzenet, egyetlen helyen (addendum A-10: explicit name()). */
    private static String notAllowedMessage(Denomination denom) {
        return "VV-VALID-007: Nem engedélyezett címlet ennél a pénznemnél, erre a sorra nem menthető"
                + " darabszám: " + denom.getCurrency().getCode() + " "
                + denom.getFaceValue().toPlainString() + " (" + denom.getDenominationType().name() + ")";
    }

    /**
     * Multi-tenant IDOR guard: a cashDeskId a hivo cegehez tartozik-e.
     *
     * <p>FK-077 (FR-2): a {@code denomination_balance.cash_desk_id} oszlop szemantikaja
     * a gyakorlatban FIOK (branch) UUID — a {@code ClosingWizardService.saveDenominationBalance}
     * a {@code branchId}-t irja bele, es a frontend is a {@code worker.branchId}-t kuldi.
     * A guard korabban KIZAROLAG a {@code cash_register_device} tabla PK-jat fogadta el,
     * ezert minden valos hivast {@code ResourceNotFoundException}-nal utasitott el (404),
     * amitol a Cimletezes oldal csendben kiurult. Ezert a guard mostantol MINDKET
     * ervenyes szemantikat elfogadja — fiok-UUID VAGY penztargep-eszkoz-id —, de
     * mindkettot a hivo cegere szurve, igy a tenant-izolacio valtozatlanul szoros
     * (cross-tenant VAGY nem letezo azonosito → 404, a letezes se szivarogjon).</p>
     *
     * <p>Csak controller-utak hivjak (getCashDeskDenominations/...ByCurrency/updateQuantity/
     * batchUpdate/calculateTotal); nincs @Scheduled/@Async/auth nelkuli hivo, ezert a
     * SecurityUtils.getCurrentCompanyId() biztonsagos.</p>
     */
    private void requireOwnCashDesk(UUID cashDeskId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (cashDeskId == null) {
            throw new ResourceNotFoundException("Pénztár nem található: " + cashDeskId);
        }
        boolean ownBranch = branchRepository.existsByIdAndCompanyId(cashDeskId, companyId);
        boolean ownDevice = !ownBranch
                && cashRegisterDeviceRepository.existsByIdAndCompanyId(cashDeskId, companyId);
        if (!ownBranch && !ownDevice) {
            throw new ResourceNotFoundException("Pénztár nem található: " + cashDeskId);
        }
    }

    /**
     * Pénztárgép összes címletének lekérése
     */
    @Transactional(readOnly = true)
    public List<DenominationBalanceDto> getCashDeskDenominations(UUID cashDeskId) {
        requireOwnCashDesk(cashDeskId);
        return denominationBalanceRepository.findByCashDeskId(cashDeskId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Pénztárgép adott valutájú címleteinek lekérése (kategória nélkül — EVENING).
     */
    @Transactional(readOnly = true)
    public List<DenominationBalanceDto> getCashDeskDenominationsByCurrency(UUID cashDeskId, Long currencyId) {
        return getCashDeskDenominationsByCurrency(cashDeskId, currencyId, DenominationCategory.EVENING);
    }

    /**
     * Pénztárgép adott valutájú címleteinek lekérése, EXPLICIT kategóriával.
     *
     * <p>FKH-038: a becímletező oldal READ-útja korábban kategória-vak volt, ezért az
     * Esti zárás (EVENING) HUF-készlete előtöltődött a Kezelési díj (HANDLING_FEE) oldalon.
     * A WRITE-út ({@link #batchUpdate}) már kategória-tudatos volt; a betöltés mostantól
     * ugyanazt a szűrést alkalmazza. Hiányzó kategória → EVENING (WRITE/selfCheck mintája).</p>
     *
     * <p>FKH-050 (D5): a visszamenőleg kompatibilis alak a MAI napra szűr
     * ({@code businessDate=null} → ma) — így egy új napon a mai oldal üresen indul,
     * nem tölti elő a tegnapi sort (elfogadott viselkedés-változás, D5 pinned test).</p>
     */
    @Transactional(readOnly = true)
    public List<DenominationBalanceDto> getCashDeskDenominationsByCurrency(
            UUID cashDeskId, Long currencyId, DenominationCategory category) {
        return getCashDeskDenominationsByCurrency(cashDeskId, currencyId, category, null);
    }

    /**
     * FKH-050 (D5): dátum-tudatos olvasás — csak az adott üzleti napra beküldött sorok.
     * {@code businessDate == null} → mai nap. A dátum-szűrés miatt egy múlt-beli nap
     * retroaktív sora nem szivárog be a mai oldalra (és viszont).
     */
    @Transactional(readOnly = true)
    public List<DenominationBalanceDto> getCashDeskDenominationsByCurrency(
            UUID cashDeskId, Long currencyId, DenominationCategory category,
            LocalDate businessDate) {
        requireOwnCashDesk(cashDeskId);
        DenominationCategory effectiveCategory =
                category == null ? DenominationCategory.EVENING : category;
        LocalDate effectiveDate = businessDate != null ? businessDate : LocalDate.now();
        return denominationBalanceRepository
                .findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                        cashDeskId, currencyId, effectiveCategory, effectiveDate)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Egyedi címlet darabszám frissítése (kategória nélkül — EVENING, visszamenőleg kompatibilis).
     */
    public DenominationBalanceDto updateQuantity(UUID cashDeskId, Long denominationId, int quantity) {
        return updateQuantity(cashDeskId, denominationId, quantity, DenominationCategory.EVENING);
    }

    /**
     * Egyedi címlet darabszám frissítése, EXPLICIT kategóriával.
     *
     * <p>FK-078 (FR-3): korábban minden karbantartó mentés {@code EVENING}-ként íródott,
     * függetlenül attól, melyik felületről indult. A becímletező oldal mostantól átadja a
     * tényleges kategóriát ({@code EVENING} vagy {@code HANDLING_FEE}), így a
     * {@code denomination_balance} sor helyesen tagelődik.</p>
     *
     * <p>FK-078 (FR-2): ez az út SEMMILYEN zárási munkamenetet nem indít — a mentés
     * napközben, korlátlanul ismételhető.</p>
     */
    public DenominationBalanceDto updateQuantity(UUID cashDeskId, Long denominationId, int quantity,
                                                 DenominationCategory category) {
        // FKH-050: a visszamenőleg kompatibilis alak a mai napra ír, dátum-vak
        // upsert-lookuppal (a V387 előtti viselkedés, a mai flow változatlan — NFR-1).
        return updateQuantity(cashDeskId, denominationId, quantity, category, null);
    }

    /**
     * FKH-050 (D5): dátum-tudatos címlet-írás. {@code businessDate == null} → a mai nap
     * a V387 előtti (dátum-vak) upsert-úton; explicit múlt-beli dátummal a lookup és az
     * írás is {@code submission_date}-re szűrt, így a múlt-beli sor NEM írja felül a mai
     * folyamatban lévő sort (pénzügyi adatvesztés elkerülése).
     */
    public DenominationBalanceDto updateQuantity(UUID cashDeskId, Long denominationId, int quantity,
                                                 DenominationCategory category, LocalDate businessDate) {
        requireOwnCashDesk(cashDeskId);
        // FK-080 (FR-5): a cimlet-sor gatja — cross-tenant/nem letezo → 404, tiltott vagy
        // inaktiv sor → VV-VALID-007 (400). A sort MINDIG betoltjuk (nem csak az orElseGet
        // agban), mert a szabaly a SORRA vonatkozik, nem arra, hogy van-e mar egyenlege.
        Denomination denomination = requireAllowedDenomination(denominationId);
        DenominationCategory effectiveCategory =
                category == null ? DenominationCategory.EVENING : category;
        // FKH-050 (D5 / V387): a lookup DATUM-TUDATOS — businessDate nélkül a mai napra.
        // A datum-vak lookup a 4-oszlopu egyedi kulcs alatt tobb sort adhatna
        // (IncorrectResultSizeDataAccessException), illetve egy mult-beli retroaktiv
        // sort irna felul — penzugyi adatvesztes.
        LocalDate effectiveDate = businessDate != null ? businessDate : LocalDate.now();
        DenominationBalance balance = denominationBalanceRepository
                .findByCashDeskIdAndDenominationIdAndCategoryAndSubmissionDate(
                        cashDeskId, denominationId, effectiveCategory, effectiveDate)
                .orElseGet(() -> DenominationBalance.builder()
                        .cashDeskId(cashDeskId)
                        .denomination(denomination)
                        .quantity(0)
                        .totalValue(BigDecimal.ZERO)
                        .denominationCategory(effectiveCategory)
                        .build());

        balance.setQuantity(quantity);
        balance.setDenominationCategory(effectiveCategory);
        balance.recalculateTotalValue();
        // FK-060: ez a karbantartó út nem kap zárási varázsló-dátumot, ezért a
        // ClosingWizardService.startWizard által is használt aktuális üzleti napot rögzíti.
        // FKH-050: explicit businessDate esetén a múlt-beli napra ír.
        balance.setSubmissionDate(effectiveDate);

        DenominationBalance saved = denominationBalanceRepository.save(balance);
        log.info("Címlet egyenleg frissítve: cashDesk={}, denomination={}, quantity={}, category={}, date={}",
                cashDeskId, denominationId, quantity, effectiveCategory, effectiveDate);

        return toDto(saved);
    }

    /**
     * Batch címlet darabszám frissítés (kategória nélkül — EVENING).
     */
    public List<DenominationBalanceDto> batchUpdate(UUID cashDeskId, List<DenominationQuantityUpdateRequestDto> updates) {
        return batchUpdate(cashDeskId, updates, DenominationCategory.EVENING);
    }

    /**
     * Batch címlet darabszám frissítés EXPLICIT kategóriával (FK-078 FR-3).
     */
    public List<DenominationBalanceDto> batchUpdate(UUID cashDeskId,
                                                    List<DenominationQuantityUpdateRequestDto> updates,
                                                    DenominationCategory category) {
        // FKH-050: visszamenőleg kompatibilis alak — a mai napra ír (businessDate=null).
        return batchUpdate(cashDeskId, updates, category, null);
    }

    /**
     * FKH-050 (D5): batch címlet-frissítés EXPLICIT üzleti dátummal — a múlt-beli nap
     * retroaktív becímletezése nem írhatja felül a mai folyamatban lévő sort.
     * {@code businessDate == null} → mai nap (V387 előtti viselkedés).
     */
    public List<DenominationBalanceDto> batchUpdate(UUID cashDeskId,
                                                    List<DenominationQuantityUpdateRequestDto> updates,
                                                    DenominationCategory category,
                                                    LocalDate businessDate) {
        requireOwnCashDesk(cashDeskId);
        DenominationCategory effectiveCategory =
                category == null ? DenominationCategory.EVENING : category;
        List<DenominationBalanceDto> results = new ArrayList<>();

        for (DenominationQuantityUpdateRequestDto update : updates) {
            Long denominationId = Long.parseLong(update.getDenominationId());
            DenominationBalanceDto result =
                    updateQuantity(cashDeskId, denominationId, update.getQuantity(), effectiveCategory, businessDate);
            results.add(result);
        }

        log.info("Batch címlet frissítés: cashDesk={}, {} tétel, kategória={}",
                cashDeskId, updates.size(), effectiveCategory);
        return results;
    }

    /**
     * FK-078 FR-4: napközbeni önellenőrzés — a MAI napra becímletezett összeg összevetése a
     * könyv szerinti {@code cash_balance.currentBalance}-szal, PÉNZNEMENKÉNT.
     *
     * <p>Kizárólag tájékoztató: a hívó felület zöld/piros jelzést mutat, de semmit nem blokkol
     * (FK-078 Scope OUT). Csak azokra a pénznemekre ad sort, amelyekre a kasszának van
     * {@code cash_balance} sora — a többihez nincs mihez viszonyítani.</p>
     *
     * <p>A {@code cashDeskId} szemantikája itt is fiók-UUID (FK-077, lásd
     * {@link #requireOwnCashDesk(UUID)}); a {@code cash_balance} lekérdezés ezért
     * branch + company szűréssel megy — cross-tenant szivárgás nélkül.</p>
     */
    @Transactional(readOnly = true)
    public List<DenominationSelfCheckDto> selfCheck(UUID cashDeskId, DenominationCategory category) {
        // FKH-050: visszamenőleg kompatibilis alak — a mai napra ellenőriz (businessDate=null).
        return selfCheck(cashDeskId, category, null);
    }

    /**
     * FKH-050 (D5): önellenőrzés EXPLICIT üzleti dátummal — a múlt-beli nap retroaktív
     * becímletezett állományát hasonlítja a könyv szerinti egyenleghez.
     * {@code businessDate == null} → mai nap (V387 előtti viselkedés).
     */
    @Transactional(readOnly = true)
    public List<DenominationSelfCheckDto> selfCheck(UUID cashDeskId, DenominationCategory category,
                                                    LocalDate businessDate) {
        requireOwnCashDesk(cashDeskId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        DenominationCategory effectiveCategory =
                category == null ? DenominationCategory.EVENING : category;
        LocalDate today = businessDate != null ? businessDate : LocalDate.now();

        // Becimletezett osszeg penznemenkent: [currencyCode, SUM(totalValue)]
        Map<String, BigDecimal> denominated = new HashMap<>();
        for (Object[] row : denominationBalanceRepository
                .sumActualStockByCurrency(cashDeskId, today, effectiveCategory)) {
            denominated.put((String) row[0], (BigDecimal) row[1]);
        }

        if (effectiveCategory == DenominationCategory.HANDLING_FEE) {
            return List.of(hufSelfCheckRow(
                    denominated,
                    HungarianRounding.roundToFive(
                            shipmentHandlingFeeRepository.sumDailyFeeForBranch(companyId, cashDeskId, today))));
        }
        if (effectiveCategory == DenominationCategory.VAT) {
            return List.of(hufSelfCheckRow(denominated, vatSupplyExpectedBalance(cashDeskId, companyId)));
        }

        List<DenominationSelfCheckDto> result = new ArrayList<>();
        Branch branch = branchRepository.findByIdAndCompanyId(cashDeskId, companyId).orElse(null);
        if (isVaultContext(branch)) {
            // FKH-046: vault arm — the "expected" value comes from the
            // currency_stock (VAULT) table, from the same source as the
            // ClosingWizardService vault arm (consistency, FR-4).
            if (branch.getVaultTerritoryId() == null) {
                // Master-data defect: without a territory the vault stock cannot be
                // resolved — fail closed.
                log.warn("selfCheck: vault branch ({}) without vault_territory_id -> fail-closed (empty list)",
                        branch.getCode());
                return result;
            }
            for (CurrencyStock stock : currencyStockRepository
                    .findByCompanyIdAndEntityTypeAndEntityId(
                            companyId, "VAULT", branch.getVaultTerritoryId().toString())) {
                String currencyCode = stock.getCurrencyCode();
                BigDecimal denominatedAmount = denominated
                        .getOrDefault(currencyCode, BigDecimal.ZERO)
                        .setScale(2, RoundingMode.HALF_UP);
                BigDecimal expected = (stock.getQuantity() == null
                        ? BigDecimal.ZERO : stock.getQuantity())
                        .setScale(2, RoundingMode.HALF_UP);
                Currency currency = currencyRepository.findByCode(currencyCode).orElse(null);
                result.add(selfCheckRow(currencyCode, currency != null ? currency.getId() : 0L,
                        denominatedAmount, expected));
            }
            return result;
        }
        for (CashBalance cashBalance : cashBalanceRepository
                .findByBranchIdAndCompanyId(cashDeskId, companyId)) {
            String currencyCode = cashBalance.getCurrency().getCode();
            BigDecimal denominatedAmount = denominated
                    .getOrDefault(currencyCode, BigDecimal.ZERO)
                    .setScale(2, RoundingMode.HALF_UP);
            BigDecimal expected = (cashBalance.getCurrentBalance() == null
                    ? BigDecimal.ZERO : cashBalance.getCurrentBalance())
                    .setScale(2, RoundingMode.HALF_UP);
            result.add(selfCheckRow(currencyCode, cashBalance.getCurrency().getId(),
                    denominatedAmount, expected));
        }
        return result;
    }

    private DenominationSelfCheckDto hufSelfCheckRow(Map<String, BigDecimal> denominated, BigDecimal expectedRaw) {
        Currency huf = currencyRepository.findByCode("HUF").orElse(null);
        Long hufId = huf != null ? huf.getId() : 0L;
        BigDecimal denominatedAmount = denominated
                .getOrDefault("HUF", BigDecimal.ZERO)
                .setScale(2, RoundingMode.HALF_UP);
        BigDecimal expected = (expectedRaw == null ? BigDecimal.ZERO : expectedRaw)
                .setScale(2, RoundingMode.HALF_UP);
        return selfCheckRow("HUF", hufId, denominatedAmount, expected);
    }

    private static DenominationSelfCheckDto selfCheckRow(
            String currencyCode, Long currencyId, BigDecimal denominatedAmount, BigDecimal expected) {
        BigDecimal difference = denominatedAmount.subtract(expected);
        return DenominationSelfCheckDto.builder()
                .currencyCode(currencyCode)
                .currencyId(currencyId)
                .denominatedAmount(denominatedAmount)
                .expectedBalance(expected)
                .difference(difference)
                .matches(difference.compareTo(BigDecimal.ZERO) == 0)
                .build();
    }

    private BigDecimal vatSupplyExpectedBalance(UUID cashDeskId, UUID companyId) {
        Branch branch = branchRepository.findByIdAndCompanyId(cashDeskId, companyId).orElse(null);
        if (branch == null || branch.getVaultTerritoryId() == null) {
            return BigDecimal.ZERO;
        }
        return vatSupplyStockRepository
                .findByCompanyIdAndVaultTerritoryId(companyId, branch.getVaultTerritoryId())
                .map(VatSupplyStock::getCurrentBalance)
                .orElse(BigDecimal.ZERO);
    }

    private static boolean isVaultContext(Branch branch) {
        return branch != null && Boolean.TRUE.equals(branch.getIsVault());
    }

    /**
     * Adott valuta teljes értékének kiszámítása a címletekből
     */
    @Transactional(readOnly = true)
    public BigDecimal calculateTotal(UUID cashDeskId, Long currencyId) {
        requireOwnCashDesk(cashDeskId);
        return denominationBalanceRepository.sumTotalValueByCashDeskIdAndCurrencyId(cashDeskId, currencyId);
    }

    // ============ HELPER ============

    private DenominationBalanceDto toDto(DenominationBalance entity) {
        Denomination denom = entity.getDenomination();
        return DenominationBalanceDto.builder()
                .id(entity.getId().toString())
                .cashDeskId(entity.getCashDeskId().toString())
                .denominationId(String.valueOf(denom.getId()))
                .denominationValue(denom.getFaceValue())
                .denominationType(denom.getDenominationType().name())
                .currencyCode(denom.getCurrency().getCode())
                .quantity(entity.getQuantity())
                .totalValue(entity.getTotalValue())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
