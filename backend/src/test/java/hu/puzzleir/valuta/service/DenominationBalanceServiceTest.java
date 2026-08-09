package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.denomination.DenominationSelfCheckDto;
import hu.puzzleir.valuta.dto.denomination.DenominationQuantityUpdateRequestDto;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CashRegisterDeviceRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
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

    private DenominationBalanceService service() {
        return new DenominationBalanceService(
                balanceRepository, denominationRepository, cashRegisterDeviceRepository, branchRepository,
                cashBalanceRepository);
    }

    @Test
    void updateQuantityExplicitlySetsCurrentSubmissionDate() {
        UUID companyId = UUID.randomUUID();
        UUID cashDeskId = UUID.randomUUID();
        Currency huf = Currency.builder().id(1L).code("HUF").build();
        Denomination denomination = Denomination.builder()
                .id(2L)
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
        // FK-078 (FR-3): az upsert-kulcs mostantol a kategoriat is tartalmazza.
        when(balanceRepository.findByCashDeskIdAndDenominationIdAndCategory(
                cashDeskId, 2L, DenominationCategory.EVENING))
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
                .currency(huf)
                .faceValue(new BigDecimal("5000"))
                .denominationType(DenominationType.BANKNOTE)
                .build();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(balanceRepository.findByCashDeskIdAndDenominationIdAndCategory(
                branchId, 5L, DenominationCategory.HANDLING_FEE))
                .thenReturn(Optional.empty());
        when(denominationRepository.findById(5L)).thenReturn(Optional.of(denomination));
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

    private static CashBalance cashBalance(Long currencyId, String code, BigDecimal balance) {
        return CashBalance.builder()
                .currency(Currency.builder().id(currencyId).code(code).build())
                .currentBalance(balance)
                .build();
    }
}
