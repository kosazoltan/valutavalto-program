package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.MaterialReceipt;
import hu.puzzleir.valuta.entity.MaterialReceiptLine;
import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.MaterialReceiptRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
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
class MaterialReceiptServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final Integer TERRITORY_ID = 1;
    private static final String TERRITORY_ENTITY_ID = TERRITORY_ID.toString();

    @Mock
    private MaterialReceiptRepository materialReceiptRepository;
    @Mock
    private CurrencyStockRepository currencyStockRepository;
    @Mock
    private VaultTerritoryRepository vaultTerritoryRepository;

    @InjectMocks
    private MaterialReceiptService service;

    private MockedStatic<SecurityUtils> securityUtilsMock;
    private Company company;
    private VaultTerritory territory;

    @BeforeEach
    void setUp() {
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

        company = Company.builder().id(COMPANY_ID).build();
        territory = VaultTerritory.builder().id(TERRITORY_ID).company(company).active(Boolean.TRUE).build();
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) {
            securityUtilsMock.close();
        }
    }

    @Test
    @DisplayName("FK-054: K típusú material receipt elégtelen vault-készletnél ValidationException, nincs véglegesítés")
    void finalizeReceipt_issue_insufficientVaultStock_throwsValidation_keepsDraftAndStockUnchanged() {
        MaterialReceipt receipt = draftReceipt("K", new BigDecimal("250.00"));
        CurrencyStock stock = CurrencyStock.builder()
                .company(company)
                .entityType("VAULT")
                .entityId(TERRITORY_ENTITY_ID)
                .currencyCode("EUR")
                .quantity(new BigDecimal("100.00"))
                .weightedAvgCost(new BigDecimal("395.5000"))
                .build();

        when(materialReceiptRepository.findById(10L)).thenReturn(Optional.of(receipt));
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ENTITY_ID, "EUR"))
                .thenReturn(Optional.of(stock));

        assertThatThrownBy(() -> service.finalizeReceipt(10L))
                .isInstanceOf(ValidationException.class)
                .hasMessage("Nincs elegendő értéktári EUR készlet! Elérhető: 100.00, szükséges: 250.00 "
                        + "(territory: 1). A művelet nem hajtható végre — készleten túli forgalmazás tiltva.");

        assertThat(stock.getQuantity()).isEqualByComparingTo("100.00");
        assertThat(receipt.getStatus()).isEqualTo("DRAFT");
        verify(materialReceiptRepository, never()).save(any());
    }

    @Test
    @DisplayName("FK-054: K típusú material receipt elegendő készlettel véglegesít és csökkenti a vault-készletet")
    void finalizeReceipt_issue_sufficientVaultStock_finalizesAndIssuesStock() {
        MaterialReceipt receipt = draftReceipt("K", new BigDecimal("125.00"));
        CurrencyStock stock = CurrencyStock.builder()
                .company(company)
                .entityType("VAULT")
                .entityId(TERRITORY_ENTITY_ID)
                .currencyCode("EUR")
                .quantity(new BigDecimal("500.00"))
                .weightedAvgCost(new BigDecimal("395.5000"))
                .build();

        when(materialReceiptRepository.findById(10L)).thenReturn(Optional.of(receipt));
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ENTITY_ID, "EUR"))
                .thenReturn(Optional.of(stock));
        when(materialReceiptRepository.save(any(MaterialReceipt.class))).thenAnswer(inv -> inv.getArgument(0));

        service.finalizeReceipt(10L);

        assertThat(stock.getQuantity()).isEqualByComparingTo("375.00");
        assertThat(receipt.getStatus()).isEqualTo("FINALIZED");
        assertThat(receipt.getFinalizedAt()).isNotNull();
    }

    private MaterialReceipt draftReceipt(String receiptType, BigDecimal amount) {
        MaterialReceipt receipt = MaterialReceipt.builder()
                .id(10L)
                .companyId(COMPANY_ID)
                .receiptNumber("KIA-20260703-0001")
                .receiptType(receiptType)
                .vaultTerritory(territory)
                .status("DRAFT")
                .createdAt(LocalDateTime.now())
                .build();
        MaterialReceiptLine line = MaterialReceiptLine.builder()
                .receipt(receipt)
                .currencyCode("EUR")
                .amount(amount)
                .exchangeRate(new BigDecimal("395.5000"))
                .build();
        receipt.getLines().add(line);
        return receipt;
    }
}
