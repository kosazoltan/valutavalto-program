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

    public List<SystemParameter> listAll() { return repo.findAll(); }
    public List<SystemParameter> listActive() { return repo.findByIsActiveTrue(); }
    public List<SystemParameter> listByCategory(String cat) { return repo.findByCategory(cat); }

    /**
     * TD7: effektív paraméter-lookup. Cég-kontextusban először a cég-specifikus sor
     * (parameter_key + company_id), hiányában a globális (company_id IS NULL).
     * Kontextus nélkül (scheduler/startup/async: getCurrentCompanyIdOrNull() == null)
     * közvetlenül a globális sor.
     */
    private Optional<SystemParameter> findEffective(String key) {
        UUID companyId = SecurityUtils.getCurrentCompanyIdOrNull();
        if (companyId != null) {
            Optional<SystemParameter> scoped = repo.findByParameterKeyAndCompanyId(key, companyId);
            if (scoped.isPresent()) {
                return scoped;
            }
        }
        return repo.findByParameterKeyAndCompanyIdIsNull(key);
    }

    public SystemParameter getByKey(String key) {
        return findEffective(key)
                .orElseThrow(() -> new ResourceNotFoundException("Paraméter nem található: " + key));
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
     * Cég-KIZÁRÓLAGOS olvasás — tenant-titok (pl. compliance címzettek).
     * SOHA nem esik vissza globális sorra; null companyId (nincs kontextus) → default.
     */
    public String getCompanyValue(String key, UUID companyId, String defaultValue) {
        if (companyId == null) {
            return defaultValue;
        }
        return repo.findByParameterKeyAndCompanyId(key, companyId)
                .map(SystemParameter::getParameterValue)
                .filter(v -> v != null && !v.isBlank())
                .orElse(defaultValue);
    }

    @Transactional(rollbackFor = Exception.class)
    public SystemParameter upsert(String key, String value, String category, String description) {
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

    @Transactional(rollbackFor = Exception.class)
    public SystemParameter create(String key, String value, String type, String category, String description) {
        SystemParameter p = SystemParameter.builder()
                .parameterKey(key).parameterValue(value).parameterType(type)
                .category(category).description(description).isActive(true).build();
        return repo.save(p);
    }

    @Transactional(rollbackFor = Exception.class)
    public SystemParameter update(UUID id, String value, String description) {
        SystemParameter p = findOrThrow(id);
        if (value != null) p.setParameterValue(value);
        if (description != null) p.setDescription(description);
        return repo.save(p);
    }

    @Transactional(rollbackFor = Exception.class)
    public SystemParameter toggleActive(UUID id) {
        SystemParameter p = findOrThrow(id);
        p.setIsActive(!p.getIsActive());
        return repo.save(p);
    }

    @Transactional(rollbackFor = Exception.class)
    public void delete(UUID id) { repo.deleteById(id); }

    private SystemParameter findOrThrow(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Paraméter nem található: " + id));
    }
}
