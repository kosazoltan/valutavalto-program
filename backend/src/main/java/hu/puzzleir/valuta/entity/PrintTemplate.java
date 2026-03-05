package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Nyomtatási sablon — bizonylat, jelentés, címke, záróbizonylat.
 * HTML vagy ESC/POS formátumú tartalom, céghez kötött.
 */
@Entity
@Table(name = "print_template")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class PrintTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 200)
    private String name;

    @Column(name = "template_type", nullable = false, length = 30)
    @Enumerated(EnumType.STRING)
    private PrintTemplateType templateType;

    /** HTML/ESC-POS sablon tartalom — placeholder-ekkel (pl. {{receiptNumber}}) */
    @Column(columnDefinition = "TEXT")
    private String content;

    @Column(name = "is_default", nullable = false)
    private Boolean isDefault;

    @Column(name = "company_id")
    private Integer companyId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
        if (isDefault == null) isDefault = false;
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
