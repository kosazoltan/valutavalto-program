package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.entity.VatSupplyStock;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.denomination.DenominationSelfCheckDto;
import hu.puzzleir.valuta.dto.denomination.DenominationQuantityUpdateRequestDto;
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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DenominationBalanceServiceTest {

    @Mock private DenominationBalanceRepository balanceRepository;
    @Mock private DenominationRepository denominationRepository;
    @Mock private CashRegisterDeviceRepository cashRegisterDeviceRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    // FK-080 (FR-5): a mentes-ut allowlist-gatjanak katalogus-repoja.
    @Mock private DenominationAllowedRepository denominationAllowedRepository;
    @Mock private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private VatSupplyStockRepository vatSupplyStockRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;

    private DenominationBalanceService service() {
        return new DenominationBalanceService(
                balanceRepository, denominationRepository, cashRegisterDeviceRepository, branchRepository,
                cashBalanceRepository, denominationAllowedRepository,
                shipmentHandlingFeeRepository, currencyRepository, vatSupplyStockRepository,
                currencyStockRepository);
    }

    @Test
    void updateQuantityExplicitlySetsCurrentSubmissionDate() {
        UUID companyId = UUID.randomUUID();
        UUID cashDeskId = UUID.randomUUID();
        Currency huf = Currency.builder().id(1L).code("HUF").build();
        Denomination denomination = Denomination.builder()
                .id(2L)
                // FK-080 (FR-5): a mentes-ut gatja a sor cegehez ES aktiv allapotahoz kotott,
                // ezert a fixture teljes (company + active), nem csonka. A HUF 1000 a V379
                // katalogusban BANKNOTE-kent szerepel.
                .company(Company.builder().id(companyId).build())
                .active(true)
                .currency(huf)
                .faceValue(new BigDecimal("1000"))
                .denominationType(DenominationType.BANKNOTE)
                .build();
        DenominationBalance balance = DenominationBalance.builder()
                .id(UUID.randomUUID())
                .cashDeskId(cashDeskId)
                .denomination(denomination)
                .quantity(1)
                .totalValue(new BigDecimal("1000"))
                .submissionDate(LocalDate.now().minusDays(1))
                .build();
        when(branchRepository.existsByIdAndCompanyId(cashDeskId, companyId)).thenReturn(false);
        when(cashRegisterDeviceRepository.existsByIdAndCompanyId(cashDeskId, companyId)).thenReturn(true);
        // FK-080 (FR-5): a gat MINDEN mentes-uton lefut, ezert a sort es a katalogus-sort
        // is be kell allitani — korabban a save-ut nem toltotte be a denomination-t.
        when(denominationRepository.findById(2L)).thenReturn(Optional.of(denomination));
        when(denominationAllowedRepository.findActiveAllowed(companyId, 1L, new BigDecimal("1000")))
                .thenReturn(Optional.of(DenominationAllowed.builder()
                        .faceValue(new BigDecimal("1000"))
                        .denominationType(DenominationType.BANKNOTE)
                        .active(true)
                        .build()));
        // FK-078 (FR-3): az upsert-kulcs mostantol a kategoriat is tartalmazza.
        // FKH-050 (D5): a lookup datum-tudatos — a mai napra szur (null businessDate -> ma).
        when(balanceRepository.findByCashDeskIdAndDenominationIdAndCategoryAndSubmissionDate(
                cashDeskId, 2L, DenominationCategory.EVENING, LocalDate.now()))
                .thenReturn(Optional.of(balance));
        when(balanceRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            service().updateQuantity(cashDeskId, 2L, 1);
        }

        ArgumentCaptor<DenominationBalance> captor = ArgumentCaptor.forClass(DenominationBalance.class);
        verify(balanceRepository).save(captor.capture());
        assertThat(captor.getValue().getSubmissionDate()).isEqualTo(LocalDate.now());
    }

    /**
     * FK-077 FR-2 — a guard gyokerok-javitasa. A denomination_balance.cash_desk_id
     * a gyakorlatban FIOK-UUID (a ClosingWizardService a branchId-t irja bele, es a
     * frontend is azt kuldi). A regi guard KIZAROLAG cash_register_device PK-t fogadott
     * el, ezert minden valos hivast 404-gyel utasitott el → csendes kiurules.
     */
    @Test
    void readAcceptsBranchUuidWithoutCashRegisterDeviceRow() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(balanceRepository.findByCashDeskId(branchId)).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThat(service().getCashDeskDenominations(branchId)).isEmpty();
        }

        // A fiok-talalat utan az eszkoz-tabla mar meg sem kerdezodik (rovidzar).
        verify(cashRegisterDeviceRepository, never()).existsByIdAndCompanyId(any(), any());
    }

    /** FK-077 FR-4 regresszio: a penztargep-eszkoz-id tovabbra is ervenyes azonosito. */
    @Test
    void readStillAcceptsCashRegisterDeviceId() {
        UUID companyId = UUID.randomUUID();
        UUID deviceId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(deviceId, companyId)).thenReturn(false);
        when(cashRegisterDeviceRepository.existsByIdAndCompanyId(deviceId, companyId)).thenReturn(true);
        when(balanceRepository.findByCashDeskId(deviceId)).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThat(service().getCashDeskDenominations(deviceId)).isEmpty();
        }
    }

    /** FK-077: a tenant-izolacio valtozatlanul szoros — mas ceg fiokja/eszkoze 404. */
    @Test
    void crossTenantIdentifierIsStillRejected() {
        UUID companyId = UUID.randomUUID();
        UUID foreignId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(foreignId, companyId)).thenReturn(false);
        when(cashRegisterDeviceRepository.existsByIdAndCompanyId(foreignId, companyId)).thenReturn(false);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            DenominationBalanceService svc = service();
            assertThatThrownBy(() -> svc.getCashDeskDenominations(foreignId))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
        verify(balanceRepository, never()).findByCashDeskId(any());
    }

    /** FK-077: null azonosito 404, a repository-k megkerdezese nelkul. */
    @Test
    void nullIdentifierIsRejected() {
        UUID companyId = UUID.randomUUID();
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            DenominationBalanceService svc = service();
            assertThatThrownBy(() -> svc.getCashDeskDenominations(null))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
        verify(branchRepository, never()).existsByIdAndCompanyId(any(), any());
        verify(cashRegisterDeviceRepository, never()).existsByIdAndCompanyId(any(), any());
    }

    // =====================================================================
    // FK-078 — napkozbeni onellenorzes
    // =====================================================================

    /**
     * FK-078 FR-3: a Kezelesi dij feluletrol mentett sor kategoriaja HANDLING_FEE,
     * nem EVENING. Korabban minden mentes EVENING-kent irodott.
     */
    @Test
    void batchUpdateTagsHandlingFeeCategory() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        Currency huf = Currency.builder().id(1L).code("HUF").build();
        Denomination denomination = Denomination.builder()
                .id(5L)
                // FK-080 (FR-5): teljes fixture — a gat a sor cegehez es aktiv allapotahoz kotott.
                .company(Company.builder().id(companyId).build())
                .active(true)
                .currency(huf)
                .faceValue(new BigDecimal("5000"))
                .denominationType(DenominationType.BANKNOTE)
                .build();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        // FKH-050 (D5): a lookup datum-tudatos — a mai napra szur (null businessDate -> ma).
        when(balanceRepository.findByCashDeskIdAndDenominationIdAndCategoryAndSubmissionDate(
                branchId, 5L, DenominationCategory.HANDLING_FEE, LocalDate.now()))
                .thenReturn(Optional.empty());
        when(denominationRepository.findById(5L)).thenReturn(Optional.of(denomination));
        // FK-080 (FR-5): a HUF 5000 a V379 katalogusban BANKNOTE — engedelyezett.
        when(denominationAllowedRepository.findActiveAllowed(companyId, 1L, new BigDecimal("5000")))
                .thenReturn(Optional.of(DenominationAllowed.builder()
                        .faceValue(new BigDecimal("5000"))
                        .denominationType(DenominationType.BANKNOTE)
                        .active(true)
                        .build()));
        when(balanceRepository.save(any())).thenAnswer(invocation -> {
            DenominationBalance saved = invocation.getArgument(0);
            saved.setId(UUID.randomUUID());
            return saved;
        });

        DenominationQuantityUpdateRequestDto update = new DenominationQuantityUpdateRequestDto();
        update.setDenominationId("5");
        update.setQuantity(3);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            service().batchUpdate(branchId, List.of(update), DenominationCategory.HANDLING_FEE);
        }

        ArgumentCaptor<DenominationBalance> captor = ArgumentCaptor.forClass(DenominationBalance.class);
        verify(balanceRepository).save(captor.capture());
        assertThat(captor.getValue().getDenominationCategory())
                .as("FR-3: a Kezelesi dij felulet HANDLING_FEE-kent tagel")
                .isEqualTo(DenominationCategory.HANDLING_FEE);
        assertThat(captor.getValue().getQuantity()).isEqualTo(3);
        assertThat(captor.getValue().getSubmissionDate()).isEqualTo(LocalDate.now());
    }

    /**
     * FK-078 FR-3: a kategoria nelkuli (regi) hivo valtozatlanul EVENING-et ir —
     * visszamenoleg kompatibilis.
     */
    @Test
    void batchUpdateWithoutCategoryStaysEvening() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThat(service().batchUpdate(branchId, List.of())).isEmpty();
        }

        // Ures lista: nincs mentes, de a kategoria-default utvonal nem dob es nem ir.
        verify(balanceRepository, never()).save(any());
    }

    /**
     * FK-078 FR-4: penznemenkenti egyezes-jelzes — pontos egyezesnel matches=true,
     * elteresnel elojeles difference. A mentes NEM blokkolodik (a metodus csak informal).
     */
    @Test
    void selfCheckComparesDenominatedAmountToCashBalance() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(balanceRepository.sumActualStockByCurrency(
                branchId, LocalDate.now(), DenominationCategory.EVENING))
                .thenReturn(List.of(
                        new Object[]{"HUF", new BigDecimal("125000.00")},
                        new Object[]{"EUR", new BigDecimal("450.00")}));
        when(cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId))
                .thenReturn(List.of(
                        cashBalance(1L, "HUF", new BigDecimal("125000.00")),
                        cashBalance(2L, "EUR", new BigDecimal("500.00")),
                        cashBalance(3L, "USD", new BigDecimal("0.00"))));

        List<DenominationSelfCheckDto> result;
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            result = service().selfCheck(branchId, DenominationCategory.EVENING);
        }

        assertThat(result).hasSize(3);

        DenominationSelfCheckDto huf = result.stream()
                .filter(r -> "HUF".equals(r.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(huf.isMatches()).as("FR-4: pontos egyezes -> zold").isTrue();
        assertThat(huf.getDifference()).isEqualByComparingTo("0.00");

        DenominationSelfCheckDto eur = result.stream()
                .filter(r -> "EUR".equals(r.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(eur.isMatches()).as("FR-4: elteres -> piros").isFalse();
        assertThat(eur.getDifference())
                .as("FR-4: elojeles elteres (450 becimletezve, 500 a konyv szerint)")
                .isEqualByComparingTo("-50.00");

        DenominationSelfCheckDto usd = result.stream()
                .filter(r -> "USD".equals(r.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(usd.getDenominatedAmount())
                .as("Becimletezes nelkuli penznem 0-val szerepel, nem hianyzik")
                .isEqualByComparingTo("0.00");
        assertThat(usd.isMatches()).isTrue();
    }

    /** FK-078: az onellenorzes is a tenant-guard mogott van (cross-tenant fiok -> 404). */
    @Test
    void selfCheckRejectsCrossTenantBranch() {
        UUID companyId = UUID.randomUUID();
        UUID foreignId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(foreignId, companyId)).thenReturn(false);
        when(cashRegisterDeviceRepository.existsByIdAndCompanyId(foreignId, companyId)).thenReturn(false);

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            DenominationBalanceService svc = service();
            assertThatThrownBy(() -> svc.selfCheck(foreignId, DenominationCategory.EVENING))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
        verify(cashBalanceRepository, never()).findByBranchIdAndCompanyId(any(), any());
    }

    // =====================================================================
    // FKH-038 — currency-scope READ kategória-szűrése
    // =====================================================================

    /**
     * FKH-038 FR-2: a HANDLING_FEE betöltés a repository-t a kért kategóriával hívja,
     * és az EVENING sort nem keveri bele.
     */
    @Test
    void getByCurrencyReturnsOnlyRequestedHandlingFeeRows() {
        UUID companyId = UUID.randomUUID();
        UUID cashDeskId = UUID.randomUUID();
        Currency huf = Currency.builder().id(1L).code("HUF").build();
        Denomination denomination = Denomination.builder()
                .id(2L)
                .currency(huf)
                .faceValue(new BigDecimal("10000"))
                .denominationType(DenominationType.BANKNOTE)
                .build();
        DenominationBalance handlingFee = DenominationBalance.builder()
                .id(UUID.randomUUID())
                .cashDeskId(cashDeskId)
                .denomination(denomination)
                .quantity(3)
                .totalValue(new BigDecimal("30000"))
                .denominationCategory(DenominationCategory.HANDLING_FEE)
                .build();
        when(branchRepository.existsByIdAndCompanyId(cashDeskId, companyId)).thenReturn(true);
        // FKH-050 (D5): az olvasás dátum-tudatos — a mai napra szűr (null businessDate -> ma).
        when(balanceRepository.findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                cashDeskId, 1L, DenominationCategory.HANDLING_FEE, LocalDate.now()))
                .thenReturn(List.of(handlingFee));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            var result = service().getCashDeskDenominationsByCurrency(
                    cashDeskId, 1L, DenominationCategory.HANDLING_FEE);
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getQuantity()).isEqualTo(3);
            assertThat(result.get(0).getTotalValue()).isEqualByComparingTo("30000");
        }

        verify(balanceRepository).findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                cashDeskId, 1L, DenominationCategory.HANDLING_FEE, LocalDate.now());
        verify(balanceRepository, never()).findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                cashDeskId, 1L, DenominationCategory.EVENING, LocalDate.now());
    }

    /**
     * FKH-038 FR-4: az Esti zárás betöltése EVENING kategóriát kér, HANDLING_FEE sort nem.
     */
    @Test
    void getByCurrencyReturnsOnlyRequestedEveningRows() {
        UUID companyId = UUID.randomUUID();
        UUID cashDeskId = UUID.randomUUID();
        Currency huf = Currency.builder().id(1L).code("HUF").build();
        Denomination denomination = Denomination.builder()
                .id(2L)
                .currency(huf)
                .faceValue(new BigDecimal("10000"))
                .denominationType(DenominationType.BANKNOTE)
                .build();
        DenominationBalance evening = DenominationBalance.builder()
                .id(UUID.randomUUID())
                .cashDeskId(cashDeskId)
                .denomination(denomination)
                .quantity(10)
                .totalValue(new BigDecimal("100000"))
                .denominationCategory(DenominationCategory.EVENING)
                .build();
        when(branchRepository.existsByIdAndCompanyId(cashDeskId, companyId)).thenReturn(true);
        // FKH-050 (D5): az olvasás dátum-tudatos — a mai napra szűr (null businessDate -> ma).
        when(balanceRepository.findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                cashDeskId, 1L, DenominationCategory.EVENING, LocalDate.now()))
                .thenReturn(List.of(evening));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            var result = service().getCashDeskDenominationsByCurrency(
                    cashDeskId, 1L, DenominationCategory.EVENING);
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getQuantity()).isEqualTo(10);
        }

        verify(balanceRepository).findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                cashDeskId, 1L, DenominationCategory.EVENING, LocalDate.now());
        verify(balanceRepository, never()).findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                cashDeskId, 1L, DenominationCategory.HANDLING_FEE, LocalDate.now());
    }

    /**
     * FKH-038: hiányzó kategória → EVENING (WRITE/selfCheck default), nem kevert lista.
     */
    @Test
    void getByCurrencyNullCategoryDefaultsToEvening() {
        UUID companyId = UUID.randomUUID();
        UUID cashDeskId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(cashDeskId, companyId)).thenReturn(true);
        // FKH-050 (D5): az olvasás dátum-tudatos — a mai napra szűr (null businessDate -> ma).
        when(balanceRepository.findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                cashDeskId, 1L, DenominationCategory.EVENING, LocalDate.now()))
                .thenReturn(List.of());

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThat(service().getCashDeskDenominationsByCurrency(cashDeskId, 1L, null)).isEmpty();
        }

        verify(balanceRepository).findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                cashDeskId, 1L, DenominationCategory.EVENING, LocalDate.now());
    }

    /**
     * FKH-039 FR-6/FR-7: HANDLING_FEE önellenőrzés az aznapi KK calculatedFee összeget
     * várja el (nem cash_balance-t); üres nap → elvárt 0, egy HUF sor.
     */
    @Test
    void selfCheckHandlingFeeUsesDailyFeeSumNotCashBalance() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(balanceRepository.sumActualStockByCurrency(
                branchId, LocalDate.now(), DenominationCategory.HANDLING_FEE))
                .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("5000.00")}));
        when(shipmentHandlingFeeRepository.sumDailyFeeForBranch(companyId, branchId, LocalDate.now()))
                .thenReturn(new BigDecimal("5000"));
        when(currencyRepository.findByCode("HUF"))
                .thenReturn(Optional.of(Currency.builder().id(1L).code("HUF").build()));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            List<DenominationSelfCheckDto> result =
                    service().selfCheck(branchId, DenominationCategory.HANDLING_FEE);
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getCurrencyCode()).isEqualTo("HUF");
            assertThat(result.get(0).getExpectedBalance()).isEqualByComparingTo("5000.00");
            assertThat(result.get(0).getDenominatedAmount()).isEqualByComparingTo("5000.00");
            assertThat(result.get(0).isMatches()).isTrue();
        }

        verify(shipmentHandlingFeeRepository).sumDailyFeeForBranch(companyId, branchId, LocalDate.now());
        verify(cashBalanceRepository, never()).findByBranchIdAndCompanyId(any(), any());
    }

    @Test
    void selfCheckHandlingFeeZeroWhenNoDailyMovement() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(balanceRepository.sumActualStockByCurrency(
                branchId, LocalDate.now(), DenominationCategory.HANDLING_FEE))
                .thenReturn(List.of());
        when(shipmentHandlingFeeRepository.sumDailyFeeForBranch(companyId, branchId, LocalDate.now()))
                .thenReturn(BigDecimal.ZERO);
        when(currencyRepository.findByCode("HUF"))
                .thenReturn(Optional.of(Currency.builder().id(1L).code("HUF").build()));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            List<DenominationSelfCheckDto> result =
                    service().selfCheck(branchId, DenominationCategory.HANDLING_FEE);
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getExpectedBalance()).isEqualByComparingTo("0.00");
            assertThat(result.get(0).isMatches()).isTrue();
        }
    }

    @Test
    void selfCheckVatUsesSupplyStockBalance() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        Branch branch = Branch.builder().id(branchId).vaultTerritoryId(7).build();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(balanceRepository.sumActualStockByCurrency(
                branchId, LocalDate.now(), DenominationCategory.VAT))
                .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("12000.00")}));
        when(branchRepository.findByIdAndCompanyId(branchId, companyId)).thenReturn(Optional.of(branch));
        when(vatSupplyStockRepository.findByCompanyIdAndVaultTerritoryId(companyId, 7))
                .thenReturn(Optional.of(VatSupplyStock.builder()
                        .currentBalance(new BigDecimal("12000.00")).build()));
        when(currencyRepository.findByCode("HUF"))
                .thenReturn(Optional.of(Currency.builder().id(1L).code("HUF").build()));

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            List<DenominationSelfCheckDto> result =
                    service().selfCheck(branchId, DenominationCategory.VAT);
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getExpectedBalance()).isEqualByComparingTo("12000.00");
            assertThat(result.get(0).isMatches()).isTrue();
        }
    }

    // =====================================================================
    // FKH-046 — vault self-check reads currency_stock (VAULT), not cash_balance
    // =====================================================================

    /**
     * FKH-046 FR-1/FR-2: vault branch EVENING self-check reads the expected
     * balance from currency_stock (entity_type=VAULT, entity_id=vaultTerritoryId),
     * never from cash_balance (which holds only the vault's booking mirror).
     */
    @Test
    void selfCheckVaultBranchReadsCurrencyStock() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        Branch branch = Branch.builder().id(branchId).isVault(true).vaultTerritoryId(7).build();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(branchRepository.findByIdAndCompanyId(branchId, companyId)).thenReturn(Optional.of(branch));
        when(balanceRepository.sumActualStockByCurrency(
                branchId, LocalDate.now(), DenominationCategory.EVENING))
                .thenReturn(List.<Object[]>of(
                        new Object[]{"HUF", new BigDecimal("220500000.00")},
                        new Object[]{"EUR", new BigDecimal("2200.00")}));
        when(currencyStockRepository.findByCompanyIdAndEntityTypeAndEntityId(companyId, "VAULT", "7"))
                .thenReturn(List.of(
                        CurrencyStock.builder().currencyCode("HUF").quantity(new BigDecimal("220500000")).build(),
                        CurrencyStock.builder().currencyCode("EUR").quantity(new BigDecimal("2200")).build(),
                        CurrencyStock.builder().currencyCode("GBP").quantity(null).build()));
        when(currencyRepository.findByCode("HUF"))
                .thenReturn(Optional.of(Currency.builder().id(1L).code("HUF").build()));
        when(currencyRepository.findByCode("EUR"))
                .thenReturn(Optional.of(Currency.builder().id(2L).code("EUR").build()));

        List<DenominationSelfCheckDto> result;
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            result = service().selfCheck(branchId, DenominationCategory.EVENING);
        }

        assertThat(result).hasSize(3);
        DenominationSelfCheckDto huf = result.stream()
                .filter(r -> "HUF".equals(r.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(huf.getExpectedBalance()).isEqualByComparingTo("220500000.00");
        assertThat(huf.isMatches()).isTrue();
        DenominationSelfCheckDto eur = result.stream()
                .filter(r -> "EUR".equals(r.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(eur.getExpectedBalance()).isEqualByComparingTo("2200.00");
        // FKH-046 (review nit W3): a null quantity is treated as ZERO expected,
        // never as an NPE or an unscaled null.
        DenominationSelfCheckDto gbp = result.stream()
                .filter(r -> "GBP".equals(r.getCurrencyCode())).findFirst().orElseThrow();
        assertThat(gbp.getExpectedBalance()).isEqualByComparingTo("0.00");
        verify(cashBalanceRepository, never()).findByBranchIdAndCompanyId(any(), any());
    }

    /**
     * FKH-046 FR-3: non-vault branch behavior is UNCHANGED (cash_balance source,
     * currency_stock never queried).
     */
    @Test
    void selfCheckNonVaultBranchStillUsesCashBalance() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        Branch branch = Branch.builder().id(branchId).isVault(false).build();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(branchRepository.findByIdAndCompanyId(branchId, companyId)).thenReturn(Optional.of(branch));
        when(balanceRepository.sumActualStockByCurrency(
                branchId, LocalDate.now(), DenominationCategory.EVENING))
                .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("125000.00")}));
        when(cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId))
                .thenReturn(List.of(cashBalance(1L, "HUF", new BigDecimal("125000.00"))));

        List<DenominationSelfCheckDto> result;
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            result = service().selfCheck(branchId, DenominationCategory.EVENING);
        }

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getExpectedBalance()).isEqualByComparingTo("125000.00");
        assertThat(result.get(0).isMatches()).isTrue();
        verify(currencyStockRepository, never())
                .findByCompanyIdAndEntityTypeAndEntityId(any(), any(), any());
    }

    /**
     * FKH-046 edge case: vault branch WITHOUT vaultTerritoryId fails closed
     * (empty result, no exception) instead of reading the wrong cash_balance row.
     */
    @Test
    void selfCheckVaultBranchWithoutTerritoryFailsClosed() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        Branch branch = Branch.builder().id(branchId).isVault(true).vaultTerritoryId(null).build();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(branchRepository.findByIdAndCompanyId(branchId, companyId)).thenReturn(Optional.of(branch));
        when(balanceRepository.sumActualStockByCurrency(
                branchId, LocalDate.now(), DenominationCategory.EVENING))
                .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("1000.00")}));

        List<DenominationSelfCheckDto> result;
        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            result = service().selfCheck(branchId, DenominationCategory.EVENING);
        }

        assertThat(result).isEmpty();
        verify(cashBalanceRepository, never()).findByBranchIdAndCompanyId(any(), any());
        verify(currencyStockRepository, never())
                .findByCompanyIdAndEntityTypeAndEntityId(any(), any(), any());
    }

    private static CashBalance cashBalance(Long currencyId, String code, BigDecimal balance) {
        return CashBalance.builder()
                .currency(Currency.builder().id(currencyId).code(code).build())
                .currentBalance(balance)
                .build();
    }
}
