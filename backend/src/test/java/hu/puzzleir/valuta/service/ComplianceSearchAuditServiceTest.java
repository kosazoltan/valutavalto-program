package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceSearchAuditDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionRowDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionSearchCriteria;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceSearchAuditDto;
import hu.puzzleir.valuta.entity.ComplianceSearchAudit;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.ComplianceSearchAuditRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.cfg.DateTimeFeature;
import tools.jackson.databind.json.JsonMapper;

import java.math.BigDecimal;
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
class ComplianceSearchAuditServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID AUDIT_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");

    private final ObjectMapper objectMapper = JsonMapper.builder()
            .disable(DateTimeFeature.WRITE_DATES_AS_TIMESTAMPS)
            .build();

    @Mock
    private ComplianceSearchAuditRepository auditRepository;

    @Mock
    private ComplianceTransactionSearchService searchService;

    private ComplianceSearchAuditService service;

    @BeforeEach
    void setUp() {
        service = new ComplianceSearchAuditService(auditRepository, searchService, objectMapper);
    }

    @Test
    @DisplayName("create: sikeres mentés snapshot-tal, startDate/endDate megtartásával")
    void create_success_persistsSnapshotWithDates() throws Exception {
        ComplianceTransactionSearchCriteria criteria = criteriaWithDates();
        when(searchService.searchForExport(criteria)).thenReturn(rows());
        when(auditRepository.save(any(ComplianceSearchAudit.class))).thenAnswer(invocation -> {
            ComplianceSearchAudit audit = invocation.getArgument(0);
            audit.setId(AUDIT_ID);
            audit.setCreatedAt(LocalDateTime.of(2026, 7, 8, 12, 0));
            return audit;
        });

        ComplianceSearchAuditDto result;
        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W-001");

            result = service.create(CreateComplianceSearchAuditDto.builder()
                    .title("  NAV PEP keresés  ")
                    .description("  Féléves ellenőrzés  ")
                    .criteria(criteria)
                    .build());
        }

        ArgumentCaptor<ComplianceSearchAudit> captor = ArgumentCaptor.forClass(ComplianceSearchAudit.class);
        verify(auditRepository).save(captor.capture());
        ComplianceSearchAudit savedEntity = captor.getValue();
        assertThat(savedEntity.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(savedEntity.getTitle()).isEqualTo("NAV PEP keresés");
        assertThat(savedEntity.getDescription()).isEqualTo("Féléves ellenőrzés");
        assertThat(savedEntity.getCreatedByWorkerCode()).isEqualTo("W-001");
        assertThat(savedEntity.getResultCount()).isEqualTo(2);

        ComplianceTransactionSearchCriteria savedCriteria = objectMapper.readValue(
                savedEntity.getCriteriaJson(), ComplianceTransactionSearchCriteria.class);
        assertThat(savedCriteria.getStartDate()).isEqualTo(LocalDate.of(2026, 1, 1));
        assertThat(savedCriteria.getEndDate()).isEqualTo(LocalDate.of(2026, 6, 30));
        assertThat(savedCriteria.isPepOnly()).isTrue();

        List<ComplianceTransactionRowDto> savedRows = objectMapper.readValue(
                savedEntity.getResultSnapshotJson(), new TypeReference<List<ComplianceTransactionRowDto>>() {});
        assertThat(savedRows).hasSize(2);
        assertThat(savedRows).extracting(ComplianceTransactionRowDto::getReceiptNumber)
                .containsExactly("B-2026-001", "B-2026-002");
        assertThat(result.getId()).isEqualTo(AUDIT_ID);
        assertThat(result.getResultCount()).isEqualTo(2);
    }

    @Test
    @DisplayName("create: üres cím elutasítva, keresés és mentés nélkül")
    void create_blankTitle_throwsValidation() {
        assertThatThrownBy(() -> service.create(CreateComplianceSearchAuditDto.builder()
                .title("   ")
                .criteria(new ComplianceTransactionSearchCriteria())
                .build()))
                .isInstanceOf(ValidationException.class);

        verify(searchService, never()).searchForExport(any());
        verify(auditRepository, never()).save(any());
    }

    @Test
    @DisplayName("create: túl hosszú cím elutasítva, mentés nélkül")
    void create_titleTooLong_throwsValidation() {
        assertThatThrownBy(() -> service.create(CreateComplianceSearchAuditDto.builder()
                .title("a".repeat(201))
                .criteria(new ComplianceTransactionSearchCriteria())
                .build()))
                .isInstanceOf(ValidationException.class);

        verify(searchService, never()).searchForExport(any());
        verify(auditRepository, never()).save(any());
    }

    @Test
    @DisplayName("create: túl hosszú leírás elutasítva, mentés nélkül")
    void create_descriptionTooLong_throwsValidation() {
        assertThatThrownBy(() -> service.create(CreateComplianceSearchAuditDto.builder()
                .title("Audit")
                .description("a".repeat(2001))
                .criteria(new ComplianceTransactionSearchCriteria())
                .build()))
                .isInstanceOf(ValidationException.class);

        verify(searchService, never()).searchForExport(any());
        verify(auditRepository, never()).save(any());
    }

    @Test
    @DisplayName("create: null criteria fail-closed validáció")
    void create_nullCriteria_throwsValidation() {
        assertThatThrownBy(() -> service.create(CreateComplianceSearchAuditDto.builder()
                .title("Audit")
                .criteria(null)
                .build()))
                .isInstanceOf(ValidationException.class);

        verify(searchService, never()).searchForExport(any());
        verify(auditRepository, never()).save(any());
    }

    @Test
    @DisplayName("create: export-cap túllépés változatlanul propagál, mentés nélkül")
    void create_exportTooLarge_failsClosedWithoutSave() {
        ComplianceTransactionSearchCriteria criteria = new ComplianceTransactionSearchCriteria();
        BusinessException tooLarge = new BusinessException("túl nagy", "COMPLIANCE_EXPORT_TOO_LARGE");
        when(searchService.searchForExport(criteria)).thenThrow(tooLarge);

        assertThatThrownBy(() -> service.create(CreateComplianceSearchAuditDto.builder()
                .title("Audit")
                .criteria(criteria)
                .build()))
                .isSameAs(tooLarge)
                .extracting("errorCode")
                .isEqualTo("COMPLIANCE_EXPORT_TOO_LARGE");

        verify(auditRepository, never()).save(any());
    }

    @Test
    @DisplayName("list: aktuális cég auditjait listázza, criteria-t deserializál, snapshot nélkül")
    void list_companyScoped_deserializesCriteriaWithoutSnapshot() {
        when(auditRepository.findByCompanyIdOrderByCreatedAtDesc(COMPANY_ID)).thenReturn(List.of(
                audit("PEP", "{\"pepOnly\":true,\"startDate\":\"2026-01-01\"}", "[]", 5)
        ));

        List<ComplianceSearchAuditDto> result;
        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            result = service.listForCurrentCompany();
        }

        assertThat(result).hasSize(1);
        assertThat(result.get(0).getCriteria().isPepOnly()).isTrue();
        assertThat(result.get(0).getCriteria().getStartDate()).isEqualTo(LocalDate.of(2026, 1, 1));
        assertThat(result.get(0).getResultCount()).isEqualTo(5);
        verify(auditRepository).findByCompanyIdOrderByCreatedAtDesc(COMPANY_ID);
    }

    @Test
    @DisplayName("list: sérült JSON esetén fail-closed BusinessException")
    void list_corruptJson_failsClosed() {
        when(auditRepository.findByCompanyIdOrderByCreatedAtDesc(COMPANY_ID)).thenReturn(List.of(
                audit("Rossz", "{nem-json", "[]", 1)
        ));

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.listForCurrentCompany())
                    .isInstanceOf(BusinessException.class)
                    .extracting("errorCode")
                    .isEqualTo("COMPLIANCE_AUDIT_JSON");
        }
    }

    @Test
    @DisplayName("loadForPdf: idegen cég / nem létező id azonos 404")
    void loadSnapshotRows_crossTenantOrMissing_throws404() {
        when(auditRepository.findByIdAndCompanyId(AUDIT_ID, COMPANY_ID)).thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            assertThatThrownBy(() -> service.loadForPdf(AUDIT_ID))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("loadForPdf: kizárólag a tárolt snapshot-sorokat adja vissza, újrakeresés nélkül")
    void loadSnapshotRows_returnsStoredRows() throws Exception {
        String snapshotJson = objectMapper.writeValueAsString(rows());
        when(auditRepository.findByIdAndCompanyId(AUDIT_ID, COMPANY_ID)).thenReturn(Optional.of(
                audit("PEP", "{}", snapshotJson, 2)
        ));

        ComplianceSearchAuditService.ComplianceSearchAuditPdfData result;
        try (MockedStatic<SecurityUtils> sec = org.mockito.Mockito.mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            result = service.loadForPdf(AUDIT_ID);
        }

        assertThat(result.rows()).hasSize(2);
        assertThat(result.rows()).extracting(ComplianceTransactionRowDto::getReceiptNumber)
                .containsExactly("B-2026-001", "B-2026-002");
        verify(searchService, never()).searchForExport(any());
    }

    private static ComplianceTransactionSearchCriteria criteriaWithDates() {
        ComplianceTransactionSearchCriteria criteria = new ComplianceTransactionSearchCriteria();
        criteria.setStartDate(LocalDate.of(2026, 1, 1));
        criteria.setEndDate(LocalDate.of(2026, 6, 30));
        criteria.setPepOnly(true);
        return criteria;
    }

    private static List<ComplianceTransactionRowDto> rows() {
        return List.of(
                ComplianceTransactionRowDto.builder()
                        .id(1L)
                        .receiptNumber("B-2026-001")
                        .transactionType(TransactionType.BUY)
                        .transactionDate(LocalDate.of(2026, 6, 1))
                        .currencyCode("EUR")
                        .currencyAmount(new BigDecimal("1000"))
                        .hufAmount(new BigDecimal("390000"))
                        .customerName("Kőműves Ödön")
                        .build(),
                ComplianceTransactionRowDto.builder()
                        .id(2L)
                        .receiptNumber("B-2026-002")
                        .transactionType(TransactionType.SELL)
                        .transactionDate(LocalDate.of(2026, 6, 2))
                        .currencyCode("USD")
                        .currencyAmount(new BigDecimal("500"))
                        .hufAmount(new BigDecimal("180000"))
                        .customerName("Árvíztűrő Tükörfúrógép")
                        .build());
    }

    private static ComplianceSearchAudit audit(String title, String criteriaJson, String resultSnapshotJson, int resultCount) {
        return ComplianceSearchAudit.builder()
                .id(AUDIT_ID)
                .companyId(COMPANY_ID)
                .title(title)
                .description("Leírás")
                .criteriaJson(criteriaJson)
                .resultSnapshotJson(resultSnapshotJson)
                .resultCount(resultCount)
                .createdByWorkerCode("W-000")
                .createdAt(LocalDateTime.of(2026, 7, 8, 12, 0))
                .build();
    }
}
