package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * TD7 SYSPARAM-NO-COMPANYID: cég-scoped lookup + globális fallback.
 * A publikus szignatúrák (getValue(key), getValue(key,default), getByKey(key))
 * változatlanok — a companyId-t a service belül szerzi (getCurrentCompanyIdOrNull).
 */
@ExtendWith(MockitoExtension.class)
class SystemParameterServiceTest {

    private static final UUID COMPANY_A =
            UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final String KEY = "FORINT_SUPERVISOR_THRESHOLD";

    @Mock private SystemParameterRepository repo;
    @InjectMocks private SystemParameterService service;

    private SystemParameter param(String value, UUID companyId) {
        return SystemParameter.builder()
                .id(UUID.randomUUID())
                .parameterKey(KEY)
                .parameterValue(value)
                .parameterType("STRING")
                .category("TRANSACTION")
                .companyId(companyId)
                .isActive(true)
                .build();
    }

    @Test
    @DisplayName("getValue — cég-specifikus sor létezik → azt adja, globált nem kérdez")
    void getValue_companySpecificWins() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.of(param("500000", COMPANY_A)));

            assertThat(service.getValue(KEY)).isEqualTo("500000");
            verify(repo, never()).findByParameterKeyAndCompanyIdIsNull(anyString());
        }
    }

    @Test
    @DisplayName("getValue — nincs cég-sor → globális fallback")
    void getValue_fallsBackToGlobal() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.empty());
            when(repo.findByParameterKeyAndCompanyIdIsNull(KEY))
                    .thenReturn(Optional.of(param("1000000", null)));

            assertThat(service.getValue(KEY)).isEqualTo("1000000");
        }
    }

    @Test
    @DisplayName("cég-specifikus ÉS globális is van → a cég-specifikus nyer")
    void getByKey_companyBeatsGlobal() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.of(param("500000", COMPANY_A)));
            // globál sor is "létezik" a DB-ben, de a service meg sem kérdezi:
            SystemParameter got = service.getByKey(KEY);

            assertThat(got.getParameterValue()).isEqualTo("500000");
            assertThat(got.getCompanyId()).isEqualTo(COMPANY_A);
            verify(repo, never()).findByParameterKeyAndCompanyIdIsNull(anyString());
        }
    }

    @Test
    @DisplayName("egyik sor sincs → getByKey RNF-et dob, getValue(key,default) defaultot ad")
    void missingParameter_semanticsUnchanged() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.empty());
            when(repo.findByParameterKeyAndCompanyIdIsNull(KEY))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.getByKey(KEY))
                    .isInstanceOf(ResourceNotFoundException.class);
            assertThat(service.getValue(KEY, "fallback")).isEqualTo("fallback");
        }
    }

    @Test
    @DisplayName("getValue(key,default) — repo-hiba → log.warn + default (változatlan)")
    void getValueWithDefault_repoError_returnsDefault() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenThrow(new RuntimeException("db down"));

            assertThat(service.getValue(KEY, "safe")).isEqualTo("safe");
        }
    }

    @Test
    @DisplayName("upsert — globál-only: mindig az IS NULL sort frissíti, override-ot sosem")
    void upsert_writesGlobalRowOnly() {
        SystemParameter global = param("1000000", null);
        when(repo.findByParameterKeyAndCompanyIdIsNull(KEY))
                .thenReturn(Optional.of(global));
        when(repo.save(any(SystemParameter.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        SystemParameter saved = service.upsert(KEY, "2000000", "TRANSACTION", null);

        assertThat(saved.getParameterValue()).isEqualTo("2000000");
        assertThat(saved.getCompanyId()).isNull();
        verify(repo, never()).findByParameterKeyAndCompanyId(anyString(), any());
    }

    @Test
    @DisplayName("listAll — csak a globál + aktuális cég paramétereit kéri")
    void listAll_usesVisibleToCurrentCompany() {
        SystemParameter companyParam = param("company", COMPANY_A);
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findAllVisibleTo(COMPANY_A)).thenReturn(List.of(companyParam));

            assertThat(service.listAll()).containsExactly(companyParam);
        }
    }

    @Test
    @DisplayName("listActive — csak a globál + aktuális cég aktív paramétereit kéri")
    void listActive_usesVisibleToCurrentCompany() {
        SystemParameter companyParam = param("company", COMPANY_A);
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findActiveVisibleTo(COMPANY_A)).thenReturn(List.of(companyParam));

            assertThat(service.listActive()).containsExactly(companyParam);
        }
    }

    @Test
    @DisplayName("listByCategory — csak a globál + aktuális cég adott kategóriájú paramétereit kéri")
    void listByCategory_usesVisibleToCurrentCompany() {
        SystemParameter companyParam = param("company", COMPANY_A);
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findByCategoryVisibleTo("TRANSACTION", COMPANY_A)).thenReturn(List.of(companyParam));

            assertThat(service.listByCategory("TRANSACTION")).containsExactly(companyParam);
        }
    }

    @Test
    @DisplayName("upsert — nincs globál sor → create globál (companyId=null) sort hoz létre")
    void upsert_createsGlobalRowWhenMissing() {
        when(repo.findByParameterKeyAndCompanyIdIsNull(KEY))
                .thenReturn(Optional.empty());
        when(repo.save(any(SystemParameter.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        SystemParameter saved = service.upsert(KEY, "42", "TRANSACTION", "desc");

        assertThat(saved.getParameterValue()).isEqualTo("42");
        assertThat(saved.getCompanyId()).isNull();
    }

    @Test
    @DisplayName("getCompanyValue — létező cég-sor értékét adja")
    void getCompanyValue_returnsCompanyScopedValue() {
        when(repo.findByParameterKeyAndCompanyId(KEY, COMPANY_A))
                .thenReturn(Optional.of(param("company-secret", COMPANY_A)));

        assertThat(service.getCompanyValue(KEY, COMPANY_A, "def")).isEqualTo("company-secret");
        verify(repo, never()).findByParameterKeyAndCompanyIdIsNull(anyString());
    }

    @Test
    @DisplayName("getCompanyValue — nincs cég-sor → default, globális fallback nélkül")
    void getCompanyValue_missingCompanyScopedValueReturnsDefaultWithoutGlobalFallback() {
        when(repo.findByParameterKeyAndCompanyId(KEY, COMPANY_A))
                .thenReturn(Optional.empty());

        assertThat(service.getCompanyValue(KEY, COMPANY_A, "def")).isEqualTo("def");
        verify(repo, never()).findByParameterKeyAndCompanyIdIsNull(anyString());
    }

    @Test
    @DisplayName("getCompanyValue — null companyId → default és repo-hívás nélkül fail-closed")
    void getCompanyValue_nullCompanyIdReturnsDefaultWithoutRepoCall() {
        assertThat(service.getCompanyValue(KEY, null, "def")).isEqualTo("def");
        verifyNoInteractions(repo);
    }

    @Test
    @DisplayName("upsertCompanyValue — létező cég-sor frissül és megtartja a companyId-t")
    void upsertCompanyValue_updatesExistingCompanyScopedRow() {
        SystemParameter existing = param("old", COMPANY_A);
        when(repo.findByParameterKeyAndCompanyId(KEY, COMPANY_A))
                .thenReturn(Optional.of(existing));
        when(repo.save(any(SystemParameter.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        SystemParameter saved = service.upsertCompanyValue(KEY, COMPANY_A, "new", "TRANSACTION", "desc");

        assertThat(saved.getParameterValue()).isEqualTo("new");
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_A);
        assertThat(saved.getDescription()).isEqualTo("desc");
    }

    @Test
    @DisplayName("upsertCompanyValue — hiányzó cég-sor létrejön companyId-val")
    void upsertCompanyValue_createsCompanyScopedRowWhenMissing() {
        when(repo.findByParameterKeyAndCompanyId(KEY, COMPANY_A))
                .thenReturn(Optional.empty());
        when(repo.save(any(SystemParameter.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        SystemParameter saved = service.upsertCompanyValue(KEY, COMPANY_A, "new", "COMPLIANCE", "desc");

        assertThat(saved.getParameterKey()).isEqualTo(KEY);
        assertThat(saved.getParameterValue()).isEqualTo("new");
        assertThat(saved.getParameterType()).isEqualTo("STRING");
        assertThat(saved.getCategory()).isEqualTo("COMPLIANCE");
        assertThat(saved.getCompanyId()).isEqualTo(COMPANY_A);
        assertThat(saved.getIsActive()).isTrue();
    }

    @Test
    @DisplayName("upsertCompanyValue — null companyId ValidationException")
    void upsertCompanyValue_nullCompanyIdThrowsValidationException() {
        assertThatThrownBy(() -> service.upsertCompanyValue(KEY, null, "new", "COMPLIANCE", "desc"))
                .isInstanceOf(ValidationException.class);
        verifyNoInteractions(repo);
    }
}
