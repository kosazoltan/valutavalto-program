package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.employee.EmployeeChildDto;
import hu.puzzleir.valuta.dto.employee.EmployeeVacationDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Employee;
import hu.puzzleir.valuta.entity.EmployeeChild;
import hu.puzzleir.valuta.entity.EmployeeVacation;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
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
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class EmployeeSubRecordServiceTest {

    @Mock private EmployeeRepository employeeRepository;
    @Mock private EmployeeOccupationalHealthRepository occupationalHealthRepository;
    @Mock private EmployeeVacationRepository vacationRepository;
    @Mock private EmployeeChildRepository childRepository;

    @InjectMocks
    private EmployeeSubRecordService service;

    private final UUID companyId = UUID.randomUUID();
    private static final Long EMPLOYEE_ID = 42L;

    private Employee employeeInCompany(UUID ownerCompanyId) {
        Company company = new Company();
        company.setId(ownerCompanyId);
        Employee e = new Employee();
        e.setId(EMPLOYEE_ID);
        e.setCompany(company);
        return e;
    }

    @Test
    @DisplayName("listVacations — happy path, év szerint csökkenő map")
    void listVacations_happyPath() {
        EmployeeVacation v = EmployeeVacation.builder()
                .id(1L).year(2026).broughtForward(2).vacationDays(20)
                .takenVacation(5).build();
        when(employeeRepository.findById(EMPLOYEE_ID)).thenReturn(Optional.of(employeeInCompany(companyId)));
        when(vacationRepository.findByEmployeeIdOrderByYearDesc(EMPLOYEE_ID)).thenReturn(List.of(v));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            List<EmployeeVacationDto> result = service.listVacations(EMPLOYEE_ID);
            assertThat(result).hasSize(1);
            assertThat(result.get(0).year()).isEqualTo(2026);
            assertThat(result.get(0).vacationDays()).isEqualTo(20);
        }
    }

    @Test
    @DisplayName("addChild — happy path elmenti")
    void addChild_happyPath() {
        when(employeeRepository.findById(EMPLOYEE_ID)).thenReturn(Optional.of(employeeInCompany(companyId)));
        when(childRepository.save(any(EmployeeChild.class))).thenAnswer(inv -> {
            EmployeeChild c = inv.getArgument(0);
            c.setId(7L);
            return c;
        });
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            EmployeeChildDto saved = service.addChild(EMPLOYEE_ID, new EmployeeChildDto(null, "Kis Pál", null));
            assertThat(saved.id()).isEqualTo(7L);
            assertThat(saved.name()).isEqualTo("Kis Pál");
        }
    }

    @Test
    @DisplayName("addChild — üres név → ValidationException")
    void addChild_blankName() {
        when(employeeRepository.findById(EMPLOYEE_ID)).thenReturn(Optional.of(employeeInCompany(companyId)));
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThatThrownBy(() -> service.addChild(EMPLOYEE_ID, new EmployeeChildDto(null, "  ", null)))
                    .isInstanceOf(ValidationException.class);
        }
    }

    @Test
    @DisplayName("addVacation — hiányzó év → ValidationException")
    void addVacation_missingYear() {
        when(employeeRepository.findById(EMPLOYEE_ID)).thenReturn(Optional.of(employeeInCompany(companyId)));
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThatThrownBy(() -> service.addVacation(EMPLOYEE_ID,
                    new EmployeeVacationDto(null, null, 0, 0, 0, 0, 0, 0, 0)))
                    .isInstanceOf(ValidationException.class);
        }
    }

    @Test
    @DisplayName("Multi-tenant: más céghez tartozó employee → ResourceNotFoundException (IDOR guard)")
    void crossTenant_guard() {
        UUID otherCompany = UUID.randomUUID();
        when(employeeRepository.findById(EMPLOYEE_ID)).thenReturn(Optional.of(employeeInCompany(otherCompany)));
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            assertThatThrownBy(() -> service.listChildren(EMPLOYEE_ID))
                    .isInstanceOf(ResourceNotFoundException.class);
            verify(childRepository, never()).findByEmployeeIdOrderByBirthDateAsc(any());
        }
    }

    @Test
    @DisplayName("addOccupationalHealth — happy path elmenti az üzemorvosi rekordot")
    void addOccupationalHealth_happyPath() {
        when(employeeRepository.findById(EMPLOYEE_ID)).thenReturn(Optional.of(employeeInCompany(companyId)));
        when(occupationalHealthRepository.save(any())).thenAnswer(inv -> {
            var e = (hu.puzzleir.valuta.entity.EmployeeOccupationalHealth) inv.getArgument(0);
            e.setId(3L);
            return e;
        });
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);
            var saved = service.addOccupationalHealth(EMPLOYEE_ID,
                    new hu.puzzleir.valuta.dto.employee.EmployeeOccupationalHealthDto(
                            null, "Lezárt", null, null, "Alkalmas", null));
            assertThat(saved.id()).isEqualTo(3L);
            assertThat(saved.result()).isEqualTo("Alkalmas");
        }
    }
}
