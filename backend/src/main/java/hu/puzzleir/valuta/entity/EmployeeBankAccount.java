package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Dolgozói bankszámla entity.
 * Típusok: bérszámla (SALARY), SZÉP kártya (SZEP_CARD).
 */
@Entity
@Table(name = "employee_bank_account")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeBankAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Kapcsolódó dolgozó */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    /** Számla típusa: SALARY, SZEP_CARD */
    @Enumerated(EnumType.STRING)
    @Column(name = "account_type", nullable = false, length = 20)
    private BankAccountType accountType;

    /** Bank kód */
    @Column(name = "bank_code", length = 10)
    private String bankCode;

    /** Bankszámlaszám */
    @Column(name = "account_number", length = 50)
    private String accountNumber;
}
