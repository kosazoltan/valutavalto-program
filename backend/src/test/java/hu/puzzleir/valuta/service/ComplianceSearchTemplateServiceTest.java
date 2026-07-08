package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceSearchTemplateDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionSearchCriteria;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceSearchTemplateDto;
import hu.puzzleir.valuta.entity.ComplianceSearchTemplate;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ComplianceSearchTemplateRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.cfg.DateTimeFeature;
import tools.jackson.databind.json.JsonMapper;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ComplianceSearchTemplateServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID TEMPLATE_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    private final ObjectMapper objectMapper = JsonMapper.builder()
            .disable(DateTimeFeature.WRITE_DATES_AS_TIMESTAMPS)
            .build();

    @Mock
    private ComplianceSearchTemplateRepository templateRepository;

    private ComplianceSearchTemplateService service;

    @BeforeEach
    void setUp() {
        service = new ComplianceSearchTemplateService(templateRepository, objectMapper);
    }

    @Test
    @DisplayName("create: sikeres mentés dátumok nélkül, többi criteria-mező megőrzésével")
    void create_success_stripsDatesOnly() throws Exception {
        when(templateRepository.existsByCompanyIdAndName(COMPANY_ID, "Nagy PEP keresés")).thenReturn(false);
        when(templateRepository.save(any(ComplianceSearchTemplate.class))).thenAnswer(invocation -> {
            ComplianceSearchTemplate template = invocation.getArgument(0);
            template.setId(TEMPLATE_ID);
            template.setCreatedAt(LocalDateTime.of(2026, 7, 8, 12, 0));
            return template;
        });

        ComplianceTransactionSearchCriteria criteria = new ComplianceTransactionSearchCriteria();
        criteria.setStartDate(LocalDate.of(2026, 1, 1));
        criteria.setEndDate(LocalDate.of(2026, 6, 30));
        criteria.setCustomerBirthDate(LocalDate.of(1990, 5, 5));
        criteria.setPepOnly(true);
        criteria.setCurrencyIds(List.of(1L, 2L));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            ComplianceSearchTemplateDto result = service.create(CreateComplianceSearchTemplateDto.builder()
                    .name("  Nagy PEP keresés  ")
                    .criteria(criteria)
                    .build());

            assertThat(result.getId()).isEqualTo(TEMPLATE_ID);
        }

        ArgumentCaptor<ComplianceSearchTemplate> captor = ArgumentCaptor.forClass(ComplianceSearchTemplate.class);
        verify(templateRepository).save(captor.capture());
        ComplianceSearchTemplate savedEntity = captor.getValue();
        assertThat(savedEntity.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(savedEntity.getName()).isEqualTo("Nagy PEP keresés");
        assertThat(savedEntity.getCreatedByWorkerCode()).isEqualTo("W-001");

        ComplianceTransactionSearchCriteria saved = objectMapper.readValue(
                savedEntity.getCriteriaJson(), ComplianceTransactionSearchCriteria.class);
        assertThat(saved.getStartDate()).isNull();
        assertThat(saved.getEndDate()).isNull();
        assertThat(saved.getCustomerBirthDate()).isEqualTo(LocalDate.of(1990, 5, 5));
        assertThat(saved.isPepOnly()).isTrue();
        assertThat(saved.getCurrencyIds()).containsExactly(1L, 2L);
    }

    @Test
    @DisplayName("create: cégen belüli duplikált név elutasítva, mentés nélkül")
    void create_duplicateName_throwsValidation() {
        when(templateRepository.existsByCompanyIdAndName(COMPANY_ID, "Sablon")).thenReturn(true);

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.create(CreateComplianceSearchTemplateDto.builder()
                    .name("Sablon")
                    .criteria(new ComplianceTransactionSearchCriteria())
                    .build()))
                    .isInstanceOf(ValidationException.class);
        }

        verify(templateRepository, never()).save(any());
    }

    @Test
    @DisplayName("create: üres sablonnév elutasítva, mentés nélkül")
    void create_blankName_throwsValidation() {
        assertThatThrownBy(() -> service.create(CreateComplianceSearchTemplateDto.builder()
                .name("   ")
                .criteria(new ComplianceTransactionSearchCriteria())
                .build()))
                .isInstanceOf(ValidationException.class);

        verify(templateRepository, never()).save(any());
    }

    @Test
    @DisplayName("create: 100 karakternél hosszabb sablonnév elutasítva")
    void create_nameTooLong_throwsValidation() {
        assertThatThrownBy(() -> service.create(CreateComplianceSearchTemplateDto.builder()
                .name("a".repeat(101))
                .criteria(new ComplianceTransactionSearchCriteria())
                .build()))
                .isInstanceOf(ValidationException.class);

        verify(templateRepository, never()).save(any());
    }

    @Test
    @DisplayName("create: null criteria fail-closed validáció")
    void create_nullCriteria_throwsValidation() {
        assertThatThrownBy(() -> service.create(CreateComplianceSearchTemplateDto.builder()
                .name("Sablon")
                .criteria(null)
                .build()))
                .isInstanceOf(ValidationException.class);

        verify(templateRepository, never()).save(any());
    }

    @Test
    @DisplayName("list: aktuális cég sablonjait listázza és criteria-t deserializál")
    void list_companyScoped_deserializesCriteria() throws Exception {
        when(templateRepository.findByCompanyIdOrderByNameAsc(COMPANY_ID)).thenReturn(List.of(
                template("PEP", "{\"pepOnly\":true}"),
                template("Név", "{\"customerName\":\"Kiss\"}")
        ));

        List<ComplianceSearchTemplateDto> result;
        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            result = service.listForCurrentCompany();
        }

        assertThat(result).hasSize(2);
        assertThat(result.get(0).getCriteria().isPepOnly()).isTrue();
        assertThat(result.get(1).getCriteria().getCustomerName()).isEqualTo("Kiss");
        verify(templateRepository).findByCompanyIdOrderByNameAsc(COMPANY_ID);
    }

    @Test
    @DisplayName("list: sérült JSON esetén fail-closed BusinessException")
    void list_corruptJson_failsClosed() {
        when(templateRepository.findByCompanyIdOrderByNameAsc(COMPANY_ID))
                .thenReturn(List.of(template("Rossz", "{nem-json")));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.listForCurrentCompany())
                    .isInstanceOf(BusinessException.class)
                    .extracting("errorCode")
                    .isEqualTo("COMPLIANCE_TEMPLATE_JSON");
        }
    }

    @Test
    @DisplayName("delete: cég-scope-olt sablon törlése")
    void delete_success() {
        ComplianceSearchTemplate entity = template("Sablon", "{}");
        when(templateRepository.findByIdAndCompanyId(TEMPLATE_ID, COMPANY_ID)).thenReturn(Optional.of(entity));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            service.delete(TEMPLATE_ID);
        }

        verify(templateRepository).delete(entity);
    }

    @Test
    @DisplayName("delete: idegen cég / nem létező id azonos 404, törlés nélkül")
    void delete_crossTenantOrMissing_throws404() {
        when(templateRepository.findByIdAndCompanyId(TEMPLATE_ID, COMPANY_ID)).thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.delete(TEMPLATE_ID))
                    .isInstanceOf(ResourceNotFoundException.class);
        }

        verify(templateRepository, never()).delete(any());
    }

    private static ComplianceSearchTemplate template(String name, String criteriaJson) {
        return ComplianceSearchTemplate.builder()
                .id(TEMPLATE_ID)
                .companyId(COMPANY_ID)
                .name(name)
                .criteriaJson(criteriaJson)
                .createdByWorkerCode("W-000")
                .createdAt(LocalDateTime.of(2026, 7, 8, 12, 0))
                .build();
    }
}
