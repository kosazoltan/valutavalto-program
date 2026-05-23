package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.ArfolyamInternetLink;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ArfolyamInternetLinkRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
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
 * N1 (legacy ARFOLYAM / TINTERNETTMKFORM, Unit2.pas) — internet-link tesztek.
 */
@ExtendWith(MockitoExtension.class)
class ArfolyamInternetLinkServiceTest {

    @Mock private ArfolyamInternetLinkRepository repository;
    @Mock private CompanyRepository companyRepository;
    @InjectMocks private ArfolyamInternetLinkService service;

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Test
    @DisplayName("create — sikeres felvétel (trimmel, a hívó cégéhez köt)")
    void testCreate() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndButtonNumber(COMPANY_ID, 3)).thenReturn(Optional.empty());
            when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(Company.builder().id(COMPANY_ID).build()));
            when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            ArfolyamInternetLink r = service.create(3, "  MNB  ", "  https://mnb.hu  ");

            assertThat(r.getButtonNumber()).isEqualTo(3);
            assertThat(r.getLabel()).isEqualTo("MNB");
            assertThat(r.getUrl()).isEqualTo("https://mnb.hu");
            assertThat(r.getCompany().getId()).isEqualTo(COMPANY_ID);
        }
    }

    @Test
    @DisplayName("create — duplikált gombszám: legacy 'KI VAN OSZTVA' ValidationException")
    void testCreateDuplicateButtonNumber() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findByCompanyIdAndButtonNumber(COMPANY_ID, 3))
                    .thenReturn(Optional.of(ArfolyamInternetLink.builder().buttonNumber(3).build()));

            assertThatThrownBy(() -> service.create(3, "MNB", "https://mnb.hu"))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("ki van osztva");
            verify(repository, never()).save(any());
        }
    }

    @Test
    @DisplayName("create — hiányzó mezők (szám/felirat/URL) ValidationException")
    void testCreateMissingFields() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThatThrownBy(() -> service.create(null, "x", "y")).isInstanceOf(ValidationException.class);
            assertThatThrownBy(() -> service.create(1, " ", "y")).isInstanceOf(ValidationException.class);
            assertThatThrownBy(() -> service.create(1, "x", " ")).isInstanceOf(ValidationException.class);
        }
    }

    @Test
    @DisplayName("create — nem-http(s) URL (javascript:/data:) elutasítva (biztonsági guard)")
    void testCreateRejectsNonHttpUrl() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            assertThatThrownBy(() -> service.create(1, "X", "javascript:alert(1)"))
                    .isInstanceOf(ValidationException.class).hasMessageContaining("http");
            assertThatThrownBy(() -> service.create(1, "X", "data:text/html,<script>"))
                    .isInstanceOf(ValidationException.class);
            assertThatThrownBy(() -> service.create(1, "X", "ftp://x"))
                    .isInstanceOf(ValidationException.class);
            verify(repository, never()).save(any());
        }
    }

    @Test
    @DisplayName("delete — más cég linkje: IDOR-védelem (ResourceNotFound, nincs delete)")
    void testDeleteOtherCompanyBlocked() {
        UUID id = UUID.randomUUID();
        ArfolyamInternetLink entity = ArfolyamInternetLink.builder()
                .id(id).company(Company.builder().id(UUID.randomUUID()).build()).build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findById(id)).thenReturn(Optional.of(entity));

            assertThatThrownBy(() -> service.delete(id)).isInstanceOf(ResourceNotFoundException.class);
            verify(repository, never()).delete(any());
        }
    }

    @Test
    @DisplayName("delete — saját cég linkje törlődik")
    void testDeleteOwn() {
        UUID id = UUID.randomUUID();
        ArfolyamInternetLink entity = ArfolyamInternetLink.builder()
                .id(id).company(Company.builder().id(COMPANY_ID).build()).build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            when(repository.findById(id)).thenReturn(Optional.of(entity));

            service.delete(id);

            verify(repository).delete(entity);
        }
    }
}
