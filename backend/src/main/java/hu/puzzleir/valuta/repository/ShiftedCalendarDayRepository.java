package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.ShiftedCalendarDay;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.Optional;

/**
 * Áthelyezett naptári napok repository (#PP-17). Globális lookup (nem tenant-scope) —
 * a kormányzati munkanap-áthelyezés országosan érvényes.
 */
public interface ShiftedCalendarDayRepository extends JpaRepository<ShiftedCalendarDay, Long> {

    Optional<ShiftedCalendarDay> findByCalendarDate(LocalDate calendarDate);
}
