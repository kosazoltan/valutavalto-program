package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.beans.factory.ObjectProvider;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Audit-finding 2026-05-31 (P1): a sikeres tranzakció könyvelése után KÖTELEZŐ az ügyfél
 * highRiskFlag frissítése. Eddig az AmlService.setHighRiskFlagIfNeeded SEHOL nem hívódott
 * (halott write-oldali AML-kontroll); a flagHighRiskAfterBooking köti be a 3 könyvelő flow-ba.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TransactionOperationHelperTest {

    @InjectMocks private TransactionOperationHelper helper;

    @Mock private DailySessionService dailySessionService;
    @Mock private AmlService amlService;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private VaultStockFlowService vaultStockFlowService;
    @Mock private ObjectProvider<CameraTransactionLinker> cameraTransactionLinkerProvider;

    @Test
    @DisplayName("flagHighRiskAfterBooking: a friss éves göngyölttel hívja a setHighRiskFlagIfNeeded-et")
    void flagHighRiskAfterBooking_callsSetWithAnnualTotal() {
        BigDecimal annual = new BigDecimal("4000000");
        when(amlService.getAnnualRollingTotal("CUST1")).thenReturn(annual);

        helper.flagHighRiskAfterBooking("CUST1");

        verify(amlService).getAnnualRollingTotal("CUST1");
        verify(amlService).setHighRiskFlagIfNeeded(eq("CUST1"), eq(annual));
    }

    @Test
    @DisplayName("flagHighRiskAfterBooking: null/üres customerId → nincs AML-hívás (anonim ügyfél)")
    void flagHighRiskAfterBooking_blankCustomer_noCall() {
        helper.flagHighRiskAfterBooking(null);
        helper.flagHighRiskAfterBooking("   ");

        verify(amlService, never()).getAnnualRollingTotal(any());
        verify(amlService, never()).setHighRiskFlagIfNeeded(any(), any());
    }

    @Test
    @DisplayName("Audit P2 #7: performAmlCheck NULL AML-eredménynél → ValidationException (FAIL-CLOSED; VV-AML-004 strukturált log)")
    void performAmlCheck_nullResult_throwsFailClosed() {
        when(amlService.checkTransaction(any(), any(), any(), any(), any(), any())).thenReturn(null);

        ValidationException ex = assertThrows(ValidationException.class,
                () -> helper.performAmlCheck(new BigDecimal("100000"), "C1", "Név", "DOC", "EUR"));
        assertTrue(ex.getMessage().contains("AML"), ex.getMessage());
        // A tranzakciót a dobott kivétel blokkolja (fail-closed); a VV-AML-004 FATAL strukturáltan logolva.
        verify(amlService).checkTransaction(any(), any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("FK-053: helper.updateCashBalance vault-kimenő pénzmozgást currency_stock fedezet nélkül blokkol")
    void updateCashBalance_vaultOutgoing_insufficientVaultStock_blocksBeforeCashMutation() {
        UUID branchId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch vaultBranch = Branch.builder()
                .id(branchId)
                .code("BR105")
                .company(company)
                .isVault(true)
                .vaultTerritoryId(1)
                .build();
        Currency eur = Currency.builder().id(978L).code("EUR").build();
        CashBalance balance = CashBalance.builder()
                .branch(vaultBranch)
                .currency(eur)
                .currentBalance(new BigDecimal("10000.00"))
                .build();

        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, 978L))
                .thenReturn(Optional.of(balance));
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(vaultBranch));
        when(currencyRepository.findById(978L)).thenReturn(Optional.of(eur));
        doThrow(new ValidationException("Nincs elegendő értéktári EUR készlet"))
                .when(vaultStockFlowService).validateVaultStockCoverage(vaultBranch, "EUR", new BigDecimal("5000.00"));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> helper.updateCashBalance(branchId, 978L, new BigDecimal("-5000.00"), false));

        assertTrue(ex.getMessage().contains("értéktári EUR készlet"), ex.getMessage());
        assertTrue(balance.getCurrentBalance().compareTo(new BigDecimal("10000.00")) == 0);
        verify(cashBalanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-053: helper.updateCashBalance vault-kimenő fedezettel cash_balance-t és currency_stock mirrort csökkent")
    void updateCashBalance_vaultOutgoing_withCoverage_updatesCashAndVaultMirror() {
        UUID branchId = UUID.randomUUID();
        Company company = Company.builder().id(UUID.randomUUID()).build();
        Branch vaultBranch = Branch.builder()
                .id(branchId)
                .code("BR105")
                .company(company)
                .isVault(true)
                .vaultTerritoryId(1)
                .build();
        Currency eur = Currency.builder().id(978L).code("EUR").build();
        CashBalance balance = CashBalance.builder()
                .branch(vaultBranch)
                .currency(eur)
                .currentBalance(new BigDecimal("10000.00"))
                .build();

        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(branchId, 978L))
                .thenReturn(Optional.of(balance));
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(vaultBranch));
        when(currencyRepository.findById(978L)).thenReturn(Optional.of(eur));

        helper.updateCashBalance(branchId, 978L, new BigDecimal("-5000.00"), false);

        assertTrue(balance.getCurrentBalance().compareTo(new BigDecimal("5000.00")) == 0);
        verify(cashBalanceRepository).save(balance);
        verify(vaultStockFlowService).validateVaultStockCoverage(vaultBranch, "EUR", new BigDecimal("5000.00"));
        verify(vaultStockFlowService).applyGenericVaultStock(vaultBranch, "EUR", new BigDecimal("5000.00"), false);
    }
}
