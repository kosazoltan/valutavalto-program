package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.WuPartnerCompany;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.WuPartnerCompanyRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * N4 (legacy GETWCEG / WUCEGEK) — WU partner-cég törzs tesztjei.
 */
@ExtendWith(MockitoExtension.class)
class WuPartnerCompanyServiceTest {

    @Mock private WuPartnerCompanyRepository repository;
    @Mock private CompanyRepository companyRepository;
    @InjectMocks private WuPartnerCompanyService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Test
    @DisplayName("create — új cég felvétele a hívó cégéhez")
    void testCreateNew() {
        Company company = Company.builder().id(COMPANY_ID).build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndNameIgnoreCase(COMPANY_ID, "Teszt Kft."))
                    .thenReturn(Optional.empty());
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
            when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            WuPartnerCompany result = service.create("  Teszt Kft.  ");

            assertThat(result.getName()).isEqualTo("Teszt Kft."); // trimmelve
            assertThat(result.getActive()).isTrue();
            assertThat(result.getCompany().getId()).isEqualTo(COMPANY_ID);
        }
    }

    @Test
    @DisplayName("create — idempotens: létező aktív cég esetén a meglévőt adja vissza, nincs új save")
    void testCreateIdempotent() {
        WuPartnerCompany existing = WuPartnerCompany.builder()
                .id(UUID.randomUUID()).name("Teszt Kft.").active(true).build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndNameIgnoreCase(COMPANY_ID, "Teszt Kft."))
                    .thenReturn(Optional.of(existing));

            WuPartnerCompany result = service.create("Teszt Kft.");

            assertThat(result).isSameAs(existing);
            verify(repository, never()).save(any());
        }
    }

    @Test
    @DisplayName("create — inaktív létező cég újra-aktiválódik")
    void testCreateReactivates() {
        WuPartnerCompany existing = WuPartnerCompany.builder()
                .id(UUID.randomUUID()).name("Teszt Kft.").active(false).build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndNameIgnoreCase(COMPANY_ID, "Teszt Kft."))
                    .thenReturn(Optional.of(existing));
            when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            WuPartnerCompany result = service.create("Teszt Kft.");

            assertThat(result.getActive()).isTrue();
            verify(repository).save(existing);
        }
    }

    @Test
    @DisplayName("create — üres név ValidationException")
    void testCreateBlank() {
        assertThatThrownBy(() -> service.create("  "))
                .isInstanceOf(ValidationException.class);
        assertThatThrownBy(() -> service.create(null))
                .isInstanceOf(ValidationException.class);
    }

    @Test
    @DisplayName("deactivate — más cég partnercége: IDOR-védelem (ResourceNotFound)")
    void testDeactivateOtherCompanyBlocked() {
        UUID otherCompany = UUID.randomUUID();
        UUID id = UUID.randomUUID();
        WuPartnerCompany entity = WuPartnerCompany.builder()
                .id(id).name("Más Cég Kft.").active(true)
                .company(Company.builder().id(otherCompany).build())
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findById(id)).thenReturn(Optional.of(entity));

            assertThatThrownBy(() -> service.deactivate(id))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(repository, never()).save(any());
        }
    }

    @Test
    @DisplayName("deactivate — saját cég partnercége: active=false")
    void testDeactivateOwn() {
        UUID id = UUID.randomUUID();
        WuPartnerCompany entity = WuPartnerCompany.builder()
                .id(id).name("Saját Kft.").active(true)
                .company(Company.builder().id(COMPANY_ID).build())
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findById(id)).thenReturn(Optional.of(entity));
            when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            service.deactivate(id);

            assertThat(entity.getActive()).isFalse();
            verify(repository).save(entity);
        }
    }

    @Test
    @DisplayName("search — üres query a teljes aktív listát adja")
    void testSearchBlank() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndActiveTrueOrderByNameAsc(COMPANY_ID))
                    .thenReturn(java.util.List.of());

            service.search("   ");

            verify(repository).findByCompanyIdAndActiveTrueOrderByNameAsc(COMPANY_ID);
            verify(repository, never()).searchByName(any(), any());
        }
    }
}
