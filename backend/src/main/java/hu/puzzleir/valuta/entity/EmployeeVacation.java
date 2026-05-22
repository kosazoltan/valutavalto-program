package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Szabadság al-nyilvántartás — évenkénti soros (G19, EXCMD b9-munkavallalo FR-19).
 */
@Entity
@Table(name = "employee_vacation")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeVacation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    /** Év. */
    @Column(nullable = false)
    private Integer year;

    /** Áthozott. */
    @Column(name = "brought_forward", nullable = false)
    @Builder.Default
    private Integer broughtForward = 0;

    /** Szabadság. */
    @Column(name = "vacation_days", nullable = false)
    @Builder.Default
    private Integer vacationDays = 0;

    /** Betegszabadság. */
    @Column(name = "sick_leave_days", nullable = false)
    @Builder.Default
    private Integer sickLeaveDays = 0;

    /** Kivett szabadság. */
    @Column(name = "taken_vacation", nullable = false)
    @Builder.Default
    private Integer takenVacation = 0;

    /** Kivett betegszabadság. */
    @Column(name = "taken_sick_leave", nullable = false)
    @Builder.Default
    private Integer takenSickLeave = 0;

    /** Táppénz. */
    @Column(name = "sick_pay_days", nullable = false)
    @Builder.Default
    private Integer sickPayDays = 0;

    /** Fizetés nélküli szabadság. */
    @Column(name = "unpaid_leave_days", nullable = false)
    @Builder.Default
    private Integer unpaidLeaveDays = 0;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
