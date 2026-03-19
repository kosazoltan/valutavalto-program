package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.checklist.DailyChecklistDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DailyChecklistItemRepository;
import hu.puzzleir.valuta.repository.DailyChecklistRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DailyChecklistServiceTest {

    @Mock
    private DailyChecklistRepository checklistRepository;

    @Mock
    private DailyChecklistItemRepository checklistItemRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private CompanyRepository companyRepository;

    @InjectMocks
    private DailyChecklistService service;

    private final UUID companyId = UUID.randomUUID();
    private final UUID branchId = UUID.randomUUID();
    private final Long workerId = 101L;
    private Company company;
    private Branch branch;

    @BeforeEach
    void setupSecurityContext() {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("ADMIN", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(workerId, companyId, branchId, "CASHIER"));
        SecurityContextHolder.getContext().setAuthentication(auth);

        company = Company.builder().id(companyId).code("EBC").name("EBC Kft.").build();
        branch = Branch.builder().id(branchId).code("B01").name("Központ").company(company).build();
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("createChecklist - 19 tétellel hozza létre")
    void createChecklist_creates19Items() {
        LocalDate date = LocalDate.of(2026, 3, 19);

        when(checklistRepository.existsByBranchIdAndChecklistDateAndCompanyId(branchId, date, companyId))
                .thenReturn(false);
        when(companyRepository.findById(companyId)).thenReturn(Optional.of(company));
        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(checklistRepository.save(any(DailyChecklist.class))).thenAnswer(inv -> {
            DailyChecklist cl = inv.getArgument(0);
            cl.setId(UUID.randomUUID());
            cl.setCreatedAt(LocalDateTime.now());
            return cl;
        });

        DailyChecklistDto result = service.createChecklist(branchId, date);

        assertNotNull(result);
        assertEquals("OPEN", result.getStatus());
        assertEquals(19, result.getItems().size());
        assertEquals(branchId, result.getBranchId());
        assertEquals(date, result.getChecklistDate());

        // Ellenőrizzük az első és utolsó tételt
        assertEquals(1, result.getItems().get(0).getItemNumber());
        assertEquals("Pénztárgép indítás és üzemkész állapot ellenőrzése",
                result.getItems().get(0).getItemTitle());
        assertEquals(19, result.getItems().get(18).getItemNumber());
        assertEquals("Napi működési napló megnyitása",
                result.getItems().get(18).getItemTitle());

        // Egyik sem kipipálva
        assertTrue(result.getItems().stream().noneMatch(DailyChecklistDto -> DailyChecklistDto.isChecked()));

        verify(checklistRepository).save(any(DailyChecklist.class));
    }

    @Test
    @DisplayName("createChecklist - duplikáció esetén hibát dob")
    void createChecklist_throwsOnDuplicate() {
        LocalDate date = LocalDate.of(2026, 3, 19);

        when(checklistRepository.existsByBranchIdAndChecklistDateAndCompanyId(branchId, date, companyId))
                .thenReturn(true);

        assertThrows(ValidationException.class, () -> service.createChecklist(branchId, date));
    }

    @Test
    @DisplayName("getChecklist - meglévőt adja vissza ha létezik")
    void getChecklist_returnsExisting() {
        LocalDate date = LocalDate.of(2026, 3, 19);
        DailyChecklist existing = buildChecklist(date, "OPEN");

        when(checklistRepository.findByBranchIdAndChecklistDateAndCompanyId(branchId, date, companyId))
                .thenReturn(Optional.of(existing));

        DailyChecklistDto result = service.getChecklist(branchId, date);

        assertNotNull(result);
        assertEquals("OPEN", result.getStatus());
        verify(checklistRepository, never()).save(any());
    }

    @Test
    @DisplayName("checkItem - kipipál egy tételt")
    void checkItem_checksAnItem() {
        UUID checklistId = UUID.randomUUID();
        DailyChecklist checklist = buildChecklist(LocalDate.now(), "OPEN");
        checklist.setId(checklistId);

        DailyChecklistItem item = checklist.getItems().get(0); // item #1

        when(checklistRepository.findById(checklistId)).thenReturn(Optional.of(checklist));
        when(checklistItemRepository.findByChecklistIdAndItemNumber(checklistId, 1))
                .thenReturn(Optional.of(item));
        when(checklistItemRepository.save(any(DailyChecklistItem.class))).thenAnswer(inv -> inv.getArgument(0));

        DailyChecklistDto result = service.checkItem(checklistId, 1, true, "OK");

        assertNotNull(result);
        assertTrue(item.isChecked());
        assertNotNull(item.getCheckedAt());
        assertEquals(workerId, item.getCheckedByWorkerId());
        assertEquals("OK", item.getNotes());
    }

    @Test
    @DisplayName("checkItem - lezárt checklistnél hibát dob")
    void checkItem_throwsWhenCompleted() {
        UUID checklistId = UUID.randomUUID();
        DailyChecklist checklist = buildChecklist(LocalDate.now(), "COMPLETED");
        checklist.setId(checklistId);

        when(checklistRepository.findById(checklistId)).thenReturn(Optional.of(checklist));

        assertThrows(ValidationException.class,
                () -> service.checkItem(checklistId, 1, true, null));
    }

    @Test
    @DisplayName("checkItem - érvénytelen tételszámnál hibát dob")
    void checkItem_throwsOnInvalidItemNumber() {
        UUID checklistId = UUID.randomUUID();
        DailyChecklist checklist = buildChecklist(LocalDate.now(), "OPEN");
        checklist.setId(checklistId);

        when(checklistRepository.findById(checklistId)).thenReturn(Optional.of(checklist));

        assertThrows(ValidationException.class,
                () -> service.checkItem(checklistId, 20, true, null));
        assertThrows(ValidationException.class,
                () -> service.checkItem(checklistId, 0, true, null));
    }

    @Test
    @DisplayName("completeChecklist - sikeresen lezár ha mind kipipálva")
    void completeChecklist_completesWhenAllChecked() {
        UUID checklistId = UUID.randomUUID();
        DailyChecklist checklist = buildChecklist(LocalDate.now(), "OPEN");
        checklist.setId(checklistId);
        // Mind a 19 tételt kipipáljuk
        checklist.getItems().forEach(item -> item.setChecked(true));

        when(checklistRepository.findById(checklistId)).thenReturn(Optional.of(checklist));
        when(checklistRepository.save(any(DailyChecklist.class))).thenAnswer(inv -> inv.getArgument(0));

        DailyChecklistDto result = service.completeChecklist(checklistId);

        assertEquals("COMPLETED", result.getStatus());
        assertNotNull(result.getCompletedAt());
    }

    @Test
    @DisplayName("completeChecklist - hibát dob ha van kipipálatlan tétel")
    void completeChecklist_throwsWhenUncheckedItems() {
        UUID checklistId = UUID.randomUUID();
        DailyChecklist checklist = buildChecklist(LocalDate.now(), "OPEN");
        checklist.setId(checklistId);
        // Csak az elsőt kipipáljuk
        checklist.getItems().get(0).setChecked(true);

        when(checklistRepository.findById(checklistId)).thenReturn(Optional.of(checklist));

        ValidationException ex = assertThrows(ValidationException.class,
                () -> service.completeChecklist(checklistId));
        assertTrue(ex.getMessage().contains("18")); // 18 kipipálatlan
    }

    @Test
    @DisplayName("completeChecklist - már lezárt checklistnél hibát dob")
    void completeChecklist_throwsWhenAlreadyCompleted() {
        UUID checklistId = UUID.randomUUID();
        DailyChecklist checklist = buildChecklist(LocalDate.now(), "COMPLETED");
        checklist.setId(checklistId);

        when(checklistRepository.findById(checklistId)).thenReturn(Optional.of(checklist));

        assertThrows(ValidationException.class,
                () -> service.completeChecklist(checklistId));
    }

    @Test
    @DisplayName("isChecklistCompleted - true ha COMPLETED")
    void isChecklistCompleted_trueWhenCompleted() {
        LocalDate date = LocalDate.now();
        DailyChecklist checklist = buildChecklist(date, "COMPLETED");

        when(checklistRepository.findByBranchIdAndChecklistDateAndCompanyId(branchId, date, companyId))
                .thenReturn(Optional.of(checklist));

        assertTrue(service.isChecklistCompleted(branchId, date));
    }

    @Test
    @DisplayName("isChecklistCompleted - false ha OPEN")
    void isChecklistCompleted_falseWhenOpen() {
        LocalDate date = LocalDate.now();
        DailyChecklist checklist = buildChecklist(date, "OPEN");

        when(checklistRepository.findByBranchIdAndChecklistDateAndCompanyId(branchId, date, companyId))
                .thenReturn(Optional.of(checklist));

        assertFalse(service.isChecklistCompleted(branchId, date));
    }

    @Test
    @DisplayName("isChecklistCompleted - false ha nem létezik")
    void isChecklistCompleted_falseWhenNotExists() {
        LocalDate date = LocalDate.now();

        when(checklistRepository.findByBranchIdAndChecklistDateAndCompanyId(branchId, date, companyId))
                .thenReturn(Optional.empty());

        assertFalse(service.isChecklistCompleted(branchId, date));
    }

    @Test
    @DisplayName("checkItem - más cég checklistjéhez nem fér hozzá")
    void checkItem_throwsOnDifferentCompany() {
        UUID checklistId = UUID.randomUUID();
        Company otherCompany = Company.builder().id(UUID.randomUUID()).code("OTHER").name("Other").build();
        DailyChecklist checklist = buildChecklist(LocalDate.now(), "OPEN");
        checklist.setId(checklistId);
        checklist.setCompany(otherCompany);

        when(checklistRepository.findById(checklistId)).thenReturn(Optional.of(checklist));

        assertThrows(ValidationException.class,
                () -> service.checkItem(checklistId, 1, true, null));
    }

    // ============ Helper ============

    private DailyChecklist buildChecklist(LocalDate date, String status) {
        DailyChecklist checklist = DailyChecklist.builder()
                .id(UUID.randomUUID())
                .company(company)
                .branch(branch)
                .checklistDate(date)
                .workerId(workerId)
                .status(status)
                .completedAt("COMPLETED".equals(status) ? LocalDateTime.now() : null)
                .createdAt(LocalDateTime.now())
                .items(new ArrayList<>())
                .build();

        String[][] titles = {
                {"Pénztárgép indítás és üzemkész állapot ellenőrzése", ""},
                {"Bizonylattömbök meglétének ellenőrzése", ""},
                {"Nyitó pénzkészlet felvétele és egyeztetése", ""},
                {"Árfolyamtábla frissítése és kihelyezése", ""},
                {"LED kijelző működésének ellenőrzése", ""},
                {"Ügyfélszolgálati információk kihelyezése", ""},
                {"Bankjegy-vizsgáló gép üzemkész állapota", ""},
                {"Biztonsági berendezések működésének ellenőrzése", ""},
                {"Páncélszekrény / értéktár leltár", ""},
                {"Pénzmosás elleni (AML) napi frissítés", ""},
                {"Western Union rendszer elérhetősége", ""},
                {"POS terminál üzemkész állapota", ""},
                {"Hírközlő eszközök működése (telefon, internet)", ""},
                {"Tűzvédelmi eszközök ellenőrzése", ""},
                {"Takarítás és rend ellenőrzése", ""},
                {"Nyitvatartási idő kihelyezése", ""},
                {"Panaszkönyv elérhetősége", ""},
                {"MNB tájékoztató kifüggesztése", ""},
                {"Napi működési napló megnyitása", ""}
        };

        for (int i = 0; i < 19; i++) {
            DailyChecklistItem item = DailyChecklistItem.builder()
                    .id(UUID.randomUUID())
                    .checklist(checklist)
                    .itemNumber(i + 1)
                    .itemTitle(titles[i][0])
                    .itemDescription(titles[i][1])
                    .checked(false)
                    .build();
            checklist.getItems().add(item);
        }

        return checklist;
    }
}
