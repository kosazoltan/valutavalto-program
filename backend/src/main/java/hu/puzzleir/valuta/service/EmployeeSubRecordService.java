package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.employee.EmployeeChildDto;
import hu.puzzleir.valuta.dto.employee.EmployeeOccupationalHealthDto;
import hu.puzzleir.valuta.dto.employee.EmployeeVacationDto;
import hu.puzzleir.valuta.entity.Employee;
import hu.puzzleir.valuta.entity.EmployeeChild;
import hu.puzzleir.valuta.entity.EmployeeOccupationalHealth;
import hu.puzzleir.valuta.entity.EmployeeVacation;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.EmployeeChildRepository;
import hu.puzzleir.valuta.repository.EmployeeOccupationalHealthRepository;
import hu.puzzleir.valuta.repository.EmployeeRepository;
import hu.puzzleir.valuta.repository.EmployeeVacationRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * G19 (EXCMD b9-munkavallalo): munkavállaló al-nyilvántartások CRUD —
 * üzemorvosi vizsgálat (FR-22), szabadságok (FR-19), gyerekek (FR-20).
 *
 * <p>Multi-tenant: minden művelet ellenőrzi, hogy az employee az aktuális
 * céghez tartozik (cross-tenant IDOR guard).</p>
 */
@Service
@RequiredArgsConstructor
@Transactional
public class EmployeeSubRecordService {

    private final EmployeeRepository employeeRepository;
    private final EmployeeOccupationalHealthRepository occupationalHealthRepository;
    private final EmployeeVacationRepository vacationRepository;
    private final EmployeeChildRepository childRepository;

    /** Betölti az employee-t és ellenőrzi, hogy az aktuális céghez tartozik. */
    private Employee loadScoped(Long employeeId) {
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new ResourceNotFoundException("Munkavállaló nem található: " + employeeId));
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (employee.getCompany() == null || !employee.getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Munkavállaló nem található: " + employeeId);
        }
        return employee;
    }

    // ============ Üzemorvosi vizsgálat (FR-22) ============

    @Transactional(readOnly = true)
    public List<EmployeeOccupationalHealthDto> listOccupationalHealth(Long employeeId) {
        loadScoped(employeeId);
        return occupationalHealthRepository.findByEmployeeIdOrderByExamDateDesc(employeeId)
                .stream().map(this::toDto).toList();
    }

    public EmployeeOccupationalHealthDto addOccupationalHealth(Long employeeId, EmployeeOccupationalHealthDto dto) {
        Employee employee = loadScoped(employeeId);
        EmployeeOccupationalHealth e = EmployeeOccupationalHealth.builder()
                .employee(employee)
                .status(dto.status())
                .deadlineDate(dto.deadlineDate())
                .examDate(dto.examDate())
                .result(dto.result())
                .restriction(dto.restriction())
                .build();
        return toDto(occupationalHealthRepository.save(e));
    }

    public void deleteOccupationalHealth(Long employeeId, Long recordId) {
        loadScoped(employeeId);
        EmployeeOccupationalHealth e = occupationalHealthRepository.findById(recordId)
                .orElseThrow(() -> new ResourceNotFoundException("Üzemorvosi rekord nem található: " + recordId));
        if (!e.getEmployee().getId().equals(employeeId)) {
            throw new ResourceNotFoundException("Üzemorvosi rekord nem található: " + recordId);
        }
        occupationalHealthRepository.delete(e);
    }

    private EmployeeOccupationalHealthDto toDto(EmployeeOccupationalHealth e) {
        return new EmployeeOccupationalHealthDto(
                e.getId(), e.getStatus(), e.getDeadlineDate(), e.getExamDate(), e.getResult(), e.getRestriction());
    }

    // ============ Szabadságok (FR-19) ============

    @Transactional(readOnly = true)
    public List<EmployeeVacationDto> listVacations(Long employeeId) {
        loadScoped(employeeId);
        return vacationRepository.findByEmployeeIdOrderByYearDesc(employeeId)
                .stream().map(this::toDto).toList();
    }

    public EmployeeVacationDto addVacation(Long employeeId, EmployeeVacationDto dto) {
        Employee employee = loadScoped(employeeId);
        if (dto.year() == null) {
            throw new ValidationException("A szabadság-sorhoz az év kötelező!");
        }
        EmployeeVacation e = EmployeeVacation.builder()
                .employee(employee)
                .year(dto.year())
                .broughtForward(nz(dto.broughtForward()))
                .vacationDays(nz(dto.vacationDays()))
                .sickLeaveDays(nz(dto.sickLeaveDays()))
                .takenVacation(nz(dto.takenVacation()))
                .takenSickLeave(nz(dto.takenSickLeave()))
                .sickPayDays(nz(dto.sickPayDays()))
                .unpaidLeaveDays(nz(dto.unpaidLeaveDays()))
                .build();
        return toDto(vacationRepository.save(e));
    }

    public void deleteVacation(Long employeeId, Long recordId) {
        loadScoped(employeeId);
        EmployeeVacation e = vacationRepository.findById(recordId)
                .orElseThrow(() -> new ResourceNotFoundException("Szabadság-rekord nem található: " + recordId));
        if (!e.getEmployee().getId().equals(employeeId)) {
            throw new ResourceNotFoundException("Szabadság-rekord nem található: " + recordId);
        }
        vacationRepository.delete(e);
    }

    private int nz(Integer v) {
        return v != null ? v : 0;
    }

    private EmployeeVacationDto toDto(EmployeeVacation e) {
        return new EmployeeVacationDto(
                e.getId(), e.getYear(), e.getBroughtForward(), e.getVacationDays(), e.getSickLeaveDays(),
                e.getTakenVacation(), e.getTakenSickLeave(), e.getSickPayDays(), e.getUnpaidLeaveDays());
    }

    // ============ Gyerekek (FR-20) ============

    @Transactional(readOnly = true)
    public List<EmployeeChildDto> listChildren(Long employeeId) {
        loadScoped(employeeId);
        return childRepository.findByEmployeeIdOrderByBirthDateAsc(employeeId)
                .stream().map(this::toDto).toList();
    }

    public EmployeeChildDto addChild(Long employeeId, EmployeeChildDto dto) {
        Employee employee = loadScoped(employeeId);
        if (dto.name() == null || dto.name().isBlank()) {
            throw new ValidationException("A gyermek neve kötelező!");
        }
        EmployeeChild e = EmployeeChild.builder()
                .employee(employee)
                .name(dto.name())
                .birthDate(dto.birthDate())
                .build();
        return toDto(childRepository.save(e));
    }

    public void deleteChild(Long employeeId, Long recordId) {
        loadScoped(employeeId);
        EmployeeChild e = childRepository.findById(recordId)
                .orElseThrow(() -> new ResourceNotFoundException("Gyermek-rekord nem található: " + recordId));
        if (!e.getEmployee().getId().equals(employeeId)) {
            throw new ResourceNotFoundException("Gyermek-rekord nem található: " + recordId);
        }
        childRepository.delete(e);
    }

    private EmployeeChildDto toDto(EmployeeChild e) {
        return new EmployeeChildDto(e.getId(), e.getName(), e.getBirthDate());
    }
}
