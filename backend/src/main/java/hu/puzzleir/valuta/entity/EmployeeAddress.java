package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Dolgozói cím entity.
 * Egy dolgozónak max 3 címe lehet: állandó, levelezési, ideiglenes.
 */
@Entity
@Table(name = "employee_address")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeAddress {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Kapcsolódó dolgozó */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "employee_id", nullable = false)
    private Employee employee;

    /** Cím típusa: PERMANENT, MAILING, TEMPORARY */
    @Enumerated(EnumType.STRING)
    @Column(name = "address_type", nullable = false, length = 20)
    private AddressType addressType;

    /** Irányítószám */
    @Column(name = "postal_code", length = 10)
    private String postalCode;

    /** Város */
    @Column(length = 100)
    private String city;

    /** Közterület neve */
    @Column(name = "street_name", length = 200)
    private String streetName;

    /** Közterület jellege (utca, út, tér, stb.) */
    @Column(name = "street_type", length = 50)
    private String streetType;

    /** Házszám */
    @Column(name = "house_number", length = 20)
    private String houseNumber;

    /** Épület */
    @Column(length = 30)
    private String building;

    /** Lépcsőház */
    @Column(length = 30)
    private String staircase;

    /** Emelet */
    @Column(length = 20)
    private String floor;

    /** Ajtó */
    @Column(length = 20)
    private String door;
}
