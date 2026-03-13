package hu.puzzleir.valuta.entity;

import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "notification")
@EntityListeners(AuditingEntityListener.class)
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    @Column(nullable = false, length = 30)
    private String type;

    /**
     * HIGH FIX #15: Worker.id Long → String konverzió.
     * A Worker.id Long típusú (GenerationType.IDENTITY), itt String-ként tároljuk.
     * Mentéskor: String.valueOf(worker.getId()) — lekérdezéskor: Long.parseLong(userId).
     * NE használj UUID-t ide — a Worker.id NEM UUID, hanem Long!
     */
    @Column(name = "user_id", length = 50)
    private String userId;

    @Column(name = "is_read")
    @Builder.Default
    private Boolean isRead = false;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
