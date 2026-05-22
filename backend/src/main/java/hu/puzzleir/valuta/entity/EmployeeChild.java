package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Gyermek al-nyilvántartás (G19, EXCMD b9-munkavallalo FR-20).
 */
@Entity
@Table(name = "employee_child")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeChild {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    /** Gyermek neve. */
    @Column(nullable = false, length = 200)
    private String name;

    /** Születési dátum. */
    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
