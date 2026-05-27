package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.RateWorkgroup;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.RateWorkgroupRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.HashSet;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * FK-02: RateWorkgroupService — kód-egyediség cégen belül, tileColor frissítés, soft-delete.
 */
@ExtendWith(MockitoExtension.class)
class RateWorkgroupServiceTest {

    @Mock private RateWorkgroupRepository workgroupRepository;
    @Mock private CompanyRepository companyRepository;
    @InjectMocks private RateWorkgroupService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Test
    @DisplayName("create: a kód-egyediséget CÉGEN BELÜL ellenőrzi (multi-tenant), nem globálisan")
    void create_checksCodeUniquenessWithinCompany() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            Company company = new Company();
            company.setId(COMPANY_ID);
            when(workgroupRepository.findByCompanyIdAndCode(COMPANY_ID, "WG01")).thenReturn(Optional.empty());
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(workgroupRepository.save(any(RateWorkgroup.class))).thenAnswer(inv -> inv.getArgument(0));

            RateWorkgroup wg = RateWorkgroup.builder().name("Pécs").code("WG01").tileColor("amber").build();
            RateWorkgroup saved = service.create(wg);

            assertThat(saved.getCompany()).isSameAs(company);
            assertThat(saved.getTileColor()).isEqualTo("amber");
            // A globális findByCode-ot NEM hívjuk (cross-tenant fals pozitív elkerülése).
            verify(workgroupRepository, never()).findByCode(anyString());
            verify(workgroupRepository).findByCompanyIdAndCode(COMPANY_ID, "WG01");
        }
    }

    @Test
    @DisplayName("create: ütköző kód CÉGEN BELÜL → ValidationException")
    void create_duplicateCodeWithinCompany_throws() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(workgroupRepository.findByCompanyIdAndCode(COMPANY_ID, "WG01"))
                    .thenReturn(Optional.of(new RateWorkgroup()));

            RateWorkgroup wg = RateWorkgroup.builder().name("Pécs").code("WG01").build();
            assertThatThrownBy(() -> service.create(wg))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("WG01");
            verify(workgroupRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("update: a tileColor frissül")
    void update_persistsTileColor() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            Company company = new Company();
            company.setId(COMPANY_ID);
            UUID id = UUID.randomUUID();
            RateWorkgroup existing = RateWorkgroup.builder().id(id).name("Régi").code("WG01")
                    .company(company).active(true).tileColor(null).legacyGroupNumber(1).build();
            when(workgroupRepository.findById(id)).thenReturn(Optional.of(existing));
            when(workgroupRepository.save(any(RateWorkgroup.class))).thenAnswer(inv -> inv.getArgument(0));

            RateWorkgroup update = RateWorkgroup.builder().name("Új").active(true).tileColor("sky").legacyGroupNumber(7).build();
            RateWorkgroup result = service.update(id, update);

            assertThat(result.getName()).isEqualTo("Új");
            assertThat(result.getTileColor()).isEqualTo("sky");
            // A sorszám is frissül (P1: korábban némán elveszett).
            assertThat(result.getLegacyGroupNumber()).isEqualTo(7);
        }
    }

    @Test
    @DisplayName("softDelete: inaktivál (active=false) ÉS feloldja a branch-hozzárendelést, NEM töröl fizikailag")
    void softDelete_deactivatesAndClearsBranches() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            Company company = new Company();
            company.setId(COMPANY_ID);
            UUID id = UUID.randomUUID();
            Set<Branch> branches = new HashSet<>();
            branches.add(new Branch());
            RateWorkgroup existing = RateWorkgroup.builder().id(id).name("Törlendő").code("WG09")
                    .company(company).active(true).branches(branches).build();
            when(workgroupRepository.findById(id)).thenReturn(Optional.of(existing));
            when(workgroupRepository.save(any(RateWorkgroup.class))).thenAnswer(inv -> inv.getArgument(0));

            service.softDelete(id);

            assertThat(existing.getActive()).isFalse();
            assertThat(existing.getBranches()).isEmpty();
            verify(workgroupRepository, never()).delete(any());
            verify(workgroupRepository, never()).deleteById(any());
        }
    }
}
