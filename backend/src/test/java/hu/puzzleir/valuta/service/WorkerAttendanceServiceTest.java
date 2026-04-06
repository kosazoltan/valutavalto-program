package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.worker.WorkerAttendanceDto;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerAttendance;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerAttendanceRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class WorkerAttendanceServiceTest {

    @Mock private WorkerAttendanceRepository attendanceRepository;
    @Mock private WorkerRepository workerRepository;
    @InjectMocks private WorkerAttendanceService service;

    @Test
    @DisplayName("recordLogin — sikeres bejelentkezes")
    void testRecordLogin_success() {
        Worker worker = Worker.builder().id(1L).build();
        UUID branchId = UUID.randomUUID();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(branchId);

            when(workerRepository.findById(1L)).thenReturn(Optional.of(worker));
            when(attendanceRepository.save(any())).thenAnswer(inv -> {
                WorkerAttendance a = inv.getArgument(0);
                a.setId(UUID.randomUUID());
                return a;
            });

            WorkerAttendanceDto result = service.recordLogin("192.168.1.1", "TestAgent");

            assertThat(result).isNotNull();
            assertThat(result.getWorkerId()).isEqualTo(1L);
            assertThat(result.getBranchId()).isEqualTo(branchId);
            assertThat(result.getLoginAt()).isNotNull();
            assertThat(result.getIpAddress()).isEqualTo("192.168.1.1");
            verify(attendanceRepository).save(any());
        }
    }

    @Test
    @DisplayName("recordLogin — nem letezo dolgozo")
    void testRecordLogin_workerNotFound() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(999L);
            su.when(SecurityUtils::getCurrentBranchId).thenReturn(UUID.randomUUID());
            when(workerRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.recordLogin("127.0.0.1", null))
                    .isInstanceOf(ResourceNotFoundException.class);
        }
    }

    @Test
    @DisplayName("recordLogout — sikeres kijelentkezes")
    void testRecordLogout_success() {
        UUID attendanceId = UUID.randomUUID();
        Worker worker = Worker.builder().id(1L).build();
        WorkerAttendance attendance = WorkerAttendance.builder()
                .id(attendanceId)
                .worker(worker)
                .branchId(UUID.randomUUID())
                .loginAt(LocalDateTime.now().minusHours(8))
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            when(attendanceRepository.findById(attendanceId)).thenReturn(Optional.of(attendance));
            when(attendanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            WorkerAttendanceDto result = service.recordLogout(attendanceId);

            assertThat(result.getLogoutAt()).isNotNull();
            verify(attendanceRepository).save(any());
        }
    }

    @Test
    @DisplayName("recordLogout — dupla kijelentkezes tiltva")
    void testRecordLogout_alreadyLoggedOut() {
        UUID attendanceId = UUID.randomUUID();
        Worker worker = Worker.builder().id(1L).build();
        WorkerAttendance attendance = WorkerAttendance.builder()
                .id(attendanceId)
                .worker(worker)
                .branchId(UUID.randomUUID())
                .loginAt(LocalDateTime.now().minusHours(8))
                .logoutAt(LocalDateTime.now())
                .build();

        when(attendanceRepository.findById(attendanceId)).thenReturn(Optional.of(attendance));

        assertThatThrownBy(() -> service.recordLogout(attendanceId))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("már rögzítve");
    }

    @Test
    @DisplayName("getMyAttendance — datum tartomany")
    void testGetMyAttendance_dateRange() {
        Worker worker = Worker.builder().id(1L).build();
        WorkerAttendance attendance = WorkerAttendance.builder()
                .id(UUID.randomUUID())
                .worker(worker)
                .branchId(UUID.randomUUID())
                .loginAt(LocalDateTime.now().minusDays(1))
                .logoutAt(LocalDateTime.now().minusDays(1).plusHours(8))
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(1L);
            when(attendanceRepository.findByWorkerIdAndDateRange(eq(1L), any(), any(), any()))
                    .thenReturn(new PageImpl<>(List.of(attendance)));

            Page<WorkerAttendanceDto> result = service.getMyAttendance(
                    LocalDate.now().minusDays(7), LocalDate.now(), PageRequest.of(0, 20));

            assertThat(result.getTotalElements()).isEqualTo(1);
        }
    }

    @Test
    @DisplayName("recordLogout — manager felulirhatja mas dolgozo logout-jat")
    void testRecordLogout_managerOverride() {
        UUID attendanceId = UUID.randomUUID();
        Worker worker = Worker.builder().id(2L).build();
        WorkerAttendance attendance = WorkerAttendance.builder()
                .id(attendanceId)
                .worker(worker)
                .branchId(UUID.randomUUID())
                .loginAt(LocalDateTime.now().minusHours(8))
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(99L); // mas dolgozo
            su.when(SecurityUtils::isManagerOrAbove).thenReturn(true);   // de manager
            when(attendanceRepository.findById(attendanceId)).thenReturn(Optional.of(attendance));
            when(attendanceRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            WorkerAttendanceDto result = service.recordLogout(attendanceId);
            assertThat(result.getLogoutAt()).isNotNull();
        }
    }

    @Test
    @DisplayName("recordLogout — nem-manager nem irhatja felul mas logout-jat")
    void testRecordLogout_nonManagerCannotOverride() {
        UUID attendanceId = UUID.randomUUID();
        Worker worker = Worker.builder().id(2L).build();
        WorkerAttendance attendance = WorkerAttendance.builder()
                .id(attendanceId)
                .worker(worker)
                .branchId(UUID.randomUUID())
                .loginAt(LocalDateTime.now().minusHours(8))
                .build();

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(99L); // mas dolgozo
            su.when(SecurityUtils::isManagerOrAbove).thenReturn(false); // nem manager
            when(attendanceRepository.findById(attendanceId)).thenReturn(Optional.of(attendance));

            assertThatThrownBy(() -> service.recordLogout(attendanceId))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("jogosultság");
        }
    }

    @Test
    @DisplayName("getAttendanceByWorker — datum nelkul")
    void testGetAttendanceByWorker_noDates() {
        Worker worker = Worker.builder().id(2L).build();
        WorkerAttendance att = WorkerAttendance.builder()
                .id(UUID.randomUUID())
                .worker(worker)
                .branchId(UUID.randomUUID())
                .loginAt(LocalDateTime.now())
                .build();

        when(attendanceRepository.findByWorkerId(eq(2L), any()))
                .thenReturn(new PageImpl<>(List.of(att)));

        Page<WorkerAttendanceDto> result = service.getAttendanceByWorker(2L, null, null, PageRequest.of(0, 20));
        assertThat(result.getTotalElements()).isEqualTo(1);
    }
}
