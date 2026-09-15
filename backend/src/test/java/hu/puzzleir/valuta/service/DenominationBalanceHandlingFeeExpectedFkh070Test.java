package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.denomination.DenominationSelfCheckDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.HandlingFeeBalance;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CashRegisterDeviceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.repository.HandlingFeeBalanceRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.repository.VatSupplyStockRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * FKH-071 (updates FKH-070 pinning): HANDLING_FEE Expected is the rolled
 * {@code HandlingFeeBalance}, not a per-day Transaction.handlingFee SUM.
 * KK {@code ShipmentHandlingFee} remains unused as Expected.
 */
@ExtendWith(MockitoExtension.class)
class DenominationBalanceHandlingFeeExpectedFkh070Test {

    @Mock
    private DenominationBalanceRepository denominationBalanceRepository;
    @Mock
    private DenominationRepository denominationRepository;
    @Mock
    private CashRegisterDeviceRepository cashRegisterDeviceRepository;
    @Mock
    private BranchRepository branchRepository;
    @Mock
    private CashBalanceRepository cashBalanceRepository;
    @Mock
    private DenominationAllowedRepository denominationAllowedRepository;
    @Mock
    private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    @Mock
    private HandlingFeeBalanceRepository handlingFeeBalanceRepository;
    @Mock
    private CurrencyRepository currencyRepository;
    @Mock
    private VatSupplyStockRepository vatSupplyStockRepository;
    @Mock
    private CurrencyStockRepository currencyStockRepository;

    @InjectMocks
    private DenominationBalanceService service;

    private final UUID companyId = UUID.randomUUID();
    private final UUID branchId = UUID.randomUUID();

    private MockedStatic<SecurityUtils> securityUtils;

    @BeforeEach
    void mockSecurity() {
        securityUtils = Mockito.mockStatic(SecurityUtils.class);
        securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
    }

    @AfterEach
    void closeSecurity() {
        securityUtils.close();
    }

    private void stubOwnBranch() {
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
    }

    private void stubHufCurrency() {
        when(currencyRepository.findByCode("HUF"))
                .thenReturn(Optional.of(Currency.builder().id(1L).code("HUF").name("Forint").build()));
    }

    private void stubBalance(BigDecimal amount) {
        when(handlingFeeBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId))
                .thenReturn(Optional.of(HandlingFeeBalance.builder().currentBalance(amount).build()));
    }

    @Test
    @DisplayName("FKH-071 FR-3: Expected = rolled HandlingFeeBalance (295)")
    void expectedComesFromRolledHandlingFeeBalance() {
        LocalDate today = LocalDate.now();
        stubOwnBranch();
        stubHufCurrency();
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, today, DenominationCategory.HANDLING_FEE))
                .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("295.00")}));
        stubBalance(new BigDecimal("295"));

        List<DenominationSelfCheckDto> rows =
                service.selfCheck(branchId, DenominationCategory.HANDLING_FEE);

        assertThat(rows).hasSize(1);
        DenominationSelfCheckDto row = rows.get(0);
        assertThat(row.getCurrencyCode()).isEqualTo("HUF");
        assertThat(row.getExpectedBalance()).isEqualByComparingTo("295.00");
        assertThat(row.getDifference()).isEqualByComparingTo("0.00");
        assertThat(row.isMatches()).isTrue();
    }

    @Test
    @DisplayName("FKH-071 NFR-1: Expected is Hungarian-rounded to 5 HUF (297 -> 295.00)")
    void expectedIsHungarianRoundedToFive() {
        stubOwnBranch();
        stubHufCurrency();
        stubBalance(new BigDecimal("297"));

        List<DenominationSelfCheckDto> rows =
                service.selfCheck(branchId, DenominationCategory.HANDLING_FEE);

        assertThat(rows).hasSize(1);
        assertThat(rows.get(0).getExpectedBalance()).isEqualByComparingTo("295.00");
        assertThat(rows.get(0).getDifference()).isEqualByComparingTo("-295.00");
        assertThat(rows.get(0).isMatches()).isFalse();
    }

    @Test
    @DisplayName("FKH-070 FR-3 kept: KK shipment-fee source and cash_balance are NOT consulted")
    void shipmentHandlingFeeRepositoryIsNotConsulted() {
        LocalDate today = LocalDate.now();
        stubOwnBranch();
        stubHufCurrency();
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, today, DenominationCategory.HANDLING_FEE))
                .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("295.00")}));
        stubBalance(new BigDecimal("295"));

        service.selfCheck(branchId, DenominationCategory.HANDLING_FEE);

        verifyNoInteractions(shipmentHandlingFeeRepository);
        verify(cashBalanceRepository, never()).findByBranchIdAndCompanyId(any(), any());
    }

    @Test
    @DisplayName("FKH-071: Expected ignores businessDate (rolled, no daily reset)")
    void expectedIgnoresBusinessDate() {
        LocalDate businessDate = LocalDate.of(2026, 9, 10);
        stubOwnBranch();
        stubHufCurrency();
        stubBalance(new BigDecimal("440"));

        List<DenominationSelfCheckDto> rows =
                service.selfCheck(branchId, DenominationCategory.HANDLING_FEE, businessDate);

        assertThat(rows.get(0).getExpectedBalance()).isEqualByComparingTo("440.00");
        verify(handlingFeeBalanceRepository).findByBranchIdAndCompanyId(branchId, companyId);
        verify(denominationBalanceRepository).sumActualStockByCurrency(
                branchId, businessDate, DenominationCategory.HANDLING_FEE);
    }

    @Test
    @DisplayName("FKH-071: missing balance row yields Expected 0.00 (never NPE)")
    void missingBalanceYieldsZeroExpected() {
        stubOwnBranch();
        stubHufCurrency();
        when(handlingFeeBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId))
                .thenReturn(Optional.empty());

        List<DenominationSelfCheckDto> rows =
                service.selfCheck(branchId, DenominationCategory.HANDLING_FEE);

        assertThat(rows).hasSize(1);
        assertThat(rows.get(0).getExpectedBalance()).isEqualByComparingTo("0.00");
    }
}
