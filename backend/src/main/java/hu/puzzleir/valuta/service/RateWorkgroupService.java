package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.entity.RateWorkgroup;
import hu.puzzleir.valuta.repository.RateWorkgroupRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class RateWorkgroupService {

    private final RateWorkgroupRepository workgroupRepository;

    @Transactional(readOnly = true)
    public List<RateWorkgroup> getAllActive() {
        return workgroupRepository.findByActiveTrue();
    }

    @Transactional(readOnly = true)
    public List<RateWorkgroup> getAll() {
        return workgroupRepository.findAll();
    }

    @Transactional(readOnly = true)
    public RateWorkgroup getById(UUID id) {
        return workgroupRepository.findById(id)
                .orElseThrow(() -> new ValidationException("Munkacsoport nem található: " + id));
    }

    @Transactional
    public RateWorkgroup create(RateWorkgroup workgroup) {
        if (workgroupRepository.findByCode(workgroup.getCode()).isPresent()) {
            throw new ValidationException("Már létezik munkacsoport ezzel a kóddal: " + workgroup.getCode());
        }
        RateWorkgroup saved = workgroupRepository.save(workgroup);
        log.info("Munkacsoport létrehozva: {} ({})", saved.getName(), saved.getCode());
        return saved;
    }

    @Transactional
    public RateWorkgroup update(UUID id, RateWorkgroup update) {
        RateWorkgroup existing = getById(id);
        existing.setName(update.getName());
        existing.setActive(update.getActive());
        return workgroupRepository.save(existing);
    }
}
