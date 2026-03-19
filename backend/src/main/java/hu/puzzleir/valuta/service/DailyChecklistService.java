package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.checklist.DailyChecklistDto;
import hu.puzzleir.valuta.dto.checklist.DailyChecklistItemDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DailyChecklist;
import hu.puzzleir.valuta.entity.DailyChecklistItem;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DailyChecklistItemRepository;
import hu.puzzleir.valuta.repository.DailyChecklistRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Napi nyitási checklist szolgáltatás (legacy: CHECKLST.DLL).
 *
 * 19 tételes ellenőrzőlista amit a pénztáros minden nap kitölt nyitáskor.
 * A napzárás csak akkor engedélyezett, ha a checklist COMPLETED státuszú.
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class DailyChecklistService {

    private final DailyChecklistRepository checklistRepository;
    private final DailyChecklistItemRepository checklistItemRepository;
    private final BranchRepository branchRepository;
    private final CompanyRepository companyRepository;

    /**
     * A 19 kötelező checklist tétel — legacy CHECKLST.DLL 1:1 megfeleltetés.
     */
    private static final String[][] DEFAULT_ITEMS = {
            {"Pénztárgép indítás és üzemkész állapot ellenőrzése",
                    "A pénztárgép bekapcsolása, inicializálás, teszt bizonylat nyomtatása."},
            {"Bizonylattömbök meglétének ellenőrzése",
                    "Vételi/eladási/átváltási bizonylatok, nyugták, számlák készletének ellenőrzése."},
            {"Nyitó pénzkészlet felvétele és egyeztetése",
                    "Páncélszekrényből kivett pénzkészlet egyeztetése az előző napi záró egyenleggel."},
            {"Árfolyamtábla frissítése és kihelyezése",
                    "Aktuális napi árfolyamok kiírása az ügyféltéri táblára."},
            {"LED kijelző működésének ellenőrzése",
                    "Elektronikus árfolyam-kijelző tábla működésének és adatainak ellenőrzése."},
            {"Ügyfélszolgálati információk kihelyezése",
                    "Panaszkezelési tájékoztató, ÁSZF, díjszabás kifüggesztése."},
            {"Bankjegy-vizsgáló gép üzemkész állapota",
                    "UV/IR/MG bankjegy-ellenőrző készülék tesztelése és kalibrálása."},
            {"Biztonsági berendezések működésének ellenőrzése",
                    "Kamerák, riasztó, pánikgomb, beléptetőrendszer működésének ellenőrzése."},
            {"Páncélszekrény / értéktár leltár",
                    "Értéktárban tárolt készpénz, értéktárgyak tételes leltározása."},
            {"Pénzmosás elleni (AML) napi frissítés",
                    "Szankciós listák frissítése, AML rendszer elérhetőségének ellenőrzése."},
            {"Western Union rendszer elérhetősége",
                    "WU online rendszer bejelentkezés, kapcsolat tesztelése."},
            {"POS terminál üzemkész állapota",
                    "Bankkártya terminál bekapcsolása és kommunikáció tesztelése."},
            {"Hírközlő eszközök működése (telefon, internet)",
                    "Vezetékes/mobil telefon, internet kapcsolat ellenőrzése."},
            {"Tűzvédelmi eszközök ellenőrzése",
                    "Tűzoltó készülék, füstérzékelő, menekülési útvonal ellenőrzése."},
            {"Takarítás és rend ellenőrzése",
                    "Ügyféltér, pénztárfülke, iroda tisztaságának ellenőrzése."},
            {"Nyitvatartási idő kihelyezése",
                    "Nyitvatartási rend kifüggesztése a bejáratnál."},
            {"Panaszkönyv elérhetősége",
                    "Vásárlók könyve / panaszkönyv hozzáférhetőségének biztosítása."},
            {"MNB tájékoztató kifüggesztése",
                    "Magyar Nemzeti Bank felügyeleti tájékoztatójának kifüggesztése."},
            {"Napi működési napló megnyitása",
                    "Működési napló megnyitása, előző napi bejegyzések áttekintése."}
    };

    /**
     * Checklist létrehozása a 19 alapértelmezett tétellel.
     */
    public DailyChecklistDto createChecklist(UUID branchId, LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        // Duplikáció ellenőrzés
        if (checklistRepository.existsByBranchIdAndChecklistDateAndCompanyId(branchId, date, companyId)) {
            throw new ValidationException("Erre a napra már létezik checklist ennél a fióknál!");
        }

        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ValidationException("Ismeretlen cég: " + companyId));
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ValidationException("Ismeretlen fiók: " + branchId));

        // Multi-tenant ellenőrzés
        if (!branch.getCompany().getId().equals(companyId)) {
            throw new ValidationException("A fiók nem tartozik az aktuális céghez!");
        }

        DailyChecklist checklist = DailyChecklist.builder()
                .company(company)
                .branch(branch)
                .checklistDate(date)
                .workerId(workerId)
                .status("OPEN")
                .build();

        // 19 tétel hozzáadása
        for (int i = 0; i < DEFAULT_ITEMS.length; i++) {
            DailyChecklistItem item = DailyChecklistItem.builder()
                    .checklist(checklist)
                    .itemNumber(i + 1)
                    .itemTitle(DEFAULT_ITEMS[i][0])
                    .itemDescription(DEFAULT_ITEMS[i][1])
                    .checked(false)
                    .build();
            checklist.getItems().add(item);
        }

        checklist = checklistRepository.save(checklist);
        log.info("Napi checklist létrehozva: branch={}, date={}, worker={}", branchId, date, workerId);
        return toDto(checklist);
    }

    /**
     * Checklist lekérése — ha még nem létezik, automatikusan létrehozza.
     */
    public DailyChecklistDto getChecklist(UUID branchId, LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        return checklistRepository
                .findByBranchIdAndChecklistDateAndCompanyId(branchId, date, companyId)
                .map(this::toDto)
                .orElseGet(() -> createChecklist(branchId, date));
    }

    /**
     * Tétel kipipálása / visszavonása.
     */
    public DailyChecklistDto checkItem(UUID checklistId, int itemNumber, boolean checked, String notes) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();

        DailyChecklist checklist = checklistRepository.findById(checklistId)
                .orElseThrow(() -> new ValidationException("Checklist nem található: " + checklistId));

        // Multi-tenant ellenőrzés
        if (!checklist.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Hozzáférés megtagadva!");
        }

        if ("COMPLETED".equals(checklist.getStatus())) {
            throw new ValidationException("A checklist már lezárt, nem módosítható!");
        }

        if (itemNumber < 1 || itemNumber > 19) {
            throw new ValidationException("Érvénytelen tételszám: " + itemNumber + " (1-19 között kell lennie)");
        }

        DailyChecklistItem item = checklistItemRepository
                .findByChecklistIdAndItemNumber(checklistId, itemNumber)
                .orElseThrow(() -> new ValidationException(
                        "Checklist tétel nem található: #" + itemNumber));

        item.setChecked(checked);
        item.setCheckedAt(checked ? LocalDateTime.now() : null);
        item.setCheckedByWorkerId(checked ? workerId : null);
        item.setNotes(notes);
        checklistItemRepository.save(item);

        log.info("Checklist tétel frissítve: checklistId={}, item={}, checked={}", checklistId, itemNumber, checked);
        return toDto(checklist);
    }

    /**
     * Checklist lezárása — csak ha mind a 19 tétel kipipálva.
     */
    public DailyChecklistDto completeChecklist(UUID checklistId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        DailyChecklist checklist = checklistRepository.findById(checklistId)
                .orElseThrow(() -> new ValidationException("Checklist nem található: " + checklistId));

        // Multi-tenant ellenőrzés
        if (!checklist.getCompany().getId().equals(companyId)) {
            throw new ValidationException("Hozzáférés megtagadva!");
        }

        if ("COMPLETED".equals(checklist.getStatus())) {
            throw new ValidationException("A checklist már lezárt!");
        }

        // Mind a 19 tételnek kipipáltnak kell lennie
        long uncheckedCount = checklist.getItems().stream()
                .filter(item -> !item.isChecked())
                .count();

        if (uncheckedCount > 0) {
            throw new ValidationException(
                    "Nem lehet lezárni: " + uncheckedCount + " tétel még nincs kipipálva!");
        }

        checklist.setStatus("COMPLETED");
        checklist.setCompletedAt(LocalDateTime.now());
        checklist = checklistRepository.save(checklist);

        log.info("Napi checklist lezárva: checklistId={}, branch={}, date={}",
                checklistId, checklist.getBranch().getId(), checklist.getChecklistDate());
        return toDto(checklist);
    }

    /**
     * Ellenőrzi, hogy az adott napi checklist COMPLETED státuszú-e.
     * Napzárás validációhoz használjuk.
     */
    @Transactional(readOnly = true)
    public boolean isChecklistCompleted(UUID branchId, LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return checklistRepository
                .findByBranchIdAndChecklistDateAndCompanyId(branchId, date, companyId)
                .map(cl -> "COMPLETED".equals(cl.getStatus()))
                .orElse(false);
    }

    // ============ Mapping ============

    private DailyChecklistDto toDto(DailyChecklist entity) {
        return DailyChecklistDto.builder()
                .id(entity.getId())
                .branchId(entity.getBranch().getId())
                .checklistDate(entity.getChecklistDate())
                .workerId(entity.getWorkerId())
                .status(entity.getStatus())
                .completedAt(entity.getCompletedAt())
                .createdAt(entity.getCreatedAt())
                .items(entity.getItems().stream().map(this::toItemDto).toList())
                .build();
    }

    private DailyChecklistItemDto toItemDto(DailyChecklistItem entity) {
        return DailyChecklistItemDto.builder()
                .itemNumber(entity.getItemNumber())
                .itemTitle(entity.getItemTitle())
                .itemDescription(entity.getItemDescription())
                .checked(entity.isChecked())
                .checkedAt(entity.getCheckedAt())
                .checkedByWorkerId(entity.getCheckedByWorkerId())
                .notes(entity.getNotes())
                .build();
    }
}
