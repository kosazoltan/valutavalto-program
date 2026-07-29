package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ShipmentRequestRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-022 kiegészítés — 9. regressziós teszt (FR-K4, GREEN-köri kiegészítés):
 * a nyomtatvány telephely-címe ({@code branchAddress}) KIZÁRÓLAG a hívó tenant-re
 * szűrt branch-lekérdezésből ({@code findByIdAndCompanyId}) származhat.
 *
 * <p>Garancia-kontraktus: a cím forrása a {@code requireAccessibleBranch} által
 * betöltött Branch — tenant-szűrés NÉLKÜLI útvonal ({@code findById}) a cím
 * feloldására nem hívódhat. Szándékosan Mockito-unit (a FrK12 mintájára), hogy
 * ezen a gépen (Docker nélkül) is futtatva bizonyítható legyen.</p>
 */
@ExtendWith(MockitoExtension.class)
class HufDaybookBranchAddressTenantScopeFrK4Test {

    private static final LocalDate DAY = LocalDate.of(2026, 7, 1);
    private static final String OWN_ADDRESS = "6720 Szeged, Sajat Tenant utca 1.";

    @Mock private ShipmentRequestRepository shipmentRequestRepository;
    @Mock private TransferRepository transferRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private AccessScopeService accessScopeService;
    @InjectMocks private HufDaybookService hufDaybookService;

    private final UUID ownCompanyId = UUID.randomUUID();
    private Branch ownBranch;

    @BeforeEach
    void setUp() {
        ownBranch = Branch.builder()
                .id(UUID.randomUUID())
                .code("BR020")
                .name("Sajat ertektar")
                .address(OWN_ADDRESS)
                .company(Company.builder().id(ownCompanyId).build())
                .build();

        TestingAuthenticationToken authentication =
                new TestingAuthenticationToken("K4-ADDR-TESZT", "test", "ROLE_ERTEKTAR");
        authentication.setDetails(new WorkerAuthenticationDetails(
                42L, ownCompanyId, ownBranch.getId(), "ERTEKTAR"));
        SecurityContextHolder.getContext().setAuthentication(authentication);

        when(branchRepository.findByIdAndCompanyId(ownBranch.getId(), ownCompanyId))
                .thenReturn(Optional.of(ownBranch));
        when(accessScopeService.vaultRegionBranchScopeOrNull()).thenReturn(null);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("FR-K4/9: a branchAddress a companyId-szűrt saját branch-ből töltődik; tenant-szűretlen findById a feloldásban nem hívódik")
    void branchAddressComesFromTenantScopedBranchLookupOnly() {
        HufDaybookDto daybook = hufDaybookService.getDaybook(ownBranch.getId(), DAY);

        assertThat(daybook.getBranchAddress())
                .as("A nyomtatvány telephely-címe a hívó tenant saját (findByIdAndCompanyId-vel "
                        + "betöltött) branch-ének címe")
                .isEqualTo(OWN_ADDRESS);
        // Regressziós guard: tenant-szűrés NÉLKÜLI branch-feloldás nem futhatott.
        verify(branchRepository, never()).findById(any(UUID.class));
        verify(branchRepository).findByIdAndCompanyId(ownBranch.getId(), ownCompanyId);
        // A cím mellett a Nyitó/Záró null-biztos: stub nélküli (null) összegeknél 0.
        assertThat(daybook.getOpeningBalanceHuf()).isEqualByComparingTo("0");
        assertThat(daybook.getClosingBalanceHuf()).isEqualByComparingTo("0");
    }
}
