package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK (Értéktár Shipment készletkönyvelés) — a könyvelő MOTOR egységtesztjei.
 *
 * <p>Tesztelési stratégia (tautológia-tilalom): a készlet-matematikát NEM másoljuk inline a tesztbe,
 * hanem VALÓS {@link CurrencyStock} / {@link CashBalance} entitásokat adunk a service-nek, és a service
 * lefuttatása UTÁN a valós entitás állapotát ellenőrizzük (a mutációt a prod-entitás {@code issueStock}/
 * {@code receiveStock}/{@code addBalance} metódusai végzik). Csak a repository-k és az audit mockolt.</p>
 */
@ExtendWith(MockitoExtension.class)
class ShipmentStockBookingServiceTest {

    @Mock
    private BranchRepository branchRepository;
    @Mock
    private CashBalanceRepository cashBalanceRepository;
    @Mock
    private CurrencyStockRepository currencyStockRepository;
    @Mock
    private CurrencyRepository currencyRepository;
    @Mock
    private AuditLogService auditLogService;

    @InjectMocks
    private ShipmentStockBookingService service;

    // ===================== transfer_type derivation (tiszta függvény) =====================

    @Test
    void deriveTransferType_mapsVaultFlagsToConstants() {
        Branch vault = Branch.builder().isVault(true).build();
        Branch cashier = Branch.builder().isVault(false).build();

        assertThat(service.deriveTransferType(vault, cashier))
                .isEqualTo(ShipmentStockBookingService.TRANSFER_VAULT_TO_BRANCH);
        assertThat(service.deriveTransferType(cashier, vault))
                .isEqualTo(ShipmentStockBookingService.TRANSFER_BRANCH_TO_VAULT);
        assertThat(service.deriveTransferType(cashier, cashier))
                .isEqualTo(ShipmentStockBookingService.TRANSFER_BRANCH_TO_BRANCH);
        assertThat(service.deriveTransferType(vault, vault))
                .isEqualTo(ShipmentStockBookingService.TRANSFER_VAULT_TO_VAULT);
    }

    // ===================== bookStockOut (átadó OUT) =====================

    @Test
    void bookStockOut_vaultSide_decreasesCurrencyStock() {
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = vaultBranch(fromId, companyId, 7);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "300", null));
        CurrencyStock stock = vaultStock(companyId, "7", "EUR", "1000", "380");

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "7", "EUR"))
                .thenReturn(Optional.of(stock));
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockOut(req, companyId);
        }

        // 1000 − 300 = 700 (valós entitás mutáció a service-en keresztül)
        assertThat(stock.getQuantity()).isEqualByComparingTo("700");
    }

    @Test
    void bookStockOut_cashierSide_decreasesCashBalance() {
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = cashierBranch(fromId, companyId);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "300", null));
        CashBalance balance = cashBalance("1000");

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(fromId, 4L))
                .thenReturn(Optional.of(balance));
        when(cashBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockOut(req, companyId);
        }

        assertThat(balance.getCurrentBalance()).isEqualByComparingTo("700");
    }

    @Test
    void bookStockOut_vaultInsufficient_throws422AndAudits() {
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = vaultBranch(fromId, companyId, 7);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "300", null));
        CurrencyStock stock = vaultStock(companyId, "7", "EUR", "100", "380"); // kevesebb mint 300

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "7", "EUR"))
                .thenReturn(Optional.of(stock));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            assertThatThrownBy(() -> service.bookStockOut(req, companyId))
                    .isInstanceOf(BusinessException.class)
                    .extracting(ex -> ((BusinessException) ex).getErrorCode())
                    .isEqualTo(ShipmentStockBookingService.ERR_INSUFFICIENT);
        }

        // a készlet NEM csökkent (rollback-szerű: a mutáció előtt dobott)
        assertThat(stock.getQuantity()).isEqualByComparingTo("100");
        verify(auditLogService).logInNewTransaction(
                eq(ShipmentStockBookingService.ACTION_STOCK_INSUFFICIENT),
                any(), any(), any(), any(), any(), any(), any());
        verify(currencyStockRepository, never()).save(any());
    }

    @Test
    void bookStockOut_cashierInsufficient_throws422() {
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = cashierBranch(fromId, companyId);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "300", null));
        CashBalance balance = cashBalance("100"); // kevesebb mint 300

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(fromId, 4L))
                .thenReturn(Optional.of(balance));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            assertThatThrownBy(() -> service.bookStockOut(req, companyId))
                    .isInstanceOf(BusinessException.class)
                    .extracting(ex -> ((BusinessException) ex).getErrorCode())
                    .isEqualTo(ShipmentStockBookingService.ERR_INSUFFICIENT);
        }

        assertThat(balance.getCurrentBalance()).isEqualByComparingTo("100");
        verify(cashBalanceRepository, never()).save(any());
    }

    // ===================== bookStockIn (átvevő IN) =====================

    @Test
    void bookStockIn_vaultSide_increasesCurrencyStock() {
        UUID companyId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Branch to = vaultBranch(toId, companyId, 9);
        ShipmentRequest req = shipment(UUID.randomUUID(), toId, item(4L, "300", null));
        CurrencyStock stock = vaultStock(companyId, "9", "EUR", "500", "380");

        when(branchRepository.findByIdAndCompanyId(toId, companyId)).thenReturn(Optional.of(to));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "9", "EUR"))
                .thenReturn(Optional.of(stock));
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockIn(req, companyId);
        }

        assertThat(stock.getQuantity()).isEqualByComparingTo("800");
    }

    @Test
    void bookStockIn_cashierSide_increasesCashBalance() {
        UUID companyId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Branch to = cashierBranch(toId, companyId);
        ShipmentRequest req = shipment(UUID.randomUUID(), toId, item(4L, "300", null));
        CashBalance balance = cashBalance("500");

        when(branchRepository.findByIdAndCompanyId(toId, companyId)).thenReturn(Optional.of(to));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(toId, 4L))
                .thenReturn(Optional.of(balance));
        when(cashBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockIn(req, companyId);
        }

        assertThat(balance.getCurrentBalance()).isEqualByComparingTo("800");
    }

    // ===================== assertReceiver (FR-4 átvevő-gate) =====================

    @Test
    void assertReceiver_allowsReceiverBranch() {
        UUID toId = UUID.randomUUID();
        ShipmentRequest req = shipment(UUID.randomUUID(), toId, item(4L, "300", null));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(toId);
            assertThatCode(() -> service.assertReceiver(req)).doesNotThrowAnyException();
        }
        verify(auditLogService, never()).logInNewTransaction(
                any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void assertReceiver_deniesNonReceiverBranch_403AndAudit() {
        UUID toId = UUID.randomUUID();
        UUID otherBranch = UUID.randomUUID();
        ShipmentRequest req = shipment(UUID.randomUUID(), toId, item(4L, "300", null));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(otherBranch);
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            assertThatThrownBy(() -> service.assertReceiver(req))
                    .isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining(ShipmentStockBookingService.ERR_NOT_RECEIVER);
        }
        verify(auditLogService).logInNewTransaction(
                eq(ShipmentStockBookingService.ACTION_ACCESS_DENIED),
                any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void assertReceiver_deniesWhenNoBranchContext_403() {
        UUID toId = UUID.randomUUID();
        ShipmentRequest req = shipment(UUID.randomUUID(), toId, item(4L, "300", null));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentBranchIdOrNull).thenReturn(null);
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            assertThatThrownBy(() -> service.assertReceiver(req))
                    .isInstanceOf(AccessDeniedException.class)
                    .hasMessageContaining(ShipmentStockBookingService.ERR_NOT_RECEIVER);
        }
    }

    // ===================== reverseStockOut (TBD-1 reverzió) =====================

    @Test
    void reverseStockOut_vaultSide_restoresStock() {
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = vaultBranch(fromId, companyId, 7);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "300", null));
        CurrencyStock stock = vaultStock(companyId, "7", "EUR", "700", "380");

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "7", "EUR"))
                .thenReturn(Optional.of(stock));
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.reverseStockOut(req, companyId);
        }

        // a beküldéskor levont 300 visszakerül: 700 + 300 = 1000
        assertThat(stock.getQuantity()).isEqualByComparingTo("1000");
        verify(auditLogService).log(
                eq(ShipmentStockBookingService.ACTION_STOCK_REVERSAL),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    // ===================== AML-flag (NFR-6) =====================

    @Test
    void bookStockOut_aboveAmlThreshold_writesAmlAudit() {
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = vaultBranch(fromId, companyId, 7);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "300", "150000"));
        CurrencyStock stock = vaultStock(companyId, "7", "EUR", "1000", "380");

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "7", "EUR"))
                .thenReturn(Optional.of(stock));
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockOut(req, companyId);
        }

        verify(auditLogService).log(
                eq(ShipmentStockBookingService.ACTION_AML_CHECK),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void bookStockOut_belowAmlThreshold_noAmlAudit() {
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = vaultBranch(fromId, companyId, 7);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "300", "50000"));
        CurrencyStock stock = vaultStock(companyId, "7", "EUR", "1000", "380");

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "7", "EUR"))
                .thenReturn(Optional.of(stock));
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockOut(req, companyId);
        }

        verify(auditLogService, never()).log(
                eq(ShipmentStockBookingService.ACTION_AML_CHECK),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    // ===================== #3 cross-tenant izoláció (VV-TENANT-001 spirit) =====================

    @Test
    void bookStockOut_crossTenantBranch_throwsAndDoesNotBook() {
        // A loadBranch findByIdAndCompanyId-t használ: ha az átadó branch NEM a hívó tenantjához
        // tartozik, üres Optional → ResourceNotFoundException, és SEMMI készlet-mutáció nem fut.
        UUID companyId = UUID.randomUUID();
        UUID foreignBranchId = UUID.randomUUID();
        ShipmentRequest req = shipment(foreignBranchId, UUID.randomUUID(), item(4L, "300", null));

        when(branchRepository.findByIdAndCompanyId(foreignBranchId, companyId))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.bookStockOut(req, companyId))
                .isInstanceOf(BusinessException.class)
                .extracting(ex -> ((BusinessException) ex).getErrorCode())
                .isEqualTo(ShipmentStockBookingService.ERR_CROSS_TENANT); // VV-TENANT-001
        // tenant-szivárgás elleni bizonyíték: idegen tenant készletét meg sem érintettük
        verify(currencyStockRepository, never()).findForUpdate(any(), any(), any(), any());
        verify(currencyStockRepository, never()).save(any());
        verify(cashBalanceRepository, never()).save(any());
    }

    // ===================== #4 pesszimista zárolás: a service a LOCKOLT repo-metódust hívja =====================

    @Test
    void bookStockOut_vaultSide_usesPessimisticLockedFindForUpdate() {
        // FR-7/NFR-7: a készlet-csökkentés a @Lock(PESSIMISTIC_WRITE)-tal annotált findForUpdate-en
        // megy (nem a lock nélküli finderen) — ez bizonyítja a pesszimista zárolás útvonalát.
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = vaultBranch(fromId, companyId, 7);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "300", null));
        CurrencyStock stock = vaultStock(companyId, "7", "EUR", "1000", "380");

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "7", "EUR"))
                .thenReturn(Optional.of(stock));
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockOut(req, companyId);
        }
        verify(currencyStockRepository).findForUpdate(companyId, "VAULT", "7", "EUR");
    }

    @Test
    void bookStockOut_cashierSide_usesPessimisticLockedFindForUpdate() {
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = cashierBranch(fromId, companyId);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "300", null));
        CashBalance balance = cashBalance("1000");

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(fromId, 4L))
                .thenReturn(Optional.of(balance));
        when(cashBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockOut(req, companyId);
        }
        verify(cashBalanceRepository).findByBranchIdAndCurrencyIdForUpdate(fromId, 4L);
    }

    // ===================== #7 FR-9 audit-esemény minden készletmozgásra =====================

    @Test
    void bookStockOut_writesStockOutAuditWithTxCategory() {
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = vaultBranch(fromId, companyId, 7);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "300", null));
        CurrencyStock stock = vaultStock(companyId, "7", "EUR", "1000", "380");

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "7", "EUR"))
                .thenReturn(Optional.of(stock));
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockOut(req, companyId);
        }
        // FR-9: SHIPMENT_STOCK_OUT audit a normál (commitoló) log()-on, minden tételre.
        verify(auditLogService).log(
                eq(ShipmentStockBookingService.ACTION_STOCK_OUT),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    @Test
    void bookStockIn_writesStockInAudit() {
        UUID companyId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Branch to = cashierBranch(toId, companyId);
        ShipmentRequest req = shipment(UUID.randomUUID(), toId, item(4L, "300", null));
        CashBalance balance = cashBalance("500");

        when(branchRepository.findByIdAndCompanyId(toId, companyId)).thenReturn(Optional.of(to));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(toId, 4L))
                .thenReturn(Optional.of(balance));
        when(cashBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockIn(req, companyId);
        }
        verify(auditLogService).log(
                eq(ShipmentStockBookingService.ACTION_STOCK_IN),
                any(), any(), any(), any(), any(), any(), any(), any(), any());
    }

    // ===================== #7 FR-5 szimmetria: Pénztár→Értéktár teljes irány =====================

    @Test
    void symmetry_cashierOutThenVaultIn_bothSidesBooked() {
        // FR-5: Pénztár ÁTAD (cash_balance OUT) → Értéktár VESZ (currency_stock IN). A két oldalt
        // egyetlen teszt láncolja, hogy a teljes Pénztár→Értéktár szimmetria bizonyított legyen.
        UUID companyId = UUID.randomUUID();
        UUID cashierId = UUID.randomUUID();
        UUID vaultId = UUID.randomUUID();
        Branch cashier = cashierBranch(cashierId, companyId);
        Branch vault = vaultBranch(vaultId, companyId, 5);
        ShipmentRequest req = shipment(cashierId, vaultId, item(4L, "500", null));
        CashBalance cashierBalance = cashBalance("1200");
        CurrencyStock vaultStock = vaultStock(companyId, "5", "USD", "200", "360");

        when(branchRepository.findByIdAndCompanyId(cashierId, companyId)).thenReturn(Optional.of(cashier));
        when(branchRepository.findByIdAndCompanyId(vaultId, companyId)).thenReturn(Optional.of(vault));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("USD")));
        when(cashBalanceRepository.findByBranchIdAndCurrencyIdForUpdate(cashierId, 4L))
                .thenReturn(Optional.of(cashierBalance));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "5", "USD"))
                .thenReturn(Optional.of(vaultStock));
        when(cashBalanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockOut(req, companyId);   // Pénztár átad → cash_balance csökken
            service.bookStockIn(req, companyId);    // Értéktár vesz → currency_stock nő
        }
        assertThat(cashierBalance.getCurrentBalance()).isEqualByComparingTo("700"); // 1200 − 500
        assertThat(vaultStock.getQuantity()).isEqualByComparingTo("700");           // 200 + 500
    }

    // ===================== #2 WAC-szétválasztás: bevételezés vs sztornó =====================

    @Test
    void bookStockIn_freshVaultStock_usesShipmentUnitHufAsWac() {
        // Valódi átvevői bevételezés ÜRES vault-sorra: a WAC a szállítmány fajlagos HUF-értéke
        // (hufValue/mennyiség = 152000/400 = 380), NEM önkényes konstans és nem 0.
        UUID companyId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Branch to = vaultBranch(toId, companyId, 3);
        ShipmentRequest req = shipment(UUID.randomUUID(), toId, item(4L, "400", "152000"));
        CurrencyStock freshRow = vaultStock(companyId, "3", "EUR", "0", "0");

        when(branchRepository.findByIdAndCompanyId(toId, companyId)).thenReturn(Optional.of(to));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "3", "EUR"))
                .thenReturn(Optional.empty(), Optional.of(freshRow)); // friss garantált sor, WAC=0
        when(currencyStockRepository.insertIfAbsent(companyId, "VAULT", "3", "EUR"))
                .thenReturn(1);
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockIn(req, companyId);
        }

        verify(currencyStockRepository).insertIfAbsent(companyId, "VAULT", "3", "EUR");
        assertThat(freshRow.getQuantity()).isEqualByComparingTo("400");
        assertThat(freshRow.getWeightedAvgCost()).isEqualByComparingTo("380"); // 152000/400
        verify(currencyStockRepository).save(freshRow);
    }

    @Test
    void bookStockIn_concurrentInsertRace_refetchesLockedRowAndBooks() {
        // GLM-review #9 constraint-safe get-or-create: ha a sort egy párhuzamos szál már
        // beszúrta, az ON CONFLICT DO NOTHING no-op → a kód ÚJRA, FOR UPDATE zárral olvassa
        // a most már létező sort, és ARRA vételez (nincs elveszett írás / dupla sor).
        UUID companyId = UUID.randomUUID();
        UUID toId = UUID.randomUUID();
        Branch to = vaultBranch(toId, companyId, 3);
        ShipmentRequest req = shipment(UUID.randomUUID(), toId, item(4L, "400", "152000"));
        CurrencyStock raced = vaultStock(companyId, "3", "EUR", "1000", "380"); // a másik szál sora

        when(branchRepository.findByIdAndCompanyId(toId, companyId)).thenReturn(Optional.of(to));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        // 1. lookup: üres (még nincs sor) → friss buildet próbálunk; 2. lookup (a catch-ágban): a
        // párhuzamos szál által beszúrt sort kapjuk, lockoltan.
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "3", "EUR"))
                .thenReturn(Optional.empty())
                .thenReturn(Optional.of(raced));
        when(currencyStockRepository.insertIfAbsent(companyId, "VAULT", "3", "EUR"))
                .thenReturn(0);
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.bookStockIn(req, companyId);
        }

        // a meglévő (1000) sorra vételeztünk +400 → 1400, nincs új sor, nincs elveszett írás
        assertThat(raced.getQuantity()).isEqualByComparingTo("1400");
        verify(currencyStockRepository).insertIfAbsent(companyId, "VAULT", "3", "EUR");
        verify(currencyStockRepository, times(2)).findForUpdate(companyId, "VAULT", "3", "EUR");
        verify(currencyStockRepository).save(raced);
    }

    @Test
    void reverseStockOut_preservesExistingWac_notShipmentRate() {
        // Sztornó-reverzió MEGLÉVŐ WAC-os sorra: a meglévő WAC (380) megmarad, a tétel eltérő
        // fajlagos rátája (200000/500=400) NEM torzítja az elszámoló árat.
        UUID companyId = UUID.randomUUID();
        UUID fromId = UUID.randomUUID();
        Branch from = vaultBranch(fromId, companyId, 7);
        ShipmentRequest req = shipment(fromId, UUID.randomUUID(), item(4L, "500", "200000"));
        CurrencyStock stock = vaultStock(companyId, "7", "EUR", "1000", "380");

        when(branchRepository.findByIdAndCompanyId(fromId, companyId)).thenReturn(Optional.of(from));
        when(currencyRepository.findById(4L)).thenReturn(Optional.of(currency("EUR")));
        when(currencyStockRepository.findForUpdate(companyId, "VAULT", "7", "EUR"))
                .thenReturn(Optional.of(stock));
        when(currencyStockRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);
            service.reverseStockOut(req, companyId);
        }

        assertThat(stock.getQuantity()).isEqualByComparingTo("1500"); // 1000 + 500 visszapótolva
        assertThat(stock.getWeightedAvgCost()).isEqualByComparingTo("380"); // WAC változatlan
    }

    // ===================== fixtures =====================

    private static Branch vaultBranch(UUID id, UUID companyId, int territoryId) {
        return Branch.builder()
                .id(id)
                .company(Company.builder().id(companyId).build())
                .code("VLT" + territoryId)
                .name("Értéktár " + territoryId)
                .isVault(true)
                .vaultTerritoryId(territoryId)
                .build();
    }

    private static Branch cashierBranch(UUID id, UUID companyId) {
        return Branch.builder()
                .id(id)
                .company(Company.builder().id(companyId).build())
                .code("PNZ")
                .name("Pénztár fiók")
                .isVault(false)
                .build();
    }

    private static CurrencyStock vaultStock(UUID companyId, String entityId, String code,
                                            String quantity, String wac) {
        return CurrencyStock.builder()
                .company(Company.builder().id(companyId).build())
                .entityType("VAULT")
                .entityId(entityId)
                .currencyCode(code)
                .quantity(new BigDecimal(quantity))
                .weightedAvgCost(new BigDecimal(wac))
                .build();
    }

    private static CashBalance cashBalance(String current) {
        return CashBalance.builder()
                .currentBalance(new BigDecimal(current))
                .openingBalance(BigDecimal.ZERO)
                .build();
    }

    private static Currency currency(String code) {
        return Currency.builder().id(4L).code(code).build();
    }

    private static ShipmentRequestItem item(Long currencyId, String amount, String hufValue) {
        return ShipmentRequestItem.builder()
                .currencyId(currencyId)
                .requestedAmount(new BigDecimal(amount))
                .hufValue(hufValue != null ? new BigDecimal(hufValue) : null)
                .build();
    }

    private static ShipmentRequest shipment(UUID fromId, UUID toId, ShipmentRequestItem... items) {
        return ShipmentRequest.builder()
                .id(UUID.randomUUID())
                .requestNumber("AT-000001")
                .fromBranchId(fromId)
                .toBranchId(toId)
                .transferType("VAULT_TO_BRANCH")
                .items(new ArrayList<>(List.of(items)))
                .build();
    }
}
