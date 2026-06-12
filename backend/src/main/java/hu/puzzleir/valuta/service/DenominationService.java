package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.DenominationCount;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.repository.CurrencyRepository;
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
 * 14-féle HUF címlet: 20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 2, 1
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

    // HUF címletek (legacy kompatibilitás)
    private static final BigDecimal[] HUF_DENOMINATIONS = {
        new BigDecimal("20000"),
        new BigDecimal("10000"),
        new BigDecimal("5000"),
        new BigDecimal("2000"),
        new BigDecimal("1000"),
        new BigDecimal("500"),
        new BigDecimal("200"),
        new BigDecimal("100"),
        new BigDecimal("50"),
        new BigDecimal("20"),
        new BigDecimal("10"),
        new BigDecimal("5"),
        new BigDecimal("2"),
        new BigDecimal("1")
    };

    /**
     * Címlet-specifikáció: névérték + bankjegy/érme besorolás.
     * A besorolás jegybanki tény (nem küszöb-heurisztika): pl. EUR 1/2 érme,
     * CHF 5/2/1 érme, JPY 500 érme, USD 1 bankjegy.
     */
    record DenominationSpec(BigDecimal faceValue, DenominationType type) {}

    /**
     * Külföldi valuta címlet-katalógus (Batch2-A, 2026-06-12).
     *
     * Forrás: hivatalos jegybanki címlet-listák (ECB, Fed, BoE, SNB, RBA, BoC,
     * BoJ, CNB, NBP, BNR, NBS, BoI, NBU, TCMB, PBoC, CBBH, BoT, BCB, Banxico,
     * RBNZ), keresztvalidálva a legacy EXCMD katalógussal
     * (legacy-transfer/text/VALUTA/DLL/KCIMLET/MAKEDLL/Unit2.pas:111-135).
     * A V320 migráció SQL-katalógusával 1:1 azonos — eltérés esetén a V320 a
     * meglévő sorokat, ez a térkép az ÚJ branch-inicializálást vezérli.
     * RUB szándékosan nincs benne (V319: nem forgalmazott, user-direktíva).
     * EUA = euró érme (apró) külön valutakódként, csak COIN sorokkal.
     */
    static final Map<String, List<DenominationSpec>> FOREIGN_DENOMINATIONS;

    private static List<DenominationSpec> specs(String banknotesCsv, String coinsCsv) {
        List<DenominationSpec> list = new ArrayList<>();
        for (String v : banknotesCsv.split(",")) {
            if (!v.isBlank()) list.add(new DenominationSpec(new BigDecimal(v.trim()), DenominationType.BANKNOTE));
        }
        for (String v : coinsCsv.split(",")) {
            if (!v.isBlank()) list.add(new DenominationSpec(new BigDecimal(v.trim()), DenominationType.COIN));
        }
        return List.copyOf(list);
    }

    static {
        FOREIGN_DENOMINATIONS = new LinkedHashMap<>();
        FOREIGN_DENOMINATIONS.put("EUR", specs("500,200,100,50,20,10,5", "2,1,0.50,0.20,0.10,0.05,0.02,0.01"));
        FOREIGN_DENOMINATIONS.put("EUA", specs("", "2,1,0.50,0.20,0.10,0.05,0.02,0.01"));
        FOREIGN_DENOMINATIONS.put("USD", specs("100,50,20,10,5,2,1", "0.50,0.25,0.10,0.05,0.01"));
        FOREIGN_DENOMINATIONS.put("GBP", specs("50,20,10,5", "2,1,0.50,0.20,0.10,0.05,0.02,0.01"));
        FOREIGN_DENOMINATIONS.put("CHF", specs("1000,200,100,50,20,10", "5,2,1,0.50,0.20,0.10,0.05"));
        FOREIGN_DENOMINATIONS.put("AUD", specs("100,50,20,10,5", "2,1,0.50,0.20,0.10,0.05"));
        FOREIGN_DENOMINATIONS.put("CAD", specs("100,50,20,10,5", "2,1,0.25,0.10,0.05"));
        FOREIGN_DENOMINATIONS.put("JPY", specs("10000,5000,2000,1000", "500,100,50,10,5,1"));
        FOREIGN_DENOMINATIONS.put("CZK", specs("5000,2000,1000,500,200,100", "50,20,10,5,2,1"));
        FOREIGN_DENOMINATIONS.put("PLN", specs("500,200,100,50,20,10", "5,2,1,0.50,0.20,0.10,0.05,0.02,0.01"));
        FOREIGN_DENOMINATIONS.put("RON", specs("500,200,100,50,20,10,5,1", "0.50,0.10,0.05,0.01"));
        // RSD 20/10: bankjegyként ÉS érmeként is forog — bankjegyként vesszük fel
        FOREIGN_DENOMINATIONS.put("RSD", specs("5000,2000,1000,500,200,100,50,20,10", "5,2,1"));
        FOREIGN_DENOMINATIONS.put("ILS", specs("200,100,50,20", "10,5,2,1,0.50,0.10"));
        // UAH 1-10: a kisbankjegyeket érmék váltották (a régi kisbankjegyek 2026.03.02-tól bevontak)
        FOREIGN_DENOMINATIONS.put("UAH", specs("1000,500,200,100,50,20", "10,5,2,1,0.50,0.10"));
        FOREIGN_DENOMINATIONS.put("TRY", specs("200,100,50,20,10,5", "1,0.50,0.25,0.10,0.05,0.01"));
        FOREIGN_DENOMINATIONS.put("CNY", specs("100,50,20,10,5,1", "0.50,0.10"));
        FOREIGN_DENOMINATIONS.put("BAM", specs("200,100,50,20,10", "5,2,1,0.50,0.20,0.10,0.05"));
        FOREIGN_DENOMINATIONS.put("THB", specs("1000,500,100,50,20", "10,5,2,1,0.50,0.25"));
        FOREIGN_DENOMINATIONS.put("BRL", specs("200,100,50,20,10,5,2", "1,0.50,0.25,0.10,0.05"));
        FOREIGN_DENOMINATIONS.put("MXN", specs("1000,500,200,100,50,20", "10,5,2,1,0.50"));
        FOREIGN_DENOMINATIONS.put("NZD", specs("100,50,20,10,5", "2,1,0.50,0.20,0.10"));
    }

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
     * HUF címlet típus meghatározása.
     *
     * Bug fix: a küszöb 1000 Ft — 100 Ft és 200 Ft érmék, nem bankjegyek.
     * >= 1000 → BANKNOTE, < 1000 → COIN
     */
    DenominationType classifyHufDenomination(BigDecimal faceValue) {
        // MNB-tény: forgalomban lévő bankjegyek 500-20000 Ft, érmék 5-200 Ft.
        // Az 500 Ft BANKJEGY (Rákóczi, megújított sorozat) — 500 Ft-os érme nem
        // létezik. A korábbi >=1000 küszöb (és a rá épülő V169) téves volt; a
        // meglévő sorokat a V320 tipus-korrekciója javítja.
        return faceValue.compareTo(new BigDecimal("500")) >= 0
                ? DenominationType.BANKNOTE
                : DenominationType.COIN;
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
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = Exception.class)
    public void initializeBranchDenominations(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található"));

        // HUF címletek inicializálása
        Currency huf = currencyRepository.findByCode("HUF")
                .orElseThrow(() -> new ResourceNotFoundException("HUF valuta nem található"));

        for (BigDecimal faceValue : HUF_DENOMINATIONS) {
            if (denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(branchId, huf.getId(), faceValue).isEmpty()) {
                Denomination denomination = Denomination.builder()
                        .company(company)
                        .branch(branch)
                        .currency(huf)
                        .faceValue(faceValue)
                        .denominationType(classifyHufDenomination(faceValue))
                        .quantity(0)
                        .active(true)
                        .build();
                denominationRepository.save(denomination);
            }
        }

        log.info("HUF címletek inicializálva irodához: {}", branch.getName());

        // Külföldi valuta címletek inicializálása (idempotens — meglévő bejegyzések kihagyva).
        // Csak AKTÍV valutára (RUB pl. V319 óta inaktív — arra nem hozunk létre sort).
        for (Map.Entry<String, List<DenominationSpec>> entry : FOREIGN_DENOMINATIONS.entrySet()) {
            String currencyCode = entry.getKey();
            currencyRepository.findByCode(currencyCode)
                    .filter(c -> Boolean.TRUE.equals(c.getActive()))
                    .ifPresent(foreignCurrency -> {
                for (DenominationSpec spec : entry.getValue()) {
                    if (denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(
                            branchId, foreignCurrency.getId(), spec.faceValue()).isEmpty()) {
                        Denomination denomination = Denomination.builder()
                                .company(company)
                                .branch(branch)
                                .currency(foreignCurrency)
                                .faceValue(spec.faceValue())
                                .denominationType(spec.type())
                                .quantity(0)
                                .active(true)
                                .build();
                        denominationRepository.save(denomination);
                    }
                }
                log.info("{} címletek inicializálva irodához: {}", currencyCode, branch.getName());
            });
        }
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
