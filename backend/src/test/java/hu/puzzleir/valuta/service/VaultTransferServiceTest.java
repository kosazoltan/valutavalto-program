package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.entity.VaultTransfer;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import hu.puzzleir.valuta.repository.VaultTransferRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VaultTransferServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final Integer SOURCE_TERRITORY_ID = 1;
    private static final Integer TARGET_TERRITORY_ID = 2;

    @Mock
    private VaultTransferRepository vaultTransferRepository;
    @Mock
    private CurrencyStockRepository currencyStockRepository;
    @Mock
    private VaultTerritoryRepository vaultTerritoryRepository;
    @Mock
    private VaultStockFlowService vaultStockFlowService;

    @InjectMocks
    private VaultTransferService service;

    private MockedStatic<SecurityUtils> securityUtilsMock;
    private Company company;
    private VaultTerritory sourceTerritory;
    private VaultTerritory targetTerritory;

    @BeforeEach
    void setUp() {
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        securityUtilsMock.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);

        company = Company.builder().id(COMPANY_ID).build();
        sourceTerritory = VaultTerritory.builder().id(SOURCE_TERRITORY_ID).company(company).active(Boolean.TRUE).build();
        targetTerritory = VaultTerritory.builder().id(TARGET_TERRITORY_ID).company(company).active(Boolean.TRUE).build();
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) {
            securityUtilsMock.close();
        }
    }

    @Test
    @DisplayName("FK-054: completeTransfer elégtelen forrás vault-készletnél ValidationException, nincs státuszváltás")
    void completeTransfer_insufficientSourceVaultStock_throwsValidation_keepsTransferRequested() {
        VaultTransfer transfer = transfer(VaultOperationStatus.REQUESTED, new BigDecimal("500.00"));
        CurrencyStock sourceStock = stock(SOURCE_TERRITORY_ID.toString(), "EUR", new BigDecimal("100.00"));

        when(vaultTransferRepository.findById(10L)).thenReturn(Optional.of(transfer));
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", SOURCE_TERRITORY_ID.toString(), "EUR"))
                .thenReturn(Optional.of(sourceStock));

        assertThatThrownBy(() -> service.completeTransfer(10L))
                .isInstanceOf(ValidationException.class)
                .hasMessage("Nincs elegendő értéktári EUR készlet! Elérhető: 100.00, szükséges: 500.00 "
                        + "(territory: 1). A művelet nem hajtható végre — készleten túli forgalmazás tiltva.");

        assertThat(sourceStock.getQuantity()).isEqualByComparingTo("100.00");
        assertThat(transfer.getStatus()).isEqualTo(VaultOperationStatus.REQUESTED);
        verify(vaultTransferRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-054: completeTransfer elegendő forráskészlettel forrást csökkent, célt növel és COMPLETED státuszt állít")
    void completeTransfer_sufficientSourceVaultStock_completesAndMovesStock() {
        VaultTransfer transfer = transfer(VaultOperationStatus.REQUESTED, new BigDecimal("200.00"));
        CurrencyStock sourceStock = stock(SOURCE_TERRITORY_ID.toString(), "EUR", new BigDecimal("500.00"));
        CurrencyStock targetStock = stock(TARGET_TERRITORY_ID.toString(), "EUR", BigDecimal.ZERO);

        when(vaultTransferRepository.findById(10L)).thenReturn(Optional.of(transfer));
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", SOURCE_TERRITORY_ID.toString(), "EUR"))
                .thenReturn(Optional.of(sourceStock));
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TARGET_TERRITORY_ID.toString(), "EUR"))
                .thenReturn(Optional.of(targetStock));
        when(vaultTransferRepository.save(any(VaultTransfer.class))).thenAnswer(inv -> inv.getArgument(0));

        service.completeTransfer(10L);

        assertThat(sourceStock.getQuantity()).isEqualByComparingTo("300.00");
        assertThat(targetStock.getQuantity()).isEqualByComparingTo("200.00");
        assertThat(transfer.getStatus()).isEqualTo(VaultOperationStatus.COMPLETED);
        assertThat(transfer.getWacAtTransfer()).isEqualByComparingTo("395.5000");
    }

    private VaultTransfer transfer(VaultOperationStatus status, BigDecimal amount) {
        return VaultTransfer.builder()
                .id(10L)
                .companyId(COMPANY_ID)
                .transferNumber("VT-20260703-0001")
                .sourceVault(sourceTerritory)
                .targetVault(targetTerritory)
                .currencyCode("EUR")
                .amount(amount)
                .requiresSupervisor(false)
                .status(status)
                .createdAt(LocalDateTime.now())
                .build();
    }

    private CurrencyStock stock(String entityId, String currencyCode, BigDecimal quantity) {
        return CurrencyStock.builder()
                .company(company)
                .entityType("VAULT")
                .entityId(entityId)
                .currencyCode(currencyCode)
                .quantity(quantity)
                .weightedAvgCost(new BigDecimal("395.5000"))
                .build();
    }
}
