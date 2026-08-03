package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@lombok.extern.slf4j.Slf4j
@RequiredArgsConstructor
public class SystemParameterService {

    private final SystemParameterRepository repo;

    public List<SystemParameter> listAll() { return repo.findAllVisibleTo(SecurityUtils.getCurrentCompanyIdOrNull()); }
    public List<SystemParameter> listActive() { return repo.findActiveVisibleTo(SecurityUtils.getCurrentCompanyIdOrNull()); }
    public List<SystemParameter> listByCategory(String cat) { return repo.findByCategoryVisibleTo(cat, SecurityUtils.getCurrentCompanyIdOrNull()); }

    /**
     * TD7: effektív paraméter-lookup. Cég-kontextusban először a cég-specifikus sor
     * (parameter_key + company_id), hiányában a globális (company_id IS NULL).
     * Kontextus nélkül (scheduler/startup/async: getCurrentCompanyIdOrNull() == null)
     * közvetlenül a globális sor.
     *
     * <p>is_active-szűrés: az admin által "Inaktív"-ra állított sor NEM effektív találat —
     * a lookup a {@code findEffective*} (aktív-szűrt, NULL-toleráns) repository-metódusokon megy.
     * Ha a CÉG-override inaktív, az úgy viselkedik, mintha nem is létezne: a globális sorra
     * esünk vissza (nem üres találat). Az admin lista- és írási utak szándékosan szűretlenek.
     */
    private Optional<SystemParameter> findEffective(String key) {
        UUID companyId = SecurityUtils.getCurrentCompanyIdOrNull();
        if (companyId != null) {
            Optional<SystemParameter> scoped = repo.findEffectiveByParameterKeyAndCompanyId(key, companyId);
            if (scoped.isPresent()) {
                return scoped;
            }
        }
        return repo.findEffectiveGlobalByParameterKey(key);
    }

    public SystemParameter getByKey(String key) {
        return findEffective(key)
                .orElseThrow(() -> new ResourceNotFoundException("Paraméter nem található: " + key));
    }

    /**
     * FK-066 (Codex M1): effektív paraméter-érték a SOR JELENLÉTÉNEK jelzésével —
     * a hívó az Optional.empty()-ből tudja, hogy nincs (használható) sor, és nem az
     * érték/default egyezéséből következtet. Jelen lévő, de null/üres értékű sor
     * szintén empty (használhatatlan konfiguráció → a hívó fallback-ága dönt).
     * Sourcery-fix (PR #1502): CSAK adat-elérési hiba fail-conservative (WARN + empty) —
     * programozási hiba (pl. NPE) tovább propagál, a pénzügyi záráskapunál a széles
     * catch néma default mögé maszkolná a valódi hibát.
     */
    public Optional<String> findEffectiveValue(String key) {
        try {
            return findEffective(key)
                    .map(SystemParameter::getParameterValue)
                    .filter(v -> v != null && !v.isBlank());
        } catch (org.springframework.dao.DataAccessException e) {
            log.warn("SystemParameter effektív lekérés sikertelen, empty-vel térünk vissza: key={}, hiba={}",
                    key, e.getMessage(), e);
            return Optional.empty();
        }
    }

    public String getValue(String key) {
        return getByKey(key).getParameterValue();
    }

    /**
     * Sprint 7.2 CB-016: null-safe getValue overload.
     * Visszaadja a paraméter értékét, vagy a defaultValue-t ha nincs.
     * NEM dob ResourceNotFoundException-t — fallback-barat.
     *
     * @param key          SystemParameter kulcs
     * @param defaultValue ha nincs a paraméter vagy üres érték
     */
    public String getValue(String key, String defaultValue) {
        try {
            SystemParameter p = findEffective(key).orElse(null);
            if (p == null || p.getParameterValue() == null || p.getParameterValue().isBlank()) {
                return defaultValue;
            }
            return p.getParameterValue();
        } catch (Exception e) {
            // Sourcery PR #128 fix: log WARN before fallback, do NOT swallow silently.
            // Misconfigured rates / DB issue elreszett hidden maradhatott volna.
            log.warn("SystemParameter lekeres sikertelen, fallback default: key={}, default={}, hiba={}",
                    key, defaultValue, e.getMessage(), e);
            return defaultValue;
        }
    }

    /**
     * Nyers effektív érték fallbackkel: a hiányzó/null paraméter defaultot ad, de a jelen lévő
     * üres értéket megőrzi, hogy a hívó meg tudja különböztetni a normál hiányt a hibás konfigurációtól.
     */
    public String getRawValue(String key, String defaultValue) {
        try {
            SystemParameter p = findEffective(key).orElse(null);
            return p == null || p.getParameterValue() == null ? defaultValue : p.getParameterValue();
        } catch (Exception e) {
            log.warn("SystemParameter nyers lekeres sikertelen, fallback default: key={}, default={}, hiba={}",
                    key, defaultValue, e.getMessage(), e);
            return defaultValue;
        }
    }

    /**
     * Cég-KIZÁRÓLAGOS olvasás — tenant-titok (pl. compliance címzettek).
     * SOHA nem esik vissza globális sorra; null companyId (nincs kontextus) → default.
     * Az inaktivált sor itt is kiesik (aktív-szűrt lookup) → default.
     */
    public String getCompanyValue(String key, UUID companyId, String defaultValue) {
        if (companyId == null) {
            return defaultValue;
        }
        return repo.findEffectiveByParameterKeyAndCompanyId(key, companyId)
                .map(SystemParameter::getParameterValue)
                .filter(v -> v != null && !v.isBlank())
                .orElse(defaultValue);
    }

    /** FK-067: a záráskori kontroll-lépéseket kapcsoló feature-flagek kulcs-prefixe. */
    static final String FEATURE_KEY_PREFIX = "FEATURE_";

    /** FK-067 (Sourcery): a kezelési díj záráskori ellenőrzését kapcsoló feature-flag kulcsa. */
    static final String FEATURE_HANDLING_FEE_DENOMINATION_KEY =
            FEATURE_KEY_PREFIX + "HANDLING_FEE_DENOMINATION";

    /**
     * Védett pénzügyi kontroll-kulcsok: a GLOBÁLIS (company_id IS NULL) soruk írása minden
     * cég zárási/ellenőrzési viselkedését befolyásolja, ezért ADMIN-only.
     * FK-066 HIGH-fix (Codex): CLOSING_TOLERANCE_*; FK-067 HIGH#1-fix (Codex): FEATURE_*.
     */
    private static final List<String> PROTECTED_FINANCIAL_CONTROL_KEY_PREFIXES =
            List.of(ClosingToleranceService.KEY_PREFIX, FEATURE_KEY_PREFIX);

    /**
     * FK-066 HIGH-fix (Codex), FK-067 HIGH#1-fixszel általánosítva: a GLOBÁLIS
     * (company_id IS NULL) védett pénzügyi kontroll-kulcsok (CLOSING_TOLERANCE_*, FEATURE_*)
     * írása minden cég zárási kapuját befolyásolja, ezért kizárólag ADMIN végezheti —
     * a generikus írási útvonalakon (update/upsert/create/toggleActive/delete) is, nem
     * csak a dedikált ADMIN-controlleren. MANAGER a saját céges override-ot a
     * {@link #upsertCompanyValue} útvonalon továbbra is kezelheti (arra a guard nem
     * vonatkozik). Auth-kontextus nélkül a SecurityUtils dob → fail-closed.
     */
    private void assertGlobalFinancialControlKeyWriteAllowed(String parameterKey, UUID companyId) {
        boolean globalRow = companyId == null;
        boolean protectedKey = parameterKey != null
                && PROTECTED_FINANCIAL_CONTROL_KEY_PREFIXES.stream().anyMatch(parameterKey::startsWith);
        if (globalRow && protectedKey && !SecurityUtils.isAdmin()) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "VV-AUTH-001: a globális " + parameterKey
                            + " védett pénzügyi kontroll-paramétert csak ADMIN módosíthatja; "
                            + "céges felülíráshoz használd a cég-szintű beállítást.");
        }
    }

    @Transactional(rollbackFor = Exception.class)
    public SystemParameter upsert(String key, String value, String category, String description) {
        assertGlobalFinancialControlKeyWriteAllowed(key, null);
        return repo.findByParameterKeyAndCompanyIdIsNull(key)
                .map(p -> {
                    p.setParameterValue(value);
                    if (description != null) p.setDescription(description);
                    return repo.save(p);
                })
                .orElseGet(() -> create(key, value, "STRING", category, description));
    }

    @Transactional(rollbackFor = Exception.class)
    public SystemParameter upsertCompanyValue(String key, UUID companyId, String value,
                                              String category, String description) {
        if (companyId == null) {
            throw new ValidationException("companyId kötelező a cég-scope-olt paraméterhez!");
        }
        return repo.findByParameterKeyAndCompanyId(key, companyId)
                .map(p -> {
                    p.setParameterValue(value);
                    if (description != null) p.setDescription(description);
                    return repo.save(p);
                })
                .orElseGet(() -> repo.save(SystemParameter.builder()
                        .parameterKey(key).parameterValue(value).parameterType("STRING")
                        .category(category).description(description)
                        .companyId(companyId).isActive(true).build()));
    }

    /** Változatlan kontraktus: isActive nélkül a létrejövő sor aktív. */
    @Transactional(rollbackFor = Exception.class)
    public SystemParameter create(String key, String value, String type, String category, String description) {
        return create(key, value, type, category, description, null);
    }

    /**
     * A létrehozó felület "Aktív" jelölőnégyzetét tiszteletben tartó overload: a kérésben
     * küldött isActive értéke ténylegesen mentődik. {@code null} (a mező nincs kitöltve)
     * → aktív sor, hogy a meglévő hívók/API-kontraktus ne változzon.
     */
    @Transactional(rollbackFor = Exception.class)
    public SystemParameter create(String key, String value, String type, String category,
                                  String description, Boolean isActive) {
        assertGlobalFinancialControlKeyWriteAllowed(key, null);
        SystemParameter p = SystemParameter.builder()
                .parameterKey(key).parameterValue(value).parameterType(type)
                .category(category).description(description)
                .isActive(isActive == null ? Boolean.TRUE : isActive).build();
        return repo.save(p);
    }

    @Transactional(rollbackFor = Exception.class)
    public SystemParameter update(UUID id, String value, String description) {
        SystemParameter p = findOrThrow(id);
        assertGlobalFinancialControlKeyWriteAllowed(p.getParameterKey(), p.getCompanyId());
        if (value != null) p.setParameterValue(value);
        if (description != null) p.setDescription(description);
        return repo.save(p);
    }

    @Transactional(rollbackFor = Exception.class)
    public SystemParameter toggleActive(UUID id) {
        SystemParameter p = findOrThrow(id);
        assertGlobalFinancialControlKeyWriteAllowed(p.getParameterKey(), p.getCompanyId());
        p.setIsActive(!p.getIsActive());
        return repo.save(p);
    }

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) {
        SystemParameter p = findOrThrow(id);
        assertGlobalFinancialControlKeyWriteAllowed(p.getParameterKey(), p.getCompanyId());
        repo.delete(p);
    }

    private SystemParameter findOrThrow(UUID id) {
        return repo.findVisibleById(id, SecurityUtils.getCurrentCompanyIdOrNull())
                .orElseThrow(() -> new ResourceNotFoundException("Paraméter nem található: " + id));
    }
}
