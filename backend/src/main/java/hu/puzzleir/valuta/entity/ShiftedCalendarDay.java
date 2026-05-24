package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Kormányzati rendelettel áthelyezett naptári nap (rendkívüli munkanap / pihenőnap).
 *
 * <p>Audit #PP-17: a magyar kormány évente áthelyez egyes szombatokat hivatalos
 * munkanappá (hétközi pihenőnap ledolgozása), illetve egyes hétköznapokat
 * pihenőnappá (hosszú hétvége). Az AML SAR-határidő (Pmt. 33. § 2 munkanap)
 * számításának ezeket figyelembe kell vennie. Globális lookup (nem tenant-függő),
 * az admin tölti a hivatalos NGM/kormányrendelet alapján.</p>
 *
 * <p>{@code workday=true}: szombat/vasárnap, amin mégis dolgozunk → munkanapnak számít.
 * {@code workday=false}: hétköznap, ami pihenőnap → NEM számít munkanapnak.</p>
 */
@Entity
@Table(name = "shifted_calendar_day")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ShiftedCalendarDay {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "calendar_date", nullable = false, unique = true)
    private LocalDate calendarDate;

    @Column(name = "is_workday", nullable = false)
    private boolean workday;

    @Column(name = "description", length = 255)
    private String description;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
    }
}
