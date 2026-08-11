package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * DenominationService UNIT tesztek.
 *
 * Lefedi:
 * - Bug 1: HUF coin/bankjegy küszöb (>= 1000 Ft → BANKNOTE)
 * - Bug 2: Külföldi valuta inicializálás (EUR/USD/GBP/CHF/CZK)
 * - Bug 3: Negatív darabszám validáció
 * - Bug 4: calculateOptimalChange explicit DESC rendezés
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DenominationServiceTest {

    @Mock private DenominationRepository denominationRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private DenominationAllowedRepository denominationAllowedRepository;

    @InjectMocks
    private DenominationService denominationService;

    private static final UUID TEST_BRANCH_ID = UUID.randomUUID();
    private static final UUID TEST_COMPANY_ID = UUID.randomUUID();

    // ============================================================
    // FK-080 (WU-8b): a classifyHufDenomination() nevertek-kuszob MEGSZUNT.
    //
    // Az 5 korabbi egysegteszt (100/200 -> COIN, 500/1000/20000 -> BANKNOTE) egy
    // olyan metodust hivott, ami mar nem letezik: a tipus mostantol a
    // denomination_allowed katalogus-sorbol jon (V376 + V379), nem szamitasbol.
    // A lefedettseg NEM veszett el — ugyanaz az 5 nevertek-allitas itt marad, csak
    // a HELYES forrason: a katalogus-vezerelt inicializalason keresztul merjuk.
    // Ez az FK-080 kert viselkedese (FR-2/FR-3), es egyben az OK, amiert a regi
    // kuszob hibas volt: devizatol fuggetlenul dontott.
    // ============================================================

    @Test
    @DisplayName("FK-080 FR-2: a HUF tipusa a katalogusbol jon — 200/100 ERME, 500/1000/20000 BANKJEGY (nem nevertek-kuszobbol)")
    void hufDenominationTypeComesFromCatalogNotFromThreshold() {
        Company company = new Company();
        company.setId(TEST_COMPANY_ID);
        Branch branch = new Branch();
        branch.setId(TEST_BRANCH_ID);
        branch.setName("Teszt iroda");

        // A V379 HUF-seed alapjan: 200 es 100 ERME, 500/1000/20000 BANKJEGY.
        List<DenominationAllowed> catalog = List.of(
                allowed("HUF", "20000", DenominationType.BANKNOTE),
                allowed("HUF", "1000", DenominationType.BANKNOTE),
                allowed("HUF", "500", DenominationType.BANKNOTE),
                allowed("HUF", "200", DenominationType.COIN),
                allowed("HUF", "100", DenominationType.COIN));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(TEST_COMPANY_ID);
            when(companyRepository.findById(TEST_COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(branch));
            when(denominationAllowedRepository.findActiveByCompanyId(TEST_COMPANY_ID))
                    .thenReturn(catalog);
            when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
                    .thenReturn(Optional.empty());

            denominationService.initializeBranchDenominations(TEST_BRANCH_ID);

            ArgumentCaptor<Denomination> saved = ArgumentCaptor.forClass(Denomination.class);
            verify(denominationRepository, times(5)).save(saved.capture());

            Map<BigDecimal, DenominationType> typeByFaceValue = saved.getAllValues().stream()
                    .collect(Collectors.toMap(Denomination::getFaceValue, Denomination::getDenominationType));

            assertThat(typeByFaceValue.get(new BigDecimal("100"))).isEqualTo(DenominationType.COIN);
            assertThat(typeByFaceValue.get(new BigDecimal("200"))).isEqualTo(DenominationType.COIN);
            assertThat(typeByFaceValue.get(new BigDecimal("500"))).isEqualTo(DenominationType.BANKNOTE);
            assertThat(typeByFaceValue.get(new BigDecimal("1000"))).isEqualTo(DenominationType.BANKNOTE);
            assertThat(typeByFaceValue.get(new BigDecimal("20000"))).isEqualTo(DenominationType.BANKNOTE);
        }
    }

    @Test
    @DisplayName("FK-080 FR-2: a bevont HUF 1 es 2 forint NEM jon letre — nincs katalogus-soruk")
    void withdrawnHufCoinsAreNeverCreated() {
        Company company = new Company();
        company.setId(TEST_COMPANY_ID);
        Branch branch = new Branch();
        branch.setId(TEST_BRANCH_ID);
        branch.setName("Teszt iroda");

        // A V379 katalogus a 6 torvenyes ermet tartalmazza — 1 es 2 forint NINCS benne.
        List<DenominationAllowed> catalog = List.of(
                allowed("HUF", "200", DenominationType.COIN),
                allowed("HUF", "100", DenominationType.COIN),
                allowed("HUF", "50", DenominationType.COIN),
                allowed("HUF", "20", DenominationType.COIN),
                allowed("HUF", "10", DenominationType.COIN),
                allowed("HUF", "5", DenominationType.COIN));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(TEST_COMPANY_ID);
            when(companyRepository.findById(TEST_COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(branch));
            when(denominationAllowedRepository.findActiveByCompanyId(TEST_COMPANY_ID))
                    .thenReturn(catalog);
            when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
                    .thenReturn(Optional.empty());

            denominationService.initializeBranchDenominations(TEST_BRANCH_ID);

            ArgumentCaptor<Denomination> saved = ArgumentCaptor.forClass(Denomination.class);
            // Pontosan 6 erme-sor — a korabbi hardkodolt tomb 8-at hozott letre (1 es 2 forinttal).
            verify(denominationRepository, times(6)).save(saved.capture());
            assertThat(saved.getAllValues())
                    .extracting(Denomination::getFaceValue)
                    .doesNotContain(BigDecimal.ONE, new BigDecimal("2"));
        }
    }

    // ============================================================
    // FK-076: az inicializálás a denomination_allowed torzsadatbol olvas
    // (a torolt FOREIGN_DENOMINATIONS Map helyett — a korabbi katalogus-tesztek
    // az FK-076 altal elirt viselkedesre lettek frissitve, nem torolve).
    // ============================================================

    /** Segedo: DenominationAllowed sor epites. */
    private static DenominationAllowed allowed(String code, String faceValue, DenominationType type) {
        Currency currency = new Currency();
        currency.setId((long) (code.hashCode() & 0x7fffffff));
        currency.setCode(code);
        currency.setActive(true);
        return DenominationAllowed.builder()
                .currency(currency)
                .faceValue(new BigDecimal(faceValue))
                .denominationType(type)
                .active(true)
                .build();
    }

    @Test
    @DisplayName("FK-076 FR-2: init pontosan a denomination_allowed sorait hozza létre (EUR 500 BANKNOTE, EUR 2 COIN)")
    void initShouldCreateExactlyTheAllowedCatalogRows() {
        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(TEST_COMPANY_ID);

            Company company = new Company();
            Branch branch = new Branch();
            branch.setName("Teszt Iroda");

            Currency huf = new Currency();
            huf.setId(1L);
            huf.setCode("HUF");

            when(companyRepository.findById(TEST_COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(branch));
            when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
            // HUF mar letezik -> a HUF-ag nem ment; ez a teszt kizarolag a
            // denomination_allowed-agat vizsgalja (HUF-init lefedve mashol).
            when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(
                    any(UUID.class), any(Long.class), any(BigDecimal.class)))
                    .thenAnswer(invocation -> {
                        Long currencyId = invocation.getArgument(1);
                        return currencyId.equals(huf.getId())
                                ? Optional.of(new Denomination())
                                : Optional.empty();
                    });
            when(denominationAllowedRepository.findActiveByCompanyId(TEST_COMPANY_ID))
                    .thenReturn(List.of(
                            allowed("EUR", "500", DenominationType.BANKNOTE),
                            allowed("EUR", "2", DenominationType.COIN),
                            // ellenor1 WARNING-2 (FK-076 review): tobb-devizas lefedettseg —
                            // a multi-currency iteralo ag ne csak egyetlen valutaval legyen tesztelve.
                            allowed("USD", "100", DenominationType.BANKNOTE),
                            allowed("CHF", "1000", DenominationType.BANKNOTE),
                            allowed("JPY", "10000", DenominationType.BANKNOTE)));
            when(denominationRepository.save(any(Denomination.class)))
                    .thenAnswer(invocation -> invocation.getArgument(0));

            denominationService.initializeBranchDenominations(TEST_BRANCH_ID);

            ArgumentCaptor<Denomination> captor = ArgumentCaptor.forClass(Denomination.class);
            verify(denominationRepository, times(5)).save(captor.capture());
            assertThat(captor.getAllValues())
                    .extracting(Denomination::getFaceValue, Denomination::getDenominationType)
                    .containsExactly(
                            org.assertj.core.groups.Tuple.tuple(
                                    new BigDecimal("500"), DenominationType.BANKNOTE),
                            org.assertj.core.groups.Tuple.tuple(
                                    new BigDecimal("2"), DenominationType.COIN),
                            org.assertj.core.groups.Tuple.tuple(
                                    new BigDecimal("100"), DenominationType.BANKNOTE),
                            org.assertj.core.groups.Tuple.tuple(
                                    new BigDecimal("1000"), DenominationType.BANKNOTE),
                            org.assertj.core.groups.Tuple.tuple(
                                    new BigDecimal("10000"), DenominationType.BANKNOTE));
            // Minden sor a sajat devizajahoz kerul (nem csusznak ossze egy valutara).
            assertThat(captor.getAllValues())
                    .extracting(d -> d.getCurrency().getCode())
                    .containsExactly("EUR", "EUR", "USD", "CHF", "JPY");
        }
    }

    @Test
    @DisplayName("FK-076 FR-2: EUA-ra 0 sor (nincs EUA-sor a denomination_allowed-ban)")
    void initShouldCreateZeroRowsForEua() {
        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(TEST_COMPANY_ID);

            Company company = new Company();
            Branch branch = new Branch();
            branch.setName("Teszt Iroda");

            Currency huf = new Currency();
            huf.setId(1L);
            huf.setCode("HUF");

            when(companyRepository.findById(TEST_COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(branch));
            when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
            // HUF mar letezik -> a HUF-ag nem ment; ez a teszt kizarolag a
            // denomination_allowed-agat vizsgalja.
            when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(
                    any(UUID.class), any(Long.class), any(BigDecimal.class)))
                    .thenAnswer(invocation -> {
                        Long currencyId = invocation.getArgument(1);
                        return currencyId.equals(huf.getId())
                                ? Optional.of(new Denomination())
                                : Optional.empty();
                    });
            // Ures katalogus -> semmilyen kulfoldi sor nem jon letre (EUA-ra sem).
            when(denominationAllowedRepository.findActiveByCompanyId(TEST_COMPANY_ID))
                    .thenReturn(List.of());

            denominationService.initializeBranchDenominations(TEST_BRANCH_ID);

            verify(denominationRepository, never()).save(any(Denomination.class));
            // A torolt EUA-kivetel nem kerulhet vissza: az EUA nem szuretheto ki
            // semmilyen kulonleges uton — a tablabol egyszeruen nem olvashato sor.
            verify(currencyRepository, never()).findByCode("EUA");
        }
    }

    @Test
    @DisplayName("FK-076 FR-2: inaktiv valuta sora kimarad az inicializalasbol")
    void initShouldSkipInactiveCurrency() {
        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(TEST_COMPANY_ID);

            Company company = new Company();
            Branch branch = new Branch();
            branch.setName("Teszt Iroda");

            Currency huf = new Currency();
            huf.setId(1L);
            huf.setCode("HUF");

            DenominationAllowed inactiveRow = allowed("RUB", "5000", DenominationType.BANKNOTE);
            inactiveRow.getCurrency().setActive(false);

            when(companyRepository.findById(TEST_COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(branch));
            when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
            // HUF mar letezik -> a HUF-ag nem ment; ez a teszt kizarolag a
            // denomination_allowed-agat vizsgalja.
            when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(
                    any(UUID.class), any(Long.class), any(BigDecimal.class)))
                    .thenAnswer(invocation -> {
                        Long currencyId = invocation.getArgument(1);
                        return currencyId.equals(huf.getId())
                                ? Optional.of(new Denomination())
                                : Optional.empty();
                    });
            when(denominationAllowedRepository.findActiveByCompanyId(TEST_COMPANY_ID))
                    .thenReturn(List.of(inactiveRow));

            denominationService.initializeBranchDenominations(TEST_BRANCH_ID);

            verify(denominationRepository, never()).save(any(Denomination.class));
        }
    }

    // ============================================================
    // Bug 2: Idempotent init — meglévő bejegyzések nem duplikálódnak
    // ============================================================

    @Test
    @DisplayName("initializeBranchDenominations: meglévő HUF címlet nem duplikálódik")
    void initShouldBeIdempotentForExistingHufDenominations() {
        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(TEST_COMPANY_ID);

            Company company = new Company();
            Branch branch = new Branch();
            branch.setName("Teszt Iroda");

            Currency huf = new Currency();
            huf.setId(1L);
            huf.setCode("HUF");

            when(companyRepository.findById(TEST_COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(branch));
            when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));

            // Szimuláljuk, hogy a 10000-es és 20000-es HUF már létezik (minden más is)
            // Minden külföldi valuta is hiányzik az adatbázisból
            when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(
                    any(UUID.class), any(Long.class), any(BigDecimal.class)))
                    .thenReturn(Optional.of(new Denomination())); // minden megtalálható → nem menthető

            // Külföldi valuták nem léteznek a DB-ben
            when(currencyRepository.findByCode("EUR")).thenReturn(Optional.empty());
            when(currencyRepository.findByCode("USD")).thenReturn(Optional.empty());
            when(currencyRepository.findByCode("GBP")).thenReturn(Optional.empty());
            when(currencyRepository.findByCode("CHF")).thenReturn(Optional.empty());
            when(currencyRepository.findByCode("CZK")).thenReturn(Optional.empty());

            denominationService.initializeBranchDenominations(TEST_BRANCH_ID);

            // Mivel minden HUF record már létezik, save soha nem hívódhat
            verify(denominationRepository, never()).save(any(Denomination.class));
        }
    }

    @Test
    @DisplayName("initializeBranchDenominations: EUR a denomination_allowed-ból inicializálódik (FK-076), meglévő sor kihagyva")
    void initShouldCreateEurDenominationsIfCurrencyExists() {
        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(TEST_COMPANY_ID);

            Company company = new Company();
            Branch branch = new Branch();
            branch.setName("Teszt Iroda");

            Currency huf = new Currency();
            huf.setId(1L);
            huf.setCode("HUF");

            Currency eur = new Currency();
            eur.setId(2L);
            eur.setCode("EUR");

            DenominationAllowed eur500 = DenominationAllowed.builder()
                    .currency(eur).faceValue(new BigDecimal("500"))
                    .denominationType(DenominationType.BANKNOTE).active(true).build();
            DenominationAllowed eur200 = DenominationAllowed.builder()
                    .currency(eur).faceValue(new BigDecimal("200"))
                    .denominationType(DenominationType.BANKNOTE).active(true).build();

            when(companyRepository.findById(TEST_COMPANY_ID)).thenReturn(Optional.of(company));
            when(branchRepository.findById(TEST_BRANCH_ID)).thenReturn(Optional.of(branch));
            when(currencyRepository.findByCode("HUF")).thenReturn(Optional.of(huf));
            // HUF már létezik; EUR 500 létezik, EUR 200 még nincs.
            when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(
                    any(UUID.class), any(Long.class), any(BigDecimal.class)))
                    .thenAnswer(invocation -> {
                        Long currencyId = invocation.getArgument(1);
                        BigDecimal faceValue = invocation.getArgument(2);
                        if (currencyId.equals(huf.getId())) {
                            return Optional.of(new Denomination()); // HUF már létezik
                        }
                        if (currencyId.equals(eur.getId())
                                && faceValue.compareTo(new BigDecimal("500")) == 0) {
                            return Optional.of(new Denomination()); // EUR 500 már létezik
                        }
                        return Optional.empty();
                    });
            when(denominationAllowedRepository.findActiveByCompanyId(TEST_COMPANY_ID))
                    .thenReturn(List.of(eur500, eur200));

            when(denominationRepository.save(any(Denomination.class)))
                    .thenAnswer(invocation -> invocation.getArgument(0));

            denominationService.initializeBranchDenominations(TEST_BRANCH_ID);

            // FK-076: kizárólag a denomination_allowed sorai — a teljes jegybanki
            // katalogus (korabban 15 EUR ertek, tort ermekkel) mar nem jon letre.
            verify(denominationRepository, times(1)).save(any(Denomination.class));
        }
    }

    // ============================================================
    // Bug 3: Negatív darabszám validáció
    // ============================================================

    @Test
    @DisplayName("updateDenominationQuantity: negatív darabszám → ValidationException")
    void negativeQuantityShouldThrowValidationException() {
        DenominationService.UpdateDenominationRequest request =
                DenominationService.UpdateDenominationRequest.builder()
                        .currencyId(1L)
                        .faceValue(new BigDecimal("10000"))
                        .newQuantity(-1)
                        .build();

        assertThatThrownBy(() -> denominationService.updateDenominationQuantity(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("negatív");
    }

    @Test
    @DisplayName("updateDenominationQuantity: nulla darabszám → megengedett")
    void zeroQuantityShouldBeAllowed() {
        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(TEST_BRANCH_ID);

            Currency huf = new Currency();
            huf.setCode("HUF");

            Denomination existingDenom = new Denomination();
            existingDenom.setQuantity(5);
            existingDenom.setCurrency(huf);

            when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(
                    TEST_BRANCH_ID, 1L, new BigDecimal("10000")))
                    .thenReturn(Optional.of(existingDenom));
            when(denominationRepository.save(existingDenom)).thenReturn(existingDenom);

            DenominationService.UpdateDenominationRequest request =
                    DenominationService.UpdateDenominationRequest.builder()
                            .currencyId(1L)
                            .faceValue(new BigDecimal("10000"))
                            .newQuantity(0)
                            .build();

            Denomination result = denominationService.updateDenominationQuantity(request);

            assertThat(result.getQuantity()).isEqualTo(0);
        }
    }

    // ============================================================
    // Bug 4: calculateOptimalChange explicit DESC sort
    // ============================================================

    @Test
    @DisplayName("calculateOptimalChange: rendezetlen DB bemenet esetén is helyes greedy eredmény")
    void calculateOptimalChangeShouldSortExplicitly() {
        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(TEST_BRANCH_ID);

            // Szándékosan fordított sorrendben adjuk vissza (ASC) — a bug esetén rossz eredményt adna
            Currency huf = new Currency();
            huf.setCode("HUF");

            List<Denomination> unsortedDenoms = new ArrayList<>();
            unsortedDenoms.add(makeDenom(huf, "10", 100));
            unsortedDenoms.add(makeDenom(huf, "20", 100));
            unsortedDenoms.add(makeDenom(huf, "100", 100));
            unsortedDenoms.add(makeDenom(huf, "200", 100));
            unsortedDenoms.add(makeDenom(huf, "1000", 100));
            unsortedDenoms.add(makeDenom(huf, "10000", 100));

            when(denominationRepository.findByBranchAndCurrency(TEST_BRANCH_ID, 1L))
                    .thenReturn(unsortedDenoms);

            // 15 000 Ft visszajáró → 1×10000 + 1×5000, de nincs 5000-es → 1×10000 + 5×1000
            Map<BigDecimal, Integer> result =
                    denominationService.calculateOptimalChange(1L, new BigDecimal("15000"));

            assertThat(result).containsEntry(new BigDecimal("10000"), 1);
            assertThat(result).containsEntry(new BigDecimal("1000"), 5);
        }
    }

    @Test
    @DisplayName("calculateOptimalChange: 230 Ft → 2×100 + 1×20 + 1×10")
    void calculateOptimalChange230Ft() {
        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(TEST_BRANCH_ID);

            Currency huf = new Currency();
            huf.setCode("HUF");

            // Szándékosan vegyes sorrendben
            List<Denomination> denoms = new ArrayList<>();
            denoms.add(makeDenom(huf, "10", 50));
            denoms.add(makeDenom(huf, "100", 10));
            denoms.add(makeDenom(huf, "20", 50));
            denoms.add(makeDenom(huf, "50", 50));
            denoms.add(makeDenom(huf, "200", 10));

            when(denominationRepository.findByBranchAndCurrency(TEST_BRANCH_ID, 1L))
                    .thenReturn(denoms);

            Map<BigDecimal, Integer> result =
                    denominationService.calculateOptimalChange(1L, new BigDecimal("230"));

            assertThat(result).containsEntry(new BigDecimal("200"), 1);
            assertThat(result).containsEntry(new BigDecimal("20"), 1);
            assertThat(result).containsEntry(new BigDecimal("10"), 1);

            BigDecimal total = result.entrySet().stream()
                    .map(e -> e.getKey().multiply(BigDecimal.valueOf(e.getValue())))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            assertThat(total).isEqualByComparingTo("230");
        }
    }

    // ============================================================
    // Helper
    // ============================================================

    private Denomination makeDenom(Currency currency, String faceValue, int quantity) {
        Denomination d = new Denomination();
        d.setCurrency(currency);
        d.setFaceValue(new BigDecimal(faceValue));
        d.setQuantity(quantity);
        d.setActive(true);
        d.setDenominationType(
                new BigDecimal(faceValue).compareTo(BigDecimal.ONE) >= 0
                        ? DenominationType.BANKNOTE
                        : DenominationType.COIN
        );
        return d;
    }
}
