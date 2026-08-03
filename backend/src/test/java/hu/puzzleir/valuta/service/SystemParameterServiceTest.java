package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.controller.SystemParameterController;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;
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
    private static final UUID COMPANY_B =
            UUID.fromString("22222222-2222-2222-2222-222222222222");
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
            when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.of(param("500000", COMPANY_A)));

            assertThat(service.getValue(KEY)).isEqualTo("500000");
            verify(repo, never()).findEffectiveGlobalByParameterKey(anyString());
        }
    }

    @Test
    @DisplayName("FK-066/Sourcery: findEffectiveValue — adat-elérési hiba fail-conservative (WARN + empty)")
    void findEffectiveValue_dataAccessErrorYieldsEmpty() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenThrow(new org.springframework.dao.DataAccessResourceFailureException("DB down"));

            assertThat(service.findEffectiveValue(KEY)).isEmpty();
        }
    }

    @Test
    @DisplayName("FK-066/Sourcery: findEffectiveValue — programozási hiba (NPE) TOVÁBB propagál, nem nyelődik el")
    void findEffectiveValue_programmingErrorPropagates() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenThrow(new NullPointerException("programozási hiba"));

            assertThatThrownBy(() -> service.findEffectiveValue(KEY))
                    .isInstanceOf(NullPointerException.class);
        }
    }

    @Test
    @DisplayName("Shipment stale küszöb — az A cég override-ja nem szivárog át a B cégbe")
    void shipmentStaleThresholdOverrideRemainsTenantScoped() {
        String key = ShipmentService.PARAM_STALE_WARNING_HOURS;
        SystemParameter companyOverride = SystemParameter.builder()
                .parameterKey(key)
                .parameterValue("24")
                .companyId(COMPANY_A)
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A, COMPANY_B);
            when(repo.findEffectiveByParameterKeyAndCompanyId(key, COMPANY_A))
                    .thenReturn(Optional.of(companyOverride));
            when(repo.findEffectiveByParameterKeyAndCompanyId(key, COMPANY_B))
                    .thenReturn(Optional.empty());
            when(repo.findEffectiveGlobalByParameterKey(key)).thenReturn(Optional.empty());

            assertThat(service.getValue(key, "48")).isEqualTo("24");
            assertThat(service.getValue(key, "48")).isEqualTo("48");
        }

        verify(repo).findEffectiveByParameterKeyAndCompanyId(key, COMPANY_A);
        verify(repo).findEffectiveByParameterKeyAndCompanyId(key, COMPANY_B);
    }

    @Test
    @DisplayName("getValue — nincs cég-sor → globális fallback")
    void getValue_fallsBackToGlobal() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.empty());
            when(repo.findEffectiveGlobalByParameterKey(KEY))
                    .thenReturn(Optional.of(param("1000000", null)));

            assertThat(service.getValue(KEY)).isEqualTo("1000000");
        }
    }

    @Test
    @DisplayName("cég-specifikus ÉS globális is van → a cég-specifikus nyer")
    void getByKey_companyBeatsGlobal() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.of(param("500000", COMPANY_A)));
            // globál sor is "létezik" a DB-ben, de a service meg sem kérdezi:
            SystemParameter got = service.getByKey(KEY);

            assertThat(got.getParameterValue()).isEqualTo("500000");
            assertThat(got.getCompanyId()).isEqualTo(COMPANY_A);
            verify(repo, never()).findEffectiveGlobalByParameterKey(anyString());
        }
    }

    @Test
    @DisplayName("egyik sor sincs → getByKey RNF-et dob, getValue(key,default) defaultot ad")
    void missingParameter_semanticsUnchanged() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.empty());
            when(repo.findEffectiveGlobalByParameterKey(KEY))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.getByKey(KEY))
                    .isInstanceOf(ResourceNotFoundException.class);
            assertThat(service.getValue(KEY, "fallback")).isEqualTo("fallback");
        }
    }

    @Test
    @DisplayName("getRawValue — a jelen lévő üres értéket nem mossa össze a hiányzó paraméterrel")
    void getRawValue_preservesPresentBlankValue() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.of(param("", COMPANY_A)));

            assertThat(service.getRawValue(KEY, null)).isEmpty();
        }
    }

    @Test
    @DisplayName("getValue(key,default) — repo-hiba → log.warn + default (változatlan)")
    void getValueWithDefault_repoError_returnsDefault() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
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
        when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                .thenReturn(Optional.of(param("company-secret", COMPANY_A)));

        assertThat(service.getCompanyValue(KEY, COMPANY_A, "def")).isEqualTo("company-secret");
        verify(repo, never()).findEffectiveGlobalByParameterKey(anyString());
    }

    @Test
    @DisplayName("getCompanyValue — nincs cég-sor → default, globális fallback nélkül")
    void getCompanyValue_missingCompanyScopedValueReturnsDefaultWithoutGlobalFallback() {
        when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                .thenReturn(Optional.empty());

        assertThat(service.getCompanyValue(KEY, COMPANY_A, "def")).isEqualTo("def");
        verify(repo, never()).findEffectiveGlobalByParameterKey(anyString());
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

    // ── SYSPARAM-IDOR-UPDATE-BYID: by-id mutációk tenant-láthatósága ──

    @Test
    @DisplayName("update — másik cég scoped sora id-ról → RNF, nincs save (IDOR-védelem)")
    void update_crossTenantRowById_throwsRnfWithoutSave() {
        UUID foreignId = UUID.randomUUID();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findVisibleById(foreignId, COMPANY_A)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.update(foreignId, "hacked", null))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("Paraméter nem található: " + foreignId);
            verify(repo).findVisibleById(foreignId, COMPANY_A);
            verify(repo, never()).save(any());
        }
    }

    @Test
    @DisplayName("toggleActive — másik cég scoped sora id-ról → RNF, nincs save")
    void toggleActive_crossTenantRowById_throwsRnfWithoutSave() {
        UUID foreignId = UUID.randomUUID();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findVisibleById(foreignId, COMPANY_A)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.toggleActive(foreignId))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("Paraméter nem található: " + foreignId);
            verify(repo).findVisibleById(foreignId, COMPANY_A);
            verify(repo, never()).save(any());
        }
    }

    @Test
    @DisplayName("delete — másik cég scoped sora id-ról → RNF, se delete se deleteById")
    void delete_crossTenantRowById_throwsRnfWithoutDelete() {
        UUID foreignId = UUID.randomUUID();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findVisibleById(foreignId, COMPANY_A)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.delete(foreignId))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessage("Paraméter nem található: " + foreignId);
            verify(repo).findVisibleById(foreignId, COMPANY_A);
            verify(repo, never()).delete(any(SystemParameter.class));
            verify(repo, never()).deleteById(any());
        }
    }

    @Test
    @DisplayName("update — saját cég sora id-ról frissül")
    void update_ownCompanyRowById_succeeds() {
        SystemParameter own = param("old", COMPANY_A);
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findVisibleById(own.getId(), COMPANY_A)).thenReturn(Optional.of(own));
            when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

            SystemParameter saved = service.update(own.getId(), "new", "desc");

            assertThat(saved.getParameterValue()).isEqualTo("new");
            assertThat(saved.getDescription()).isEqualTo("desc");
            assertThat(saved.getCompanyId()).isEqualTo(COMPANY_A);
        }
    }

    @Test
    @DisplayName("toggleActive — saját cég sora id-ról átbillen")
    void toggleActive_ownCompanyRowById_flips() {
        SystemParameter own = param("v", COMPANY_A); // isActive=true a helperből
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findVisibleById(own.getId(), COMPANY_A)).thenReturn(Optional.of(own));
            when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

            assertThat(service.toggleActive(own.getId()).getIsActive()).isFalse();
        }
    }

    @Test
    @DisplayName("delete — saját cég sora id-ról: repo.delete(entity), sosem deleteById")
    void delete_ownCompanyRowById_deletesEntity() {
        SystemParameter own = param("v", COMPANY_A);
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findVisibleById(own.getId(), COMPANY_A)).thenReturn(Optional.of(own));

            service.delete(own.getId());

            verify(repo).delete(own);
            verify(repo, never()).deleteById(any());
        }
    }

    @Test
    @DisplayName("update — globál sor (companyId=null) cég-adminnak is frissíthető")
    void update_globalRowById_succeedsForCompanyAdmin() {
        SystemParameter global = param("old", null);
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findVisibleById(global.getId(), COMPANY_A)).thenReturn(Optional.of(global));
            when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

            SystemParameter saved = service.update(global.getId(), "new", null);

            assertThat(saved.getParameterValue()).isEqualTo("new");
            assertThat(saved.getCompanyId()).isNull();
        }
    }

    @Test
    @DisplayName("toggleActive — globál sor cég-adminnak is billenthető")
    void toggleActive_globalRowById_flipsForCompanyAdmin() {
        SystemParameter global = param("v", null);
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findVisibleById(global.getId(), COMPANY_A)).thenReturn(Optional.of(global));
            when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));

            assertThat(service.toggleActive(global.getId()).getIsActive()).isFalse();
        }
    }

    @Test
    @DisplayName("delete — globál sor cég-adminnak is törölhető: repo.delete(entity)")
    void delete_globalRowById_deletesEntity() {
        SystemParameter global = param("v", null);
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findVisibleById(global.getId(), COMPANY_A)).thenReturn(Optional.of(global));

            service.delete(global.getId());

            verify(repo).delete(global);
            verify(repo, never()).deleteById(any());
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // is_active-szűrés az EFFEKTÍV lookupon (findEffective + wrapperek,
    // getCompanyValue). Az admin lista- (listAll/listByCategory) és ÍRÁSI utak
    // szándékosan NEM szűrnek: az adminnak látnia és írnia kell az inaktív sort.
    // ─────────────────────────────────────────────────────────────────────────

    /** Inaktivált (is_active=false) sor — az admin a felületen "Inaktív"-ra állította. */
    private SystemParameter inactiveParam(String key, String value, UUID companyId) {
        return SystemParameter.builder()
                .id(UUID.randomUUID())
                .parameterKey(key)
                .parameterValue(value)
                .parameterType("STRING")
                .category("CLOSING")
                .companyId(companyId)
                .isActive(false)
                .build();
    }

    @Test
    @DisplayName("is_active: inaktivált GLOBÁLIS sor nem effektív találat → findEffectiveValue üres")
    void findEffectiveValue_inactiveGlobalRowIsNotEffective() {
        String key = "CLOSING_TOLERANCE_EUR";
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(null);
            when(repo.findEffectiveGlobalByParameterKey(key)).thenReturn(Optional.empty());

            // A ClosingToleranceService az empty-ből tudja, hogy nincs használható sor,
            // és a fallbackra (nem-HUF → 0) esik vissza — nem az inaktivált 5000-re.
            assertThat(service.findEffectiveValue(key)).isEmpty();
        }
    }

    @Test
    @DisplayName("is_active: inaktivált CÉG-override → visszaesés az AKTÍV globális sorra (nem üres)")
    void findEffective_inactiveCompanyOverrideFallsBackToGlobal() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.empty());
            when(repo.findEffectiveGlobalByParameterKey(KEY))
                    .thenReturn(Optional.of(param("1000000", null)));

            assertThat(service.findEffectiveValue(KEY)).contains("1000000");
            assertThat(service.getValue(KEY)).isEqualTo("1000000");
            assertThat(service.getByKey(KEY).getCompanyId()).isNull();
        }
    }

    @Test
    @DisplayName("is_active: inaktivált CÉG-override és nincs globális sor → üres / RNF")
    void findEffective_inactiveCompanyOverrideWithoutGlobalYieldsEmpty() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(COMPANY_A);
            when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                    .thenReturn(Optional.empty());
            when(repo.findEffectiveGlobalByParameterKey(KEY)).thenReturn(Optional.empty());

            assertThat(service.findEffectiveValue(KEY)).isEmpty();
            assertThat(service.getValue(KEY, "fallback")).isEqualTo("fallback");
            assertThatThrownBy(() -> service.getByKey(KEY))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("is_active NULL (nincs kitöltve) → TOVÁBBRA IS érvényes effektív találat")
    void findEffectiveValue_nullIsActiveStillCountsAsActive() {
        SystemParameter legacyRow = SystemParameter.builder()
                .id(UUID.randomUUID())
                .parameterKey(KEY)
                .parameterValue("1000000")
                .parameterType("STRING")
                .category("TRANSACTION")
                .isActive(null)
                .build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(null);
            when(repo.findEffectiveGlobalByParameterKey(KEY)).thenReturn(Optional.of(legacyRow));

            assertThat(service.findEffectiveValue(KEY)).contains("1000000");
            assertThat(service.getValue(KEY)).isEqualTo("1000000");
        }
        // A NULL-tolerancia SQL-szintű bizonyítéka a
        // SystemParameterIsActiveEffectiveLookupPostgresTest (valós PostgreSQL).
    }

    @Test
    @DisplayName("getCompanyValue — inaktivált cég-sor kiesik → default, globális fallback nélkül")
    void getCompanyValue_inactiveRowYieldsDefault() {
        when(repo.findEffectiveByParameterKeyAndCompanyId(KEY, COMPANY_A))
                .thenReturn(Optional.empty());

        assertThat(service.getCompanyValue(KEY, COMPANY_A, "def")).isEqualTo("def");
        verify(repo, never()).findByParameterKeyAndCompanyIdIsNull(anyString());
        verify(repo, never()).findEffectiveGlobalByParameterKey(anyString());
    }

    @Test
    @DisplayName("create — a kérésben küldött isActive=false ténylegesen mentődik (nem mindig true)")
    void create_honoursIsActiveFalseFromRequestBody() {
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));
        SystemParameterController controller = new SystemParameterController(service);

        SystemParameter created = controller.create(Map.of(
                "parameterKey", "RECEIPT_FOOTER_TEXT",
                "parameterValue", "szoveg",
                "parameterType", "STRING",
                "category", "RECEIPT",
                "description", "leiras",
                "isActive", "false")).getBody();

        ArgumentCaptor<SystemParameter> captor = ArgumentCaptor.forClass(SystemParameter.class);
        verify(repo).save(captor.capture());
        assertThat(captor.getValue().getIsActive()).isFalse();
        assertThat(created).isNotNull();
        assertThat(created.getIsActive()).isFalse();
    }

    @Test
    @DisplayName("create — a frontend boolean isActive mezője a Map<String,String> body-ban \"false\"-ként érkezik")
    void createRequestBody_booleanIsActiveDeserializesToStringValue() throws Exception {
        // A SystemParameterPage boolean-t küld ({"isActive": false}); a controller body-ja
        // Map<String,String> — a Jackson scalar→String coercion adja a "false"-t, amit a
        // parseIsActive értelmez. Ez a teszt ezt a (különben néma) feltevést rögzíti.
        Map<String, String> body = new com.fasterxml.jackson.databind.ObjectMapper().readValue(
                "{\"parameterKey\":\"K\",\"isActive\":false}",
                new com.fasterxml.jackson.core.type.TypeReference<Map<String, String>>() { });

        assertThat(body).containsEntry("isActive", "false");
    }

    @Test
    @DisplayName("create — isActive nélküli kérés változatlanul aktív sort hoz létre (API-kontraktus)")
    void create_defaultsToActiveWhenIsActiveAbsent() {
        when(repo.save(any(SystemParameter.class))).thenAnswer(inv -> inv.getArgument(0));
        SystemParameterController controller = new SystemParameterController(service);

        SystemParameter created = controller.create(Map.of(
                "parameterKey", "RECEIPT_FOOTER_TEXT",
                "parameterValue", "szoveg",
                "parameterType", "STRING",
                "category", "RECEIPT")).getBody();

        assertThat(created).isNotNull();
        assertThat(created.getIsActive()).isTrue();
    }
}
