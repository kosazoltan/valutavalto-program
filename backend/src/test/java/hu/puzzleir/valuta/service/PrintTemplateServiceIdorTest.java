package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.printtemplate.PrintTemplateResponse;
import hu.puzzleir.valuta.entity.PrintTemplate;
import hu.puzzleir.valuta.entity.PrintTemplateType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.PrintTemplateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.util.LegacyCompanyIdentityCodec;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * PrintTemplateService multi-tenant IDOR guard tesztek (audit 2026-06-15, FINDING #14).
 * A tenancy a legacy Integer companyId-n keresztül él (UUID→Integer a LegacyCompanyIdentityCodec-kel).
 */
@ExtendWith(MockitoExtension.class)
class PrintTemplateServiceIdorTest {

    private static final UUID COMPANY_UUID = UUID.randomUUID();
    private static final Integer OWN_LEGACY = LegacyCompanyIdentityCodec.toLegacyInt(COMPANY_UUID);
    private static final Integer FOREIGN_LEGACY = OWN_LEGACY + 12345;

    @Mock private PrintTemplateRepository printTemplateRepository;
    @InjectMocks private PrintTemplateService service;

    private MockedStatic<SecurityUtils> securityUtilsMock;

    @BeforeEach
    void setUp() {
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_UUID);
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) securityUtilsMock.close();
    }

    private PrintTemplate template(Integer legacyCompanyId) {
        return PrintTemplate.builder()
                .id(UUID.randomUUID()).name("Blokk").templateType(PrintTemplateType.RECEIPT)
                .content("x").isDefault(legacyCompanyId == null).companyId(legacyCompanyId).build();
    }

    @Test
    @DisplayName("getTemplateById: saját cég sablonja → visszaadja")
    void getById_own_returns() {
        PrintTemplate t = template(OWN_LEGACY);
        when(printTemplateRepository.findById(t.getId())).thenReturn(Optional.of(t));

        assertThat(service.getTemplateById(t.getId()).getId()).isEqualTo(t.getId());
    }

    @Test
    @DisplayName("getTemplateById: globális default (companyId==null) → visszaadja")
    void getById_globalDefault_returns() {
        PrintTemplate t = template(null);
        when(printTemplateRepository.findById(t.getId())).thenReturn(Optional.of(t));

        assertThat(service.getTemplateById(t.getId()).getId()).isEqualTo(t.getId());
    }

    @Test
    @DisplayName("getTemplateById: más cég sablonja → ResourceNotFoundException (404)")
    void getById_crossTenant_throws() {
        PrintTemplate t = template(FOREIGN_LEGACY);
        when(printTemplateRepository.findById(t.getId())).thenReturn(Optional.of(t));

        assertThatThrownBy(() -> service.getTemplateById(t.getId()))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Sablon nem található");
    }

    @Test
    @DisplayName("getTemplatesByType: idegen cég egyedi sablonjai kiszűrve, default + saját marad")
    void getByType_filtersForeign() {
        PrintTemplate own = template(OWN_LEGACY);
        PrintTemplate global = template(null);
        PrintTemplate foreign = template(FOREIGN_LEGACY);
        when(printTemplateRepository.findByTemplateType(PrintTemplateType.RECEIPT))
                .thenReturn(List.of(own, global, foreign));

        List<PrintTemplateResponse> result = service.getTemplatesByType("RECEIPT");

        assertThat(result).extracting(PrintTemplateResponse::getId)
                .containsExactlyInAnyOrder(own.getId(), global.getId());
    }
}
