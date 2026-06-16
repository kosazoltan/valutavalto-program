package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.BankTransactionRequestDto;
import hu.puzzleir.valuta.dto.ertektar.BankTransactionResponseDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.VaultBankTransaction;
import hu.puzzleir.valuta.entity.VaultOperationStatus;
import hu.puzzleir.valuta.entity.VaultTerritory;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.VaultBankTransactionRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
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
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * F1 fix-batch (Tamas hianypotlo coverage) — VaultBankTransactionService.createBankTransaction
 * BUY/SELL flow unit-tesztek.
 *
 * Eredeti audit (Tamas F3): a `ba4eec1c` v2.2.2 hotfix uj `VaultStockFlowService` mediator-t
 * vezetett be a Collection/Distribution/Transfer flow-hoz, de a VaultBankTransactionService
 * NEM hivja ezt — kozvetlenul receiveStock/issueStock-ot hiv a CurrencyStock-on. Ez a teszt
 * azt verifikalja, hogy a HUF + foreign currency stock konzisztens ervenyu marad BUY+SELL flowban.
 *
 * Ez fedi le a "v2.2.2 elesi teszt 500-as hiba" root cause-at: ha vault HUF stock 0,
 * akkor BUY-nal IllegalStateException-be dőlt. A VaultTerritoryService.create v2.2.2 hotfix
 * (HUF auto-init) + V159 migration miatt ez nem fordulhat elo, de defense-in-depth ellenorzes.
 */
@ExtendWith(MockitoExtension.class)
class VaultBankTransactionServiceCreateTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final Integer TERRITORY_ID = 1;
    private static final String TERRITORY_ENTITY_ID = TERRITORY_ID.toString();

    @Mock
    private VaultBankTransactionRepository bankTransactionRepository;
    @Mock
    private CurrencyStockRepository currencyStockRepository;
    @Mock
    private VaultTerritoryRepository vaultTerritoryRepository;

    @InjectMocks
    private VaultBankTransactionService service;

    private MockedStatic<SecurityUtils> securityUtilsMock;
    private VaultTerritory territory;
    private Company company;

    @BeforeEach
    void setUp() {
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        securityUtilsMock.when(SecurityUtils::getCurrentWorkerId).thenReturn(42L);

        company = Company.builder().id(COMPANY_ID).build();
        territory = VaultTerritory.builder()
                .id(TERRITORY_ID).company(company).active(Boolean.TRUE)
                .baseCapital(new BigDecimal("10000000")).build();
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) securityUtilsMock.close();
    }

    private BankTransactionRequestDto buildRequest(String type, String code, BigDecimal amount, BigDecimal rate) {
        BankTransactionRequestDto r = new BankTransactionRequestDto();
        r.setTransactionType(type);
        r.setCurrencyCode(code);
        r.setAmount(amount);
        r.setExchangeRate(rate);
        r.setVaultTerritoryId(TERRITORY_ID);
        r.setBankName("Raiffeisen");
        return r;
    }

    @Test
    @DisplayName("createBankTransaction BUY: vault EUR stock += amount, vault HUF stock -= hufAmount")
    void createBankTransaction_BUY_creditsForeign_debitsHuf() {
        BankTransactionRequestDto req = buildRequest("BUY", "EUR", new BigDecimal("1000"), new BigDecimal("395.5"));

        // territory megvan + HUF stock van eleg
        when(vaultTerritoryRepository.findByIdAndCompanyId(TERRITORY_ID, COMPANY_ID)).thenReturn(Optional.of(territory));

        CurrencyStock eurStock = CurrencyStock.builder()
                .company(company).entityType("VAULT").entityId(TERRITORY_ENTITY_ID)
                .currencyCode("EUR").quantity(new BigDecimal("0"))
                .weightedAvgCost(new BigDecimal("0")).build();
        CurrencyStock hufStock = CurrencyStock.builder()
                .company(company).entityType("VAULT").entityId(TERRITORY_ENTITY_ID)
                .currencyCode("HUF").quantity(new BigDecimal("10000000"))
                .weightedAvgCost(BigDecimal.ONE).build();
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ENTITY_ID, "EUR"))
                .thenReturn(Optional.of(eurStock));
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ENTITY_ID, "HUF"))
                .thenReturn(Optional.of(hufStock));
        when(bankTransactionRepository.save(any(VaultBankTransaction.class))).thenAnswer(inv -> inv.getArgument(0));

        BankTransactionResponseDto result = service.createBankTransaction(req);

        assertThat(eurStock.getQuantity()).isEqualByComparingTo("1000"); // 0 + 1000
        assertThat(hufStock.getQuantity()).isEqualByComparingTo("9604500"); // 10_000_000 - 395_500
        assertThat(result.getStatus()).isEqualTo("COMPLETED");
        assertThat(result.getHufAmount()).isEqualByComparingTo("395500.00");
    }

    @Test
    @DisplayName("createBankTransaction SELL: vault EUR stock -= amount, vault HUF stock += hufAmount")
    void createBankTransaction_SELL_debitsForeign_creditsHuf() {
        BankTransactionRequestDto req = buildRequest("SELL", "EUR", new BigDecimal("500"), new BigDecimal("390.0"));

        when(vaultTerritoryRepository.findByIdAndCompanyId(TERRITORY_ID, COMPANY_ID)).thenReturn(Optional.of(territory));

        CurrencyStock eurStock = CurrencyStock.builder()
                .company(company).entityType("VAULT").entityId(TERRITORY_ENTITY_ID)
                .currencyCode("EUR").quantity(new BigDecimal("2000"))
                .weightedAvgCost(new BigDecimal("395.0")).build();
        CurrencyStock hufStock = CurrencyStock.builder()
                .company(company).entityType("VAULT").entityId(TERRITORY_ENTITY_ID)
                .currencyCode("HUF").quantity(new BigDecimal("0"))
                .weightedAvgCost(BigDecimal.ONE).build();
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ENTITY_ID, "EUR"))
                .thenReturn(Optional.of(eurStock));
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ENTITY_ID, "HUF"))
                .thenReturn(Optional.of(hufStock));
        when(bankTransactionRepository.save(any(VaultBankTransaction.class))).thenAnswer(inv -> inv.getArgument(0));

        BankTransactionResponseDto result = service.createBankTransaction(req);

        assertThat(eurStock.getQuantity()).isEqualByComparingTo("1500");
        assertThat(hufStock.getQuantity()).isEqualByComparingTo("195000.00");
        assertThat(result.getStatus()).isEqualTo("COMPLETED");
    }

    @Test
    @DisplayName("createBankTransaction territoryId nem letezik -> ResourceNotFoundException")
    void createBankTransaction_unknownTerritory_throws() {
        BankTransactionRequestDto req = buildRequest("BUY", "EUR", new BigDecimal("100"), new BigDecimal("395.5"));
        req.setVaultTerritoryId(9999);
        when(vaultTerritoryRepository.findByIdAndCompanyId(9999, COMPANY_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.createBankTransaction(req))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("9999");
    }

    @Test
    @DisplayName("createBankTransaction status COMPLETED + companyId helyesen beallitva (multi-tenant)")
    void createBankTransaction_setsCompanyIdAndStatus() {
        BankTransactionRequestDto req = buildRequest("BUY", "USD", new BigDecimal("100"), new BigDecimal("350"));
        when(vaultTerritoryRepository.findByIdAndCompanyId(TERRITORY_ID, COMPANY_ID)).thenReturn(Optional.of(territory));

        CurrencyStock usdStock = CurrencyStock.builder()
                .company(company).entityType("VAULT").entityId(TERRITORY_ENTITY_ID)
                .currencyCode("USD").quantity(new BigDecimal("0")).weightedAvgCost(new BigDecimal("0")).build();
        CurrencyStock hufStock = CurrencyStock.builder()
                .company(company).entityType("VAULT").entityId(TERRITORY_ENTITY_ID)
                .currencyCode("HUF").quantity(new BigDecimal("10000000")).weightedAvgCost(BigDecimal.ONE).build();
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ENTITY_ID, "USD"))
                .thenReturn(Optional.of(usdStock));
        when(currencyStockRepository.findForUpdate(COMPANY_ID, "VAULT", TERRITORY_ENTITY_ID, "HUF"))
                .thenReturn(Optional.of(hufStock));

        ArgumentCaptor<VaultBankTransaction> captor = ArgumentCaptor.forClass(VaultBankTransaction.class);
        when(bankTransactionRepository.save(captor.capture())).thenAnswer(inv -> inv.getArgument(0));

        service.createBankTransaction(req);

        VaultBankTransaction saved = captor.getValue();
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(saved.getStatus()).isEqualTo(VaultOperationStatus.COMPLETED);
        assertThat(saved.getCreatedBy()).isEqualTo(42L);
        verify(bankTransactionRepository, atLeastOnce()).save(any());
    }
}
