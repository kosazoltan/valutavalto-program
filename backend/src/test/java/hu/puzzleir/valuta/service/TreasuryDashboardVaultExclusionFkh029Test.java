package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.treasury.TreasuryDashboardDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.repository.BranchGroupRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.DailyReportRepository;
import hu.puzzleir.valuta.repository.InventoryMovementRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * FKH-029 FR-6: a Treasury dashboard PÉNZTÁRI valuta-összesítője ne tartalmazza az
 * értéktári és a counterparty-branch-ek {@code cash_balance} egyenlegét.
 *
 * <p><b>Miért most:</b> az FKH-029 V371 migráció mind a 8 aktív Értéktárnak létrehozza a
 * 23-23 (nulla) {@code cash_balance} sorát. A {@code getCompanyWideSummary} eddig
 * {@code findByCompanyId}-val, szűrés NÉLKÜL aggregált — így az Értéktárak bekerülnének a
 * pénztári összesítőbe, és a {@code branchCount} is őket számolta. Ez a FK-036
 * („66 helyett 65 pénztár") hibaosztály ismétlődése lenne.</p>
 *
 * <p><b>A counterparty-kizárás azért kell az {@code isVault} MELLÉ</b>, mert a
 * {@code VAULT_COUNTERPARTY} típusú branch-ek (MNB, bankok, Úton lévő pénztár,
 * Többlet/Hiány) {@code is_vault=FALSE} értékűek — FK-058 tanulság.</p>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class TreasuryDashboardVaultExclusionFkh029Test {

    @Mock private DailyReportRepository dailyReportRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private InventoryMovementRepository movementRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private BranchGroupRepository branchGroupRepository;
    @Mock private TransactionRepository transactionRepository;

    private TreasuryDashboardService service;

    private final UUID companyId = UUID.randomUUID();

    private static final Currency EUR = Currency.builder().id(4L).code("EUR").name("Euró").build();

    @BeforeEach
    void setUp() {
        service = new TreasuryDashboardService(
                dailyReportRepository, cashBalanceRepository, movementRepository,
                branchRepository, branchGroupRepository, transactionRepository);
        when(dailyReportRepository.findByCompanyIdAndReportDate(companyId, LocalDate.now()))
                .thenReturn(List.of());
    }

    /** Pénztár: is_vault=FALSE, nem counterparty → BENNE van az összesítőben. */
    private static Branch cashier(String code) {
        return Branch.builder().id(UUID.randomUUID()).code(code).isVault(false).isActive(true)
                .branchType(Dictionary.builder().id(UUID.randomUUID()).code("PENZTAR").build())
                .build();
    }

    /** Értéktár: is_vault=TRUE (a V371 után van cash_balance sora) → KIZÁRVA. */
    private static Branch vault(String code) {
        return Branch.builder().id(UUID.randomUUID()).code(code).isVault(true).isActive(true)
                .vaultTerritoryId(2)
                .branchType(Dictionary.builder().id(UUID.randomUUID()).code("PENZTAR").build())
                .build();
    }

    /** Counterparty: is_vault=FALSE, de VAULT_COUNTERPARTY típus → KIZÁRVA. */
    private static Branch counterparty(String code) {
        return Branch.builder().id(UUID.randomUUID()).code(code).isVault(false).isActive(true)
                .branchType(Dictionary.builder().id(UUID.randomUUID()).code("VAULT_COUNTERPARTY").build())
                .build();
    }

    private static CashBalance balance(Branch branch, String amount) {
        return CashBalance.builder()
                .branch(branch)
                .currency(EUR)
                .currentBalance(new BigDecimal(amount))
                .openingBalance(BigDecimal.ZERO)
                .build();
    }

    @Test
    @DisplayName("FR-6: az értéktári és counterparty egyenleg NEM kerül a pénztári valuta-összesítőbe (csak a pénztári 1000 EUR)")
    void vaultAndCounterpartyBalances_excludedFromCurrencyTotals() {
        Branch cashier = cashier("BR035");
        Branch vault = vault("BR075");
        Branch counterparty = counterparty("MNB");

        when(cashBalanceRepository.findByCompanyId(companyId)).thenReturn(List.of(
                balance(cashier, "1000"),
                balance(vault, "500000"),        // értéktári — nem pénztári készlet
                balance(counterparty, "9999")    // counterparty — is_vault=FALSE, mégis kizárt
        ));
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId))
                .thenReturn(List.of(cashier, vault));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            TreasuryDashboardDto dto = service.getCompanyWideSummary();

            assertThat(dto.getCurrencyTotals()).containsKey("EUR");
            assertThat(dto.getCurrencyTotals().get("EUR").getTotalStock())
                    .as("Kizárólag a pénztári 1000 EUR számít bele (az értéktári 500 000 és a "
                            + "counterparty 9 999 kizárva)")
                    .isEqualByComparingTo("1000");
        }
    }

    @Test
    @DisplayName("FR-6: a branchCount csak a pénztárakat számolja — az Értéktár és a counterparty nem (FK-036 hibaosztály)")
    void branchCount_countsOnlyCashierBranches() {
        Branch cashierA = cashier("BR035");
        Branch cashierB = cashier("BR076");
        Branch vault = vault("BR075");

        when(cashBalanceRepository.findByCompanyId(companyId)).thenReturn(List.of());
        // A repo-metódus a counterparty-kat MÁR kiszűri (FK-058); az isVault szűrés a service-ben.
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId))
                .thenReturn(List.of(cashierA, cashierB, vault));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            TreasuryDashboardDto dto = service.getCompanyWideSummary();

            assertThat(dto.getBranchCount())
                    .as("2 pénztár + 1 Értéktár → a pénztár-szám 2 (nem 3)")
                    .isEqualTo(2);
        }
    }

    @Test
    @DisplayName("FR-6: null branchType és null branch nem okoz NPE-t (null-safe szűrő)")
    void nullSafeFiltering() {
        Branch noType = Branch.builder().id(UUID.randomUUID()).code("BR999")
                .isVault(false).isActive(true).branchType(null).build();

        when(cashBalanceRepository.findByCompanyId(companyId)).thenReturn(List.of(
                balance(noType, "250"),
                balance(null, "777")             // hiányzó branch — védekezően kizárva
        ));
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId))
                .thenReturn(List.of(noType));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            TreasuryDashboardDto dto = service.getCompanyWideSummary();

            assertThat(dto.getCurrencyTotals().get("EUR").getTotalStock())
                    .as("A branchType nélküli pénztár beleszámít; a branch nélküli sor kizárva")
                    .isEqualByComparingTo("250");
        }
    }
}
