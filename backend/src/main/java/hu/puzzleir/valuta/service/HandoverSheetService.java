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
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return repo.findAllByCompanyId(companyId);
    }

    public HandoverSheet getById(UUID id) {
        HandoverSheet sheet = repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Átadás-átvételi lap nem található: " + id));

        // Multi-tenant IDOR guard (NEW-1): idegen cég átadás-átvételi lapja nem olvasható
        // és nem mutálható (print/complete is ezen át megy). Cross-tenant (vagy hiányzó
        // companyId) → ResourceNotFoundException, hogy a létezés se szivárogjon.
        // Nincs @Scheduled / belső hívó: a HandoverSheetController az egyetlen belépési
        // pont, így a getCurrentCompanyId() mindig bejelentkezett usert kap.
        UUID currentCompanyId = SecurityUtils.getCurrentCompanyId();
        if (sheet.getCompanyId() == null || !sheet.getCompanyId().equals(currentCompanyId)) {
            throw new ResourceNotFoundException("Átadás-átvételi lap nem található: " + id);
        }
        return sheet;
    }

    @Transactional(rollbackFor = Exception.class)
    public HandoverSheet generate(HandoverSheet entity) {
        entity.setId(null);
        entity.setStatus(HandoverSheetStatus.DRAFT);
        entity.setTransferDate(LocalDate.now());
        entity.setCreatedById(SecurityUtils.getCurrentWorkerId());
        entity.setCompanyId(SecurityUtils.getCurrentCompanyId());
        return repo.save(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    public HandoverSheet print(UUID id) {
        HandoverSheet sheet = getById(id);
        sheet.setStatus(HandoverSheetStatus.PRINTED);
        return repo.save(sheet);
    }

    @Transactional(rollbackFor = Exception.class)
    public HandoverSheet complete(UUID id) {
        HandoverSheet sheet = getById(id);
        sheet.setStatus(HandoverSheetStatus.COMPLETED);
        return repo.save(sheet);
    }
}
