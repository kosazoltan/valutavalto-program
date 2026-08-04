package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ertektar.MaterialReceiptResponseDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.MaterialReceipt;
import hu.puzzleir.valuta.entity.MaterialReceiptLine;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.MaterialReceiptRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-029 FR-4: a {@code CASHIER} típusú {@code currency_stock} sor {@code entity_id}-ja a
 * branch UUID-ja legyen, ne a fiókkód.
 *
 * <p><b>A hiba (kód-feltérképezés 2026-08-04):</b> a {@code MaterialReceiptService} ÍRÓ oldala
 * {@code receipt.getBranchCode()}-ot ("BR035") tett az {@code entity_id}-ba, míg MINDEN olvasó
 * a branch UUID-ját keresi:
 * <ul>
 *   <li>{@code DailyBalanceService:222} — {@code branchId.toString()}</li>
 *   <li>{@code MonthlyClosingService:119} — {@code branchId.toString()}</li>
 *   <li>{@code CurrencyStockRepository.findByBranchIdAndCurrencyCode / findAllByBranchIds} — UUID</li>
 * </ul>
 * Következmény: az így írt sor SOHA nem olvasható vissza (árva sor). A {@code VAULT} ág
 * helyesen {@code vaultTerritoryId.toString()}-et használ, tehát a hiba a CASHIER íráson volt.
 *
 * <p><b>Latens:</b> élesben a {@code material_receipt} tábla 0 sor, ezért a hiba még nem
 * materializálódott — az első éles bizonylat előtt javítva.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class MaterialReceiptCashierEntityIdFkh029Test {

    @Mock private MaterialReceiptRepository materialReceiptRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;
    @Mock private VaultTerritoryRepository vaultTerritoryRepository;
    @Mock private BranchRepository branchRepository;

    private MaterialReceiptService service;

    private final UUID companyId = UUID.randomUUID();
    private final UUID branchUuid = UUID.randomUUID();
    private static final String BRANCH_CODE = "BR035";

    @BeforeEach
    void setUp() {
        service = new MaterialReceiptService(materialReceiptRepository, currencyStockRepository,
                vaultTerritoryRepository, branchRepository);
    }

    private MaterialReceipt draftCashierReceipt() {
        MaterialReceiptLine line = MaterialReceiptLine.builder()
                .currencyCode("EUR")
                .amount(new BigDecimal("1000"))
                .exchangeRate(new BigDecimal("389.5000"))
                .build();
        List<MaterialReceiptLine> lines = new ArrayList<>();
        lines.add(line);
        return MaterialReceipt.builder()
                .id(1L)
                .companyId(companyId)
                .receiptNumber("BEV-20260804-0001")
                .receiptType("B")
                .status("DRAFT")
                .branchCode(BRANCH_CODE)   // pénztári (CASHIER) cél — vaultTerritory NINCS
                .vaultTerritory(null)
                .lines(lines)
                .build();
    }

    @Test
    @DisplayName("FR-4: a CASHIER currency_stock sor entity_id-ja a branch UUID-ja (nem a 'BR035' fiókkód)")
    void cashierReceipt_writesBranchUuidAsEntityId() {
        MaterialReceipt receipt = draftCashierReceipt();
        Branch branch = Branch.builder().id(branchUuid).code(BRANCH_CODE).build();

        when(materialReceiptRepository.findById(1L)).thenReturn(Optional.of(receipt));
        when(materialReceiptRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(branchRepository.findByCompanyIdAndCode(companyId, BRANCH_CODE))
                .thenReturn(Optional.of(branch));
        // A sor még nem létezik → a service létrehozza (getOrCreateStock).
        when(currencyStockRepository.findForUpdate(eq(companyId), eq("CASHIER"), any(), eq("EUR")))
                .thenReturn(Optional.empty());
        when(currencyStockRepository.save(any(CurrencyStock.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            MaterialReceiptResponseDto dto = service.finalizeReceipt(1L);
            assertThat(dto).isNotNull();
        }

        ArgumentCaptor<CurrencyStock> captor = ArgumentCaptor.forClass(CurrencyStock.class);
        verify(currencyStockRepository).save(captor.capture());

        assertThat(captor.getValue().getEntityType()).isEqualTo("CASHIER");
        assertThat(captor.getValue().getEntityId())
                .as("Az entity_id a branch UUID-ja — különben a UUID-alapú olvasók soha nem "
                        + "találják meg a sort (árva sor)")
                .isEqualTo(branchUuid.toString())
                .isNotEqualTo(BRANCH_CODE);
    }

    @Test
    @DisplayName("FR-4: a UUID-alapú olvasó (findByBranchIdAndCurrencyCode kulcsa) megtalálja a frissen írt sort")
    void writtenRow_isFoundByUuidBasedReader() {
        MaterialReceipt receipt = draftCashierReceipt();
        Branch branch = Branch.builder().id(branchUuid).code(BRANCH_CODE).build();

        when(materialReceiptRepository.findById(1L)).thenReturn(Optional.of(receipt));
        when(materialReceiptRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        when(branchRepository.findByCompanyIdAndCode(companyId, BRANCH_CODE))
                .thenReturn(Optional.of(branch));
        when(currencyStockRepository.findForUpdate(eq(companyId), eq("CASHIER"), any(), eq("EUR")))
                .thenReturn(Optional.empty());
        when(currencyStockRepository.save(any(CurrencyStock.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            service.finalizeReceipt(1L);
        }

        // A DailyBalanceService / MonthlyClosingService pontosan ezzel a kulccsal keres:
        verify(currencyStockRepository).findForUpdate(companyId, "CASHIER", branchUuid.toString(), "EUR");
    }

    @Test
    @DisplayName("FR-4 fail-closed: nem létező fiókkódra ResourceNotFoundException — nem keletkezik árva sor")
    void unknownBranchCode_failsClosed() {
        MaterialReceipt receipt = draftCashierReceipt();

        when(materialReceiptRepository.findById(1L)).thenReturn(Optional.of(receipt));
        when(branchRepository.findByCompanyIdAndCode(companyId, BRANCH_CODE))
                .thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service.finalizeReceipt(1L))
                    .as("Ismeretlen fiókkód nem hozhat létre olvashatatlan currency_stock sort")
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining(BRANCH_CODE);
        }

        verify(currencyStockRepository, org.mockito.Mockito.never()).save(any(CurrencyStock.class));
    }
}
