package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Bank;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BankRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-005/C1 — Bank-törzs területi szűrés + idempotens felvétel + IDOR egységteszt.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class BankServiceTest {

    @Mock private BankRepository repository;
    @Mock private CompanyRepository companyRepository;
    @Mock private AccessScopeService accessScopeService;

    @InjectMocks private BankService service;

    private final UUID companyId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("W", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(1L, companyId, UUID.randomUUID(), "FOERTEKTAR"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("list() cég-szintű role (region null) → összes aktív bank")
    void list_companyWide_allActive() {
        when(accessScopeService.vaultRegionCodeOrNull()).thenReturn(null);
        when(repository.findByCompanyIdAndActiveTrueOrderByNameAsc(companyId))
                .thenReturn(List.of(Bank.builder().name("OTP").build()));

        List<Bank> result = service.list();

        assertEquals(1, result.size());
        verify(repository).findByCompanyIdAndActiveTrueOrderByNameAsc(companyId);
        verify(repository, never()).findActiveByCompanyAndRegionOrGlobal(any(), any());
    }

    @Test
    @DisplayName("list() értéktáros (region=20) → cég-szintű + saját régió bankok")
    void list_vault_regionScoped() {
        when(accessScopeService.vaultRegionCodeOrNull()).thenReturn("20");
        when(repository.findActiveByCompanyAndRegionOrGlobal(companyId, "20"))
                .thenReturn(List.of(
                        Bank.builder().name("OTP").regionCode(null).build(),
                        Bank.builder().name("Szegedi Bank").regionCode("20").build()));

        List<Bank> result = service.list();

        assertEquals(2, result.size());
        verify(repository).findActiveByCompanyAndRegionOrGlobal(companyId, "20");
        verify(repository, never()).findByCompanyIdAndActiveTrueOrderByNameAsc(any());
    }

    @Test
    @DisplayName("search() értéktárosnál is területi szűrés (idegen régió kiesik)")
    void search_vault_filtersForeignRegion() {
        when(accessScopeService.vaultRegionCodeOrNull()).thenReturn("20");
        when(repository.searchByName(eq(companyId), eq("bank"))).thenReturn(List.of(
                Bank.builder().name("OTP Bank").regionCode(null).build(),
                Bank.builder().name("Szegedi Bank").regionCode("20").build(),
                Bank.builder().name("Pécsi Bank").regionCode("99").build()));

        List<Bank> result = service.search("bank");

        assertEquals(2, result.size()); // a "99" régiós kiesik
        assertTrue(result.stream().noneMatch(b -> "99".equals(b.getRegionCode())));
    }

    @Test
    @DisplayName("create() üres név → ValidationException")
    void create_blankName_throws() {
        assertThrows(ValidationException.class, () -> service.create("  ", null));
    }

    @Test
    @DisplayName("create() új bank → mentés region-nel")
    void create_new_savesWithRegion() {
        when(repository.findByCompanyIdAndNameIgnoreCase(companyId, "Új Bank")).thenReturn(Optional.empty());
        when(companyRepository.findById(companyId)).thenReturn(Optional.of(Company.builder().id(companyId).build()));
        when(repository.save(any(Bank.class))).thenAnswer(inv -> inv.getArgument(0));

        Bank created = service.create("Új Bank", "20");

        assertEquals("Új Bank", created.getName());
        assertEquals("20", created.getRegionCode());
        assertTrue(Boolean.TRUE.equals(created.getActive()));
    }

    @Test
    @DisplayName("create() létező inaktív → újra-aktiválás (idempotens)")
    void create_existingInactive_reactivates() {
        Bank existing = Bank.builder().id(UUID.randomUUID()).name("OTP").active(false).build();
        when(repository.findByCompanyIdAndNameIgnoreCase(companyId, "OTP")).thenReturn(Optional.of(existing));
        when(repository.save(any(Bank.class))).thenAnswer(inv -> inv.getArgument(0));

        Bank result = service.create("OTP", null);

        assertTrue(Boolean.TRUE.equals(result.getActive()));
        verify(companyRepository, never()).findById(any());
    }

    @Test
    @DisplayName("deactivate() kereszt-cég → IDOR blokk (ResourceNotFound)")
    void deactivate_crossCompany_blocked() {
        UUID otherCompany = UUID.randomUUID();
        Bank foreign = Bank.builder().id(UUID.randomUUID()).name("Idegen")
                .company(Company.builder().id(otherCompany).build()).build();
        when(repository.findById(foreign.getId())).thenReturn(Optional.of(foreign));

        assertThrows(ResourceNotFoundException.class, () -> service.deactivate(foreign.getId()));
        verify(repository, never()).save(any());
    }
}
