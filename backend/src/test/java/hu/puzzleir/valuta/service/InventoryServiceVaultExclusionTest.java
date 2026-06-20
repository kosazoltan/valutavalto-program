package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.InventoryMovementRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * FK-036 (2026-06-20): a getAllStock() (Országos / pénztári cash_balance nézet) NEM adhat vissza
 * is_vault=TRUE branch sort. Gyökérok: a V247 a deaktivált KORUT pénztár egyenlegét tévesen BR020
 * (is_vault=TRUE) branch-be rakta; mivel BR020 NEM counterparty, a
 * findByCompanyIdAndIsActiveTrueExcludingCounterparties átengedi → a vault-sor beszivárgott a
 * válaszba (és a "X pénztár" számláló 65 helyett 66-ot mutatott). A fix az activeNonVaultBranch
 * predikátum a valódi cash_balance sorokra is.
 *
 * <p>A teszt SZÁNDÉKOSAN úgy állítja be, hogy a vault-branch BENNE van a counterparty-kizáró
 * lekérdezés eredményében (mint élesben) — így a régi (fix nélküli) kód átengedné a vault-sort, az
 * új viszont kizárja. Ez teszi a tesztet érdemivé (nem trivializálja a counterparty-szűrő).</p>
 */
@ExtendWith(MockitoExtension.class)
class InventoryServiceVaultExclusionTest {

    @Mock private InventoryMovementRepository movementRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private AuditLogRepository auditLogRepository;
    @Mock private ExchangeRateRepository exchangeRateRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;

    @InjectMocks private InventoryService inventoryService;

    @Test
    @DisplayName("FK-036: getAllStock kizárja az is_vault=TRUE branch valódi cash_balance sorát")
    void getAllStock_excludesVaultBranchRealRows() {
        UUID companyId = UUID.randomUUID();
        UUID normalBranchId = UUID.randomUUID();
        UUID vaultBranchId = UUID.randomUUID();

        Branch normalBranch = Branch.builder()
                .id(normalBranchId).name("BUD01 Pénztár").isVault(false).isActive(true).build();
        Branch vaultBranch = Branch.builder()
                .id(vaultBranchId).name("BR020 Szeged Értéktár").isVault(true).isActive(true).build();

        CashBalance cbNormal = CashBalance.builder()
                .id(1L).branch(normalBranch).currentBalance(new BigDecimal("100")).build();
        CashBalance cbVault = CashBalance.builder()
                .id(2L).branch(vaultBranch).currentBalance(new BigDecimal("200")).build();

        when(cashBalanceRepository.findByCompanyId(companyId)).thenReturn(List.of(cbNormal, cbVault));
        // Éles viselkedés: a vault-branch NEM counterparty → benne van a kizáró lekérdezésben.
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId))
                .thenReturn(List.of(normalBranch, vaultBranch));
        // Nincs aktív valuta → nincs szintetikus 0-sor (a tesztet a valódi sorok szűrésére fókuszáljuk).
        lenient().when(currencyRepository.findAllActiveOrdered()).thenReturn(List.of());

        try (MockedStatic<SecurityUtils> securityUtils = mockStatic(SecurityUtils.class)) {
            securityUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            List<CashBalance> result = inventoryService.getAllStock();

            assertTrue(
                    result.stream().noneMatch(cb -> Boolean.TRUE.equals(cb.getBranch().getIsVault())),
                    "is_vault=TRUE branch cash_balance sora NEM kerülhet az Országos készlet válaszába");
            assertEquals(1, result.size(), "csak a nem-vault pénztár valódi sora maradhat");
            assertEquals(normalBranchId, result.get(0).getBranch().getId());
        }
    }
}
