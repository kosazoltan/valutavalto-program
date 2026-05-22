package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Üzemorvosi vizsgálat al-nyilvántartás (G19, EXCMD b9-munkavallalo FR-22).
 */
@Entity
@Table(name = "employee_occupational_health")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeOccupationalHealth {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    /** Orvosi vizsgálat állapota (pl. "Lezárt"). */
    @Column(length = 50)
    private String status;

    /** Határidő dátuma. */
    @Column(name = "deadline_date")
    private LocalDate deadlineDate;

    /** Vizsgálat dátuma. */
    @Column(name = "exam_date")
    private LocalDate examDate;

    /** Orvosi vizsgálat eredménye (pl. "Alkalmas"). */
    @Column(length = 100)
    private String result;

    /** Megkötés. */
    @Column(length = 500)
    private String restriction;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
