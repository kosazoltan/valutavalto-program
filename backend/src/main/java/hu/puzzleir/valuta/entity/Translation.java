package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * Fordítás (i18n) entity.
 *
 * A rendszer alapból magyar, de a bizonylatok és kijelzők
 * angol/német nyelvre is fordíthatók.
 */
@Entity
@Table(name = "translation", indexes = {
    @Index(name = "idx_translation_lang_key", columnList = "language_code, message_key", unique = true),
    @Index(name = "idx_translation_module", columnList = "module")
})
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Translation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "language_code", nullable = false, length = 5)
    private String languageCode;

    @Column(name = "message_key", nullable = false, length = 200)
    private String messageKey;

    @Column(name = "message_value", nullable = false, columnDefinition = "TEXT")
    private String messageValue;

    @Column(name = "module", nullable = false, length = 30)
    private String module;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
