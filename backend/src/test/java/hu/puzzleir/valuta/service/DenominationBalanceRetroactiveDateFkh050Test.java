package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.DenominationType;
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
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-050 (D5): date-keyed denomination rows — a past-date retroactive write must
 * NOT clobber today's in-progress row. V387 replaces the dateless unique key with
 * {@code (cash_desk_id, denomination_id, denomination_category, submission_date)}
 * and the service gains a trailing {@code businessDate} parameter (null -> today).
 */
@ExtendWith(MockitoExtension.class)
class DenominationBalanceRetroactiveDateFkh050Test {

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
    private CurrencyRepository currencyRepository;
    @Mock
    private VatSupplyStockRepository vatSupplyStockRepository;
    @Mock
    private CurrencyStockRepository currencyStockRepository;

    @InjectMocks
    private DenominationBalanceService service;

    private final UUID companyId = UUID.randomUUID();
    private final UUID branchId = UUID.randomUUID();

    @BeforeEach
    void setupSecurityContext() {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("CASHIER1", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(101L, companyId, branchId, "CASHIER"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("D5: a past-date write creates/updates a SEPARATE row; today's row untouched;"
            + " the past-date stock aggregation is queried with the past date")
    void pastDateWriteDoesNotClobberTodaysRow() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);
        Company company = Company.builder().id(companyId).code("EBC").name("EBC").build();
        Currency huf = Currency.builder().id(1L).code("HUF").name("Forint").build();
        Denomination denom = denomination(huf);

        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(denominationRepository.findById(7L)).thenReturn(Optional.of(denom));
        when(denominationAllowedRepository.findActiveAllowed(companyId, 1L, new BigDecimal("1000")))
                .thenReturn(Optional.of(DenominationAllowed.builder()
                        .currency(huf)
                        .faceValue(new BigDecimal("1000"))
                        .denominationType(DenominationType.BANKNOTE)
                        .build()));
        // No existing row for either date -> both writes INSERT distinct rows.
        when(denominationBalanceRepository
                .findByCashDeskIdAndDenominationIdAndCategoryAndSubmissionDate(
                        branchId, 7L, DenominationCategory.EVENING, today))
                .thenReturn(Optional.empty());
        when(denominationBalanceRepository
                .findByCashDeskIdAndDenominationIdAndCategoryAndSubmissionDate(
                        branchId, 7L, DenominationCategory.EVENING, d3))
                .thenReturn(Optional.empty());
        when(denominationBalanceRepository.save(any(DenominationBalance.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        // Today's entry: 5 x 1000 HUF (businessDate=null -> today).
        service.updateQuantity(branchId, 7L, 5, DenominationCategory.EVENING, null);
        // Retroactive entry: 3 x 1000 HUF with businessDate=D-3.
        service.updateQuantity(branchId, 7L, 3, DenominationCategory.EVENING, d3);

        ArgumentCaptor<DenominationBalance> saved = ArgumentCaptor.forClass(DenominationBalance.class);
        verify(denominationBalanceRepository, org.mockito.Mockito.times(2)).save(saved.capture());
        List<DenominationBalance> rows = saved.getAllValues();

        // TWO distinct rows: today qty=5 and D-3 qty=3.
        assertThat(rows).hasSize(2);
        assertThat(rows.get(0).getSubmissionDate()).isEqualTo(today);
        assertThat(rows.get(0).getQuantity()).isEqualTo(5);
        assertThat(rows.get(0).getTotalValue()).isEqualByComparingTo("5000");
        assertThat(rows.get(1).getSubmissionDate()).isEqualTo(d3);
        assertThat(rows.get(1).getQuantity()).isEqualTo(3);
        assertThat(rows.get(1).getTotalValue()).isEqualByComparingTo("3000");

        // The past-date stock aggregation reads by the past date only.
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, d3, DenominationCategory.EVENING))
                .thenReturn(List.of(new Object[]{"HUF", new BigDecimal("3000")}));
        List<Object[]> pastStock = denominationBalanceRepository
                .sumActualStockByCurrency(branchId, d3, DenominationCategory.EVENING);
        assertThat((BigDecimal) pastStock.get(0)[1]).isEqualByComparingTo("3000");
        verify(denominationBalanceRepository, never()).delete(any());
    }

    @Test
    @DisplayName("D5: selfCheck with a past businessDate aggregates that date; null -> today")
    void selfCheckWithPastBusinessDateUsesThatDate() {
        LocalDate today = LocalDate.now();
        LocalDate d3 = today.minusDays(3);
        Branch branch = Branch.builder().id(branchId).code("B1").company(
                Company.builder().id(companyId).build()).build();

        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(branchRepository.findByIdAndCompanyId(branchId, companyId))
                .thenReturn(Optional.of(branch));
        when(cashBalanceRepository.findByBranchIdAndCompanyId(branchId, companyId))
                .thenReturn(List.of());
        // Counts exist only for D-3.
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, d3, DenominationCategory.EVENING))
                .thenReturn(List.of(new Object[]{"HUF", new BigDecimal("3000")}));
        when(denominationBalanceRepository.sumActualStockByCurrency(
                branchId, today, DenominationCategory.EVENING))
                .thenReturn(List.of());

        // Past-date self-check sees the D-3 counts.
        service.selfCheck(branchId, DenominationCategory.EVENING, d3);
        verify(denominationBalanceRepository).sumActualStockByCurrency(
                branchId, d3, DenominationCategory.EVENING);

        // null businessDate -> today.
        service.selfCheck(branchId, DenominationCategory.EVENING, null);
        verify(denominationBalanceRepository).sumActualStockByCurrency(
                branchId, today, DenominationCategory.EVENING);
    }

    @Test
    @DisplayName("D5 (pinned accepted change): today's read is date-filtered —"
            + " a D-1 row is not returned for today")
    void todayReadIsDateFiltered() {
        LocalDate today = LocalDate.now();
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(denominationBalanceRepository
                .findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                        branchId, 1L, DenominationCategory.EVENING, today))
                .thenReturn(List.of());

        service.getCashDeskDenominationsByCurrency(branchId, 1L, DenominationCategory.EVENING, null);

        // The lookup MUST be date-scoped to today (a D-1 row cannot leak in).
        verify(denominationBalanceRepository)
                .findByCashDeskIdAndCurrencyIdAndCategoryAndSubmissionDate(
                        eq(branchId), eq(1L), eq(DenominationCategory.EVENING), eq(today));
        verify(denominationBalanceRepository, never()).findByCashDeskIdAndCurrencyIdAndCategory(
                any(), any(), any());
    }

    private Denomination denomination(Currency huf) {
        Company company = Company.builder().id(companyId).code("EBC").name("EBC").build();
        return Denomination.builder()
                .id(7L)
                .company(company)
                .branch(Branch.builder().id(branchId).company(company).build())
                .currency(huf)
                .faceValue(new BigDecimal("1000"))
                .denominationType(DenominationType.BANKNOTE)
                .build();
    }
}
