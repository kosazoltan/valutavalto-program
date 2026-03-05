package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * ENSZ/EU/OFAC szankciós lista bejegyzés.
 *
 * Jogszabályi háttér:
 * - 2017. évi LIII. törvény (Pmt.) — pénzmosás és terrorizmus finanszírozás megelőzése
 * - EU 2580/2001 rendelet — terrorizmus elleni szankciós lista
 * - ENSZ BT határozatok alapján vezetett szankciós lista
 *
 * A szűrés KÖTELEZŐ minden pénzváltási tranzakció előtt.
 */
@Entity
@Table(name = "sanction_entries", indexes = {
        @Index(name = "idx_sanction_full_name", columnList = "full_name"),
        @Index(name = "idx_sanction_document_number", columnList = "document_number"),
        @Index(name = "idx_sanction_active", columnList = "active"),
        @Index(name = "idx_sanction_list_type", columnList = "list_type")
})
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class SanctionEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /** Teljes név */
    @Column(name = "full_name", nullable = false, length = 500)
    private String fullName;

    /** Alternatív nevek (JSON tömb) */
    @Column(name = "aliases", columnDefinition = "TEXT")
    private String aliases;

    /** Születési dátum */
    @Column(name = "date_of_birth", length = 50)
    private String dateOfBirth;

    /** Állampolgárság */
    @Column(name = "nationality", length = 100)
    private String nationality;

    /** Okmányszám (személyi, útlevél) */
    @Column(name = "document_number", length = 100)
    private String documentNumber;

    /** Lista típusa: UN, EU, OFAC */
    @Column(name = "list_type", nullable = false, length = 20)
    private String listType;

    /** Lista hivatkozás (pl. UN határozat száma) */
    @Column(name = "list_reference", length = 500)
    private String listReference;

    /** Felvétel dátuma a listára */
    @Column(name = "added_date")
    private LocalDate addedDate;

    /** Utolsó frissítés dátuma */
    @Column(name = "last_updated")
    private LocalDate lastUpdated;

    /** Aktív-e a bejegyzés */
    @Column(name = "active", nullable = false)
    @Builder.Default
    private Boolean active = true;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
