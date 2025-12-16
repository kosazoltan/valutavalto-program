package hu.puzzleir.valuta.entity;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Pénztáros munkamenet (bejelentkezés/kijelentkezés tracking).
 * 
 * Legacy mapping:
 * - prosbe.dll: PtarosBelepese (login)
 * - proski.dll: PtarosKilep (logout)
 * - Nem volt explicit session tracking a legacy-ben
 */
@Entity
@Table(name = "worker_session")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkerSession {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    /**
     * MULTI-TENANT: Cég kapcsolat
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    private Company company;
    
    /**
     * Pénztáros
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "worker_id", nullable = false)
    private Worker worker;
    
    /**
     * Iroda/fiók ahol bejelentkezett
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id", nullable = false)
    private Branch branch;
    
    /**
     * Bejelentkezés időpontja
     */
    @Column(name = "login_at", nullable = false)
    private LocalDateTime loginAt;
    
    /**
     * Kijelentkezés időpontja (null = még aktív)
     */
    @Column(name = "logout_at")
    private LocalDateTime logoutAt;
    
    /**
     * IP cím
     */
    @Column(name = "ip_address", length = 45)
    private String ipAddress;
    
    /**
     * User agent (böngésző)
     */
    @Column(name = "user_agent")
    private String userAgent;
    
    /**
     * JWT token ID (opcionális - token invalidation tracking)
     */
    @Column(name = "token_id", length = 100)
    private String tokenId;
}
