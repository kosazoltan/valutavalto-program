package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.denomination.DenominationSelfCheckDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CashRegisterDeviceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.VatSupplyStockRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyCollection;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

/**
 * FKH-070: the HANDLING_FEE self-check Expected must come from the LIVE
 * {@code Transaction.handlingFee} header sum (company + branch + business date,
 * COMPLETED + financialEffective + buy/sell types), Hungarian-rounded to 5 HUF —
 * NOT from the never-populated KK {@code ShipmentHandlingFee} sum.
 *
 * <p>Pinning test (plan WU-1): do not edit after commit.</p>
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
    // Kept ONLY so case 3 can prove the KK source is not consulted anymore.
    @Mock
    private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    @Mock
    private TransactionRepository transactionRepository;
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

    @Test
    @DisplayName("FKH-070 FR-1: Expected = live transaction handling-fee sum (295 -> 295.00)")
    void expectedComesFromLiveTransactionHandlingFeeSum() {
        LocalDate today = LocalDate.now();
        stubOwnBranch();
        stubHufCurrency();
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, today, DenominationCategory.HANDLING_FEE))
                .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("295.00")}));
        when(transactionRepository.sumHandlingFeeForBranchAndDate(
                eq(companyId), eq(branchId), eq(today), anyCollection()))
                .thenReturn(new BigDecimal("295"));

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
    @DisplayName("FKH-070 NFR-2: Expected is Hungarian-rounded to 5 HUF (297 -> 295.00)")
    void expectedIsHungarianRoundedToFive() {
        LocalDate today = LocalDate.now();
        stubOwnBranch();
        stubHufCurrency();
        when(transactionRepository.sumHandlingFeeForBranchAndDate(
                eq(companyId), eq(branchId), eq(today), anyCollection()))
                .thenReturn(new BigDecimal("297"));

        List<DenominationSelfCheckDto> rows =
                service.selfCheck(branchId, DenominationCategory.HANDLING_FEE);

        assertThat(rows).hasSize(1);
        DenominationSelfCheckDto row = rows.get(0);
        assertThat(row.getExpectedBalance()).isEqualByComparingTo("295.00");
        assertThat(row.getDifference()).isEqualByComparingTo("-295.00");
        assertThat(row.isMatches()).isFalse();
    }

    @Test
    @DisplayName("FKH-070 FR-3: the KK shipment-fee source and cash_balance are NOT consulted")
    void shipmentHandlingFeeRepositoryIsNotConsulted() {
        LocalDate today = LocalDate.now();
        stubOwnBranch();
        stubHufCurrency();
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, today, DenominationCategory.HANDLING_FEE))
                .thenReturn(List.<Object[]>of(new Object[]{"HUF", new BigDecimal("295.00")}));
        when(transactionRepository.sumHandlingFeeForBranchAndDate(
                eq(companyId), eq(branchId), eq(today), anyCollection()))
                .thenReturn(new BigDecimal("295"));

        service.selfCheck(branchId, DenominationCategory.HANDLING_FEE);

        verifyNoInteractions(shipmentHandlingFeeRepository);
        verify(cashBalanceRepository, never()).findByBranchIdAndCompanyId(any(), any());
    }

    @Test
    @DisplayName("FKH-070 / FKH-050: an explicit businessDate is passed through to the finder")
    void explicitBusinessDateIsPassedThrough() {
        LocalDate businessDate = LocalDate.of(2026, 9, 10);
        stubOwnBranch();

        service.selfCheck(branchId, DenominationCategory.HANDLING_FEE, businessDate);

        verify(transactionRepository).sumHandlingFeeForBranchAndDate(
                eq(companyId), eq(branchId), eq(businessDate), anyCollection());
    }

    @Test
    @DisplayName("FKH-070 TBD-2: the type filter is exactly the buy+sell family")
    void typeFilterIsBuyAndSellFamily() {
        stubOwnBranch();

        service.selfCheck(branchId, DenominationCategory.HANDLING_FEE);

        @SuppressWarnings("unchecked")
        ArgumentCaptor<Collection<TransactionType>> captor =
                ArgumentCaptor.forClass((Class<Collection<TransactionType>>) (Class<?>) Collection.class);
        verify(transactionRepository).sumHandlingFeeForBranchAndDate(
                eq(companyId), eq(branchId), any(LocalDate.class), captor.capture());
        assertThat(captor.getValue()).containsExactlyInAnyOrder(
                TransactionType.BUY,
                TransactionType.WESTERN_UNION_RECEIVE,
                TransactionType.MONEYGRAM_RECEIVE,
                TransactionType.SELL,
                TransactionType.WESTERN_UNION_SEND,
                TransactionType.MONEYGRAM_SEND);
    }

    @Test
    @DisplayName("FKH-070: a null live sum yields Expected 0.00 (never NPE)")
    void nullSumYieldsZeroExpected() {
        LocalDate today = LocalDate.now();
        stubOwnBranch();
        stubHufCurrency();
        when(transactionRepository.sumHandlingFeeForBranchAndDate(
                eq(companyId), eq(branchId), eq(today), anyCollection()))
                .thenReturn(null);

        List<DenominationSelfCheckDto> rows =
                service.selfCheck(branchId, DenominationCategory.HANDLING_FEE);

        assertThat(rows).hasSize(1);
        assertThat(rows.get(0).getExpectedBalance()).isEqualByComparingTo("0.00");
    }
}
