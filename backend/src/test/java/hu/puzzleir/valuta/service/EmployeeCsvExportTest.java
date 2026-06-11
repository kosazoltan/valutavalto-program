package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Employee;
import hu.puzzleir.valuta.entity.EmployeeOccupationalHealth;
import hu.puzzleir.valuta.entity.EmployeeVacation;
import hu.puzzleir.valuta.repository.EmployeeChildRepository;
import hu.puzzleir.valuta.repository.EmployeeOccupationalHealthRepository;
import hu.puzzleir.valuta.repository.EmployeeRepository;
import hu.puzzleir.valuta.repository.EmployeeVacationRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

/**
 * CSV export tesztek — multi-tenant company-szűrés + CSV-injection védelem (NFR-03).
 */
@ExtendWith(MockitoExtension.class)
class EmployeeCsvExportTest {

    @Mock private EmployeeRepository employeeRepository;
    @Mock private EmployeeOccupationalHealthRepository occupationalHealthRepository;
    @Mock private EmployeeVacationRepository vacationRepository;
    @Mock private EmployeeChildRepository childRepository;

    @InjectMocks
    private EmployeeSubRecordService service;

    private final UUID companyId = UUID.randomUUID();

    private Employee employee(String lastName, String firstName) {
        Company company = new Company();
        company.setId(companyId);
        Employee e = new Employee();
        e.setId(1L);
        e.setLastName(lastName);
        e.setFirstName(firstName);
        e.setCompany(company);
        return e;
    }

    // ── Üzemorvosi export: company-szűrés ──

    @Test
    @DisplayName("exportOccupationalHealthCsv — csak az aktuális cég rekordjait adja vissza")
    void exportOccupationalHealth_companyScoped() {
        EmployeeOccupationalHealth rec = EmployeeOccupationalHealth.builder()
                .id(1L)
                .employee(employee("Kovács", "Péter"))
                .status("Lezárt")
                .examDate(LocalDate.of(2026, 3, 15))
                .result("Alkalmas")
                .build();
        when(occupationalHealthRepository.findAllByCompanyId(companyId)).thenReturn(List.of(rec));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            String csv = service.exportOccupationalHealthCsv();
            assertThat(csv).contains("Kovács Péter");
            assertThat(csv).contains("Lezárt");
            assertThat(csv).contains("Alkalmas");
            // Fejléc jelen van
            assertThat(csv).contains("Dolgozó neve;Státusz");
            // BOM jelen van
            assertThat(csv.charAt(0)).isEqualTo('\uFEFF');
        }
        // Csak a cég rekordjait kérdezte le (nem más céget)
        verify(occupationalHealthRepository).findAllByCompanyId(companyId);
        verify(occupationalHealthRepository, never()).findAll();
    }

    @Test
    @DisplayName("exportOccupationalHealthCsv — üres lista esetén csak fejléc és BOM")
    void exportOccupationalHealth_emptyList() {
        when(occupationalHealthRepository.findAllByCompanyId(companyId)).thenReturn(List.of());
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            String csv = service.exportOccupationalHealthCsv();
            long lineCount = csv.lines().count();
            assertThat(lineCount).isEqualTo(1); // csak fejlécsor
        }
    }

    // ── Szabadság export: company-szűrés ──

    @Test
    @DisplayName("exportVacationsCsv — csak az aktuális cég rekordjait adja vissza")
    void exportVacations_companyScoped() {
        EmployeeVacation vac = EmployeeVacation.builder()
                .id(2L)
                .employee(employee("Nagy", "Anna"))
                .year(2026)
                .broughtForward(3)
                .vacationDays(20)
                .sickLeaveDays(5)
                .takenVacation(8)
                .takenSickLeave(2)
                .sickPayDays(1)
                .unpaidLeaveDays(0)
                .build();
        when(vacationRepository.findAllByCompanyId(companyId)).thenReturn(List.of(vac));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            String csv = service.exportVacationsCsv();
            assertThat(csv).contains("Nagy Anna");
            assertThat(csv).contains("2026");
            assertThat(csv).contains("20");
            assertThat(csv).contains("Dolgozó neve;Év");
            assertThat(csv.charAt(0)).isEqualTo('\uFEFF');
        }
        verify(vacationRepository).findAllByCompanyId(companyId);
        verify(vacationRepository, never()).findAll();
    }

    // ── CSV-injection védelem ──

    @Test
    @DisplayName("CSV-injection: = karakterrel kezdődő cella elé aposztróf kerül")
    void csvInjection_equalsPrefix() {
        String escaped = CsvUtils.escapeCsvCell("=SUM(A1:A10)");
        assertThat(escaped).isEqualTo("'=SUM(A1:A10)");
    }

    @Test
    @DisplayName("CSV-injection: + karakterrel kezdődő cella elé aposztróf kerül")
    void csvInjection_plusPrefix() {
        assertThat(CsvUtils.escapeCsvCell("+cmd")).isEqualTo("'+cmd");
    }

    @Test
    @DisplayName("CSV-injection: - karakterrel kezdődő cella elé aposztróf kerül")
    void csvInjection_minusPrefix() {
        assertThat(CsvUtils.escapeCsvCell("-1+1")).isEqualTo("'-1+1");
    }

    @Test
    @DisplayName("CSV-injection: @ karakterrel kezdődő cella elé aposztróf kerül")
    void csvInjection_atPrefix() {
        assertThat(CsvUtils.escapeCsvCell("@SUM")).isEqualTo("'@SUM");
    }

    @Test
    @DisplayName("CSV-injection: normál szöveg nem módosul")
    void csvInjection_normalText() {
        assertThat(CsvUtils.escapeCsvCell("Kovács Péter")).isEqualTo("Kovács Péter");
    }

    @Test
    @DisplayName("CSV-injection: null értéket üres stringgé alakítja")
    void csvInjection_null() {
        assertThat(CsvUtils.escapeCsvCell(null)).isEmpty();
    }

    @Test
    @DisplayName("CSV-injection (review #1088): vezető whitespace/tab utáni képlet is védett")
    void csvInjection_leadingWhitespace() {
        assertThat(CsvUtils.escapeCsvCell(" =SUM(A1)")).isEqualTo("' =SUM(A1)");
        assertThat(CsvUtils.escapeCsvCell("\t=SUM(A1)")).startsWith("'");
    }

    @Test
    @DisplayName("RFC 4180 (review #1088): elválasztó/idézőjel/sortörés idézést kap")
    void rfc4180_quoting() {
        assertThat(CsvUtils.escapeCsvCell("Kovács; Péter")).isEqualTo("\"Kovács; Péter\"");
        assertThat(CsvUtils.escapeCsvCell("idéz\"őjel")).isEqualTo("\"idéz\"\"őjel\"");
        assertThat(CsvUtils.escapeCsvCell("több\nsor")).isEqualTo("\"több\nsor\"");
        // kombinált: injection-prefix + idézés
        assertThat(CsvUtils.escapeCsvCell("=1;2")).isEqualTo("\"'=1;2\"");
    }

    @Test
    @DisplayName("exportOccupationalHealthCsv — orvosi rekord =injection tartalmú eredménnyel védett")
    void exportOccupationalHealth_injectionInResult() {
        EmployeeOccupationalHealth rec = EmployeeOccupationalHealth.builder()
                .id(3L)
                .employee(employee("Teszt", "Elek"))
                .status("Lezárt")
                .result("=HYPERLINK(\"http://evil.com\",\"katt\")")
                .build();
        when(occupationalHealthRepository.findAllByCompanyId(companyId)).thenReturn(List.of(rec));
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            String csv = service.exportOccupationalHealthCsv();
            // Az injection-es cella elé aposztróf kerül
            assertThat(csv).contains("'=HYPERLINK");
        }
    }
}
