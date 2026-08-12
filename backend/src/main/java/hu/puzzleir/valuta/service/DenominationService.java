package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.DenominationCount;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.repository.DenominationCountRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Címletezés szolgáltatás.
 *
 * Legacy: CIMLET tábla kezelés - napi zárás címletvalidálás
 *
 * FK-080 (FR-2): MINDEN címletsor — a HUF is — a `denomination_allowed`
 * törzsadatból (V376 + V379) származik. A korábbi 14 elemű, hardkódolt HUF
 * tömb és a névérték-küszöbre épülő típus-besorolás megszűnt: a katalógus az
 * egyetlen igazságforrás, érme kizárólag HUF 200/100/50/20/10/5 és EUR 2/1.
 */
@Service
@RequiredArgsConstructor
@Transactional(rollbackFor = Exception.class)
@Slf4j
public class DenominationService {

    private final DenominationRepository denominationRepository;
    private final DenominationCountRepository denominationCountRepository;
    private final CurrencyRepository currencyRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;
    // FK-076/FK-080: az engedelyezett cimlet-katalogus (denomination_allowed torzsadat) —
    // MINDEN deviza, a HUF-ot is beleertve (V376 deviza-seed + V379 HUF-seed).
    private final DenominationAllowedRepository denominationAllowedRepository;

    // FK-076 (2026-08-07) + FK-080 (2026-08-11): a statikus FOREIGN_DENOMINATIONS Map
    // (teljes jegybanki katalogus), a DenominationSpec record, a 14 elemu
    // HUF_DENOMINATIONS tomb es a classifyHufDenomination() mind megszunt — a
    // branch-inicializalast KIZAROLAG a denomination_allowed torzsadat vezerli
    // (V376 deviza-seed + V379 HUF-seed). Lásd: DenominationAllowedRepository.

    /**
     * Címletek lekérdezése az aktuális irodához és valutához
     */
    @Transactional(readOnly = true)
    public List<Denomination> getDenominations(Long currencyId) {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return denominationRepository.findByBranchAndCurrency(branchId, currencyId);
    }

    /**
     * Címletek lekérdezése valuta kód alapján
     */
    @Transactional(readOnly = true)
    public List<Denomination> getDenominationsByCurrencyCode(String currencyCode) {
        Currency currency = currencyRepository.findByCode(currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException("Valuta nem található: " + currencyCode));
        return getDenominations(currency.getId());
    }

    /**
     * Összes címlet az aktuális irodához
     */
    @Transactional(readOnly = true)
    public List<Denomination> getAllBranchDenominations() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return denominationRepository.findByBranchId(branchId);
    }

    /**
     * Alacsony készletű címletek figyelmeztetés
     */
    @Transactional(readOnly = true)
    public List<Denomination> getLowStockAlerts() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return denominationRepository.findLowStock(companyId);
    }

    /**
     * Címlet készlet módosítása
     *
     * Legacy: CIMLET frissítés
     */
    public Denomination updateDenominationQuantity(UpdateDenominationRequest request) {
        if (request.getNewQuantity() < 0) {
            throw new ValidationException("A darabszám nem lehet negatív: " + request.getNewQuantity());
        }

        UUID branchId = SecurityUtils.getCurrentBranchId();

        Denomination denomination = denominationRepository
                .findByBranchIdAndCurrencyIdAndFaceValue(branchId, request.getCurrencyId(), request.getFaceValue())
                .orElseThrow(() -> new ResourceNotFoundException("Címlet nem található"));

        int oldQuantity = denomination.getQuantity();
        denomination.setQuantity(request.getNewQuantity());

        Denomination saved = denominationRepository.save(denomination);

        log.info("Címlet frissítve: {} {} - {} db -> {} db",
                denomination.getCurrency().getCode(), request.getFaceValue(),
                oldQuantity, request.getNewQuantity());

        // #LazyInit (2026-05-27, architect-mode): a PUT /denominations + /bulk a derived
        // findByBranchIdAndCurrencyIdAndFaceValue-t használja (nincs JOIN FETCH), majd a controller
        // a session lezárása UTÁN (OSIV=false) mappel DTO-ra. A DenominationMapper a branch+currency
        // proxyt olvassa → LazyInit 500. A branch-et itt, a tranzakción belül inicializáljuk
        // (a currency-t a fenti log már betöltötte, de explicit a robusztusságért).
        org.hibernate.Hibernate.initialize(saved.getBranch());
        org.hibernate.Hibernate.initialize(saved.getCurrency());

        return saved;
    }

    /**
     * Címletezés validálás (napi záráshoz)
     *
     * Legacy: NAPZAR - címletezés ellenőrzés
     * Összehasonlítja a címletezett összeget a kassza egyenleggel
     */
    public DenominationValidationResult validateDenomination(Long currencyId, BigDecimal expectedBalance) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<Denomination> denominations = denominationRepository.findByBranchAndCurrency(branchId, currencyId);

        BigDecimal denominatedTotal = denominations.stream()
                .map(Denomination::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal difference = denominatedTotal.subtract(expectedBalance);
        boolean isValid = difference.compareTo(BigDecimal.ZERO) == 0;

        DenominationValidationResult result = DenominationValidationResult.builder()
                .currencyId(currencyId)
                .expectedBalance(expectedBalance)
                .denominatedTotal(denominatedTotal)
                .difference(difference)
                .isValid(isValid)
                .denominations(denominations)
                .build();

        if (!isValid) {
            log.warn("Címletezés eltérés: {} - várt: {}, címletezett: {}, különbség: {}",
                    denominations.isEmpty() ? "?" : denominations.get(0).getCurrency().getCode(),
                    expectedBalance, denominatedTotal, difference);
        }

        return result;
    }

    /**
     * Tömeges címlet frissítés (napi zárás űrlap)
     */
    public List<Denomination> bulkUpdateDenominations(List<UpdateDenominationRequest> requests) {
        List<Denomination> updated = new ArrayList<>();

        for (UpdateDenominationRequest request : requests) {
            updated.add(updateDenominationQuantity(request));
        }

        return updated;
    }

    /**
     * Címletek inicializálása új irodához.
     *
     * 2026-04-29 v2.3.29 (Codex P1 PR #292 follow-up):
     * `Propagation.REQUIRES_NEW` — ÚJ független transzakcióban fut, NEM a parent
     * `BranchService.create()` tx-ében. Ha ez a metódus dobás, csak a saját tx-et
     * rollback-olja, a parent commit NEM kerül `UnexpectedRollbackException`-ba.
     *
     * Spring iparági pattern: auxiliary/optional init logika REQUIRES_NEW-vel
     * izolált, hogy a parent operation (branch létrehozás) sikeres maradjon
     * akkor is, ha a kiegészítő init dob.
     *
     * FK-080 (FR-2): a korábbi KÜLÖN HUF-ág (14 elemű hardkódolt tömb +
     * classifyHufDenomination küszöb) MEGSZŰNT. A HUF ugyanazon az egyetlen
     * cikluson megy át, mint minden más deviza, és a típusát — akárcsak a többi —
     * a katalógus-sor `denominationType` mezője adja. Következmény: új fiók
     * pontosan 6 HUF érme-sort kap (200/100/50/20/10/5), nem 8-at; az 1 és 2
     * forintos érme-sor többé nem jön létre (2008-ban bevonták).
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = Exception.class)
    public void initializeBranchDenominations(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));

        // FK-076 (FR-2) + FK-080 (FR-2): MINDEN cimlet — a HUF is — a
        // denomination_allowed torzsadatbol (V376 deviza-seed + V379 HUF-seed) jon letre.
        // A korabbi FOREIGN_DENOMINATIONS Map (teljes jegybanki katalogus, tort es
        // nem-EUR ermekkel) es a HUF-specifikus ag egyarant megszunt. Az EUA-kivetel
        // sem kell: az EUA-nak nincs sora a tablaban -> 0 cimlet-sor jon letre.
        // Idempotens (meglévő bejegyzések kihagyva), csak AKTIV valutakra.
        List<DenominationAllowed> catalog = denominationAllowedRepository.findActiveByCompanyId(companyId);

        // FK-081: a migraciok UTAN letrehozott ceg katalogusa URES (a V376/V379
        // INSERT ... SELECT csak az akkor letezo cegekre toltott). Ures katalogussal a
        // fiok 0 cimletsort kapna, es az FK-080 ota a torvenyes HUF-zaras is elbukna
        // (VV-VALID-006/007 mindent elutasit). Ezert itt egyszer feltoltjuk a katalogust
        // a meglevo, migraciobol szarmazo torzsadatbol — nincs masodik igazsagforras.
        // A meglevo negy tenantra ez az ag SOHA nem fut le.
        if (catalog.isEmpty()) {
            int seededRows = denominationAllowedRepository.seedCatalogForCompany(companyId);
            log.warn("FK-081: ures cimlet-katalogus a(z) {} cegnel — {} sor seed-elve a torzsadatbol",
                    companyId, seededRows);
            catalog = denominationAllowedRepository.findActiveByCompanyId(companyId);
        }

        int created = 0;
        for (DenominationAllowed allowed : catalog) {
            Currency currency = allowed.getCurrency();
            if (!Boolean.TRUE.equals(currency.getActive())) {
                continue;
            }
            if (denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(
                    branchId, currency.getId(), allowed.getFaceValue()).isEmpty()) {
                Denomination denomination = Denomination.builder()
                        .company(company)
                        .branch(branch)
                        .currency(currency)
                        .faceValue(allowed.getFaceValue())
                        .denominationType(allowed.getDenominationType())
                        .quantity(0)
                        .active(true)
                        .build();
                denominationRepository.save(denomination);
                created++;
                // ellenor1 NIT-1 (FK-076 review): a log CSAK a tenyleges INSERT-et naplozza —
                // az if-en kivul minden mar letezo sorra is tuzelt (126 felrevezeto sor/branch).
                log.debug("{} {} címlet inicializálva irodához: {}", currency.getCode(),
                        allowed.getFaceValue(), branch.getName());
            }
        }

        log.info("Címletek inicializálva irodához: {} ({} új sor a denomination_allowed katalógusból)",
                branch.getName(), created);
    }

    /**
     * Címletezés összesítő
     */
    @Transactional(readOnly = true)
    public DenominationSummary getDenominationSummary(Long currencyId) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<Denomination> denominations = denominationRepository.findByBranchAndCurrency(branchId, currencyId);

        BigDecimal totalValue = denominations.stream()
                .map(Denomination::getTotalValue)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        int totalPieces = denominations.stream()
                .mapToInt(Denomination::getQuantity)
                .sum();

        long banknoteCount = denominations.stream()
                .filter(d -> d.getDenominationType() == DenominationType.BANKNOTE)
                .mapToInt(Denomination::getQuantity)
                .sum();

        long coinCount = denominations.stream()
                .filter(d -> d.getDenominationType() == DenominationType.COIN)
                .mapToInt(Denomination::getQuantity)
                .sum();

        return DenominationSummary.builder()
                .currencyId(currencyId)
                .currencyCode(denominations.isEmpty() ? null : denominations.get(0).getCurrency().getCode())
                .totalValue(totalValue)
                .totalPieces(totalPieces)
                .banknoteCount((int) banknoteCount)
                .coinCount((int) coinCount)
                .denominations(denominations)
                .build();
    }

    /**
     * Optimális címlet kiadás számítása (visszajáró)
     *
     * Legacy: VISSZAJARO - optimális címlet kombináció
     */
    @Transactional(readOnly = true)
    public Map<BigDecimal, Integer> calculateOptimalChange(Long currencyId, BigDecimal amount) {
        UUID branchId = SecurityUtils.getCurrentBranchId();

        List<Denomination> denominations = denominationRepository.findByBranchAndCurrency(branchId, currencyId);

        // Bug fix: explicit DESC rendezés névérték szerint — nem támaszkodunk az adatbázis sorrendjére
        List<Denomination> sorted = denominations.stream()
                .sorted(Comparator.comparing(Denomination::getFaceValue).reversed())
                .collect(Collectors.toList());

        Map<BigDecimal, Integer> result = new LinkedHashMap<>();

        BigDecimal remaining = amount;

        // Nagyobb címletektől kezdve (greedy)
        for (Denomination denom : sorted) {
            if (denom.getQuantity() > 0 && remaining.compareTo(denom.getFaceValue()) >= 0) {
                int needed = remaining.divideToIntegralValue(denom.getFaceValue()).intValue();
                int available = Math.min(needed, denom.getQuantity());

                if (available > 0) {
                    result.put(denom.getFaceValue(), available);
                    remaining = remaining.subtract(denom.getFaceValue().multiply(BigDecimal.valueOf(available)));
                }
            }

            if (remaining.compareTo(BigDecimal.ZERO) == 0) {
                break;
            }
        }

        if (remaining.compareTo(BigDecimal.ZERO) > 0) {
            log.warn("Nem sikerült teljes visszajárót kiadni: {} maradék", remaining);
        }

        return result;
    }

    // ============ KATEGÓRIA ALAPÚ CÍMLETEZÉS ============

    /**
     * Címletezés rögzítése adott kategóriával.
     *
     * Legacy: CIMLETSZAM rekord felvétele a napi zárás során,
     * az egyes kasszatípusokhoz (esti, kezelési díj, WU, ÁFA, stb.)
     *
     * @param branchId iroda
     * @param sessionId munkamenet
     * @param category címletezési kategória
     * @param denomCounts Map: currencyCode -> Map(faceValue darabszám -> quantity)
     * @return rögzített DenominationCount lista
     */
    public List<DenominationCount> recordDenomination(
            UUID branchId,
            UUID sessionId,
            DenominationCategory category,
            Map<String, Map<Integer, Integer>> denomCounts) {

        if (denomCounts == null || denomCounts.isEmpty()) {
            throw new ValidationException("Üres címletezési adat!");
        }

        Long workerId = SecurityUtils.getCurrentWorkerId();

        List<DenominationCount> saved = new ArrayList<>();

        for (Map.Entry<String, Map<Integer, Integer>> currencyEntry : denomCounts.entrySet()) {
            String currencyCode = currencyEntry.getKey();
            Map<Integer, Integer> faceValueCounts = currencyEntry.getValue();

            for (Map.Entry<Integer, Integer> fvEntry : faceValueCounts.entrySet()) {
                BigDecimal faceValue = new BigDecimal(fvEntry.getKey());
                int quantity = fvEntry.getValue();

                if (quantity < 0) {
                    throw new ValidationException(
                        String.format("Negatív darabszám nem megengedett: %s %s = %d",
                            currencyCode, faceValue.toPlainString(), quantity));
                }

                DenominationCount count = DenominationCount.builder()
                    .branchId(branchId)
                    .sessionId(sessionId)
                    .currencyCode(currencyCode)
                    .faceValue(faceValue)
                    .quantity(quantity)
                    .countType("CLOSING")
                    .denominationCategory(category)
                    .workerId(workerId)
                    .build();

                saved.add(denominationCountRepository.save(count));
            }
        }

        log.info("Címletezés rögzítve: iroda={}, kategória={}, {} tétel",
            branchId, category.getDisplayName(), saved.size());

        return saved;
    }

    /**
     * Kategória alapú címletezés összesítés.
     */
    @Transactional(readOnly = true)
    public BigDecimal getCategoryDenominatedTotal(UUID branchId, java.time.LocalDate date, DenominationCategory category) {
        return denominationCountRepository.sumDenominatedAmountByCategory(branchId, date, category);
    }

    /**
     * Ellenőrzi, hogy adott kategória címletezése megtörtént-e az adott napon.
     */
    @Transactional(readOnly = true)
    public boolean isCategoryDenominated(UUID branchId, java.time.LocalDate date, DenominationCategory category) {
        return denominationCountRepository.existsByBranchIdAndDateAndCategory(branchId, date, category);
    }

    // ============ REQUEST/RESPONSE DTO-k ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class UpdateDenominationRequest {
        private Long currencyId;
        private BigDecimal faceValue;
        private Integer newQuantity;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DenominationValidationResult {
        private Long currencyId;
        private BigDecimal expectedBalance;
        private BigDecimal denominatedTotal;
        private BigDecimal difference;
        private boolean isValid;
        private List<Denomination> denominations;
    }

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DenominationSummary {
        private Long currencyId;
        private String currencyCode;
        private BigDecimal totalValue;
        private int totalPieces;
        private int banknoteCount;
        private int coinCount;
        private List<Denomination> denominations;
    }
}
