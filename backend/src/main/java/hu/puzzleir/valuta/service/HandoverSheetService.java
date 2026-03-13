package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.HandoverSheet;
import hu.puzzleir.valuta.entity.HandoverSheetStatus;
import hu.puzzleir.valuta.repository.HandoverSheetRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HandoverSheetService {

    private final HandoverSheetRepository repo;

    public List<HandoverSheet> listAll() {
        return repo.findAll();
    }

    public HandoverSheet getById(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Átadás-átvételi lap nem található: " + id));
    }

    @Transactional
    public HandoverSheet generate(HandoverSheet entity) {
        entity.setId(null);
        entity.setStatus(HandoverSheetStatus.DRAFT);
        entity.setTransferDate(LocalDate.now());
        entity.setCreatedById(SecurityUtils.getCurrentWorkerId());
        return repo.save(entity);
    }

    @Transactional
    public HandoverSheet print(UUID id) {
        HandoverSheet sheet = getById(id);
        sheet.setStatus(HandoverSheetStatus.PRINTED);
        return repo.save(sheet);
    }

    @Transactional
    public HandoverSheet complete(UUID id) {
        HandoverSheet sheet = getById(id);
        sheet.setStatus(HandoverSheetStatus.COMPLETED);
        return repo.save(sheet);
    }
}
