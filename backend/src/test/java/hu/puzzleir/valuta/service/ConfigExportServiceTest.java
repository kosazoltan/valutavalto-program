package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.config.ConfigBundleDto;
import hu.puzzleir.valuta.dto.config.ImportResultDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.LedDisplayRepository;
import hu.puzzleir.valuta.repository.PrintTemplateRepository;
import hu.puzzleir.valuta.repository.RateCategoryRepository;
import hu.puzzleir.valuta.repository.RoundingRuleRepository;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ConfigExportServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID BRANCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final String KEY = "IMPORT_LIMIT";
    private static final String IMPORTED_VALUE = "250000";

    @Mock private BranchRepository branchRepository;
    @Mock private SystemParameterRepository systemParameterRepository;
    @Mock private RateCategoryRepository rateCategoryRepository;
    @Mock private RoundingRuleRepository roundingRuleRepository;
    @Mock private PrintTemplateRepository printTemplateRepository;
    @Mock private LedDisplayRepository ledDisplayRepository;

    @InjectMocks private ConfigExportService service;

    @Test
    @DisplayName("importConfig — company-scoped row exists: updates only scoped row and does not query global fallback")
    void importConfig_scopedRowExists_updatesOnlyScopedRow() {
        SystemParameter scoped = systemParameter("old-scoped", COMPANY_ID);
        SystemParameter global = systemParameter("old-global", null);
        arrangeOwnedBranch();
        when(systemParameterRepository.findByParameterKeyAndCompanyId(KEY, COMPANY_ID))
            .thenReturn(Optional.of(scoped));
        when(systemParameterRepository.save(scoped)).thenReturn(scoped);

        ImportResultDto result = importWithCompany(bundle(KEY, IMPORTED_VALUE));

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getImportedSystemParams()).isEqualTo(1);
        assertThat(result.getWarnings()).isEmpty();
        assertThat(result.getErrors()).isEmpty();
        assertThat(scoped.getParameterValue()).isEqualTo(IMPORTED_VALUE);
        assertThat(global.getParameterValue()).isEqualTo("old-global");
        verify(systemParameterRepository).save(scoped);
        verify(systemParameterRepository, never()).findByParameterKeyAndCompanyIdIsNull(KEY);
    }

    @Test
    @DisplayName("importConfig — only global row exists: creates scoped override copied from global metadata")
    void importConfig_globalOnly_createsScopedOverrideWithoutMutatingGlobal() {
        SystemParameter global = systemParameter("old-global", null);
        arrangeOwnedBranch();
        when(systemParameterRepository.findByParameterKeyAndCompanyId(KEY, COMPANY_ID))
            .thenReturn(Optional.empty());
        when(systemParameterRepository.findByParameterKeyAndCompanyIdIsNull(KEY))
            .thenReturn(Optional.of(global));
        ArgumentCaptor<SystemParameter> savedCaptor = ArgumentCaptor.forClass(SystemParameter.class);
        when(systemParameterRepository.save(savedCaptor.capture())).thenAnswer(invocation -> invocation.getArgument(0));

        ImportResultDto result = importWithCompany(bundle(KEY, IMPORTED_VALUE));

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getImportedSystemParams()).isEqualTo(1);
        assertThat(result.getWarnings()).isEmpty();
        assertThat(result.getErrors()).isEmpty();
        SystemParameter saved = savedCaptor.getValue();
        assertThat(saved).isNotSameAs(global);
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
        assertThat(saved.getParameterKey()).isEqualTo(global.getParameterKey());
        assertThat(saved.getParameterType()).isEqualTo(global.getParameterType());
        assertThat(saved.getCategory()).isEqualTo(global.getCategory());
        assertThat(saved.getDescription()).isEqualTo(global.getDescription());
        assertThat(saved.getIsActive()).isEqualTo(global.getIsActive());
        assertThat(saved.getParameterValue()).isEqualTo(IMPORTED_VALUE);
        assertThat(global.getCompanyId()).isNull();
        assertThat(global.getParameterValue()).isEqualTo("old-global");
    }

    @Test
    @DisplayName("importConfig — unknown key: returns warning and does not save")
    void importConfig_unknownKey_warnsAndDoesNotSave() {
        arrangeOwnedBranch();
        when(systemParameterRepository.findByParameterKeyAndCompanyId(KEY, COMPANY_ID))
            .thenReturn(Optional.empty());
        when(systemParameterRepository.findByParameterKeyAndCompanyIdIsNull(KEY))
            .thenReturn(Optional.empty());

        ImportResultDto result = importWithCompany(bundle(KEY, IMPORTED_VALUE));

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getImportedSystemParams()).isZero();
        assertThat(result.getWarnings()).containsExactly("Ismeretlen rendszer paraméter, kihagyva: " + KEY);
        assertThat(result.getErrors()).isEmpty();
        verify(systemParameterRepository, never()).save(Mockito.any(SystemParameter.class));
    }

    private ImportResultDto importWithCompany(ConfigBundleDto bundle) {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            return service.importConfig(BRANCH_ID, bundle);
        }
    }

    private void arrangeOwnedBranch() {
        when(branchRepository.existsByIdAndCompanyId(BRANCH_ID, COMPANY_ID)).thenReturn(true);
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(Branch.builder()
            .id(BRANCH_ID)
            .code("B001")
            .name("Test branch")
            .build()));
    }

    private ConfigBundleDto bundle(String key, String value) {
        return ConfigBundleDto.builder()
            .systemParams(Map.of(key, value))
            .build();
    }

    private SystemParameter systemParameter(String value, UUID companyId) {
        return SystemParameter.builder()
            .id(UUID.randomUUID())
            .parameterKey(KEY)
            .companyId(companyId)
            .parameterValue(value)
            .parameterType("STRING")
            .category("IMPORT")
            .description("Import limit")
            .isActive(true)
            .build();
    }
}
