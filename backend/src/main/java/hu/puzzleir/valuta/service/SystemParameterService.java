package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.repository.SystemParameterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SystemParameterService {

    private final SystemParameterRepository repo;

    public List<SystemParameter> listAll() { return repo.findAll(); }
    public List<SystemParameter> listActive() { return repo.findByIsActiveTrue(); }
    public List<SystemParameter> listByCategory(String cat) { return repo.findByCategory(cat); }

    public SystemParameter getByKey(String key) {
        return repo.findByParameterKey(key)
                .orElseThrow(() -> new ResourceNotFoundException("Paraméter nem található: " + key));
    }

    public String getValue(String key) {
        return getByKey(key).getParameterValue();
    }

    @Transactional
    public SystemParameter create(String key, String value, String type, String category, String description) {
        SystemParameter p = SystemParameter.builder()
                .parameterKey(key).parameterValue(value).parameterType(type)
                .category(category).description(description).isActive(true).build();
        return repo.save(p);
    }

    @Transactional
    public SystemParameter update(UUID id, String value, String description) {
        SystemParameter p = findOrThrow(id);
        if (value != null) p.setParameterValue(value);
        if (description != null) p.setDescription(description);
        return repo.save(p);
    }

    @Transactional
    public SystemParameter toggleActive(UUID id) {
        SystemParameter p = findOrThrow(id);
        p.setIsActive(!p.getIsActive());
        return repo.save(p);
    }

    @Transactional
    public void delete(UUID id) { repo.deleteById(id); }

    private SystemParameter findOrThrow(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Paraméter nem található: " + id));
    }
}
